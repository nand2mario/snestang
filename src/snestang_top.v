/* 
 * Top level for snestang
 * nand2mario, 2023.6
 */

//`define STEP_TRACE

module snestang_top (
    input sys_clk,
    input s0,                     

    // UART
    input UART_RXD,
    output UART_TXD,

    // HDMI TX
    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p,

    // LED
    output [1:0] led,

    // MicroSD
    output sd_clk,
    inout  sd_cmd,      // MOSI
    input  sd_dat0,     // MISO
    output sd_dat1,
    output sd_dat2,
    output sd_dat3,

    // SPI flash
    output flash_spi_cs_n,          // chip select
    input flash_spi_miso,           // master in slave out
    output flash_spi_mosi,          // mster out slave in
    output flash_spi_clk,           // spi clock
    output flash_spi_wp_n,          // write protect
    output flash_spi_hold_n,        // hold operations

    // dualshock controllers
    output ds_clk,
    input ds_miso,
    output ds_mosi,
    output ds_cs,
    output ds_clk2,
    input ds_miso2,
    output ds_mosi2,
    output ds_cs2,

    // SDRAM
    output sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [15:0] IO_sdram_dq,       // 16 bit bidirectional data bus
    output [12:0] O_sdram_addr,     // 13 bit multiplexed address bus
    output [1:0] O_sdram_ba,        // 4 banks
    output [1:0] O_sdram_dqm        // 
);

// Clock signals
wire wclk;                      // Actual work clock for SNES for most components, 1/2 of SNES master clock speed
wire fclk;                      // Fast clock for sdram for SDRAM
wire fclk_p;                    // 180-degree shifted fclk
wire clk27;                     // 27Mhz for hdmi clock generation
wire hclk5, hclk;               // 720p pixel clock at 74.25Mhz, and 5x high-speed
wire mclk;                      // SNES master clock at 21.6Mhz (~21.477), used for faster components like DSPn

reg resetn = 1'b0;              // reset is cleared after 4 cycles
wire pause;

reg [15:0] resetcnt = 16'hffff;
always @(posedge wclk) begin
    resetcnt <= resetcnt == 0 ? 0 : resetcnt - 1;
    if (resetcnt == 0)
//   if (resetcnt == 0 && s0)   // primer25k
//     if (resetcnt == 0 && ~s0)   // mega138k
        resetn <= 1'b1;
end

`ifndef VERILATOR

gowin_pll_27 pll_27 (
    .clkin(sys_clk),
    .clkout0(clk27)
);

// DRAM and SNES clocks
gowin_pll_snes pll_snes (
    .clkout0(wclk),             // 10.8Mhz
    .clkout1(fclk),             // 86.4Mhz
    .clkout2(fclk_p),            
    .clkout3(mclk),             // 21.6Mhz
    .clkin(clk27));

// HDMI clocks
gowin_pll_hdmi pll_hdmi (
    .clkin(clk27), .clkout0(hclk5), .clkout1(hclk)
);

`else

// Simulated clocks for verilator
assign fclk = sys_clk;
reg [2:0] fclk_cnt = 3'b0;      // 0 1 2 3 4 5 6 7
always @(posedge fclk) fclk_cnt <= fclk_cnt + 3'b1;
assign wclk = fclk_cnt[2];
assign mclk = fclk_cnt[1];

