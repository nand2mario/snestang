// Triple-channel CL2 SDRAM controller for SNES on Tang Primer 25K and Tang Mega 138K
// nand2mario 2024.1
// 
// This supports 3 parallel access streams (ROM/WRAM/BSRAM/RiscV softcore, ARAM, VRAM),
// independent from each other. SNES ROM/BSRAM/WRAM uses bank 0 (8MB, largest game is 6MB, 
// BSRAM max 1MB). RV uses bank 1. ARAM uses bank 2. VRAM uses bank 3.
// 
// Memory works at 8x clkref speed. clkref and clk should come from the same PLL
// so that they are aligned. Request needs to be ready 3 fclk before clkref posedge. 
// Data out is ready 3 fclk after clkref posedge.
//
// All requests except RV ones are served in one clkref cycle. RV requests are served
// on a best-effort basis. ROM/WRAM take precedence. `rv_wait` signals whether RV needs
// to wait. The Risc-V channel is 16 bit wide for reliability. A 32-bit design would 
// need even higher gear ratio and is probably less reliable.
//
// SDRAM is accessed in an interleaving style as follows (RAS: bank activation,
// READ: CAS read commands, WRITE: CAS write commands, DATA: read data available, 
// <LZ>: memory starts driving DQ one cycle before DATA). Note that this design avoids 
// READ-then-WRITE bus contentions on the <LZ> cycle, as the memory starts driving DQ 
// during <LZ> cycles.
//
//   Normal schedule      Delayed write
// 0 RAS                 RAS           
// 1       RAS   <LZ>                <LZ>          
// 2 R/W         DATA    READ        DATA      
// 3       READ                RAS         
// 4 <LZ>        RAS     <LZ>        RAS   
// 5 DATA                DATA                  
// 6       DATA                WRITE      <-- clkref posedge
// 7             R/W                 R/W   
//
// As can be seen, there are two schedules depending on operations by the first two channels 
// (ROM/WRAM/BSRAM/RiscV, and ARAM):
// - Normal schedule:     READ-READ, WRITE-READ, WRITE-WRITE
// - Delayed write:       READ-WRITE
//
// Timings: 
//    clkref  ‾‾‾‾\_______/‾‾‾‾‾‾‾\____
//    cycle   |0|1|2|3|4|5|6|7|0|1|2|3|
//    request ==|    
//    dout                          |==
//
// Tang SDRAM v1.2 - Winbond W9825G6KH-6 (166CL3, 133CL2). 8K rows, 512 words per row, 
// 16 bits per word

module sdram_snes
#(
    parameter         FREQ = 86_400_000,

    // Time delays
    parameter [3:0]   CAS  = 4'd2,     // 2 cycles, set in mode register
    parameter [3:0]   T_WR = 4'd2,     // 2 cycles, write recovery
    parameter [3:0]   T_MRD= 4'd2,     // 2 cycles, mode register set
    parameter [3:0]   T_RP = 4'd1,     // 15ns, precharge to active
    parameter [3:0]   T_RCD= 4'd1,     // 15ns, active to r/w, 2 cycles below 133, 1 cycle below 66.7
    parameter [3:0]   T_RC = 4'd4      // 63ns, ref/active to ref/active
)
(
    // SDRAM side interface
    inout      [15:0] SDRAM_DQ,
    output     [12:0] SDRAM_A,
    output     [1:0]  SDRAM_BA,
    output reg        SDRAM_nCS,    // chip select for 2 chips
    output            SDRAM_nWE,
    output            SDRAM_nRAS,
    output            SDRAM_nCAS,
    output            SDRAM_CKE,    // not strictly necessary, always 1
    output reg  [1:0] SDRAM_DQM,
    
    // Logic side interface
    input             clkref,       // main reference clock, requests are sampled on its rising edge
    input             clk,          // sdram clock
    input             resetn,

    // CPU access (ROM and WRAM) uses bank 0 and 1 (total 16MB)
    input      [15:0] cpu_din /* synthesis syn_keep=1 */,
    input             cpu_port,
    output reg [15:0] cpu_port0,    // output register for ROM
    output reg [15:0] cpu_port1,    // output register for WRAM
    input      [22:1] cpu_addr,     // 8MB memory
    input             cpu_rd /* synthesis syn_keep=1 */,
    input             cpu_wr /* synthesis syn_keep=1 */,
    input       [1:0] cpu_ds,       // byte enable

    input      [16:0] bsram_addr,
    input       [7:0] bsram_din,
    output reg  [7:0] bsram_dout,
    input             bsram_rd,
    input             bsram_wr,

    // ARAM access uses bank 2
    input             aram_16,      // 16-bit access
    input      [15:0] aram_addr,
    input      [15:0] aram_din,
    output reg [15:0] aram_dout,
    input             aram_rd,
    input             aram_wr,

    // VRAM1
	input      [14:0] vram1_addr,
	input       [7:0] vram1_din,
	output reg  [7:0] vram1_dout,
	input             vram1_rd,     // rd==1 for both, addr same for 16-bit reads
	input             vram1_wr,     // wr==1 only for one of vram

    // VRAM2
	input      [14:0] vram2_addr,
	input       [7:0] vram2_din,
	output reg  [7:0] vram2_dout,
	input             vram2_rd,
	input             vram2_wr,

    // Risc-V softcore uses bank 0-1 of 2nd chip
    input      [22:1] rv_addr,      // 8MB RV memory space
    input      [15:0] rv_din,       // 16-bit accesses
    input      [1:0]  rv_ds,
    output reg        rv_wait,      // rv request is not serviced this cycle
    output reg [15:0] rv_dout,      
    input             rv_rd,
    input             rv_wr,

    output reg [23:0] total_refresh,

    output reg        busy
);

