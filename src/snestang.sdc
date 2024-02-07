
// set_multicycle_path: https://docs.xilinx.com/r/en-US/ug903-vivado-using-constraints/set_multicycle_path-Syntax

create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
create_clock -name fclk -period 11.57 -waveform {0 5.787} [get_nets {fclk}]
create_generated_clock -name wclk -source [get_nets {fclk}] -divide_by 8 [get_nets {wclk}]
create_generated_clock -name clk_audio -source [get_nets {wclk}] -divide_by 225 [get_nets {s2h/clk_audio}]

create_clock -name hclk5 -period 2.694 -waveform {0 1.347} [get_nets {hclk5}]
create_generated_clock -name hclk -source [get_nets {hclk5}] -master_clock hclk5 -divide_by 5 [get_nets {hclk}]

// see start of sdram_snes.v for detailed timing of sdram
// sdram to SNES
set_multicycle_path 3 -setup -start -from [get_clocks {fclk}] -to [get_clocks {wclk}]
set_multicycle_path 2 -hold -start -from [get_clocks {fclk}] -to [get_clocks {wclk}]

// SNES to sdram
set_multicycle_path 3 -setup -end -from [get_clocks {wclk}] -to [get_clocks {fclk}]
set_multicycle_path 2 -hold -end -from [get_clocks {wclk}] -to [get_clocks {fclk}]

// Last constraint takes precedence: PPU to sdram is even longer at 6 fclk cycles
set_multicycle_path 6 -setup -end -from [get_nets {main/SNES/PPU/BG*}] -to [get_clocks {fclk}]
set_multicycle_path 5 -hold -end -from [get_nets {main/SNES/PPU/BG*}] -to [get_clocks {fclk}]

// false paths
set_false_path -from [get_regs {main/SNES/smp/CPUO*}] -to [get_regs {sdram/dq_out*}]

