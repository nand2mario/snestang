// Simulation model of sdram_snes.v for Verilator

module sdram_sim
(
    input             clkref,       // main reference clock, requests are sampled on its rising edge
    input             resetn,

    // CPU access (ROM and WRAM) uses bank 0 and 1 (total 16MB)
	input      [15:0] cpu_din,
	input             cpu_port,
	output reg [15:0] cpu_port0,    // output register for bank 0
	output reg [15:0] cpu_port1,    // output register for bank 1
	input      [22:1] cpu_addr,     // 16MB memory space
	input             cpu_rd,
	input             cpu_wr,
	input       [1:0] cpu_ds,       // byte enable

    input      [19:0] bsram_addr,
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

    output reg        busy
);

reg [15:0] mem_cpu [4*1024*1024];       // max 8MB
reg [15:0] mem_aram [32*1024];          // 64KB
reg [15:0] mem_bsram[64*1024];           // max 128KB

initial $readmemh("random_4m_words.hex", mem_cpu);

always @(posedge clkref) begin
    if (cpu_wr) begin
        case(cpu_ds)
        2'b00: ;
        2'b10: begin
            mem_cpu[cpu_addr][15:8] <= cpu_din[15:8];
            $display("[%06x] <= %02x", {cpu_addr, 1'b1}, cpu_din[15:8]);
        end
        2'b01: begin
            mem_cpu[cpu_addr][7:0] <= cpu_din[7:0];
            $display("[%06x] <= %02x", {cpu_addr, 1'b0}, cpu_din[7:0]);
        end
        2'b11:
            mem_cpu[cpu_addr] <= cpu_din;
        endcase
    end else if (cpu_rd) begin
        if (cpu_port)
            cpu_port1 <= mem_cpu[cpu_addr]; 
        else
            cpu_port0 <= mem_cpu[cpu_addr]; 
    end
end

always @(posedge clkref) begin
    if (bsram_wr) begin
        if (bsram_addr[0])
            mem_bsram[bsram_addr[16:1]][15:8] <= bsram_din;
        else
            mem_bsram[bsram_addr[16:1]][7:0] <= bsram_din;
    end else if (bsram_rd) begin
        bsram_dout <= bsram_addr[0] ? mem_bsram[bsram_addr[16:1]][15:8] : mem_bsram[bsram_addr[16:1]][7:0]; 
    end
end

always @(posedge clkref) begin
     if (aram_wr) begin
        if (aram_16) 
            mem_aram[aram_addr[15:1]] <= aram_din;
        else if (aram_addr[0]) begin
            mem_aram[aram_addr[15:1]][15:8] <= aram_din[15:8];
            // $display("ARAM[%04x] <= %02x", aram_addr, aram_din[15:8]);
        end else begin
            mem_aram[aram_addr[15:1]][7:0] <= aram_din[7:0];
            // $display("ARAM[%04x] <= %02x", aram_addr, aram_din[7:0]);
        end
     end else if (aram_rd) begin
        if (aram_16)
            aram_dout <= mem_aram[aram_addr[15:1]];
        else if (aram_addr[0])
            aram_dout[15:8] <= mem_aram[aram_addr[15:1]][15:8];
        else
            aram_dout[7:0] <= mem_aram[aram_addr[15:1]][7:0]; 
    end
end

endmodule