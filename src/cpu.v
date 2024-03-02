module SCPU(
    input CLK,              // Master clock 21 Mhz
    input RST_N,
    input ENABLE,

    output reg [23:0] CA,   // Addr Bus A: S-CPU to WRAM and Cart
    output reg CPURD_N,    
    output reg CPUWR_N,

    output reg CPURD_CYC_N, // full-cycle version of CPURD_N
    output reg PARD_CYC_N,

    output DOT_CLK_CE_O,

    output reg [7:0] PA,    // Addr Bus B: Peripheral bus
    output reg PARD_N,      //    S-CPU to PPU, SMP, WRAM, Cart and expansion port
    output reg PAWR_N,
    input [7:0] DI,
    output [7:0] DO,

    output reg RAMSEL_N,
    output reg ROMSEL_N,

    output [7:6] JPIO67,
    output SNES_REFRESH,

    // Sys clock: \___/   \___/   
    //            F   R   F   R
    // output LAST_CYCLE,      // Last cycle for current instruction
    output SYSCLK,
    output SYSCLKF_CE,  // Falling edge of SNES sys clock, for CPU operations.
    output SYSCLKR_CE,  // Rising edge of SNES sys clock, for memory accesses.

    input HBLANK,
    input VBLANK,

    input IRQ_N,

    input [1:0] JOY1_DI,
    input [1:0] JOY2_DI,
    output JOY_STRB,
    output JOY1_CLK,
    output JOY2_CLK,

    input TURBO,

    output DBG_CPU_BRK,
    input [7:0] DBG_REG,
    output reg [7:0] DBG_DAT,
    input [7:0] DBG_DAT_IN,
    output [7:0] DBG_CPU_DAT,
    input DBG_CPU_WR
);

// clocks
reg INT_CLK;
wire EN;
reg INT_CLKF_CE, INT_CLKR_CE, DOT_CLK_CE;
reg [3:0] P65_CLK_CNT;
reg [2:0] DMA_CLK_CNT;
localparam [2:0] DMA_LAST_CLOCK = 3'b111;
localparam [2:0] DMA_MID_CLOCK = 3'b011;
reg [3:0] CPU_LAST_CLOCK;
localparam [3:0] CPU_MID_CLOCK = 4'd2;
reg CPU_ACTIVEr, DMA_ACTIVEr;
reg [1:0] DOT_CLK_CNT;
reg [8:0] H_CNT;
reg [8:0] V_CNT;
reg FIELD;

// 65C816
wire P65_R_WN;
wire [23:0] P65_A;
wire [7:0] P65_DO;
reg [7:0] P65_DI;
wire P65_NMI_N, P65_IRQ_N;
wire P65_EN;
wire P65_VPA, P65_VDA;
wire P65_BRK;

parameter [1:0] XSLOW = 0, SLOW = 1, FAST = 2, SLOWFAST = 3;
reg [1:0] SPEED;

//CPU BUS
wire [23:0] INT_A;
wire IO_SEL;
reg CPU_WR, CPU_RD;

//DMA BUS
reg [23:0] DMA_A, HDMA_A;
reg [7:0] DMA_B, HDMA_B;
reg DMA_A_WR, HDMA_A_WR, DMA_A_RD, HDMA_A_RD;
reg DMA_B_WR, DMA_B_RD, HDMA_B_WR, HDMA_B_RD;
reg DMA_A_WR_CYC, HDMA_A_WR_CYC, DMA_A_RD_CYC, HDMA_A_RD_CYC;
reg DMA_B_WR_CYC, DMA_B_RD_CYC, HDMA_B_WR_CYC, HDMA_B_RD_CYC;

// CPU IO Registers
reg [7:0] MDR;
reg NMI_EN;
reg [1:0] HVIRQ_EN;
reg AUTO_JOY_EN;
reg [7:0] WRIO;
reg [7:0] WRMPYA;
// reg [7:0] WRMPYB;
reg [15:0] WRDIVA;
// reg [7:0] WRDIVB;
reg [8:0] HTIME = 9'b1_1111_1111;
reg [8:0] VTIME = 9'b1_1111_1111;
reg [7:0] MDMAEN;
reg [7:0] HDMAEN;
reg MEMSEL;
reg [15:0] RDDIV, RDMPY;

reg NMI_FLAG, IRQ_FLAG;
reg MUL_REQ, DIV_REQ;
reg [3:0] MATH_CLK_CNT;
reg [22:0] MATH_TEMP;
reg HBLANK_OLD, VBLANK_OLD, VBLANK_OLD2;
reg HIRQ_VALID, VIRQ_VALID, IRQ_VALID;
reg IRQ_LOCK, IRQ_VALID_OLD;
reg NMI_LOCK;

localparam [1:0] REFS_IDLE = 2'd0;
localparam [1:0] REFS_EXEC = 2'd1;
localparam [1:0] REFS_END = 2'd2;
reg [1:0] REFS;
reg [2:0] REFRESH_CNT;
reg REFRESHED;
reg HBLANK_REF_OLD;

// DMA registers
// Direction (D), indirect HDMA (I), address increment mode (A), transfer pattern (P).
reg [7:0] DMAP[0:7] = '{8{8'b1111_1111}};   // DI.A APPP, $43n0	
reg [7:0] BBAD[0:7] = '{8{8'b1111_1111}};   // B-bus address, $43n1	

// DMA source address / HDMA table start address.
reg [15:0] A1T[0:7] = '{8{16'hffff}};       // $43n2 $43n3
reg [7:0] A1B[0:7] = '{8{8'b1111_1111}};    // BBBB BBBB, $43n4

// DMA byte count (H:L) / HDMA indirect table address (B:H:L).
reg [15:0] DAS[0:7] = '{8{16'hffff}};       // $43n5, $43n6
reg [7:0] DASB[0:7] = '{8{8'b1111_1111}};   // BBBB BBBB, $43n7

// HDMA table current address within bank (H:L).
reg [15:0] A2A[0:7] = '{8{16'hffff}};       // $43n8, $43n9

// HDMA reload flag (R) and scanline counter (L).
reg [7:0] NTLR[0:7] = '{8{8'b1111_1111}};   // RLLL LLLL, $43nA
reg [7:0] UNUSED[0:7] = '{8{8'b1111_1111}}; 

reg [2:0] DCH, HCH;
reg DMA_RUN, HDMA_RUN;
wire DMA_ACTIVE;
reg [7:0] HDMA_CH_WORK, HDMA_CH_RUN, HDMA_CH_DO;
reg [7:0] HDMA_CH_EN;
reg HDMA_INIT_EXEC, HDMA_RUN_EXEC;