// Tri-state DQ input/output
reg dq_oen;        // 0 means output
reg [15:0] dq_out;
assign SDRAM_DQ = dq_oen ? {16{1'bz}} : dq_out;
wire [15:0] dq_in = SDRAM_DQ;     // DQ input
reg [3:0] cmd;
assign {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd[2:0];

assign SDRAM_CKE = 1'b1;

reg [2:0] state;
localparam INIT = 3'd0;
localparam CONFIG = 3'd1;
localparam NORMAL = 3'd2;
localparam REFRESH = 3'd3;

// CS# RAS# CAS# WE#
localparam CMD_NOP=4'b1111;
localparam CMD_SetModeReg=4'b0000;
localparam CMD_BankActivate=4'b0011;
localparam CMD_Write=4'b0100;
localparam CMD_Read=4'b0101;
localparam CMD_AutoRefresh=4'b0001;
localparam CMD_PreCharge=4'b0010;

localparam [2:0] BURST_LEN = 3'b0;      // burst length 1
localparam BURST_MODE = 1'b0;           // sequential
localparam [10:0] MODE_REG = {4'b0, CAS[2:0], BURST_MODE, BURST_LEN};
// 64ms/8192 rows = 7.8us -> 500 cycles@64.8MHz
localparam RFRSH_CYCLES = 9'd500;

reg cfg_now;            // pulse for configuration

// registers for next cycle output
reg         dq_oen_next;
reg [15:0]  dq_out_next;
reg [3:0]   cmd_next;
reg [12:0]  a_next;
reg [1:0]   ba_next;
assign      cmd = cmd_next;
assign      SDRAM_BA = ba_next;
assign      SDRAM_A = a_next;
assign      dq_oen = dq_oen_next;
assign      dq_out = dq_out_next;

reg [11:0]   cycle;     // one hot encoded

reg         clkref_r;
always @(posedge clk) clkref_r <= clkref;

reg [8:0]   refresh_cnt;
reg         need_refresh = 0; 
reg         write_delay;
reg         channel0_active;
reg         aram_rd_buf, aram_wr_buf, aram_16_buf;
reg [15:0]  aram_din_buf;
reg [15:0]  aram_addr_buf;
reg         vram_req;
reg         vram1_rd_buf, vram1_wr_buf, vram2_rd_buf, vram2_wr_buf;
reg [15:0]  vram_din_buf;
reg [14:0]  vram_addr_buf;
//
// SDRAM state machine
//
always @(posedge clk) begin
    if (~resetn) begin
        busy <= 1'b1;
        dq_oen_next <= 1'b1;        // turn off DQ output
        SDRAM_DQM <= 2'b0;          // DQM
        state <= INIT;
        write_delay <= 0;
    end else begin
        if (state == INIT) begin
            if (cfg_now) begin                  // wait 200 us on power-on
                state <= CONFIG;
                cycle <= 1;
            end
        end else if (state == CONFIG)           // cycle 0-11 for CONFIG
            cycle <= {cycle[10:0], 1'b0};
        else begin                              // cycle 0-7 for NORMAL
            if (clkref & ~clkref_r)             // go to cycle 7 after clkref posedge
                cycle <= 12'b0000_1000_0000;
            else
                cycle[7:0] <= {cycle[6:0], cycle[7]};
        end

        // defaults
        cmd_next <= CMD_NOP; 
        dq_oen_next <= 1'b1;
        SDRAM_DQM <= 2'b11;
        SDRAM_nCS <= 0;

        // refresh logic
        refresh_cnt <= refresh_cnt + 1'd1;
        if (refresh_cnt == RFRSH_CYCLES) begin
            need_refresh <= 1;
            refresh_cnt <= 0;
        end

        // wait 200 us on power-on
        if (state == CONFIG) begin
            // configuration sequence
            //  cycle  / 0 \___/ 1 \___/ 2 \___/ ... __/ 6 \___/ ...___/10 \___/11 \___/ 12\___
            //  cmd            |PC_All |Refresh|       |Refresh|       |  MRD  |       | _next_
            //                 '-T_RP--`----  T_RC  ---'----  T_RC  ---'------T_MRD----'
            if (cycle[0]) begin
                // precharge all
                cmd_next <= CMD_PreCharge;
                a_next[10] <= 1'b1;
            end
            if (cycle[T_RP]) begin
                // 1st AutoRefresh
                cmd_next <= CMD_AutoRefresh;
            end
            if (cycle[T_RP+T_RC]) begin
                // 2nd AutoRefresh
                cmd_next <= CMD_AutoRefresh;
            end
            if (cycle[T_RP+T_RC+T_RC]) begin
                // set register
                cmd_next <= CMD_SetModeReg;
                a_next[10:0] <= MODE_REG;
            end
            if (cycle[T_RP+T_RC+T_RC+T_MRD]) begin
                state <= NORMAL;
                cycle <= 0;
                busy <= 1'b0;              // init&config is done
            end
        end else if (state == NORMAL) begin
            // RAS
            if (cycle[4'd0]) begin        // CPU and RV uses bank 0 and 1
                reg is_read = 0;
                rv_wait <= 1;
                channel0_active <= 0;
                if (cpu_rd | cpu_wr) begin
                    cmd_next <= CMD_BankActivate;
                    ba_next <= 2'b00;        
                    a_next <= cpu_addr[22:10];              // 8K rows, 13-bit address
                    is_read = cpu_rd;
                    channel0_active <= 1;
                end else if (bsram_rd | bsram_wr) begin
                    cmd_next <= CMD_BankActivate;
                    ba_next <= 2'b00;
                    a_next <= {6'b111_000, bsram_addr[16:10]};  // BSRAM uses 128KB starting from 7MB
                    is_read = bsram_rd;
                    channel0_active <= 1;
                end else if (rv_rd | rv_wr) begin
                    cmd_next <= CMD_BankActivate;
                    ba_next <= 2'b01;
                    a_next <= rv_addr[22:10];        
                    rv_wait <= 0;                           // rv request is served        
                    is_read = rv_rd;
                    channel0_active <= 1;
                end
                write_delay <= is_read & aram_wr;           // delay aram write on READ-WRITE
            end
            if (cycle[1] & ~write_delay | cycle[3] & write_delay) begin
                if (aram_rd | aram_wr) begin                // ARAM @ 1 or 3
                    cmd_next <= CMD_BankActivate;
                    ba_next <= 2'b10;
                    a_next <= {7'b0, aram_addr[15:10]};
                    aram_rd_buf <= aram_rd;                 // buffer everything for next clkref cycle
                    aram_wr_buf <= aram_wr;
                    aram_din_buf <= aram_din;
                    aram_addr_buf <= aram_addr;
                    aram_16_buf <= aram_16;
                end
            end
            if (cycle[3]) begin     // precalc VRAM signals
                reg [14:0] vram_addr_t = (vram1_rd|vram1_wr) ? vram1_addr : vram2_addr;
                vram_req <= vram1_rd | vram2_rd | vram1_wr | vram2_wr;
                vram_addr_buf <= vram_addr_t;
                {vram1_rd_buf, vram1_wr_buf, vram2_rd_buf, vram2_wr_buf} <= 
                    {vram1_rd, vram1_wr, vram2_rd, vram2_wr};
            end
            if (cycle[4]) begin     // VRAM
                if (vram_req) begin
                    cmd_next <= CMD_BankActivate;
                    ba_next <= 2'b11;
                    a_next <= {7'b0, vram_addr_buf[14:9]};
                    vram_din_buf <= {vram2_din, vram1_din};
                end else if (need_refresh && ~channel0_active && ~aram_rd && ~aram_wr) begin
                    // refresh when all banks are idle
                    // refresh <= 1'b1;
                    cmd_next <= CMD_AutoRefresh;
                    need_refresh <= 0;
                    total_refresh <= total_refresh + 1;
                end
                
            end

            // CAS
            if (cycle[2]) begin     // CPU and RV
                if (cpu_rd | cpu_wr) begin
                    cmd_next <= cpu_wr?CMD_Write:CMD_Read;
                    ba_next <= 2'b00;
                    a_next[10] <= 1'b1;                     // set auto precharge
                    a_next[8:0] <= cpu_addr[9:1];           // column address
                    if (cpu_wr) begin
                        dq_oen_next <= 0;
                        dq_out_next <= cpu_din;
                        SDRAM_DQM <= ~cpu_ds;
                    end else
                        SDRAM_DQM <= 2'b0;
                end else if (bsram_rd | bsram_wr) begin
                    cmd_next <= bsram_wr?CMD_Write:CMD_Read;
                    ba_next <= 2'b00;
                    a_next[10] <= 1'b1;                     // set auto precharge
                    a_next[8:0] <= bsram_addr[9:1];         // column address
                    SDRAM_DQM <= {~bsram_addr[0], bsram_addr[0]};
                    if (bsram_wr) begin
                        dq_oen_next <= 0;
                        dq_out_next <= {bsram_din, bsram_din};
                    end
                end else if (rv_rd | rv_wr) begin
                    cmd_next <= rv_wr ? CMD_Write : CMD_Read;
                    ba_next <= 2'b01;
                    a_next[10] <= 1'b1;
                    a_next[8:0] <= rv_addr[9:1];
                    if (rv_wr) begin
                        dq_oen_next <= 0;
                        dq_out_next <= rv_din;
                        SDRAM_DQM <= ~rv_ds;
                    end else
                        SDRAM_DQM <= 2'b0;
                end
            end 
            if (cycle[3] & ~write_delay | cycle[6] & write_delay) begin      // ARAM CAS @ 3 or 6
                // not 5 to give DQ bus time to turn around from DATA in cycle 5
                if (aram_rd_buf | aram_wr_buf) begin
                    cmd_next <= aram_wr_buf ? CMD_Write : CMD_Read;
                    ba_next <= 2'b10;
                    a_next[10] <= 1'b1;                 // set auto precharge
                    a_next[8:0] <= aram_addr_buf[9:1];      // column address
                    if (aram_wr_buf) begin
                        dq_oen_next <= 0;
                        dq_out_next <= aram_din_buf;
                        SDRAM_DQM <= aram_16_buf ? 2'b0 : {~aram_addr_buf[0], aram_addr_buf[0]}; // DQM
                    end else
                        SDRAM_DQM <= 2'b0;
                end
            end
            if (cycle[7]) begin     // VRAM
                if (vram_req) begin
                    cmd_next <= (vram1_wr_buf | vram2_wr_buf) ? CMD_Write : CMD_Read;
                    ba_next <= 2'b11;
                    a_next[10] <= 1'b1;
                    a_next[8:0] <= vram_addr_buf[8:0];
                    if (vram1_wr_buf | vram2_wr_buf) begin
                        dq_oen_next <= 0;
                        dq_out_next <= vram_din_buf;
                        SDRAM_DQM <= {~vram2_wr_buf, ~vram1_wr_buf};
                    end else
                        SDRAM_DQM <= 2'b0;
                end
            end

            // DATA
            if (cycle[5]) begin     // CPU & RV
                if (cpu_rd) begin
                    if (cpu_port) begin
                        if (cpu_ds[0]) cpu_port1[7:0] <= dq_in[7:0];
                        if (cpu_ds[1]) cpu_port1[15:8] <= dq_in[15:8];
                    end else begin
                        if (cpu_ds[0]) cpu_port0[7:0] <= dq_in[7:0];
                        if (cpu_ds[1]) cpu_port0[15:8] <= dq_in[15:8];
                    end
                end else if (bsram_rd) begin
                    if (bsram_addr[0]) bsram_dout <= dq_in[15:8];
                    else               bsram_dout <= dq_in[7:0];
                end 
                if (rv_rd & ~rv_wait) begin
                    rv_dout <= dq_in;
                end
            end
            if (cycle[6]) begin     // ARAM
                if (aram_rd_buf) aram_dout <= dq_in;
                aram_rd_buf <= 0;
                aram_wr_buf <= 0;
            end
            if (cycle[2]) begin     // VRAM
                if (vram1_rd_buf) vram1_dout <= dq_in[7:0];
                if (vram2_rd_buf) vram2_dout <= dq_in[15:8];
                {vram1_rd_buf, vram1_wr_buf, vram2_rd_buf, vram2_wr_buf} <= 0;
            end
        end
    end
end


//
// Generate cfg_now pulse after initialization delay (normally 200us)
//
reg  [14:0]   rst_cnt;
reg rst_done, rst_done_p1, cfg_busy;
  
always @(posedge clk) begin
    if (~resetn) begin
        rst_cnt  <= 15'd0;
        rst_done <= 1'b0;
        cfg_busy <= 1'b1;
    end else begin
        rst_done_p1 <= rst_done;
        cfg_now     <= rst_done & ~rst_done_p1;// Rising Edge Detect

        if (rst_cnt != FREQ / 1000 * 200 / 1000) begin      // count to 200 us
            rst_cnt  <= rst_cnt[14:0] + 15'd1;
            rst_done <= 1'b0;
            cfg_busy <= 1'b1;
        end else begin
            rst_done <= 1'b1;
            cfg_busy <= 1'b0;
        end        
    end
end

endmodule