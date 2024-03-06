// This adds memory map and extension chips to SNES.

module main (
	// input             WCLK,
	input			  MCLK,
	input             RESET_N,
	input             ENABLE,

	output 			  SYSCLKF_CE,		// snes system clock falling cycle (for CPU/DMA control work and DMA memory writes)
	output            SYSCLKR_CE,		// snes system clock rising cycle (for memory reads/writes)

	output		      REFRESH,

	input       [7:0] ROM_TYPE,
	input      [23:0] ROM_MASK,
	input      [23:0] RAM_MASK,

	output reg [23:0] ROM_ADDR,
	output reg [15:0] ROM_D,
	input      [15:0] ROM_Q,
	output reg        ROM_CE_N,
	output reg        ROM_OE_N,
	output reg        ROM_WE_N,
	output reg        ROM_WORD,

	output reg [19:0] BSRAM_ADDR,
	output reg  [7:0] BSRAM_D,
	input       [7:0] BSRAM_Q,
	output reg        BSRAM_CE_N,
	output reg        BSRAM_OE_N,
	output reg        BSRAM_WE_N,
	output            BSRAM_RD_N,

	output     [16:0] WRAM_ADDR,
	output      [7:0] WRAM_D,
	input       [7:0] WRAM_Q,
	output            WRAM_CE_N,
	output            WRAM_OE_N,
	output            WRAM_WE_N,
	output            WRAM_RD_N,

	output     [15:0] VRAM1_ADDR,
	input       [7:0] VRAM1_DI,
	output      [7:0] VRAM1_DO,
	output            VRAM1_WE_N,
	output     [15:0] VRAM2_ADDR,
	input       [7:0] VRAM2_DI,
	output      [7:0] VRAM2_DO,
	output            VRAM2_WE_N,
	output            VRAM_OE_N,

	output     [15:0] ARAM_ADDR,
	output      [7:0] ARAM_D,
	input       [7:0] ARAM_Q,
	output            ARAM_CE_N,
	output            ARAM_OE_N,
	output            ARAM_WE_N,

	// output            GSU_ACTIVE,
	// input             GSU_TURBO,

	input             BLEND,
	input             PAL,
	input		      DIS_SHORTLINE,
	output            HIGH_RES,
	output            FIELD,
	output            INTERLACE,
	output            DOTCLK,
    output     [14:0] RGB_OUT,
	output            HBLANKn,
	output            VBLANKn,
    output     [8:0]  X_OUT,
    output     [8:0]  Y_OUT,

	input       [1:0] JOY1_DI,
	input       [1:0] JOY2_DI,
	output            JOY_STRB,
	output            JOY1_CLK,
	output            JOY2_CLK,
	output            JOY1_P6,
	output            JOY2_P6,
	input             JOY2_P6_in,

	output            DOT_CLK_CE,

	input      [64:0] EXT_RTC,

	// input             GG_EN,
	// input     [128:0] GG_CODE,
	// input             GG_RESET,
	// output            GG_AVAILABLE,

	input             SPC_MODE,

	input      [16:0] IO_ADDR,
	input      [15:0] IO_DAT,
	input             IO_WR,

	// input             TURBO,
	// output            TURBO_ALLOW,

	// output     [15:0] MSU_TRACK_NUM,
	// output            MSU_TRACK_REQUEST,
	// input             MSU_TRACK_MOUNTING,
	// input             MSU_TRACK_MISSING,
	// output      [7:0] MSU_VOLUME,
	// input             MSU_AUDIO_STOP,
	// output            MSU_AUDIO_REPEAT,
	// output            MSU_AUDIO_PLAYING,
	// output     [31:0] MSU_DATA_ADDR,
	// input       [7:0] MSU_DATA,
	// input             MSU_DATA_ACK,
	// output            MSU_DATA_SEEK,
	// output            MSU_DATA_REQ,
	// input             MSU_ENABLE,

	output     [15:0] AUDIO_L,
	output     [15:0] AUDIO_R,
    output            AUDIO_READY,
    input             AUDIO_EN,


    input       [7:0] DBG_SEL,
    input       [7:0] DBG_REG,
    input 			  DBG_REG_WR,
    input       [7:0] DBG_DAT_IN,
    output      [7:0] DBG_DAT_OUT,
    output            DBG_BREAK	
);

