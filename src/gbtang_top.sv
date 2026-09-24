//
// NESTang top level
// nand2mario
//

// `timescale 1ns / 100ps

import configPackage::*;

module gbtang_top (
    input sys_clk,

    // Button S1 and pin 48 are both resets
    input s1,
    input reset2,

    // UART
    input UART_RXD,
    output UART_TXD,

    // LEDs
    output [1:0] led,

    // SDRAM - Tang SDRAM pmod 1.2 for primer 25k, on-chip 32-bit 8MB SDRAM for nano 20k
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [SDRAM_DATA_WIDTH-1:0] IO_sdram_dq,      // bidirectional data bus
    output [SDRAM_ROW_WIDTH-1:0] O_sdram_addr,     // multiplexed address bus
    output [1:0] O_sdram_ba,        // two banks
    output [SDRAM_DATA_WIDTH/8-1:0] O_sdram_dqm,    

    // MicroSD
    output sd_clk,
    inout  sd_cmd,      // MOSI
    input  sd_dat0,     // MISO
    output sd_dat1,     // 1
    output sd_dat2,     // 1
    output sd_dat3,     // 1

    // SPI flash
    output flash_spi_cs_n,          // chip select
    input flash_spi_miso,           // master in slave out
    output flash_spi_mosi,          // mster out slave in
    output flash_spi_clk,           // spi clock
    output flash_spi_wp_n,          // write protect
    output flash_spi_hold_n,        // hold operations

`ifdef CONTROLLER_SNES
    // snes controllers
    output joy1_strb,
    output joy1_clk,
    input joy1_data,
    output joy2_strb,
    output joy2_clk,
    input joy2_data,
`endif

`ifdef CONTROLLER_DS2
    // dualshock controllers
    output ds_clk,
    input ds_miso,
    output ds_mosi,
    output ds_cs,
    output ds_clk2,
    input ds_miso2,
    output ds_mosi2,
    output ds_cs2,
`endif

    // USB
//     inout usbdm,
//     inout usbdp,
// `ifndef PRIMER
//     inout usbdm2,
//     inout usbdp2,
// `endif

    // HDMI TX
    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// Core settings
wire arm_reset = 0;
wire [1:0] system_type;
wire pal_video = 0;
wire [1:0] scanlines = 2'b0;
wire joy_swap = 0;
wire mirroring_osd = 0;
wire overscan_osd = 0;
wire famicon_kbd = 0;
wire [3:0] palette_osd = 0;
wire [2:0] diskside_osd = 0;
wire blend = 0;
wire bk_save = 0;

// GB/VerilogBoy signals
reg reset_nes = 1;    // active-high reset to boy core
reg clkref;
wire clk_gb;

// VerilogBoy cartridge bus
wire [15:0] gb_addr;
wire [7:0]  gb_dout;    // CPU -> cart
wire [7:0]  gb_din;     // cart -> CPU
wire        gb_wr;
wire        gb_rd;

// VerilogBoy video signals
wire gameboy_hs;
wire gameboy_vs;
wire gameboy_cpl;
wire [1:0] gameboy_pixel;
wire gameboy_valid;

// VerilogBoy audio signals
wire [15:0] gameboy_left;
wire [15:0] gameboy_right;

wire sdram_busy;
wire [21:0] memory_addr_cpu;  // mapped from gb_addr for SDRAM portB
wire [21:0] memory_addr_ppu;  // unused (tied 0)
wire memory_read_cpu, memory_write_cpu;
wire [7:0] memory_din_cpu;    // SDRAM -> CPU
wire [7:0] memory_dout_cpu;   // CPU -> SDRAM

// MBC5 instantiation for Game Boy cartridge mapping
wire [22:14] vb_rom_a;
wire [16:13] vb_ram_a;
wire rom_cs_n, ram_cs_n;

mbc5 u_mbc5(
    .vb_clk (clk_gb),
    .vb_rst (~sys_resetn | reset_nes),
    .vb_a   (gb_addr[15:12]),
    .vb_d   (gb_dout),
    .vb_wr  (gb_wr),
    .vb_rd  (gb_rd),
    .rom_a  (vb_rom_a),
    .ram_a  (vb_ram_a),
    .rom_cs_n (rom_cs_n),
    .ram_cs_n (ram_cs_n)
);

// Map ROM & RAM to SDRAM:
// ROM: 0x000000 - 0x3FFFFF (up to 4MB) mapped via vb_rom_a + gb_addr[13:0]
// RAM: 0x400000+ mapped via vb_ram_a + gb_addr[12:0]
assign memory_addr_cpu  = ~rom_cs_n ? {vb_rom_a[21:14], gb_addr[13:0]} :
                          ~ram_cs_n ? {2'b01, 3'b000, vb_ram_a[16:13], gb_addr[12:0]} :
                          22'd0;
assign memory_addr_ppu  = 22'd0;
assign memory_read_cpu  = ~loading & gb_rd & (~rom_cs_n | ~ram_cs_n);
assign memory_write_cpu = ~loading & gb_wr & ~ram_cs_n; // Writes only to Cart RAM, never overwrite Cart ROM!
assign memory_dout_cpu  = gb_dout;
assign gb_din           = memory_din_cpu;

// Combine joy1 and joy2 so either controller port works
wire [11:0] joy = joy1_btns | joy2_btns;

// Joypad: GB key mapping (VerilogBoy: bit 7=Down, 6=Up, 5=Left, 4=Right, 3=Start, 2=Select, 1=B, 0=A)
// Standard NES/SNES layout:
//   A: joy[0] (NES A / SNES B) | joy[8] (SNES A)
//   B: joy[1] (NES B / SNES Y) | joy[9] (SNES X)
wire [7:0] gb_key = {
    joy[5],                 // Down
    joy[4],                 // Up
    joy[6],                 // Left
    joy[7],                 // Right
    joy[3],                 // Start
    joy[2],                 // Select
    joy[1] | joy[9],        // B (NES B / SNES Y / SNES X)
    joy[0] | joy[8]         // A (NES A / SNES B / SNES A)
};

wire [4:0]  joypad1_data = 5'b11111;  // unused legacy
wire [4:0]  joypad2_data = 5'b11111;
wire [2:0]  joypad_out   = 3'b0;
wire [1:0]  joypad_clock = 2'b0;
reg  [7:0]  joypad_bits, joypad_bits2;
reg  [1:0]  last_joypad_clock;
wire [1:0]  nes_ce;

wire loading;
wire [7:0] loader_do;
wire loader_do_valid;

// iosys softcore
wire        rv_valid;
reg         rv_ready;
wire [22:0] rv_addr;
wire [31:0] rv_wdata;
wire [3:0]  rv_wstrb;
reg  [15:0] rv_dout0;
wire [31:0] rv_rdata = {rv_dout, rv_dout0};
reg         rv_valid_r;
reg         rv_word;           // which word
reg         rv_req;
wire        rv_req_ack;
wire [15:0] rv_dout;
reg [1:0]   rv_ds;
reg         rv_new_req;

// Controller
wire [7:0] joy_rx[0:1], joy_rx2[0:1];     // 6 RX bytes for all button/axis state
wire [7:0] usb_btn, usb_btn2;
wire usb_btn_x, usb_btn_y, usb_btn_x2, usb_btn_y2;
wire usb_conerr, usb_conerr2;
wire auto_a, auto_b, auto_a2, auto_b2;

// OR together when both SNES and DS2 controllers are connected (right now only nano20k supports both simultaneously)
wor [11:0] joy1_btns, joy2_btns;    // SNES layout (R L X A RT LT DN UP START SELECT Y B)
                                    // Lower 8 bits are NES buttons

// NES gamepad
wire [7:0]NES_gamepad_button_state;
wire NES_gamepad_data_available;
wire [7:0]NES_gamepad_button_state2;
wire NES_gamepad_data_available2;

// Loader
wire [21:0] loader_addr;
wire [7:0] loader_write_data;
reg loading_r;
always @(posedge clk) loading_r <= loading;
wire loader_reset = loading & ~loading_r;
wire loader_write;
wire [63:0] loader_flags;
reg  [63:0] mapper_flags;
wire loader_done, loader_fail;
wire loader_busy, loaded;
wire type_nes = 1'b1;  // (menu_index == 0) || (menu_index == {2'd0, 6'h1});
wire type_bios = 1'b0; // (menu_index == 2);
wire is_bios = 0;      //type_bios;
wire type_fds = 1'b0;  // (menu_index == {2'd1, 6'h1});
wire type_nsf = 1'b0;  // (menu_index == {2'd2, 6'h1});

wire int_audio;         // for VCR6
wire ext_audio;

///////////////////////////
// Clocks
///////////////////////////

wire clk;       // ~21.6 MHz main clock (27/5*4 via PLL clkoutd3)
wire fclk;      // 3x clk SDRAM clock
wire hclk;      // 720p pixel clock: 74.25 Mhz
wire hclk5;     // 5x pixel clock: 371.25 Mhz
wire clk27;     // 27Mhz to generate hclk/hclk5
wire clk_usb;   // 12Mhz USB clock

// Game Boy clock enable: divide clk (~21.6 MHz) by 5 => ~4.32 MHz
// VerilogBoy boy.v expects clk = 4.194304 MHz; CE method avoids extra PLL
reg [2:0] gb_ce_cnt;
wire gb_ce = (gb_ce_cnt == 3'd0);
always @(posedge clk) begin
    if (~sys_resetn)
        gb_ce_cnt <= 3'd0;
    else
        gb_ce_cnt <= (gb_ce_cnt == 3'd4) ? 3'd0 : gb_ce_cnt + 3'd1;
end

reg sys_resetn = 0;
reg [7:0] reset_cnt = 255;      // reset for 255 cycles before start everything
always @(posedge clk) begin
    reset_cnt <= reset_cnt == 0 ? 0 : reset_cnt - 1;
    if (reset_cnt == 0)
//    if (reset_cnt == 0 && s1)     // for nano
        sys_resetn <= ~(joy1_btns[5] && joy1_btns[3]);    //  Select + Up
end

`ifndef VERILATOR

`ifdef PRIMER
// sysclk 50Mhz
gowin_pll_27 pll_27 (.clkin(sys_clk), .clkout0(clk27));      // Primer25K: PLL to generate 27Mhz from 50Mhz
gowin_pll_gb pll_gb (.clkin(sys_clk), .clkout0(clk), .clkout1(fclk), .clkout2(O_sdram_clk));
`else
// sys_clk 27Mhz
assign clk27 = sys_clk;       // Nano20K: native 27Mhz system clock
gowin_pll_gb pll_gb(.clkin(sys_clk), .clkoutd3(clk), .clkout(fclk), .clkoutp(O_sdram_clk));
`endif  // PRIMER

gowin_pll_hdmi pll_hdmi (
    .clkin(clk27),
    .clkout(hclk5)
);

CLKDIV #(.DIV_MODE(5)) div5 (
    .CLKOUT(hclk),
    .HCLKIN(hclk5),
    .RESETN(sys_resetn),
    .CALIB(1'b0)
);

`else   // verilator

// dummy clocks for verilator
assign clk = sys_clk;
assign fclk = sys_clk;

`endif  // verilator

wire [31:0] status;

// 4.32 MHz Game Boy clock (21.6 MHz / 5)
reg [2:0] clk_gb_cnt;
reg r_clk_gb;
always @(posedge clk or negedge sys_resetn) begin
    if (!sys_resetn) begin
        clk_gb_cnt <= 3'd0;
        r_clk_gb   <= 1'b0;
    end else begin
        if (clk_gb_cnt == 3'd4) begin
            clk_gb_cnt <= 3'd0;
            r_clk_gb   <= 1'b1;
        end else begin
            clk_gb_cnt <= clk_gb_cnt + 3'd1;
            if (clk_gb_cnt == 3'd1)
                r_clk_gb <= 1'b0;
        end
    end
end
assign clk_gb = r_clk_gb;

///////////////////////////
// VerilogBoy Game Boy Core
///////////////////////////

boy u_verilogboy (
    .rst  (~sys_resetn | reset_nes),  // active-high reset
    .clk  (clk_gb),                   // 4.32 MHz Game Boy clock
    // Cartridge interface
    .a    (gb_addr),
    .dout (gb_dout),
    .din  (gb_din),
    .wr   (gb_wr),
    .rd   (gb_rd),
    // Keyboard: active-high in VerilogBoy (1=pressed, 0=released)
    .key  (gb_key),
    // LCD output
    .hs   (gameboy_hs),
    .vs   (gameboy_vs),
    .cpl  (gameboy_cpl),
    .pixel(gameboy_pixel),
    .valid(gameboy_valid),
    // Sound output
    .left (gameboy_left),
    .right(gameboy_right),
    // Debug
    .phi  (),
    .done (),
    .fault()
);

// loader_write -> clock when data available
reg loader_write_mem;
reg [7:0] loader_write_data_mem;
reg [21:0] loader_addr_mem;
reg loader_write_r;

always @(posedge clk) begin
    loader_write_mem <= 0;
    loader_write_r <= loader_write;

    loader_write_mem <= loader_write || loader_write_r;   // width 2
	if (loader_write) begin
		loader_addr_mem <= loader_addr;
		loader_write_data_mem <= loader_write_data;
	end

    if (loader_done)
        mapper_flags <= loader_flags;
end

// SDRAM: Port A unused (was NES PPU), Port B serves GB cartridge bus
sdram_gb sdram (
    .clk(fclk), .clkref(clkref), .resetn(sys_resetn), .busy(sdram_busy),

    .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba), 
    .SDRAM_nCS(O_sdram_cs_n), .SDRAM_nWE(O_sdram_wen_n), .SDRAM_nRAS(O_sdram_ras_n), 
    .SDRAM_nCAS(O_sdram_cas_n), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm), 

    // Port A: unused (tie off)
    .addrA(22'd0), .weA(1'b0), .dinA(8'd0), .oeA(1'b0), .doutA(),

    // Port B: GB cartridge ROM/RAM reads + loader writes
    .addrB(loading ? loader_addr_mem : memory_addr_cpu),
    .weB  (loader_write_mem | memory_write_cpu),
    .dinB (loading ? loader_write_data_mem : memory_dout_cpu),
    .oeB  (~loading & memory_read_cpu),
    .doutB(memory_din_cpu),

    // IOSys risc-v softcore (only needed in standalone PicoRV32 mode)
`ifdef MCU_BL616
    .rv_addr(23'd0), .rv_din(16'd0), 
    .rv_ds(2'd0), .rv_dout(), .rv_req(1'b0), .rv_req_ack(), .rv_we(1'b0)
`else
    .rv_addr({rv_addr[20:2], rv_word}), .rv_din(rv_word ? rv_wdata[31:16] : rv_wdata[15:0]), 
    .rv_ds(rv_ds), .rv_dout(rv_dout), .rv_req(rv_req), .rv_req_ack(rv_req_ack), .rv_we(rv_wstrb != 0)
`endif
);

// ROM loader: sequential raw binary stream into SDRAM starting from 0x000000
reg loader_do_valid_r;
always @(posedge clk) loader_do_valid_r <= loader_do_valid;
wire loader_do_valid_pulse = loader_do_valid & ~loader_do_valid_r;

reg [21:0] raw_loader_addr;
reg [7:0]  raw_loader_data;
reg        raw_loader_write;

always @(posedge clk) begin
    if (~sys_resetn || loader_reset) begin
        raw_loader_addr  <= 22'd0;
        raw_loader_write <= 1'b0;
    end else if (loading && loader_do_valid_pulse) begin
        raw_loader_data  <= loader_do;
        raw_loader_write <= 1'b1;
    end else if (raw_loader_write) begin
        raw_loader_write <= 1'b0;
        raw_loader_addr  <= raw_loader_addr + 22'd1;
    end
end

assign loader_write      = raw_loader_write;
assign loader_addr       = raw_loader_addr;
assign loader_write_data = raw_loader_data;
assign loader_done       = ~loading & loading_r;
assign loader_busy       = loading;
assign loader_fail       = 1'b0;
assign loader_flags      = 64'd0;

assign int_audio = 0;
assign ext_audio  = 0;

always @(posedge clk) begin
    clkref <= ~clkref;
    if (~loading && loading_r) begin
        reset_nes <= 0;
        clkref <= 1;
    end else if (loading && ~loading_r)
        reset_nes <= 1;
    if (~sys_resetn)
        reset_nes <= 1;
end

///////////////////////////
// Peripherals
///////////////////////////

`ifdef VERILATOR

// For verilator, the only peripheral is the compiled-in game data 
GameData game_data(
    .clk(clk), .reset(~sys_resetn), .downloading(loading), 
    .odata(loader_do), .odata_clk(loader_do_valid));

`else

// For physical board, there's HDMI, iosys, joypads, and USB
wire overlay;                   // iosys controls overlay
wire [10:0] overlay_x;
wire [9:0]  overlay_y;
wire [15:0] overlay_color;      // BGR5
wire GB_aspect_ratio;

// HDMI output - Game Boy video+audio via gameboy2hdmi
gameboy2hdmi u_hdmi (
    .clk(clk_gb), .resetn(sys_resetn),
    // Game Boy video
    .gameboy_hs(gameboy_hs),
    .gameboy_vs(gameboy_vs),
    .gameboy_cpl(gameboy_cpl),
    .gameboy_pixel(gameboy_pixel),
    .gameboy_valid(gameboy_valid),
    // Game Boy audio
    .gameboy_left(gameboy_left),
    .gameboy_right(gameboy_right),
    // Aspect ratio
    .i_reg_aspect_ratio(GB_aspect_ratio),
    // OSD overlay
    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color),
    // HDMI clocks and output
    .clk_pixel(hclk), .clk_5x_pixel(hclk5),
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p),
    .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
);

`ifdef MCU_BL616
// -----------------------------------------------------------------------------
// TangCore Companion Mode: BL616 MCU manages menu and ROM streaming via UART
// -----------------------------------------------------------------------------
iosys_bl616 #(
    .COLOR_LOGO(15'b00000_10101_00000), // green GBTang logo
    .FREQ(21_500_000),
    .CORE_ID(7)                          // 7: GBTang Game Boy / Color
) sys_inst (
    .clk(clk),
    .hclk(hclk),
    .resetn(sys_resetn),

    .overlay(overlay),
    .overlay_x(overlay_x),
    .overlay_y(overlay_y),
    .overlay_color(overlay_color[14:0]),
    .joy1(joy1_btns),
    .joy2(joy2_btns),
    .hid1(),
    .hid2(),
    .uart_tx(UART_TXD),
    .uart_rx(UART_RXD),

    .rom_loading(loading),
    .rom_do(loader_do),
    .rom_do_valid(loader_do_valid),
    .mgmt_address(),
    .mgmt_read(),
    .mgmt_readdata(16'd0),
    .mgmt_write(),
    .mgmt_writedata(),
    .fdd_request(2'd0),
    .kbd_data(),
    .kbd_data_valid(),
    .core_config()
);

assign overlay_color[15] = 1'b0;
assign GB_aspect_ratio = 1'b0;
wire system_type = 1'b0;

`else
// -----------------------------------------------------------------------------
// Standalone Mode: OSTang iosys with internal PicoRV32 softcore
// -----------------------------------------------------------------------------
localparam RV_IDLE_REQ0 = 3'd0;
localparam RV_WAIT0_REQ1 = 3'd1;
localparam RV_DATA0 = 3'd2;
localparam RV_WAIT1 = 3'd3;
localparam RV_DATA1 = 3'd4;
reg [2:0]   rvst;

always @(posedge clk) begin            // RV
    if (~sys_resetn) begin
        rvst <= RV_IDLE_REQ0;
        rv_ready <= 0;
    end else begin
        reg write = rv_wstrb != 0;
        reg rv_new_req_t = rv_valid & ~rv_valid_r;
        if (rv_new_req_t) rv_new_req <= 1;

        rv_ready <= 0;
        rv_valid_r <= rv_valid;

        case (rvst)
        RV_IDLE_REQ0: if (rv_new_req || rv_new_req_t) begin
            rv_new_req <= 0;
            rv_req <= ~rv_req;
            if (write && rv_wstrb[1:0] == 2'b0) begin
                // shortcut for only writing the upper word
                rv_word <= 1;
                rv_ds <= rv_wstrb[3:2];
                rvst <= RV_WAIT1;
            end else begin
                rv_word <= 0;
                if (write)
                    rv_ds <= rv_wstrb[1:0];
                else
                    rv_ds <= 2'b11;
                rvst <= RV_WAIT0_REQ1;
            end
        end

        RV_WAIT0_REQ1: begin
            if (rv_req == rv_req_ack) begin
                rv_req <= ~rv_req;      // request 1
                rv_word <= 1;
                if (write) begin
                    rvst <= RV_WAIT1;
                    if (rv_wstrb[3:2] == 2'b0) begin
                        // shortcut for only writing the lower word
                        rv_req <= rv_req;
                        rv_ready <= 1;
                        rvst <= RV_IDLE_REQ0;
                    end
                    rv_ds <= rv_wstrb[3:2];
                end else begin
                    rv_ds <= 2'b11;
                    rvst <= RV_DATA0;
                end
            end
        end

        RV_DATA0: begin
            rv_dout0 <= rv_dout;
            rvst <= RV_WAIT1;
        end
            
        RV_WAIT1: 
            if (rv_req == rv_req_ack) begin
                if (write)  begin
                    rv_ready <= 1;
                    rvst <= RV_IDLE_REQ0;
                end else
                    rvst <= RV_DATA1;
            end

        RV_DATA1: begin
            rv_ready <= 1;
            rvst <= RV_IDLE_REQ0;
        end

        default:;
        endcase
    end
end
reg GB_enhanced_APU;
wire system_type;
iosys #(.COLOR_LOGO(15'b01000_00000_01000), .CORE_ID(3) )     // purple nestang logo
    iosys (
    .clk(clk), .hclk(hclk), .resetn(sys_resetn),

    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color),
    .joy1(joy1_btns), .joy2(joy2_btns),

    .rom_loading(loading), .rom_do(loader_do), .rom_do_valid(loader_do_valid), 
    .ram_busy(sdram_busy),

    .rv_valid(rv_valid), .rv_ready(rv_ready), .rv_addr(rv_addr),
    .rv_wdata(rv_wdata), .rv_wstrb(rv_wstrb), .rv_rdata(rv_rdata),

    .flash_spi_cs_n(flash_spi_cs_n), .flash_spi_miso(flash_spi_miso),
    .flash_spi_mosi(flash_spi_mosi), .flash_spi_clk(flash_spi_clk),
    .flash_spi_wp_n(flash_spi_wp_n), .flash_spi_hold_n(flash_spi_hold_n),

    .uart_tx(UART_TXD), .uart_rx(UART_RXD),

    .sd_clk(sd_clk), .sd_cmd(sd_cmd), .sd_dat0(sd_dat0), .sd_dat1(sd_dat1),
    .sd_dat2(sd_dat2), .sd_dat3(sd_dat3),
    .o_reg_enhanced_apu(),
    // Wishbone master (tied off)
    .i_wb_ack(1'b0),
    .i_wb_stall(1'b0),
    .i_wb_idata(129'd0),
    .i_wb_err(1'b0),
	.o_wb_cyc(),
    .o_wb_stb(),
    .o_wb_we(),
    .o_wb_err(),
    .o_wb_addr(),
    .o_wb_odata(),
    .o_wb_sel(),

    // Cheats
    .o_cheats_enabled(),
    .o_cheats_loaded(),

    // Debug LED
    .o_dbg_led(),

    // System Type
    .o_sys_type(system_type),
    
    // Aspect Ratio
    .o_reg_aspect_ratio(GB_aspect_ratio)
);
`endif

// Diagnostic LEDs:
// led[0]: lights up (active low) once Game Boy CPU executes past $0100 in Cartridge ROM
// led[1]: toggles with Game Boy PPU VSync (~1 Hz heartbeat)
reg executed_game;
always @(posedge clk_gb or negedge sys_resetn) begin
    if (!sys_resetn)
        executed_game <= 1'b0;
    else if (gb_addr >= 16'h0100 && gb_addr <= 16'h7fff && gb_rd)
        executed_game <= 1'b1;
end

reg [5:0] vs_cnt;
always @(posedge gameboy_vs or negedge sys_resetn) begin
    if (!sys_resetn)
        vs_cnt <= 6'd0;
    else
        vs_cnt <= vs_cnt + 6'd1;
end

assign led[0] = ~executed_game;
assign led[1] = ~vs_cnt[5];

// Controller input
`ifdef CONTROLLER_SNES
controller_snes joy1_snes (
    .clk(clk), .resetn(sys_resetn), .buttons(joy1_btns),
    .joy_strb(joy1_strb), .joy_clk(joy1_clk), .joy_data(joy1_data)
);
controller_snes joy2_snes (
    .clk(clk), .resetn(sys_resetn), .buttons(joy2_btns),
    .joy_strb(joy2_strb), .joy_clk(joy2_clk), .joy_data(joy2_data)
);
`endif

`ifdef CONTROLLER_DS2
controller_ds2 joy1_ds2 (
    .clk(clk), .snes_buttons(joy1_btns),
    .ds_clk(ds_clk), .ds_miso(ds_miso), .ds_mosi(ds_mosi), .ds_cs(ds_cs) 
);
controller_ds2 joy2_ds2 (
   .clk(clk), .snes_buttons(joy2_btns),
   .ds_clk(ds_clk2), .ds_miso(ds_miso2), .ds_mosi(ds_mosi2), .ds_cs(ds_cs2) 
);
`endif

`endif // !VERILATOR

endmodule