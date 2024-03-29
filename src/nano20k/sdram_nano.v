// Triple-channel CL2 SDRAM controller for SNES on Tang Nano 20K
// nand2mario 2024.3
// 
// This supports 3 parallel access streams (ROM/WRAM/BSRAM/RiscV softcore, ARAM, VRAM),
// independent from each other. SNES ROM/WRAM uses bank 0 (8MB, largest game is 6MB, 
// BSRAM max 1MB). RV and BSRAM uses bank 1. ARAM uses bank 2. VRAM uses bank 3. 
// SDRAM works at 86Mhz.
//
// SDRAM is accessed in an interleaving style like this (RAS: bank activation,
//   CAS: read/write commands, DATA: read data available),
//
//   Normal schedule      Delayed write   clkref
//   CPU   ARAM  VRAM    CPU   ARAM  VRAM
//  ---------------------------------------------
// 0 RAS                 RAS                0
// 1       RAS   <LZ>          RAS   <LZ>   0       
// 2 R/W         DATA    READ        DATA   1   
// 3       READ                             1
// 4 <LZ>        RAS     <LZ>        RAS    1
// 5 DATA                DATA               1  
// 6       DATA                WRITE        0
// 7             R/W                 R/W    0
// 
// As can be seen, there are two schedules depending on operations by the first two channels 
// (ROM/WRAM/BSRAM/RiscV, and ARAM):
// - Normal schedule:     READ-READ, WRITE-READ, WRITE-WRITE
// - Delayed write:       READ-WRITE
//
// Requests are placed using the "multi-cycle req-ack handshake", borrowed from the MIST
// sdram controller. Whenever a new request is needed, the host readies the addr/din/we lines,
// then toggles the *_req line. After the controller accepts the request, it toggles the 
// *_ack line to notify the host. Now the host is free to make new requests.
//
// A clkref signal, if supplied, allows finer control of the timings of the controller.
// It needs to be 1/8 the speed of clk. The cycles will aligned as shown above.
// In this case, CPU/RV/ARAM requests are accepted when clkref=1, while VRAM requests are
// accepted when clkref=0.
//
// Clkref also allows relaxed timing constraints. Requests need to be ready at most 3 
// clks after mclk edge. Data out is ready at least 3 fclk before mclk posedge. This 
// means the following timing constraints.
//
// set_multicycle_path 3 -setup -end -from [get_clocks {mclk}] -to [get_clocks {fclk}]
// set_multicycle_path 2 -hold -end -from [get_clocks {mclk}] -to [get_clocks {fclk}]
// set_multicycle_path 3 -setup -start -from [get_clocks {fclk}] -to [get_clocks {mclk}]
// set_multicycle_path 2 -hold -start -from [get_clocks {fclk}] -to [get_clocks {mclk}]
//
// Tang Nano 20K embedded 64Mbit SDRAM - 4 banks, 2K rows, 256 words per row, 32-bit words

