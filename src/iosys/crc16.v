module crc16 (
    input clk,
    input reset,
    input [7:0] data_in,
    input data_in_en,       // Added enable pin
    output reg [15:0] crc_out
);

reg [15:0] crc_reg;
reg [15:0] next_crc;

always @(posedge clk) begin
    if (reset) begin
        crc_reg <= 16'hFFFF;  // Initial value
    end else if (data_in_en) begin  // Only update when enabled
        crc_reg <= next_crc;
    end
end

// CRC-16-CCITT polynomial: x^16 + x^12 + x^5 + 1 (0x1021)
always @(*) begin
    next_crc = crc_reg;
    for (int i = 7; i >= 0; i = i - 1) begin       // LFSR
        next_crc = (next_crc << 1) ^ (16'h1021 & {16{(next_crc[15] ^ data_in[i])}});
    end
end

assign crc_out = crc_reg;

endmodule
