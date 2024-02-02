// File CPU.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
//
// nand2mario: This old design treats signals as clocks. This should be fixed
//       see : https://stackoverflow.com/questions/71625591/treat-signal-as-a-clock-in-verilog

module SCPU(
    // input CLK,            // Master clock 21 Mhz
    input WCLK,              // Work clock for all actual logic, half speed of CLK
    input RST_N,
    input ENABLE,

    output reg [23:0] CA,   // Addr Bus A: S-CPU to WRAM and Cart
    output reg CPURD_N,     // available one wclk after SYSCLKR_CE
    output reg CPUWR_N,

    output reg CPURD_CYC_N, // full-cycle version of CPURD_N
    output reg PARD_CYC_N,

    output reg [7:0] PA,    // Addr Bus B: Peripheral bus
    output reg PARD_N,      //    S-CPU to PPU, SMP, WRAM, Cart and expansion port
    output reg PAWR_N,
    input [7:0] DI,
    output [7:0] DO,

    output reg RAMSEL_N,
    output reg ROMSEL_N,
    output DMA_ACTIVE,

    // Sys clock: \___/   \___/   
    //            F   R   F   R
    // output LAST_CYCLE,      // Last cycle for current instruction
    output reg SYSCLKF_CE,  // Falling edge of SNES sys clock, for CPU operations.
    output reg SYSCLKR_CE,  // Rising edge of SNES sys clock, for memory accesses.
    output [7:6] JPIO67,
    output SNES_REFRESH,

    input HBLANK,
    input VBLANK,

    input IRQ_N,

    input [1:0] JOY1_DI,
    input [1:0] JOY2_DI,
    output JOY_STRB,
    output JOY1_CLK,
    output JOY2_CLK,

    output DBG_CPU_BRK,
    input [7:0] DBG_REG,
    output reg [7:0] DBG_DAT,
    input [7:0] DBG_DAT_IN,
    output [7:0] DBG_CPU_DAT,
    input DBG_CPU_WR
);

reg [1:0] CYCLE_TYPE;       // CPU cycle type: 0: 3-cycle, 1: 4-cycle, 2: 6-cycle
reg CPU_ACTIVEr, DMA_ACTIVEr;
reg [5:0] PH;               // one-hot phase signal for phase 0-5
reg DOT_CLK_CE;

wire EN;
reg [8:0] H_CNT;
reg [8:0] V_CNT;
reg FIELD;

// 65C816
wire P65_WE_N;
wire [23:0] P65_A;
wire [7:0] P65_DO;
reg [7:0] P65_DI;
wire P65_NMI_N; wire P65_IRQ_N;
wire P65_EN;
wire P65_VPA; wire P65_VDA;
wire P65_BRK;

parameter [1:0] XSLOW = 0, SLOW = 1, FAST = 2, SLOWFAST = 3;
reg [1:0] SPEED;

//CPU BUS
wire [23:0] INT_A;
wire IO_SEL;

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
reg [7:0] WRMPYB;
reg [15:0] WRDIVA;
reg [7:0] WRDIVB;
reg [8:0] HTIME = 9'b1_1111_1111;
reg [8:0] VTIME = 9'b1_1111_1111;
reg [7:0] MDMAEN;
reg [7:0] HDMAEN;
reg MEMSEL;
reg [15:0] RDDIV, RDMPY;

reg IRQ_FLAG_RST, IRQ_FLAG_RSTr;
reg NMI_FLAG, IRQ_FLAG;
reg MUL_REQ, DIV_REQ;
reg REFRESHED;
reg [3:0] MUL_CNT;
reg [22:0] MATH_TEMP;
reg HBLANKr, HBLANKrr;
reg VBLANKr, VBLANKrr;
reg IRQ_VALIDr;

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
// wire DMA_ACTIVE;
reg [7:0] HDMA_CH_WORK, HDMA_CH_RUN, HDMA_CH_DO;
reg HDMA_INIT_EXEC, HDMA_RUN_EXEC;

parameter [1:0] DS_IDLE = 0, DS_CH_SEL = 1, DS_TRANSFER = 2;
reg [1:0] DS;     // DMA state

parameter [2:0] HDS_IDLE = 0, HDS_PRE_INIT = 1, HDS_INIT = 2,
                HDS_INIT_IND = 3, HDS_PRE_TRANSFER = 4,
                HDS_TRANSFER = 5;
reg [2:0] HDS;

reg [1:0] HDMA_INIT_STEP;
reg [1:0] DMA_TRMODE_STEP, HDMA_TRMODE_STEP;
reg HDMA_FIRST_INIT;
// MMM: manually translated
// typedef logic [1:0] DmaTransMode[0:7][0:3];
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

function logic [2:0] NextDMACh(logic [7:0] data);
    return  data[0] ? 0 :
            data[1] ? 1 :
            data[2] ? 2 :
            data[3] ? 3 :
            data[4] ? 4 :
            data[5] ? 5 :
            data[6] ? 6 :
            data[7] ? 7 : 0;
endfunction

