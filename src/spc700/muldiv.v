
import spc700::*;

module MulDiv(
    input wire CLK,
    input wire RST_N,
    input wire EN,
    input SpcALUCtrl_r CTRL,
    input wire [7:0] A,
    input wire [7:0] X,
    input wire [7:0] Y,
    output wire [15:0] RES,
    output wire ZO,
    output wire VO,
    output wire HO
);

reg [15:0] tResult;
reg tV; reg tZ;
reg [15:0] mulRes; reg [15:0] mulTemp;
reg [15:0] mulA;
reg [7:0] mulY;
reg [15:0] divt;
reg [8:0] quotient;
reg [15:0] remainder;

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      mulA <= {16{1'b0}};
      mulY <= {8{1'b0}};
      mulRes <= {16{1'b0}};
      divt <= {16{1'b0}};
      remainder <= {16{1'b0}};
      quotient <= {9{1'b0}};
    end else begin
      if(EN == 1'b1) begin
        if(CTRL.secOp == 4'b1110) begin
          mulRes <= mulTemp;
          mulA <= {mulA[14:0],1'b0};
          mulY <= {1'b0,mulY[7:1]};
        end
        else if(CTRL.secOp == 4'b1111) begin
          if(remainder >= divt) begin
            remainder <= remainder - divt;
            quotient <= {quotient[7:0],1'b1};
          end
          else begin
            quotient <= {quotient[7:0],1'b0};
          end
          divt <= {1'b0,divt[15:1]};
        end
        else begin
          mulA <= {8'b00000000,A};
          mulY <= Y;
          mulRes <= {16{1'b0}};
          divt <= {X,8'b00000000};
          remainder <= {Y,A};
          quotient <= {9{1'b0}};
        end
      end
    end
end

always @* begin
    mulTemp = {16{1'b0}};
    if(CTRL.secOp == 4'b1110) begin
      if(mulY[0] == 1'b1) begin
        mulTemp = mulRes + mulA;
      end
      else begin
        mulTemp = mulRes;
      end
      tResult = mulTemp;
      if(mulTemp[15:8] == 0) begin
        tZ = 1'b1;
      end
      else begin
        tZ = 1'b0;
      end
      tV = 1'b0;
    end
    else if(CTRL.secOp == 4'b1111) begin
      tResult = {remainder[7:0],quotient[7:0]};
      if(quotient[7:0] == 0) begin
        tZ = 1'b1;
      end
      else begin
        tZ = 1'b0;
      end
      tV = quotient[8];
    end
    else begin
      tResult = {16{1'b0}};
      tZ = 1'b0;
      tV = 1'b0;
    end
end

assign RES = tResult;
assign ZO = tZ;
assign VO = tV;
assign HO = Y[3:0] >= X[3:0] ? 1'b1 : 1'b0;

endmodule
