// SPI master module for picorv32 similar to simpleuart.v
// This is mostly for sd card access.
//
// Registers:
// 0x200_000C: Data reg. Write to initiate a byte transfer.
//             The lowest byte is transfered over SPI.
//             Then a read will return the received byte.
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

	input         reg_dat_we,
	input         reg_dat_re,
	input  [31:0] reg_dat_di,
	output [31:0] reg_dat_do,
	output        reg_dat_wait
);

reg [7:0] tx_byte;
wire [7:0] rx_byte /* synthesis syn_keep=1 */;
reg spi_start;
// reg cs_buf = 1;
// assign cs = cs_buf;

assign reg_dat_wait = reg_dat_we & ~spi_rxdv;
assign reg_dat_do = {24'b0, rx_byte};

SPI_Master spi_io_master (
  .i_Clk(clk), .i_Rst_L(resetn),
  .i_TX_Byte(tx_byte), .i_TX_DV(spi_start), .o_TX_Ready(spi_ready),
  .o_RX_DV(spi_rxdv), .o_RX_Byte(rx_byte),
  .o_SPI_Clk(sck), .i_SPI_MISO(miso), .o_SPI_MOSI(mosi)
);

always @(posedge clk) begin
	if (!resetn) begin
		spi_start <= 0;
		// cs_buf <= 1;
	end else begin
		spi_start <= 0;
		if (spi_ready && reg_dat_we) begin
			// cs_buf <= 0;
			spi_start <= 1;
			tx_byte <= reg_dat_di[7:0];
		end
	end
end

endmodule
