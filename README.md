# SNESTang - SNES for Sipeed Tang FPGA Boards

<p align="right">
  <a title="Releases" href="https://github.com/nand2mario/snestang/releases"><img src="https://img.shields.io/github/commits-since/nand2mario/snestang/latest.svg?longCache=true&style=flat-square&logo=git&logoColor=fff"></a>
</p>

<img src="doc/images/snestang.jpg" width=300>

SNESTang is an open source project to recreate the Super Nintendo Entertainment System (SNES) with the affordable Sipeed Tang FPGA boards. Currently Tang Primer 25K, Tang Nano 20K and Tang Mega 138K Pro are supported. 

* 720p HDMI output.
* Cycle accurate gameplay.
* Supports LoROM, HiROM and ExHiROM.
* ROM loading from MicroSD with an easy-to-use menu system.
* Extension chips: DSP-1/2/3/4, S-RTC, OBC-1.
* Automatic BSRAM backup and restore.

Also check out the sibling project, [NESTang](https://github.com/nand2mario/nestang).

If you haven't bought your board yet, Tang Primer 25K is probably the one to get. Tang Nano 20K only runs games smaller than 3.75MB (30Mbits) due to its limited SDRAM size.

Current development focus,

* [SNAC](https://boogermann.github.io/Bible_MiSTer/hardware/io-board/#serial-io) native controller adapter support.
* Core switching between SNESTang and NESTang.

## Setup Instructions

Detailed [step-by-step instructions](doc/installation.md).

Quick instructions for experienced users:
* Tang Primer 25K needs 4 modules: Tang sdram, DVI, Dualshock2, SD and a pair of dualshock controllers. Currently these should cost ~$60 in total. Tang Nano 20K just needs controller adapters. Check [instructions](doc/installation.md) for how to connect the modules / adapters.
* Download a [SNESTang release](https://github.com/nand2mario/snestang/releases), and program `snestang.fs` to the board with Gowin programmer.
* Since 0.3, a firmware program also needs to be programmed to the board. Program `firmware.bin` to address `0x500000` of the on-board flash. See [this screenshot](doc/images/programmer_firmware.png) for how to do it.
* Put your .sfc or .smc roms on a MicroSD card.
* Connect one or two DualShock2 controllers to the DS2 pmod.
* Insert the MicroSD card, connect an HDMI monitor or TV, and enjoy your games.

More information on [game compatibility](https://github.com/nand2mario/snestang/wiki/Game-Compatibility).

## Usage

Basic operations
* .SFC and .SMC roms should be automatically recognized.
* SELECT-RB (right button) to open OSD.

Backup SRAM support
* Many SNES gamepaks include battery-backed SRAM chips to store game saves, for example Super Mario World. Since 0.5, SNESTang supports fully-automatic backup and restore of BSRAM content, with no interruption to the game play.
* The function is by default turned off. To use it, first enable it in options. Then launch a game with BSRAM support. Every 10 seconds, SNESTang will check if there's new BSRAM content, and if yes saves it into `/saves/<rom_name>.srm`. BSRAM is also automatically restored at game launch if the corresponding .srm file exists, and BSRAM function is on.
* [List of games](https://www.dkoldies.com/blog/complete-list-of-snes-games-with-save-batteries/) with save batteries.

## Development

I am developing with Gowin IDE 1.9.9 Pro version. It requires a free license. Just open the project file snestang_primer25k.gprj.

Read the updated [design notes](doc/design.md) to understand the code or to add features.

You can also simulate the code with [our verilator harness](verilator). `src/test_loader.v` specifies which rom is used by the simulation. Then `make sim` will start a SDL-based graphical simulation.

## Special Thanks

* [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by Sergiy Dvodnenko (srg320) and gyurco. SNESTang is a port of this core for MiSTer and MIST.
* [hdl-util/hdmi](https://github.com/hdl-util/hdmi) by Sameer Puri.

nand2mario (`nand2mario at outlook.com`)

Since 2024.1
