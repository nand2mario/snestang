
# Design notes for SNESTang

nand2mario, 2024

This documents the design of SNESTang for my own reference and others who want to read the code. It also aims to be helpful to people porting other cores to Tang FPGAs. Note that the doc has been updated to cover SNESTang 0.5.

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

There are two main code trees for SNES,
* The original, archived [FpgaSnes](https://github.com/srg320/FpgaSnes) by srg320 (old but simple)
* The active [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by gyurco (new but more complex).

As of SNESTang 0.5, we are now mainly based on the new SNES_FPGA tree. Some code is reused from the previous [NESTang](https://github.com/nand2mario/nestang) project for NES on Tang Primer 25K.

## Clocks

The original SNES has the following clocks,

* "Master clock" at 21.477Mhz for CPU and PPU.
  * CPU instruction takes 6, 8 or 12 cycles.
  * PPU output 1 dot every 4 cycles.
* SMP sound system works off a separate 24.576Mhz clock. 
  * DSP runs on 1/6 of the clock cycles
  * SPC700 runs at 1/24 of the cycles (i.e. 2.048Mhz).

For FPGA implementation, we want as few separate clock domains as possible, because crossing them adds complexity and latency. So clocking works as follows. Latency is important as SNES is faster than NES and we do not have a lot of timing leeway to make the design work.

* `hclk`: HDMI 720p pixel clock at 74.25Mhz
* `mclk`: ~21.5Mhz, for everything other than HDMI or SDRAM, including CPU, PPU, SMP, SD card and etc. 
  * CPU/PPU runs slightly faster than intended for synchronization with HDMI. See below ("SNES video to HDMI") for how we stay in sync.
  * Sound DSP/SMP is enabled with a CE signal at 4.096Mhz. So it runs roughtly once every 5-6 mclk cycles.
* `fclk`: SDRAM clock at ~86Mhz (64.8Mhz for Mega 138K). This is exactly 4x of mclk and generated from the same PLL. So they are related clocks and domain-crossing is easier.

## Timings

Typical timings of the components:

```
wclk     /‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__
phase    | 0  | 1  | 2  | 3  | 4  | 5  | 0  | 1  | 2  | 3  | 4  | 5  | 6  | 7  | 0  | 1  | 2  | 3  | 4  | 5  |
sysclkf  /‾‾‾‾\________________________/‾‾‾‾\__________________________________/‾‾‾‾\_________________________
sysclkr  _______________/‾‾‾‾\________________________/‾‾‾‾\__________________________________/‾‾‾‾\__________
         |---------- 6-cycle ----------|---------------- 8-cycle --------------|  .... 12-cycle ...
ppu      \_________/‾‾dot 1‾‾\_________/‾‾dot 2‾‾\____ ...
 vram_rd /‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾ ...
dsp      \_________/substep0‾\_________/substep1‾\____ ...
 aram_rd /‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾‾‾‾‾‾\_________/‾‾‾‾ ...
```

SNES CPU uses variable clock speeds. Basically a CPU cycle takes 6, 8 or 12 master clock cycles depending on the operation. Cycles with no memory or I/O operation takes 6 master clock cycles. Cycles accessing memory takes 8. Cycles accessing I/O takes 12.

Therefore, actual timing for a CPU cycle would look like this:
  * Phase 0 (marked by `SYSCLKF_CE` in code, "falling sys clk"): P65 computation is executed, and memory read requests issued.
  * Middle phase (marked by `SYSCLKR_CE`, "rising sys clk"): memory write requests are issues.
  * For DMA, there could be at most one read and one write. So the result of the read is used by the write.

PPU and audio DSP work similarly, albeit interleaved memory operations and computation.

## SDRAM controller

This is more complicated than NES because we have more memory components to support. There are the cartridge ROM, catridge BSRAM (battery-back SRAM to hold game saves), WRAM (128KB main work RAM), VRAM (64KB video RAM) and ARAM (64KB audio RAM).

In FPGA, the fastest and most convenient memory is block RAM or BRAM. BRAM usage takes a few lines of code and data accesses uses exactly one cycle. For instance, the MiSTer SNES core places everything except the ROM in BRAM, which makes things much simpler. In contrast, the Tang Primer 25K has 56x18kb blocks, or 126K bytes of BRAM in total. So it is in short supply if we look at what SNES needs. SNESTang places only the VRAM in BRAM. All other memories reside in the SDRAM. The rest half of BRAM are used for processor micro codes, video buffer for HDMI and etc.

We use a triple-channel interleaved SDRAM controller (with CAS latency CL=2) (`sdram_snes.v`). This allows parallel accesses from both the CPU, SMP and PPU, therefore avoiding the need for complex time-multiplexing (which I did spent some time on and abandoned). 

The nice thing about this design is that the SDRAM does not need to run at super-high speed. 85Mhz is significantly lower the speed of MIST-SNES's 128Mhz (which uses a CL3 3-way interleaving controller). In my experiments, I have not found a way to make Tang Primer 25K SDRAM work reliably for 128Mhz yet.

Here is the timings for the SDRAM controller. 
```
fclk  Normal schedule      Delayed write   clkref
      CPU   ARAM  VRAM    CPU   ARAM  VRAM
     ---------------------------------------------
 0    RAS                 RAS                0
 1          RAS   <LZ>                <LZ>   0       
 2    R/W         DATA    READ        DATA   1   
 3          READ                RAS          1
 4    <LZ>        RAS     <LZ>        RAS    1
 5    DATA                DATA               1  
 6          DATA                WRITE        0
 7                R/W                 R/W    0
``` 
For each memory access, RAS is row activation, followed by CAS (column activation and write data), and then DATA for read data available. As can be seen, there are two schedules depending on operations by the CPU and ARAM channels:

* Normal schedule, if the operations are READ-READ, WRITE-READ or WRITE-WRITE.
* "Delayed write", for READ-WRITE operations.

For READ-WRITE operations, this schedule avoids a bus contention on cycle 4. If we were to use the normal scheduel for this, the memory is already driving the data lines (`<LZ>` in the diagram), and at the same time, the host sends data for writing the ARAM (`WRITE`). 

Note that 4 fclk cycles are 1 mclk cycle. So looking from the host side, each memory request takes 2 or 3 mclk cycles to complete, depending how it aligns with the reference clock. Here are two examples,

```
clkref   1    0    1    0    1    0    1    0
cpureq1 REQ  RAS  CAS  DATA                         ; takes 2 cycles
cpureq2                REQ [BUB] RAS  CAS  DATA     ; takes an extra cycle as CPU RAS always happen when clkref=0
```

For the Mega 138K Pro, we use a double-channel SDRAM controller running at 64.8Mhz, and puts the VRAM in FPGA BRAM. It operates similarly. For details, see comments in `sdram_cl2_2ch.v`

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

## SNES video to HDMI

Video upscaling to HDMI is done in `snes2hdmi.v`. It upscale the SNES video by 3. So 256x224 becomes 1024x672, leaving empty columns on the sides and narrow bars on the top and bottom. The final result is OK.

However this works quite differently from `nes2hdmi.v` for NES, mainly because we had to give up the frame buffer. The frame buffer for NES is introduced because the console and HDMI works at different pixel scanning speeds. So things become easier when there is a full frame buffer that hold the whole frame image. 

For SNESTang, however, a frame buffer would take too much space. The RGB5 pixel format takes 15 bits (round up to 2 bytes) to store one pixel. Therefore 256x224 would need 112KB, almost all the BRAM we have. One way would be to store the frame buffer in SDRAM. But given the high pixel clock of HDMI and our already busy SDRAM, implementing a SDRAM-backed frame buffer would be challenging here.

The approach I chose was to let HDMI generate pixels at 74.25Mhz from a multi-line pixel buffer, which was fed by SNES in a mostly-synchronized fashion. It is somewhat similar to the VGA line-doubler used in other FPGA cores that expands 240p to VGA. The scanning speed of 720p is different from the 256x224 video feed of SNES. So they tend to go out of sync over time. But if HDMI and SNES can start each frame at the same time, they would not drift from each other too far away. After some calculation and experimentation, a 16 line buffer turns out to be enough, using 4 BRAM blocks. In order to sync the SNES to HDMI frames, the `pause_snes_for_frame_sync` signal was introduced. We pause the SNES during a "DRAM refresh period" (middle of scanline, marked by the REFRESH signal), where there is no RAM access, and wait for HDMI to catch up.

## I/O Controller (`iosys/`)

The iosys is a RV32I RISC-V soft processor (PicoRV32) that handles input and output related tasks for SNESTang, including file systems, on-screen-display menu, ROM loading into SNES, configuration options, BSRAM backup/restore and etc. The idea is that although we pay the price of using some FPGA area for the soft processor (about 2K LUT), it actually uses less resources than implementing the functionalities with Verilog directly. Moreover the LUT usage does not grow as we add more functionality to the firmware. Compared with using an external MCU for these tasks (the route chosen by MIST), this approach does not require extra hardware and is much easier to set up to the end user.

Iosys loads its firmware from the onboard SPI flash chip, at address 0x500000 (5MB) for 256KB, out of the bitstream range for both Primer 25K and Mega 138K. Right now the firmware is about 70KB in size.

Here are the resource/peripherals available for the iosys. Most are accessible through memory-mapped I/O in firmware.
* **SPI flash**. Firmware loading is done by the `spiflash.v` module at startup.
* **Main memory**. 2MB of memory is available to the RISC-V, with program at the start and stack at the end.
* **Text mode display**. `textdisp.v` provides a 32x28 monochrome text display overlay. MMIO address is 0x2000000. Writing a 32-bit command to this address updates one character on screen: [23:16]: x, [15:8]: y, [7-0]: ASCII of character to print.
* **UART console**. At address 0x2000010. A memory write initiate a byte transmission, while a memory read returns a byte read (blocks waiting while receiving).
* **SPI Master for SD card**. Writing a byte to 0x2000020 will initiate sending and receiving a SPI byte. SPI is master-driven and sending and receiving happens at the same time. A read after the write returns the just-received byte. Another register, 0x2000024, is a faster 32-bit interface. Writing to 0x2000024 sends 4 bytes back to back, and a read after that return the just-received 4 bytes.
* **SNES**. Writing 1 to 0x2000030 starts the SNES rom loading process, while writing 0 finishes it. Data is sent through 0x2000034 in groups of 4 bytes. The first 64 bytes are the SNES header (32 bytes) plus the 32 bytes after the SNES header in the ROM file. Then the actual ROM follows.
* **JOYSTICK**. 0x2000040 is the joystick button states.
* **Time counter**. A 32-bit milli second counter is available at 0x2000050 for the firmware to keep time. It counts from 0 from startup. Right now no wall-clock-time is available.

Iosys currently does not have interrupt enabled, to save area.

For the memory interface and firmware loading implementation of iosys, also refer to the [blog post](https://nand2mario.github.io/posts/softcore_for_fpga_gaming/).

## Iosys Firmware

The firmware is in `firmware/` and can be built with the standard RISC-V toolchain. We currently use the [xpack-gcc](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/). It is very easy to use and building takes one command and 10 seconds.

The following functionality is implemented,

* **File system**. We use the excellent [fatfs](http://elm-chan.org/fsw/ff/) generic FAT library. FAT16/32/exFAT are fully supported, with full read-write functionality.
* **SPI SD access**. Using the MMIO SPI master device, the firmware implements SD accesses through SPI (`spi_sd.c`). The SPI clock speed is 21.5/4=5.1Mhz. In practice, loading a 1MB ROM takes about 8 seconds.
* **OSD and UART printing**. `print*()` prints on the screen. `cursor()` changes where we print next. `uart_print*()`, however, prints to the UART console, mostly for debugging purposes.
* **Configuration options**. First time an option is changed, like "BSRAM backup enable", a `snestang.ini` file is created in the root dir of the SD card to store the options for future reads (The file is set to hidden, so you need to enable viewing hidden files in Windows to see it).
* **ROM loading**. SNES roms come in .sfc and .smc files. They are actually the same format, but parsing them is a bit tricky. There is an optional 512-byte "ROM headers" at the front. And the actual useful 32-byte "SNES header" is embedded inside the ROM at offsets like 0x7FC0 or 0xFFC0. So there are guesses and heuristics at play here, all handled by `parse_snes_header()`. After the SNES header is correctly parsed, it is sent first to the machine so it can set up memory mapping and other settings. Then the actual ROM bits are sent. Once loading is done, `snes_ctrl(0)` starts the machine.
* **BSRAM backup/restore**. Automatic BSRAM backup and restore is implemented. It is off by default and can be enabled in options. All backups are saved in `/saves/<rom_name>.srm` on SD card, in standard `.srm` file format. We exploit the fact that everything shares the same SDRAM chip, to directly map the SNES BSRAM into RISC-V memory space (0x7xxxxx). Additionally, as RV memory access takes lower precedence than SNES, accessing BSRAM from iosys does not cause any conflicts or slowdowns to SNES. It is done siliently in the background, using "idle cycles" of the SDRAM. To balance backup timeliness and number of writes to SD cards, we calculate CRC checksum of BSRAM every 10 seconds, and only writes to SD when BSRAM content changes.

## Acknowledgements

* [SNES Architecture](https://www.copetti.org/writings/consoles/super-nintendo/) by Rodrigo Copetti
* [FpgaSnes](https://github.com/srg320/FpgaSnes) by srg320 
* [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by gyurco
