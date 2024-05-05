// send raw stereo audio stream through UART
// 4 bytes per sample: low_left, high_left, low_right, high_right
// So for 32Khz stereoaudio, min baud rate is 32K*32 = 1Mbps
module audio2uart (
    input clk,
    input audio_ready,
    input [15:0] audio_left,
    input [15:0] audio_right,

    output tx
);

parameter CLK_FREQ = 21_500_000;
parameter BAUD_RATE = 921600;

reg [31:0] data;
reg data_wren;
reg [1:0] cnt;
wire busy;

reg [31:0] total;

//uart_tx_V2 #(.clk_freq(CLK_FREQ), .uart_freq(BAUD_RATE)) uart (
//    .clk(clk), .din(data[7:0]), .wr_en(data_wren), .tx_busy(busy), .tx_p(uart_tx)
//);

uart_tx #(.CLKS_PER_BIT(CLK_FREQ/BAUD_RATE)) uart1 (
   .i_Clock(clk), .i_Tx_DV(data_wren), .i_Tx_Byte(data[7:0]), 
   .o_Tx_Active(busy), .o_Tx_Serial(tx), .o_Tx_Done() );

always @(posedge clk) begin
    data_wren <= 0;
    if (audio_ready) begin
        data_wren <= 1;
        // data <= {audio_right, audio_left};
        data <= total;
        total <= total + 1;
        cnt <= 1;       // only send the left channel as we don't have enough UART bandwidth for both
    end else if (!data_wren && !busy && cnt != 0) begin
        data <= {8'b0, data[31:8]};
        data_wren <= 1;
        cnt <= cnt - 1;
    end 
end

endmodule


