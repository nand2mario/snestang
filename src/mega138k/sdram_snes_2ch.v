// Double-channel CL2 SDRAM controller for SNES on Tang Mega 138K Pro
// nand2mario 2024.2
// 
// This supports two parallel access streams (ROM/WRAM/BSRAM/RiscV softcore and ARAM), 
// independent from each other. SNES ROM/BSRAM/WRAM uses bank 0 (8MB, largest game is 6MB, 
// BSRAM max 1MB). RV uses bank 1. ARAM uses bank 2.
//
// This controller works at 64.8Mhz, lower than the 3 channel controller, making it
// more stable on the Mega 138K Pro. Requests need to be ready at most 3 fclk after
// the last clkref posedge. Data out is ready at least 3 fclk before the next clkref posedge.
//
// SDRAM is accessed in an interleaving style like this (RAS: bank activation,
//   CAS: read/write commands, DATA: read data available),
//
// clk_#    CPU         ARAM
//   0      RAS1
//   1      CAS1        DATA2
//   2                  RAS2/Refresh
//   3                              
//   4      DATA1       CAS2        <-- clkref
//   5                  
// 
// Here we do not overlap the two CAS-DATA periods, avoiding potential bus contentions.
//
// Tang SDRAM v1.2 - Winbond W9825G6KH. 8K rows, 512 words per row, 16 bits per word

