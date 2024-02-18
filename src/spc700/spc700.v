
import spc700::*;

module SPC700(
    input wire CLK,
    input wire RST_N,
    input wire RDY,
    input wire IRQ_N,
    input wire [7:0] D_IN,
    output wire [7:0] D_OUT,    // this is comb logic heavy
    output reg [15:0] A_OUT  /* synthesis syn_keep=1 */,
    output reg WE_N,
    input wire [7:0] DBG_REG,
    input wire [7:0] DBG_DAT_IN,
    output reg [7:0] DBG_DAT_OUT,
    input wire DBG_DAT_WR,
    output reg BRK_OUT
);

reg [7:0] A; reg [7:0] X; reg [7:0] Y; reg [7:0] SP; reg [7:0] PSW; reg [7:0] T;
wire [15:0] PC;
reg [7:0] IR;
reg [3:0] NextState;
wire [7:0] NextIR;
reg [3:0] STATE;
wire LAST_CYCLE;
reg GotInterrupt = 1;     
reg IsResetInterrupt = 1; // nand2mario: reset on power-on
reg JumpTaken;
reg IsIRQInterrupt;
wire EN /* synthesis syn_keep=1 */;
reg STPExec;
wire IrqActive;
wire AYLoad;
wire [7:0] CToBit; wire [7:0] BitToC;
SpcMCode_r MC;
wire [7:0] SB; wire [7:0] DB;

// AddrGen
wire [15:0] AX;
wire ALCarry;

// ALU
wire [7:0] AluR;
wire [15:0] MulDivR;
wire CO, VO, SO, ZO, HO, DivZO, DivVO, DivHO, DivSO;
wire w16;
reg [7:0] BitMask;
reg [2:0] nBit;
parameter ONE = 8'h01;

//debug
wire [15:0] DBG_NEXT_PC;
reg DBG_RUN_LAST;
reg DBG_DAT_WRr;
reg [15:0] DBG_BRK_ADDR = 16'b1111_1111_1111_1111;
reg [7:0] DBG_CTRL = 8'b0;

