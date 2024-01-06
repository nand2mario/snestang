/*
SD and UART SNES rom loader. 

For SD, this loads an SNES rom produced by scripts/smc2img.py
- It first reads in the SNES header in the 1st sector and fills in map_ctrl, 
  rom_size and ram_size.
- Then sd_loader reads the actual rom. Data is streamed over dout and dout_valid
  pulses 1 when a byte is available on dout. 
- Finally if everything is successful, done becomes 1, or fail becomes 1.

For UART, you send 32 bytes of SNES header first, followed by the actual ROM.
*/
module loader #(
    parameter FREQ = 10_800_000         // Frequency of wclk, for SD clock divider
) (
    input wclk,
    input resetn,

    output reg overlay,                 // Only implemented in menu_loader.sv
    input fclk,
    output [14:0] overlay_color,        
    input [7:0] overlay_y,
    input [7:0] overlay_x,    

    output reg [7:0] dout,              // ROM data is streamed out through dout.  
    output reg dout_valid,              // pulse 1 when dout is valid
    output reg loading,                 // 1: for the loading process. 
                                        // rising edge resets SNES, falling edge starts SNES
    output reg fail,

    output reg [7:0] map_ctrl,          // 0x15 of SNES header, `mapper_header` in mist-snes
    output reg [7:0] rom_type_header,   // 0x16
    output reg [3:0] rom_size,          // 0x17, actual size is (1024 << rom_size)
    output reg [3:0] ram_size,          // 0x18
    output reg [23:0] rom_mask,
    output reg [23:0] ram_mask,

    input serial_reset,                 // pulse to start serial transmission
    input [7:0] serial_data,            // 32 bytes of SNES header, then actual ROM
    input serial_data_valid,            // serial data strobe

    // SD card physical interface
    output sd_clk,
    inout  sd_cmd,                      // MOSI
    input  sd_dat0,                     // MISO
    output sd_dat1,                     // 1
    output sd_dat2,                     // 1
    output sd_dat3,                     // 1
    
    // debug
    input [7:0] dbg_reg,
    output reg [7:0] dbg_dat_out,
    output [23:0] debug_sd_rsector,
    output debug_serial_en,
    output [2:0] debug_state
);

assign overlay = 0;

reg sd_rstart = 0;
reg [23:0] sd_rsector;
wire sd_rdone, sd_outen;
wire [7:0] sd_outbyte;
reg [8:0] off;         // in-sector offset
reg serial_en = 1'b0;

reg sd_outen_r;
reg [15:0] checksum = 16'b0;

//assign dout = din;
//assign dout_valid = loading & din_valid;