`endif

wire [23:0] ROM_ADDR;
wire ROM_CE_N, ROM_OE_N, ROM_WE_N, ROM_WORD;
wire [15:0] ROM_D;
wire [15:0] ROM_Q;
assign      ROM_Q = (ROM_WORD || ~ROM_ADDR[0]) ? cpu_port0 : { cpu_port0[7:0], cpu_port0[15:8] };

wire [16:0] WRAM_ADDR;
wire        WRAM_CE_N;
wire        WRAM_OE_N;
wire        WRAM_RD_N;
wire        WRAM_WE_N;
wire  [7:0] WRAM_SD_Q = WRAM_ADDR[0] ? cpu_port1[15:8] : cpu_port1[7:0];
wire  [7:0] WRAM_Q;
wire  [7:0] WRAM_D;
wire        wram_rd = ~WRAM_CE_N & ~WRAM_RD_N;
wire        wram_wr = ~WRAM_CE_N & ~WRAM_WE_N;

wire [19:0] BSRAM_ADDR;
wire        BSRAM_CE_N;
wire        BSRAM_OE_N;
wire        BSRAM_WE_N;
wire        BSRAM_RD_N;
wire  [7:0] BSRAM_Q = bsram_dout;
wire  [7:0] BSRAM_D;

wire [15:0] VRAM1_ADDR;
wire        VRAM1_WE_N;
wire  [7:0] VRAM1_D, VRAM1_Q;
wire [15:0] VRAM2_ADDR;
wire        VRAM2_WE_N;
wire  [7:0] VRAM2_D, VRAM2_Q;
wire        VRAM_OE_N;

wire [15:0] ARAM_ADDR;
wire        ARAM_CE_N;
wire        ARAM_OE_N;
wire        ARAM_WE_N;
wire [15:0] aram_dout;
reg         aram_lsb;       // select which byte to output
wire  [7:0] ARAM_Q = aram_lsb ? aram_dout[15:8] : aram_dout[7:0];
wire  [7:0] ARAM_D;
wire        aram_16 = 0;

wire BLEND = 1'b0;
reg        PAL;
wire       dotclk  /*verilator public*/;
wire [14:0] rgb_out  /*verilator public*/;
wire [8:0] x_out /*verilator public*/, y_out /*verilator public*/;
wire       hblankn,vblankn;

wire [15:0] audio_l /*verilator public*/, audio_r /*verilator public*/;
wire audio_ready /*verilator public*/;
wire audio_en /*XXX synthesis syn_keep=1 */;

//     .JOY1_DI(), .JOY2_DI(), .JOY_STRB(), .JOY1_CLK(), .JOY2_CLK(), 
wire [1:0] joy1_di, joy2_di;
wire joy_strb;
wire joy1_clk, joy2_clk;
wire [11:0] joy1_btns, joy2_btns;

wire [5:0] ph;
reg snes_start = 1'b0;
wire pause_snes_for_frame_sync;

wire [7:0] loader_do;
wire loader_do_valid, loading;

reg [23:0] loader_addr = 0;

reg [7:0] dbg_reg, dbg_sel; 
wire [7:0] dbg_dat_out, dbg_dat_in;
reg dbg_reg_wr = 0;
reg dbg_break = 0;

wire [7:0] rom_type;
wire [3:0] rom_size, ram_size;
wire [23:0] rom_mask, ram_mask;

wire sdram_busy;
wire refresh;
reg enable; // && ~dbg_break && ~pause;
reg loaded;

always @(posedge wclk) begin        // wait until memory initialize to start SNES
    if (~sdram_busy && ~pause_snes_for_frame_sync && loaded)
        enable <= 1;
    else 
        enable <= 0;
end

wire sysclkf_ce, sysclkr_ce;
wire overlay;

main #(
    .USE_GSU(1)
) main (
    .WCLK(wclk), .MCLK(mclk), .RESET_N(resetn & ~loading), .ENABLE(enable), 
    .SYSCLKF_CE(sysclkf_ce), .SYSCLKR_CE(sysclkr_ce), .REFRESH(refresh),

    .ROM_TYPE(rom_type), .ROM_MASK(rom_mask), .RAM_MASK(ram_mask),

    .ROM_ADDR(ROM_ADDR), .ROM_D(ROM_D), .ROM_Q(ROM_Q),
    .ROM_CE_N(ROM_CE_N), .ROM_OE_N(ROM_OE_N), .ROM_WE_N(ROM_WE_N),
    .ROM_WORD(ROM_WORD),

    .BSRAM_ADDR(BSRAM_ADDR), .BSRAM_D(BSRAM_D),	.BSRAM_Q(BSRAM_Q),
    .BSRAM_CE_N(BSRAM_CE_N), .BSRAM_OE_N(BSRAM_OE_N), .BSRAM_WE_N(BSRAM_WE_N),
    .BSRAM_RD_N(BSRAM_RD_N),

    .WRAM_ADDR(WRAM_ADDR), .WRAM_D(WRAM_D),	.WRAM_Q(WRAM_SD_Q),
    .WRAM_CE_N(WRAM_CE_N), .WRAM_OE_N(WRAM_OE_N), .WRAM_WE_N(WRAM_WE_N),
    .WRAM_RD_N(WRAM_RD_N),

    .VRAM1_ADDR(VRAM1_ADDR), .VRAM1_DI(VRAM1_Q), .VRAM1_DO(VRAM1_D),
    .VRAM1_WE_N(VRAM1_WE_N), .VRAM2_ADDR(VRAM2_ADDR), .VRAM2_DI(VRAM2_Q),
    .VRAM2_DO(VRAM2_D), .VRAM2_WE_N(VRAM2_WE_N), .VRAM_OE_N(VRAM_OE_N),

    .ARAM_ADDR(ARAM_ADDR), .ARAM_Q(ARAM_Q), .ARAM_D(ARAM_D), 
    .ARAM_CE_N(ARAM_CE_N), .ARAM_OE_N(ARAM_OE_N), .ARAM_WE_N(ARAM_WE_N),

    .BLEND(BLEND), .PAL(PAL), .HIGH_RES(), .FIELD(), .INTERLACE(),
    .DOTCLK(dotclk), .RGB_OUT(rgb_out), .HBLANKn(hblankn),
    .VBLANKn(vblankn), .X_OUT(x_out), .Y_OUT(y_out),

    .JOY1_DI(overlay?2'b11:joy1_di), .JOY2_DI(overlay?2'b11:joy2_di), .JOY_STRB(joy_strb), 
    .JOY1_CLK(joy1_clk), .JOY2_CLK(joy2_clk), 

    .AUDIO_L(audio_l), .AUDIO_R(audio_r), .AUDIO_READY(audio_ready), .AUDIO_EN(audio_en),

    .JOY1_P6(), .JOY2_P6(), .JOY2_P6_in(), .DOT_CLK_CE(), .EXT_RTC(),
    .SPC_MODE(), .IO_ADDR(), .IO_DAT(), .IO_WR(), 

    .DBG_SEL(dbg_sel), .DBG_REG(dbg_reg), .DBG_REG_WR(dbg_reg_wr), .DBG_DAT_IN(dbg_dat_in), 
    .DBG_DAT_OUT(dbg_dat_out), .DBG_BREAK(dbg_break)
);

// SDRAM for SNES ROM, WRAM and ARAM
reg [22:0] cpu_addr; 
wire [15:0] cpu_port0;
wire [15:0] cpu_port1;
reg        cpu_port;
reg  [1:0] cpu_ds;
reg [15:0] cpu_din;
reg        cpu_rd, cpu_wr;
reg        f2, r2;

assign sdram_clk = fclk_p;
wire aram_rd = ~ARAM_CE_N & ~ARAM_OE_N;
wire aram_wr = ~ARAM_CE_N & ~ARAM_WE_N;
always @(posedge wclk) if (aram_rd) aram_lsb <= ARAM_ADDR[0];

reg bsram_rd, bsram_wr;
reg [19:0] bsram_addr;
reg [7:0] bsram_din;
wire [7:0] bsram_dout;

wire rv_rd, rv_wr;
wire [15:0] rv_din, rv_dout;
wire [22:0] rv_addr;
wire [1:0] rv_ds;
wire rv_wait;

// Generate SDRAM signals
always @(posedge wclk) begin
    reg bsram_rd_t = ~BSRAM_CE_N & (~BSRAM_RD_N || rom_type[7:4] == 4'hC) & f2;
    f2 <= sysclkf_ce && enable;
    r2 <= sysclkr_ce && enable;
    cpu_rd <= 0;
    cpu_wr <= 0;
    cpu_addr <= 0;
    cpu_din <= 0;
    cpu_ds <= 0;
    cpu_port <= 0;
    if (loading && loader_do_valid) begin
        cpu_addr <= loader_addr[22:0];
        cpu_wr <= 1;
        cpu_din <= {loader_do, loader_do};
        cpu_ds <= {loader_addr[0], ~loader_addr[0]};
    end else if (~ROM_CE_N && ~bsram_rd_t && f2) begin     // ROM reads on R cycles
        cpu_rd <= 1;
        cpu_addr <= ROM_ADDR[22:0];
        cpu_ds <= 2'b11;
    end else if (wram_rd | wram_wr) begin
        cpu_addr <= {6'b111_111, WRAM_ADDR[16:0]};  // 7E,7F:0000-FFFF, total 128KB
        cpu_ds <= {WRAM_ADDR[0], ~WRAM_ADDR[0]};
        cpu_din <= {WRAM_D, WRAM_D};        
        cpu_port <= 1;
        if (wram_rd && f2) cpu_rd <= 1;
        if (wram_wr && r2) cpu_wr <= 1;
    end

    bsram_addr <= BSRAM_ADDR;
    bsram_din <= BSRAM_D;
    bsram_rd <= bsram_rd_t;
    bsram_wr <= ~BSRAM_CE_N & ~BSRAM_WE_N & r2;
end

// VRAM signals are passed on in the same cycle
reg [14:0] vram1_addr_old, vram2_addr_old;
reg vram_oe_n_old;
// a new VRAM read request is present - this removes duplicate requests
wire vram1_new_read = ~VRAM_OE_N && (vram_oe_n_old || vram1_addr_old != VRAM1_ADDR[14:0]);
wire vram2_new_read = ~VRAM_OE_N && (vram_oe_n_old || vram2_addr_old != VRAM2_ADDR[14:0]);
// vram1/vram2 reading different addresses, then delay vram2 read one cycle
wire vram2_read_delay = vram1_new_read && vram2_new_read && VRAM1_ADDR != VRAM2_ADDR;
reg vram2_read_delay_r;     
always @(posedge wclk) begin
    vram_oe_n_old <= VRAM_OE_N;
    vram1_addr_old <= VRAM1_ADDR[14:0];
    vram2_addr_old <= VRAM2_ADDR[14:0];
    vram2_read_delay_r <= vram2_read_delay;
end

sdram_snes sdram(
    .clk(fclk), .clkref(wclk), .resetn(resetn), .busy(sdram_busy),

    // SDRAM pins
    .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba), 
    .SDRAM_nCS(O_sdram_cs_n), .SDRAM_nWE(O_sdram_wen_n), .SDRAM_nRAS(O_sdram_ras_n), 
    .SDRAM_nCAS(O_sdram_cas_n), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm), 

    // CPU accesses
    .cpu_addr(cpu_addr[22:1]), .cpu_din(cpu_din), .cpu_port(cpu_port), 
    .cpu_port0(cpu_port0), .cpu_port1(cpu_port1), .cpu_rd(cpu_rd), 
    .cpu_wr(cpu_wr), .cpu_ds(cpu_ds),

    // BSRAM accesses
    .bsram_addr(bsram_addr), .bsram_dout(bsram_dout), .bsram_din(bsram_din),
    .bsram_rd(bsram_rd), .bsram_wr(bsram_wr),

    // ARAM accesses
    .aram_16(aram_16), .aram_addr(ARAM_ADDR), .aram_din({ARAM_D, ARAM_D}), 
    .aram_dout(aram_dout), .aram_wr(aram_wr), .aram_rd(aram_rd),

    .vram1_rd(vram1_new_read), .vram1_wr(~VRAM1_WE_N), 
    .vram2_rd(vram2_new_read & ~vram2_read_delay | vram2_read_delay_r), .vram2_wr(~VRAM2_WE_N),
    .vram1_addr(VRAM1_ADDR[14:0]), .vram2_addr(VRAM2_ADDR[14:0]), 
    .vram1_din(VRAM1_D), .vram2_din(VRAM2_D),
    .vram1_dout(VRAM1_Q), .vram2_dout(VRAM2_Q),

    // IOSys risc-v softcore
    .rv_addr(rv_addr[22:1]), .rv_din(rv_din), .rv_ds(rv_ds), .rv_dout(rv_dout),
    .rv_rd(rv_rd), .rv_wr(rv_wr), .rv_wait(rv_wait)
);

// FPGA block RAM for SNES VRAM 
// vram vram(
//     .clk(wclk), 
//     .addra(VRAM1_ADDR[14:0]), .rda(vram1_new_read), .wra(~VRAM1_WE_N), 
//     .dina(VRAM1_D), .douta(VRAM1_Q), 
//     .addrb(VRAM2_ADDR[14:0]), .rdb(vram2_new_read), .wrb(~VRAM2_WE_N), 
//     .dinb(VRAM2_D), .doutb(VRAM2_Q)
// );

reg loading_r;
always @(posedge wclk) begin
    if (~resetn) begin
        loading_r <= 0;
        loaded <= 0;
    end else begin
        loading_r <= loading;
        if (loader_do_valid)
            loader_addr <= loader_addr + 24'd1; 
        if (loading & ~loading_r) begin
            loader_addr <= 0;
            loaded <= 0;
        end
        if (~loading & loading_r)
            loaded <= 1;
    end
end

`ifndef VERILATOR

