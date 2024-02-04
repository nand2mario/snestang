
# Design notes for SNESTang

nand2mario, Jan 2024

This documents the design of SNESTang for my own reference and others who want to read the code. It also aims to be helpful to people porting other cores to Tang FPGAs.

## The SNES architecture

```
        +-------+                +------+  +------+
        | WRAM  |                | SPPU |..| VRAM |
        | 128KB |   +========+   |      |  |2x32KB|
        +-------+...|  SCPU  |...+------+  +------+
                    | w/ DMA |   
    +-----------+...+========+...+------+  +------+  +------+
    | Cartridge |       |        | SSMP |..| DSP  |..| ARAM |
    |  Rom 16MB |       |        |SPC700|  |      |  | 64KB |
    | Sram/chip |   +--------+   +------+  +------+  +------+
    +-----------+   | ^  Joy |
                    |< > O O |
                    | v   2x |
                    +--------+
```

Several things are worth pointing out,
* The 16-bit CPU runs the main game program. The cartridge ROM, cartridge SRAM and WRAM (work RAM) live in the same 24-bit address space (max 16MB). The CPU reads or writes at most one word of this memory space per cycle for normal operations, or up to 2 words (one read and one write) when doing DMA.
* The PPU graphics processor operates stand-alone, with no access to the CPU address space. The CPU can access VRAM through memory-mapped registers or DMA, but not the other way around.
* The SMP/APU audio processor also operates independently from the CPU, with its own memory (64KB of ARAM). The audio DSP does not run code. It is driven by voice tables in ARAM written by the APU.

