// File SNES.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// This is an SNES machine without a few peripherals: cartridge, ROM loading, display interface.
// A SDRAM chip is needed for this to work.

module SNES(
    input MCLK,              // Master clock 21Mhz

    input RST_N,
    input ENABLE,
    input PAL,
    input BLEND,
    input DIS_SHORTLINE,

    // Cartridge
    output [23:0] CA,
    output CPURD_N,
    output CPUWR_N,
    output CPURD_CYC_N,
    output DOT_CLK_CE,

    output [7:0] PA,
    output PARD_N,
    output PAWR_N,
    input [7:0] DI,
    output [7:0] DO,

    output RAMSEL_N,
    output ROMSEL_N,

	output SYSCLKF_CE,
	output SYSCLKR_CE,
    output SNES_REFRESH,

    input IRQ_N,

    // Work RAM
    // TODO: generate WRAM_ADDR, WRAM_CE_N ...
    output [16:0] WRAM_ADDR,
    output [7:0] WRAM_D,       // Data to WRAM
    input [7:0] WRAM_Q,        // Data from WRAM
    output WRAM_CE_N,
    output WRAM_OE_N,
    output WRAM_WE_N,
    output WRAM_RD_N,

    // VRAM interface
    output [15:0] VRAM_ADDRA,   // VRAM, in dual-port signals
    output [15:0] VRAM_ADDRB,
    input [7:0] VRAM_DAI,
    input [7:0] VRAM_DBI,
    output [7:0] VRAM_DAO,
    output [7:0] VRAM_DBO,
    output VRAM_WRA_N,
    output VRAM_WRB_N,
    output VRAM_RD_N,

    // Audio RAM interface
    output [15:0] ARAM_ADDR,    // ARAM
    output [7:0] ARAM_D,
    input [7:0] ARAM_Q,
    output ARAM_CE_N,             // {ARAM_WR,ARAM_RD}=1X: write, =01: read, 00: idle
    output ARAM_OE_N,
    output ARAM_WE_N,

    // Video
    output HIGH_RES,
    output FIELD_OUT,
    output INTERLACE,
    output V224_MODE,
    output DOTCLK,

    output [14:0] RGB_OUT /*verilator public*/,
    output HDE,
    output VDE,
    output HSYNC,
    output VSYNC,
    output [8:0] X_OUT,
    output [8:0] Y_OUT,

    // Joystick
    input [1:0] JOY1_DI,
    input [1:0] JOY2_DI,
    output JOY_STRB,
    output JOY1_CLK,
    output JOY2_CLK,

    // Audio
    output [15:0] AUDIO_L,  // audio sample
    output [15:0] AUDIO_R,
    output AUDIO_READY,     // pulse when a sample is ready
    input AUDIO_EN,         // 0: pause SMP/DSP processing to limit to 32Khz rate

    // Debug
    input [7:0] DBG_SEL,
    input [7:0] DBG_REG,
    input DBG_REG_WR,
    input [7:0] DBG_DAT_IN,
    output [7:0] DBG_DAT_OUT,
    output DBG_BREAK
);

wire DSPCLK = MCLK;

// SCPU
wire [23:0] INT_CA;
wire INT_CPURD_N, INT_CPUWR_N;
wire [7:0] CPU_DI;
wire [7:0] CPU_DO;
wire INT_RAMSEL_N;
wire INT_ROMSEL_N;
wire [7:0] INT_PA;
wire INT_PARD_N, INT_PAWR_N;
wire [7:6] JPIO67;
wire INT_SYSCLKF_CE, INT_SYSCLKR_CE;
wire INT_CPURD_CYC_N, INT_PARD_CYC_N;

wire [7:0] BUSA_DO;
wire [7:0] BUSB_DO;
wire BUSA_SEL;
wire BUSB_SEL;

wire [16:0] WRAM_A;
wire [7:0] WRAM_DO, WRAM_DI;
wire WRAM_CE2_N, WRAM_OE2_N, WRAM_WE2_N;

// PPU
wire INT_HBLANK, INT_VBLANK;
wire [7:0] PPU_DO;
wire [7:0] PPU_DI;  

