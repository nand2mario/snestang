
// IOSys - PicoRV32-based IO subsystem for snestang
//
// IOSys provides the following functionality,
// - Menu system
// - ROM file loading
// - (Future) USB controller handling
// - (Future) Configuration options
// - (Future) Savestate handling
//
// This is similar to the IO controller of MIST, or HPS of MiSTer.
//
// The softcore runs RV32I at 10.8Mhz and uses SDRAM as main memory. Firmware is 
// loaded from SPI flash on the board. Firmware source is in /snestang/firmware.
// 
// Author: nand2mario, 1/2024

`ifndef PICORV32_REGS
`ifdef PICORV32_V
`error "iosys.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module iosys (
    input wclk,
    input hclk,                     // hdmi clock
    input resetn,

    // OSD display interface
    output overlay,
    input [10:0] overlay_x,         // 720p
    input [9:0] overlay_y,
    output [14:0] overlay_color,    // BGR5
    input [11:0] joy1,              // joystick 1: (R L X A RT LT DN UP START SELECT Y B)
    input [11:0] joy2,              // joystick 2

    // ROM loading interface
    output reg rom_loading,             // 0-to-1 loading starts, 1-to-0 loading is finished
    output [7:0] rom_do,            
    output reg rom_do_valid,            // strobe for rom_do
    // ROM meta-data
    output reg [7:0] map_ctrl,          
    output reg [3:0] rom_size,
    output reg [3:0] ram_size,
    output reg [23:0] rom_mask,
    output reg [23:0] ram_mask,
    
    // SDRAM interface for risc-v softcore
    output reg [22:0] rv_addr,
    output reg [15:0] rv_din,
    output reg [1:0] rv_ds,
    input [15:0] rv_dout,
    output reg rv_rd,
    output reg rv_wr,
    input ram_busy,                 // iosys starts after SDRAM initialization

    // SPI flash
    output flash_spi_cs_n,          // chip select
    input  flash_spi_miso,          // master in slave out
    output flash_spi_mosi,          // mster out slave in
    output flash_spi_clk,           // spi clock
    output flash_spi_wp_n,          // write protect
    output flash_spi_hold_n,        // hold operations

    // SD card
    output sd_clk,
    inout  sd_cmd,                  // MOSI
    input  sd_dat0,                 // MISO
    output sd_dat1,                 // 1
    output sd_dat2,                 // 1
    output sd_dat3                  // 0 for SPI mode

    // UART
    // input UART_RXD,
    // output UART_TXD,
);

/* verilator lint_off PINMISSING */
/* verilator lint_off WIDTHTRUNC */

localparam FIRMWARE_SIZE = 256*1024;

reg flash_loaded;
reg flash_loading;
reg [20:0] flash_cnt;
reg [20:0] flash_addr /* synthesis syn_keep=1 */;

reg flash_start;
wire [7:0] flash_dout;
wire flash_out_strb;
assign flash_spi_hold_n = 1;
assign flash_spi_wp_n = 0;
reg [15:0] flash_d;
reg flash_wr;

// Load 256KB of ROM from flash address 0x500000 into SDRAM at address 0x0
spiflash #(.ADDR(24'h500000), .LEN(FIRMWARE_SIZE)) flash (
    .clk(wclk), .resetn(resetn),
    .ncs(flash_spi_cs_n), .miso(flash_spi_miso), .mosi(flash_spi_mosi),
    .sck(flash_spi_clk),

    .start(flash_start), .dout(flash_dout), .dout_strb(flash_out_strb),
    .busy()
);

always @(posedge wclk) begin
    if (~resetn) begin
        flash_loaded <= 0;
        flash_cnt <= 0;
    end else begin
        flash_start <= 0;
        flash_wr <= 0;
        if (~flash_loaded && ~flash_loading && ~ram_busy) begin
            // start loading
            flash_start <= 1;
            flash_loading <= 1;
        end
        if (flash_loading) begin
            if (flash_out_strb) begin
                if (flash_cnt[0]) begin
                    flash_d[15:8] <= flash_dout;
                    flash_wr <= 1;
                    flash_addr <= flash_cnt;
                end else
                    flash_d[7:0] <= flash_dout;
                flash_cnt <= flash_cnt + 1;
                if (flash_cnt + 1 == FIRMWARE_SIZE) begin
                    flash_loading <= 0;
                    flash_loaded <= 1;
                end
            end
        end
    end
end

// picorv32 softcore
wire mem_valid /* synthesis syn_keep=1 */;
wire mem_ready;
wire [31:0] mem_addr /* synthesis syn_keep=1 */, mem_wdata /* synthesis syn_keep=1 */;
wire [3:0] mem_wstrb /* synthesis syn_keep=1 */;
wire [31:0] mem_rdata /* synthesis syn_keep=1 */;

reg ram_ready;
reg [31:0] ram_rdata;

wire        textdisp_reg_char_sel /* synthesis syn_keep=1 */= mem_valid && (mem_addr == 32'h 0200_0000);

wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
wire [31:0] simpleuart_reg_div_do;

wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
wire [31:0] simpleuart_reg_dat_do;
wire        simpleuart_reg_dat_wait;

wire        simplespimaster_reg_sel = mem_valid && (mem_addr == 32'h0200_000C);
wire [31:0] simplespimaster_reg_do;
wire        simplespimaster_reg_wait /* synthesis syn_keep=1 */;

wire        romload_reg_ctrl_sel /* synthesis syn_keep=1 */ = mem_valid && (mem_addr == 32'h 0200_0010);       // write 1 to start loading, 0 to finish loading
wire        romload_reg_data_sel /* synthesis syn_keep=1 */ = mem_valid && (mem_addr == 32'h 0200_0014);       // write once to load 4 bytes

wire        joystick_reg_sel = mem_valid && (mem_addr == 32'h 0200_0018);

assign mem_ready = ram_ready || textdisp_reg_char_sel || simpleuart_reg_div_sel || 
            romload_reg_ctrl_sel || romload_reg_data_sel || joystick_reg_sel ||
            (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) ||
            (simplespimaster_reg_sel && !simplespimaster_reg_wait);

assign mem_rdata = ram_ready ? ram_rdata :
        joystick_reg_sel ? {4'b0, joy1, 4'b0, joy2} :
        simpleuart_reg_div_sel ? simpleuart_reg_div_do :
        simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : 
        simplespimaster_reg_sel ? simplespimaster_reg_do : 32'h 0000_0000;

picorv32 #(
    // .ENABLE_MUL(1),
    // .ENABLE_DIV(1),
    // .COMPRESSED_ISA(1)
    .CATCH_ILLINSN(0),
    .ENABLE_COUNTERS (0),
    .ENABLE_COUNTERS64 (0),
    .CATCH_MISALIGN (0),
    .TWO_STAGE_SHIFT(0)
) rv32 (
    .clk(wclk), .resetn(resetn & flash_loaded),
    .mem_valid(mem_valid), .mem_ready(mem_ready), .mem_addr(mem_addr), 
    .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata)
);

// text display @ 0x0200_0000
textdisp disp (
    .wclk(wclk), .hclk(hclk), .resetn(resetn),
    .overlay_x(overlay_x), .overlay_y(overlay_y), .overlay_color(overlay_color),
    .reg_char_we(textdisp_reg_char_sel ? mem_wstrb : 4'b0),
    .reg_char_di(mem_wdata) 
);

// toggle overlay display on/off
reg overlay_buf = 1;
assign overlay = overlay_buf;
always @(posedge wclk) begin
    if (~resetn) begin
        overlay_buf <= 1;
    end else begin
        if (textdisp_reg_char_sel && mem_wstrb[0]) begin
            case (mem_wdata[25:24])
            2'd1: overlay_buf <= 1;
            2'd2: overlay_buf <= 0;
            default: ;
            endcase
        end 
    end
end

// uart @ 0x0200_0004 & 0x200_0008
// simpleuart simpleuart (
//     .clk         (wclk         ),
//     .resetn      (resetn      ),

//     .ser_tx      (UART_TXD      ),
//     .ser_rx      (UART_RXD      ),

//     .reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
//     .reg_div_di  (mem_wdata),
//     .reg_div_do  (simpleuart_reg_div_do),

//     .reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
//     .reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
//     .reg_dat_di  (mem_wdata),
//     .reg_dat_do  (simpleuart_reg_dat_do),
//     .reg_dat_wait(simpleuart_reg_dat_wait)
// );

// spi sd card @ 0x0200_000c
assign sd_dat1 = 1;
assign sd_dat2 = 1;
assign sd_dat3 = 0;
simplespimaster simplespi (
    .clk(wclk), .resetn(resetn),
    .sck(sd_clk), .mosi(sd_cmd), .miso(sd_dat0),
    .reg_dat_we(simplespimaster_reg_sel ? mem_wstrb[0] : 1'b0),
    .reg_dat_re(simplespimaster_reg_sel && !mem_wstrb),
    .reg_dat_di(mem_wdata),
    .reg_dat_do(simplespimaster_reg_do),
    .reg_dat_wait(simplespimaster_reg_wait)
);

// rom loading I/O
// 12-byte header + data
// header[0]: map_ctrl
// header[1]: rom_size
// header[2]: ram_size
// header[4..6]: rom_mask (little endian)
// header[8..10]: ram_mask
// header[3,7,11]: unused
reg [1:0] rom_cnt, rom_header;
reg [31:0] rom_do_buf;
assign rom_do = rom_do_buf[7:0];
always @(posedge wclk) begin
    if (~resetn) begin
        rom_cnt <= 0;
    end else begin
        rom_do_valid <= 0;
        if (romload_reg_ctrl_sel && mem_wstrb) begin
            if (mem_wdata[7:0] == 8'd1) begin
                rom_loading <= 1;
                rom_header <= 0;
            end
            if (mem_wdata[7:0] == 8'd0)
                rom_loading <= 0;
        end
        if (romload_reg_data_sel && mem_wstrb) begin
            case (rom_header)
            2'd0: begin         // 12-byte header
                map_ctrl <= mem_wdata[7:0];
                rom_size <= mem_wdata[11:8];
                ram_size <= mem_wdata[19:16];
                rom_header <= 2'd1;
            end
            2'd1: begin
                rom_mask <= mem_wdata[23:0];
                rom_header <= 2'd2;
            end
            2'd2: begin
                ram_mask <= mem_wdata[23:0];
                rom_header <= 2'd3;
            end
            2'd3: begin                 // actual ROM data
                rom_do_buf <= mem_wdata;
                rom_cnt <= 2'd3;
                rom_do_valid <= 1;
            end
            endcase
        end
        if (rom_cnt != 2'd0) begin      // output remaining rom_do
            rom_do_buf[23:0] <= rom_do_buf[31:8];
            rom_cnt <= rom_cnt - 2'd1;
            rom_do_valid <= 1;
        end
    end
end

// RV memory access
reg [1:0] ram_cnt;
reg ram_writing;
reg [15:0] rv_din_hi;
reg [1:0] rv_ds_hi;
always @(posedge wclk) begin
    if (~resetn) begin
        ram_cnt <= 0;
        ram_writing <= 0;
        ram_ready <= 0;
    end else begin
        rv_rd <= 0;
        rv_wr <= 0;
        if (flash_loading) begin
            rv_addr <= flash_addr;
            rv_wr <= flash_wr;
            rv_din <= flash_d;        
            rv_ds <= 2'b11;    
        end else begin
            reg wr = (| mem_wstrb);
            ram_ready <= 0;
            case (ram_cnt)
            2'd0:
                if (mem_valid && ~ram_ready && mem_addr < 8*1024*1024) begin
                    rv_addr <= {mem_addr[22:2], 2'b00};
                    if (wr) begin
                        ram_ready <= 1;                 // allow cpu to move on
                        rv_wr <= 1;
                        ram_writing <= 1;
                        rv_din <= mem_wdata[15:0];      // low 16-bit request
                        rv_ds <= mem_wstrb[1:0];
                        rv_din_hi <= mem_wdata[31:16];  // store hi 16-bit request
                        rv_ds_hi <= mem_wstrb[3:2];
                    end else begin
                        rv_rd <= 1;
                    end
                    ram_cnt <= 1;
                end
            2'd1: begin
                if (~ram_writing) begin // read hi 16-bit
                    rv_rd <= 1;
                    rv_addr <= {mem_addr[22:2], 2'b10};                
                end
                ram_cnt <= 2;
            end
            2'd2: begin
                if (ram_writing) begin  // write hi 16-bit
                    rv_wr <= 1;
                    rv_din <= rv_din_hi;
                    rv_ds <= rv_ds_hi;
                    rv_addr <= {mem_addr[22:2], 2'b10};                
                end else begin
                    ram_rdata[15:0] <= rv_dout; 
                end 
                ram_cnt <= 3;
            end
            2'd3: begin
                if (~ram_writing) begin
                    ram_rdata[31:16] <= rv_dout; 
                    ram_ready <= 1;
                end
                ram_writing <= 0;
                ram_cnt <= 0;                
            end
            endcase            
        end

    end
end

// assign led = ~{2'b0, (^ total_refresh[7:0]), s0, flash_cnt[12]};     // flash while loading

endmodule

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule

