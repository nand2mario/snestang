// Dual-chip, 4-channel SDRAM controller for SNES on Tang Primer 25K and Tang Mega 138K
// nand2mario 2024.1
// 
// This supports 4 parallel access streams (CPU, ARAM, VRAM and RiscV softcore),
// independent from each other. SNES CPU uses bank 0 and 1 and thus is 16MB max. 
// ARAM uses bank 2. VRAM uses bank 3. Risc-V softcore uses the 2nd chip.
// 
// Memory works at 8x clkref speed. clkref and clk should come from the same PLL
// so that they are aligned. Access requests are recognized at clkref's rising edge. 
// Read results will be available in 1 clkref cycle for CPU, 1.25 cycles for ARAM, 
// 1.5 cycles for VRAM, and 1.75 cycles for RiscV.
//
// The Risc-V channel is 16 bit wide for reliability. A 32-bit design would be
// a 10x gear-ratio design and over 100Mhz.
//
// SDRAM is accessed in an interleaving style like this (RAS: bank activation,
// CAS: read/write commands, DS: DQM mask for reads, DATA: read data available),
//
//             Chip 1        | Chip 2   DQ driven by
//     CPU     ARAM    VRAM    RV                
// 0   RAS0            DS2              FPGA        
// 1           DATA1           CAS3     RAM         
// 2           RAS1            DS3      FPGA        
// 3   CAS0            DATA2            RAM
// 4   DS0             RAS2             FPGA
// 5           CAS1            DATA3    RAM 
// 6           DS1             RAS3     FPGA
// 7   DATA0           CAS2             RAM     
//
// Tang SDRAM v1.2 - 2x Winbond W9825G6KH-6 (166CL3, 133CL2). 8K rows, 512 words per row, 
// 16 bits per word

module sdram_snes
#(
    parameter         FREQ = 86_400_000,

    // Time delays
    parameter [3:0]   CAS  = 4'd3,     // 3 cycles, set in mode register
    parameter [3:0]   T_WR = 4'd2,     // 2 cycles, write recovery
    parameter [3:0]   T_MRD= 4'd2,     // 2 cycles, mode register set
    parameter [3:0]   T_RP = 4'd1,     // 15ns, precharge to active
    parameter [3:0]   T_RCD= 4'd1,     // 15ns, active to r/w, 2 cycles below 133, 1 cycle below 66.7
    parameter [3:0]   T_RC = 4'd4      // 63ns, ref/active to ref/active
)
(
    // SDRAM side interface
    inout      [15:0] SDRAM_DQ,
    output reg [12:0] SDRAM_A,
    output reg [1:0]  SDRAM_BA,
    output reg        SDRAM_nCS,    // chip select for 2 chips
    output            SDRAM_nWE,
    output            SDRAM_nRAS,
    output            SDRAM_nCAS,
    output            SDRAM_CKE,    // not strictly necessary, always 1
    output reg  [1:0] SDRAM_DQM,
    
    // Logic side interface
    input             clkref,       // main reference clock, requests are sampled on its rising edge
    input             clk,          // sdram clock, max 66.7Mhz
    input             resetn,

    // CPU access (ROM and WRAM) uses bank 0 and 1 (total 16MB)
	input      [15:0] cpu_din /* synthesis syn_keep=1 */,
	input             cpu_port,
	output reg [15:0] cpu_port0 /* synthesis syn_keep=1 */,    // output register for bank 0
	output reg [15:0] cpu_port1 /* synthesis syn_keep=1 */,    // output register for bank 1
	input      [23:1] cpu_addr,     // 16MB SNES memory space 
	input             cpu_rd /* synthesis syn_keep=1 */,
	input             cpu_wr /* synthesis syn_keep=1 */,
	input       [1:0] cpu_ds,       // byte enable

    input      [19:0] bsram_addr,
    input       [7:0] bsram_din,
    output reg [15:0] bsram_dout /* synthesis syn_keep=1 */,
    input             bsram_rd,
    input             bsram_wr,

    // ARAM access uses bank 2
	input             aram_16,      // 16-bit access
	input      [15:0] aram_addr,
	input      [15:0] aram_din,
	output reg [15:0] aram_dout,
	input             aram_rd,
    input             aram_wr,

    // Risc-V softcore uses bank 0-1 of 2nd chip
    input      [22:1] rv_addr,      // 8MB RV memory space (currently using only bank 0 of 2nd chip)
    input      [15:0] rv_din,       // 32-bit accesses
    input       [1:0] rv_ds,        // byte enable for writes
    output reg [15:0] rv_dout /* synthesis syn_keep=1 */,      // available 1 and 3/5 clkref cycles later
    input             rv_rd,
    input             rv_wr,

    output reg [23:0] total_refresh,

    output            busy
);

