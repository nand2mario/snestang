module GSUMap(
    input MCLK,
    input RST_N,
    input ENABLE,
    input CLKREF,       // for sdram access sync
    input [23:0] CA,
    input [7:0] DI,
    output [7:0] DO,
    input CPURD_N,
    input CPUWR_N,
    input [7:0] PA,
    input PARD_N,
    input PAWR_N,
    input ROMSEL_N,
    input RAMSEL_N,
    input SYSCLKF_CE,
    input SYSCLKR_CE,
    input REFRESH,
    output IRQ_N,
    output [22:0] ROM_ADDR,
    input [15:0] ROM_Q,
    output ROM_CE_N,
    output ROM_OE_N,
    output ROM_WORD,
    output [19:0] BSRAM_ADDR,
    output [7:0] BSRAM_D,
    input [7:0] BSRAM_Q,
    output BSRAM_CE_N,
    output BSRAM_OE_N,
    output BSRAM_WE_N,
    output MAP_ACTIVE,
    input [7:0] MAP_CTRL,
    input [23:0] ROM_MASK,
    input [23:0] BSRAM_MASK,
    input TURBO
);

wire [20:0] ROM_A;
wire [16:0] RAM_A;
wire RAM_WE_N;
wire MAP_SEL;

assign MAP_SEL = MAP_CTRL[7:4] == 4'h7 ? 1'b1 : 1'b0;
assign MAP_ACTIVE = MAP_SEL;

GSU GSU(
    .CLK(MCLK), .RST_N(RST_N & MAP_SEL), .ENABLE(ENABLE), .CLKREF(CLKREF),
    .ADDR(CA), .DO(DO), .DI(DI), .RD_N(CPURD_N), .WR_N(CPUWR_N),
    .SYSCLKF_CE(SYSCLKF_CE), .SYSCLKR_CE(SYSCLKR_CE),
    .IRQ_N(IRQ_N), .ROM_A(ROM_A),
    .ROM_DI(ROM_Q[7:0]), .ROM_RD_N(ROM_OE_N),
    .RAM_A(RAM_A), .RAM_DI(BSRAM_Q), .RAM_DO(BSRAM_D),
    .RAM_WE_N(RAM_WE_N), .RAM_CE_N(BSRAM_CE_N),
    .TURBO(TURBO)
);

assign ROM_ADDR = ({2'b00,ROM_A}) & ROM_MASK[22:0];
assign ROM_CE_N = ROMSEL_N; // 1'b0;        nand2mario: should not always enable ROM read, this interferes with BSRAM reads
assign ROM_WORD = 1'b0;
assign BSRAM_ADDR = {4'b0000,RAM_A[15:0]};
assign BSRAM_OE_N =  ~RAM_WE_N;
assign BSRAM_WE_N = RAM_WE_N;

endmodule
