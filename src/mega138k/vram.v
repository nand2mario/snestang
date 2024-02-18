// Block RAM backed SNES VRAM implementation
// SNES VRAM is basically two 8-bit SRAMs

module vram (
    input clk,

    input [14:0] addra, // low byte
    input rda,
    input wra,
    input [7:0] dina,   
    output reg [7:0] douta,

    input [14:0] addrb, // high byte
    input rdb,
    input wrb,
    input [7:0] dinb,   
    output reg [7:0] doutb
);

// Two 32k * 8 mem
reg [7:0] mema [0:32*1024-1];
reg [7:0] memb [0:32*1024-1];

always @(posedge clk) begin
    if (wra) begin
        mema[addra] <= dina;
        // $fdisplay(32'h80000002, "vram_write_a: [%x]L <= %x", addra, dina);
    end else 
        douta <= mema[addra];
end

always @(posedge clk) begin
    if (wrb) begin
        memb[addrb] <= dinb;
        // $fdisplay(32'h80000002, "vram_write_b: [%x]H <= %x", addrb, dinb);
    end else
        doutb <= memb[addrb];
end

endmodule