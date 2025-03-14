// NES video and sound to HDMI converter
// nand2mario, 2022.9
// Modified by @fjpolo, 2025.03
`timescale 1ns / 1ps

module gameboy2hdmi (
    input clk,                // Main clock (Game Boy clock)
    input resetn,

    // Game Boy video signals
    input gameboy_hs,         // Horizontal Sync
    input gameboy_vs,         // Vertical Sync
    input gameboy_cpl,        // Pixel Latch
    input [1:0] gameboy_pixel,// Pixel Data (2-bit)
    input gameboy_valid,      // Pixel Valid

    // Game Boy audio signals
    input [15:0] gameboy_left,  // Left Audio
    input [15:0] gameboy_right, // Right Audio

    // Video clocks
    input clk_pixel,
    input clk_5x_pixel,

    // HDMI outputs
    output tmds_clk_n,
    output tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// HDMI Configuration for 720p
localparam FRAMEWIDTH = 1280;
localparam FRAMEHEIGHT = 720;
localparam TOTALWIDTH = 1650;
localparam TOTALHEIGHT = 750;
localparam VIDEOID = 4;
localparam VIDEO_REFRESH = 60.0;
localparam CLKFRQ = 74250;

// Game Boy resolution
localparam GB_WIDTH = 160;
localparam GB_HEIGHT = 144;
localparam MEM_DEPTH = GB_WIDTH * GB_HEIGHT;
localparam MEM_ABITS = 16; // Sufficient for 160*144=23040 (15 bits)

// Game Boy Palette (4 colors)
logic [23:0] GB_PALETTE [0:3] = '{
    24'h000000, // Black
    24'h555555, // Dark Gray
    24'haaaaaa, // Light Gray
    24'hffffff  // White
};

// BRAM Frame Buffer
logic [1:0] mem [0:MEM_DEPTH-1];
logic [MEM_ABITS-1:0] write_addr;
logic [MEM_ABITS-1:0] read_addr;
logic mem_we;

// Video Counters
reg [8:0] h_count;
reg [8:0] v_count;
wire active_area = (h_count < GB_WIDTH) && (v_count < GB_HEIGHT);

// Capture Game Boy pixels
always @(posedge clk) begin
    if (!resetn) begin
        h_count <= 0;
        v_count <= 0;
        mem_we <= 0;
    end else begin
        if (gameboy_valid) begin
            mem[write_addr] <= gameboy_pixel;
            h_count <= h_count + 1;
            if (h_count == GB_WIDTH - 1) begin
                h_count <= 0;
                v_count <= v_count + 1;
                if (v_count == GB_HEIGHT - 1)
                    v_count <= 0;
            end
        end
        write_addr <= v_count * GB_WIDTH + h_count;
        mem_we <= gameboy_valid;
    end
end

// HDMI Timing Generation
logic [10:0] cx;
logic [9:0] cy;
logic [23:0] rgb;

// Scale Game Boy image to 720p (4x scale with borders)
always @(posedge clk_pixel) begin
    if (cx >= 320 && cx < 320 + 640 && cy >= 72 && cy < 72 + 576) begin
        read_addr <= ((cy - 72) >> 2) * GB_WIDTH + ((cx - 320) >> 2);
        rgb <= GB_PALETTE[mem[read_addr]];
    end else begin
        rgb <= 24'h000000; // Black borders
    end
end

// Audio Handling
logic [15:0] audio_sample_word [1:0];
always @(posedge clk_pixel) begin
    audio_sample_word[0] <= gameboy_left;
    audio_sample_word[1] <= gameboy_right;
end

// HDMI output wires (single-ended)
wire [2:0] tmds;
wire tmds_clk;

// HDMI instance now outputs to intermediate wires
hdmi #(
    .VIDEO_ID_CODE(VIDEOID),
    .DVI_OUTPUT(0),
    .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
    .AUDIO_RATE(48000),
    .AUDIO_BIT_WIDTH(16)
) hdmi_inst (
    .clk_pixel_x5(clk_5x_pixel),
    .clk_pixel(clk_pixel),
    .clk_audio(clk_pixel),
    .rgb(rgb),
    .reset(~resetn),
    .audio_sample_word(audio_sample_word),
    .tmds(tmds),          // Connect to 3-bit wire
    .tmds_clock(tmds_clk), // Connect to clock wire
    .cx(cx),
    .cy(cy)
);

// Correct LVDS buffer connection
ELVDS_OBUF tmds_bufds [3:0] (
    .I({tmds_clk, tmds}),  // Clock + 3 data channels
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
);

endmodule