// send raw stereo audio stream through SPI master
// 4 bytes per sample: low_left, high_left, low_right, high_right
// So for 32Khz stereoaudio, min baud rate is 32K*32 = 1Mbps
module audio2spi (
    input clk,
    input audio_ready,
    input [15:0] audio_left,
    input [15:0] audio_right,

    output spi_clk,
    output spi_mosi,
    input spi_miso,
    output spi_ss,              // slave select

    output reg [3:0] errors
);

parameter CLK_FREQ = 21_500_000;
parameter BAUD_RATE = 921600;

reg [31:0] data;
reg data_wren;
reg [1:0] state;
wire ready;

reg [31:0] total;
reg [7:0] cnt = 0;

SPI_Master #(.CLKS_PER_HALF_BIT(CLK_FREQ/BAUD_RATE/2)) spi (
   .i_Clk(clk), .i_Rst_L(1'b1),
   .i_TX_Byte(data[7:0]), .i_TX_DV(data_wren), .o_TX_Ready(ready),
   .o_RX_DV(), .o_RX_Byte(),
   .o_SPI_Clk(spi_clk), .i_SPI_MISO(spi_miso), .o_SPI_MOSI(spi_mosi)
);

reg spi_ss_buf = 1'b1;
//assign spi_ss = spi_ss_buf;
assign spi_ss = 0;

always @(posedge clk) begin
    data_wren <= 0;
    case (state)
    2'd0:           // wait for audio data
        if (audio_ready) begin 
            data_wren <= 1;
            data <= {audio_right, audio_left};
//            data <= total;
//            total <= total + 1;
            state <= 1;
            cnt <= 3;
            spi_ss_buf <= 1'b0;         // enable slave
        end
    2'd1:           // wait for SPI to finish, then send next byte
        if (!data_wren && ready) begin
            if (cnt != 0) begin
                data <= {8'b0, data[31:8]};
                data_wren <= 1;
                cnt <= cnt - 1;
            end else begin              // done sending 4 bytes
                state <= 2'd0;
                spi_ss_buf <= 1'b1;     // disable slave
            end
        end
    endcase
end

endmodule
