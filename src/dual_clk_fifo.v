// https://www.cnblogs.com/lyc-seu/p/12439203.html

module dual_clk_fifo #(
    parameter DATESIZE = 8,
    parameter ADDRSIZE = 4,
    parameter ALMOST_GAP = 3
)(
    input clk, wrst_n,
    input [DATESIZE-1:0] wdata,         
    input winc,                         // 1: write data and increment write ptr
    input rclk, rrst_n,
    input rinc,                         // 1: increment read ptr
    output wire [DATESIZE-1:0] rdata,   // valid when rempty == 0
    output reg wfull,
    output reg rempty,
    output reg almost_full,
    output reg almost_empty
);
wire [ADDRSIZE-1:0] waddr, raddr;
reg  [ADDRSIZE:0] wptr, rptr;
wire rempty_val,wfull_val;

//--------------------------------
// RTL Verilog memory model
//--------------------------------
localparam DEPTH = 1<<ADDRSIZE;
reg [DATESIZE-1:0] mem [0:DEPTH-1];
assign rdata = mem[raddr];

always @(posedge clk)
    if (winc && !wfull) 
        mem[waddr] <= wdata;

//--------------------------------
// read-domain to write-domain synchronizer
//--------------------------------
reg [ADDRSIZE:0] wq1_rptr,wq2_rptr;
always @(posedge clk or negedge wrst_n)
    if (!wrst_n) 
        {wq2_rptr,wq1_rptr} <= 0;
    else 
        {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

//--------------------------------
// Write-domain to read-domain synchronizer
//--------------------------------
reg [ADDRSIZE:0] rq1_wptr,rq2_wptr;
always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) 
        {rq2_wptr,rq1_wptr} <= 0;
    else 
        {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

//--------------------------------
//Read pointer & empty generation logic
//--------------------------------
reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgraynext, rbinnext;
// GRAYSTYLE2 pointer
always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) 
        {rbin, rptr} <= 0;
    else 
        {rbin, rptr} <= {rbinnext, rgraynext};

// Memory read-address pointer (okay to use binary to address memory)
assign raddr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (rinc & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

// FIFO empty when the next rptr == synchronized wptr or on reset
assign rempty_val = (rgraynext == rq2_wptr);

always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) 
        rempty <= 1'b1;
    else 
        rempty <= rempty_val ;

//--------------------------------
// Write pointer & full generation logic
//--------------------------------
reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgraynext, wbinnext;

// GRAYSTYLE2 pointer
always @(posedge clk or negedge wrst_n)
if (!wrst_n) {wbin, wptr} <= 0;
else {wbin, wptr} <= {wbinnext, wgraynext};

// Memory write-address pointer (okay to use binary to address memory)
assign waddr = wbin[ADDRSIZE-1:0];
assign wbinnext = wbin + (winc & ~ wfull);
assign wgraynext = (wbinnext>>1) ^ wbinnext;

//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
wire [ADDRSIZE:0] full_flag;
assign full_flag = {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]};
assign wfull_val = (wgraynext==full_flag);

always @(posedge clk or negedge wrst_n)
    if (!wrst_n) 
        wfull <= 1'b0;
    else 
        wfull <= wfull_val;

//--------------------------------
// almost full and empty logic
//--------------------------------
//Gray encoded read and write address decode to bin.
wire [ADDRSIZE:0]rq2_wptr_bin,wq2_rptr_bin;
wire almost_empty_val,almost_full_val;
assign rq2_wptr_bin[ADDRSIZE] = rq2_wptr[ADDRSIZE]; 
assign wq2_rptr_bin[ADDRSIZE] = wq2_rptr[ADDRSIZE];
genvar i;
generate
    for(i=ADDRSIZE-1;i>=0;i=i-1) begin:wpgray2bin          
        assign rq2_wptr_bin[i] = rq2_wptr_bin[i+1]^rq2_wptr[i];
        assign wq2_rptr_bin[i] = wq2_rptr_bin[i+1]^wq2_rptr[i];
    end
endgenerate

//--------------------------------
// read almost empty
//--------------------------------
wire [ADDRSIZE:0] rgap_reg;
assign rgap_reg = rq2_wptr_bin - rbin;
assign almost_empty_val = (rgap_reg <= ALMOST_GAP);

always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) 
        almost_empty <= 1'b1;
    else 
        almost_empty <= almost_empty_val;

//--------------------------------
//write almost full
//--------------------------------
wire [ADDRSIZE:0] wgap_reg;
assign wgap_reg = (wbin[ADDRSIZE] ^ wq2_rptr_bin[ADDRSIZE])? wq2_rptr_bin[ADDRSIZE-1:0] - wbin[ADDRSIZE-1:0]:DEPTH + wq2_rptr_bin - wbin;
assign almost_full_val = (wgap_reg <= ALMOST_GAP);

always @(posedge clk or negedge wrst_n)
    if (!wrst_n) 
        almost_full <= 1'b0;
    else 
        almost_full <= almost_full_val;


endmodule 