function logic IsLastHDMACh(logic [7:0] data, logic [2:0] ch);
    if ((data >> (ch+1)) == 8'h0)
        return 1;
    else
        return 0;
endfunction

// JOY
reg [15:0] JOY1_DATA; reg [15:0] JOY2_DATA; reg [15:0] JOY3_DATA; reg [15:0] JOY4_DATA;
reg AUTO_JOY_CLK;
reg OLD_JOY_STRB; reg AUTO_JOY_STRB;
reg OLD_JOY1_CLK; reg OLD_JOY2_CLK;
reg [5:0] JOY_POLL_CLK;
reg [4:0] JOY_POLL_CNT;
reg JOYRD_BUSY;
reg JOY_POLL_RUN;

//debug
// reg [15:0] FRAME_CNT;
wire P65_RDY;

assign DMA_ACTIVE = DMA_RUN | HDMA_RUN;

/*
mclk    /1\__/2\__/3\__/4\__/5\__/6\__/7\__/8\__/9\__/0\__/1\__/2\__/3\__/4\__/5\__/6\__/7\__/8\__/9\__/0\__/
wclk    / 1  \____/ 2  \____/ 3  \____/ 4  \____/ 5  \____/ 6  \____/ 7  \____/ 8  \____/ 9  \____/ 10 \____
phase   |    0    |    1    |    0    |    1    |    2    |    0    |    1    |    2    |    3    |    0    |
CPU_CLK __4-cycle_/         \_6-cycle_/                   \_8-cycle_/                             \12-cycle_/
DOT_CLK ___dot 1__/         \__dot 2__/         \_
*/

always @(posedge WCLK) begin : cpu_clk_gen
    if(RST_N == 1'b0) begin
        PH <= 6'd1;
        CPU_ACTIVEr <= 1'b1;
        DMA_ACTIVEr <= 1'b0;
    end else if (ENABLE) begin  // nand2mario: no F/R pulses when disabled for pause_snes_for_frame_sync to work
        if ((REFRESHED == 1'b1 && CPU_ACTIVEr == 1'b1) || DMA_ACTIVE)
            CYCLE_TYPE <= 1;  // 4 wclk == 8 mclk
        else if (SPEED == FAST || (SPEED == SLOWFAST && MEMSEL == 1'b1))
            CYCLE_TYPE <= 0;  // Internal cycle takes 6 mclk
        else if(SPEED == SLOW || (SPEED == SLOWFAST && MEMSEL == 1'b0))
            CYCLE_TYPE <= 1;  // Memory cycle takes 8 mclk
        else
            CYCLE_TYPE <= 2;  // IO cycles takes 12 mclk
        
        if (CYCLE_TYPE == 0 && PH[2] || (CYCLE_TYPE == 1 && PH[3]) || PH[5])
            PH <= 6'd1;
        else
            PH <= {PH[4:0], 1'b0};

        if (~DMA_ACTIVEr && DMA_ACTIVE && PH[3] && ~REFRESHED)
            DMA_ACTIVEr <= 1'b1;
        else if (DMA_ACTIVEr && ~DMA_ACTIVE && ~REFRESHED)
            DMA_ACTIVEr <= 1'b0;

        if (CPU_ACTIVEr && DMA_ACTIVE && ~DMA_ACTIVEr && ~REFRESHED)
            CPU_ACTIVEr <= 1'b0;
        else if (~CPU_ACTIVEr && ~DMA_ACTIVE && SYSCLKF_CE && ~REFRESHED)
            CPU_ACTIVEr <= 1'b1;
    end
end

always @(posedge WCLK) begin
    if (~RST_N) begin
        SYSCLKF_CE <= 0;
        SYSCLKR_CE <= 0;
    end else begin
        if (ENABLE) begin   // nand2mario: no F/R pulses when disabled for pause_snes_for_frame_sync to work
          // SYSCLKF_CE is always on first cycle
          if (CYCLE_TYPE == 0 && PH[2] || 
              (DMA_ACTIVEr || CYCLE_TYPE == 1) && PH[3] || 
              CYCLE_TYPE == 2 && PH[5])
            SYSCLKF_CE <= 1;
          if (PH[0])
            SYSCLKF_CE <= 0;

          // SYSCLKR_CE is on cycle 2
          if (PH[1])
            SYSCLKR_CE <= 1;
          else if (PH[2])
            SYSCLKR_CE <= 0;
        end
    end
end

// always @* begin
//     SYSCLKF_CE = 0;
//     SYSCLKR_CE = 0;
//     if (ENABLE) begin   // nand2mario: no F/R pulses when disabled for pause_snes_for_frame_sync to work
//       SYSCLKF_CE = PH[0];
//       if (DMA_ACTIVEr) begin
//           SYSCLKR_CE = PH[2];
//       end else begin
//           if (CYCLE_TYPE == 0 && PH[2] || CYCLE_TYPE == 1 && PH[2] || CYCLE_TYPE == 2 && PH[3])
//               SYSCLKR_CE = 1;
//       end
//     end
// end


assign EN = ENABLE & ~REFRESHED;
assign P65_EN = ~DMA_ACTIVE & EN;
wire P65_EN_IN_PHASE = P65_EN & SYSCLKF_CE;
// assign SYSCLK = INT_CLK;

// 65C816
P65C816 P65C816(
    .CLK(WCLK), .RST_N(RST_N), .WE_N(P65_WE_N),
    .D_IN(P65_DI), .D_OUT(P65_DO), .A_OUT(P65_A),
    .RDY_IN(P65_EN_IN_PHASE), .NMI_N(P65_NMI_N), .IRQ_N(P65_IRQ_N),
    .ABORT_N(1'b1), .VPA(P65_VPA), .VDA(P65_VDA),
    .RDY_OUT(P65_RDY), .CE(1'b1),
    .MLB(), .VPB(), .LAST_CYCLE(),
  
    .BRK_OUT(P65_BRK), .DBG_REG(DBG_REG), .DBG_DAT_IN(DBG_DAT_IN),
    .DBG_DAT_OUT(DBG_CPU_DAT), .DBG_DAT_WR(DBG_CPU_WR)
);

always @* begin
    SPEED = SLOW;
    if(P65_VPA == 1'b0 && P65_VDA == 1'b0)
      SPEED = FAST;
    else if(P65_A[22] == 1'b0) begin                            // $00-$3F, $80-$BF | System Area
      if(P65_A[15:9] == 7'b0100000)                             // $4000-$41FF | XSlow
        SPEED = XSLOW;
      else if(P65_A[15:13] == 3'b000 ||                         // $0000-$1FFF | Slow
              P65_A[15:13] == 3'b011)                           // $6000-$7FFF | Slow
        SPEED = SLOW;
      else if(P65_A[15] == 1'b1) begin                          // $8000-$FFFF | Fast,Slow
        if(P65_A[23] == 1'b0)
          SPEED = SLOW;
        else
          SPEED = SLOWFAST;
      end else
        SPEED = FAST;
    end
    else if(P65_A[23:22] == 2'b01)                              // $40-$7D | $0000-$FFFF | Slow
      SPEED = SLOW;                                             // $7E-$7F | $0000-$FFFF | Slow
    else if(P65_A[23:22] == 2'b11)                              // $C0-$FF | $0000-$FFFF | Fast,Slow
      SPEED = SLOWFAST;
end

//IO Registers
assign IO_SEL = P65_EN == 1'b1 && P65_A[22] == 1'b0 && P65_A[15:10] == 6'b010000
            && (P65_VPA == 1'b1 || P65_VDA == 1'b1) ? 1'b1 : 1'b0;  //$00-$3F/$80-$BF:$4000-$43FF

// NMI/IRQ

always @(posedge WCLK) begin
    if(RST_N == 1'b0) begin
      HVIRQ_EN <= 2'b0;
      NMI_EN <= 1'b0;
      AUTO_JOY_EN <= 1'b0;
      WRIO <= 8'b1111_1111;
      WRMPYA <= 8'b1111_1111;
      WRMPYB <= 8'b0;
      WRDIVA <= 16'b1111_1111_1111_1111;
      WRDIVB <= 8'b0;
      MEMSEL <= 1'b0;
      RDDIV <= 16'b0;
      RDMPY <= 16'b0;
      HTIME <= 9'b1_1111_1111;
      VTIME <= 9'b1_1111_1111;
      NMI_FLAG <= 1'b0;
      VBLANKrr <= 1'b0;
      IRQ_FLAG_RST <= 1'b0;
      MUL_REQ <= 1'b0;
      DIV_REQ <= 1'b0;
      MUL_CNT <= 4'b0;
      MATH_TEMP <= 23'b0;
    end else if (SYSCLKF_CE && ENABLE) begin     // negedge INT_CLK is PHASE 1
        VBLANKrr <= VBLANK;

        if(VBLANK == 1'b1 && VBLANKrr == 1'b0)
          NMI_FLAG <= 1'b1;
        else if(VBLANK == 1'b0 && VBLANKrr == 1'b1)
          NMI_FLAG <= 1'b0;
        else if(P65_WE_N == 1'b1 && P65_A[15:0] == 16'h4210 && IO_SEL == 1'b1)
          NMI_FLAG <= 1'b0;

        if(MUL_REQ == 1'b1) begin   // long multiplication (8 cycles)
          if(RDDIV[0] == 1'b1)
            RDMPY <= (RDMPY) + (MATH_TEMP[15:0]);
          RDDIV <= {1'b0, RDDIV[15:1]};
          MATH_TEMP <= {MATH_TEMP[21:0], 1'b0};
          MUL_CNT <= MUL_CNT + 4'd1;
          if(MUL_CNT == 4'd7)
            MUL_REQ <= 1'b0;
        end

        if (DIV_REQ == 1'b1) begin  // long division (16 cycles)
          if ({7'b0, RDMPY} >= MATH_TEMP) begin
            RDMPY <= (RDMPY) - (MATH_TEMP[15:0]);
            RDDIV <= {RDDIV[14:0],1'b1};
          end else
            RDDIV <= {RDDIV[14:0],1'b0};
          MATH_TEMP <= {1'b0, MATH_TEMP[22:1]};
          MUL_CNT <= MUL_CNT + 4'd1;
          if (MUL_CNT == 4'd15)
            DIV_REQ <= 1'b0;
        end

        IRQ_FLAG_RST <= 1'b0;
        if (P65_A[15:8] == 8'h42 && IO_SEL == 1'b1) begin
          if(P65_WE_N == 1'b0) begin
            case (P65_A[7:0])
            8'h00 : begin
              NMI_EN <= P65_DO[7];
              HVIRQ_EN <= P65_DO[5:4];
              AUTO_JOY_EN <= P65_DO[0];
              if(P65_DO[5:4] == 2'b00)
                IRQ_FLAG_RST <= 1'b1;
            end
            8'h01 :
              WRIO <= P65_DO;
            8'h02 :
              WRMPYA <= P65_DO;
            8'h03 : begin
              // WRMPYB <= P65_DO;
              RDMPY <= 16'b0;
              if (~MUL_REQ && ~DIV_REQ) begin
                RDDIV <= {P65_DO,WRMPYA};
                MATH_TEMP <= {15'b0, P65_DO};
                MUL_CNT <= 4'b0;
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
                MATH_TEMP <= {P65_DO,15'b0};
                MUL_CNT <= 4'b0;
                DIV_REQ <= 1'b1;                
              end
            end
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
            default : begin end
            endcase

          end else begin
            if (P65_A[7:0] == 8'h11)
              IRQ_FLAG_RST <= 1'b1;
          end
        end
    end
end

wire [2:0] INT_I = P65_A[6:4];

always @* begin : P4
    reg [2:0] i;

    P65_DI = DI;
    if(IO_SEL == 1'b1) begin
      P65_DI = MDR;
      if(P65_A[15:8] == 8'h42) begin
        case(P65_A[7:0])
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
        default : begin
          P65_DI = MDR;
        end
        endcase
      end
      else if(P65_A[15:8] == 8'h43) begin
        case(P65_A[3:0])
        4'h0 :
          P65_DI = DMAP[INT_I];                                //DMAPx
        4'h1 :
          P65_DI = BBAD[INT_I];                                //BBADx
        4'h2 :
          P65_DI = A1T[INT_I][7:0];                            //A1TxL
        4'h3 :
          P65_DI = A1T[INT_I][15:8];                           //A1TxH
        4'h4 :
          P65_DI = A1B[INT_I];                                 //A1Bx
        4'h5 :
          P65_DI = DAS[INT_I][7:0];                            //DASxL
        4'h6 :
          P65_DI = DAS[INT_I][15:8];                           //DASxH
        4'h7 :
          P65_DI = DASB[INT_I];                                //DASBx
        4'h8 :
          P65_DI = A2A[INT_I][7:0];                            //A2AxL
        4'h9 :
          P65_DI = A2A[INT_I][15:8];                           //A2AxH
        4'hA :
          P65_DI = NTLR[INT_I];                                //NTLRx
        4'hB :
          P65_DI = UNUSED[INT_I];                              //UNUSEDx
        default : begin
          P65_DI = MDR;
        end
        endcase
      end
      else if(P65_A[15:8] == 8'h40) begin
        case(P65_A[7:0])
        8'h16 :
          P65_DI = {MDR[7:2], ~JOY1_DI[1],( ~JOY1_DI[0]) | AUTO_JOY_EN};
        8'h17 :
          P65_DI = {MDR[7:5],3'b111, ~JOY2_DI[1],( ~JOY2_DI[0]) | AUTO_JOY_EN};
        default :
          P65_DI = MDR;
        endcase
      end
    end
end

assign JPIO67 = WRIO[7:6];

// Memory Data Register
always @(posedge WCLK) begin
    if(RST_N == 1'b0)
        MDR <= 8'b1111_1111;
    else if (SYSCLKR_CE) begin      // get post-CPU MDR data at falling edge
        if(P65_EN && (P65_VPA || P65_VDA) && ~P65_WE_N) 
            MDR <= P65_DO;
    end else if (SYSCLKF_CE) begin
        if (P65_EN && (P65_VPA || P65_VDA) && P65_WE_N) 
            MDR <= P65_DI;
        else if (DMA_ACTIVE && EN) 
            MDR <= DI;
    end
end

// assign DO = MDR;
// nand2mario: we need the P65_DO for writes in phase 0 or 1
assign DO = P65_EN && (P65_VPA || P65_VDA) && ~P65_WE_N ?
       P65_DO : MDR;

// H/V Counters
// always @(negedge DOT_CLK, negedge RST_N) begin
always @(posedge WCLK) begin
    if(RST_N == 1'b0) begin
      DOT_CLK_CE <= 0;
      H_CNT <= 9'b0;
      V_CNT <= 9'b0;
      FIELD <= 1'b0;
      // FRAME_CNT <= 16'b0;
      VBLANKr <= 1'b0;
    end else begin        // prepare H_CNT/V_CNT for dot generation in ~DOT_CLK phase
      if (ENABLE) begin
        DOT_CLK_CE <= ~DOT_CLK_CE;
        VBLANKr <= VBLANK;
        HBLANKr <= HBLANK;
        if (~HBLANK && HBLANKr) begin
          H_CNT <= 0;
          V_CNT <= V_CNT + 9'd1;
        end else if (~VBLANK && VBLANKr) begin
          H_CNT <= 0;
        end else if (DOT_CLK_CE) begin
          H_CNT <= H_CNT + 9'd1;
        end
        if(~VBLANK && VBLANKr) begin
          V_CNT <= 0;
          FIELD <=  ~FIELD;
          // FRAME_CNT <= FRAME_CNT + 16'd1;
        end
      end
    end
end

// IRQ
// always @(negedge RST_N, negedge DOT_CLK) begin : P3
always @(posedge WCLK) begin : P3
    reg IRQ_VALID;

    if(RST_N == 1'b0) begin
      IRQ_FLAG <= 1'b0;
      IRQ_VALIDr <= 1'b0;
      IRQ_FLAG_RSTr <= 1'b0;
    end else begin
      if(ENABLE && DOT_CLK_CE) begin
        if(HVIRQ_EN == 2'b01 && H_CNT == (HTIME))       //H-IRQ:  every scanline, H=HTIME+~3.5
          IRQ_VALID = 1'b1;
        else if(HVIRQ_EN == 2'b10 && V_CNT == (VTIME))  //V-IRQ:  V=VTIME, H=~2.5--H_CNT <= 4 and
          IRQ_VALID = 1'b1;
        else if(HVIRQ_EN == 2'b11 && H_CNT == (HTIME) && V_CNT == (VTIME))
                                                        //HV-IRQ: V=VTIME, H=HTIME+~3.5
          IRQ_VALID = 1'b1;
        else
          IRQ_VALID = 1'b0;

        IRQ_VALIDr <= IRQ_VALID;
        IRQ_FLAG_RSTr <= IRQ_FLAG_RST;
        if(IRQ_FLAG == 1'b0 && IRQ_VALID == 1'b1 && IRQ_VALIDr == 1'b0)
          IRQ_FLAG <= 1'b1;
        else if(IRQ_FLAG == 1'b1 && IRQ_FLAG_RST == 1'b1 && IRQ_FLAG_RSTr == 1'b0)
          IRQ_FLAG <= 1'b0;
      end
    end
end

assign P65_NMI_N =  ~(NMI_EN & NMI_FLAG);
assign P65_IRQ_N =  ~IRQ_FLAG & IRQ_N;

reg [2:0] REFRESH_CNT;
reg [1:0] REFS;
reg HBLANK_REF_OLD;

// WRAM refresh once per scanline
always @(posedge WCLK) begin
    if (RST_N == 1'b0) begin
      REFRESHED <= 1'b0;
      REFRESH_CNT <= 0;
      REFS <= 0;
    end else if (ENABLE && SYSCLKF_CE) begin      // align with CPU operation, 8 cycles * 5 = 40 master cycles
      HBLANK_REF_OLD <= HBLANK;
      case(REFS)
      2'd0:       // idle
        if(H_CNT >= 133) begin
          REFRESHED <= 1;
          REFS <= 2'd1;
        end
      2'd1: begin // refreshing
        REFRESH_CNT <= REFRESH_CNT + 3'd1;
        if (REFRESH_CNT == 3'd4) begin
          REFRESHED <= 0;
          REFRESH_CNT <= 0;
          REFS <= 2'd2;
        end
      end
      2'd2:       // wait till next scanline
        if (~HBLANK && HBLANK_REF_OLD)
          REFS <= 0;
      default: ;
      endcase
    end
end

assign SNES_REFRESH = REFRESHED /*& INT_CLK*/;

//DMA/HDMA
// always @(negedge RST_N, negedge INT_CLK) begin : P2
always @(posedge WCLK) begin : P2
    integer j;
    reg [2:0] i;
    reg [7:0] NEXT_NTLR;

    if(RST_N == 1'b0) begin
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
      HDMA_INIT_STEP <= 2'b0;
      HDMA_FIRST_INIT <= 1'b0;
      DS <= DS_IDLE;
      HDS <= HDS_IDLE;

      HDMA_INIT_EXEC <= 1'b1;
      HDMA_RUN_EXEC <= 1'b0;
      HBLANKrr <= 1'b0;
    end else if (SYSCLKF_CE) begin
      if(P65_WE_N == 1'b0 && IO_SEL == 1'b1) begin
        if(P65_A[15:8] == 8'h42) begin
          case(P65_A[7:0])
          8'h0B :
            MDMAEN <= P65_DO;       // $420B: Start DMA
          8'h0C :
            HDMAEN <= P65_DO;
          default : ;
          endcase
        end
        else if(P65_A[15:8] == 8'h43) begin
          i = P65_A[6:4];
          case(P65_A[3:0])
          4'h0 :
            DMAP[i] <= P65_DO;
          4'h1 :
            BBAD[i] <= P65_DO;
          4'h2 :
            A1T[i][7:0] <= P65_DO;
          4'h3 :
            A1T[i][15:8] <= P65_DO;
          4'h4 :
            A1B[i] <= P65_DO;
          4'h5 :
            DAS[i][7:0] <= P65_DO;
          4'h6 :
            DAS[i][15:8] <= P65_DO;
          4'h7 :
            DASB[i] <= P65_DO;
          4'h8 :
            A2A[i][7:0] <= P65_DO;
          4'h9 :
            A2A[i][15:8] <= P65_DO;
          4'hA :
            NTLR[i] <= P65_DO;
          4'hB :
            UNUSED[i] <= P65_DO;
          default : begin end
          endcase
        end
      end

      if(EN == 1'b1) begin
        //DMA
        if(~HDMA_RUN) begin
          case(DS)
          DS_IDLE : begin
            if(MDMAEN != 8'h00) begin
              DMA_RUN <= 1'b1;
              DS <= DS_CH_SEL;
            end
          end
          DS_CH_SEL : begin
            if(MDMAEN != 8'h00) begin
              DAS[DCH] <= DAS[DCH] - 16'd1;
              DMA_TRMODE_STEP <= {2{1'b0}};
//              DAS0 <= DAS0 - 16'd1;     // for debug
              DS <= DS_TRANSFER;
            end else begin
              DMA_RUN <= 1'b0;
              DS <= DS_IDLE;
            end
          end
          DS_TRANSFER : begin
            case(DMAP[DCH][4:3])
            2'b00 :
              A1T[DCH] <= A1T[DCH] + 16'd1;
            2'b10 :
              A1T[DCH] <= A1T[DCH] - 16'd1;
            default : ;
            endcase
            if(DAS[DCH] != 16'h0000) begin
              DAS[DCH] <= DAS[DCH] - 16'd1;
              DMA_TRMODE_STEP <= DMA_TRMODE_STEP + 2'd1;
            end else begin
              MDMAEN[DCH] <= 1'b0;
              DS <= DS_CH_SEL;
            end
          end
          default : begin end
          endcase
        end

        //HDMA
        HBLANKrr <= HBLANK;
        HDMA_RUN_EXEC <= 1'b0;
        if(HBLANK == 1'b1 && HBLANKrr == 1'b0 && VBLANK == 1'b0) begin
          HDMA_RUN_EXEC <= 1'b1;
        end

        HDMA_INIT_EXEC <= 1'b0;
        if(VBLANK == 1'b0 && VBLANKrr == 1'b1) begin
          HDMA_INIT_EXEC <= 1'b1;
        end

        case(HDS)
        HDS_IDLE : begin
          if(HDMA_INIT_EXEC == 1'b1) begin
            HDMA_CH_RUN <= 8'b1111_1111;
            HDMA_CH_DO <= 8'b0;
            if(HDMAEN != 8'h00) begin
              HDMA_RUN <= 1'b1;
              HDS <= HDS_PRE_INIT;
            end
          end
          if(HDMA_RUN_EXEC == 1'b1) begin
            if((HDMA_CH_RUN & HDMAEN) != 8'h00) begin
              HDMA_RUN <= 1'b1;
              HDS <= HDS_PRE_TRANSFER;
            end
          end
        end

        HDS_PRE_INIT : begin
          for (j=0; j <= 7; j = j + 1) begin
            if(HDMAEN[j] == 1'b1) begin
              A2A[j] <= A1T[j];
              NTLR[j] <= 8'b0;
              MDMAEN[j] <= 1'b0;
            end
          end
          HDMA_CH_WORK <= HDMAEN;
          HDMA_FIRST_INIT <= 1'b1;
          HDS <= HDS_INIT;
        end

        HDS_INIT : begin
          NEXT_NTLR = NTLR[HCH] - 8'd1;
          if(NEXT_NTLR[6:0] == 7'b0000000 || HDMA_FIRST_INIT == 1'b1) begin
            NTLR[HCH] <= DI;

            if(DI == 8'h00) begin
              HDMA_CH_RUN[HCH] <= 1'b0;
              HDMA_CH_DO[HCH] <= 1'b0;
            end else
              HDMA_CH_DO[HCH] <= 1'b1;

            if(DMAP[HCH][6] == 1'b0) begin
              HDMA_CH_WORK[HCH] <= 1'b0;
              if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin        // MMM
                HDMA_RUN <= 1'b0;
                HDS <= HDS_IDLE;
              end
            end else begin
              HDMA_INIT_STEP <= 2'b0;
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
          DAS[HCH] <= {DI,DAS[HCH][15:8]};
          HDMA_INIT_STEP <= HDMA_INIT_STEP + 2'd1;
          A2A[HCH] <= A2A[HCH] + 16'd1;
          if(HDMA_INIT_STEP[0] == 1'b1) begin
            HDMA_CH_WORK[HCH] <= 1'b0;
            if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin          // MMM
              HDMA_RUN <= 1'b0;
              HDS <= HDS_IDLE;
            end else begin
              HDS <= HDS_INIT;
            end
          end
        end

        HDS_PRE_TRANSFER : begin
          for (j=0; j <= 7; j = j + 1) begin
            if(HDMA_CH_RUN[j] == 1'b1 && HDMAEN[j] == 1'b1) 
              MDMAEN[j] <= 1'b0;
          end

          HDMA_FIRST_INIT <= 1'b0;

          if(HDMA_CH_DO != 8'h00) begin
            HDMA_CH_WORK <= HDMA_CH_DO & HDMAEN;
            HDMA_TRMODE_STEP <= 2'b0;
            HDS <= HDS_TRANSFER;
          end else begin
            HDMA_CH_WORK <= HDMA_CH_RUN & HDMAEN;
            HDS <= HDS_INIT;
          end
        end

        HDS_TRANSFER : begin
          HDMA_TRMODE_STEP <= HDMA_TRMODE_STEP + 2'd1;
          if(DMAP[HCH][6] == 1'b0) 
            A2A[HCH] <= A2A[HCH] + 16'd1;
          else 
            DAS[HCH] <= DAS[HCH] + 16'd1;
          
          if (HDMA_TRMODE_STEP == DMA_TRMODE_LEN[DMAP[HCH][2:0]]) begin     // MMM
            HDMA_TRMODE_STEP <= 2'b0;
            HDMA_CH_WORK[HCH] <= 1'b0;
            if (IsLastHDMACh(HDMA_CH_WORK, HCH)) begin          // MMM
              HDMA_CH_WORK <= HDMA_CH_RUN & HDMAEN;
              HDMA_INIT_STEP <= {2{1'b0}};
              HDS <= HDS_INIT;
            end
          end
        end
        default : begin end
        endcase
      end
    end
end

`ifdef VERILATOR

reg DMA_RUNr;
reg [23:0] DMA_CAr;
always @(posedge WCLK) begin
  DMA_RUNr <= DMA_RUN;
  DMA_CAr <= CA;
  if (DMA_RUN && ~DMA_RUNr) 
    $display("PC=%06x, DMA Started", DMA_CAr);
  else if (~DMA_RUN && DMA_RUNr)
    $display("DMA Finished");
end

`endif

// These controls DMA between A and B bus, in both directions
// - DMA_A, DMA_A_RD, DMA_A_WR
// - DMA_B, DMA_B_WR, DMA_B_WR
// - HDMA_A, HDMA_A_RD, HDMA_A_WR
// - HDMA_B, HDMA_B_RD, HDMA_B_WR
always @* begin
    HCH = NextDMACh(HDMA_CH_WORK);
    DCH = NextDMACh(MDMAEN);
    DMA_A = DS == DS_TRANSFER ? {A1B[DCH],A1T[DCH]} : {24{1'b1}};
    DMA_B = BBAD[DCH] + {6'b0, DMA_TRMODE_TAB[DMAP[DCH][2:0]][DMA_TRMODE_STEP]};       // MMM
    HDMA_A = DMAP[HCH][6] == 1'b1 && HDS == HDS_TRANSFER ? {DASB[HCH], DAS[HCH]} : 
                DMAP[HCH][6] == 1'b0 && HDS == HDS_TRANSFER ? {A1B[HCH], A2A[HCH]} : 
                HDS == HDS_INIT || HDS == HDS_INIT_IND ? {A1B[HCH], A2A[HCH]} : 24'b1;
    HDMA_B = BBAD[HCH] + {6'b0, DMA_TRMODE_TAB[DMAP[HCH][2:0]][HDMA_TRMODE_STEP]};       // MMM

    if (DS == DS_TRANSFER) begin
        DMA_A_WR_CYC = DMAP[DCH][7];
        DMA_A_RD_CYC = ~DMAP[DCH][7];
        DMA_B_RD_CYC = DMAP[DCH][7];
        DMA_B_WR_CYC = ~DMAP[DCH][7];
    end else begin
        DMA_A_WR_CYC = 1'b0;
        DMA_A_RD_CYC = 1'b0;
        DMA_B_RD_CYC = 1'b0;
        DMA_B_WR_CYC = 1'b0;
    end

    if (HDS == HDS_TRANSFER) begin
      HDMA_A_WR_CYC = DMAP[HCH][7];;
      HDMA_A_RD_CYC = ~DMAP[HCH][7];
      HDMA_B_WR_CYC = ~DMAP[HCH][7];
      HDMA_B_RD_CYC = DMAP[HCH][7];
    end else begin
      HDMA_A_WR_CYC = 1'b0;
      if (HDS == HDS_INIT || HDS == HDS_INIT_IND)
        HDMA_A_RD_CYC = 1'b1;
      else
        HDMA_A_RD_CYC = 1'b0;
      HDMA_B_WR_CYC = 1'b0;
      HDMA_B_RD_CYC = 1'b0;
    end
end

always @(posedge WCLK) begin
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
    if (SYSCLKR_CE) begin
      DMA_A_WR <= DMA_A_WR_CYC;
      DMA_A_RD <= DMA_A_RD_CYC;
      DMA_B_WR <= DMA_B_WR_CYC;
      DMA_B_RD <= DMA_B_RD_CYC;
      HDMA_A_WR <= HDMA_A_WR_CYC;
      HDMA_A_RD <= HDMA_A_RD_CYC;
      HDMA_B_WR <= HDMA_B_WR_CYC;
      HDMA_B_RD <= HDMA_B_RD_CYC;
    end else if (SYSCLKF_CE) begin
      DMA_A_WR <= 0;
      DMA_A_RD <= 0;
      DMA_B_WR <= 0;
      DMA_B_RD <= 0;
      HDMA_A_WR <= 0;
      HDMA_A_RD <= 0;
      HDMA_B_WR <= 0;
      HDMA_B_RD <= 0;      
    end
  end
end


assign INT_A =  HDMA_RUN == 1'b1 ? HDMA_A :
                DMA_RUN == 1'b1 ? DMA_A : P65_A;

always @* begin
    RAMSEL_N = 1'b1;
    ROMSEL_N  = 1'b1;
    CA = INT_A;
    if(INT_A[22] == 1'b0) begin                 //$00-$3F, $80-$BF
      if(INT_A[15:13] <= 3'b000) begin          //$0000-$1FFF | Slow  | Address Bus A + /WRAM (mirror $7E:0000-$1FFF)
        CA[23:13] = {8'h7E,3'b000};
        RAMSEL_N = 1'b0;
      end else if(INT_A[15] == 1'b1)            //$8000-$FFFF | Slow  | Address Bus A + /CART
        ROMSEL_N = 1'b0;
    end else begin                              //$40-$7F, $C0-$FF
        if (INT_A[23:17] == 7'b0111111)         //$7E-$7F | $0000-$FFFF | Slow  | Address Bus A + /WRAM
            RAMSEL_N = 1'b0;      
        else if (INT_A[23:22] == 2'b01              //$40-$7D | $0000-$FFFF | Slow  | Address Bus A + /CART
              || INT_A[23:22] == 2'b11)             //$C0-$FF | $0000-$FFFF | Fast,Slow | Address Bus A + /CART
            ROMSEL_N = 1'b0;
    end
end

reg CPU_WR, CPU_RD;

always @(posedge WCLK) begin
  if (~RST_N) begin
    CPU_WR <= 0;
    CPU_RD <= 0;
  end else if (EN) begin
    if (SYSCLKR_CE) begin
      if (P65_EN && (P65_VPA || P65_VDA)) begin
        CPU_WR <= ~P65_WE_N;
        CPU_RD <= P65_WE_N;
      end else begin
        CPU_WR <= 0;
        CPU_RD <= 0;
      end   
    end if (SYSCLKF_CE) begin
      CPU_WR <= 0;
      CPU_RD <= 0;
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
  end else if (P65_A[22] == 1'b0 && P65_A[15:8] == 8'h21) begin
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
    CPUWR_N =  ~HDMA_A_WR;
  end else if (DMA_RUN && EN) begin
    CPURD_N =  ~DMA_A_RD;
    CPUWR_N =  ~DMA_A_WR;
  end else if (P65_EN) begin
    CPURD_N =  ~CPU_RD;
    CPUWR_N =  ~CPU_WR;
  end else begin
    CPURD_N = 1'b1;
    CPUWR_N = 1'b1;
  end
end

always @* begin
  if (HDMA_RUN && EN)
    PARD_CYC_N = ~HDMA_B_RD_CYC;
  else if (DMA_RUN && EN)
    PARD_CYC_N = ~DMA_B_RD_CYC;
  else if (P65_A[22] == 1'b0 && P65_A[15:8] == 8'h21 && P65_EN)
    PARD_CYC_N = ~P65_WE_N;
  else
    PARD_CYC_N = 1'b1;

  if (HDMA_RUN && EN)
    CPURD_CYC_N = ~HDMA_A_RD_CYC;
  else if (DMA_RUN && EN)
    CPURD_CYC_N = ~DMA_A_RD_CYC;
  else if (P65_EN)
    CPURD_CYC_N = ~P65_WE_N;
  else
    CPURD_CYC_N = 1'b1;
end

//Joy old
// always @(negedge RST_N, negedge INT_CLK) begin
always @(posedge WCLK) begin
    if(RST_N == 1'b0) begin
      OLD_JOY_STRB <= 1'b0;
      OLD_JOY1_CLK <= 1'b0;
      OLD_JOY2_CLK <= 1'b0;
    end else begin
      if(ENABLE == 1'b1 && SYSCLKF_CE) begin
        OLD_JOY1_CLK <= 1'b0;
        OLD_JOY2_CLK <= 1'b0;
        if (P65_A[15:8] == 8'h40 && IO_SEL == 1'b1) begin
          if (P65_WE_N == 1'b0) begin
            case(P65_A[7:0])
            8'h16 : 
              OLD_JOY_STRB <= P65_DO[0];
            default : begin end
            endcase
          end
          else begin
            case(P65_A[7:0])
            8'h16 : 
              OLD_JOY1_CLK <= 1'b1;
            8'h17 : 
              OLD_JOY2_CLK <= 1'b1;
            default : begin end
            endcase
          end
        end
      end
    end
end

// Joy auto
// always @(negedge RST_N, negedge DOT_CLK) begin
always @(posedge WCLK) begin
    if(RST_N == 1'b0) begin
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
        // Poll all controllers once every VBLANK
        if (V_CNT == 0) 
          JOY_POLL_CNT <= 0;

        JOY_POLL_CLK <= JOY_POLL_CLK + 1;
      if(JOY_POLL_CLK == 63 && VBLANK == 1'b1 && JOY_POLL_RUN == 1'b0 && JOY_POLL_CNT == 0) 
          JOY_POLL_RUN <= 1'b1;
        else if(JOY_POLL_CLK[4:0] == 31 && JOY_POLL_RUN == 1'b1) begin
          if(JOY_POLL_CNT == 0) 
            AUTO_JOY_STRB <= ( ~JOY_POLL_CLK[5]) & AUTO_JOY_EN;         // 0 : strobe
          else 
            AUTO_JOY_CLK <= ( ~JOY_POLL_CLK[5]) & AUTO_JOY_EN;          // 1-15: clock 

          if(JOY_POLL_CLK[5] == 1'b1) begin                             // * : 63
            JOY_POLL_CNT <= JOY_POLL_CNT + 1;
            JOY1_DATA[15:0] <= {JOY1_DATA[14:0], ~JOY1_DI[0]};
            JOY2_DATA[15:0] <= {JOY2_DATA[14:0], ~JOY2_DI[0]};
            JOY3_DATA[15:0] <= {JOY3_DATA[14:0], ~JOY1_DI[1]};
            JOY4_DATA[15:0] <= {JOY4_DATA[14:0], ~JOY2_DI[1]};
          end

          if(JOY_POLL_CNT == 0 && JOY_POLL_CLK[5] == 1'b0)              // 0 : 31
            JOYRD_BUSY <= 1'b1;
          else if(JOY_POLL_CNT == 16 && JOY_POLL_CLK[5] == 1'b1) begin  // 15 : 63  
            JOYRD_BUSY <= 1'b0;
            JOY_POLL_RUN <= 1'b0;
          end
        end
      end
    end
end

assign JOY_STRB = AUTO_JOY_EN == 1'b0 ? OLD_JOY_STRB : AUTO_JOY_STRB;
assign JOY1_CLK = AUTO_JOY_EN == 1'b0 ? OLD_JOY1_CLK : AUTO_JOY_CLK;
assign JOY2_CLK = AUTO_JOY_EN == 1'b0 ? OLD_JOY2_CLK : AUTO_JOY_CLK;

always @(posedge WCLK) begin
  reg [31:0] i;
  if(DBG_REG[7] == 1'b0) begin
     case(DBG_REG)
     8'h00 : 
       DBG_DAT <= {NMI_EN,1'b0,HVIRQ_EN,3'b000,AUTO_JOY_EN};
     8'h01 : 
       DBG_DAT <= WRIO;
     8'h02 : 
       DBG_DAT <= WRMPYA;
     8'h03 : 
       DBG_DAT <= WRMPYB[7:0];
     8'h04 : 
       DBG_DAT <= WRDIVA[7:0];
     8'h05 : 
       DBG_DAT <= WRDIVA[15:8];
     8'h06 : 
       DBG_DAT <= WRDIVB[7:0];
     8'h07 : 
       DBG_DAT <= HTIME[7:0];
     8'h08 : 
       DBG_DAT <= {7'b0000000,HTIME[8]};
     8'h09 : 
       DBG_DAT <= VTIME[7:0];
     8'h0A : 
       DBG_DAT <= {7'b0000000,VTIME[8]};
     8'h0B : 
       DBG_DAT <= {7'b0000000,MEMSEL};
     8'h0C : 
       DBG_DAT <= MDMAEN;
     8'h0D : 
       DBG_DAT <= HDMAEN;
     8'h0E : 
       DBG_DAT <= 8'h00;
     8'h0F : 
       DBG_DAT <= 8'h00;
     8'h10 : 
       DBG_DAT <= {NMI_FLAG,7'b0000000};
     8'h11 : 
       DBG_DAT <= {IRQ_FLAG,7'b0000000};
     8'h12 : 
       DBG_DAT <= {VBLANK,HBLANK,5'b00000,JOYRD_BUSY};
     8'h13 : 
       DBG_DAT <= RDDIV[7:0];
     8'h14 : 
       DBG_DAT <= RDDIV[15:8];
     8'h15 : 
       DBG_DAT <= RDMPY[7:0];
     8'h16 : 
       DBG_DAT <= RDMPY[15:8];
     8'h17 : 
       DBG_DAT <= MDR;
     8'h18 : 
       DBG_DAT <= H_CNT[7:0];
     8'h19 : 
       DBG_DAT <= {7'b0000000,H_CNT[8]};
     8'h1A : 
       DBG_DAT <= V_CNT[7:0];
     8'h1B : 
       DBG_DAT <= {FIELD,6'b000000,V_CNT[8]};
     8'h1C : 
       DBG_DAT <= JOY1_DATA[7:0];
     8'h1D : 
       DBG_DAT <= JOY1_DATA[15:8];
    //  8'h1E : 
    //    DBG_DAT <= FRAME_CNT[7:0];
    //  8'h1F : 
      //  DBG_DAT <= FRAME_CNT[15:8];
     8'h20 : 
       DBG_DAT <= {ENABLE,CPU_ACTIVEr,DMA_ACTIVEr,P65_RDY,REFRESHED,DMA_RUN,HDMA_RUN,P65_EN};
     default : 
       DBG_DAT <= 8'h00;
     endcase
   end else begin
     i = {29'b0, DBG_REG[6:4]};
     case(DBG_REG[3:0])
     4'h0 : 
       DBG_DAT <= DMAP[i];
     4'h1 : 
       DBG_DAT <= BBAD[i];
     4'h2 : 
       DBG_DAT <= A1T[i][7:0];
     4'h3 : 
       DBG_DAT <= A1T[i][15:8];
     4'h4 : 
       DBG_DAT <= A1B[i];
     4'h5 : 
       DBG_DAT <= DAS[i][7:0];
     4'h6 : 
       DBG_DAT <= DAS[i][15:8];
     4'h7 : 
       DBG_DAT <= DASB[i];
     4'h8 : 
       DBG_DAT <= A2A[i][7:0];
     4'h9 : 
       DBG_DAT <= A2A[i][15:8];
     4'hA : 
       DBG_DAT <= NTLR[i];
     default : 
       DBG_DAT <= 8'h00;
     endcase
   end
end

// assign DBG_CPU_BRK = P65_BRK & ( ~DMA_ACTIVE) & ( ~REFRESHED);

endmodule
