// NES video and sound to HDMI converter
// nand2mario, 2022.9
// Modified by @fjpolo, 2025.03
`timescale 1ns / 1ps

module gameboy2hdmi (
    input clk,             // Main clock (Game Boy clock)
    input resetn,

    // Game Boy video signals
    input gameboy_hs,      // Horizontal Sync
    input gameboy_vs,      // Vertical Sync
    input gameboy_cpl,     // Pixel Latch
    input [1:0] gameboy_pixel, // Pixel Data (2-bit)
    input gameboy_valid,   // Pixel Valid

    // Game Boy audio signals
    input [15:0] gameboy_left,  // Left Audio
    input [15:0] gameboy_right, // Right Audio

    // Aspect Ratio
    input wire i_reg_aspect_ratio,

    // overlay interface
    input overlay,
    output [10:0] overlay_x,
    output [9:0] overlay_y,
    input [15:0] overlay_color, // BGR5, [15] is opacity

    // Video clocks
    input clk_pixel,
    input clk_5x_pixel,

    // HDMI outputs
    output tmds_clk_n,
    output tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// include from tang_primer_25k/config.sv and tang_nano_20k/config.sv

localparam FRAMEWIDTH = 1280;
localparam FRAMEHEIGHT = 720;
localparam TOTALWIDTH = 1650;
localparam TOTALHEIGHT = 750;
localparam SCALE = 5;
localparam VIDEOID = 4;
localparam VIDEO_REFRESH = 60.0;

localparam CLKFRQ = 74250;

localparam COLLEN = 80;
localparam AUDIO_BIT_WIDTH = 16;

localparam POWERUPNS = 100000000.0;
localparam CLKPERNS = (1.0/CLKFRQ)*1000000.0;
localparam int POWERUPCYCLES = $rtoi($ceil( POWERUPNS/CLKPERNS ));

// Main clock frequency
localparam FREQ=27_000_000;      // at least 10x baudrate
// localparam FREQ=37_800_000;

// UART baudrate: BAUDRATE <= FREQ/10
localparam BAUDRATE=115200;
// localparam BAUDRATE=921600;

// define this to execute one Game Boy cycle per 0.01 second and print the operation done
// `define STEP_TRACING

