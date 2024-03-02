// Block RAM backed SNES VRAM implementation
// SNES VRAM is basically two 8-bit SRAMs

module vram (
    input clk,

    input [14:0] vram1_addr, // low byte
    input vram1_req,
    output reg vram1_ack,
    input vram1_we,
    input [7:0] vram1_din,   
    output reg [7:0] vram1_dout,

    input [14:0] vram2_addr, // high byte
    input vram2_req,
    output reg vram2_ack,
    input vram2_we,
    input [7:0] vram2_din,   
    output reg [7:0] vram2_dout
);

// Two 32k * 8 mem
reg [7:0] mema [0:32*1024-1];
reg [7:0] memb [0:32*1024-1];

always @(posedge clk) begin
    if (vram1_req ^ vram1_ack) begin
        vram1_ack <= vram1_req;
        if (vram1_we) begin
            mema[vram1_addr] <= vram1_din;
            // $fdisplay(32'h80000002, "vram_write_a: [%x]L <= %x", addra, dina);
        end else 
            vram1_dout <= mema[vram1_addr];
    end
end

always @(posedge clk) begin
    if (vram2_req ^ vram2_ack) begin
        vram2_ack <= vram2_req;
        if (vram2_we) begin
            memb[vram2_addr] <= vram2_din;
            // $fdisplay(32'h80000002, "vram_write_b: [%x]H <= %x", addrb, dinb);
        end else
            vram2_dout <= memb[vram2_addr];
    end
end

endmodule