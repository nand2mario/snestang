
// PPU OAM: 512 bytes dual port

module ppuoam (
    input clock,
    input [7:0] address_a,
    input [6:0] address_b,
    input [15:0] data_a,
    input [31:0] data_b,
    input wren_a,
    input wren_b,
    output [15:0] q_a,
    output [31:0] q_b
);

`ifndef VERILATOR

Gowin_DPB_OAM mem(.douta(q_a), .doutb(q_b), .clka(clock), .ocea(), .cea(1'b1), .reseta(1'b0), 
            .wrea(wren_a), .clkb(clock), .oceb(), .ceb(1'b1), .resetb(1'b0), 
            .wreb(wren_b), .ada(address_a), .dina(data_a), .adb(address_b), .dinb(data_b));

/*
reg [31:0] mem [0:127];
reg [31:0] douta;
reg [31:0] doutb;
wire [4:0] pos_a = {address_a[0], 4'b1111};
assign q_a = douta[pos_a -: 16];
assign q_b = doutb;

always @(posedge clock) begin
    douta <= mem[address_a[7:1]];
    if (wren_a)
        mem[address_a[7:0]][pos_a -: 16] <= data_a;
end

always @(posedge clock) begin
    doutb <= mem[address_b];
    if (wren_b)
        mem[address_b] <= data_b;
end
*/

`else

reg [15:0] mem [0:255];
reg [15:0] douta;
reg [31:0] doutb;
assign q_a = douta;
assign q_b = doutb; 

always @(posedge clock) begin
    douta <= mem[address_a];
    doutb <= {mem[{address_b, 1'd1}], mem[{address_b, 1'd0}]};
    if (wren_a) begin
        mem[address_a] <= data_a;
        // $display("OAM[%x] <= %x", address_a, data_a);
    end
    if (wren_b) begin
        mem[{address_b,1'b1}] <= data_b[31:16];
        mem[{address_b,1'b0}] <= data_b[15:0];
        // $display("OAM[%x] <= %x, OAM=[%x] <= %x", {address_b,1'b0}, data_b[15:0], {address_b,1'b1}, data_b[31:16]);
    end
end

`endif

endmodule