parameter [1:0] DS_IDLE = 0, DS_INIT = 1, DS_CH_SEL = 2, DS_TRANSFER = 3;
reg [1:0] DS;     // DMA state

parameter [2:0] HDS_IDLE = 0, HDS_PRE_INIT = 1, HDS_INIT = 2,
                HDS_INIT_IND = 3, HDS_PRE_TRANSFER = 4,
                HDS_TRANSFER = 5;
reg [2:0] HDS;

reg HDMA_INIT_STEP;
reg [1:0] DMA_TRMODE_STEP, HDMA_TRMODE_STEP;
reg HDMA_FIRST_INIT;
parameter [1:0] DMA_TRMODE_TAB[0:7][0:3] = '{
    '{2'b00,2'b00,2'b00,2'b00},
    '{2'b00,2'b01,2'b00,2'b01},
    '{2'b00,2'b00,2'b00,2'b00},
    '{2'b00,2'b00,2'b01,2'b01},
    '{2'b00,2'b01,2'b10,2'b11},
    '{2'b00,2'b01,2'b00,2'b01},
    '{2'b00,2'b00,2'b00,2'b00},
    '{2'b00,2'b00,2'b01,2'b01}
};
// typedef logic [1:0] DmaTransLenth[0:7];
parameter [1:0] DMA_TRMODE_LEN[0:7] = '{2'b00,2'b01,2'b01,2'b11,2'b11,2'b11,2'b01,2'b11};

//  function logic [2:0] GetDMACh(logic [7:0] data);
//      return  data[0] ? 0 :
//              data[1] ? 1 :
//              data[2] ? 2 :
//              data[3] ? 3 :
//              data[4] ? 4 :
//              data[5] ? 5 :
//              data[6] ? 6 :
//              data[7] ? 7 : 0;
//  endfunction

function logic [2:0] GetDMACh(logic [7:0] data);
    reg b1,b2,b3,b4,b5,b6,b7;
    reg [2:0] v;
    b1 = ~data[0] & data[1];
    b2 = ~data[0] & ~data[1] & data[2];
    b3 = ~data[0] & ~data[1] & ~data[2] & data[3];
    b4 = ~data[0] & ~data[1] & ~data[2] & ~data[3] & data[4];
    b5 = ~data[0] & ~data[1] & ~data[2] & ~data[3] & ~data[4] & data[5];
    b6 = ~data[0] & ~data[1] & ~data[2] & ~data[3] & ~data[4] & ~data[5] & data[6];
    b7 = ~data[0] & ~data[1] & ~data[2] & ~data[3] & ~data[4] & ~data[5] & ~data[6] & data[7];
   v[0] = b1 | b3 | b5 | b7;
   v[1] = b2 | b3 | b6 | b7;
   v[2] = b4 | b5 | b6 | b7;
   return v;
endfunction

