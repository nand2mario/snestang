
// set_multicycle_path: https://docs.xilinx.com/r/en-US/ug903-vivado-using-constraints/set_multicycle_path-Syntax

create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
create_clock -name fclk -period 11.57 -waveform {0 5.787} [get_nets {fclk}]
create_generated_clock -name wclk -source [get_nets {fclk}] -divide_by 8 [get_nets {wclk}]
create_generated_clock -name smpclk -source [get_nets {fclk}] -divide_by 8 [get_nets {smpclk}]
create_generated_clock -name clk_audio -source [get_nets {wclk}] -divide_by 225 [get_nets {s2h/clk_audio}]

create_clock -name hclk5 -period 2.694 -waveform {0 1.347} [get_nets {hclk5}]
create_generated_clock -name hclk -source [get_nets {hclk5}] -master_clock hclk5 -divide_by 5 [get_nets {hclk}]

// see start of sdram_snes.v for detailed timing of sdram
// sdram to CPU/RV
set_multicycle_path 3 -setup -start -from [get_clocks {fclk}] -to [get_clocks {wclk}]
set_multicycle_path 2 -hold -start -from [get_clocks {fclk}] -to [get_clocks {wclk}]
// sdram to SMP
set_multicycle_path 6 -setup -start -from [get_clocks {fclk}] -to [get_clocks {smpclk}]
set_multicycle_path 5 -hold -start -from [get_clocks {fclk}] -to [get_clocks {smpclk}]

// CPU/RV to sdram
set_multicycle_path 3 -setup -end -from [get_clocks {wclk}] -to [get_clocks {fclk}]
set_multicycle_path 2 -hold -end -from [get_clocks {wclk}] -to [get_clocks {fclk}]
// SMP to sdram
set_multicycle_path 3 -setup -end -from [get_clocks {smpclk}] -to [get_clocks {fclk}]
set_multicycle_path 2 -hold -end -from [get_clocks {smpclk}] -to [get_clocks {fclk}]

// cpu_port/bsram back to sdram, at least 6 fclk cycles (actually longer)
//set_multicycle_path -end -setup -from [get_regs {sdram/cpu_port*}] -to [get_regs {sdram/dq*}] 6
//set_multicycle_path -end -setup -from [get_regs {sdram/bsram*}] -to [get_regs {sdram/dq*}] 6

// false paths
set_false_path -from [get_regs {main/SNES/smp/CPUO*}] -to [get_regs {sdram/dq_out*}]

// https://retroramblings.net/?p=515
// SDRAM pin delays, assuming board delay is 1ns
// SDRAM max and min output delay + board delay (1ns)
// Output Data High Impedance Time = 5ns
// About 0.15ns/in
//create_generated_clock -name fclk_p -source [get_nets {fclk}] -phase 225 [get_ports {sdram_clk}]
//set_input_delay 0.5 -clock fclk_p [get_ports {IO_sdram*}]
//set_input_delay 6 -max -clock fclk_p [get_ports {IO_sdram*}]
//set_input_delay 1 -min -clock fclk_p [get_ports {IO_sdram*}]
// SDRAM pin setup and hold time
// applies to all sdram pins EXCEPT the clock
//set_output_delay 1.5 -max -clock fclk_p [get_ports {O_sdram*}] [get_ports {IO_sdram*}]
//set_output_delay -0.8 -min -clock fclk_p [get_ports {O_sdram*}] [get_ports {IO_sdram*}]

// we are skipping a cycle when reading data from sdram
//set_multicycle_path 2 -setup -end -from [get_clocks {fclk_p}] -to [get_clocks {fclk}]
