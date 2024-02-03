# SNESTang - SNES for Sipeed Tang Primer 25K FPGA Board

<p align="right">
  <a title="Releases" href="https://github.com/nand2mario/snestang/releases"><img src="https://img.shields.io/github/commits-since/nand2mario/snestang/latest.svg?longCache=true&style=flat-square&logo=git&logoColor=fff"></a>
</p>

<img src="doc/images/snestang0.1.jpg" width=300>

SNESTang is an open source project to recreate the Super Nintendo Entertainment System (SNES) with the tiny Sipeed Tang Primer 25K FPGA board. Similar to its sibling [NESTang](https://github.com/nand2mario/nestang), it support 720p HDMI output, cycle accurate gameplay, ROM loading from MicroSD with an easy-to-use menu system, and playstation 2 controller support.

## Setup Instructions

Detailed [step-by-step instructions](doc/installation.md).

Quick instructions for experienced users:
* Get a Tang Primer 25K with 4 modules: Tang sdram, DVI, Dualshock2, SD and a pair of dualshock controllers. Currently these should cost ~$60 in total. Plug in the modules as shown above. Also make sure the sdram module is in the right direction (The side labeled "this side faces outwards" should face away from the board).
* Download a [SNESTang release](https://github.com/nand2mario/snestang/releases), and program `snestang.fs` to the board with Gowin programmer.
* Since 0.3, a firmware program also needs to be programmed to the board. Program `firmware.bin` to address `0x500000` of the on-board flash. See [this screenshot](doc/images/programmer_firmware.png) for how to do it.
* Put your .sfc or .smc roms on a MicroSD card. Note that 0.2 and earlier version only support FAT32. 0.3 and later supports FAT16, FAT32 and exFAT.
* Connect one or two DualShock2 controllers to the DS2 pmod.
* Insert the MicroSD card, connect an HDMI monitor or TV, and enjoy your games.

The project is still in early stages and some games do not work. Here are a few games that work well for me: Super Mario World, Gradius III, Contra III and MegaMan X. Find more information on the [game compatibility page](https://github.com/nand2mario/snestang/wiki/Game-Compatibility).

## Development

I am developing with Gowin IDE 1.9.9 Pro version. It requires a free license. Just open the project file snestang_primer25k.gprj.

Read the [design notes](doc/design.md) to understand the code or to add features.

You can also simulate the code with [our verilator harness](verilator). `src/test_loader.v` specifies which rom is used by the simulation. Then `make sim` will start a SDL-based graphical simulation.

## Special Thanks

* [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by Sergiy Dvodnenko (srg320) and gyurco. SNESTang is a port of this core for MiSTer and MIST.
* [hdl-util/hdmi](https://github.com/hdl-util/hdmi) by Sameer Puri.

nand2mario (`nand2mario at outlook.com`)

Since 2024.1
