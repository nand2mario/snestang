
// Simple firmware for socdemo
// nand2mario, 1/2024
//
// Need xpack-gcc risc-v gcc: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/
// Use build.bat to build. Then burn firmware.bin to NOR flash address 0x100000 with Gowin programmer.

#include "picorv32.h"
#include "fatfs/ff.h"

void cmd_print_root() {
	DIR d;
	if (f_opendir(&d, "/") != 0) {
		printf("Open root dir failure\n");
		goto print_root_end;
	}
	
	FILINFO fno;
	int cnt = 0;
	while (f_readdir(&d, &fno) == FR_OK) {
		if (fno.fname[0] == 0)
			break;
		if (fno.fattrib & AM_DIR) {
			printf("%s/\n", fno.fname);
		} else {
			printf("%s %d\n", fno.fname, fno.fsize);
		}
		cnt++;
	}
	printf("Total %d entries.\n", cnt);
	f_closedir(&d);

print_root_end:
	return;
}

#define FILENAME "ActRaiser.smc"

void cmd_read_test() {
	FIL f;
	if (f_open(&f, FILENAME, FA_READ) != FR_OK) {
		printf("Cannot open %s\n", FILENAME);
		goto read_test_end;
	}

	uint8_t buf[1024];
	int total, c;
	while (f_read(&f, buf, 1024, &c) == FR_OK) {
		total += c;
		// if (total % (64*1024) == 0)
			print(".");
		if (c < 1024) break;		// EOF
	}
	printf("\nTotal %d bytes read\n", total);

	f_close(&f);

read_test_end:
	return;
}

void status(char *msg) {
	cursor(0, 27);
	for (int i = 0; i < 32; i++)
		putchar(' ');
	cursor(2, 27);
	print(msg);
}

FATFS fs;

#define PAGESIZE 22
#define TOPLINE 2
#define PWD_SIZE 1024

char pwd[PWD_SIZE];		// total path length 1023
// one page of file names to display
char file_names[PAGESIZE][256];
int file_dir[PAGESIZE];
int file_sizes[PAGESIZE];
int file_len;		// number of files on this page

// starting from `start`, load `len` file names into file_names, 
// file_dir. 
// *count is set to number of all valid entries and `file_len` is
// set to valid entries on this page.
// return: 0 if successful
int load_dir(char *dir, int start, int len, int *count) {
	int cnt = 0;
	int r = 0;
	DIR d;
	file_len = 0;
	// initiaze sd again to be sure
	if (sd_init() != 0) return 99;

	if (f_opendir(&d, dir) != 0) {
		return -1;
	}
	// an entry to return to parent dir or main menu 
	int is_root = dir[1] == '\0';
	if (start == 0 && len > 0) {
		if (is_root) {
			strncpy(file_names[0], "<< Return to main menu", 256);
			file_dir[0] = 0;
		} else {
			strncpy(file_names[0], "..", 256);
			file_dir[0] = 1;
		}
		file_len++;
	}
	cnt++;

	// generate all file entries
	FILINFO fno;
	while (f_readdir(&d, &fno) == FR_OK) {
		if (fno.fname[0] == 0)
			break;
		if ((fno.fattrib & AM_HID) || (fno.fattrib & AM_SYS))
 			// skip hidden and system files
			continue;
		if (cnt >= start && file_len < len) {
			strncpy(file_names[file_len], fno.fname, 256);
			file_dir[file_len] = fno.fattrib & AM_DIR;
			file_sizes[file_len] = fno.fsize;
			file_len++;
		}
		cnt++;
	}
	f_closedir(&d);
	*count = cnt;
	return 0;
}

// return 0: user chose a ROM (*choice), 1: no choice made, -1: error
// file chosen: pwd / file_name[*choice]
int menu_loadrom(int *choice) {
	int page = 0, pages, total;
	int active = 0;
	pwd[0] = '/';
	pwd[1] = '\0';
	while (1) {
		clear();
		int r = load_dir(pwd, page*PAGESIZE, PAGESIZE, &total);
		if (r == 0) {
			pages = (total+PAGESIZE-1) / PAGESIZE;
			status("Page ");
			printf("%d/%d", page+1, pages);
			if (active > file_len-1)
				active = file_len-1;
			for (int i = 0; i < PAGESIZE; i++) {
				int idx = page*PAGESIZE + i;
				cursor(2, i+TOPLINE);
				if (idx < total) {
					print(file_names[i]);
					if (file_dir[i])
						print("/");
				}
			}
			while (1) {
				int r = joy_choice(TOPLINE, file_len, &active);
				if (r == 1) {
					if (strcmp(pwd, "/") && page == 0 && active == 0) {
						// return to main menu
						return 1;
					} else if (file_dir[active]) {
						if (file_names[active][0] == '.' && file_names[active][1] == '.') {
							// return to parent dir
							char *slash = strrchr(pwd, '/');
							if (slash)
								*slash = '\0';
						} else {								// enter sub dir
							strncat(pwd, "/", PWD_SIZE);
							strncat(pwd, file_names[active], PWD_SIZE);
						}
						active = 0;
						page = 0;
						break;
					} else {
						// actually load a ROM
						*choice = active;
						return 0;
					}
				}
				if (r == 2 && page < pages-1) {
					page++;
					break;
				} else if (r == 3 && page > 0) {
					page--;
					break;
				}
			}
		} else {
			status("Error opening director");
			printf(" %d", r);
			return -1;
		}
	}
}