// 2 controllers, convert from DS2 to SNES
ds2snes joy1 (
    .clk(wclk),
    .snes_joy_strb(joy_strb), .snes_joy_clk(joy1_clk), .snes_joy_di(joy1_di[0]),
    .snes_buttons(joy1_btns),
    .ds_clk(ds_clk), .ds_miso(ds_miso), .ds_mosi(ds_mosi), .ds_cs(ds_cs) 
);
ds2snes joy2 (
    .clk(wclk),
    .snes_joy_strb(joy_strb), .snes_joy_clk(joy2_clk), .snes_joy_di(joy2_di[0]),
    .snes_buttons(joy2_btns),
    .ds_clk(ds_clk2), .ds_miso(ds_miso2), .ds_mosi(ds_mosi2), .ds_cs(ds_cs2) 
);
assign joy1_di[1] = 0;  // P3
assign joy2_di[1] = 0;  // P4

wire overlay;
wire [14:0] overlay_color;
wire [10:0] overlay_x;
wire [9:0] overlay_y;

wire [7:0] dbg_dat_out_loader;

snes2hdmi s2h(
    .clk(wclk), .resetn(resetn), .snes_refresh(refresh),
    .pause_snes_for_frame_sync(pause_snes_for_frame_sync),
    .dotclk(dotclk), .hblank(~hblankn),.vblank(~vblankn),.rgb5(rgb_out),
    .xs(x_out), .ys(y_out), 
    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color), 
    .audio_l(audio_l), .audio_r(audio_r), .audio_ready(audio_ready), .audio_en(audio_en),
    .clk_pixel(hclk),.clk_5x_pixel(hclk5),.locked(1'b1),
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p),
    .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
);

