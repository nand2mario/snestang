
// PPU HOAM: 32 bytes dual-port

module ppuhoam (
    input clock,
    input [4:0] address_a,
    input [6:0] address_b,
    input [7:0] data_a,
    input [1:0] data_b,
    input wren_a,
    input wren_b,
    output [7:0] q_a,
    output [1:0] q_b
);

`ifndef VERILATOR

Gowin_DPB_HOAM mem(.douta(q_a), .doutb(q_b), .clka(clock), .ocea(), .cea(1'b1), .reseta(1'b0), 
            .wrea(wren_a), .clkb(clock), .oceb(), .ceb(1'b1), .resetb(1'b0), 
            .wreb(wren_b), .ada(address_a), .dina(data_a), .adb(address_b), .dinb(data_b));

/*
reg [7:0] mem [0:31];
reg [7:0] douta;
reg [7:0] doutb;
assign q_a = douta;
wire [2:0] pos_b = {address_b[1:0], 1'b1};
assign q_b = doutb[pos_b -: 2];

always @(posedge clock) begin
    douta <= mem[address_a];
    if (wren_a)
        mem[address_a] <= data_a;
end

always @(posedge clock) begin
    doutb <= mem[address_b[6:2]];
    if (wren_b)
        mem[address_b[6:2]][pos_b -: 2] <= data_b;
end
*/

`else

reg [1:0] mem [0:127];
reg [7:0] douta;
reg [1:0] doutb;
assign q_a = douta;
assign q_b = doutb; 

always @(posedge clock) begin
    douta <= {mem[{address_a, 2'd3}], mem[{address_a, 2'd2}], mem[{address_a, 2'd1}], mem[{address_a, 2'd0}]};
    doutb <= mem[address_b];
    if (wren_a) begin
        mem[{address_a, 2'd3}] <= data_a[7:6];
        mem[{address_a, 2'd2}] <= data_a[5:4];
        mem[{address_a, 2'd1}] <= data_a[3:2];
        mem[{address_a, 2'd0}] <= data_a[1:0];
        $fdisplay(32'h80000002, "HOAM[%x-%x]=%x", {address_a, 2'd0}, {address_a, 2'd3}, data_a);
    end 
    if (wren_b) begin
        mem[address_b] <= data_b;
        $fdisplay(32'h80000002, "HOAM[%x]=%x", address_b, data_b);
    end
end

`endif



endmodule
