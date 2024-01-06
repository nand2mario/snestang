
module BCDAdder(A, B, CI, S, CO, VO, ADD, BCD);
   input [3:0]  A;
   input [3:0]  B;
   input        CI;

   output [3:0] S;
   output       CO;
   output       VO;

   input        ADD;
   input        BCD;


   wire [3:0]   B2;
   wire [3:0]   BIN_S;
   wire         BIN_CO;
   wire [3:0]   BCD_B;
   wire         BCD_CO;

   assign B2 = B ^ {4{~ADD}};


   adder4 bin_adder(.A(A), .B(B2), .CI(CI), .S(BIN_S), .CO(BIN_CO));

   assign BCD_CO = (((BIN_S[3] & BIN_S[2]) | (BIN_S[3] & BIN_S[1])) & ADD) | ((~(BIN_CO ^ ADD)));
   assign BCD_B = {(~ADD), ((BCD_CO & BCD) ^ (~ADD)), ((BCD_CO & BCD) ^ (~ADD)), (~ADD)};

   adder4 bcd_corr_adder(.A(BIN_S), .B(BCD_B), .CI((~ADD)), .S(S), .CO());

   assign CO = (BCD == 1'b0) ? BIN_CO :
               BCD_CO ^ (~ADD);
   assign VO = ((~(A[3] ^ B2[3]))) & (A[3] ^ BIN_S[3]);

endmodule