module sdram_snes
#(
    // Clock frequency
    parameter         FREQ = 86_000_000,  

    // Typical SDRAM delays
    parameter [4:0]   CAS  = 2,     // 2/3 cycles, set in mode register
    parameter [4:0]   T_WR = 2,     // 2 cycles, write recovery
    parameter [4:0]   T_MRD= 2,     // 2 cycles, mode register set
    parameter [4:0]   T_RP = 2,     // 15ns, precharge to active
    parameter [4:0]   T_RCD= 2,     // 15ns, active to r/w
    parameter [4:0]   T_RC = 6      // 63ns, ref/active to ref/active
)
(
    // SDRAM side interface
    inout      [31:0] SDRAM_DQ,
    output     [10:0] SDRAM_A,
    output reg [3:0]  SDRAM_DQM,
    output reg [1:0]  SDRAM_BA,
    output            SDRAM_nCS,
    output            SDRAM_nWE,
    output            SDRAM_nRAS,
    output            SDRAM_nCAS,
    output            SDRAM_CKE,    // not strictly necessary, always 1
    
    // Logic side interface
    input             clk,          // sdram clock, max 66.7Mhz
    input             mclk,
    input             clkref,       // main reference clock, half speed of clk
    input             resetn,

    // CPU access (ROM and WRAM) uses bank 0 and 1 (total 16MB)
	input      [15:0] cpu_din /* synthesis syn_keep=1 */,
	input             cpu_port,
	output reg [15:0] cpu_port0,    // output register for bank 0
	output reg [15:0] cpu_port1,    // output register for bank 1
	input      [22:1] cpu_addr,     // 8MB SNES memory, with WRAM at end
    input             cpu_req,
    output reg        cpu_req_ack,
	input             cpu_we,
	input       [1:0] cpu_ds,       // which bytes to enable

    input      [19:0] bsram_addr,   // only [16:0], max 128KB
    input       [7:0] bsram_din,    // byte access
    output reg  [7:0] bsram_dout,
    input             bsram_req,
    output reg        bsram_req_ack,
    input             bsram_we,

    // ARAM access uses bank 2
	input             aram_16,      // 16-bit access
	input      [15:0] aram_addr,
	input      [15:0] aram_din,
	output reg [15:0] aram_dout,
    input             aram_req,
    output reg        aram_req_ack,
	input             aram_we,

    // VRAM1
    // Two modes are supported for VRAM.
    // 1. 8-bit read or write. One port active a time.
    // 2. 16-bit reads. vram1_rd=vram2_rd=1, vram1_addr==vram2_addr
	input      [14:0] vram1_addr,
	input       [7:0] vram1_din,
	output reg  [7:0] vram1_dout,
	input             vram1_req,
    output reg        vram1_ack,
	input             vram1_we,     // wr==1 only for one of vram

    // VRAM2
	input      [14:0] vram2_addr,
	input       [7:0] vram2_din,
	output reg  [7:0] vram2_dout,
	input             vram2_req,
    output reg        vram2_ack,
	input             vram2_we,

    // RISC-V softcore
    // For nano 20k, RV channel shares bank 2 with ARAM
    input      [22:1] rv_addr,      // 8MB RV memory space
    input      [15:0] rv_din,       // 16-bit accesses
    input      [1:0]  rv_ds,
    output reg [15:0] rv_dout,
    input             rv_req,
    output reg        rv_req_ack,   // ready for new requests. read data available on NEXT mclk
    input             rv_we,

    output            refreshing,
    output reg [23:0] total_refresh,

    output reg        busy
);

