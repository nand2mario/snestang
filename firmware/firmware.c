
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

// one page of file names to display
char file_names[20][256];
int file_dir[20];
int file_len;		// number of files

// load one page of file names into file_names
// *count is set to number of total entries to display
// return: 0 if successful
int load_dir(char *dir, int start, int len, int *count) {
	int cnt = 0, idx = 0;
	int r = 0;
	DIR d;
	if (f_opendir(&d, dir) != 0) {
		r = -1;
		goto load_dir_end;
	}
	// generate `..` to return to parent dir
	int is_root = dir[1] == '\0';
	if (start == 0 && len > 0) {
		strncpy(file_names[0], is_root ? ".. <main menu> .." : "..", 256);
		file_dir[0] = 1;
		idx++;
	}
	cnt++;

	// generate all file entries
	FILINFO fno;
	while (f_readdir(&d, &fno) == FR_OK) {
		if (fno.fname[0] == 0)
			break;
		if (cnt >= start && idx < len) {
			strncpy(file_names[idx], fno.fname, 256);
			file_dir[idx] = fno.fattrib & AM_DIR;
			idx++;
		}
		cnt++;
	}
	f_closedir(&d);
	*count = cnt;

load_dir_end:
	return r;
}

#define PWD_SIZE 1024
char pwd[PWD_SIZE];		// total path length 1023

// return 0: user chose a ROM (*choice), 1: no choice made, -1: error
// file chosen: pwd / file_name[*choice]
int menu_loadrom(int *choice) {
	int page = 0, pages, total;
	int active = 0;
	pwd[0] = '/';
	pwd[1] = '\0';
	while (1) {
		clear();
		if (load_dir(pwd, page*20, 20, &total) == 0) {
			pages = (total + 19) / 20;
			status("Page ");
			printf("%d / %d", page, pages);
			if (active > file_len-1)
				active = file_len-1;
			while (1) {
				int r = joy_choice(0, file_len, &active);
				if (r == 1) {
					if (file_dir[active]) {
						if (file_names[active][0] == '.' && file_names[active][1] == '.') {
							if (strcmp(pwd, "/")) {
								// return to main menu
								return 1;
							} else {
								// return to parent dir
								char *slash = strrchr(pwd, '/');
								if (slash)
									*slash = '\0';
							}							
						} else {								// enter sub dir
							strncat(pwd, "/", PWD_SIZE);
							strncat(pwd, file_names[active], PWD_SIZE);
						}
						active = 0;
						page = 0;
						break;
					} else {
						*choice = active;
						status("ROM: ");
						print(file_names[active]);
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

	int choice = 0;
	for (;;) {
		if (joy_choice(12, 1, &choice) == 1)
			break;
	}
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

		cursor(2, 27);
		print("Init SD card... ");
		f_mount(&fs, "", 0);
		print("done");

		int choice = 0;
		for (;;) {
			int r = joy_choice(12, 2, &choice);
			if (r == 1) break;
		}

		if (choice == 0) {
			int rom;
			menu_loadrom(&rom);
		} else if (choice == 1) {
			menu_options();
		}
	}
}