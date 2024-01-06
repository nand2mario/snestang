
// convert dualshock to snes controller
module ds2snes #(parameter FREQ=10_800_000) (
    input clk,

    input snes_joy_strb,
    input snes_joy_clk,
    output snes_joy_di,

    output [11:0] snes_buttons,     // (R L X A RT LT DN UP START SELECT Y B)

    output ds_clk,
    input ds_miso,
    output ds_mosi,
    output ds_cs
);

wire [7:0] rx0, rx1;

// JOYDATA:  BYsS UDLR   AXlr 0000
// Up: 0400, Down: 0200, Left: 0100, Right: 0080

//  dualshock buttons:  0:(L D R U St R3 L3 Se)  1:(□ X O △ R1 L1 R2 L2)
//  12 SNES buttons:    (R L X A RT LT DN UP START SELECT Y B)
//                      A=O, B=X, X=△, Y=□
wire [11:0] snes_btn = {~rx1[3] | ~rx1[1], ~rx1[2] | ~rx1[0],   // R L
                        ~rx1[4], ~rx1[5], ~rx0[5], ~rx0[7],     // X A RT LT
                        ~rx0[6], ~rx0[4], ~rx0[3], ~rx0[0],     // DN, UP, ST, SE
                        ~rx1[7], ~rx1[6]};                      // Y B 

assign snes_buttons = snes_btn;

// Dualshock controller
dualshock_controller #(.FREQ(FREQ)) ds (
    .clk(clk), .I_RSTn(1'b1),
    .O_psCLK(ds_clk), .O_psSEL(ds_cs), .O_psTXD(ds_mosi),
    .I_psRXD(ds_miso),
    .O_RXD_1(rx0), .O_RXD_2(rx1), .O_RXD_3(),
    .O_RXD_4(), .O_RXD_5(), .O_RXD_6()
);

reg [11:0] bits;
reg snes_joy_clk_r;
assign snes_joy_di = ~bits[0];

// CNT     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |13 |14 |15 |
// STRB    / \_______________________________________________________________
// CLK     ____/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \___
// DI      |bit 0| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |13 |14 |15 |  
// Sample     ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^  

always @(posedge clk) begin
    if (snes_joy_strb) 
        bits <= snes_btn;
    if (~snes_joy_clk && snes_joy_clk_r)    // falling edge: load new value
        bits <= {1'b0, bits[11:1]};        // JOYx_DI is flipped, from B to Y to ... to R then 4 zeros.
    snes_joy_clk_r <= snes_joy_clk;
end

endmodule