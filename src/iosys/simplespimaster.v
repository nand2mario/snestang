// SPI master module for picorv32 similar to simpleuart.v
// This is mostly for sd card access.
//
// Registers:
// 0x200_0020: Byte reg. Write to initiate a byte transfer.
//             The lowest byte is transfered over SPI.
//             Then a read will return the received byte.
// 0x200_0024: Word transfer. Writes and reads 4 bytes.
//
// SPI clock is 1/4 of clk. SD_DAT[3:1]=3'b011 for SPI mode.
module simplespimaster (
	input clk,
	input resetn,

	// SPI mode: SD_DAT[3]=0, SD_DAT[2]=1, SD_DAT[1]=1
	output sck,			// SD_SCK
	output mosi,		// SD_CMD
	input  miso,		// SD_DAT[0]
	// output cs,			// SD_DAT[3]

    input             reg_byte_we,  // 1: write-read a byte 
    input	      	  reg_word_we,	// 1: write-read a word

    input      [31:0] reg_di,
    output reg [31:0] reg_do,
    output            reg_wait
);

reg [7:0] tx_byte;
wire [7:0] rx_byte /* synthesis syn_keep=1 */;
reg spi_start;

reg wait_buf = 1;
assign reg_wait = wait_buf & (reg_byte_we | reg_word_we);

SPI_Master spi_io_master (
  .i_Clk(clk), .i_Rst_L(resetn),
  .i_TX_Byte(tx_byte), .i_TX_DV(spi_start), .o_TX_Ready(spi_ready),
  .o_RX_DV(spi_rxdv), .o_RX_Byte(rx_byte),
  .o_SPI_Clk(sck), .i_SPI_MISO(miso), .o_SPI_MOSI(mosi)
);

reg [1:0] cnt;  // how many bytes is already sent

// receiving
always @(posedge clk) begin
    if (!resetn) begin
        wait_buf <= 1;
        cnt <= 0;
    end else begin
        wait_buf <= 1;
        if (spi_rxdv) begin
            cnt <= cnt + 2'd1;
            reg_do[cnt*8 +: 8] <= rx_byte;
            if (reg_byte_we && cnt == 2'd0 || reg_word_we && cnt == 2'd3) begin
                wait_buf <= 0;
                cnt <= 0;
            end
        end        
    end
end

// sending
always @(posedge clk) begin
	if (!resetn) begin
		spi_start <= 0;
	end else begin
		spi_start <= 0;
		if (spi_ready && (reg_byte_we || reg_word_we)) begin      // spi_ready is after spi_rxdv
			spi_start <= 1;
			tx_byte <= reg_di[cnt*8 +: 8];
		end
	end
end

endmodule