// IOSys for menu, rom loading...
iosys iosys (
    .wclk(wclk), .hclk(hclk), .resetn(resetn),

    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color),
    .joy1(joy1_btns), .joy2(joy2_btns),

    .rom_loading(loading), .rom_do(loader_do), .rom_do_valid(loader_do_valid), 
    .rom_type(rom_type), .rom_mask(rom_mask), .ram_mask(ram_mask),
    .rom_size(rom_size), .ram_size(ram_size),
    .ram_busy(sdram_busy),

    .rv_addr(rv_addr), .rv_din(rv_din), .rv_ds(rv_ds), .rv_dout(rv_dout),
    .rv_rd(rv_rd), .rv_wr(rv_wr), .rv_wait(rv_wait),

    .flash_spi_cs_n(flash_spi_cs_n), .flash_spi_miso(flash_spi_miso),
    .flash_spi_mosi(flash_spi_mosi), .flash_spi_clk(flash_spi_clk),
    .flash_spi_wp_n(flash_spi_wp_n), .flash_spi_hold_n(flash_spi_hold_n),

    .uart_tx(UART_TXD), .uart_rx(UART_RXD),

    .sd_clk(sd_clk), .sd_cmd(sd_cmd), .sd_dat0(sd_dat0), .sd_dat1(sd_dat1),
    .sd_dat2(sd_dat2), .sd_dat3(sd_dat3)
);



// Test rom
//testrom rom (
//    .clk(wclk), .addr(rom_addr), .dout(rom_do)
//);

`else

// test loader with embedded rom
test_loader test_loader (
    .wclk(wclk), .resetn(resetn),

    .dout(loader_do), .dout_valid(loader_do_valid),

    .map_ctrl(rom_type), .rom_size(rom_size),
    .rom_mask(rom_mask), .ram_mask(ram_mask),
    
    .loading(loading), .fail()
);

// test audio sink: FIFO-like rate limiting to sound sample generation
reg [3:0] sample_counter = 0;
always @(posedge wclk) begin
    if (audio_ready)
        sample_counter <= 0;
    else
        sample_counter <= sample_counter == 15 ? 15 : sample_counter + 1;
end
assign audio_en = sample_counter == 15;


// test video sync by turning on pause_snes_for_frame_sync periodically
reg test_halt_snes, test_sync_done;
reg [3:0] test_halt_cnt = 0;
assign pause_snes_for_frame_sync = test_halt_snes;

always @(posedge wclk) begin    // halt SNES during snes dram refresh on line 2
    if (~resetn) begin
        test_halt_cnt <= 0;
        test_halt_snes <= 0;
        test_sync_done <= 0;
    end else begin
        if (~test_sync_done) begin
            if (~test_halt_snes) begin
                if (y_out[7:0] == 2 && refresh) begin
                    test_halt_snes <= 1;
                    test_halt_cnt <= 4'd12;        // halt snes for 13 cycles
                end
            end else begin
                if (test_halt_cnt != 0) begin
                    test_halt_cnt <= test_halt_cnt - 4'd1;
                end else begin
                    test_halt_snes <= 0;
                    test_sync_done <= 1;
                end                            
            end
        end else if (y_out[7:0] == 8'd200)
            test_sync_done <= 0;
    end
end

`endif


