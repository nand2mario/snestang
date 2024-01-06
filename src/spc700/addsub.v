import spc700::*;

module SPC700_AddSub(
    input wire [7:0] A,
    input wire [7:0] B,
    input wire CI,
    input wire ADD,
    output wire [7:0] S,
    output wire CO,
    output wire VO,
    output wire HO
);

wire [7:0] tempB;
reg [7:0] res;
reg C7;

assign tempB = ADD == 1'b1 ? B : B ^ 8'hFF;
always @* begin : P1
    reg [4:0] temp0, temp1;

    temp0 = ({1'b0,A[3:0]}) + ({1'b0,tempB[3:0]}) + ({4'b0000,CI});
    temp1 = ({1'b0,A[7:4]}) + ({1'b0,tempB[7:4]}) + ({4'b0000,temp0[4]});
    res = {temp1[3:0],temp0[3:0]};
    C7 = temp1[4];
end

assign S = res;
assign VO = ( ~(A[7] ^ tempB[7])) & (A[7] ^ res[7]);
assign HO = ( ~(A[3] ^ tempB[3])) & (A[3] ^ res[3]);
assign CO = C7;

endmodule
