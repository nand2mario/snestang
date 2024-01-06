
// PPU CGRAM: 256 * 15 bits

module ppucgram (
    input clock,
    input [7:0] address_a,
    input [7:0] address_b,
    input [14:0] data_a,
    input [14:0] data_b,
    input wren_a,
    input wren_b,
    output [14:0] q_a,
    output [14:0] q_b
);

`ifndef VERILATOR

gowin_dpb_cgram mem(.douta(q_a), .doutb(q_b), .clka(clock), .ocea(), .cea(1'b1), .reseta(1'b0), 
            .wrea(wren_a), .clkb(clock), .oceb(), .ceb(1'b1), .resetb(1'b0), 
            .wreb(wren_b), .ada(address_a), .dina(data_a), .adb(address_b), .dinb(data_b));

`else

reg [14:0] mem [0:255];
reg [14:0] douta;
reg [14:0] doutb;
assign q_a = douta;
assign q_b = doutb; 

always @(posedge clock) begin
    douta <= mem[address_a];
    doutb <= mem[address_b];
    if (wren_a) begin
        mem[address_a] <= data_a;
        // $display("CGRAM[%x] <= %x", address_a, data_a);
    end
    if (wren_b) begin
        mem[address_b] <= data_b;
        // $display("CGRAM[%x] <= %x", address_b, data_b);
    end
end

`endif

endmodule
