
// PPU SPR_BUF: 256 * 9 bits
// Port A is 18-bit accesses with separate 9-bit write enablement
// Port B is normal 9-bit accesses

module ppusprbuf (
    input clock,
    input [6:0] address_a,
    input [7:0] address_b,
    input [17:0] data_a,
    input [8:0] data_b,
    input wren_a,
    input [1:0] ds_a,           // 2'b11: write both halves, 2'b10, write higher half
    input wren_b,
    output [17:0] q_a,
    output [8:0] q_b
);

`ifndef VERILATOR

// q_b output logic
wire [8:0] dout_b0, dout_b1;
reg lsb_b_r;
always @(posedge clock) lsb_b_r <= address_b[0];
assign q_b = lsb_b_r ? dout_b1 : dout_b0;

// mem for even addresses
gowin_dpb_spr_buf mem0(
    .clka(clock), .ocea(), .cea(1'b1), .reseta(1'b0), 
    .wrea(wren_a & ds_a[0]), .ada(address_a), 
    .douta(q_a[8:0]), .dina(data_a[8:0]),
    .clkb(clock), .oceb(), .ceb(1'b1), .resetb(1'b0), 
    .wreb(wren_b & ~address_b[0]), .adb(address_b[7:1]), 
    .doutb(dout_b0), .dinb(data_b)
);

// mem for odd addresses
gowin_dpb_spr_buf mem1(
    .clka(clock), .ocea(), .cea(1'b1), .reseta(1'b0), 
    .wrea(wren_a & ds_a[1]), .ada(address_a), 
    .douta(q_a[17:9]), .dina(data_a[17:9]),
    .clkb(clock), .oceb(), .ceb(1'b1), .resetb(1'b0), 
    .wreb(wren_b & address_b[0]), .adb(address_b[7:1]), 
    .doutb(dout_b1), .dinb(data_b)
);

`else

reg [8:0] mem0 [0:127];
reg [8:0] mem1 [0:127];
reg [17:0] douta;
reg [8:0] doutb;
assign q_a = douta;
assign q_b = doutb;

// port a
always @(posedge clock) begin
    if (wren_a && ds_a[0]) 
        mem0[address_a] <= data_a[8:0];
        // $display("SPR_BUF[%x] <= %x", address_a, data_a);
    douta[8:0] <= mem0[address_a];

    if (wren_a && ds_a[1])
        mem1[address_a] <= data_a[17:9];
        // $display("SPR_BUF[%x] <= %x", address_a, data_a);
    douta[17:9] <= mem1[address_a];
end

// port b
always @(posedge clock) begin
    if (wren_b && ~address_b[0]) 
        mem0[address_b[7:1]] <= data_b;
    if (wren_b && address_b[0]) 
        mem1[address_b[7:1]] <= data_b;
    doutb <= address_b[0] ? mem1[address_b[7:1]] : mem0[address_b[7:1]];
end

`endif

endmodule
