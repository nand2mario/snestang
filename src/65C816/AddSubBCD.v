
module AddSubBCD(A, B, CI, ADD, BCD, w16, S, CO, VO);
   input [15:0]  A;
   input [15:0]  B;
   input         CI;
   input         ADD;
   input         BCD;
   input         w16;
   output [15:0] S;
   output        CO;
   output        VO;

   wire          VO1;
   wire          VO3;
   wire          CO0;
   wire          CO1;
   wire          CO2;
   wire          CO3;

   BCDAdder add0(.A(A[3:0]), .B(B[3:0]), .CI(CI), .S(S[3:0]), .CO(CO0), .VO(), .ADD(ADD), .BCD(BCD));
   BCDAdder add1(.A(A[7:4]), .B(B[7:4]), .CI(CO0), .S(S[7:4]), .CO(CO1), .VO(VO1), .ADD(ADD), .BCD(BCD));
   BCDAdder add2(.A(A[11:8]), .B(B[11:8]), .CI(CO1), .S(S[11:8]), .CO(CO2), .VO(), .ADD(ADD), .BCD(BCD));
   BCDAdder add3(.A(A[15:12]), .B(B[15:12]), .CI(CO2), .S(S[15:12]), .CO(CO3), .VO(VO3), .ADD(ADD), .BCD(BCD));

   assign VO = (w16 == 1'b0) ? VO1 :
               VO3;
   assign CO = (w16 == 1'b0) ? CO1 :
               CO3;

endmodule