This architecture is both inherited and different from NES. For example in NES, the PPU accesses the same memory as the CPU. So it has direct access to the cartridge and RAM while here it does not. The benefit on the other hand is more memory bandwidth for the PPU. The APU is not Nintendo developed, but sourced from SONY. So it not only has its own memory, but also operates at a different clock speed. For a detailed description of the SNES architecture, refer to [SNES Architecture](https://www.copetti.org/writings/consoles/super-nintendo/) by Rodrigo Copetti.

## Original code bases

We are mainly porting from two code bases,
* The original, archived [FpgaSnes](https://github.com/srg320/FpgaSnes) by srg320 (old but simple)
* The active [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by gyurco (new but more complex).

Some code is reused from the previous [NESTang](https://github.com/nand2mario/nestang) project for NES on Tang Primer 25K.

## Clocks

The original SNES has the following clocks,

* "Master clock" at 21.477Mhz for CPU and PPU.
  * CPU instruction takes 6, 8 or 12 cycles.
  * PPU output 1 dot every 4 cycles.
* SMP sound system works off a separate 24.576Mhz clock. 
  * DSP runs on 1/6 of the clock cycles
  * SPC700 runs at 1/24 of the cycles (i.e. 2.048Mhz).

In SNESTang we map the clocks to FPGA in the following way. It may look a bit convoluted. But the goal is to have as few separate clock domains as possible, because crossing them adds complexity and latency. Latency is important as SNES is faster than NES and we do not have a lot of timing leeway to make the design work.

* `hclk`: HDMI 720p pixel clock at 74.25Mhz
* `wclk`: Main "work clock" at 10.8Mhz for everything other than HDMI or SDRAM, including CPU, PPU, SMP, SD card and etc. This is half of SNES master clock speed so CPU instruction takes 3, 4 or 6 wclk cycles. 
  * CPU/PPU runs slightly faster (10.8 > 21.477/2). See below ("SNES video to HDMI") for how we stay in sync.
  * Sound also runs faster than original SNES. See below ("SNES audio to HDMI") for how audio is synchronized.
* `fclk`: SDRAM clock at 64.8Mhz. This is exactly 6x of wclk and generated from the same PLL. So they are related clocks and domain-crossing is easier.
  * It takes 5 cycles to access SDRAM. So 6x wclk makes SDRAM able to finish access in one wclk cycle, making the CPU/PPU logic simpler.

The original design in FpgaSnes uses signals like INT_CLK, DOT_CLK as clocks (ripple clocks), which are not good style and confuses Verilator. So we switch to a phase-based design similar to NESTang. This is similar to but slightly different from SNES_FPGA by gyurco.

## Timings

Typical timings of the components:

```
wclk     /‾1‾‾\____/‾2‾‾\____/‾3‾‾\____/‾4‾‾\____/‾5‾‾\____/‾6‾‾\____/‾7‾‾\____/‾8‾‾\____/‾9‾‾\____/‾10‾\____
phase    |    0    |    1    |    2    |    0    |    1    |    2    |    3    |    0    |    1    |    2    |
cpu      /‾‾‾‾‾‾‾‾‾\___________________/‾‾‾‾‾‾‾‾‾\_____________________________/‾‾‾‾‾‾‾‾‾\____________________
         |---------- 6-cycle ----------|---------------- 8-cycle --------------|  .... 12-cycle ...
 mem_rd  ____________________/‾‾‾‾‾‾‾‾‾\___________________/‾‾‾‾‾‾‾‾‾\_____________________________/‾‾‾‾‾‾‾‾‾\
 mem_wr  /‾‾‾‾‾‾‾‾‾\___________________/‾‾‾‾‾‾‾‾‾\_____________________________/‾‾‾‾‾‾‾‾‾\____________________
ppu      \_________/‾‾dot 1‾‾\_________/‾‾dot 2‾‾\____ ...
 vram_rd /‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾ ...
dsp      \_________/substep0‾\_________/substep1‾\____ ...
 aram_rd /‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾ ...
```

SNES CPU uses variable clock speeds. Basically a CPU cycle takes 6, 8 or 12 master clock cycles depending on the operation. Cycles with no memory or I/O operation takes 6 master clock cycles (i.e. 3 wclk "phases" as our wclk is twice the speed of SNES master clock). Cycles accessing memory takes 8. Cycles accessing I/O takes 12.

Therefore, actual timing for a CPU cycle would look like this:
  * (`cpu` line in the diagram) Phase 0 (marked by `SYSCLKF_CE` in code, "falling sys clk"): P65 computation is executed. 
  * (`mem_rd` line) Middle phase (marked by `SYSCLKR_CE`, "rising sys clk"): memory read operations. The read result may be needed by the next CPU cycle.
  * (`mem_wr` line) Memory writes are done in the next cpu cycle's phase 0. This overlaps safely with next CPU cycle because writes does not affect next cycle.
  * For DMA, there could be at most one read and one write. So the result of the read is used by the write in the next CPU cycle.

PPU and audio DSP work similarly, albeit with memory operations in phase 0 and computation in phase 1.

## SDRAM controller

This is more complicated than NES because we have more memory components to support. There are the cartridge ROM, catridge BSRAM (battery-back SRAM to hold game saves), WRAM (128KB main work RAM), VRAM (64KB video RAM) and ARAM (64KB audio RAM).

In FPGA, the fastest and most convenient memory is block RAM or BRAM. BRAM usage takes a few lines of code and data accesses take exactly one cycle. For instance, the MiSTer SNES core places everything except the ROM in BRAM, which makes things much simpler. In contrast, the Tang Primer 25K has 56x18kb blocks, or 126K bytes of BRAM in total. So it is in short supply if we look at what SNES needs. SNESTang places only the VRAM in BRAM. All other memories reside in the SDRAM. The rest half of BRAM are used for processor micro codes, video buffer for HDMI and etc.

We use a dual-bank interleaved SDRAM controller (with CAS latency CL=2): `sdram_snes.v`. This allows parallel accesses from both the CPU and SMP, therefore avoiding the need for complex time-multiplexing (which I did spent some time on and abandoned). 

The nice thing about this design is that the SDRAM does not need to run at super-high speed. 64.8Mhz is half the speed of MIST-SNES's 128Mhz (which uses a CL3 3-way interleaving controller). In my experiments, I have not found a way to make Tang Primer 25K SDRAM work reliably for 128Mhz yet.

Here is the timings for the SDRAM controller. Remember 6 fclk cycles are 1 wclk cycle.
```
fclk_#    CPU         ARAM
   0          
   1      RAS1        DATA2
   2      CAS1
   3                  RAS2/Refresh
   4      DATA1
   5                  CAS2
```
For each memory access, RAS is row activation, followed by CAS (column activation and write data), and then DATA for read data available. So you can see that the CPU channel is designed to operate within one wclk cycle. The ARAM channel crosses two wclk cycles. Note that RAS and CAS are shown when they are registered on the memory side. Because the memory operate in CL2 (CAS latency 2) mode, exactly two cycles after CAS1, we have read data ready (DATA1).

## Memory Layout

SNES memory layout roughly looks likes this,

```
     00-1F 20-3F 40-5F 60-7D 7E-7F 80-9F A0-BF C0-DF E0-FF
0000 -----------------------------------------------------
     |   RAM    |           |     |    RAM    |          |
2000 |----------|           |     |-----------|          |
     |   I/O    |           |     |    I/O    |          |
     |          |    ROM    | RAM |           |   ROM    |
8000 |----------|           |     |-----------|          |
     |          |           |     |           |          |
     |   ROM    |           |     |    ROM    |          |
     |          |           |     |           |          |
ffff -----------------------------------------------------
```

Details of the memory map are determined by the `map_ctrl`, `rom_size` and `ram_size` in the SNES header. See code for details.

## DMA

`cpu.v` contains mainly DMA-related code. The actually 65C816 processor is in `P65C816.v`. The DMA controller is a Nintendo design and technically outside of the CPU. When DMA is active, the 65C816 is simply paused. Every DMA cycle is 4 wclks (8 master cycles). It always transfers one byte from Bus A (CA) to Bus B (PA), or vice versa.  Actual operations are controlled by the DMA registers like DMAEN, BBAD and etc. With these registers, we can do ROM-VRAM DMA, ROM-WRAM DMA, WRAM-CGRAM DMA and etc. It is very flexible, as long as it is between Bus A and B. 

DMA is implemented with the following timings. This example shows WRAM to WRAM DMA, the most complicated situation.

```
wclk          / 0 \___/ 1 \___/ 2 \___/ 3 \___/
SYSCLKF_CE    /       \_______________________/       
SYSCLKR_CE    ________________/       \________
DMA           |NxtAddr|
SDRAM         |MEM<=MDR|      |DI<=MEM|       
MDR           |MDR<=DI|
```

## SNES video to HDMI

Video upscaling to HDMI is done in `snes2hdmi.v`. It upscale the SNES video by 3. So 256x224 becomes 1024x672, leaving empty columns on the sides and narrow bars on the top and bottom. The final result is OK.

However this works quite differently from `nes2hdmi.v` for NES, mainly because we had to give up the frame buffer. The frame buffer for NES is introduced because the console and HDMI works at different pixel scanning speeds. So things become easier when there is a full frame buffer that hold the whole frame image. 

For SNESTang, however, a frame buffer would take too much space. The RGB5 pixel format takes 15 bits (round up to 2 bytes) to store one pixel. Therefore 256x224 would need 112KB, almost all the BRAM we have. One way would be to store the frame buffer in SDRAM. But given the high pixel clock of HDMI and our already busy SDRAM, implementing a SDRAM-backed frame buffer would be challenging here.

The approach I chose was to let HDMI generate pixels at 71.25Mhz from a multi-line pixel buffer, which was fed by SNES in a mostly-synchronized fashion. It is somewhat similar to the VGA line-doubler used in other FPGA cores that expands 240p to VGA. The scanning speed of 720p is different from the 256x224 video feed of SNES. So they tend to go out of sync over time. But if HDMI and SNES can start each frame at the same time, they would not drift from each other too far away. After some calculation and experimentation, a 16 line buffer turns out to be enough, using 4 BRAM blocks. In order to sync the SNES to HDMI frames, the `pause_snes_for_frame_sync` signal was introduced. We pause the SNES during the first "DRAM refresh period" (middle of scanline, marked by the REFRESH signal), where there is no RAM access, and wait for HDMI to catch up.

## SMP audio to HDMI

Audio generated by the SMP is streamed through the `AUDIO_L[15:0]`, `AUDIO_R[15:0]` signals of `main.v`. The sound should be 32K samples per second. As we discussed above, in order to simplify clocking and allow the SMP to use SDRAM directly without clock domain crossing, SMP is also run with wclk. The original `dsp.v` runs at 4.096Mhz and now becomes 10.8/2=5.4Mhz, 32% faster. The 32K sample rate is thus maintained by introducing an `AUDIO_EN` input signal to `main.v`. When the HDMI audio input FIFO is full, `AUDIO_EN` becomes 0, temporarily stopping sound generation. When there is empty space in the FIFO, it becomes 1 again, resuming sound.

## Acknowledgements

* [SNES Architecture](https://www.copetti.org/writings/consoles/super-nintendo/) by Rodrigo Copetti
* [FpgaSnes](https://github.com/srg320/FpgaSnes) by srg320 
* [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by gyurco