assign EN = RDY &  ~STPExec;
assign NextIR = (STATE != 4'b0000) ? IR : GotInterrupt == 1'b1 ? 8'h0F : D_IN;
always @(posedge CLK) begin : spc_jumps
    if (~RST_N) begin
      JumpTaken <= 0;
      BitMask <= 0;
      nBit <= 0;
    end else begin
      if(EN == 1'b1) begin
        if (STATE == 4'b0000 && D_IN[3:0] == 4'h0) begin
          case(D_IN[7:4])
          4'h1 : JumpTaken <=  ~PSW[7];   // BPL
          4'h3 : JumpTaken <= PSW[7];     // BMI
          4'h5 : JumpTaken <=  ~PSW[6];   // BVC
          4'h7 : JumpTaken <= PSW[6];     // BVS
          4'h9 : JumpTaken <=  ~PSW[0];   // BCC
          4'hB : JumpTaken <= PSW[0];     // BCS
          4'hD : JumpTaken <=  ~PSW[1];   // BNE
          4'hF : JumpTaken <= PSW[1];     // BEQ
          default : ;
          endcase
        end else if (STATE == 4'b0010 && IR[3:0] == 4'h3) begin
          case(IR[7:4])
          4'h0 : JumpTaken <= D_IN[0];    // BBS0
          4'h1 : JumpTaken <=  ~D_IN[0];  // BBC0
          4'h2 : JumpTaken <= D_IN[1];    // BBS1
          4'h3 : JumpTaken <=  ~D_IN[1];  // BBC1
          4'h4 : JumpTaken <= D_IN[2];    // BBS1
          4'h5 : JumpTaken <=  ~D_IN[2];  // BBC2
          4'h6 : JumpTaken <= D_IN[3];    // BBS3
          4'h7 : JumpTaken <=  ~D_IN[3];  // BBC3
          4'h8 : JumpTaken <= D_IN[4];    // BBS4
          4'h9 : JumpTaken <=  ~D_IN[4];  // BBC4
          4'hA : JumpTaken <= D_IN[5];    // BBS5
          4'hB : JumpTaken <=  ~D_IN[5];  // BBC5
          4'hC : JumpTaken <= D_IN[6];    // BBS6
          4'hD : JumpTaken <=  ~D_IN[6];  // BBC6
          4'hE : JumpTaken <= D_IN[7];    // BBS7
          4'hF : JumpTaken <=  ~D_IN[7];  // BBC7
          default : ;
          endcase
        end
        else if(STATE == 4'b0010 && IR == 8'hFE) 
          JumpTaken <=  ~ZO;              // DBNZ
        else if(STATE == 4'b0010 && IR == 8'h6E)
          JumpTaken <=  ~ZO;
        else if(STATE == 4'b0010 && IR == 8'h2E)
          JumpTaken <=  ~ZO;              // CBNE
        else if(STATE == 4'b0011 && IR == 8'hDE)
          JumpTaken <=  ~ZO;
        else if (MC.STATE_CTRL == 2'b10)
          JumpTaken <= 0;

        if(STATE == 4'b0001 && IR[3:0] == 4'h2)
          BitMask <= ONE << (IR[7:5]);
        else if(STATE == 4'b0010 && IR[4:0] == {1'b0,4'hA}) begin
          BitMask <= ONE << D_IN[7:5];
          nBit <= D_IN[7:5];
        end
      end
    end
end

always @* begin
    case(MC.STATE_CTRL)
    2'b00 :
      NextState = STATE + 4'd1;

    2'b01 : begin
      if(ALCarry == 1'b1)
        NextState = STATE + 4'd1;
      else
        NextState = STATE + 4'd2;
    end

    2'b10 : begin
      if(JumpTaken == 1'b1)
        NextState = STATE + 4'd1;
      else
        NextState = 4'b0000;
    end

    default :
      NextState = 4'b0000;
    endcase
end

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      STATE <= {4{1'b0}};
      IR <= {8{1'b0}};
    end else begin
      if(EN == 1'b1) begin
        IR <= NextIR;
        STATE <= NextState;
      end
    end
end

assign LAST_CYCLE = NextState == 4'b0000 ? 1'b1 : 1'b0;

SPC700_MCode MCode(
    .CLK(CLK),
    .RST_N(RST_N),
    .EN(EN),
    .IR(NextIR),
    .STATE(NextState),
    .M(MC));

SPC700_AddrGen AddrGen(
    .CLK(CLK),
    .RST_N(RST_N),
    .EN(EN),
    .ADDR_CTRL(MC.ADDR_CTRL),
    .LOAD_PC(MC.LOAD_PC),
    .GotInterrupt(GotInterrupt),
    .D_IN(D_IN),
    .X(X),
    .Y(Y),
    .S(SP),
    .T(T),
    .P(PSW[5]),
    .PC(PC),
    .AX(AX),
    .ALCarry(ALCarry),
    .DBG_REG(DBG_REG),
    .DBG_DAT_IN(DBG_DAT_IN),
    .DBG_DAT_WR(DBG_DAT_WR),
    .DBG_NEXT_PC(DBG_NEXT_PC));

assign BitToC = (D_IN) >> nBit;
assign CToBit = (PSW & 8'h01) << nBit;
assign SB = MC.BUS_CTRL[4:2] == 3'b000 ? A : 
            MC.BUS_CTRL[4:2] == 3'b001 ? X : 
            MC.BUS_CTRL[4:2] == 3'b010 ? Y : 
            MC.BUS_CTRL[4:2] == 3'b011 ? T : 
            MC.BUS_CTRL[4:2] == 3'b100 ? D_IN : 
            MC.BUS_CTRL[4:2] == 3'b101 ? {7'b0000000,PSW[0]} :    // C
            MC.BUS_CTRL[4:2] == 3'b110 ? MulDivR[7:0] : 
            MC.BUS_CTRL[4:2] == 3'b111 ? SP : 
            8'h00;
assign DB = MC.BUS_CTRL[1:0] == 2'b00 && MC.BUS_CTRL[4] == 1'b0 ? D_IN : 
            MC.BUS_CTRL[1:0] == 2'b00 && MC.BUS_CTRL[4] == 1'b1 ? T : 
            MC.BUS_CTRL[1:0] == 2'b01 ? SB : 
            MC.BUS_CTRL[1:0] == 2'b10 ? BitMask : 
            MC.BUS_CTRL[1:0] == 2'b11 && MC.BUS_CTRL[4:2] != 3'b111 ? BitToC : 
            MC.BUS_CTRL[1:0] == 2'b11 && MC.BUS_CTRL[4:2] == 3'b111 ? CToBit : 
            8'h00;
assign w16 = (IR == 8'hBA && STATE == 4'b0100) || (IR == 8'h3A && STATE == 4'b0100) || (IR == 8'h1A && STATE == 4'b0100) || (IR == 8'h7A && STATE == 4'b0100) || (IR == 8'h5A && STATE == 4'b0100) || (IR == 8'hDA && STATE == 4'b0100) || (IR == 8'h9A && STATE == 4'b0100) ? 1'b1 : 1'b0;
SPC700_ALU ALU(
    .CLK(CLK), .RST_N(RST_N), .EN(EN),
    
    .L(SB), .R(DB), .CTRL(MC.ALU_CTRL), .w16(w16), 
    .CI(PSW[0]), .VI(PSW[6]),.SI(PSW[7]), .ZI(PSW[1]), 
    .HI(PSW[3]), .DivZI(DivZO), .DivVI(DivVO), .DivHI(DivHO), .DivSI(DivSO),

    .RES(AluR), .CO(CO), .VO(VO), .SO(SO), .ZO(ZO), .HO(HO));

MulDiv MulDiv(
    .CLK(CLK),
    .EN(EN),
    .RST_N(RST_N),
    .CTRL(MC.ALU_CTRL),
    .A(A),
    .X(X),
    .Y(Y),
    .RES(MulDivR),
    .ZO(DivZO),
    .VO(DivVO),
    .HO(DivHO),
    .SO(DivSO));

assign AYLoad = IR == 8'hCF || IR == 8'h9E ? 1'b1 : 1'b0;

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      A <= 8'b0;
      X <= 8'b0;
      Y <= 8'b0;
    end else begin
      if(EN == 1'b0) begin
        if(DBG_DAT_WR == 1'b1) begin
          case(DBG_REG)
          8'h00 : begin
            A <= DBG_DAT_IN;
          end
          8'h01 : begin
            X <= DBG_DAT_IN;
          end
          8'h02 : begin
            Y <= DBG_DAT_IN;
          end
          default : begin
          end
          endcase
        end
      end else begin
        if(MC.LOAD_AXY == 2'b10) begin
          X <= AluR;
        end
        if(MC.LOAD_AXY == 2'b01) begin
          if(AYLoad == 1'b0) begin
            A <= AluR;
          end
          else begin
            A <= AluR;
          end
        end
        if(MC.LOAD_AXY == 2'b11) begin
          Y <= AluR;
        end
        else if(MC.LOAD_AXY == 2'b01 && AYLoad == 1'b1) begin
          Y <= MulDivR[15:8];
        end
      end
    end
end

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      PSW <= 8'b0;
      SP <= 8'b0;
      T <= 8'b0;
    end else begin
      if (EN == 1'b0) begin
        if (DBG_DAT_WR == 1'b1) begin
          case(DBG_REG)
          8'h05 : begin
            PSW <= DBG_DAT_IN;
            $fdisplay(32'h80000002, "PSW <= %x", DBG_DAT_IN);
          end
          8'h06 : begin
            SP <= DBG_DAT_IN;
            $fdisplay(32'h80000002, "SP <= %x", DBG_DAT_IN);
          end
          default : begin
          end
          endcase
        end
      end else begin
        case(MC.LOAD_SP)
          2'b00 : ;
          2'b01 : SP <= (SP) + 1;
          2'b10 : SP <= (SP) - 1;
          2'b11 : SP <= X;
          default : ;
        endcase
        
        case(MC.LOAD_T)
          2'b01 : T <= D_IN;
          2'b10 : T <= AluR;
          default : ;
        endcase

        case(MC.LOAD_P)
          3'b000 : PSW <= PSW;          // No Op
          3'b001 : begin                // ALU
            PSW[1:0] <= {ZO,CO};
            PSW[3] <= HO;
            PSW[7:6] <= {SO,VO};    
          end
          3'b010: begin                 // BRK
            PSW[2] <= 0;
            PSW[4] <= ~IsResetInterrupt;
          end
          3'b011 : PSW <= D_IN;         // RETI/POP PSW
          3'b100 : begin
            case(IR[7:5])
              3'b001 : PSW[5] <= 1'b0;  // CLRP 20
              3'b010 : PSW[5] <= 1'b1;  // SETP 40
              3'b011 : PSW[0] <= 1'b0;  // CLRC 60
              3'b100 : PSW[0] <= 1'b1;  // SETC 80
              3'b101 : PSW[2] <= 1'b1;  // EI A0
              3'b110 : PSW[2] <= 1'b0;  // DI C0
              3'b111 : begin            // CLRV E0
                PSW[6] <= 1'b0;
                PSW[3] <= 1'b0;
              end
              default : begin end
            endcase
          end
          3'b101 : PSW[0] <= AluR[0];
          default : PSW <= PSW;
        endcase
      end
    end
end

assign D_OUT =  MC.OUT_BUS == 3'b001 ? SB : 
                MC.OUT_BUS == 3'b010 ? AluR : 
                MC.OUT_BUS == 3'b011 ? PSW : 
                MC.OUT_BUS == 3'b100 ? PC[7:0] : 
                MC.OUT_BUS == 3'b101 ? PC[15:8] : 
                8'hFF;
       
always @* begin
    WE_N = 1'b1;
    if (MC.OUT_BUS != 3'b000 && ~IsResetInterrupt/* && EN*/)
      WE_N = 1'b0;
end

always @* begin
    case(MC.ADDR_BUS)
    2'b00 : 
      A_OUT = PC;

    2'b01 : begin
      if (IR == 8'h0A || IR == 8'h2A || IR == 8'h4A || IR == 8'h6A || IR == 8'h8A || IR == 8'hAA || IR == 8'hCA || IR == 8'hEA) 
        A_OUT = AX & 16'h1FFF;
      else 
        A_OUT = AX;
    end

    2'b10 : 
      A_OUT = {8'h01,SP};

    2'b11 : begin
      if (IR[3:0] == 4'h1)
        A_OUT = {8'hFF,3'b110, ~IR[7:4],STATE[0]};        //FFC0-FFDF
      else begin
        if (GotInterrupt == 1'b1) 
          A_OUT = {8'hFF, 2'b11, ~IsIRQInterrupt, 4'b1111, STATE[0]}; //FFFE/F
        else 
          A_OUT = {8'hFF, 3'b110, ~IR[7:4], STATE[0]};
      end
    end
    default : ;
    endcase
end

assign IrqActive =  ~IRQ_N &  ~PSW[2];
always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      GotInterrupt <= 1'b1;
      IsResetInterrupt <= 1'b1;
      IsIRQInterrupt <= 1'b0;
      STPExec <= 1'b0;
    end else begin
      if(EN == 1'b0) begin
        if(DBG_DAT_WR == 1'b1 && (DBG_REG == 8'h03 || DBG_REG == 8'h04)) begin
          GotInterrupt <= 1'b0;
          //need for SPC Player
          IsResetInterrupt <= 1'b0;
        end
      end
      else begin
        if (LAST_CYCLE) begin
          GotInterrupt <= IrqActive;
          IsResetInterrupt <= 1'b0;

          if (IrqActive == 1'b1 && IsIRQInterrupt == 1'b0) 
            IsIRQInterrupt <= 1'b1;
          else 
            IsIRQInterrupt <= 1'b0;
        end

        if (STATE == 4'b0000 && ~IsResetInterrupt) begin   // nand2mario: when resetting, ignore SLEEP/STP
          if (D_IN == 8'hEF || D_IN == 8'hFF) begin
            // SLEEP, STP
            STPExec <= 1'b1;
          end
        end
      end
    end
end

//debug
always @* begin
    case(DBG_REG)
    8'h00 : begin
      DBG_DAT_OUT = A;
    end
    8'h01 : begin
      DBG_DAT_OUT = X;
    end
    8'h02 : begin
      DBG_DAT_OUT = Y;
    end
    8'h03 : begin
      DBG_DAT_OUT = PC[7:0];
    end
    8'h04 : begin
      DBG_DAT_OUT = PC[15:8];
    end
    8'h05 : begin
      DBG_DAT_OUT = PSW;
    end
    8'h06 : begin
      DBG_DAT_OUT = SP;
    end
    8'h07 : begin
      DBG_DAT_OUT = AX[7:0];
    end
    8'h08 : begin
      DBG_DAT_OUT = AX[15:8];
    end
    default : begin
      DBG_DAT_OUT = 8'h00;
    end
    endcase
end

`ifdef VERILATOR

// Trace printing for verilator
/*
reg [3:0] STATEr;
always @(posedge CLK) begin
  STATEr <= STATE;
  if (STATE == 4'd0 && STATE != STATEr) begin
    $fdisplay(32'h80000002, "PC=%x, IR=%x, A=%x, X=%x, Y=%x, SP=%x, PSW=%x", PC, IR, A, X, Y, SP, PSW);
  end
end
*/

`endif

endmodule
