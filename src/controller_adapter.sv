
// Adapt button presses to SNES controller interface
module controller_adapter (
    input clk,
    input [15:0] snes_buttons,     // (R L X A RT LT DN UP START SELECT Y B)

    input snes_joy_strb,
    input snes_joy_clk,
    output snes_joy_di
);

reg [15:0] bits;
reg snes_joy_clk_r;
assign snes_joy_di = ~bits[0];

always @(posedge clk) begin
    if (snes_joy_strb) 
        bits <= snes_buttons;
    if (~snes_joy_clk && snes_joy_clk_r)    // falling edge: load new value
        bits <= {1'b1, bits[15:1]};         // JOYx_DI is flipped, from B to Y to ... to R then 4 zeros. After that it has to return 1.
    snes_joy_clk_r <= snes_joy_clk;
end

endmodule