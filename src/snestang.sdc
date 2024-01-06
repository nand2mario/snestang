//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.11 Education
//Created Time: 2023-06-23 16:56:38
create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
create_clock -name fclk -period 15.43 -waveform {0 7.715} [get_nets {fclk}]
//create_generated_clock -name fclk_p -source [get_nets {fclk}] -master_clock fclk -phase 180 [get_nets {fclk_p}]
create_generated_clock -name wclk -source [get_nets {fclk}] -master_clock fclk -divide_by 6 [get_nets {wclk}]
create_generated_clock -name smpclk -source [get_nets {fclk}] -master_clock fclk -divide_by 6 [get_nets {smpclk}]

create_clock -name hclk5 -period 2.694 -waveform {0 1.347} [get_nets {hclk5}]
create_generated_clock -name hclk -source [get_nets {hclk5}] -master_clock hclk5 -divide_by 5 [get_nets {hclk}]

// see start of sdram_snes.v for detailed timing of sdram
// relax CPU to sdram paths to 6 fclk cycles
// set_multicycle_path -end -setup -from [get_clocks {wclk}] -to [get_clocks {fclk}] 6
// relax SMP to sdram paths to 3 fclk cycle
set_multicycle_path -end -setup -from [get_clocks {smpclk}] -to [get_clocks {fclk}] 3

// set sdram to CPU to 6 fclk cycle
set_multicycle_path -start -setup -from [get_clocks {fclk}] -to [get_clocks {wclk}] 6
// set sdram to SMP to 5 fclk cycle
set_multicycle_path -start -setup -from [get_clocks {fclk}] -to [get_clocks {smpclk}] 4

// cpu_port/bsram back to sdram, at least 6 fclk cycles (actually longer)
set_multicycle_path -end -setup -from [get_regs {sdram/cpu_port*}] -to [get_regs {sdram/dq*}] 6
//set_multicycle_path -end -setup -from [get_regs {sdram/bsram*}] -to [get_regs {sdram/dq*}] 6

// false paths
set_false_path -from [get_regs {main/SNES/smp/CPUO*}] -to [get_regs {sdram/dq_out*}]