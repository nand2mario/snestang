# SNESTang Installation Instructions

This is a step-by-step guide to install SNESTang 0.3 and later versions.

What you need,
* Windows computer
* Sipeed Tang Primer 25K dock.
* Sipeed Tang SDRAM module.
* Sipeed Tang DVI pmod, TF-Card pmod, DS2x2 pmod.
* Dualshock 2 controller
* MicroSD card

<img src="images/components.jpg" width=400>

## 1. Assemble the Tang Primer 25K

The first step is to plug in the modules as follows.

<img src="images/primer25k_setup.jpg" width=400>

## 2. Download SNESTang and Install Gowin IDE

Now download a SNESTang release from [github](https://github.com/nand2mario/snestang/releases). For example, [SNESTang 0.3](https://github.com/nand2mario/snestang/releases/download/v0.3/snestang-0.3.zip). Extract the zip file and you will see the FPGA bitstream `snestang.fs` and SNESTang menu firmware `firmware.bin`.

In order to transfer these files to the board, you need the Gowin IDE from the FPGA manufacturer. It is available for free after registration on their website: https://www.gowinsemi.com/. You can also use the [direct link](http://cdn.gowinsemi.com.cn/Gowin_V1.9.9Beta-4_Education_win.zip) if you do not bother to register. 

Once the Gowin IDE installer finishes downloading, extract, run and install everything, including the "programmer" and device drivers.

<img src="images/install_programmer.png" width=400> <img src="images/install_drivers.png" width=400>

## 3. Install the bitstream (snestang.fs)

Now plug the Tang Primer 25k board to your computer using the USB cable that comes with the board. Then launch the "Gowin Programmer" application.

<img src="images/programmer_init.png" width=400>

Just press SAVE. Then choose "GW5A" in Series.

<img src="images/programmer_series.png" width=400>

Now double click "Bypass" in Operation. In the window that pops up, choose "External Flash Mode 5AT" for Access Mode, "exFlash Erase, Program 5AT" for Operation, and your `snestang.fs` file for File Name. Then press "Save" to dispose of the window.

<img src="images/programmer_flash.png" width=300>

Now press the button with a play icon on the toolbar to actually start the transfer.

<img src="images/programmer_doit.png" width=400>

It will take about 30 seconds. Now the FPGA bitstream is ready.

## 4. Install the firmware (firmware.bin)

The final step is to transfer the firmware to the board. The firmware is also stored in the on-board SPI flash chip, albeit at a different address than the bitstream. So we also use the Gowin programmer for that. Double click "exFlash Erase, Program 5AT" in the Operation field. In the popup window, press the "..." beside the filename to choose the SNESTang "firmware.bin". In the pop-up, you probably need to change the file type filter to `*.*` to be able to choose the `.bin` file. Then set Start Address to `0x500000`, which is the address for the firmware. Then press "Save" to close the window.

<img src="images/programmer_firmware.png" width=300>

Now press the button with a play icon on the toolbar again to start the transfer.

<img src="images/programmer_doit.png" width=400>

**That is all!** SNESTang installation is now finished.

## Finished

Plug in the controller, HDMI cable and a SD card loaded with ROM files. FAT16, FAT32 or exFAT file systems are supported. Connect the USB cable. You should see this main screen on your monitor/tv, from where you can load your games.

<img src="images/mainscreen.jpg" width=400>

When a game is running, press SELECT-RB (right button) to call out the menu again and load other games.

Happy SNESing!