function logic IsLastHDMACh(logic [7:0] data, logic [2:0] ch);
    if ((data >> (ch+1)) == 8'h0)
        return 1;
    else
        return 0;
endfunction

// JOY
reg [15:0] JOY1_DATA, JOY2_DATA, JOY3_DATA, JOY4_DATA;
reg AUTO_JOY_CLK;
reg OLD_JOY_STRB, AUTO_JOY_STRB;
reg OLD_JOY1_CLK, OLD_JOY2_CLK;
reg [5:0] JOY_POLL_CLK;
reg [4:0] JOY_POLL_CNT;
reg JOY_POLL_STRB;
reg JOYRD_BUSY;
reg JOY_POLL_RUN;
reg JOY_VBLANK_OLD;

//debug
// reg [15:0] FRAME_CNT;
wire P65_RDY;

assign DMA_ACTIVE = DMA_RUN | HDMA_RUN;

/*
mclk    /1\__/2\__/3\__/4\__/5\__/6\__/7\__/8\__/9\__/0\__/1\__/2\__/3\__/4\__/5\__/6\__/7\__/8\__/9\__/0\__/
phase   |    0    |    1    |    0    |    1    |    2    |    0    |    1    |    2    |    3    |    0    |
CPU_CLK __4-cycle_/         \_6-cycle_/                   \_8-cycle_/                             \12-cycle_/
DOT_CLK ___dot 1__/         \__dot 2__/         \_
*/

always @* begin
    if (TURBO) /* and P65_ACCESSED_PERIPHERAL_CNT = x"0" */
        CPU_LAST_CLOCK = 4'd4;	
    else if (REFRESHED && CPU_ACTIVEr)
        CPU_LAST_CLOCK = 4'd7;	
    else if (SPEED == FAST || (SPEED == SLOWFAST && MEMSEL))
        CPU_LAST_CLOCK = 4'd5;
    else if (SPEED == SLOW || (SPEED == SLOWFAST && ~MEMSEL))
        CPU_LAST_CLOCK = 4'd7;
    else	
        CPU_LAST_CLOCK = 4'hB;
end

always @(posedge CLK) begin : cpu_clk_gen
    if (~RST_N) begin
        P65_CLK_CNT <= 0;
        DMA_CLK_CNT <= 0;
        INT_CLK <= 1;
        CPU_ACTIVEr <= 1'b1;
        DMA_ACTIVEr <= 1'b0;
    end else begin
        DMA_CLK_CNT <= DMA_CLK_CNT + 1;
        if (DMA_CLK_CNT == DMA_LAST_CLOCK)
            DMA_CLK_CNT <= 0;

        P65_CLK_CNT <= P65_CLK_CNT + 1;
        if (P65_CLK_CNT >= CPU_LAST_CLOCK)
            P65_CLK_CNT <= 0;
        
        if (~DMA_ACTIVEr && DMA_ACTIVE && DMA_CLK_CNT == DMA_LAST_CLOCK && ~REFRESHED)
            DMA_ACTIVEr <= 1;
        else if (DMA_ACTIVEr && ~DMA_ACTIVE && ~REFRESHED)
            DMA_ACTIVEr <= 0;

        if (CPU_ACTIVEr && DMA_ACTIVE && ~DMA_ACTIVEr && ~REFRESHED)
            CPU_ACTIVEr <= 1'b0;
        else if (~CPU_ACTIVEr && ~DMA_ACTIVE && P65_CLK_CNT >= CPU_LAST_CLOCK && ~REFRESHED)
            CPU_ACTIVEr <= 1'b1;

        if (DMA_ACTIVEr || ~ENABLE) begin
            if (DMA_CLK_CNT == DMA_MID_CLOCK)
                INT_CLK <= 1;
            else if (DMA_CLK_CNT == DMA_LAST_CLOCK)
                INT_CLK <= 0;
        end else if (CPU_ACTIVEr) begin
            if (P65_CLK_CNT == CPU_MID_CLOCK)
                INT_CLK <= 1;
            else if (P65_CLK_CNT >= CPU_LAST_CLOCK)
                INT_CLK <= 0;
        end
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        INT_CLKF_CE <= 0;
        INT_CLKR_CE <= 0;
    end else begin
        INT_CLKF_CE <= 0;
        INT_CLKR_CE <= 0;
        if (DMA_ACTIVEr || ~ENABLE) begin
            if (DMA_CLK_CNT == DMA_MID_CLOCK)
                INT_CLKR_CE <= 1;
            else if (DMA_CLK_CNT == DMA_LAST_CLOCK)
                INT_CLKF_CE <= 1;
        end else if (CPU_ACTIVEr) begin
            if (P65_CLK_CNT == CPU_MID_CLOCK)
                INT_CLKR_CE <= 1;
            else if (P65_CLK_CNT >= CPU_LAST_CLOCK)
                INT_CLKF_CE <= 1; 
        end
    end
end

assign EN = ENABLE & ~REFRESHED;
assign P65_EN = ~DMA_ACTIVE & EN;

assign SYSCLK = INT_CLK; 
assign SYSCLKF_CE = INT_CLKF_CE;
assign SYSCLKR_CE = INT_CLKR_CE;

assign DOT_CLK_CE_O = DOT_CLK_CE;

// 65C816
P65C816 P65C816(
    .CLK(CLK), .RST_N(RST_N), .CE(INT_CLKF_CE),

    .WE_N(P65_R_WN), .D_IN(P65_DI), .D_OUT(P65_DO), .A_OUT(P65_A),
    .RDY_IN(P65_EN), .NMI_N(P65_NMI_N), .IRQ_N(P65_IRQ_N),
    .ABORT_N(1'b1), .VPA(P65_VPA), .VDA(P65_VDA),

    .RDY_OUT(), .MLB(), .VPB(),

    .BRK_OUT(P65_BRK), .DBG_REG(DBG_REG), .DBG_DAT_IN(DBG_DAT_IN),
    .DBG_DAT_OUT(DBG_CPU_DAT), .DBG_DAT_WR(DBG_CPU_WR)
);

always @* begin
    SPEED = SLOW;

    if (~P65_VPA && ~P65_VDA)
        SPEED = FAST;
    else if (~P65_A[22]) begin                          // $00-$3F, $80-$BF | System Area
        if (P65_A[15:9] == 7'b0100000)                  // $4000-$41FF | XSlow
            SPEED = XSLOW;
        else if (P65_A[15:13] == 3'b000 ||              // $0000-$1FFF | Slow
                 P65_A[15:13] == 3'b011)                // $6000-$7FFF | Slow
            SPEED = SLOW;
        else if (P65_A[15]) begin                       // $8000-$FFFF | Fast,Slow
            if (~P65_A[23])
                SPEED = SLOW;
            else
                SPEED = SLOWFAST;
        end else
            SPEED = FAST;
    end else if (P65_A[23:22] == 2'b01)                 // $40-$7D | $0000-$FFFF | Slow
      SPEED = SLOW;                                     // $7E-$7F | $0000-$FFFF | Slow
    else if (P65_A[23:22] == 2'b11)                     // $C0-$FF | $0000-$FFFF | Fast,Slow
      SPEED = SLOWFAST;
end

assign INT_A =  HDMA_RUN ? HDMA_A :
                DMA_RUN ? DMA_A : 
                P65_A;

always @* begin
    RAMSEL_N = 1;
    ROMSEL_N = 1;

    CA = INT_A;
    
    if (~INT_A[22]) begin                       //$00-$3F, $80-$BF
        if (INT_A[15:13] <= 3'b000) begin       //$0000-$1FFF | Slow  | Address Bus A + /WRAM (mirror $7E:0000-$1FFF)
            CA[23:13] = {8'h7E,3'b000};
            RAMSEL_N = 1'b0;
        end else if (INT_A[15])                 //$8000-$FFFF | Slow  | Address Bus A + /CART
            ROMSEL_N = 1'b0;
    end else begin                              //$40-$7F, $C0-$FF
        if (INT_A[23:17] == 7'b0111111)         //$7E-$7F | $0000-$FFFF | Slow  | Address Bus A + /WRAM
            RAMSEL_N = 1'b0;
        else if (INT_A[23:22] == 2'b01          //$40-$7D | $0000-$FFFF | Slow  | Address Bus A + /CART
              || INT_A[23:22] == 2'b11)         //$C0-$FF | $0000-$FFFF | Fast,Slow | Address Bus A + /CART
            ROMSEL_N = 1'b0;
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        CPU_WR <= 0;
        CPU_RD <= 0;
    end else begin
        if (EN) begin
            if (P65_EN && (P65_VPA || P65_VDA) && INT_CLKR_CE) begin
                CPU_WR <= ~P65_R_WN;
                CPU_RD <= P65_R_WN;
            end else if (INT_CLKF_CE) begin
                CPU_WR <= 0;
                CPU_RD <= 0;
            end   
        end
    end
end

always @* begin
    if (HDMA_RUN && EN) begin
        PA = HDMA_B;
        PARD_N =  ~HDMA_B_RD;
        PAWR_N =  ~HDMA_B_WR;
    end else if (DMA_RUN && EN) begin
        PA = DMA_B;
        PARD_N =  ~DMA_B_RD;
        PAWR_N =  ~DMA_B_WR;
    end else if (~P65_A[22] && P65_A[15:8] == 8'h21 && P65_EN) begin
        PA = P65_A[7:0];
        PARD_N = ~CPU_RD; 
        PAWR_N = ~CPU_WR;
    end else begin
        PA = 8'hFF;
        PARD_N = 1'b1;
        PAWR_N = 1'b1;
    end 
    
    if (HDMA_RUN && EN) begin
        CPURD_N = ~HDMA_A_RD;
        CPUWR_N = ~HDMA_A_WR;
    end else if (DMA_RUN && EN) begin
        CPURD_N = ~DMA_A_RD;
        CPUWR_N = ~DMA_A_WR;
    end else if (P65_EN) begin
        CPURD_N = ~CPU_RD;
        CPUWR_N = ~CPU_WR;
    end else begin
        CPURD_N = 1;
        CPUWR_N = 1;
    end
end

always @* begin
    // Read signal for a full clock cycle
    if (HDMA_RUN && EN)
        PARD_CYC_N = ~HDMA_B_RD_CYC;
    else if (DMA_RUN && EN)
        PARD_CYC_N = ~DMA_B_RD_CYC;
    else if (~P65_A[22] && P65_A[15:8] == 8'h21 && P65_EN)
        PARD_CYC_N = ~P65_R_WN;
    else
        PARD_CYC_N = 1'b1;

    if (HDMA_RUN && EN)
        CPURD_CYC_N = ~HDMA_A_RD_CYC;
    else if (DMA_RUN && EN)
        CPURD_CYC_N = ~DMA_A_RD_CYC;
    else if (P65_EN)
        CPURD_CYC_N = ~P65_R_WN;
    else
        CPURD_CYC_N = 1'b1;
end

//IO Registers
assign IO_SEL = P65_EN && ~P65_A[22] && P65_A[15:10] == 6'b010000
            && (P65_VPA || P65_VDA);            //$00-$3F/$80-$BF:$4000-$43FF

// NMI/IRQ
always @(posedge CLK) begin
    if (~RST_N) begin
        AUTO_JOY_EN <= 1'b0;
        HVIRQ_EN <= 2'b0;
        NMI_EN <= 1'b0;
        HTIME <= {9{1'b1}};
        VTIME <= {9{1'b1}};
        WRIO <= {8{1'b1}};
        MEMSEL <= 0;       
    end else if (ENABLE && INT_CLKF_CE) begin
        if (P65_A[15:8] == 8'h42 && ~P65_R_WN && IO_SEL) begin
            case (P65_A[7:0])
            8'h00 : begin
                AUTO_JOY_EN <= P65_DO[0];
                HVIRQ_EN <= P65_DO[5:4];
                NMI_EN <= P65_DO[7];
            end
            8'h01 :
                WRIO <= P65_DO;
            8'h07 :
                HTIME[7:0] <= P65_DO;
            8'h08 :
                HTIME[8] <= P65_DO[0];
            8'h09 :
                VTIME[7:0] <= P65_DO;
            8'h0A :
                VTIME[8] <= P65_DO[0];
            8'h0D :
                MEMSEL <= P65_DO[0];
            default: ;
            endcase
        end
    end
end

always @(posedge CLK) begin
    reg RDNMI_READ;
    if (~RST_N) begin
        NMI_FLAG <= 1'b0;
        VBLANK_OLD2 <= 0;
        NMI_LOCK <= 0;
    end else begin
        if (P65_R_WN && P65_A[15:0] == 16'h4210 && IO_SEL)
            RDNMI_READ = 1;
        else
            RDNMI_READ = 0;
        
        if (ENABLE) begin
            if (DOT_CLK_CE) begin
                VBLANK_OLD2 <= VBLANK;
                NMI_LOCK <= 0;
            end

            if (VBLANK && ~VBLANK_OLD2 && DOT_CLK_CE) begin
                NMI_FLAG <= 1;
                NMI_LOCK <= 1;
            end else if (~VBLANK && VBLANK_OLD2 && DOT_CLK_CE)
                NMI_FLAG <= 0;
            else if (RDNMI_READ && ~NMI_LOCK && INT_CLKF_CE)
                NMI_FLAG <= 0;
        end
    end
end

assign P65_NMI_N =  ~(NMI_EN & NMI_FLAG);

always @(posedge CLK) begin
    reg TIMEUP_READ, HVIRQ_DISABLE;
    if (~RST_N) begin
        IRQ_FLAG <= 0;
        HIRQ_VALID <= 0;
        VIRQ_VALID <= 0;
        IRQ_VALID <= 0;
        IRQ_VALID_OLD <= 0;
        IRQ_LOCK <= 0;
    end else begin
        if (P65_R_WN && P65_A[15:0] == 16'h4211 && IO_SEL)
            TIMEUP_READ = 1;
        else
            TIMEUP_READ = 0;

        if (~P65_R_WN && P65_A[15:0] == 16'h4200 && IO_SEL && P65_DO[5:4] == 2'b00) 
            HVIRQ_DISABLE = 1;
        else
            HVIRQ_DISABLE = 0;
        
        if (ENABLE) begin
            if (DOT_CLK_CE) begin
                if (H_CNT == HTIME+1 || HVIRQ_EN == 2'b10)
                    HIRQ_VALID <= 1;
                else
                    HIRQ_VALID <= 0;

                if (V_CNT == VTIME)
                    VIRQ_VALID <= 1;
                else
                    VIRQ_VALID <= 0;

                if (HVIRQ_EN == 2'b01 && HIRQ_VALID)       //H-IRQ:  every scanline, H=HTIME+~3.5
                    IRQ_VALID <= 1'b1;
                else if (HVIRQ_EN == 2'b10 && HIRQ_VALID && VIRQ_VALID)  //V-IRQ:  V=VTIME, H=~2.5--H_CNT <= 4 and
                    IRQ_VALID <= 1'b1;
                else if (HVIRQ_EN == 2'b11 && HIRQ_VALID && V_CNT == VTIME)
                    IRQ_VALID <= 1'b1;                        //HV-IRQ: V=VTIME, H=HTIME+~3.5
                else
                    IRQ_VALID <= 1'b0;

                IRQ_VALID_OLD <= IRQ_VALID;
                IRQ_LOCK <= 0;
            end

            if (HVIRQ_EN != 2'b00 && IRQ_VALID && ~IRQ_VALID_OLD && DOT_CLK_CE) begin
                IRQ_FLAG <= 1;
                IRQ_LOCK <= 1;
            end else if (TIMEUP_READ && ~IRQ_LOCK && INT_CLKF_CE) 
                IRQ_FLAG <= 0;
        
            if (HVIRQ_DISABLE && INT_CLKF_CE)
                IRQ_FLAG <= 0;
            
            if (~HBLANK && HBLANK_OLD)
                VIRQ_VALID <= 1'b0;
        end
    end
end

assign P65_IRQ_N =  ~IRQ_FLAG & IRQ_N;


// MATH
always @(posedge CLK) begin
    if (~RST_N) begin
        WRMPYA <= {8{1'b1}};
        //   WRMPYB <= 8'b0;
        WRDIVA <= {16{1'b1}};
        //   WRDIVB <= 8'b0;
        RDDIV <= 16'b0;
        RDMPY <= 16'b0;
        MUL_REQ <= 1'b0;
        DIV_REQ <= 1'b0;
        MATH_CLK_CNT <= 4'b0;
        MATH_TEMP <= 23'b0;
    end else if (ENABLE && INT_CLKF_CE) begin
        if (MUL_REQ) begin   // long multiplication (8 cycles)
            if (RDDIV[0])
                RDMPY <= RDMPY + MATH_TEMP[15:0];
            RDDIV <= {1'b0, RDDIV[15:1]};
            MATH_TEMP <= {MATH_TEMP[21:0], 1'b0};
            MATH_CLK_CNT <= MATH_CLK_CNT + 4'd1;
            if (MATH_CLK_CNT == 4'd7)
                MUL_REQ <= 1'b0;
        end

        if (DIV_REQ) begin  // long division (16 cycles)
            if ({7'b0, RDMPY} >= MATH_TEMP) begin
                RDMPY <= RDMPY - MATH_TEMP[15:0];
                RDDIV <= {RDDIV[14:0], 1'b1};
            end else
                RDDIV <= {RDDIV[14:0], 1'b0};
            MATH_TEMP <= {1'b0, MATH_TEMP[22:1]};
            MATH_CLK_CNT <= MATH_CLK_CNT + 4'd1;
            if (MATH_CLK_CNT == 4'd15)
                DIV_REQ <= 1'b0;
        end

        if (P65_A[15:8] == 8'h42 && ~P65_R_WN && IO_SEL) begin
            case (P65_A[7:0])
            8'h02 :
                WRMPYA <= P65_DO;
            8'h03 : begin
                // WRMPYB <= P65_DO;
                RDMPY <= 16'b0;
                if (~MUL_REQ && ~DIV_REQ) begin
                    RDDIV <= {P65_DO, WRMPYA};
                    MATH_TEMP <= {15'b0, P65_DO};
                    MATH_CLK_CNT <= 4'b0;
                    MUL_REQ <= 1'b1;                
                end
            end
            8'h04 :
                WRDIVA[7:0] <= P65_DO;
            8'h05 :
                WRDIVA[15:8] <= P65_DO;
            8'h06 : begin
                // WRDIVB <= P65_DO;
                RDMPY <= WRDIVA;
                if (~DIV_REQ && ~MUL_REQ) begin
                    // RDDIV <= 16'b0;
                    MATH_TEMP <= {P65_DO, 15'b0};
                    MATH_CLK_CNT <= 4'b0;
                    DIV_REQ <= 1'b1;                
                end
            end
            default : begin end
            endcase
        end
    end
end

always @* begin : P4
    reg [2:0] i;

    P65_DI = DI;
    if (IO_SEL) begin
        P65_DI = MDR;
        if (P65_A[15:8] == 8'h42) begin
            case (P65_A[7:0])
            8'h10 :
                P65_DI = {NMI_FLAG,MDR[6:4],4'b0010};            //RDNMI
            8'h11 :
                P65_DI = {IRQ_FLAG,MDR[6:0]};                    //TIMEUP
            8'h12 :
                P65_DI = {VBLANK,HBLANK,MDR[5:1],JOYRD_BUSY};    //HVBJOY
            8'h13 :
                P65_DI = 8'h00;                                  //RDIO
            8'h14 :
                P65_DI = RDDIV[7:0];                             //RDDIVL
            8'h15 :
                P65_DI = RDDIV[15:8];                            //RDDIVH
            8'h16 :
                P65_DI = RDMPY[7:0];                             //RDMPYL
            8'h17 :
                P65_DI = RDMPY[15:8];                            //RDMPYH
            8'h18 :
                P65_DI = JOY1_DATA[7:0];                         //JOY1L
            8'h19 :
                P65_DI = JOY1_DATA[15:8];                        //JOY1H
            8'h1A :
                P65_DI = JOY2_DATA[7:0];                         //JOY2L
            8'h1B :
                P65_DI = JOY2_DATA[15:8];                        //JOY2H
            8'h1C :
                P65_DI = JOY3_DATA[7:0];                         //JOY3L
            8'h1D :
                P65_DI = JOY3_DATA[15:8];                        //JOY3H
            8'h1E :
                P65_DI = JOY4_DATA[7:0];                         //JOY4L
            8'h1F :
                P65_DI = JOY4_DATA[15:8];                        //JOY4H
            default : 
                P65_DI = MDR;
            endcase
        end else if (P65_A[15:7] == {8'h43, 1'b0}) begin
            i = P65_A[6:4];
            case (P65_A[3:0])
            4'h0 :
                P65_DI = DMAP[i];                                //DMAPx
            4'h1 :
                P65_DI = BBAD[i];                                //BBADx
            4'h2 :
                P65_DI = A1T[i][7:0];                            //A1TxL
            4'h3 :
                P65_DI = A1T[i][15:8];                           //A1TxH
            4'h4 :
                P65_DI = A1B[i];                                 //A1Bx
            4'h5 :
                P65_DI = DAS[i][7:0];                            //DASxL
            4'h6 :
                P65_DI = DAS[i][15:8];                           //DASxH
            4'h7 :
                P65_DI = DASB[i];                                //DASBx
            4'h8 :
                P65_DI = A2A[i][7:0];                            //A2AxL
            4'h9 :
                P65_DI = A2A[i][15:8];                           //A2AxH
            4'hA :
                P65_DI = NTLR[i];                                //NTLRx
            4'hB, 4'hF :
                P65_DI = UNUSED[i];                              //UNUSEDx
            default : 
                P65_DI = MDR;
            endcase
        end else if (P65_A[15:8] == 8'h40) begin
            case (P65_A[7:0])
            8'h16 :
                P65_DI = {MDR[7:2], ~JOY1_DI[1], ~JOY1_DI[0]};
            8'h17 :
                P65_DI = {MDR[7:5], 3'b111, ~JOY2_DI[1], ~JOY2_DI[0]};
            default :
                P65_DI = MDR;
            endcase
        end
    end
end

assign JPIO67 = WRIO[7:6];


// Memory Data Register
always @(posedge CLK) begin
    if (~RST_N)
        MDR <= 8'b1111_1111;
    else begin
        if (INT_CLKR_CE) begin      // get post-CPU MDR data at falling edge
            if (P65_EN && (P65_VPA || P65_VDA) && ~P65_R_WN) 
                MDR <= P65_DO;
        end else if (INT_CLKF_CE) begin
            if (P65_EN && (P65_VPA || P65_VDA) && P65_R_WN) 
                MDR <= P65_DI;
            else if (DMA_ACTIVE && EN) 
                MDR <= DI;
        end
    end
end

assign DO = MDR;

// H/V Counters
always @(posedge CLK) begin
    if (~RST_N) begin
        DOT_CLK_CE <= 0;
        DOT_CLK_CNT <= 0;
        H_CNT <= 9'b0;
        V_CNT <= 9'b0;
        FIELD <= 1'b0;
        HBLANK_OLD <= 0;
        VBLANK_OLD <= 0;
    end else begin        // prepare H_CNT/V_CNT for dot generation in ~DOT_CLK phase
        if (ENABLE) begin
            DOT_CLK_CNT <= DOT_CLK_CNT + 1;

            DOT_CLK_CE <= 0;
            if (DOT_CLK_CNT == 2)
                DOT_CLK_CE <= 1;

            VBLANK_OLD <= VBLANK;
            HBLANK_OLD <= HBLANK;
            if (~HBLANK && HBLANK_OLD) begin
                H_CNT <= 0;
                V_CNT <= V_CNT + 9'd1;
            end else if (~VBLANK && VBLANK_OLD) 
                H_CNT <= 0;
            else if (DOT_CLK_CE) 
                H_CNT <= H_CNT + 9'd1;

            if (~VBLANK && VBLANK_OLD) begin
                V_CNT <= 0;
                FIELD <=  ~FIELD;
            end
        end
    end
end


// WRAM refresh once per scanline
always @(posedge CLK) begin
    if (~RST_N) begin
        REFRESHED <= 1'b0;
        REFS <= REFS_IDLE;
        REFRESH_CNT <= 0;
        HBLANK_REF_OLD <= 0;
    end else if (ENABLE && INT_CLKF_CE) begin      // align with CPU operation, 8 cycles * 5 = 40 master cycles
        HBLANK_REF_OLD <= HBLANK;
        case(REFS)
        REFS_IDLE:     
            if (H_CNT >= 133) begin
                REFRESHED <= 1;
                REFS <= REFS_EXEC;
            end
        
        REFS_EXEC: begin
            REFRESH_CNT <= REFRESH_CNT + 3'd1;
            if (REFRESH_CNT == 3'd4) begin
                REFRESHED <= 0;
                REFRESH_CNT <= 0;
                REFS <= REFS_END;
            end
        end

        REFS_END:       // wait till next scanline
            if (~HBLANK && HBLANK_REF_OLD)
                REFS <= REFS_IDLE;

        default: ;
        endcase
    end
end

assign SNES_REFRESH = REFRESHED;

//DMA/HDMA
always @(posedge CLK) begin : P2
    integer j;
    reg [2:0] i;
    reg [7:0] NEXT_NTLR;

    if (~RST_N) begin
        MDMAEN <= 8'b0;
        HDMAEN <= 8'b0;
        // these init uses 700 LUTs, avoid for now
        //   DMAP <= '{8{8'b1111_1111}};
        //   BBAD <= '{8{8'b1111_1111}};
        //   A1T <= '{8{16'b1111_1111_1111_1111}};
        //   A1B <= '{8{8'b1111_1111}};
        //   DAS <= '{8{16'b1111_1111_1111_1111}};
        //   DASB <= '{8{8'b1111_1111}};
        //   A2A <= '{8{16'b1111_1111_1111_1111}};
        //   NTLR <= '{8{8'b1111_1111}};
        //   UNUSED <= '{8{8'b1111_1111}};

        DMA_RUN <= 1'b0;
        HDMA_RUN <= 1'b0;
        HDMA_CH_RUN <= 8'b0;
        HDMA_CH_DO <= 8'b0;
        HDMA_CH_WORK <= 8'b0;
        DMA_TRMODE_STEP <= 2'b0;
        HDMA_TRMODE_STEP <= 2'b0;
        HDMA_INIT_STEP <= 0;
        HDMA_FIRST_INIT <= 1'b0;
        DS <= DS_IDLE;
        HDS <= HDS_IDLE;

        HDMA_INIT_EXEC <= 1'b1;
        HDMA_RUN_EXEC <= 1'b0;
    end else begin
        if (~P65_R_WN && IO_SEL && INT_CLKF_CE) begin
            if (P65_A[15:8] == 8'h42) begin
                case (P65_A[7:0])
                8'h0B :
                    MDMAEN <= P65_DO;       // $420B: Start DMA
                8'h0C :
                    HDMAEN <= P65_DO;
                default : ;
                endcase
            end else if (P65_A[15:7] == {8'h43, 1'b0}) begin
                i = P65_A[6:4];
                case (P65_A[3:0])
                4'h0 : DMAP[i] <= P65_DO;
                4'h1 : BBAD[i] <= P65_DO;
                4'h2 : A1T[i][7:0] <= P65_DO;
                4'h3 : A1T[i][15:8] <= P65_DO;
                4'h4 : A1B[i] <= P65_DO;
                4'h5 : DAS[i][7:0] <= P65_DO;
                4'h6 : DAS[i][15:8] <= P65_DO;
                4'h7 : DASB[i] <= P65_DO;
                4'h8 : A2A[i][7:0] <= P65_DO;
                4'h9 : A2A[i][15:8] <= P65_DO;
                4'hA : NTLR[i] <= P65_DO;
                4'hB,4'hF : UNUSED[i] <= P65_DO;
                default : ;
                endcase
            end
        end

        if (EN && INT_CLKF_CE) begin
            //DMA
            if (~HDMA_RUN) begin
                case(DS)
                DS_IDLE : begin
                    if (MDMAEN != 8'h00) begin
                        DMA_RUN <= 1'b1;
                        DS <= DS_CH_SEL;
                    end
                end
                DS_CH_SEL : begin
                    if (MDMAEN != 8'h00) begin
                        DAS[DCH] <= DAS[DCH] - 16'd1;
                        DMA_TRMODE_STEP <= 0;
                        DS <= DS_TRANSFER;
                    end else begin
                        DMA_RUN <= 1'b0;
                        DS <= DS_IDLE;
                    end
                end
                DS_TRANSFER : begin
                    if (MDMAEN[DCH]) begin
                        case (DMAP[DCH][4:3])
                        2'b00 : A1T[DCH] <= A1T[DCH] + 16'd1;
                        2'b10 : A1T[DCH] <= A1T[DCH] - 16'd1;
                        default : ;
                        endcase
                    end

                    if (DAS[DCH] != 16'h0000 && MDMAEN[DCH]) begin
                        DAS[DCH] <= DAS[DCH] - 16'd1;
                        DMA_TRMODE_STEP <= DMA_TRMODE_STEP + 2'd1;
                    end else begin
                        MDMAEN[DCH] <= 1'b0;
                        DS <= DS_CH_SEL;
                    end
                end
                default : ;
                endcase
            end

            //HDMA
            case (HDS)
            HDS_IDLE : begin
                if (H_CNT >= 6 && V_CNT == 0 && ~HDMA_INIT_EXEC) begin
                    HDMA_CH_RUN <= 8'b1111_1111;
                    HDMA_CH_DO <= 8'b0;
                    if (HDMAEN != 8'h00) begin
                        HDMA_RUN <= 1'b1;
                        HDS <= HDS_PRE_INIT;
                    end
                    HDMA_CH_EN <= HDMAEN;
                    HDMA_INIT_EXEC <= 1;
                end else if (V_CNT != 0 && HDMA_INIT_EXEC)
                    HDMA_INIT_EXEC <= 0;

                if (H_CNT >= 277 && ~VBLANK && ~HDMA_RUN_EXEC) begin
                    if ((HDMA_CH_RUN & HDMAEN) != 8'h00) begin
                        HDMA_RUN <= 1'b1;
                        HDS <= HDS_PRE_TRANSFER;
                    end
                    HDMA_CH_EN <= HDMAEN;
                    HDMA_RUN_EXEC <= 1;
                end else if (H_CNT < 277 && ~VBLANK && HDMA_RUN_EXEC)
                    HDMA_RUN_EXEC <= 0;
            end

            HDS_PRE_INIT : begin
                for (j=0; j <= 7; j = j + 1) begin
                    if (HDMA_CH_EN[j]) begin
                        A2A[j] <= A1T[j];
                        NTLR[j] <= 8'b0;
                        MDMAEN[j] <= 1'b0;
                    end
                end
                HDMA_CH_WORK <= HDMA_CH_EN;
                HDMA_FIRST_INIT <= 1'b1;
                HDS <= HDS_INIT;
            end

            HDS_INIT : begin
                NEXT_NTLR = NTLR[HCH] - 8'd1;
                if (NEXT_NTLR[6:0] == 7'b0 || HDMA_FIRST_INIT) begin
                    NTLR[HCH] <= DI;

                    if (DI == 8'h00) begin
                        HDMA_CH_RUN[HCH] <= 1'b0;
                        HDMA_CH_DO[HCH] <= 1'b0;
                    end else
                        HDMA_CH_DO[HCH] <= 1'b1;

                    if (~DMAP[HCH][6]) begin
                        HDMA_CH_WORK[HCH] <= 1'b0;
                        if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin        // MMM
                            HDMA_RUN <= 1'b0;
                            HDS <= HDS_IDLE;
                        end
                    end else begin
                        DAS[HCH] <= 0;
                        HDMA_INIT_STEP <= 0;
                        HDS <= HDS_INIT_IND;
                    end
                    A2A[HCH] <= A2A[HCH] + 16'd1;
                end else begin
                    NTLR[HCH] <= NEXT_NTLR;
                    HDMA_CH_DO[HCH] <= NEXT_NTLR[7];

                    HDMA_CH_WORK[HCH] <= 1'b0;
                    if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin          // MMM
                        HDMA_RUN <= 1'b0;
                        HDS <= HDS_IDLE;
                    end
                end
            end

            HDS_INIT_IND : begin
                DAS[HCH] <= {DI, DAS[HCH][15:8]};

                A2A[HCH] <= A2A[HCH] + 16'd1;
                if (~HDMA_INIT_STEP && IsLastHDMACh(HDMA_CH_WORK, HCH) && ~HDMA_CH_RUN[HCH]) begin
                    HDMA_CH_WORK[HCH] <= 0;
                    HDMA_RUN <= 1'b0;
                    HDS <= HDS_IDLE;
                end if (HDMA_INIT_STEP) begin
                    HDMA_CH_WORK[HCH] <= 1'b0;
                    if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin
                        HDMA_RUN <= 1'b0;
                        HDS <= HDS_IDLE;
                    end else 
                        HDS <= HDS_INIT;
                end
                HDMA_INIT_STEP <= ~HDMA_INIT_STEP;
            end

            HDS_PRE_TRANSFER : begin
                for (j=0; j <= 7; j = j + 1) begin
                    if (HDMA_CH_RUN[j] && HDMAEN[j]) 
                        MDMAEN[j] <= 1'b0;
                end

                HDMA_FIRST_INIT <= 1'b0;

                if ((HDMA_CH_DO & HDMA_CH_EN) != 8'h00) begin
                    HDMA_CH_WORK <= HDMA_CH_DO & HDMA_CH_EN;
                    HDMA_TRMODE_STEP <= 2'b0;
                    HDS <= HDS_TRANSFER;
                end else begin
                    HDMA_CH_WORK <= HDMA_CH_RUN & HDMA_CH_EN;
                    HDS <= HDS_INIT;
                end
            end

            HDS_TRANSFER : begin
                HDMA_TRMODE_STEP <= HDMA_TRMODE_STEP + 2'd1;
                if (~DMAP[HCH][6]) 
                    A2A[HCH] <= A2A[HCH] + 16'd1;
                else 
                    DAS[HCH] <= DAS[HCH] + 16'd1;
                
                if (HDMA_TRMODE_STEP == DMA_TRMODE_LEN[DMAP[HCH][2:0]]) begin
                    HDMA_TRMODE_STEP <= 2'b0;
                    HDMA_CH_WORK[HCH] <= 1'b0;
                    if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin          
                        HDMA_CH_WORK <= HDMA_CH_RUN & HDMA_CH_EN;
                        HDMA_INIT_STEP <= 0;
                        HDS <= HDS_INIT;
                    end
                end
            end

            default : ;
            endcase
        end
    end
end

`ifdef VERILATOR

reg DMA_RUNr;
reg [23:0] DMA_CAr;
always @(posedge CLK) begin
  DMA_RUNr <= DMA_RUN;
  DMA_CAr <= CA;
  if (DMA_RUN && ~DMA_RUNr) 
    $fdisplay(32'h80000002, "PC=%06x, DMA Started", DMA_CAr);
  else if (~DMA_RUN && DMA_RUNr)
    $fdisplay(32'h80000002, "DMA Finished");
end

`endif

assign HCH = GetDMACh(HDMA_CH_WORK);
assign DCH = GetDMACh(MDMAEN);

assign DMA_A = DS == DS_TRANSFER ? {A1B[DCH],A1T[DCH]} : 0;

assign DMA_B = DS == DS_TRANSFER ? BBAD[DCH] + {6'b0, DMA_TRMODE_TAB[DMAP[DCH][2:0]][DMA_TRMODE_STEP]} :
                {8{1'b1}};

assign HDMA_A = DMAP[HCH][6] && HDS == HDS_TRANSFER ? {DASB[HCH], DAS[HCH]} : 
                (~DMAP[HCH][6] && HDS == HDS_TRANSFER) || HDS == HDS_INIT || HDS == HDS_INIT_IND ? {A1B[HCH], A2A[HCH]} : 
                {24{1'b1}};
assign HDMA_B = HDS == HDS_TRANSFER ? BBAD[HCH] + {6'b0, DMA_TRMODE_TAB[DMAP[HCH][2:0]][HDMA_TRMODE_STEP]} :
                {8{1'b1}};

// These controls DMA between A and B bus, in both directions
// - DMA_A, DMA_A_RD, DMA_A_WR
// - DMA_B, DMA_B_WR, DMA_B_WR
// - HDMA_A, HDMA_A_RD, HDMA_A_WR
// - HDMA_B, HDMA_B_RD, HDMA_B_WR
always @* begin
    DMA_A_WR_CYC = 1'b0;
    DMA_A_RD_CYC = 1'b0;
    DMA_B_RD_CYC = 1'b0;
    DMA_B_WR_CYC = 1'b0;
    
    if (DS == DS_TRANSFER) begin
        DMA_A_WR_CYC = DMAP[DCH][7];
        DMA_A_RD_CYC = ~DMAP[DCH][7];
        DMA_B_WR_CYC = ~DMAP[DCH][7];
        DMA_B_RD_CYC = DMAP[DCH][7];
    end

    HDMA_A_WR_CYC = 1'b0;
    HDMA_A_RD_CYC = 1'b0;
    HDMA_B_WR_CYC = 1'b0;
    HDMA_B_RD_CYC = 1'b0;

    if (HDS == HDS_TRANSFER) begin
        HDMA_A_WR_CYC = DMAP[HCH][7];;
        HDMA_A_RD_CYC = ~DMAP[HCH][7];
        HDMA_B_WR_CYC = ~DMAP[HCH][7];
        HDMA_B_RD_CYC = DMAP[HCH][7];
    end else if (HDS == HDS_INIT || HDS == HDS_INIT_IND)
        HDMA_A_RD_CYC = 1'b1;
end

always @(posedge CLK) begin
    if (~RST_N) begin
        DMA_A_WR <= 0;
        DMA_A_RD <= 0;
        DMA_B_WR <= 0;
        DMA_B_RD <= 0;
        HDMA_A_WR <= 0;
        HDMA_A_RD <= 0;
        HDMA_B_WR <= 0;
        HDMA_B_RD <= 0;
    end else if (EN) begin
        if (INT_CLKR_CE) begin
            DMA_A_WR <= DMA_A_WR_CYC;
            DMA_A_RD <= DMA_A_RD_CYC;
            DMA_B_WR <= DMA_B_WR_CYC;
            DMA_B_RD <= DMA_B_RD_CYC;
        end else if (INT_CLKF_CE) begin
            DMA_A_WR <= 0;
            DMA_A_RD <= 0;
            DMA_B_WR <= 0;
            DMA_B_RD <= 0;
        end

        if (INT_CLKR_CE) begin
            HDMA_A_WR <= HDMA_A_WR_CYC;
            HDMA_A_RD <= HDMA_A_RD_CYC;
            HDMA_B_WR <= HDMA_B_WR_CYC;
            HDMA_B_RD <= HDMA_B_RD_CYC;
        end else if (INT_CLKF_CE) begin
            HDMA_A_WR <= 0;
            HDMA_A_RD <= 0;
            HDMA_B_WR <= 0;
            HDMA_B_RD <= 0;
        end
    end
end

//Joy old
always @(posedge CLK) begin
    if (~RST_N) begin
        OLD_JOY_STRB <= 1'b0;
        OLD_JOY1_CLK <= 1'b0;
        OLD_JOY2_CLK <= 1'b0;
    end else begin
        if (ENABLE && INT_CLKF_CE) begin
            OLD_JOY1_CLK <= 1'b0;
            OLD_JOY2_CLK <= 1'b0;
            if (P65_A[15:8] == 8'h40 && IO_SEL) begin
                if (~P65_R_WN) begin
                    case(P65_A[7:0])
                    8'h16 : 
                        OLD_JOY_STRB <= P65_DO[0];
                    default : ;
                    endcase
                end else begin
                    case(P65_A[7:0])
                    8'h16 : 
                        OLD_JOY1_CLK <= 1'b1;
                    8'h17 : 
                        OLD_JOY2_CLK <= 1'b1;
                    default : ;
                    endcase
                end
            end
        end
    end
end

// Joy auto
always @(posedge CLK) begin
    if (~RST_N) begin
        JOY1_DATA <= {16{1'b0}};
        JOY2_DATA <= {16{1'b0}};
        JOY3_DATA <= {16{1'b0}};
        JOY4_DATA <= {16{1'b0}};
        JOY_POLL_CLK <= {6{1'b0}};
        JOY_POLL_CNT <= {5{1'b0}};
        JOY_POLL_RUN <= 1'b0;
        JOYRD_BUSY <= 1'b0;
        AUTO_JOY_STRB <= 1'b0;
        AUTO_JOY_CLK <= 1'b0;
    end else begin
        if (ENABLE && DOT_CLK_CE) begin
            JOY_POLL_CLK <= JOY_POLL_CLK + 1;
            if (JOY_POLL_CLK[4:0] == 5'd31) begin
                if (JOY_POLL_CLK[5] && VBLANK && ~JOY_POLL_RUN && AUTO_JOY_EN)  begin
                    JOY_POLL_RUN <= 1;
                    JOY_POLL_CNT <= 0;
                end else if (JOY_POLL_CLK[5] && ~VBLANK && JOY_POLL_RUN && JOY_POLL_CNT == 5'd16) 
                    JOY_POLL_RUN <= 0;
                else if (JOY_POLL_RUN && JOY_POLL_CNT <= 15) begin
                    if (~JOY_POLL_STRB) begin
                        if (~JOY_POLL_CLK[5]) begin
                            AUTO_JOY_STRB <= 1;
                            JOYRD_BUSY <= 1;
                        end else begin
                            AUTO_JOY_STRB <= 0;
                            JOY_POLL_STRB <= 1;
                        end
                    end else begin
                        if (~JOY_POLL_CLK[5]) begin
                            JOY1_DATA[15:0] <= {JOY1_DATA[14:0], ~JOY1_DI[0]};
                            JOY2_DATA[15:0] <= {JOY2_DATA[14:0], ~JOY2_DI[0]};
                            JOY3_DATA[15:0] <= {JOY3_DATA[14:0], ~JOY1_DI[1]};
                            JOY4_DATA[15:0] <= {JOY4_DATA[14:0], ~JOY2_DI[1]};
                            AUTO_JOY_CLK <= 1;
                        end else begin
                            AUTO_JOY_CLK <= 0;
                            JOY_POLL_CNT <= JOY_POLL_CNT + 1;
                            if (JOY_POLL_CNT == 5'd15) begin
                                JOYRD_BUSY <= 0;
                                JOY_POLL_STRB <= 0;
                            end
                        end
                    end
                end 
            end
        end
    end
end

assign JOY_STRB = OLD_JOY_STRB | AUTO_JOY_STRB;
assign JOY1_CLK = OLD_JOY1_CLK | AUTO_JOY_CLK;
assign JOY2_CLK = OLD_JOY2_CLK | AUTO_JOY_CLK;

endmodule
