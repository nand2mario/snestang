// File CEGen.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
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

module CEGen(
  input wire CLK,
  input wire RST_N,
  input wire [31:0] IN_CLK,
  input wire [31:0] OUT_CLK,
  output reg CE
);

  always @(posedge CLK) begin : P1
    reg [31:0] CLK_SUM;

    if(RST_N == 1'b0) begin
      CLK_SUM = 0;
      CE <= 1'b0;
    end else begin
      CE <= 1'b0;
      CLK_SUM = CLK_SUM + OUT_CLK;
      if(CLK_SUM >= IN_CLK) begin
        CLK_SUM = CLK_SUM - IN_CLK;
        CE <= 1'b1;
      end
    end
  end


endmodule