void menu_options() {
	clear();
	cursor(2, 10);
    print("--- Options ---");

	cursor(2, 12);
	print("Return to main menu");
	delay(100);

	int choice = 0;
	for (;;) {
		if (joy_choice(12, 1, &choice) == 1)
			break;
	}
}

int in_game;

// return 0 if snes header is successfully parsed at off
// typ 0: LoROM, 1: HiROM, 2: ExHiROM
int parse_snes_header(FIL *fp, int pos, int file_size, int typ, int *map_ctrl, int *rom_size, int *ram_size) {
	int br;
	int mc, rom, ram;
	if (f_lseek(fp, pos))
		return 1;
	uint8_t hdr[32];
	f_read(fp, hdr, 32, &br);
	if (br != 32) return 1;
	mc = hdr[21];
	rom = hdr[23];
	ram = hdr[24];
	int size2 = 1024 << rom;
	status("");
	printf("size=%d", size2);
	// a lot of test ROMS have rom_size = 1...
	if (rom < 14 && ram <= 7 && (size2 >= file_size || rom == 1) && (
		(typ == 0 && (mc & 3) == 0) || 	// normal LoROM
		(typ == 0 && mc == 0x53)    ||	// contra 3 has 0x53 and LoROM
		(typ == 1 && (mc & 3) == 1) ||	// HiROM
		(typ == 2 && (mc & 3) == 2))) {	// ExHiROM
		*map_ctrl = mc;
		*rom_size = rom;
		*ram_size = ram;
		return 0;
	}
	return 1;
}

// actually load a rom file
// return 0 if successful
int loadrom(int rom) {
	FIL f;
	char fname[1024];
	char buf[1024];
	strncpy(fname, pwd, 1024);
	strncat(fname, "/", 1024);
	strncat(fname, file_names[rom], 1024);

	// initiaze sd again to be sure
	if (sd_init() != 0) return 99;

	int r = f_open(&f, fname, FA_READ);
	if (r) {
		status("Cannot open file");
		goto loadrom_end;
	}
	int br, total = 0;
	int size = file_sizes[rom];
	int map_ctrl, rom_size, ram_size;
	// parse SNES header from ROM file
	int off = size & 0x3ff;		// rom header (0 or 512)
	r = parse_snes_header(&f, 0x7fc0 + off, size-off, 0, &map_ctrl, &rom_size, &ram_size) &&
		parse_snes_header(&f, 0xffc0 + off, size-off, 1, &map_ctrl, &rom_size, &ram_size) &&
		parse_snes_header(&f, 0x40ffc0 + off, size-off, 2, &map_ctrl, &rom_size, &ram_size);
	if (r) {
		status("Not a SNES ROM file");
		delay(200);
		goto loadrom_close_file;
	}

	// load actual ROM
	snes_ctrl(1);
	// 3-word header
	snes_data(map_ctrl | (rom_size << 8) | (ram_size << 16));
	snes_data((1024 << (rom_size < 7 ? 12 : rom_size)) - 1);
	snes_data(ram_size ? (1024 << ram_size) - 1 : 0);

	if ((r = f_lseek(&f, off)) != FR_OK) {
		status("Seek failure");
		goto loadrom_snes_end;
	}
	do {
		if ((r = f_read(&f, buf, 1024, &br)) != FR_OK)
			break;
		for (int i = 0; i < br; i += 4) {
			uint32_t *w = (uint32_t *)(buf + i);
			snes_data(*w);				// send actual ROM data
		}
		total += br;
		if ((total & 0xffff) == 0) {	// display progress every 64KB
			status("");
			printf("%d/%dK", total >> 10, size >> 10);
			if ((map_ctrl & 3) == 0)
				print(" Lo");
			else if ((map_ctrl & 3) == 1)
				print(" Hi");
			else if ((map_ctrl & 3) == 2)
				print(" ExHi");
			printf(" ROM=%d RAM=%d", 1 << rom_size, ram_size ? (1 << ram_size) : 0);
		}
	} while (br == 1024);
	status("Done");

loadrom_snes_end:
	snes_ctrl(0);
loadrom_close_file:
	f_close(&f);
loadrom_end:
	return r;
}

int main() {
	uint8_t a, b, c, d;
	a = 1; b = 2; c = 3; d = 4;
	reg_uart_clkdiv = 94;       // 10800000 / 115200

	for (;;) {
		// main menu
		clear();
		cursor(2, 10);
		//     01234567890123456789012345678901
		print("~~~ Welcome to SNESTang ~~~");
		cursor(2, 12);
		print("1) Load ROM from SD card\n");
		cursor(2, 13);
		print("2) Options\n");
		cursor(2, 15);
		print("Version: ");
		print(__DATE__);

		// cursor(2, 27);
		// print("Init SD card... ");
		f_mount(&fs, "", 0);
		// print("done");

		delay(100);

		int choice = 0;
		for (;;) {
			int r = joy_choice(12, 2, &choice);
			if (r == 1) break;
		}

		if (choice == 0) {
			int rom;
			int r = menu_loadrom(&rom);
			if (r == 0) {
				if (loadrom(rom) == 0) {
					overlay(0);		// turn off OSD
					in_game = 1;
				}
			}
		} else if (choice == 1) {
			menu_options();
			continue;
		}
	}
}