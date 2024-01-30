
import P65816::*;

// See: 
// - https://wiki.superfamicom.org/65816-reference
// - 65C816 dataseet

module P65C816(CLK, RST_N, CE, RDY_IN, NMI_N, IRQ_N, ABORT_N, D_IN, 
               D_OUT, A_OUT, WE_N, RDY_OUT, VPA, VDA, MLB, VPB, 
               BRK_OUT, DBG_REG, DBG_DAT_IN, DBG_DAT_OUT, DBG_DAT_WR, LAST_CYCLE);
   input         CLK;
   input         RST_N;
   input         CE;       // chip enable

   input         RDY_IN;   // ready in
   input         NMI_N;    // non-maskable interrupt
   input         IRQ_N;    // interrupt
   input         ABORT_N;  // abort input
   input [7:0]   D_IN;
   output [7:0]  D_OUT;
   output [23:0] A_OUT;
   output        WE_N;     // 0: write ENABLE 
   reg           WE_N;
   output        RDY_OUT;  // ready out
   output        VPA;      // valid program address
   reg           VPA;
   output        VDA;      // valid data address
   reg           VDA;
   output        MLB;      // memory lock
   reg           MLB;
   output        VPB;      // vector pull
   reg           VPB;
   output        LAST_CYCLE;  // For single step 

	output reg    BRK_OUT;
	input [7:0]   DBG_REG;
   input [7:0]   DBG_DAT_IN;
   output reg [7:0] DBG_DAT_OUT;
	input         DBG_DAT_WR;

   // pins not present: E, MX, PHI2, RWB

   reg [15:0]    A;
   reg [15:0]    X;
   reg [15:0]    Y;
   reg [15:0]    D;     // direct page
   reg [15:0]    SP;    // stack pointer
   reg [15:0]    T;
   reg [7:0]     PBR;   // program bank
   reg [7:0]     DBR;   // data bank
   reg [8:0]     P;     // processor status: NVMXDIZC  (and E, B)
   wire [15:0]   PC;

   reg [7:0]     DR;    
   wire          EF;    // 0: native mode
   wire          XF;
   wire          MF;    // 0: 16-bit accumulator, 1: 8-bit accumulator
   reg           oldXF;
   wire [15:0]   SB;
   wire [15:0]   DB;
   wire          EN;    // enable
   MCode_r       MC;    // micro code
   reg [7:0]     IR;    // instruction
   wire [7:0]    NextIR;
   reg [3:0]     STATE;
   reg [3:0]     NextState;
   reg           GotInterrupt;
   reg           IsResetInterrupt;
   reg           IsNMIInterrupt;
   reg           IsIRQInterrupt;
   wire          IsABORTInterrupt;
   wire          IsBRKInterrupt;
   wire          IsCOPInterrupt;
   reg           JumpTaken;
   wire          JumpNoOverflow;
   wire          IsBranchCycle1;
   wire          w16;
   wire          DLNoZero;
   reg           WAIExec;
   reg           STPExec;
   reg           NMI_SYNC;
   reg           IRQ_SYNC;
   reg           NMI_ACTIVE;
   reg           IRQ_ACTIVE;
   reg           OLD_NMI_N;
   wire          OLD_NMI2_N;
   reg [23:0]    ADDR_BUS;

   wire [15:0]   AluR;
   wire [15:0]   AluIntR;
   wire          CO;
   wire          VO;
   wire          SO;
   wire          ZO;

   wire [16:0]   AA;
   wire [7:0]    AB;
   wire          AALCarry;
   wire [15:0]   DX;

   reg           DBG_DAT_WRr;
   reg  [23:0]   DBG_BRK_ADDR;
   reg  [7:0]    DBG_CTRL;
   reg           DBG_RUN_LAST;
   wire [15:0]   DBG_NEXT_PC;
   reg  [23:0]   JSR_RET_ADDR;
   reg           JSR_FOUND;

   assign EN = RDY_IN & CE & (~WAIExec) & (~STPExec);

   assign IsBranchCycle1 = (IR[4:0] == 5'b10000 & STATE == 4'b0001) ? 1'b1 :
                           1'b0;

   always @*
      case (IR[7:5])
         3'b000 :
            JumpTaken = (~P[7]);
         3'b001 :
            JumpTaken = P[7];
         3'b010 :
            JumpTaken = (~P[6]);
         3'b011 :
            JumpTaken = P[6];
         3'b100 :
            JumpTaken = (~P[0]);
         3'b101 :
            JumpTaken = P[0];
         3'b110 :
            JumpTaken = (~P[1]);
         3'b111 :
            JumpTaken = P[1];
         default :
            JumpTaken = 1'b0;
      endcase

   assign DLNoZero = (D[7:0] == 8'h00) ? 1'b0 :
                     1'b1;

   assign NextIR = ((STATE != 4'b0000)) ? IR :
                   (GotInterrupt == 1'b1) ? 8'h00 :
                   D_IN;

   always @*
      case (MC.STATE_CTRL)
         3'b000 :
            NextState = STATE + 4'd1;
         3'b001 :
            if (AALCarry == 1'b0 & (XF == 1'b1 | EF == 1'b1))
               NextState = STATE + 4'd2;
            else
               NextState = STATE + 4'd1;
         3'b010 :
            if (IsBranchCycle1 == 1'b1 & JumpTaken == 1'b1)
               NextState = 4'b0010;
            else
               NextState = 4'b0000;
         3'b011 :
            if (JumpNoOverflow == 1'b1 | EF == 1'b0)
               NextState = 4'b0000;
            else
               NextState = STATE + 4'd1;
         3'b100 :
            if ((MC.LOAD_AXY[1] == 1'b0 & MF == 1'b0 & EF == 1'b0) 
               | (MC.LOAD_AXY[1] == 1'b1 & XF == 1'b0 & EF == 1'b0))
               NextState = STATE + 4'd1;
            else
               NextState = 4'b0000;
         3'b101 :
            if (DLNoZero == 1'b1 & EF == 1'b0)
               NextState = STATE + 4'd1;
            else
               NextState = STATE + 4'd2;
         3'b110 :
            if ((MC.LOAD_AXY[1] == 1'b0 & MF == 1'b0 & EF == 1'b0) 
               | (MC.LOAD_AXY[1] == 1'b1 & XF == 1'b0 & EF == 1'b0))
               NextState = STATE + 4'd1;
            else
               NextState = STATE + 4'd2;
         3'b111 :
            if (EF == 1'b0)
               NextState = STATE + 4'd1;
            else if (EF == 1'b1 & IR == 8'h40)
               NextState = 4'b0000;
            else
               NextState = STATE + 4'd2;
         default :
            ;
      endcase

   assign LAST_CYCLE = (NextState == 4'b0000) ? 1'b1 :
                       1'b0;

   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         STATE <= {4{1'b0}};
         IR <= {8{1'b0}};
      end
      else
      begin
         if (EN == 1'b1)
         begin
            IR <= NextIR;
            STATE <= NextState;
         end
      end


   mcode MCode(.CLK(CLK), .RST_N(RST_N), .EN(EN), .IR(NextIR), .STATE(NextState), 
         .M(MC));

   AddrGen AddrGen(.CLK(CLK), .RST_N(RST_N), .EN(EN), .LOAD_PC(MC.LOAD_PC), 
         .PCDec(CO), .GotInterrupt(GotInterrupt), .ADDR_CTRL(MC.ADDR_CTRL), 
         .IND_CTRL(MC.IND_CTRL), .D_IN(D_IN), .X(X), .Y(Y), .D(D), .S(SP), 
         .T(T), .DR(DR), .DBR(DBR), .e6502(EF), .PC(PC), .AA(AA), .AB(AB), 
         .DX(DX), .AALCarry(AALCarry), .JumpNoOfl(JumpNoOverflow));

   assign w16 = (MC.ALU_CTRL.w16 == 1'b1) ? 1'b1 :
                (IR == 8'hEB | IR == 8'hAB) ? 1'b0 :
                ((IR == 8'h44 | IR == 8'h54) & STATE == 4'b0101) ? 1'b1 :     // for MVN/MVP DEC A
                ((MC.LOAD_AXY[1] == 1'b0) & MF == 1'b0 & EF == 1'b0) ? 1'b1 :
                ((MC.LOAD_AXY[1] == 1'b1) & XF == 1'b0 & EF == 1'b0) ? 1'b1 :
                1'b0;

   assign SB = (MC.BUS_CTRL[5:3] == 3'b000) ? A :
               (MC.BUS_CTRL[5:3] == 3'b001) ? X :
               (MC.BUS_CTRL[5:3] == 3'b010) ? Y :
               (MC.BUS_CTRL[5:3] == 3'b011) ? D :
               (MC.BUS_CTRL[5:3] == 3'b100) ? T :
               (MC.BUS_CTRL[5:3] == 3'b101) ? SP :
               (MC.BUS_CTRL[5:3] == 3'b110) ? {8'h00, PBR} :
               (MC.BUS_CTRL[5:3] == 3'b111) ? {8'h00, DBR} :
               16'h0000;

   assign DB = (MC.BUS_CTRL[2:0] == 3'b000) ? {8'h00, D_IN} :
               (MC.BUS_CTRL[2:0] == 3'b001) ? {D_IN, DR} :
               (MC.BUS_CTRL[2:0] == 3'b010) ? SB :
               (MC.BUS_CTRL[2:0] == 3'b011) ? D :
               (MC.BUS_CTRL[2:0] == 3'b100) ? T :
               (MC.BUS_CTRL[2:0] == 3'b101) ? 16'h0001 :
               16'h0000;


   ALU ALU(.CTRL(MC.ALU_CTRL), .L(SB), .R(DB), .w16(w16), .BCD(P[3]), .CI(P[0]), 
         .VI(P[6]), .SI(P[7]), .CO(CO), .VO(VO), .SO(SO), .ZO(ZO), .RES(AluR), 
         .IntR(AluIntR));

   assign MF = P[5];
   assign XF = P[4];
   assign EF = P[8];


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         A <= {16{1'b0}};
         X <= {16{1'b0}};
         Y <= {16{1'b0}};
         SP <= 16'h0100;
         oldXF <= 1'b1;
      end
      else
      begin
         if (IR == 8'hFB & P[0] == 1'b1 & MC.LOAD_P == 3'b101)
         begin
            X[15:8] <= 8'h00;
            Y[15:8] <= 8'h00;
            SP[15:8] <= 8'h01;
            oldXF <= 1'b1;
         end
         else if (EN == 1'b1)
         begin
            if (MC.LOAD_AXY == 3'b110)
            begin
               if (MC.BYTE_SEL[1] == 1'b1 & XF == 1'b0 & EF == 1'b0)
               begin
                  X[15:8] <= AluR[15:8];
                  X[7:0] <= AluR[7:0];
               end
               else if (MC.BYTE_SEL[0] == 1'b1 & (XF == 1'b1 | EF == 1'b1))
               begin
                  X[7:0] <= AluR[7:0];
                  X[15:8] <= 8'h00;
               end
            end
            if (MC.LOAD_AXY == 3'b101)
            begin
               if (IR == 8'hEB)
               begin
                  A[15:8] <= A[7:0];
                  A[7:0] <= A[15:8];
               end
               else if ((MC.BYTE_SEL[1] == 1'b1 & MF == 1'b0 & EF == 1'b0) 
                  | (MC.BYTE_SEL[1] == 1'b1 & w16 == 1'b1))
               begin
                  A[15:8] <= AluR[15:8];
                  A[7:0] <= AluR[7:0];
               end
               else if (MC.BYTE_SEL[0] == 1'b1 & (MF == 1'b1 | EF == 1'b1))
                  A[7:0] <= AluR[7:0];
            end
            if (MC.LOAD_AXY == 3'b111)
            begin
               if (MC.BYTE_SEL[1] == 1'b1 & XF == 1'b0 & EF == 1'b0)
               begin
                  Y[15:8] <= AluR[15:8];
                  Y[7:0] <= AluR[7:0];
               end
               else if (MC.BYTE_SEL[0] == 1'b1 & (XF == 1'b1 | EF == 1'b1))
               begin
                  Y[7:0] <= AluR[7:0];
                  Y[15:8] <= 8'h00;
               end
            end

            oldXF <= XF;
            if (XF == 1'b1 & oldXF == 1'b0 & EF == 1'b0)
            begin
               X[15:8] <= 8'h00;
               Y[15:8] <= 8'h00;
            end

            case (MC.LOAD_SP)
               3'b000 :
                  ;
               3'b001 :
                  if (EF == 1'b0)
                     SP <= (SP + 16'd1);
                  else
                     SP[7:0] <= ((SP[7:0]) + 8'd1);
               3'b010 :
                  if (MC.BYTE_SEL[1] == 1'b0 & w16 == 1'b1)
                  begin
                     if (EF == 1'b0)
                        SP <= SP + 16'd1;
                     else
                        SP[7:0] <= SP[7:0] + 8'd1;
                  end
               3'b011 :
                  if (EF == 1'b0)
                     SP <= SP - 16'd1;
                  else
                     SP[7:0] <= SP[7:0] - 8'd1;
               3'b100 :
                  if (EF == 1'b0)
                     SP <= A;
                  else
                     SP <= {8'h01, A[7:0]};
               3'b101 :
                  if (EF == 1'b0)
                     SP <= X;
                  else
                     SP <= {8'h01, X[7:0]};
               default :
                  ;
            endcase
         end
      end


   always @(posedge CLK)
      if (RST_N == 1'b0)
         P <= 9'b100110100;
      else
      begin
         if (EN == 1'b1)
            case (MC.LOAD_P)
               3'b000 :
                  P <= P;
               3'b001 :
                  if ((MC.LOAD_AXY[1] == 1'b0 & MC.BYTE_SEL[0] == 1'b1 
                     & (MF == 1'b1 | EF == 1'b1)) 
                     | (MC.LOAD_AXY[1] == 1'b1 & MC.BYTE_SEL[0] == 1'b1 
                     & (XF == 1'b1 | EF == 1'b1)) 
                     | (MC.LOAD_AXY[1] == 1'b0 & MC.BYTE_SEL[1] == 1'b1 
                     & (MF == 1'b0 & EF == 1'b0)) 
                     | (MC.LOAD_AXY[1] == 1'b1 & MC.BYTE_SEL[1] == 1'b1 
                     & (XF == 1'b0 & EF == 1'b0)) 
                     | (MC.LOAD_AXY[1] == 1'b0 & MC.BYTE_SEL[1] == 1'b1 
                     & w16 == 1'b1) | IR == 8'hEB | IR == 8'hAB)
                  begin
                     P[1:0] <= {ZO, CO};
                     P[7:6] <= {SO, VO};
                  end
               3'b010 :
                  begin
                     P[2] <= 1'b1;
                     P[3] <= 1'b0;
                  end
               3'b011 :
                  begin
                     P[7:6] <= D_IN[7:6];
                     P[5] <= D_IN[5] | EF;
                     P[4] <= D_IN[4] | EF;
                     P[3:0] <= D_IN[3:0];
                  end
               3'b100 :
                  case (IR[7:6])
                     2'b00 :
                        P[0] <= IR[5];
                     2'b01 :
                        P[2] <= IR[5];
                     2'b10 :
                        P[6] <= 1'b0;
                     2'b11 :
                        P[3] <= IR[5];
                     default :
                        ;
                  endcase
               3'b101 :
                  begin
                     P[8] <= P[0];
                     P[0] <= P[8];
                     if (P[0] == 1'b1)
                     begin
                        P[4] <= 1'b1;
                        P[5] <= 1'b1;
                     end
                  end
               3'b110 :
                  case (IR[5])
                     1'b1 :
                        P[7:0] <= P[7:0] | ({DR[7:6], (DR[5] & (~EF)), 
                                  (DR[4] & (~EF)), DR[3:0]});
                     1'b0 :
                        P[7:0] <= P[7:0] & ((~({DR[7:6], (DR[5] & (~EF)), 
                                  (DR[4] & (~EF)), DR[3:0]})));
                     default :
                        ;
                  endcase
               3'b111 :
                  P[1] <= ZO;
               default :
                  ;
            endcase
      end


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         T <= {16{1'b0}};
         DR <= {8{1'b0}};
         D <= {16{1'b0}};
         PBR <= {8{1'b0}};
         DBR <= {8{1'b0}};
      end
      else
      begin
         if (EN == 1'b1)
         begin
            DR <= D_IN;

            case (MC.LOAD_T)
               2'b01 :
                  if (MC.BYTE_SEL[1] == 1'b1)
                     T[15:8] <= D_IN;
                  else
                     T[7:0] <= D_IN;
               2'b10 :
                  T <= AluR;
               default :
                  ;
            endcase

            case (MC.LOAD_DKB)
               2'b01 :
                  D <= AluIntR;
               2'b10 :
                  if (IR == 8'h00 | IR == 8'h02)      // BRK/COP reset PBR
                     PBR <= {8{1'b0}};
                  else
                     PBR <= D_IN;
               2'b11 :
                  if (IR == 8'h44 | IR == 8'h54)      // MVN/MVP
                     DBR <= D_IN;
                  else
                     DBR <= AluIntR[7:0];
               default :
                  ;
            endcase
         end
      end

   // nand2mario: PHP fix from FpgaSnes
   assign D_OUT = // (MC.OUT_BUS == 3'b001 & MC.BYTE_SEL[1] == 1'b1) ? AluR[15:8] :
                  // (MC.OUT_BUS == 3'b001 & MC.BYTE_SEL[1] == 1'b0) ? AluR[7:0] :
                  (MC.OUT_BUS == 3'b010 & MC.BYTE_SEL[1] == 1'b1) ? PC[15:8] :
                  (MC.OUT_BUS == 3'b010 & MC.BYTE_SEL[1] == 1'b0) ? PC[7:0] :
                  (MC.OUT_BUS == 3'b011 & MC.BYTE_SEL[1] == 1'b1) ? AA[15:8] :
                  (MC.OUT_BUS == 3'b011 & MC.BYTE_SEL[1] == 1'b0) ? AA[7:0] :
                  (MC.OUT_BUS == 3'b100) ? {P[7], P[6], (P[5] | EF), 
                                 (P[4] | ((~(GotInterrupt)) & EF)), P[3:0]} :
                  (MC.OUT_BUS == 3'b101 & MC.BYTE_SEL[1] == 1'b1) ? SB[15:8] :
                  (MC.OUT_BUS == 3'b101 & MC.BYTE_SEL[1] == 1'b0) ? SB[7:0] :
                  (MC.OUT_BUS == 3'b110 & MC.BYTE_SEL[1] == 1'b1) ? DR :
                  (MC.OUT_BUS == 3'b110 & MC.BYTE_SEL[1] == 1'b0) ? PBR :
                  8'h00;
   // wire [2:0] out_bus = MC.OUT_BUS;
   // wire [1:0] byte_sel = MC.BYTE_SEL;
   // wire [7:0] pcl = PC[7:0];
   // assign D_OUT = (out_bus == 3'b001) ? {P[7], P[6], (P[5] | EF), (P[4] | ((~(GotInterrupt)) & EF)), P[3:0]} :
   //                (out_bus == 3'b010) && (byte_sel[1] == 1'b1) ? PC[15:8] :
   //                (out_bus == 3'b010) && (byte_sel[1] == 1'b0) ? PC[7:0] :
   //                (out_bus == 3'b011) && (byte_sel[1] == 1'b1) ? AA[15:8] :
   //                (out_bus == 3'b011) && (byte_sel[1] == 1'b0) ? AA[7:0] :
   //                (out_bus == 3'b100) ? PBR :
   //                (out_bus == 3'b101) && (byte_sel[1] == 1'b1) ? SB[15:8] :
   //                (out_bus == 3'b101) && (byte_sel[1] == 1'b0) ? SB[7:0] :
   //                (out_bus == 3'b110) ? DR :
   //                8'h00;

   always @*
   begin
      WE_N = 1'b1;
      if (MC.OUT_BUS != 3'b000 & IsResetInterrupt == 1'b0)
         WE_N = 1'b0;
   end


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         OLD_NMI_N <= 1'b1;
         NMI_SYNC <= 1'b0;
         IRQ_SYNC <= 1'b0;
      end
      else
      begin
         if (CE == 1'b1 & IsResetInterrupt == 1'b0)
         begin
            OLD_NMI_N <= NMI_N;
            if (NMI_N == 1'b0 & OLD_NMI_N == 1'b1 & NMI_SYNC == 1'b0)
               NMI_SYNC <= 1'b1;
            else if (NMI_ACTIVE == 1'b1 & LAST_CYCLE == 1'b1 & EN == 1'b1)
               NMI_SYNC <= 1'b0;
            IRQ_SYNC <= (~IRQ_N);
         end
      end


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         IsResetInterrupt <= 1'b1;
         IsNMIInterrupt <= 1'b0;
         IsIRQInterrupt <= 1'b0;
         GotInterrupt <= 1'b1;
         NMI_ACTIVE <= 1'b0;
         IRQ_ACTIVE <= 1'b0;
      end
      else
      begin
         if (RDY_IN == 1'b1 & CE == 1'b1)
         begin
            NMI_ACTIVE <= NMI_SYNC;
            IRQ_ACTIVE <= (~IRQ_N);

            if (LAST_CYCLE == 1'b1 & EN == 1'b1)
            begin
               if (GotInterrupt == 1'b0)
               begin
                  GotInterrupt <= (IRQ_ACTIVE & (~P[2])) | NMI_ACTIVE;
                  if (NMI_ACTIVE == 1'b1)
                     NMI_ACTIVE <= 1'b0;
               end
               else
                  GotInterrupt <= 1'b0;

               IsResetInterrupt <= 1'b0;
               IsNMIInterrupt <= NMI_ACTIVE;
               IsIRQInterrupt <= IRQ_ACTIVE & (~P[2]);
            end
         end
      end

   assign IsBRKInterrupt = (IR == 8'h00) ? 1'b1 :
                           1'b0;
   assign IsCOPInterrupt = (IR == 8'h02) ? 1'b1 :
                           1'b0;
   assign IsABORTInterrupt = 1'b0;


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         WAIExec <= 1'b0;
         STPExec <= 1'b0;
      end
      else
      begin
         if (EN == 1'b1 & GotInterrupt == 1'b0)
         begin
            if (STATE == 4'b0000)
            begin
               if (D_IN == 8'hCB)
                  WAIExec <= 1'b1;
               else if (D_IN == 8'hDB)
                  STPExec <= 1'b1;
            end
         end

         if (RDY_IN == 1'b1 & CE == 1'b1)
         begin
            if ((NMI_SYNC == 1'b1 | IRQ_SYNC == 1'b1 | ABORT_N == 1'b0) 
                  & WAIExec == 1'b1)
               WAIExec <= 1'b0;
         end
      end


   always @*
   begin: xhdl0
      reg [15:0]     ADDR_INC;
      ADDR_INC = { 14'b0, MC.ADDR_INC[1:0] };
      case (MC.ADDR_BUS)
         3'b000 :
            ADDR_BUS[23:0] = {PBR, PC};
         3'b001 :
            ADDR_BUS[23:0] = (({DBR, 16'h0000}) + ({8'h00, (AA[15:0])}) + 
                              ({8'h00, ADDR_INC}));
         3'b010 :
            if (EF == 1'b0)
               ADDR_BUS[23:0] = {8'h00, SP};
            else
               ADDR_BUS[23:0] = {8'h00, 8'h01, SP[7:0]};
         3'b011 :
            ADDR_BUS[23:0] = {8'h00, (DX + ADDR_INC)};
         3'b100 :
            begin
               ADDR_BUS[23:4] = {8'h00, 11'b11111111111, EF};
               if (IsResetInterrupt == 1'b1)
                  ADDR_BUS[3:0] = {3'b110, MC.ADDR_INC[0]};
               else if (IsABORTInterrupt == 1'b1)
                  ADDR_BUS[3:0] = {3'b100, MC.ADDR_INC[0]};
               else if (IsNMIInterrupt == 1'b1)
                  ADDR_BUS[3:0] = {3'b101, MC.ADDR_INC[0]};
               else if (IsIRQInterrupt == 1'b1)
                  ADDR_BUS[3:0] = {3'b111, MC.ADDR_INC[0]};
               else if (IsCOPInterrupt == 1'b1)
                  ADDR_BUS[3:0] = {3'b010, MC.ADDR_INC[0]};
               else
                  ADDR_BUS[3:0] = {EF, 2'b11, MC.ADDR_INC[0]};
            end
         3'b101 :
            ADDR_BUS[23:0] = (({AB, 16'h0000}) + ({7'b0000000, AA}) + 
                              ({8'h00, ADDR_INC}));
         3'b110 :
            ADDR_BUS[23:0] = {8'h00, ((AA[15:0]) + ADDR_INC)};
         3'b111 :
            ADDR_BUS[23:0] = {PBR, ((AA[15:0]) + ADDR_INC)};
         default :
            ;
      endcase
   end

   assign A_OUT = ADDR_BUS;


   always @*
   begin: xhdl1
      reg           rmw;
      reg           twoCls;
      reg           softInt;
      if (IR == 8'h06 | IR == 8'h0E | IR == 8'h16 | IR == 8'h1E | IR == 8'hC6 
         | IR == 8'hCE | IR == 8'hD6 | IR == 8'hDE | IR == 8'hE6 | IR == 8'hEE 
         | IR == 8'hF6 | IR == 8'hFE | IR == 8'h46 | IR == 8'h4E | IR == 8'h56 
         | IR == 8'h5E | IR == 8'h26 | IR == 8'h2E | IR == 8'h36 | IR == 8'h3E 
         | IR == 8'h66 | IR == 8'h6E | IR == 8'h76 | IR == 8'h7E | IR == 8'h14 
         | IR == 8'h1C | IR == 8'h04 | IR == 8'h0C)
         rmw = 1'b1;
      else
         rmw = 1'b0;

      if (MC.ADDR_BUS == 3'b100)
         VPB = 1'b0;
      else
         VPB = 1'b1;

      if ((MC.ADDR_BUS == 3'b001 | MC.ADDR_BUS == 3'b011) & rmw == 1'b1)
         MLB = 1'b0;
      else
         MLB = 1'b1;

      if (LAST_CYCLE == 1'b1 & STATE == 1 & MC.VA == 2'b00)
         twoCls = 1'b1;
      else
         twoCls = 1'b0;

      if ((IsBRKInterrupt == 1'b1 | IsCOPInterrupt == 1'b1) & STATE == 1 
            & GotInterrupt == 1'b0)
         softInt = 1'b1;
      else
         softInt = 1'b0;

      VDA = MC.VA[1];
      VPA = MC.VA[0] | (twoCls & ((IRQ_ACTIVE & (~P[2])) | NMI_ACTIVE)) | softInt;
   end

   assign RDY_OUT = EN;

   // debug
   always @* begin
      case (DBG_REG)
      8'h00: DBG_DAT_OUT = A[7:0];
      8'h01: DBG_DAT_OUT = A[15:8];
      8'h02: DBG_DAT_OUT = X[7:0];
      8'h03: DBG_DAT_OUT = X[15:8];
      8'h04: DBG_DAT_OUT = Y[7:0];
      8'h05: DBG_DAT_OUT = Y[15:8];
      8'h06: DBG_DAT_OUT = PC[7:0];
      8'h07: DBG_DAT_OUT = PC[15:8];
      8'h08: DBG_DAT_OUT = P[7:0];
      8'h09: DBG_DAT_OUT = SP[7:0];
      8'h0A: DBG_DAT_OUT = SP[15:8];
      8'h0B: DBG_DAT_OUT = D[7:0];
      8'h0C: DBG_DAT_OUT = D[15:8];
      8'h0D: DBG_DAT_OUT = PBR;
      8'h0E: DBG_DAT_OUT = DBR;
      8'h0F: DBG_DAT_OUT = {6'b00_0000, MC.ADDR_INC};
      8'h10: DBG_DAT_OUT = AA[7:0];
      8'h11: DBG_DAT_OUT = AA[15:8];
      8'h12: DBG_DAT_OUT = AB;
      8'h13: DBG_DAT_OUT = DX[7:0];
      8'h14: DBG_DAT_OUT = DX[15:8];
      8'h15: DBG_DAT_OUT = {GotInterrupt, IsResetInterrupt, IsNMIInterrupt, IsIRQInterrupt, RDY_IN, EN, WAIExec, STPExec};
      default: DBG_DAT_OUT = 8'h0;      
      endcase
   end
/*
   always @(posedge CLK) begin
      reg [15:0] AFTER_JSR_PC;
      reg JSRS;

      if (~RST_N) begin
         BRK_OUT <= 1'b0;
         DBG_RUN_LAST <= 1'b0;
         JSR_RET_ADDR <= 24'b0;
         JSR_FOUND <= 1'b0;
      end else begin
         if (RDY_IN == 1'b1) begin
            if (NextIR == 8'h20 || NextIR == 8'h22 || NextIR == 8'hfc) 
               JSRS = 1'b1;
            else
               JSRS = 1'b0;
            if (NextIR == 8'h20 || NextIR == 8'hfc)
               AFTER_JSR_PC = PC + 16'd3;
            else
               AFTER_JSR_PC = PC + 16'd4;
            
            BRK_OUT <= 1'b0;
            if (DBG_CTRL[0]) begin           // step
               if (LAST_CYCLE == 1'b1) begin
                  if (DBG_CTRL[1]) begin     // trace
                     BRK_OUT <= 1'b1;
                     JSR_FOUND <= 1'b0;
                  end else if (JSR_FOUND == 1'b0) begin
                     BRK_OUT <= 1'b1;
                     if (JSRS) begin
                        JSR_RET_ADDR <= {PBR, AFTER_JSR_PC};
                        JSR_FOUND <= 1'b1; 
                     end
                  end else if (JSR_RET_ADDR[15:0] == DBG_NEXT_PC && JSR_RET_ADDR[23:16] == PBR && JSR_FOUND) begin
                     BRK_OUT <= 1'b1;
                     if (JSRS) begin
                        JSR_RET_ADDR <= {PBR, AFTER_JSR_PC};
                        JSR_FOUND <= 1'b1;
                     end else
                        JSR_FOUND <= 1'b0;
                  end
               end
            end else if (DBG_CTRL[2]) begin  // opcode address break
               if (LAST_CYCLE && DBG_BRK_ADDR[15:0] == DBG_NEXT_PC
                  && DBG_BRK_ADDR[23:16] == PBR)
                  BRK_OUT <= 1'b1;
            end else if (DBG_CTRL[3]) begin  // read/write address break
               if (DBG_BRK_ADDR == ADDR_BUS && MC.VA == 2'b10)
                  BRK_OUT <= 1'b1;
            end
         end

         DBG_RUN_LAST <= DBG_CTRL[7];        // run
         if (DBG_CTRL[7] && ~DBG_RUN_LAST)
            BRK_OUT <= 1'b0;
      end
   end


   always @(posedge CLK) begin
      if (~RST_N) begin
         DBG_DAT_WRr <= 1'b0;
      end else begin
			DBG_DAT_WRr <= DBG_DAT_WR;
			if (DBG_DAT_WR && ~DBG_DAT_WRr) begin
				case (DBG_REG)
					8'h80: DBG_BRK_ADDR[7:0] <= DBG_DAT_IN;
					8'h81: DBG_BRK_ADDR[15:8] <= DBG_DAT_IN;
					8'h82: DBG_BRK_ADDR[23:16] <= DBG_DAT_IN;
					8'h83: DBG_CTRL <= DBG_DAT_IN;
					default: ;
				endcase;
			end      
      end
   end
*/

endmodule