// Tri-state DQ input/output
reg dq_oen;        // 0 means output
reg [31:0] dq_out;
assign SDRAM_DQ = dq_oen ? {32{1'bz}} : dq_out;
wire [31:0] dq_in = SDRAM_DQ;     // DQ input
reg [3:0] cmd;
reg [10:0] a;
assign {SDRAM_nCS, SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE} = cmd;
assign SDRAM_A = a;

assign SDRAM_CKE = 1'b1;

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
localparam RFRSH_CYCLES = 9'd501;

// state
reg [16:0] cycle;       // one hot encoded
reg normal=0, setup=0;
reg cfg_now;            // pulse for configuration

// requests
reg [24:0] addr_latch[3];
reg [15:0] din_latch[3];
reg  [2:0] oe_latch;
reg  [2:0] we_latch;
reg  [1:0] ds[3];

localparam PORT_NONE  = 2'd0;

localparam PORT_CPU   = 2'd1;
localparam PORT_BSRAM = 2'd2;

localparam PORT_ARAM  = 2'd1;
localparam PORT_RV    = 2'd2;

localparam PORT_VRAM  = 2'd1;
localparam PORT_VRAM1 = 2'd2;
localparam PORT_VRAM2 = 2'd3;

reg  [1:0] port[3];
reg  [1:0] next_port[3];
reg [22:0] next_addr[3];        // 2-bit bank #, then 2MB byte address in bank
reg [15:0] next_din[3];
reg  [1:0] next_ds[3];
reg  [2:0] next_we;
reg  [2:0] next_oe;

reg clkref_r;
always @(posedge clk) clkref_r <= clkref;

reg        refresh;
assign refreshing = refresh;
reg [8:0]  refresh_cnt;
reg        write_delay;
reg        need_refresh = 1'b0;

always @(posedge clk) begin
	if (refresh_cnt == 0)
		need_refresh <= 0;
	else if (refresh_cnt == RFRSH_CYCLES)
		need_refresh <= 1;
end

// ROM: bank 0,1
// WRAM, BSRAM: bank 1
always @(*) begin
	next_port[0] = PORT_NONE;
	next_addr[0] = 0;
	next_we[0] = 0;
	next_oe[0] = 0;
	next_ds[0] = 0;
	next_din[0] = 0;
    if (cpu_req ^ cpu_req_ack) begin
		next_port[0] = PORT_CPU;
		next_addr[0] = { 1'b0, cpu_addr[21:1], 1'b0 };  // CPU uses bank 0 and 1, WRAM at last 128KB of bank 1
		next_din[0]  = cpu_din;
		next_ds[0]   = cpu_ds;
		next_we[0]   = cpu_we;
		next_oe[0]   = ~cpu_we;
	end else if (bsram_req ^ bsram_req_ack) begin
		next_port[0] = PORT_BSRAM;
		next_addr[0] = { 6'b01_1110, bsram_addr[16:0]};  // BSRAM at 2nd last 128KB of bank 1
		next_din[0] = { bsram_din, bsram_din };
		next_ds[0] = {bsram_addr[0], ~bsram_addr[0]};
		next_we[0] = bsram_we;
		next_oe[0] = ~bsram_we;
	end 
end

// ARAM,RV: bank 2
always @* begin
	next_port[1] = PORT_NONE;
	next_addr[1] = 0;
	next_we[1] = 0;
	next_oe[1] = 0;
	next_ds[1] = 0;
	next_din[1] = 0;
    // T_RC=6, refresh starts cycle 3 and ends exactly at cycle 1, so causes no delay to ARAM
    if (aram_req ^ aram_req_ack) begin
		next_port[1] = PORT_ARAM;
		next_addr[1] = { 7'b10_00000, aram_addr};       // ARAM at start of bank 2
		next_we[1]   = aram_we;
		next_oe[1]   = ~aram_we;
		next_din[1]  = aram_din;
		next_ds[1]   = aram_16 ? 2'b11 : {aram_addr[0], ~aram_addr[0]};
	end else if (next_port[0] == PORT_NONE &&           // only allow RV access when bank 0,1 are also idle
            (rv_req ^ rv_req_ack)) begin                // RV uses upper 1MB of bank 2
		next_port[1] = PORT_RV;
        if (rv_addr[22:20] == 3'd7)                     // RV access BSRAM
            next_addr[1] = {6'b01_1110, rv_addr[16:1], 1'b0};
        else                                            // normal RV address
		    next_addr[1] = {3'b10_1, rv_addr[19:1], 1'b0};    
		next_we[1] = rv_we;
		next_oe[1] = ~rv_we;
		next_din[1] = rv_din;
		next_ds[1] = rv_ds;
	end
end

// VRAM: bank 3
always @(*) begin
	next_port[2] = PORT_NONE;
	next_addr[2] = 0;
	next_we[2] = 0;
	next_oe[2] = 0;
	next_din[2] = 0;
	next_ds[2] = 0;
	if ((vram1_req ^ vram1_ack) && (vram2_req ^ vram2_ack) && (vram1_addr == vram2_addr) && (vram1_we == vram2_we))
	begin
		// 16 bit VRAM access
		next_port[2] = PORT_VRAM;
		next_addr[2] = { 7'b11_11111, vram1_addr, 1'b0};
		next_we[2] = vram1_we;
		next_oe[2] = ~vram1_we;
		next_din[2] = { vram2_din, vram1_din };
		next_ds[2] = 2'b11;
	end else if (vram1_req ^ vram1_ack) begin
		next_port[2] = PORT_VRAM1;
		next_addr[2] = { 7'b11_11111, vram1_addr, 1'b0};
		next_we[2] = vram1_we;
		next_oe[2] = ~vram1_we;
		next_din[2] = { vram1_din, vram1_din };
		next_ds[2] = 2'b01;
	end else if (vram2_req ^ vram2_ack) begin
		next_port[2] = PORT_VRAM2;
		next_addr[2] = { 7'b11_11111, vram2_addr, 1'b1};
		next_we[2] = vram2_we;
		next_oe[2] = ~vram2_we;
		next_din[2] = { vram2_din, vram2_din };
		next_ds[2] = 2'b10;
	end
end

reg [7:0] bsram_dout_reg;
always @* begin                 // output bsram_dout on the same cycle
    if (cycle[5] && oe_latch[0] && port[0] == PORT_BSRAM)
        case (addr_latch[0][1:0])
        2'b00: bsram_dout = dq_in[7:0];
        2'b01: bsram_dout = dq_in[15:8];
        2'b10: bsram_dout = dq_in[23:16];
        2'b11: bsram_dout = dq_in[31:24]; 
        endcase
    else
        bsram_dout = bsram_dout_reg;
end

//
// SDRAM state machine
//
always @(posedge clk) begin
    if (~resetn) begin
        busy <= 1'b1;
        dq_oen <= 1;
        SDRAM_DQM <= 4'b1111;
        normal <= 0;
        setup <= 0;
    end else begin
        // defaults
        dq_oen <= 1'b1;
        SDRAM_DQM <= 4'b1111;
        cmd <= CMD_NOP; 

        // wait 200 us on power-on
        if (~normal && ~setup && cfg_now) begin // wait 200 us on power-on
            setup <= 1;
            cycle <= 1;
        end 

        // setup process
        if (setup) begin
            cycle <= {cycle[15:0], 1'b0};       // cycle 0-16 for setup
            // configuration sequence
            if (cycle[0]) begin
                // precharge all
                cmd <= CMD_PreCharge;
                a[10] <= 1'b1;
                SDRAM_BA <= 0;
            end
            if (cycle[T_RP]) begin              // 2
                // 1st AutoRefresh
                cmd <= CMD_AutoRefresh;
            end
            if (cycle[T_RP+T_RC]) begin         // 8
                // 2nd AutoRefresh
                cmd <= CMD_AutoRefresh;
            end
            if (cycle[T_RP+T_RC+T_RC]) begin    // 14
                // set register
                cmd <= CMD_SetModeReg;
                a[10:0] <= MODE_REG;
                SDRAM_BA <= 0;
            end
            if (cycle[T_RP+T_RC+T_RC+T_MRD]) begin  // 16
                setup <= 0;
                normal <= 1;
                cycle <= 1;
                busy <= 1'b0;               // init&config is done
            end
        end 
        if (normal) begin
            if (clkref & ~clkref_r)             // go to cycle 3 after clkref posedge
                cycle[7:0] <= 8'b0000_1000;     
            else
                cycle[7:0] <= {cycle[6:0], cycle[7]};
            refresh_cnt <= refresh_cnt + 1'd1;
            
            // RAS
            // bank 0,1 - ROM, WRAM, BSRAM
            if (cycle[0]) begin
    			port[0] <= next_port[0];
	    		{ we_latch[0], oe_latch[0] } <= { next_we[0], next_oe[0] };
    			addr_latch[0] <= next_addr[0];
	    		a <= next_addr[0][20:10];
                SDRAM_BA <= next_addr[0][22:21];
                din_latch[0] <= next_din[0];
                ds[0] <= next_ds[0];
                if (next_port[0] != PORT_NONE) cmd <= CMD_BankActivate;
            end

            // bank 2 - ARAM, RV
            if (cycle[1]) begin
                port[1] <= next_port[1];
                { we_latch[1], oe_latch[1] } <= { next_we[1], next_oe[1] };
                addr_latch[1] <= next_addr[1];
                a <= next_addr[1][20:10];
                SDRAM_BA <= next_addr[1][22:21];
                din_latch[1] <= next_din[1];
                ds[1] <= next_ds[1];
                case (next_port[1])
                PORT_ARAM: begin 
                    cmd <= CMD_BankActivate; 
                    aram_req_ack <= aram_req; 
                end
                PORT_RV: begin
                    cmd <= CMD_BankActivate;
                end
                default: ;
                endcase 
                write_delay <= oe_latch[0] & next_we[1];     // delay aram write when cpu is read
            end

            // bank 3 - VRAM
            if (cycle[4]) begin
                port[2] <= next_port[2];
                { we_latch[2], oe_latch[2] } <= { next_we[2], next_oe[2] };
                addr_latch[2] <= next_addr[2];
                a <= next_addr[2][20:10];
                SDRAM_BA <= 2'b11;
                din_latch[2] <= next_din[2];
                ds[2] <= next_ds[2];
                if (next_port[2] != PORT_NONE) 
                    cmd <= CMD_BankActivate;
            end

            // Refresh
            if (cycle[2] && need_refresh && !(vram1_req^vram1_ack) && !(vram2_req^vram2_ack)    // timing critical for vram1_req and vram2_req
                && !we_latch[0] && !oe_latch[0] && !we_latch[1] && !oe_latch[1]) begin
                // REFRESH if there's no ongoing CPU/ARAM nor upcoming VRAM requests
                refresh <= 1'b1;
                refresh_cnt <= 0;
                cmd <= CMD_AutoRefresh;
                total_refresh <= total_refresh + 1;
            end
            if (cycle[0])           // T_RC=6
                refresh <= 1'b0;

            // CAS
            // ROM, WRAM, BSRAM
            if (cycle[2] && (oe_latch[0] || we_latch[0])) begin
                cmd <= we_latch[0]?CMD_Write:CMD_Read;
                if (we_latch[0]) begin
                    dq_oen <= 0;
                    dq_out <= {din_latch[0], din_latch[0]};
                    SDRAM_DQM <= addr_latch[0][1] ? {~ds[0], 2'b11} : {2'b11, ~ds[0]};
                end else
                    SDRAM_DQM <= 4'b0;
                a <= { 3'b100, addr_latch[0][9:2] };  // auto precharge
                SDRAM_BA <= addr_latch[0][22:21];                
            end
            if (cycle[2]) begin
                case (port[0])
                PORT_CPU:   cpu_req_ack <= cpu_req;
                PORT_BSRAM: bsram_req_ack <= bsram_req;
                default: ;
                endcase
            end

            // ARAM, RV
            if (cycle[3] & ~write_delay | cycle[6] & write_delay) begin
                if (oe_latch[1] || we_latch[1]) begin
                    cmd <= we_latch[1]?CMD_Write:CMD_Read;
                    if (we_latch[1]) begin
                        dq_oen <= 0;
                        dq_out <= {din_latch[1], din_latch[1]};
                        SDRAM_DQM <= addr_latch[1][1] ? {~ds[1], 2'b11} : {2'b11, ~ds[1]};
                    end else
                        SDRAM_DQM <= 4'b0;
                    a <= { 3'b100, addr_latch[1][9:2] };  // auto precharge
                    SDRAM_BA <= addr_latch[1][22:21];
                end
            end
            if (cycle[3] && port[1] == PORT_RV)         // ack RV request on cycle 3
                rv_req_ack <= rv_req;

            // VRAM
            if(cycle[7] && (oe_latch[2] || we_latch[2])) begin
                cmd <= we_latch[2]?CMD_Write:CMD_Read;
                if (we_latch[2]) begin
                    dq_oen <= 0;
                    dq_out <= {din_latch[2], din_latch[2]};
                    SDRAM_DQM <= addr_latch[2][1] ? {~ds[2], 2'b11} : {2'b11, ~ds[2]};
                end else
                    SDRAM_DQM <= 4'b0;
                a <= { 3'b100, addr_latch[2][9:2] };  // auto precharge
                SDRAM_BA <= 2'b11;
            end
            if(cycle[7]) begin
                case (port[2])
                    PORT_VRAM:   { vram1_ack, vram2_ack } <= { vram1_req, vram2_req };
                    PORT_VRAM1:  vram1_ack <= vram1_req;
                    PORT_VRAM2:  vram2_ack <= vram2_req;
                    default: ;
                endcase
            end

            // read
            // ROM, WRAM, BSRAM and RV
            if (cycle[5] && oe_latch[0]) begin
                case (port[0])
                PORT_CPU:   
                    if (cpu_port) 
                        cpu_port1 <= addr_latch[0][1] ? dq_in[31:16] : dq_in[15:0]; 
                    else 
                        cpu_port0 <= addr_latch[0][1] ? dq_in[31:16] : dq_in[15:0];
                PORT_BSRAM: 
                    case ({addr_latch[0][1:0]})
                    2'b00: bsram_dout_reg <= dq_in[7:0];
                    2'b01: bsram_dout_reg <= dq_in[15:8];
                    2'b10: bsram_dout_reg <= dq_in[23:16];
                    2'b11: bsram_dout_reg <= dq_in[31:24]; 
                    endcase
                default: ;
                endcase
            end

            // ARAM & RV
            if (cycle[6] && oe_latch[1]) 
                case (port[1])
                PORT_ARAM: aram_dout <= addr_latch[1][1] ? dq_in[31:16] : dq_in[15:0];
                PORT_RV:    rv_dout <= addr_latch[1][1] ? dq_in[31:16] : dq_in[15:0];
                default: ;
                endcase

            // VRAM
            if (cycle[2] && oe_latch[2]) begin
                case (port[2])
				PORT_VRAM: { vram2_dout, vram1_dout } <= addr_latch[2][1] ? dq_in[31:16] : dq_in[15:0];
				PORT_VRAM1: vram1_dout <= addr_latch[2][1] ? dq_in[23:16] : dq_in[7:0];
				PORT_VRAM2: vram2_dout <= addr_latch[2][1] ? dq_in[31:24] : dq_in[15:8];
                default: ;
                endcase
            end
            if (cycle[2] && we_latch[2]) begin
                case (port[2])
				PORT_VRAM: { vram2_dout, vram1_dout } <= din_latch[2];
				PORT_VRAM1: vram1_dout <= din_latch[2][7:0];
				PORT_VRAM2: vram2_dout <= din_latch[2][7:0];
                default: ;
                endcase
            end
        end
    end
end

//
// Generate cfg_now pulse after initialization delay (normally 200us)
//
localparam CFG_DELAY = FREQ / 1000 * 200 / 1000;
reg  [$clog2(CFG_DELAY)-1:0]   rst_cnt;
reg rst_done, rst_done_r;
  
always @(posedge clk) begin
    if (~resetn) begin
        rst_cnt  <= 0;
        rst_done <= 0;
    end else begin
        rst_done_r <= rst_done;
        cfg_now    <= rst_done & ~rst_done_r;

        if (rst_cnt != CFG_DELAY-1) begin      // count to 200 us
            rst_cnt  <= rst_cnt + 1;
            rst_done <= 1'b0;
        end else 
            rst_done <= 1'b1;
    end
end

endmodule