parameter USE_DLH = 1'b1;
parameter USE_CX4 = 1'b0;
parameter USE_SDD1 = 1'b0;
parameter USE_GSU = 1'b0;
parameter USE_SA1 = 1'b0;
parameter USE_DSPn = 1'b0;
parameter USE_SPC7110 = 1'b0;
parameter USE_BSX = 1'b0;
parameter USE_MSU = 1'b0;

wire [23:0] CA;
wire        CPURD_N;
wire        CPUWR_N;
wire        CPURD_CYC_N;
reg   [7:0] DI;
wire  [7:0] DO;
wire        RAMSEL_N;
wire        ROMSEL_N;
reg         IRQ_N;
wire  [7:0] PA;
wire        PARD_N;
wire        PAWR_N;

wire  [5:0] MAP_ACTIVE;

SNES SNES
(
	.MCLK(MCLK), .RST_N(RESET_N), .ENABLE(ENABLE),

	.CA(CA), .CPURD_N(CPURD_N),	.CPUWR_N(CPUWR_N), .CPURD_CYC_N(CPURD_CYC_N),
	.PA(PA), .PARD_N(PARD_N), .PAWR_N(PAWR_N), .DI(DI),	.DO(DO),
	.RAMSEL_N(RAMSEL_N), .ROMSEL_N(ROMSEL_N),

	.SYSCLKF_CE(SYSCLKF_CE), .SYSCLKR_CE(SYSCLKR_CE), .DOT_CLK_CE(DOT_CLK_CE),
	.SNES_REFRESH(REFRESH),

	.IRQ_N(IRQ_N),

	.WRAM_ADDR(WRAM_ADDR), .WRAM_D(WRAM_D),	.WRAM_Q(WRAM_Q),
	.WRAM_CE_N(WRAM_CE_N), .WRAM_OE_N(WRAM_OE_N), .WRAM_WE_N(WRAM_WE_N),
	.WRAM_RD_N(WRAM_RD_N),

	.VRAM_ADDRA(VRAM1_ADDR), .VRAM_ADDRB(VRAM2_ADDR), .VRAM_DAI(VRAM1_DI),
	.VRAM_DBI(VRAM2_DI), .VRAM_DAO(VRAM1_DO), .VRAM_DBO(VRAM2_DO),
	.VRAM_RD_N(VRAM_OE_N), .VRAM_WRA_N(VRAM1_WE_N), .VRAM_WRB_N(VRAM2_WE_N),

	.ARAM_ADDR(ARAM_ADDR), .ARAM_D(ARAM_D), .ARAM_Q(ARAM_Q),
	.ARAM_CE_N(ARAM_CE_N), .ARAM_OE_N(ARAM_OE_N), .ARAM_WE_N(ARAM_WE_N),

	.JOY1_DI(JOY1_DI), .JOY2_DI(JOY2_DI), .JOY_STRB(JOY_STRB),
	.JOY1_CLK(JOY1_CLK), .JOY2_CLK(JOY2_CLK),//.JOY1_P6(JOY1_P6),
	// .JOY2_P6(JOY2_P6),
	// .JOY2_P6_IN(JOY2_P6_IN),

	.BLEND(BLEND), .PAL(PAL), .DIS_SHORTLINE(DIS_SHORTLINE),
	.HIGH_RES(HIGH_RES), .FIELD_OUT(FIELD), .INTERLACE(INTERLACE), .DOTCLK(DOTCLK),
	.V224_MODE(),

	.RGB_OUT(RGB_OUT), .HDE(HBLANKn), .VDE(VBLANKn), .HSYNC(), .VSYNC(),
    .X_OUT(X_OUT), .Y_OUT(Y_OUT),

	.AUDIO_L(AUDIO_L), .AUDIO_R(AUDIO_R), .AUDIO_READY(AUDIO_READY),
    .AUDIO_EN(AUDIO_EN),

	// .gg_en(GG_EN),
	// .gg_code(GG_CODE),
	// .gg_reset(GG_RESET),
	// .gg_available(GG_AVAILABLE),
	
	// .SPC_MODE(SPC_MODE),
	
	// .IO_ADDR(IO_ADDR),
	// .IO_DAT(IO_DAT),
	// .IO_WR(IO_WR),
	
	// .DBG_BG_EN(DBG_BG_EN),
	// .DBG_CPU_EN(DBG_CPU_EN),
	
	// .TURBO(TURBO),

	.DBG_SEL(DBG_SEL), .DBG_REG(DBG_REG), .DBG_REG_WR(DBG_REG_WR), 
	.DBG_DAT_IN(DBG_DAT_IN), .DBG_DAT_OUT(DBG_DAT_OUT), .DBG_BREAK(DBG_BREAK)
);

