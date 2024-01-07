# SNESTang - SNES for Sipeed Tang Primer 25K FPGA Board

<p align="right">
  <a title="Releases" href="https://github.com/nand2mario/snestang/releases"><img src="https://img.shields.io/github/commits-since/nand2mario/snestang/latest.svg?longCache=true&style=flat-square&logo=git&logoColor=fff"></a>
</p>

<img src="doc/images/snestang0.1.jpg" width=300>

SNESTang is an open source project to recreate the Super Nintendo Entertainment System (SNES) with the tiny Sipeed Tang Primer 25K FPGA board. Similar to its sibling [NESTang](https://github.com/nand2mario/nestang), it support 720p HDMI output, cycle accurate gameplay, ROM loading from MicroSD with an easy-to-use menu system, and playstation 2 controller support.

## Setup Instructions

* Get a Tang Primer 25K with 4 modules: Tang sdram, DVI, Dualshock2, SD and a pair of dualshock controllers. Currently these should cost ~$60 in total. Plug in the modules as follows. Make sure you plug in pmods exactly as shown and the sdram module in the right direction (The side labeled "this side faces outwards" should face away from the board). <br><img src="doc/images/primer25k_setup.jpg" width=400 />.
* Download a [SNESTang release](https://github.com/nand2mario/nestang/releases), and program the board with Gowin programmer.
* Format a MicroSD card in FAT32. Then put the .sfc or .smc roms in the root dir.
  * **64GB/128GB cards**: Windows does not allow FAT32 on cards >32GB, you can use [Parition Assistant](https://www.diskpart.com/free-partition-manager.html) to force it to FAT32 instead of exFAT.
  * The roms may appear out of order. If you want them to show in alpabetical or other specific order, you can use [DriveSort](http://www.anerty.net/software/file/DriveSort/?lang=en).
* Connect one or two DualShock2 controllers to the DS2 pmod.
* Insert the MicroSD card, connect an HDMI monitor or TV, and enjoy your games.

The project is still in early stages and some games do not work. Here are a few games that work for me: Super Mario World, Gradius III, Contra III and MegaMan X. Find more information on the [game compatibility page](https://github.com/nand2mario/snestang/wiki/Game-Compatibility).

## Development

You can build the code with Gowin IDE 1.9.9 Beta-4 Education version. The education version does not require a license. Just open the project file snestang_primer25k.gprj.

You can also simulate the code with [our verilator harness](verilator). `src/test_loader.v` specifies which rom is used by the simulation. Then `make sim` will start a SDL-based graphical simulation.

## Special Thanks

* [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) by Sergiy Dvodnenko (srg320) and gyurco. SNESTang is a port of this core for MiSTer and MIST.
* [hdl-util/hdmi](https://github.com/hdl-util/hdmi) by Sameer Puri.

nand2mario (`nand2mario at outlook.com`)

Since 2024.1
