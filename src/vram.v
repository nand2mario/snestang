// SNES VRAM is basically two 8-bit SRAMs

module vram (
    input clk,

    input [14:0] addra, // low byte
    input wra_n,
    input [7:0] dina,   
    output reg [7:0] douta,

    input [14:0] addrb, // high byte
    input wrb_n,
    input [7:0] dinb,   
    output reg [7:0] doutb
);

// Two 32k * 8 mem
reg [7:0] mema [0:32*1024-1];
reg [7:0] memb [0:32*1024-1];

// wire [14:0] vram_addr = (dotclk == 1'b0 && vram_rd_n == 1'b0 && vram_addra[13:0] != vram_addrb[13:0]) ? vram_addrb[14:0] :
//                         vram_addra[14:0];
// (vram_addra[13:0] != vram_addrb[13:0]) ? vram_dbi_temp : vram_doutb;
// reg [7:0] vram_dbi_temp;

// always @(posedge dotclk) begin
//     vram_dbi_temp <= VRAM[vram_addr][15:8];
// end

always @(posedge clk) begin
    if (wra_n) 
        douta <= mema[addra];
    else begin
        mema[addra] <= dina;
        $display("vram_write_a: [%x]L <= %x", addra, dina);
    end
end

always @(posedge clk) begin
    if (wrb_n)
        doutb <= memb[addrb];
    else begin
        memb[addrb] <= dinb;
        $display("vram_write_b: [%x]H <= %x", addrb, dinb);
    end
end

endmodule