module sdram_snes
#(
    // Clock frequency, max 66.7Mhz with current set of T_xx/CAS parameters.
    parameter         FREQ = 64_800_000,  

    // Time delays for 66.7Mhz max clock (min clock cycle 15ns)
    // The SDRAM supports max 166.7Mhz (RP/RCD/RC need changes)
    // Alliance AS4C32M16SB-7TIN 512Mb
    parameter [3:0]   CAS  = 4'd2,     // 2/3 cycles, set in mode register
    parameter [3:0]   T_WR = 4'd2,     // 2 cycles, write recovery
    parameter [3:0]   T_MRD= 4'd2,     // 2 cycles, mode register set
    parameter [3:0]   T_RP = 4'd1,     // 15ns, precharge to active
    parameter [3:0]   T_RCD= 4'd1,     // 15ns, active to r/w
    parameter [3:0]   T_RC = 4'd4      // 63ns, ref/active to ref/active
)
(
    // SDRAM side interface
    inout      [15:0] SDRAM_DQ,
    output reg [12:0] SDRAM_A,
    output reg [1:0]  SDRAM_BA,
    output            SDRAM_nCS,
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
	output reg [15:0] cpu_port0,    // output register for bank 0
	output reg [15:0] cpu_port1,    // output register for bank 1
	input      [23:1] cpu_addr,     // 16MB SNES memory space 
	input             cpu_rd /* synthesis syn_keep=1 */,
	input             cpu_wr /* synthesis syn_keep=1 */,
	input       [1:0] cpu_ds,       // which bytes to enable

    input      [19:0] bsram_addr,   // only [16:0] value, max 128KB
    input       [7:0] bsram_din,    // byte access
    output reg  [7:0] bsram_dout,
    input             bsram_rd,
    input             bsram_wr,

    // ARAM access uses bank 2
	input             aram_16,      // 16-bit access
	input      [15:0] aram_addr,
	input      [15:0] aram_din,
	output     [15:0] aram_dout,
	input             aram_rd,
    input             aram_wr,

    // Risc-V softcore
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
assign {SDRAM_nCS, SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd;

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

reg [3:0] cycle /* synthesis syn_keep=1 */;

reg clkref_r;
always @(posedge clk) clkref_r <= clkref;

// *_buf buffers those signals that crosses clkref boundaries
reg aram_rd_buf, aram_wr_buf, aram_16_buf;
reg [15:0] aram_addr_buf;
reg [15:0] aram_dout_buf;
// immediately use dq_in as aram_dout for cycle 1
assign aram_dout = (aram_rd_buf && cycle == 4'd1) ? dq_in : aram_dout_buf;

reg cpu_rd_buf, cpu_wr_buf, cpu_port_buf;
reg [1:0] cpu_ds_buf;
reg bsram_rd_buf, bsram_addr0_buf;
reg rv_rd_buf;

reg        refresh;
reg [8:0]  refresh_cnt;
reg        need_refresh = 1'b0;

always @(posedge clk) begin
	if (refresh_cnt == 0)
		need_refresh <= 0;
	else if (refresh_cnt == RFRSH_CYCLES)
		need_refresh <= 1;
end


//
// SDRAM state machine
//
always @(posedge clk) begin
    cycle <= cycle == 4'hf ? cycle : cycle + 4'd1;

    // defaults
    cmd_next <= CMD_NOP; 
    dq_oen_next <= 1'b1;

    // wait 200 us on power-on
    if (state == INIT && cfg_now) begin
        state <= CONFIG;
        cycle <= 0;
    end else if (state == CONFIG) case (cycle)
        // configuration sequence
        //  cycle  / 0 \___/ 1 \___/ 2 \___/ ... __/ 6 \___/ ...___/10 \___/11 \___/ 12\___
        //  cmd            |PC_All |Refresh|       |Refresh|       |  MRD  |       | _next_
        //                 '-T_RP--`----  T_RC  ---'----  T_RC  ---'------T_MRD----'
        4'd0 : begin
            // precharge all
            cmd_next <= CMD_PreCharge;
            a_next[10] <= 1'b1;
        end
        T_RP : begin
            // 1st AutoRefresh
            cmd_next <= CMD_AutoRefresh;
        end
        T_RP+T_RC : begin
            // 2nd AutoRefresh
            cmd_next <= CMD_AutoRefresh;
        end
        T_RP+T_RC+T_RC : begin
            // set register
            cmd_next <= CMD_SetModeReg;
            a_next[10:0] <= MODE_REG;
        end
        T_RP+T_RC+T_RC+T_MRD: begin
            state <= NORMAL;
            cycle <= 0;
            busy <= 1'b0;               // init&config is done
        end
    endcase else if (state == NORMAL) begin
        if (clkref & ~clkref_r)         // go to cycle 5 after clkref edge
            cycle <= 4'd5;
        else if (cycle == 5)
            cycle <= 0;
		refresh_cnt <= refresh_cnt + 1'd1;
        
        case (cycle[2:0])

        // CPU RAS
        3'd0: begin
            rv_wait <= 1;
            if (cpu_rd | cpu_wr) begin
                cmd_next <= CMD_BankActivate;
                ba_next <= {1'b0, cpu_addr[23]};        
                a_next <= cpu_addr[22:10];              // 8K rows, 13-bit address
                cpu_rd_buf <= cpu_rd;
                cpu_port_buf <= cpu_port;
                cpu_ds_buf <= cpu_ds;
            end else if (bsram_rd | bsram_wr) begin
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b01;
                a_next <= {6'b111_000, bsram_addr[16:10]};  // 17-bit bsram address, map to F0-F1:xxxx
                bsram_rd_buf <= bsram_rd;
                bsram_addr0_buf <= bsram_addr[0];
            end else if (rv_rd | rv_wr) begin
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b01;
                a_next <= rv_addr[22:10];        
                rv_wait <= 0;                           // rv request is served        
                rv_rd_buf <= rv_rd;
            end
        end

        // CPU CAS & ARAM DATA
        3'd1: begin
            if (cpu_rd | cpu_wr) begin
                cmd_next <= cpu_wr?CMD_Write:CMD_Read;
                ba_next <= {1'b0, cpu_addr[23]};
                a_next[10] <= 1'b1;                     // set auto precharge
                a_next[8:0] <= cpu_addr[9:1];           // column address
                SDRAM_DQM <= ~cpu_ds;     
                if (cpu_wr) begin
                    dq_oen_next <= 0;
                    dq_out_next <= cpu_din;
                end            
            end else if (bsram_rd | bsram_wr) begin
                cmd_next <= bsram_wr?CMD_Write:CMD_Read;
                ba_next <= 2'b01;
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
            if (aram_rd_buf) 
                aram_dout_buf <= dq_in;
            aram_rd_buf <= 0;
        end

        // ARAM RAS
        3'd2: begin
            if (aram_rd | aram_wr) begin  
                cmd_next <= CMD_BankActivate;
                ba_next <= 2'b10;
                a_next <= {7'b0, aram_addr[15:10]};
                aram_rd_buf <= aram_rd;
                aram_wr_buf <= aram_wr;
                aram_16_buf <= aram_16;
                aram_addr_buf <= aram_addr;
            end else if (need_refresh && ~cpu_rd && ~cpu_wr && ~bsram_rd && ~bsram_wr && ~rv_rd && ~rv_wr) begin  
                // refresh when both bank are idle
				refresh <= 1'b1;
				refresh_cnt <= 0;
				cmd_next <= CMD_AutoRefresh;                
            end
        end

        // ARAM CAS & CPU DATA
        3'd4: begin
            if (aram_rd_buf | aram_wr_buf) begin
                cmd_next <= aram_wr_buf ? CMD_Write : CMD_Read;
                ba_next <= 2'b10;
                a_next[10] <= 1'b1;                 // set auto precharge
                a_next[8:0] <= aram_addr_buf[9:1];      // column address
                SDRAM_DQM <= aram_16 ? 2'b0 : {~aram_addr_buf[0], aram_addr_buf[0]}; // DQM
                if (aram_wr_buf) begin
                    dq_oen_next <= 0;
                    dq_out_next <= aram_din;
                end
            end
            aram_wr_buf <= 0;
            if (cpu_rd_buf) begin
                if (cpu_port_buf) begin
                    if (cpu_ds_buf[0]) cpu_port1[7:0] <= dq_in[7:0];
                    if (cpu_ds_buf[1]) cpu_port1[15:8] <= dq_in[15:8];
                end else begin
                    if (cpu_ds_buf[0]) cpu_port0[7:0] <= dq_in[7:0];
                    if (cpu_ds_buf[1]) cpu_port0[15:8] <= dq_in[15:8];
                end
            end else if (bsram_rd_buf) begin
                if (bsram_addr0_buf) bsram_dout <= dq_in[15:8];
                else               bsram_dout <= dq_in[7:0];
            end
            if (rv_rd_buf && ~rv_wait) begin
                rv_dout <= dq_in;                
            end
            cpu_rd_buf <= 0;
            bsram_rd_buf <= 0;
            rv_rd_buf <= 0;
        end
        endcase
    end

    if (~resetn) begin
        busy <= 1'b1;
        dq_oen_next <= 1'b1;        // turn off DQ output
        SDRAM_DQM <= 2'b0;      // DQM
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