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
    input             clk,
    input             resetn,

    output            sck,			// SD_SCK
    output            mosi,			// SD_CMD
    input             miso,			// SD_DAT[0]
    // Other pins needs to be hard-wired for SPI mode: 
    //     SD_DAT[3]=0, SD_DAT[2]=1, SD_DAT[1]=1

    input             reg_byte_we,  // 1: write-read a byte 
    input	      	  reg_word_we,	// 1: write-read a word

    input      [31:0] reg_di,
    output     [31:0] reg_do,
    output            reg_wait
);

reg [7:0] tx_byte;
wire [7:0] rx_byte;
reg spi_start;
reg [23:0] rx_buf;      // higher 3 bytes

assign reg_wait = (reg_byte_we || reg_word_we) && (~spi_rxdv || cnt!=0);
assign reg_do = {rx_buf, rx_byte};

SPI_Master spi_io_master (
  .i_Clk(clk), .i_Rst_L(resetn),
  .i_TX_Byte(tx_byte), .i_TX_DV(spi_start), .o_TX_Ready(spi_ready),
  .o_RX_DV(spi_rxdv), .o_RX_Byte(rx_byte),
  .o_SPI_Clk(sck), .i_SPI_MISO(miso), .o_SPI_MOSI(mosi)
);

reg [1:0] cnt;

always @(posedge clk) begin
    if (!resetn) begin
        spi_start <= 0;
        // cs_buf <= 1;
    end else begin
        spi_start <= 0;
        if (spi_ready && (reg_byte_we || reg_word_we)) begin
            // start transfer of 1st byte
            spi_start <= 1;
            tx_byte <= reg_di[7:0];
            cnt <= reg_word_we ? 2'd3 : 2'd0;
            rx_buf <= 0;
        end
        if (spi_rxdv && cnt != 0) begin
            // latch this non-final byte
            rx_buf <= {rx_buf[15:0], rx_byte};
            // start next byte
            cnt <= cnt - 2'd1;
            spi_start <= 1;
            case (cnt)
            2'd3: tx_byte <= reg_di[15:8];
            2'd2: tx_byte <= reg_di[23:16];
            2'd1: tx_byte <= reg_di[31:24];
            default ;
            endcase
        end
    end
end

endmodule
