//
// Testbench
//

`timescale 1ns/10ps

module testbench;

reg clk = 0;
wire [5:0] fakeled;

P65816_top #(.ROM_FILE("blink_sim.hex")) DUT(
    .sys_clk (clk),
    .led (fakeled)
);

`ifndef FINISHTIME
    `define FINISHTIME 10000000
`endif

initial begin
    #450 $display("addr %x: %s",
        DUT.addr,
        (DUT.addr == 16'hfc00) ? "OK" : "FAIL");
    #`FINISHTIME $stop;
end

always #10 clk <= ~clk;

always @(fakeled) $display("fakeled=%02x", ~fakeled);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, testbench);
end

endmodule
