// NES video and sound to HDMI converter
// nand2mario, 2022.9
// This is a special version for tang nano 20k as it uses less BRAM (4 vs the normal 8)

`timescale 1ns / 1ps

module snes2hdmi (
	input clk,      // snes clock
	input resetn,

    // snes video and audio signals
    input dotclk,
    input hblank,
    input vblank,
    input [14:0] rgb5,
    input [8:0] xs, // {x,dotclk}
    input [8:0] ys, // {field,y}

    input overlay,
    output reg [7:0] overlay_x,
    output reg [7:0] overlay_y,
    input [14:0] overlay_color,

    input [15:0] audio_l,
    input [15:0] audio_r,
    input audio_ready,
    output audio_en,

    // frame-sync pause happens during snes_refresh
    input snes_refresh,

	// video clocks
	input clk_pixel,
	input clk_5x_pixel,
	input locked,

    output reg pause_snes_for_frame_sync,

    // output [7:0] led,

	// output signals
	output       tmds_clk_n,
	output       tmds_clk_p,
	output [2:0] tmds_d_n,
	output [2:0] tmds_d_p
);

    localparam FRAMEWIDTH = 1280;       // 720P
    localparam FRAMEHEIGHT = 720;
    localparam TOTALWIDTH = 1650;
    localparam TOTALHEIGHT = 750;
    localparam SCALE = 5;
    localparam VIDEOID = 4;
    localparam VIDEO_REFRESH = 60.0;

    localparam IDIV_SEL_X5 = 3;
    localparam FBDIV_SEL_X5 = 54;
    localparam ODIV_SEL_X5 = 2;
    localparam DUTYDA_SEL_X5 = "1000";
    localparam DYN_SDIV_SEL_X5 = 2;
    
    localparam CLKFRQ = 74250;

    localparam AUDIO_BIT_WIDTH = 16;

    // video stuff
    wire [9:0] cy, frameHeight;
    wire [10:0] cx, frameWidth;
    reg active, r_active;
    wire [7:0] x, y;                    // SNES pixel position

    //
    // BRAM line buffer for 16 lines. Each pixel is 5:5:5 RGB
    // Each BRAM block holds 4 lines. So 16 lines needs 4 blocks.
    //
    localparam BUF_WIDTH = 4;        // 2 ^ BUF_WIDTH lines
    localparam BUF_SIZE = 1 << BUF_WIDTH;
    reg [14:0] mem [0:BUF_SIZE*256-1];
    reg [11:0] mem_portA_addr;
    reg [14:0] mem_portA_wdata;
    reg mem_portA_we;
    wire [11:0] mem_portB_addr;
    reg [14:0] mem_portB_rdata;
    reg mem_writeto = 1'b0;     // current line we are writing to. we read from the other line
   
    // We need to do a bit of synchronization as the SNES and HDMI run on separate clocks and they
    // do not align perfectly.
    // - Let SNES execute a bit faster (0.5%) than the HDMI stack. This way we always have enough pixels.
    // - For each frame, we let the SNES run until the first line is rendered, and written to line buffer.
    //   Then we pause the SNES and wait (through pause_snes_for_frame_sync) for HDMI to catch up.
    // - Once HDMI started the frame, start SNES again.
    reg sync_done = 1'b0;
    reg hdmi_first_line;
    reg pause_sync;     // pause for even number of cycles for PPU sdram access to stay in sync
    always @(posedge clk) begin
        if (pause_snes_for_frame_sync) pause_sync <= ~pause_sync;
        if (~sync_done) begin
            if (~pause_snes_for_frame_sync) begin
                if (ys[7:0] == 8'd2 && snes_refresh) begin      // halt SNES during snes dram refresh on line 2
                    pause_snes_for_frame_sync <= 1'b1;
                    pause_sync <= 0;
                end
            end else if (hdmi_first_line && pause_sync) begin                 // HDMI frame start, now resume SNES
                pause_snes_for_frame_sync <= 1'b0;
                sync_done <= 1'b1;
            end
        end else
            pause_snes_for_frame_sync <= 1'b0;
        if (ys[7:0] == 8'd200) sync_done <= 1'b0;               // reset sync_done for next frame
    end
    always @(posedge clk_pixel) begin
        if (cy == 10'd24 && cx >= 11'd256 && cx < 11'd356)      // first 100 pixels of first line
            hdmi_first_line <= 1;
        else
            hdmi_first_line <= 0;
    end

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

    integer j;
    initial begin
        // On power-up, fill line buffer with a gradient
        for (j = 0; j < 512; j=j+1) begin
            mem[j][14:10] = j;
            mem[j][9:5] = j;
            mem[j][4:0] = j;
        end
    end

    // 
    // Data input
    //
    reg r_dotclk, r_vblank, r_hblank;
    always @(posedge clk) begin
        r_dotclk <= dotclk;
        r_vblank <= vblank;
        mem_portA_we <= 1'b0;
        if (dotclk && ~r_dotclk && ~hblank && ~vblank && ys[7:0] < 224) begin       // on posedge of dotclk, read a pixel
            mem_portA_addr <= {ys[BUF_WIDTH-1:0], xs[8:1]};
            mem_portA_wdata <= rgb5;
            mem_portA_we <= 1'b1;
        end
    end

    always @(posedge clk) begin
        r_hblank <= hblank;
        if (hblank & ~r_hblank) begin       // flip active line on hblank
            mem_writeto <= ~mem_writeto;
        end
    end
    

    // HDMI TX audio - send 32K sampling rate audio
    // Hoarse sound issue: https://github.com/nand2mario/snestang/issues/16
    // SNES average framerate is 60.09881. So we need to pause the SNES a bit every frame to ensure 60 fps HDMI. 
    // For sound, that translate to about 8 samples pause time per frame. So we run our DSP a bit faster to 
    // buffer enough samples before the SNES pause.
    localparam AUDIO_OUT_RATE = 32000;
    localparam AUDIO_DELAY = CLKFRQ * 1000 / AUDIO_OUT_RATE / 2;
    reg [15:0] audio_sample_word [1:0];
    reg [$clog2(AUDIO_DELAY)-1:0] audio_divider;
    reg clk_audio;
    reg audio_rinc;
    wire audio_full, audio_empty;
    wire [31:0] audio_sample;

    always @(posedge clk_pixel) begin
        if (resetn) begin
            audio_rinc <= 0;
            if (audio_divider != AUDIO_DELAY - 1) 
                audio_divider <= audio_divider + 1;
            else begin 
                audio_divider <= 0;
                clk_audio = ~clk_audio;     // generate audio clock @ 32Khz
                // output audio sample on posedge clk_audio
                if (!clk_audio && !audio_empty) begin
                    {audio_sample_word[0], audio_sample_word[1]} <= audio_sample;
                    audio_rinc <= 1'b1;                    
                end
            end
        end
    end

    // Audio sample FIFO for 16 samples
    dual_clk_fifo #(.DATESIZE(32), .ADDRSIZE(4)) audio_fifo (
        .clk(clk), .wrst_n(1'b1), 
        .winc(audio_ready), .wdata({audio_l, audio_r}), .wfull(audio_full),
        .rclk(clk_pixel), .rrst_n(1'b1),
        .rinc(audio_rinc), .rdata(audio_sample), .rempty(audio_empty),
        .almost_full(), .almost_empty()
    );

    //
    // Video
    //
    assign active = cx >= 11'd256 && cx < 11'd1024 && cy >= 10'd24 && cy < 10'd696;
    wire [10:0] x0 = cx - 11'd256;
    wire [9:0] y0 = cy - 10'd24;

    // synthesizer takes care of integer const division with a few ALUs and no DSP usage
    assign x = (cx - 256) / 3;  
    assign y = (cy - 24) / 3;
    // another way that works but uses more resources
    // 0.3333 = 0.0101010101 binary
//    assign x = (x0 + (x0 >> 2) + (x0 >> 4) + (x0 >> 6) + (x0 >> 8)) >> 2;
    // assign y = (y0 + (y0 >> 2) + (y0 >> 4) + (y0 >> 6) + (y0 >> 8)) >> 2;
    assign mem_portB_addr = {y[BUF_WIDTH-1:0], x};
    reg [23:0] rgb;

    reg [1:0] overlay_cnt;

    always @(posedge clk_pixel) begin
        if (cx == 0) begin
            overlay_x <= 0;
            overlay_cnt <= 0;
        end
        if (cx >= 256) begin
            overlay_cnt <= overlay_cnt == 2 ? 0 : overlay_cnt + 1;
            if (overlay_cnt == 1)
                overlay_x <= overlay_x + 1;
        end
        overlay_y <= y;
    end

    // calc rgb value to hdmi
    always @(posedge clk_pixel) r_active <= active;

    always @* begin
        if (r_active)
//             if (y < 1)             // XXX: for debug purposes, show a gradient on the top
//                 rgb <= {x, x, x};
//             else
            if (~overlay)
                rgb <= {mem_portB_rdata[4:0], 3'b0, mem_portB_rdata[9:5], 3'b0, mem_portB_rdata[14:10], 3'b0};                
            else begin
//                if (overlay_color == 0) 
//                    rgb <= {2'b0, mem_portB_rdata[4:0], 3'b0, mem_portB_rdata[9:5], 3'b0, mem_portB_rdata[14:10], 1'b0};
//                else
                    rgb <= {overlay_color[4:0], 3'b0, overlay_color[9:5], 3'b0, overlay_color[14:10], 3'b0};
            end
        else
            rgb <= 24'h303030;      // show a grey background
    end


    // HDMI output.
    logic[2:0] tmds;

    hdmi #( .VIDEO_ID_CODE(VIDEOID), 
            .DVI_OUTPUT(0), 
            .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
            .IT_CONTENT(1),
            .AUDIO_RATE(AUDIO_OUT_RATE), 
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

endmodule
