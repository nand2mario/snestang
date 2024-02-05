
import spc700::*;

module SPC700_ALU(
    input wire CLK,
    input wire RST_N,
    input wire EN,
    input SpcALUCtrl_r CTRL,
    input wire [7:0] L,
    input wire [7:0] R,
    input wire w16,
    input wire CI,
    input wire VI,
    input wire SI,
    input wire ZI,
    input wire HI,
    input wire DivZI,
    input wire DivVI,
    input wire DivHI,
    input wire DivSI,
    output wire CO,
    output reg VO,
    output reg SO,
    output wire ZO,
    output wire HO,
    output wire [7:0] RES
);


reg [7:0] tIntR;
reg CR, COut, HOut, VOut, SOut, tZ, SaveC; 
wire CIIn, ADDIn;
wire [7:0] AddR, BCDR;
wire AddCO, AddVO, AddHO, BCDCO;
reg [7:0] tResult;

always @* begin
    CR = CI;
    case(CTRL.fstOp)
    3'b000 : begin
      CR = R[7];
      tIntR = {R[6:0],1'b0};
    end
    3'b001 : begin
      CR = R[7];
      tIntR = {R[6:0],CI};
    end
    3'b010 : begin
      CR = R[0];
      tIntR = {1'b0,R[7:1]};
    end
    3'b011 : begin
      CR = R[0];
      tIntR = {CI,R[7:1]};
    end
    3'b100 : begin
      tIntR = 8'h00;
    end
    3'b101 : begin
      //INC,DEC
      tIntR = 8'h01;
    end
    3'b110 : begin
      tIntR = R;
    end
    3'b111 : begin
      tIntR =  ~R;
    end
    default : begin
    end
    endcase
  end

  always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      SaveC <= 1'b0;
    end else begin
      if(EN == 1'b1) begin
        if(CTRL.secOp[3] == 1'b1) begin
          SaveC <= AddCO;
        end
      end
    end
  end

  assign CIIn = CTRL.intC == 1'b1 ? SaveC : CTRL.secOp[0] == 1'b0 ? CI : CTRL.secOp[1];
  assign ADDIn =  ~CTRL.secOp[1];
  SPC700_AddSub AddSub(
    .A(L),
    .B(tIntR),
    .CI(CIIn),
    .ADD(ADDIn),
    .S(AddR),
    .CO(AddCO),
    .VO(AddVO),
    .HO(AddHO));

  SPC700_BCDAdj BCD(
    .A(L),
    .ADD(CTRL.secOp[0]),
    .CI(CI),
    .HI(HI),
    .R(BCDR),
    .CO(BCDCO));

  always @* begin
    HOut = 1'b0;
    COut = CR;
    case(CTRL.secOp)
    4'b0000 : begin
      tResult = L | tIntR;
    end
    4'b0001 : begin
      tResult = L & tIntR;
    end
    4'b0010 : begin
      tResult = L ^ tIntR;
    end
    4'b0011 : begin
      tResult = tIntR;
    end
    4'b0100 : begin
      //TCLR1
      tResult = tIntR & ( ~L);
    end
    4'b0101 : begin
      //TSET1
      tResult = tIntR | L;
    end
    4'b0110 : begin
      //XCN
      tResult = {tIntR[3:0],tIntR[7:4]};
    end
    4'b1000,4'b1010,4'b1001,4'b1011 : begin
      //ADC,SBC, ADD,SUB
      tResult = AddR;
      COut = AddCO;
      HOut = AddHO;
    end
    4'b1100,4'b1101 : begin
      //DAA,DAS
      tResult = BCDR;
      COut = BCDCO;
    end
    4'b1110 : begin
      //MUL
      tResult = tIntR;
    end
    4'b1111 : begin
      //DIV
      tResult = tIntR;
      HOut = DivHI;
    end
    default : begin
      tResult = 8'h00;
    end
    endcase
  end

  always @* begin
    VOut = VI;
    case(CTRL.secOp)
      4'b1000, 4'b1001: VOut = AddVO;   //ADC,ADD
      4'b1010, 4'b1011: VOut = AddVO;   //SBC,SUB
      4'b1111:          VOut = DivVI;   //DIV
      default : ;
    endcase
  end

  always @* begin
    SOut = SI;
    case (CTRL.secOp)
    4'b1110: SOut = DivSI;          // MUL
    4'b1111: SOut = DivSI;          // DIV
    default: SOut = tResult[7];
    endcase

  end

  assign tZ = CTRL.secOp[3:1] == 3'b111 ? DivZI : tResult == 8'h00 ? 1'b1 : 1'b0;
  assign ZO = w16 ? ZI & tZ : tZ;
  assign CO = CTRL.chgCO ? COut : CI;
  assign VO = CTRL.chgVO ? VOut : VI;
  assign HO = CTRL.chgHO ? HOut : HI;
  assign SO = SOut;
  assign RES = tResult;

endmodule