`ifdef VERILATOR
`define EMBED_GAME
`endif

// video stuff
wire [9:0] cy, frameHeight;
wire [10:0] cx, frameWidth;
logic [7:0] ONE_THIRD[0:768];       // lookup table for divide-by-3

assign overlay_x = cx;
assign overlay_y = cy;

logic active;
logic r_active;
logic [7:0] x;                  // Game Boy pixel position
wire [7:0] y;

//
// BRAM frame buffer
//
localparam MEM_DEPTH=160*144;
localparam MEM_ABITS=14;

logic [1:0] mem [0:160*144-1];
logic [13:0] mem_portA_addr;
logic [1:0] mem_portA_wdata;
logic mem_portA_we;

wire [13:0] mem_portB_addr;
logic [1:0] mem_portB_rdata;

logic initializing = 1;
logic [7:0] init_y = 0;
logic [7:0] init_x = 0;

// BRAM port A read/write
always_ff @(posedge clk) begin
    if (mem_portA_we) begin
        mem[mem_portA_addr] <= mem_portA_wdata;
    end
end

// BRAM port B read
always_ff @(posedge clk_pixel) begin
    mem_portB_rdata <= mem[mem_portB_addr];
end

initial begin
    $readmemb("background.txt", mem);
end

//
// Data input and initial background loading
//
logic r_gameboy_valid;
logic r_gameboy_cpl;
logic [1:0] r_gameboy_pixel;

always @(posedge clk) begin
    if (~resetn) begin
        initializing <= 1;
        init_y <= 0;
        init_x <= 0;
        mem_portA_we <= 0;
    end else if (initializing) begin      // setup background at initialization
        init_x <= init_x + 1;
        init_y <= init_x == 159 ? init_y + 1 : init_y;
        if (init_y == 144)
            initializing <= 0;
        mem_portA_we <= 1;
        mem_portA_addr <= {init_y, init_x};
        mem_portA_wdata <= 0;          // grey
    end else begin
        r_gameboy_valid <= gameboy_valid;
        r_gameboy_cpl <= gameboy_cpl;
        r_gameboy_pixel <= gameboy_pixel;

        mem_portA_we <= 1'b0;
        if ((r_gameboy_valid != gameboy_valid || r_gameboy_cpl != gameboy_cpl) && gameboy_valid && gameboy_cpl) begin
            mem_portA_addr <= {init_y, init_x};
            mem_portA_wdata <= gameboy_pixel;
            mem_portA_we <= 1'b1;
            init_x <= (init_x == 159) ? 0 : init_x + 1;
            init_y <= (init_x == 159) ? init_y + 1 : init_y;
            if (init_y == 144) init_y <= 0;
        end
    end
end

// audio stuff
localparam AUDIO_RATE=48000;
localparam AUDIO_CLK_DELAY = CLKFRQ * 1000 / AUDIO_RATE / 2;
logic [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
logic clk_audio;

always_ff@(posedge clk_pixel)
begin
    if (audio_divider != AUDIO_CLK_DELAY - 1)
        audio_divider++;
    else begin
        clk_audio <= ~clk_audio;
        audio_divider <= 0;
    end
end

reg [15:0] audio_sample_word [1:0], audio_sample_word0 [1:0];
always @(posedge clk_pixel) begin        // crossing clock domain
    audio_sample_word0[0] <= gameboy_left;
    audio_sample_word[0] <= audio_sample_word0[0];
    audio_sample_word0[1] <= gameboy_right;
    audio_sample_word[1] <= audio_sample_word0[1];
end

//
// Video
//
// We support both 1:1 pixel aspect ratio, and 10:9
// - 9 Game Boy pixels are mapped to 30 or 32 HDMI pixels horizontally in these 2 modes.
// - For 10:9, the follows are "border" HDMI pixels (0 to 31) that combine 2 neighboring Game Boy pixels
//      3:  120,199 6: 239,80 10: 160,160 13: 199,120 17: 80,239 20: 160,160 23: 120,199 26: 239,80 29: 199,120
//  For 1:1, there's no border pixels. Each Game Boy pixel is expanded to 3 HDMI pixels.
// - For 10:9, total width is 32*18 + 10 = 586. Therefore x goes from 347 to 932.
reg r2_active;
reg [4:0] xs, r_xs, r2_xs;     // x step for each 9 Game Boy pixel group, 0-31 for 10:9 pixel aspect ratio, or 0-29 for 1:1 pixel aspect ratio
wire xload = i_reg_aspect_ratio ?
        (xs == 5'd0 || xs == 5'd3 || xs == 5'd6 || xs == 5'd10 || xs == 5'd13 || xs == 5'd17 || xs == 5'd20 || xs == 5'd23 || xs == 5'd26 || xs == 5'd29)
    : (xs == 5'd0 || xs == 5'd3 || xs == 5'd6 || xs == 5'd9 || xs == 5'd12 || xs == 5'd15 || xs == 5'd18 || xs == 5'd21 || xs == 5'd24 || xs == 5'd27);
reg r_xload;
// x is incremented whenver xload is 1
assign y = ONE_THIRD[cy];
assign mem_portB_addr = {y, x};
// assign led = ~{2'b0, mem_portB_rdata};
reg [23:0] GB_PALETTE [0:3];
// Mix ratio of border pixels for 10x9 pixel aspect ratio
reg [15:0] mixratio;
reg mix;
wire [15:0] next_mixratio = ~i_reg_aspect_ratio ? 16'b0 :          // no mixing for 1:1 pixel aspect ratio
                            r_xs == 5'd3 ? {8'd120,8'd199} :
                            r_xs == 5'd6 ? {8'd239,8'd80} :
                            r_xs == 5'd10 ? {8'd160,8'd160} :
                            r_xs == 5'd13 ? {8'd199,8'd120} :
                            r_xs == 5'd17 ? {8'd80,8'd239} :
                            r_xs == 5'd20 ? {8'd160,8'd160} :
                            r_xs == 5'd23 ? {8'd120,8'd199} :
                            r_xs == 5'd26 ? {8'd239,8'd80} :
                            r_xs == 5'd29 ? {8'd199,8'd120} : 16'b0;
wire next_mix = r_xs == 5'd3 || r_xs == 5'd6 || r_xs == 5'd10 || r_xs == 5'd13 || r_xs == 5'd17 || r_xs == 5'd20 || r_xs == 5'd23 || r_xs == 5'd26 || r_xs == 5'd29;
reg [23:0] rgbv, r_rgbv;
wire [15:0] rmix = r_rgbv[23:16]*mixratio[15:8] + rgbv[23:16]*mixratio[7:0];
wire [15:0] gmix = r_rgbv[15:8]*mixratio[15:8] + rgbv[15:8]*mixratio[7:0];
wire [15:0] bmix = r_rgbv[7:0]*mixratio[15:8] + rgbv[7:0]*mixratio[7:0];
reg [23:0] rgb;     // actual RGB output
reg overlay_active;

// calc rgb value to hdmi
always_ff @(posedge clk_pixel) begin
    reg [23:0] rgb_gb;
    if (i_reg_aspect_ratio && cx == 11'd347 || ~i_reg_aspect_ratio && cx == 11'd381)
        active <= 1'b1;
    if (i_reg_aspect_ratio && cx == 11'd932 || ~i_reg_aspect_ratio && cx == 11'd898)
        active <= 1'b0;
    if (cx == 11'd256 && cy >= 10'd24 && cy < 10'd696)
        overlay_active <= 1;
    if (cx == 11'd1023)
        overlay_active <= 0;

    // calculate pixel rgb through 3 cycles
    // 0 - load: xmem_portB_rdata = mem[{y,x}]
    r_xload <= xload;
    r_active <= active; r2_active <= r_active;
    r_xs <= xs; r2_xs <= r_xs;
    if (active) begin
        if (i_reg_aspect_ratio)
            xs <= xs == 5'd31 ? 0 : xs + 1;
        else
            xs <= xs == 5'd29 ? 0 : xs + 1;
    end

    // 1 - look up palette and load mixratio
    if (r_active && r_xload) begin
        x <= x + 1;
        rgbv <= GB_PALETTE[mem_portB_rdata];
        r_rgbv <= rgbv;
    end
    mixratio <= next_mixratio;
    mix <= next_mix;

    // 2 - mix rgb and output
    if (r2_active) begin
        if (i_reg_aspect_ratio && mix)
            rgb_gb = {rmix[15:8], gmix[15:8], bmix[15:8]};
        else
            rgb_gb = rgbv;
    end else
        rgb_gb = 24'b0;

    if (overlay) begin     // transparency effect for overlay
        rgb <= {2'b0, rgb_gb[23:18], 2'b0, rgb_gb[15:10], 2'b0, rgb_gb[7:2]};
        if (overlay_active && overlay_color[15]) // overlay_color is BGR5
            rgb <= {overlay_color[4:0], 3'b0, overlay_color[9:5], 3'b0, overlay_color[14:10], 3'b0};
    end else
        rgb <= rgb_gb;     // normal Game Boy display

    if (cx == 0) begin
        x <= 0;
        xs <= 0; r_xs <= 0; r2_xs <= 0;
    end
end

// HDMI output.
logic[2:0] tmds;
hdmi #(
    .VIDEO_ID_CODE(VIDEOID), 
    .DVI_OUTPUT(0),
    .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
    .IT_CONTENT(1),
    .AUDIO_RATE(AUDIO_RATE),
    .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
    .START_X(0),
    .START_Y(0) )
hdmi( .clk_pixel_x5(clk_5x_pixel),
    .clk_pixel(clk_pixel),
    .clk_audio(clk_audio),
    .rgb(rgb),
    .reset( ~resetn ),
    .audio_sample_word(audio_sample_word),
    .tmds(tmds),
    .tmds_clock(tmdsClk),
    .cx(cx),
    .cy(cy),
    .frame_width( frameWidth ),
    .frame_height( frameHeight ) );

// Gowin LVDS output buffer
ELVDS_OBUF tmds_bufds [3:0] (
    .I({clk_pixel, tmds}),
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
);

// divide by three lookup table
genvar i;
generate
    for (i = 0; i < 768; i = i + 1) begin : gen_one_third
        assign ONE_THIRD[i] = i / 3;
    end
endgenerate

// Game Boy palette:
assign GB_PALETTE[0] = 24'he0f8d0; // lightest
assign GB_PALETTE[1] = 24'h88c070; // light
assign GB_PALETTE[2] = 24'h346856; // dark
assign GB_PALETTE[3] = 24'h081820; // darkest

endmodule