sd_reader #(
    .CLK_DIV(FREQ > 50_000_000 ? 3'd2 : FREQ > 25_000_000 ? 3'd1 : 3'd0), .SIMULATE(0)
) sd_reader_i (
    .rstn(resetn), .clk(wclk),
    .sdclk(sd_clk), .sdcmd(sd_cmd), .sddat0(sd_dat0),
    .card_stat(),.card_type(),
    .rstart(sd_rstart), .rbusy(), .rdone(sd_rdone), .outen(sd_outen),
    .rsector({8'b0, sd_rsector}),
    .outaddr(), .outbyte(sd_outbyte)
);

// SD card loading process
reg [2:0] state;
localparam [2:0] SD_READ_META = 3'd1;       // getting meta-data from sector 0
localparam [2:0] SD_READ_ROM = 3'd2;
localparam [2:0] SERIAL_READ_META = 3'd3;
localparam [2:0] SERIAL_READ_ROM = 3'd4;
localparam [2:0] FAIL = 3'd5;
localparam [2:0] DONE = 3'd6;

assign debug_state = state; 
assign debug_sd_rsector = state == SERIAL_READ_META ? off : sd_rsector;
assign debug_serial_en = serial_en;

always @(posedge wclk) begin
    if (~resetn || serial_reset) begin
        sd_rstart <= 1;
        sd_rsector <= 0;
        state <= SD_READ_META;
        off <= 0;
        loading <= 1;
        fail <= 1'b0;
        checksum <= 16'b0;
        if (serial_reset) begin
            serial_en <= 1'b1;
            state <= SERIAL_READ_META;
        end
    end else begin
        sd_outen_r <= sd_outen;
        dout_valid <= 0;
        case (state)
        SD_READ_META: begin     // parse meta sector
            if (sd_outen & ~sd_outen_r) begin
                sd_rstart <= 0;
                off <= off + 9'b1;
                if (off == 9'h15) map_ctrl <= sd_outbyte;
                if (off == 9'h16) rom_type_header <= sd_outbyte;
                if (off == 9'h17) begin 
                    rom_size <= sd_outbyte[3:0];
                    rom_mask <= (24'h400 << sd_outbyte[3:0]) - 24'b1;
                end
                if (off == 9'h18) begin 
                    ram_size <= sd_outbyte[3:0];
                    ram_mask <= (24'h400 << sd_outbyte[3:0]) - 24'b1;
                end
            end
            if (sd_rdone) begin
                // if (map_ctrl[7:5] != 3'b1 || (map_ctrl[3:0] != 4'd0 
                //         && map_ctrl[3:0] != 4'd1 && map_ctrl[3:0] != 4'd5)) begin
                if (ram_size > 8) begin             // RAM size 256KB max
                    // invalid meta sector
                    sd_rstart <= 0;
                    state <= FAIL;
                    fail <= 1'b1;
                end else begin
                    sd_rstart <= 1;
                    sd_rsector[23:0] <= 23'd1;      // rom starts at sector 1
                    off <= 0;
                    state <= SD_READ_ROM;
                    loading <= 1;
                end
            end
        end
        SD_READ_ROM: begin
            sd_rstart <= 0;
            if (sd_outen) begin
                // data handled by dout_valid, dout above
                checksum <= checksum + {8'b0, sd_outbyte};
                dout <= sd_outbyte;
                dout_valid <= 1;
            end
            if (sd_rdone) begin
                // e.g. rom_size==8, 256KB, sector 1 to 512.
                //      rom_size==12, 4MB, sector 1 to 8192.
                if (sd_rsector[13:0] == (14'd2 << rom_size) + 14'd1) begin
                    loading <= 0;
                    state <= DONE;
                end else begin
                    sd_rstart <= 1;
                    sd_rsector[13:0] <= sd_rsector[13:0] + 14'd1;
                    off <= 0;
                    state <= SD_READ_ROM;
                end
            end        
        end
        SERIAL_READ_META: begin
            if (serial_data_valid) begin
                off <= off + 9'b1;
                if (off == 9'h15) map_ctrl <= serial_data;
                if (off == 9'h16) rom_type_header <= serial_data;
                if (off == 9'h17) begin 
                    rom_size <= serial_data[3:0];
                    rom_mask <= (24'h400 << serial_data[3:0]) - 24'b1;
                end
                if (off == 9'h18) begin 
                    ram_size <= serial_data[3:0];
                    ram_mask <= (24'h400 << serial_data[3:0]) - 24'b1;
                end
            end
            if (off == 9'h20) begin
                // if (map_ctrl[7:5] != 3'b1 || (map_ctrl[3:0] != 4'd0 
                //         && map_ctrl[3:0] != 4'd1 && map_ctrl[3:0] != 4'd5)) begin
                if (ram_size > 8) begin             // RAM size 256KB max
                    // invalid meta sector
                    state <= FAIL;
                    serial_en <= 1'b0;
                    fail <= 1'b1;
                end else begin
                    off <= 0;
                    sd_rsector <= 0;        // borrow sd_rsector for counting
                    state <= SERIAL_READ_ROM;
                end
            end
        end
        SERIAL_READ_ROM: begin
            if (serial_data_valid) begin
                checksum <= checksum + {8'b0, serial_data};
                dout <= serial_data;
                dout_valid <= 1;
                off <= off + 9'b1;
                if (off == 9'd511)
                    sd_rsector[13:0] <= sd_rsector[13:0] + 14'b1;
            end
            if (sd_rsector[13:0] == (14'd2 << rom_size)) begin
                loading <= 0;
                state <= DONE;
                serial_en = 1'b0;
            end
        end
        endcase        
    end 
end

always @* begin
    case (dbg_reg)
    8'h00: dbg_dat_out <= map_ctrl;
//    8'h01: dbg_dat_out <= chiplet;
    8'h02: dbg_dat_out <= rom_size;
    8'h03: dbg_dat_out <= ram_size;
    8'h04: dbg_dat_out <= rom_mask[7:0];
    8'h05: dbg_dat_out <= rom_mask[15:8];
    8'h06: dbg_dat_out <= rom_mask[23:16];
    8'h07: dbg_dat_out <= ram_mask[7:0];
    8'h08: dbg_dat_out <= ram_mask[15:8];
    8'h09: dbg_dat_out <= ram_mask[23:16];
    8'h0a: dbg_dat_out <= {5'b0, state};
    8'h0b: dbg_dat_out <= {5'b0, sd_outen, sd_rdone, loading};
    8'h0c: dbg_dat_out <= sd_rsector[7:0];
    8'h0d: dbg_dat_out <= sd_rsector[15:8];
    8'h0e: dbg_dat_out <= sd_rsector[23:16];
    8'h0f: dbg_dat_out <= off[7:0];
    8'h10: dbg_dat_out <= {7'b0, off[8]};
    8'h11: dbg_dat_out <= checksum[7:0];
    8'h12: dbg_dat_out <= checksum[15:8];
    default: dbg_dat_out <= 8'b0;
    endcase
end

endmodule

// convert dout/dout_valid pulse from clk_fast to clk_slow
/*
module sd_cross (
    input clk_fast,
    input clk_slow,

    input [7:0] dout_orig,              // ROM data is streamed out through dout.  
    input dout_valid_orig,              // pulse 1 when dout is valid

    output reg [7:0] dout,
    output reg dout_valid
);

reg dout_valid_toggle = 1'b0;
always @(posedge clk_fast) begin        // convert pulse to toggle
    if (dout_valid_orig) begin
        dout_valid_toggle = ~dout_valid_toggle;
        dout <= dout_orig;
    end
end

reg dout_valid_toggle_r = 1'b0;
always @(posedge clk_slow) begin        // detect toggle change and output pulse
    dout_valid_toggle_r <= dout_valid_toggle;
    dout_valid <= 1'b0;
    if (dout_valid_toggle != dout_valid_toggle_r)
        dout_valid <= 1'b1;
end

endmodule
*/