`ifndef VERILATOR

reg [19:0] timer;           // 21 times per second

reg [11:0] reached;

// LED control
assign led = ~s0 ? ~(reached[9:5]) : ~{reached[4:0]};

// a simple memory access logger
// localparam mlog_len = 16;
// reg [23:0] mlog_a[0:mlog_len-1];
// reg [7:0] mlog_q[0:mlog_len-1];
// reg [$clog2(mlog_len)-1:0] mlog_i = 0;
// reg mlog_active;

// reg cpu_rd_r;
// reg [23:0] cpu_addr_r;

// always @(posedge wclk) begin
//     cpu_rd_r <= cpu_rd;
//     cpu_addr_r <= cpu_addr;
//     if (~loading) begin
//         // result from active read
//         if (mlog_active) begin
//             mlog_q[mlog_i] <= ROM_Q[7:0];
//             mlog_active <= 0;
//             if (mlog_i != mlog_len - 1)
//                 mlog_i <= mlog_i + 1;
//         end

//         // start next read
//         if (cpu_rd && (~cpu_rd_r || cpu_addr != cpu_addr_r) && mlog_i != mlog_len - 1) begin
//             mlog_active <= 1;
//             mlog_a[mlog_i] <= cpu_addr;
//         end
//     end
// end

// end of memory access logger

// assign led = s1 ? ~{reach_wai, reach_string_loop, reach_charset_loop, reach_set_palette, reach_start, snes_start} :  // 000011 means ClearVRAM did not return
//                   ~{reach_rts, reach_enddma, reach_startdma, reach_clearvram, reach_start, reach_reset_vector};      // 001111 means DMA started but did not end

// Serial debugger and loader data source
/*
debugger dbg (
    .clk(wclk), .resetn(resetn),
    .uart_rx(UART_RXD), .uart_tx(UART_TXD),

    .dbg_sel(dbg_sel), .dbg_reg(dbg_reg), 
    .dbg_dat_out(dbg_sel[7] ? dbg_dat_out_loader : 
                 dbg_sel[2] ? dbg_dat_out_mem :     // take over WRAM's slot
                 dbg_dat_out),
    .dbg_reg_wr(dbg_reg_wr), .dbg_dat_in(dbg_dat_in), 

    .pause(pause), .last_cycle(last_cycle), .last_phase(last_phase),

    .serial_reset(serial_reset), .serial_data(serial_data), .serial_data_valid(serial_data_valid),
    .loader_done(loader_done), .loader_fail(loader_fail),

    .dbg_state(dbg_state)
);
*/

//
// Print control
//
/*
`include "print.v"
localparam BAUDRATE=115200;

defparam tx.uart_freq=BAUDRATE;
defparam tx.clk_freq=10_800_000;
assign print_clk = wclk;
assign UART_TXD = uart_txp;

wire tick;
assign tick = (timer == 20'b0);

reg [19:0] frame_sync_cycles = 20'b0;

always @(posedge wclk) begin
    if (pause_snes_for_frame_sync && frame_sync_cycles != 20'hfffff)
        frame_sync_cycles = frame_sync_cycles + 1;
end

reg [23:0] dbg_sd_sector;
reg [$clog2(mlog_len)-1:0] mlog_prt = 0;
//wire mlog_prt_done = mlog_prt == mlog_len - 1;
reg [2:0] prt_state = 0;
// 0:loader, 1:memory header, 2: memory content, 3: cpu stat

always @(posedge wclk) begin
    // print CA every tick
    timer <= timer + 20'd1;
    case (timer) 
    20'h00000: `print("map_ctrl=", STR);
    20'h10000: `print(rom_type, 1);
    20'h20000: `print(", rom_size=", STR);
    20'h30000: `print({4'b0, rom_size}, 1);
    20'h40000: `print(", ram_size=", STR);
    20'h50000: `print({4'b0, ram_size}, 1);
    20'h60000: `print(", btns=", STR);
    20'h70000: `print({4'b0, joy1_btns}, 2);
    20'h80000: `print(", addr=", STR);
    20'h90000: `print(loader_addr, 3);
    20'hA0000: `print(", loading=", STR);
    20'hA8000: `print({7'b0, loading}, 1);

    20'hf0000: `print("\n", STR);
    endcase
end
*/

`endif

endmodule