wire  [7:0] MSU_DO;
wire        MSU_SEL;

generate
if (USE_MSU == 1'b1) begin
MSU MSU
(
	.CLK(MCLK),
	.RST_N(RESET_N),
	.ENABLE(MSU_ENABLE),

	.RD_N(CPURD_N),
	.WR_N(CPUWR_N),
	.SYSCLKF_CE(SYSCLKF_CE),

	.ADDR(CA),
	.DIN(DO),
	.DOUT(MSU_DO),
	.MSU_SEL(MSU_SEL),

	.data_addr(MSU_DATA_ADDR),
	.data(MSU_DATA),
	.data_ack(MSU_DATA_ACK),
	.data_seek(MSU_DATA_SEEK),
	.data_req(MSU_DATA_REQ),

	.track_num(MSU_TRACK_NUM),
	.track_request(MSU_TRACK_REQUEST),
	.track_mounting(MSU_TRACK_MOUNTING),

	.status_track_missing(MSU_TRACK_MISSING),
	.status_audio_repeat(MSU_AUDIO_REPEAT),
	.status_audio_playing(MSU_AUDIO_PLAYING),
	.audio_stop(MSU_AUDIO_STOP),

	.volume(MSU_VOLUME)
);
end else begin
	assign MSU_DO  = 0;
	assign MSU_SEL = 0;
	// assign MSU_TRACK_NUM = 0;
	// assign MSU_TRACK_REQUEST = 0;
	// assign MSU_VOLUME = 0;
	// assign MSU_AUDIO_REPEAT = 0;
	// assign MSU_AUDIO_PLAYING = 0;
end
endgenerate

assign      BSRAM_RD_N = CPURD_CYC_N;

wire  [7:0] DLH_DO;
wire        DLH_IRQ_N;
wire [23:0] DLH_ROM_ADDR;
wire        DLH_ROM_CE_N;
wire        DLH_ROM_OE_N;
wire        DLH_ROM_WORD;
wire [19:0] DLH_BSRAM_ADDR;
wire  [7:0] DLH_BSRAM_D;
wire        DLH_BSRAM_CE_N;
wire        DLH_BSRAM_OE_N;
wire        DLH_BSRAM_WE_N;

generate
if (USE_DLH == 1'b1) begin

DSP_LHRomMap #(.USE_DSPn(USE_DSPn)) DSP_LHRomMap
(
	// .WCLK(WCLK),
	.MCLK(MCLK),
	.RST_N(RESET_N),
    .ENABLE(1'b1),

	.CA(CA),
	.DI(DO),
	.DO(DLH_DO),
	.CPURD_N(CPURD_N),
	.CPUWR_N(CPUWR_N),
	
	.PA(PA),
	.PARD_N(PARD_N),
	.PAWR_N(PAWR_N),

	.ROMSEL_N(ROMSEL_N),
	.RAMSEL_N(RAMSEL_N),

	.SYSCLKF_CE(SYSCLKF_CE),
	.SYSCLKR_CE(SYSCLKR_CE),
	.REFRESH(REFRESH),

	.IRQ_N(DLH_IRQ_N),

	.ROM_ADDR(DLH_ROM_ADDR),
	.ROM_Q(ROM_Q),
	.ROM_CE_N(DLH_ROM_CE_N),
	.ROM_OE_N(DLH_ROM_OE_N),
	.ROM_WORD(DLH_ROM_WORD),

	.BSRAM_ADDR(DLH_BSRAM_ADDR),
	.BSRAM_D(DLH_BSRAM_D),
	.BSRAM_Q(BSRAM_Q),
	.BSRAM_CE_N(DLH_BSRAM_CE_N),
	.BSRAM_OE_N(DLH_BSRAM_OE_N),
	.BSRAM_WE_N(DLH_BSRAM_WE_N),

    .MAP_ACTIVE(),
	.MAP_CTRL(ROM_TYPE),
	.ROM_MASK(ROM_MASK),
	.BSRAM_MASK(RAM_MASK),

	.EXT_RTC(EXT_RTC)
);
end else begin
	assign DLH_DO = 0;
	assign DLH_IRQ_N = 1;
	assign DLH_ROM_ADDR = 0;
	assign DLH_ROM_CE_N = 1;
	assign DLH_ROM_OE_N = 1;
	assign DLH_BSRAM_ADDR = 0;
	assign DLH_BSRAM_D = 0;
	assign DLH_BSRAM_CE_N = 1;
	assign DLH_BSRAM_OE_N = 1;
	assign DLH_BSRAM_WE_N = 1;
	assign DLH_ROM_WORD = 0;
end
endgenerate

wire [7:0]  CX4_DO;
wire        CX4_IRQ_N;
wire [22:0] CX4_ROM_ADDR;
wire        CX4_ROM_CE_N;
wire        CX4_ROM_OE_N;
wire        CX4_ROM_WORD;
wire [19:0] CX4_BSRAM_ADDR;
wire [7:0]  CX4_BSRAM_D;
wire        CX4_BSRAM_CE_N;
wire        CX4_BSRAM_OE_N;
wire        CX4_BSRAM_WE_N;

generate
if (USE_CX4 == 1'b1) begin

CX4Map CX4Map
(
	.mclk(MCLK),
	.rst_n(RESET_N),

	.ca(CA),
	.di(DO),
	.DO(CX4_DO),
	.cpurd_n(CPURD_N),
	.cpuwr_n(CPUWR_N),

	.pa(PA),
	.pard_n(PARD_N),
	.pawr_n(PAWR_N),

	.romsel_n(ROMSEL_N),
	.ramsel_n(RAMSEL_N),

	.sysclkf_ce(SYSCLKF_CE),
	.sysclkr_ce(SYSCLKR_CE),
	.refresh(REFRESH),

	.irq_n(CX4_IRQ_N),

	.rom_addr(CX4_ROM_ADDR),
	.rom_q(ROM_Q),
	.rom_ce_n(CX4_ROM_CE_N),
	.rom_oe_n(CX4_ROM_OE_N),
	.rom_word(CX4_ROM_WORD),

	.bsram_addr(CX4_BSRAM_ADDR),
	.bsram_d(CX4_BSRAM_D),
	.bsram_q(BSRAM_Q),
	.bsram_ce_n(CX4_BSRAM_CE_N),
	.bsram_oe_n(CX4_BSRAM_OE_N),
	.bsram_we_n(CX4_BSRAM_WE_N),

	.map_active(MAP_ACTIVE[0]),
	.map_ctrl(ROM_TYPE),
	.rom_mask(ROM_MASK),
	.bsram_mask(RAM_MASK)
);
end else
assign MAP_ACTIVE[0] = 0;
endgenerate

wire [7:0]  SDD_DO;
wire        SDD_IRQ_N;
wire [22:0] SDD_ROM_ADDR;
wire        SDD_ROM_CE_N;
wire        SDD_ROM_OE_N;
wire        SDD_ROM_WORD;
wire [19:0] SDD_BSRAM_ADDR;
wire [7:0]  SDD_BSRAM_D;
wire        SDD_BSRAM_CE_N;
wire        SDD_BSRAM_OE_N;
wire        SDD_BSRAM_WE_N;

generate
if (USE_SDD1 == 1'b1) begin

SDD1Map SDD1Map
(
	.mclk(MCLK),
	.rst_n(RESET_N),

	.ca(CA),
	.di(DO),
	.DO(SDD_DO),
	.cpurd_n(CPURD_N),
	.cpuwr_n(CPUWR_N),

	.pa(PA),
	.pard_n(PARD_N),
	.pawr_n(PAWR_N),

	.romsel_n(ROMSEL_N),
	.ramsel_n(RAMSEL_N),

	.sysclkf_ce(SYSCLKF_CE),
	.sysclkr_ce(SYSCLKR_CE),
	.refresh(REFRESH),

	.irq_n(SDD_IRQ_N),

	.rom_addr(SDD_ROM_ADDR),
	.rom_q(ROM_Q),
	.rom_ce_n(SDD_ROM_CE_N),
	.rom_oe_n(SDD_ROM_OE_N),
	.rom_word(SDD_ROM_WORD),

	.bsram_addr(SDD_BSRAM_ADDR),
	.bsram_d(SDD_BSRAM_D),
	.bsram_q(BSRAM_Q),
	.bsram_ce_n(SDD_BSRAM_CE_N),
	.bsram_oe_n(SDD_BSRAM_OE_N),
	.bsram_we_n(SDD_BSRAM_WE_N),

	.map_active(MAP_ACTIVE[1]),
	.map_ctrl(ROM_TYPE),
	.rom_mask(ROM_MASK),
	.bsram_mask(RAM_MASK)
);
end else
assign MAP_ACTIVE[1] = 0;
endgenerate

wire [7:0]  GSU_DO;
wire        GSU_IRQ_N;
wire [22:0] GSU_ROM_ADDR;
wire        GSU_ROM_CE_N;
wire        GSU_ROM_OE_N;
wire        GSU_ROM_WORD;
wire [19:0] GSU_BSRAM_ADDR;
wire [7:0]  GSU_BSRAM_D;
wire        GSU_BSRAM_CE_N;
wire        GSU_BSRAM_OE_N;
wire        GSU_BSRAM_WE_N;
wire 		GSU_TURBO;

generate
if (USE_GSU == 1'b1) begin

GSUMap GSUMap
(
	.MCLK(MCLK),
	.RST_N(RESET_N),
	.ENABLE(1'b1),
	.CLKREF(DOT_CLK_CE),

	.CA(CA),
	.DI(DO),
	.DO(GSU_DO),
	.CPURD_N(CPURD_N),
	.CPUWR_N(CPUWR_N),

	.PA(PA),
	.PARD_N(PARD_N),
	.PAWR_N(PAWR_N),

	.ROMSEL_N(ROMSEL_N),
	.RAMSEL_N(RAMSEL_N),

	.SYSCLKF_CE(SYSCLKF_CE),
	.SYSCLKR_CE(SYSCLKR_CE),
	.REFRESH(REFRESH),

	.IRQ_N(GSU_IRQ_N),

	.ROM_ADDR(GSU_ROM_ADDR),
	.ROM_Q(ROM_Q),
	.ROM_CE_N(GSU_ROM_CE_N),
	.ROM_OE_N(GSU_ROM_OE_N),
	.ROM_WORD(GSU_ROM_WORD),

	.BSRAM_ADDR(GSU_BSRAM_ADDR),
	.BSRAM_D(GSU_BSRAM_D),
	.BSRAM_Q(BSRAM_Q),
	.BSRAM_CE_N(GSU_BSRAM_CE_N),
	.BSRAM_OE_N(GSU_BSRAM_OE_N),
	.BSRAM_WE_N(GSU_BSRAM_WE_N),

	.MAP_ACTIVE(MAP_ACTIVE[2]),
	.MAP_CTRL(ROM_TYPE),
	.ROM_MASK(ROM_MASK),
	.BSRAM_MASK(RAM_MASK),

	.TURBO(GSU_TURBO)
);
end else
assign MAP_ACTIVE[2] = 0;
endgenerate

// assign GSU_ACTIVE = MAP_ACTIVE[2];

wire [7:0]  SA1_DO;
wire        SA1_IRQ_N;
wire [22:0] SA1_ROM_ADDR;
wire        SA1_ROM_CE_N;
wire        SA1_ROM_OE_N;
wire        SA1_ROM_WORD;
wire [19:0] SA1_BSRAM_ADDR;
wire [7:0]  SA1_BSRAM_D;
wire        SA1_BSRAM_CE_N;
wire        SA1_BSRAM_OE_N;
wire        SA1_BSRAM_WE_N;

generate
if (USE_SA1 == 1'b1) begin

SA1Map SA1Map
(
	.mclk(MCLK),
	.rst_n(RESET_N),

	.ca(CA),
	.di(DO),
	.DO(SA1_DO),
	.cpurd_n(CPURD_N),
	.cpuwr_n(CPUWR_N),

	.pa(PA),
	.pard_n(PARD_N),
	.pawr_n(PAWR_N),

	.romsel_n(ROMSEL_N),
	.ramsel_n(RAMSEL_N),

	.sysclkf_ce(SYSCLKF_CE),
	.sysclkr_ce(SYSCLKR_CE),
	.refresh(REFRESH),

	.pal(PAL),

	.irq_n(SA1_IRQ_N),

	.rom_addr(SA1_ROM_ADDR),
	.rom_q(ROM_Q),
	.rom_ce_n(SA1_ROM_CE_N),
	.rom_oe_n(SA1_ROM_OE_N),
	.rom_word(SA1_ROM_WORD),

	.bsram_addr(SA1_BSRAM_ADDR),
	.bsram_d(SA1_BSRAM_D),
	.bsram_q(BSRAM_Q),
	.bsram_ce_n(SA1_BSRAM_CE_N),
	.bsram_oe_n(SA1_BSRAM_OE_N),
	.bsram_we_n(SA1_BSRAM_WE_N),

	.map_active(MAP_ACTIVE[3]),
	.map_ctrl(ROM_TYPE),
	.rom_mask(ROM_MASK),
	.bsram_mask(RAM_MASK)
);
end else
assign MAP_ACTIVE[3] = 0;
endgenerate

wire [7:0]  SPC7110_DO;
wire        SPC7110_IRQ_N;
wire [22:0] SPC7110_ROM_ADDR;
wire        SPC7110_ROM_CE_N;
wire        SPC7110_ROM_OE_N;
wire        SPC7110_ROM_WORD;
wire [19:0] SPC7110_BSRAM_ADDR;
wire [7:0]  SPC7110_BSRAM_D;
wire        SPC7110_BSRAM_CE_N;
wire        SPC7110_BSRAM_OE_N;
wire        SPC7110_BSRAM_WE_N;

generate
if (USE_SPC7110 == 1'b1) begin
SPC7110Map SPC7110Map
(
	.mclk(MCLK),
	.rst_n(RESET_N),

	.ca(CA),
	.di(DO),
    .DO(SPC7110_DO),
	.cpurd_n(CPURD_N),
	.cpuwr_n(CPUWR_N),

	.pa(PA),
	.pard_n(PARD_N),
	.pawr_n(PAWR_N),

	.romsel_n(ROMSEL_N),
	.ramsel_n(RAMSEL_N),

	.sysclkf_ce(SYSCLKF_CE),
	.sysclkr_ce(SYSCLKR_CE),
	.refresh(REFRESH),

	.irq_n(SPC7110_IRQ_N),

	.rom_addr(SPC7110_ROM_ADDR),
	.rom_q(ROM_Q),
	.rom_ce_n(SPC7110_ROM_CE_N),
	.rom_oe_n(SPC7110_ROM_OE_N),
	.rom_word(SPC7110_ROM_WORD),

	.bsram_addr(SPC7110_BSRAM_ADDR),
	.bsram_d(SPC7110_BSRAM_D),
	.bsram_q(BSRAM_Q),
	.bsram_ce_n(SPC7110_BSRAM_CE_N),
	.bsram_oe_n(SPC7110_BSRAM_OE_N),
	.bsram_we_n(SPC7110_BSRAM_WE_N),

	.map_active(MAP_ACTIVE[4]),
	.map_ctrl(ROM_TYPE),
	.rom_mask(ROM_MASK),
	.bsram_mask(RAM_MASK),
	
	.ext_rtc(EXT_RTC)
);
end else
assign MAP_ACTIVE[4] = 0;
endgenerate

wire [7:0]  BSX_DO;
wire        BSX_IRQ_N;
wire [22:0] BSX_ROM_ADDR;
wire [7:0]  BSX_ROM_D;
wire        BSX_ROM_CE_N;
wire        BSX_ROM_OE_N;
wire        BSX_ROM_WE_N;
wire        BSX_ROM_WORD;
wire [19:0] BSX_BSRAM_ADDR;
wire [7:0]  BSX_BSRAM_D;
wire        BSX_BSRAM_CE_N;
wire        BSX_BSRAM_OE_N;
wire        BSX_BSRAM_WE_N;

generate
if (USE_BSX == 1'b1) begin
BSXMap BSXMap
(
	.mclk(MCLK),
	.rst_n(RESET_N),

	.ca(CA),
	.di(DO),
	.DO(BSX_DO),
	.cpurd_n(CPURD_N),
	.cpuwr_n(CPUWR_N),

	.pa(PA),
	.pard_n(PARD_N),
	.pawr_n(PAWR_N),

	.romsel_n(ROMSEL_N),
	.ramsel_n(RAMSEL_N),

	.sysclkf_ce(SYSCLKF_CE),
	.sysclkr_ce(SYSCLKR_CE),
	.refresh(REFRESH),

	.irq_n(BSX_IRQ_N),

	.rom_addr(BSX_ROM_ADDR),
	.rom_d(BSX_ROM_D),
	.rom_q(ROM_Q),
	.rom_ce_n(BSX_ROM_CE_N),
	.rom_oe_n(BSX_ROM_OE_N),
	.rom_we_n(BSX_ROM_WE_N),
	.rom_word(BSX_ROM_WORD),

	.bsram_addr(BSX_BSRAM_ADDR),
	.bsram_d(BSX_BSRAM_D),
	.bsram_q(BSRAM_Q),
	.bsram_ce_n(BSX_BSRAM_CE_N),
	.bsram_oe_n(BSX_BSRAM_OE_N),
	.bsram_we_n(BSX_BSRAM_WE_N),

	.map_active(MAP_ACTIVE[5]),
	.map_ctrl(ROM_TYPE),
	.rom_mask(ROM_MASK),
	.bsram_mask(RAM_MASK),

	
	.ext_rtc(EXT_RTC)
);
end else
assign MAP_ACTIVE[5] = 0;
endgenerate

// assign TURBO_ALLOW = ~(MAP_ACTIVE[3] | MAP_ACTIVE[1]);

always @(*) begin
	case (MAP_ACTIVE)
	'b000001:
		begin
			DI         = CX4_DO;
			IRQ_N      = CX4_IRQ_N;
			ROM_ADDR   = {1'b0,CX4_ROM_ADDR};
			ROM_D      = 0;
			ROM_CE_N   = CX4_ROM_CE_N;
			ROM_OE_N   = CX4_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = CX4_BSRAM_ADDR;
			BSRAM_D    = CX4_BSRAM_D;
			BSRAM_CE_N = CX4_BSRAM_CE_N;
			BSRAM_OE_N = CX4_BSRAM_OE_N;
			BSRAM_WE_N = CX4_BSRAM_WE_N;
			ROM_WORD   = CX4_ROM_WORD;
		end

	'b000010:
		begin
			DI         = SDD_DO;
			IRQ_N      = SDD_IRQ_N;
			ROM_ADDR   = {1'b0,SDD_ROM_ADDR};
			ROM_D      = 0;
			ROM_CE_N   = SDD_ROM_CE_N;
			ROM_OE_N   = SDD_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = SDD_BSRAM_ADDR;
			BSRAM_D    = SDD_BSRAM_D;
			BSRAM_CE_N = SDD_BSRAM_CE_N;
			BSRAM_OE_N = SDD_BSRAM_OE_N;
			BSRAM_WE_N = SDD_BSRAM_WE_N;
			ROM_WORD   = SDD_ROM_WORD;
		end

	'b000100:
		begin
			DI         = GSU_DO;
			IRQ_N      = GSU_IRQ_N;
			ROM_ADDR   = {1'b0,GSU_ROM_ADDR};
			ROM_D      = 0;
			ROM_CE_N   = GSU_ROM_CE_N;
			ROM_OE_N   = GSU_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = GSU_BSRAM_ADDR;
			BSRAM_D    = GSU_BSRAM_D;
			BSRAM_CE_N = GSU_BSRAM_CE_N;
			BSRAM_OE_N = GSU_BSRAM_OE_N;
			BSRAM_WE_N = GSU_BSRAM_WE_N;
			ROM_WORD   = GSU_ROM_WORD;
		end

	'b001000:
		begin
			DI         = SA1_DO;
			IRQ_N      = SA1_IRQ_N;
			ROM_ADDR   = {1'b0,SA1_ROM_ADDR};
			ROM_D      = 0;
			ROM_CE_N   = SA1_ROM_CE_N;
			ROM_OE_N   = SA1_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = SA1_BSRAM_ADDR;
			BSRAM_D    = SA1_BSRAM_D;
			BSRAM_CE_N = SA1_BSRAM_CE_N;
			BSRAM_OE_N = SA1_BSRAM_OE_N;
			BSRAM_WE_N = SA1_BSRAM_WE_N;
			ROM_WORD   = SA1_ROM_WORD;
		end

	'b010000:
		begin
			DI         = SPC7110_DO;
			IRQ_N      = SPC7110_IRQ_N;
			ROM_ADDR   = {1'b0,SPC7110_ROM_ADDR};
			ROM_D      = 0;
			ROM_CE_N   = SPC7110_ROM_CE_N;
			ROM_OE_N   = SPC7110_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = SPC7110_BSRAM_ADDR;
			BSRAM_D    = SPC7110_BSRAM_D;
			BSRAM_CE_N = SPC7110_BSRAM_CE_N;
			BSRAM_OE_N = SPC7110_BSRAM_OE_N;
			BSRAM_WE_N = SPC7110_BSRAM_WE_N;
			ROM_WORD   = SPC7110_ROM_WORD;
		end

	'b100000:
		begin
			DI         = BSX_DO;
			IRQ_N      = BSX_IRQ_N;
			ROM_ADDR   = {1'b0,BSX_ROM_ADDR};
			ROM_D      = {8'd0, BSX_ROM_D};
			ROM_CE_N   = BSX_ROM_CE_N;
			ROM_OE_N   = BSX_ROM_OE_N;
			ROM_WE_N   = BSX_ROM_WE_N;
			BSRAM_ADDR = BSX_BSRAM_ADDR;
			BSRAM_D    = BSX_BSRAM_D;
			BSRAM_CE_N = BSX_BSRAM_CE_N;
			BSRAM_OE_N = BSX_BSRAM_OE_N;
			BSRAM_WE_N = BSX_BSRAM_WE_N;
			ROM_WORD   = BSX_ROM_WORD;
		end
		
	default:
		begin
			DI         = DLH_DO;
			IRQ_N      = DLH_IRQ_N;
			ROM_ADDR   = DLH_ROM_ADDR;
			ROM_D      = 0;
			ROM_CE_N   = DLH_ROM_CE_N;
			ROM_OE_N   = DLH_ROM_OE_N;
			ROM_WE_N   = 1;
			BSRAM_ADDR = DLH_BSRAM_ADDR;
			BSRAM_D    = DLH_BSRAM_D;
			BSRAM_CE_N = DLH_BSRAM_CE_N;
			BSRAM_OE_N = DLH_BSRAM_OE_N;
			BSRAM_WE_N = DLH_BSRAM_WE_N;
			ROM_WORD   = DLH_ROM_WORD;
		end
	endcase
	
	if(MSU_SEL)   DI = MSU_DO;
end

endmodule
