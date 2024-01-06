// File OBC1.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001-2023 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2023 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// no timescale needed

module OBC1(
  input CLK,
  input RST_N,
  input ENABLE,
  input [23:0] CA,
  input [7:0] DI,
  input CPURD_N,
  input CPUWR_N,
  input SYSCLKF_CE,
  input CS,
  output [12:0] SRAM_A,
  input [7:0] SRAM_DI,
  output reg [7:0] SRAM_DO
);

reg BASE;
reg [6:0] INDEX;
reg [12:0] SRAM_ADDR;

always @(posedge CLK) begin
  if(RST_N == 1'b0) begin
    INDEX <= {7{1'b0}};
    BASE <= 1'b0;
  end else begin
    if(ENABLE == 1'b1 && SYSCLKF_CE == 1'b1) begin
      if(CPUWR_N == 1'b0 && CS == 1'b1 && CA[15:4] == 12'h7FF) begin
        case(CA[3:0])
        4'h5 : begin
          BASE <= DI[0];
        end
        4'h6 : begin
          INDEX <= DI[6:0];
        end
        default : begin
        end
        endcase
      end
    end
  end
end

always @(CA, BASE, INDEX) begin
  if(CA[12:3] == 10'b1111111110) begin
    //7FF0-7FF7
    case(CA[3:0])
    4'h0,4'h1,4'h2,4'h3 : begin
      SRAM_ADDR <= {2'b11, ~BASE,1'b0,INDEX,CA[1:0]};
    end
    4'h4 : begin
      SRAM_ADDR <= {2'b11, ~BASE,1'b1,4'b0000,INDEX[6:2]};
    end
    default : begin
      SRAM_ADDR <= CA[12:0];
    end
    endcase
  end
  else begin
    SRAM_ADDR <= CA[12:0];
  end
end

assign SRAM_A = SRAM_ADDR;
always @(CA, DI, INDEX, SRAM_DI) begin
  if(CA[12:0] == 13'b1111111110100) begin
    //7FF4
    case(INDEX[1:0])
    2'b00 : begin
      SRAM_DO <= {SRAM_DI[7:2],DI[1:0]};
    end
    2'b01 : begin
      SRAM_DO <= {SRAM_DI[7:4],DI[1:0],SRAM_DI[1:0]};
    end
    2'b10 : begin
      SRAM_DO <= {SRAM_DI[7:6],DI[1:0],SRAM_DI[3:0]};
    end
    default : begin
      SRAM_DO <= {DI[1:0],SRAM_DI[5:0]};
    end
    endcase
  end
  else begin
    SRAM_DO <= DI;
  end
end

endmodule