// APU
wire SMP_CE;
wire [15:0] SMP_A;
wire [7:0] SMP_DO;
wire [7:0] SMP_DI;
wire SMP_WE_N;
reg [7:0] SMP_CPU_DO;
wire [7:0] SMP_CPU_DI;
wire SMP_EN;

wire [15:0] APU_RAM_A;
wire [7:0] APU_RAM_DO;
wire [7:0] APU_RAM_DI;
wire APU_RAM_CE, APU_RAM_OE, APU_RAM_WE;  

// DEBUG
wire [7:0] DBG_CPU_DAT; wire [7:0] DBG_SCPU_DAT; wire [7:0] DBG_WRAM_DAT; wire [7:0] DBG_PPU_DAT; wire [7:0] DBG_SMP_DAT; wire [7:0] DBG_SPC700_DAT; wire [7:0] DBG_DSP_DAT; 
wire CPU_BRK; reg SMP_BRK; wire SMP_BRK_TEMP; wire PPU_DBG_BRK;
wire CPU_DBG_WR; wire WRAM_DBG_WR; wire SPC700_DAT_WR; wire SMP_DAT_WR; wire PPU_DBG_WR; wire DSP_DBG_WR;
//reg APU_ENABLE;
wire [7:0] DBG_CPU_TEMP;

// CPU
SCPU CPU(
    .CLK(MCLK), .RST_N(RST_N), 
    .ENABLE(ENABLE), .IRQ_N(IRQ_N), .HBLANK(INT_HBLANK), .VBLANK(INT_VBLANK),     
    .CA(INT_CA), .CPURD_N(INT_CPURD_N), .CPUWR_N(INT_CPUWR_N),
    .PA(INT_PA), .PARD_N(INT_PARD_N), .PAWR_N(INT_PAWR_N),
    .DI(CPU_DI), .DO(CPU_DO),
    .CPURD_CYC_N(INT_CPURD_CYC_N), .PARD_CYC_N(INT_PARD_CYC_N), .DOT_CLK_CE_O(DOT_CLK_CE),
    .RAMSEL_N(INT_RAMSEL_N), .ROMSEL_N(INT_ROMSEL_N),
    .SNES_REFRESH(SNES_REFRESH), .JPIO67(JPIO67),
    .SYSCLKF_CE(INT_SYSCLKF_CE), .SYSCLKR_CE(INT_SYSCLKR_CE), 
    .JOY1_CLK(JOY1_CLK), .JOY2_CLK(JOY2_CLK), .JOY_STRB(JOY_STRB),
    .JOY1_DI(JOY1_DI), .JOY2_DI(JOY2_DI), 
    .DBG_CPU_BRK(CPU_BRK),.DBG_REG(DBG_REG),.DBG_DAT(DBG_SCPU_DAT),
    .DBG_DAT_IN(DBG_DAT_IN), .DBG_CPU_DAT(DBG_CPU_DAT),.DBG_CPU_WR(CPU_DBG_WR),
    .SYSCLK(), .TURBO()
);

reg INT_RAMSEL_N_buf, BUSA_SEL_buf, BUSB_SEL_buf;
reg [7:0] BUSA_DO_buf, BUSB_DO_buf;
always @(posedge MCLK) begin 
    INT_RAMSEL_N_buf <= INT_RAMSEL_N;
    BUSA_SEL_buf <= BUSA_SEL;
    BUSA_DO_buf <= BUSA_DO;
    BUSB_SEL_buf <= BUSB_SEL;
    BUSB_DO_buf <= BUSB_DO;
end

assign BUSA_SEL =   INT_CA[22] == 1'b0 && INT_CA[15:8] == 8'h20 ? 1'b1 : 
                    INT_CA[22] == 1'b0 && INT_CA[15:8] >= 8'h22 ? 1'b1 : 
                    INT_CA[23:16] >= 8'h40 && INT_CA[23:16] <= 8'h7D ? 1'b1 : 
                    INT_CA[23:16] >= 8'hC0 ? 1'b1 : 1'b0;
assign BUSA_DO =    ~INT_CA[22] && (INT_CA[15:8] == 8'h40 || INT_CA[15:8] == 8'h43) ? 8'h0 :
                    DI;

