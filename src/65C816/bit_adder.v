
module bit_adder(A, B, CI, S, CO);
   input   A;
   input   B;
   input   CI;
   output  S;
   output  CO;
   assign S = ((~A) & (~B) & CI) | ((~A) & B & (~CI)) | (A & (~B) & (~CI)) | (A & B & CI);
   assign CO = ((~A) & B & CI) | (A & (~B) & CI) | (A & B & (~CI)) | (A & B & CI);

endmodule
