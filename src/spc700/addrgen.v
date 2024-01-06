// import spc700::*;

module SPC700_AddrGen(
    input wire CLK,
    input wire RST_N,
    input wire EN,
    input wire [5:0] ADDR_CTRL,
    input wire [2:0] LOAD_PC,
    input wire GotInterrupt,
    input wire [7:0] D_IN,
    input wire [7:0] X,
    input wire [7:0] Y,
    input wire [7:0] S,
    input wire [7:0] T,
    input wire P,
    output wire [15:0] PC,
    output wire [15:0] AX,
    output wire ALCarry,
    input wire [7:0] DBG_REG,
    input wire [7:0] DBG_DAT_IN,
    input wire DBG_DAT_WR,
    output wire [15:0] DBG_NEXT_PC
);

reg [7:0] AL; reg [7:0] AH;
reg SavedCarry;
reg [8:0] NewAL; wire [8:0] NewAH;
wire [7:0] NewAHWithCarry;
wire [15:0] NextAX;
reg [7:0] DR;
reg [15:0] PCr;
reg [15:0] NextPC; wire [15:0] NewPCWithOffset;
wire [1:0] ALCtrl;
wire [1:0] AHCtrl;
wire [1:0] MuxCtrl;

assign ALCtrl = ADDR_CTRL[5:4];
assign AHCtrl = ADDR_CTRL[3:2];
assign MuxCtrl = ADDR_CTRL[1:0];
assign NewPCWithOffset = PCr + {{8{DR[7]}}, DR}; 
// NewPCWithOffset <= std_logic_vector(unsigned(PCr) + unsigned((7 downto 0 => DR(7)) & DR)); 
always @* begin
    case(LOAD_PC)
    3'b000 : begin
      NextPC = PCr;
    end
    3'b001 : begin
      if(GotInterrupt == 1'b0) begin
        NextPC = (PCr) + 1;
      end
      else begin
        NextPC = PCr;
      end
    end
    3'b010 : begin
      NextPC = {D_IN,DR};
    end
    3'b011 : begin
      NextPC = NewPCWithOffset;
    end
    3'b100 : begin
      NextPC = {AH,AL};
    end
    3'b101 : begin
      NextPC = {8'hFF,AL};
    end
    default : begin
      NextPC = PCr;
    end
    endcase
end

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      PCr <= {16{1'b0}};
      DR <= {8{1'b0}};
    end else begin
      if(EN == 1'b0) begin
        if(DBG_DAT_WR == 1'b1) begin
          case(DBG_REG)
          8'h03 : begin
            PCr[7:0] <= DBG_DAT_IN;
          end
          8'h04 : begin
            PCr[15:8] <= DBG_DAT_IN;
          end
          default : begin
          end
          endcase
        end
      end else begin
        DR <= D_IN;
        PCr <= NextPC;
      end
    end
end

assign DBG_NEXT_PC = NextPC;
always @* begin
    case(MuxCtrl)
    2'b00 : begin
      NewAL = ({1'b0,AL}) + ({1'b0,X});
    end
    2'b01 : begin
      NewAL = ({1'b0,AL}) + ({1'b0,Y});
    end
    2'b10 : begin
      NewAL = {1'b0,DR};
    end
    2'b11 : begin
      NewAL = ({1'b0,DR}) + ({1'b0,Y});
    end
    default : ;
    endcase
end

assign NewAHWithCarry = (AH) + ({7'b0000000,SavedCarry});
assign NextAX = ({AH,AL}) + 1;
always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      AL <= {8{1'b0}};
      AH <= {8{1'b0}};
      SavedCarry <= 1'b0;
    end else begin
      if(EN == 1'b1) begin
        case(ALCtrl)
        2'b00 : begin
          SavedCarry <= 1'b0;
        end
        2'b01 : begin
          AL <= NewAL[7:0];
          SavedCarry <= NewAL[8];
        end
        2'b10 : begin
          case(MuxCtrl)
          2'b00 : begin
            AL <= D_IN;
          end
          2'b01 : begin
            AL <= X;
          end
          2'b10 : begin
            AL <= Y;
          end
          default : begin
          end
          endcase
          SavedCarry <= 1'b0;
        end
        2'b11 : begin
          AL <= NextAX[7:0];
          SavedCarry <= 1'b0;
        end
        default : begin
        end
        endcase
        case(AHCtrl)
        2'b00 : begin
        end
        2'b01 : begin
          AH <= {7'b0000000,P};
        end
        2'b10 : begin
          AH <= D_IN;
        end
        2'b11 : begin
          if(ALCtrl != 2'b11) begin
            AH <= NewAHWithCarry;
          end
          else begin
            AH <= NextAX[15:8];
          end
        end
        default : begin
        end
        endcase
      end
    end
end

assign ALCarry = NewAL[8];
assign AX = {AH,AL};
assign PC = PCr;

endmodule