// Tri-state DQ input/output
reg dq_oen;        // 0 means output
reg [15:0] dq_out;
assign SDRAM_DQ = dq_oen ? {16{1'bz}} : dq_out;
wire [15:0] dq_in = SDRAM_DQ;     // DQ input
reg [3:0] cmd;
assign {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd[2:0];

reg busy_buf = 1;
assign busy = busy_buf;
assign SDRAM_CKE = 1'b1;

reg [1:0] state;
localparam INIT = 2'd0;
localparam CONFIG = 2'd1;
localparam NORMAL = 2'd2;

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
reg        dq_oen_next;
reg [15:0] dq_out_next;
reg [3:0]  cmd_next;
reg [12:0] a_next;
reg [1:0]  ba_next;
assign cmd = cmd_next;
assign SDRAM_BA = ba_next;
assign SDRAM_A = a_next;
assign dq_oen = dq_oen_next;
assign dq_out = dq_out_next;

// reg [3:0] cycle /* synthesis syn_keep=1 */;
reg [11:0] cycle;       // one hot encoded

reg clkref_r;
always @(posedge clk) clkref_r <= clkref;
reg cpu_rd_buf, aram_rd_buf;
reg rv_rd_buf, rv_wr_buf;
reg [31:0] rv_din_buf;
reg [22:1] rv_addr_buf;
reg [1:0] rv_ds_buf;

// reg        refresh;
reg [8:0]  refresh_cnt;
reg [1:0]  need_refresh = 0; // for 2 chips

//
// SDRAM state machine
//
always @(posedge clk) begin
    if (state == INIT ) begin
        if (cfg_now) begin                  // wait 200 us on power-on
            state <= CONFIG;
            cycle <= 1;
        end
    end else if (state == CONFIG)           // cycle 0-11 for CONFIG
        cycle <= {cycle[10:0], 1'b0};
    else begin                              // cycle 0-7 for NORMAL
        if (clkref & ~clkref_r)             // go to cycle 1 after clkref posedge
            cycle <= 2;
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
		need_refresh <= 2'b11;
        refresh_cnt <= 0;
    end

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
            cycle <= 1;
            busy_buf <= 1'b0;              // init&config is done
        end
    end else if (state == NORMAL) begin
        // RAS
        if (cycle[4'd0]) begin        // CPU
            if (cpu_rd | cpu_wr) begin
                cmd_next <= CMD_BankActivate;
                ba_next <= {1'b0, cpu_addr[23]};        
                a_next <= cpu_addr[22:10];              // 8K rows, 13-bit address
            end else if (bsram_rd | bsram_wr) begin
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b01;
                a_next <= {3'b111, bsram_addr[19:10]};  // 13-bit address
            end
        end
        if (cycle[4'd2]) begin        // ARAM
            if (aram_rd | aram_wr) begin    // tight timing for aram_rd, aram_wr, aram_addr
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b10;
                a_next <= {7'b0, aram_addr[15:10]};
                aram_rd_buf <= aram_rd;
            end else if (need_refresh[0] && ~cpu_rd && ~cpu_wr) begin  
                // refresh when all banks are idle
				// refresh <= 1'b1;
				cmd_next <= CMD_AutoRefresh;                
                need_refresh[0] <= 0;
                total_refresh <= total_refresh + 1;
            end            
        end
        if (cycle[4'd4]) begin        // VRAM
        end
        if (cycle[4'd6]) begin        // RV
            if (rv_rd | rv_wr) begin
                {rv_rd_buf, rv_wr_buf} <= {rv_rd, rv_wr};
                rv_addr_buf <= rv_addr;
                rv_din_buf <= rv_din;
                rv_ds_buf <= rv_ds;
                SDRAM_nCS <= 1'b1;
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b0;
                a_next <= rv_addr[22:10];
            end else if (need_refresh[1]) begin  
                // refresh for 2nd chip
                SDRAM_nCS <= 1'b1;
				cmd_next <= CMD_AutoRefresh;
                need_refresh[1] <= 0;
                total_refresh <= total_refresh + 1;
            end   
        end

        // CAS
        if (cycle[4'd3]) begin        // CPU
            if (cpu_rd | cpu_wr) begin
                cmd_next <= cpu_wr?CMD_Write:CMD_Read;
                ba_next <= {1'b0, cpu_addr[23]};
                a_next[10] <= 1'b1;                     // set auto precharge
                a_next[8:0] <= cpu_addr[9:1];           // column address
                if (cpu_wr) begin
                    dq_oen_next <= 0;
                    dq_out_next <= cpu_din;
                    SDRAM_DQM <= ~cpu_ds;     
                end            
            end else if (bsram_rd | bsram_wr) begin
                cmd_next <= bsram_wr?CMD_Write:CMD_Read;
                ba_next <= 2'b01;
                a_next[10] <= 1'b1;                     // set auto precharge
                a_next[8:0] <= bsram_addr[9:1];         // column address
                if (bsram_wr) begin
                    dq_oen_next <= 0;
                    dq_out_next <= {bsram_din, bsram_din};
                    SDRAM_DQM <= ~cpu_ds;
                end            
            end            
        end
        if (cycle[4'd5]) begin        // ARAM
            if (aram_rd | aram_wr) begin
                cmd_next <= aram_wr ? CMD_Write : CMD_Read;
                ba_next <= 2'b10;
                a_next[10] <= 1'b1;                 // set auto precharge
                a_next[8:0] <= aram_addr[9:1];      // column address
                if (aram_wr) begin
                    dq_oen_next <= 0;
                    dq_out_next <= aram_din;
                    SDRAM_DQM <= aram_16 ? 2'b0 : {~aram_addr[0], aram_addr[0]}; // DQM
                end
            end            
        end
        if (cycle[4'd7]) begin        // VRAM
        end
        if (cycle[4'd1]) begin        // RV
            if (rv_rd_buf || rv_wr_buf) begin
                SDRAM_nCS <= 1;
                cmd_next <= rv_wr_buf ? CMD_Write : CMD_Read;
                ba_next <= 2'b0;
                a_next[10] <= 1'b1;
                a_next[8:0] <= rv_addr_buf[9:1];
                if (rv_wr_buf) begin
                    dq_oen_next <= 0;
                    dq_out_next <= rv_din_buf;
                    SDRAM_DQM <= ~rv_ds_buf;
                    rv_wr_buf <= 0;
                end
            end
        end

        // DS
        if (cycle[4'd4] && (cpu_rd|bsram_rd)) // CPU
            SDRAM_DQM <= 2'b0;
        if (cycle[4'd6] && aram_rd)           // ARAM
            SDRAM_DQM <= 2'b0; 
        if (cycle[4'd8]) begin                // VRAM
        end
        if (cycle[4'd2])                      // RV
            if (rv_rd_buf) SDRAM_DQM <= 2'b0;

        // DATA
        if (cycle[4'd7]) begin                // CPU
            if (cpu_rd) begin
                if (cpu_port) begin
                    if (cpu_ds[0]) cpu_port1[7:0] <= dq_in[7:0];
                    if (cpu_ds[1]) cpu_port1[15:8] <= dq_in[15:8];
                end else begin
                    if (cpu_ds[0]) cpu_port0[7:0] <= dq_in[7:0];
                    if (cpu_ds[1]) cpu_port0[15:8] <= dq_in[15:8];
                end
            end else if (bsram_rd) begin
                if (cpu_ds[0]) bsram_dout[7:0] <= dq_in[7:0];
                if (cpu_ds[1]) bsram_dout[15:8] <= dq_in[15:8];
            end            
        end
        if (cycle[4'd1]) begin                // ARAM
            if (aram_rd_buf) aram_dout <= dq_in;
            aram_rd_buf <= 0;
        end
        if (cycle[4'd3]) begin                // VRAM
        end
        if (cycle[4'd5]) begin                // RV
            if (rv_rd_buf) begin
                rv_dout <= dq_in;
                rv_rd_buf <= 0;
            end
        end
    end

    if (~resetn) begin
        busy_buf <= 1'b1;
        dq_oen_next <= 1'b1;        // turn off DQ output
        SDRAM_DQM <= 2'b0;          // DQM
        state <= INIT;
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