assign BUSB_SEL =   ~INT_PA[7] || INT_PA[7:2] == 6'b100000;
assign BUSB_DO =    INT_PA[7:6] == 2'b00 ? PPU_DO : 
                    INT_PA[7:6] == 2'b01 ? SMP_CPU_DO :
                    INT_PA[7:2] == 6'b100000 ? WRAM_DO : 
                     8'hFF;

// nand2mario: INT_CA and INT_RAMSEL_N has a critical path from HDMA
//             buffer to improve timing
assign CPU_DI =     ~INT_RAMSEL_N_buf ? WRAM_DO : 
                    BUSA_SEL_buf ? BUSA_DO_buf :
                    BUSB_SEL_buf ? BUSB_DO_buf : 
                    DI;

// WRAM
assign WRAM_DI =    BUSA_SEL ? BUSA_DO :
                    ~INT_PARD_N ? BUSB_DO :
                    CPU_DO;

SWRAM wram (
    .CLK(MCLK), .SYSCLK_CE(INT_SYSCLKF_CE), .RST_N(RST_N), .ENABLE(ENABLE),
    .CA(INT_CA), .CPURD_N(INT_CPURD_N), .CPUWR_N(INT_CPUWR_N), .RAMSEL_N(INT_RAMSEL_N),
    .PA(INT_PA), .PARD_N(INT_PARD_N), .PAWR_N(INT_PAWR_N),
    .CPURD_CYC_N(INT_CPURD_CYC_N), .PARD_CYC_N(INT_PARD_CYC_N),
    .DI(WRAM_DI), .DO(WRAM_DO),
    .RAM_A(WRAM_ADDR), .RAM_D(WRAM_D), .RAM_Q(WRAM_Q), .RAM_WE_N(WRAM_WE_N),
    .RAM_CE_N(WRAM_CE_N), .RAM_OE_N(WRAM_OE_N), .RAM_RD_N(WRAM_RD_N)
);

// PPU
assign  PPU_DI = BUSA_SEL ? BUSA_DO : 
        ~INT_RAMSEL_N ? WRAM_DO : 
        CPU_DO;

