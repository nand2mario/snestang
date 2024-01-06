// XXX: this is not used. See test_loader.v instead.
//
// https://github.com/SlithyMatt/snes-hello
//
// built with roms/hello/build.sh and dumped with scripts/rom2hex.py

module testrom(
    input clk,
    input [21:0] addr,      // 4MB address space
    output reg [7:0] dout
);

reg [7:0] rom [0:1251];     // $0-$4E3
reg [7:0] hdr [0:63];       // $7FC0-$7FFF
initial begin
//    $readmemh("roms/hello_0_4E0.hex", rom);           // black background
//    $readmemh("roms/hello_7FC0_8000.hex", hdr);
    $readmemh("roms/hello2_0_4E4.hex", rom);            // grey background
    $readmemh("roms/hello2_7FC0_8000.hex", hdr);
end

// $0FD5 (hdr[31]) = $31 (0011_0001): HiROM + FastROM
always @(posedge clk) begin
    if (addr < 22'h4E4) 
        dout <= rom[addr[10:0]];
    else if (addr >= 22'h7FC0 && addr < 22'h8000)
        dout <= hdr[addr[5:0]];
    else
        dout <= 8'b0;
end

endmodule
