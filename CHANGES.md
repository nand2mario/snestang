0.4, current
* Cartridge DSP expansion chip is supported. Games like Super Mario Kart are working.
* Fix game freezes due to BSRAM bugs: Super Mario All-Star, Super Metroid, Legend of Zelda - A Link to the Past
* Fix SPC CPU bugs. Now passes all Peter Lemon's CPUTests.
* For developers: VRAM is moved from BRAM to SDRAM bank 3. DSPn uses some of the saved BRAM space. We now provides 3 channels from SDRAM: CPU/softcore, ARAM and VRAM.

0.3, 2/3/2024
* Add iosys, PicoRV32-based riscv softcore for game loading and menu system.
  * See [rv-experiments](https://github.com/nand2mario/rv-experiments/blob/master/CHANGES.md)
* New 3-channel sdram to run softcore (and possibly vram in the future)
* Initial version of firmware in on-board SPI flash
* Menu system supporting directories, with FatFs library
* Fix Donkey Kong Country freeze
* Press Select and Start to switch between OSD and game

0.2, 1/13/2024
* Bug fixes. More games are now playable: Donkey Kong Country, Earthbound, Mortal Kombat II, Donkey Kong Country 2 and more.
* Fix most image glitches from the upscaler.
* SD module area optimization saving ~1000 LUTs.

0.1, 1/6/2024
* First public release
* Basic SNES. No enhancement chips.
* FAT32 rom loading from SD card.
* Menu for choosing roms.