SPPU PPU(
    .CLK(MCLK), .RST_N(RST_N), .SYSCLK_CE(INT_SYSCLKF_CE), .ENABLE(ENABLE), 
    .DIS_SHORTLINE(DIS_SHORTLINE),
    .PA(INT_PA), .PARD_N(INT_PARD_N), .PAWR_N(INT_PAWR_N), .DI(PPU_DI), .DO(PPU_DO),
    .VRAM_ADDRA(VRAM_ADDRA), .VRAM_ADDRB(VRAM_ADDRB), .VRAM_DAI(VRAM_DAI), .VRAM_DBI(VRAM_DBI),
    .VRAM_DAO(VRAM_DAO), .VRAM_DBO(VRAM_DBO), .VRAM_RD_N(VRAM_RD_N),
    .VRAM_WRA_N(VRAM_WRA_N), .VRAM_WRB_N(VRAM_WRB_N),
    .EXTLATCH(JPIO67[7]), .BLEND(BLEND), .PAL(PAL), .HIGH_RES(), .DOTCLK(DOTCLK), 
    .FIELD_OUT(FIELD_OUT), .INTERLACE(INTERLACE), .V224(V224_MODE), 
    .COLOR_OUT(RGB_OUT), .HBLANK(INT_HBLANK), .VBLANK(INT_VBLANK),
    .HDE(HDE), .VDE(VDE), .HSYNC(HSYNC), .VSYNC(VSYNC),
    .FRAME_OUT(), .X_OUT(X_OUT), .Y_OUT(Y_OUT), 
    .BG_EN(5'b11111)
    // .DBG_REG(DBG_REG), .DBG_DAT_OUT(DBG_PPU_DAT), .DBG_DAT_IN(DBG_DAT_IN),
    // .DBG_DAT_WR(PPU_DBG_WR), .DBG_BRK(PPU_DBG_BRK)
);

assign SMP_CPU_DI = BUSA_SEL ? BUSA_DO : 
                    ~INT_RAMSEL_N ? WRAM_DO : 
                    CPU_DO;

// SMP
SMP smp(
   .CLK(DSPCLK), .RST_N(RST_N), .CE(SMP_CE), .ENABLE(SMP_EN), .SYSCLKF_CE(INT_SYSCLKF_CE),
   .A(SMP_A), .DI(SMP_DI), .DO(SMP_DO), .WE_N(SMP_WE_N),
   .PA(INT_PA[1:0]), .PARD_N(INT_PARD_N), .PAWR_N(INT_PAWR_N), .CPU_DI(SMP_CPU_DI), .CPU_DO(SMP_CPU_DO),
   .CS(INT_PA[6]), .CS_N(INT_PA[7]),
   .DBG_REG(DBG_REG), .DBG_DAT_IN(DBG_DAT_IN), .DBG_SMP_DAT(DBG_SMP_DAT), .DBG_CPU_DAT(DBG_SPC700_DAT),
   .DBG_CPU_DAT_WR(SPC700_DAT_WR), .DBG_SMP_DAT_WR(SMP_DAT_WR), .BRK_OUT(SMP_BRK)
);

// DSP 
DSP dsp(
    .CLK(DSPCLK), .RST_N(RST_N), .ENABLE(ENABLE), .PAL(PAL),
    .SMP_EN(SMP_EN), .SMP_A(SMP_A), .SMP_DO(SMP_DO), .SMP_DI(SMP_DI),
    .SMP_WE_N(SMP_WE_N), .SMP_CE(SMP_CE),
    .RAM_A(ARAM_ADDR), .RAM_D(ARAM_D), .RAM_Q(ARAM_Q),
    .RAM_WE_N(ARAM_WE_N), .RAM_OE_N(ARAM_OE_N), .RAM_CE_N(ARAM_CE_N), 
    .SND_RDY(AUDIO_READY), .AUDIO_L(AUDIO_L), .AUDIO_R(AUDIO_R),
    .DBG_REG(DBG_REG), .DBG_DAT_IN(DBG_DAT_IN), .DBG_DAT_OUT(DBG_DSP_DAT), .DBG_DAT_WR(DSP_DBG_WR)
);

assign CA = INT_CA;
assign CPURD_N = INT_CPURD_N;
assign CPUWR_N = INT_CPUWR_N;
assign CPURD_CYC_N = INT_CPURD_CYC_N;

assign PA = INT_PA;
assign PARD_N = INT_PARD_N;
assign PAWR_N = INT_PAWR_N;

assign RAMSEL_N = INT_RAMSEL_N;
assign ROMSEL_N = INT_ROMSEL_N;

assign DO = ~INT_PARD_N ? BUSB_DO : CPU_DO;

assign SYSCLKF_CE = INT_SYSCLKF_CE;
assign SYSCLKR_CE = INT_SYSCLKR_CE;

// assign JOY1_P6 = JPIO67[6];
// assign JOY2_P6 = JPIO67[7];

assign CPU_DBG_WR = DBG_SEL[0] & DBG_REG_WR;
assign WRAM_DBG_WR = DBG_SEL[2] & DBG_REG_WR;
assign SPC700_DAT_WR = DBG_SEL[3] & DBG_REG_WR;
assign SMP_DAT_WR = DBG_SEL[4] & DBG_REG_WR;
assign PPU_DBG_WR = DBG_SEL[5] & DBG_REG_WR;
assign DSP_DBG_WR = DBG_SEL[6] & DBG_REG_WR;

assign DBG_DAT_OUT = DBG_SEL[0] ? DBG_CPU_DAT : 
                    DBG_SEL[1] ? DBG_SCPU_DAT : 
                    DBG_SEL[2] ? DBG_WRAM_DAT : 
                    DBG_SEL[3] ? DBG_SPC700_DAT : 
                    DBG_SEL[4] ? DBG_SMP_DAT : 
                    DBG_SEL[5] ? DBG_PPU_DAT : 
                    DBG_SEL[6] ? DBG_DSP_DAT : 8'h00;
assign DBG_BREAK = CPU_BRK | SMP_BRK | PPU_DBG_BRK;

endmodule
