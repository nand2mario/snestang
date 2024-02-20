
// Simple firmware for SNESTang
// nand2mario, 2024.1
//
// Needs xpack-gcc risc-v gcc: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/
// Use build.bat to build. Then burn firmware.bin to SPI flash address 0x500000 with Gowin programmer.

#include "picorv32.h"
#include "fatfs/ff.h"

#define OPTION_FILE "/snestang.ini"
#define OPTION_INVALID 2

#define OPTION_OSD_KEY_SELECT_START 1
#define OPTION_OSD_KEY_SELECT_RB 2

int option_osd_key = OPTION_OSD_KEY_SELECT_RB;

#define OSD_KEY_CODE (option_osd_key == 1 ? 0xC : 0x804)

void message(char *msg, int center);
void status(char *msg);

// return 0: success, 1: no option file found, 2: option file corrupt
int load_option() {
	FIL f;
	int r = 0;
	char buf[1024];
	char *line, *key, *value;
	if (f_open(&f, OPTION_FILE, FA_READ))
		return 1;
	// XXX: handle escapes and quotes
	while (f_gets(buf, 1024, &f)) {
		line = trimwhitespace(buf);
		if (line[0] == '\0' || line[0] == '[' || line[0] == ';' || line[0] == '#')
			continue;
		// find '='
		char *s = strchr(line, '=');
		if (!s) {
			r = OPTION_INVALID;
			goto load_option_close;
		}
		*s='\0';
		key = trimwhitespace(line);
		value = trimwhitespace(s+1);
		// status("");
		// printf("key=%s, value=%s", key, value);
		// message("see below",1);

		// now handle all key-value pairs
		if (strcmp(key, "osd_key") == 0) {
			option_osd_key = atoi(value);
			if (option_osd_key <= 0) {
				r = OPTION_INVALID;
				goto load_option_close;
			}
		} else {
			// just ignore unknown keys
		}
	}

load_option_close:
	f_close(&f);
	return r;
}


// return 0: success, 1: cannot save
int save_option() {
	FIL f;
	if (f_open(&f, OPTION_FILE, FA_READ | FA_WRITE | FA_CREATE_ALWAYS)) {
		message("f_open failed",1);
		return 1;
	}
	if (f_puts("osd_key=", &f) < 0) {
		message("f_puts failed",1);
		goto save_options_close;
	}
	if (option_osd_key == OPTION_OSD_KEY_SELECT_START)
		f_puts("1\n", &f);
	else
		f_puts("2\n", &f);
		
save_options_close:
	f_close(&f);
	// hide snestang.ini in dir list
	f_chmod(OPTION_FILE, AM_HID, AM_HID);
	return 0;
}

void status(char *msg) {
	cursor(0, 27);
	for (int i = 0; i < 32; i++)
		putchar(' ');
	cursor(2, 27);
	print(msg);
}

// show a pop-up message, press any key to discard (caller needs to redraw screen)
// msg: could be multi-line (separate with \n), max 10 lines
// center: whether to center the text
void message(char *msg, int center) {
	// count number of lines and max width
	int w[10], lines=10, maxw = 0;
	int len = strlen(msg);
	char *end = msg + len;
	char *sol = msg;
	for (int i = 0; i < 10; i++) {
		char *eol = strchr(sol, '\n');
		if (eol) { // found \n
			w[i] = min(eol - sol, 26);
			maxw = max(w[i], maxw);
			sol = eol+1;
		} else {
			w[i] = min(end - sol, 26);
			maxw = max(w[i], maxw);
			lines = i+1;
			break;
		}		
	}
	// status("");
	// printf("w=%d, lines=%d", maxw, lines);
	// draw a box 
	int y0 = 14 - ((lines + 2) >> 1);
	int y1 = y0 + lines + 2;
	int x0 = 16 - ((maxw + 2) >> 1);
	int x1 = x0 + maxw + 2;
	for (int y = y0; y < y1; y++)
		for (int x = x0; x < x1; x++) {
			cursor(x, y);
			if ((x == x0 || x == x1-1) && (y == y0 || y == y1-1))
				putchar('+');
			else if (x == x0 || x == x1-1)
				putchar('|');
			else if (y == y0 || y == y1-1)
				putchar('-');
			else
				putchar(' ');
		}
	// print text
	char *s = msg;
	for (int i = 0; i < lines; i++) {
		if (center)
			cursor(16-(w[i]>>1), y0+i+1);
		else
			cursor(x0+1, y0+i+1);
		while (*s != '\n' && *s != '\0') {
			putchar(*s);
			s++;
		}
		s++;
	}
	// wait for a keypress
	delay(300);
	for (;;) {
		int joy1, joy2;
		joy_get(&joy1, &joy2);
	   	if ((joy1 & 0x1) || (joy1 & 0x100) || (joy2 & 0x1) || (joy2 & 0x100))
	   		break;
	}
	delay(300);
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

int loadrom(int rom);

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
					if (idx != 0 && file_dir[i])
						print("/");
				}
			}
			delay(300);
			while (1) {
				int r = joy_choice(TOPLINE, file_len, &active, OSD_KEY_CODE);
				if (r == 1) {
					if (strcmp(pwd, "/") == 0 && page == 0 && active == 0) {
						// return to main menu
						return 1;
					} else if (file_dir[active]) {
						if (file_names[active][0] == '.' && file_names[active][1] == '.') {
							// return to parent dir
							// message(file_names[active], 1);
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
						if (loadrom(active) != 0) {
							message("Cannot load rom",1);
							break;
						}
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
	int choice = 0;
	while (1) {
		clear();
		cursor(8, 10);
		print("--- Options ---");

		cursor(2, 12);
		print("<< Return to main menu");
		cursor(2, 14);
		print("OSD hot key:");
		cursor(16, 14);
		if (option_osd_key == OPTION_OSD_KEY_SELECT_START)
			print("SELECT&START");
		else
			print("SELECT&RB");

		delay(300);

		for (;;) {
			if (joy_choice(12, 3, &choice, OSD_KEY_CODE) == 1) {
				if (choice == 0) {
					return;
				} if (choice == 2) {
					if (option_osd_key == OPTION_OSD_KEY_SELECT_START)
						option_osd_key = OPTION_OSD_KEY_SELECT_RB;
					else
						option_osd_key = OPTION_OSD_KEY_SELECT_START;
					status("Saving options...");
					if (save_option()) {
						message("Cannot save options to SD",1);
						break;
					}
					break;	// redraw UI
				}
			}
		}
	}
}

int in_game;

// return 0 if snes header is successfully parsed at off
// typ 0: LoROM, 1: HiROM, 2: ExHiROM
int parse_snes_header(FIL *fp, int pos, int file_size, int typ, uint8_t *hdr, int *map_ctrl, int *rom_type_header, int *rom_size, int *ram_size, int *company) {
	int br;
	if (f_lseek(fp, pos))
		return 1;
	f_read(fp, hdr, 64, &br);
	if (br != 64) return 1;
	int mc = hdr[21];
	int rom = hdr[23];
	int ram = hdr[24];
	int checksum = (hdr[28] << 8) + hdr[29];
	int checksum_compliment = (hdr[30] << 8) + hdr[31];
	int reset = (hdr[61] << 8) + hdr[60];
	int size2 = 1024 << rom;

	status("");
	printf("size=%d", size2);

	// calc heuristics score
	int score = 0;		
	if (size2 >= file_size) score++;
	if (rom == 1) score++;
	if (checksum + checksum_compliment == 0xffff) score++;
	int all_ascii = 1;
	for (int i = 0; i < 21; i++)
		if (hdr[i] < 32 || hdr[i] > 127)
			all_ascii = 0;
	score += all_ascii;

	DEBUG("pos=%x, type=%d, map_ctrl=%d, rom=%d, ram=%d, checksum=%x, checksum_comp=%x, reset=%x, score=%d\n", 
			pos, typ, mc, rom, ram, checksum, checksum_compliment, reset, score);

	if (rom < 14 && ram <= 7 && score >= 1 && 
		reset >= 0x8000 &&				// reset vector position correct
	   ((typ == 0 && (mc & 3) == 0) || 	// normal LoROM
		(typ == 0 && mc == 0x53)    ||	// contra 3 has 0x53 and LoROM
		(typ == 1 && (mc & 3) == 1) ||	// HiROM
		(typ == 2 && (mc & 3) == 2))) {	// ExHiROM
		*map_ctrl = mc;
		*rom_type_header = hdr[22];
		*rom_size = rom;
		*ram_size = ram;
		*company = hdr[26];
		return 0;
	}
	return 1;
}

char load_fname[1024];
char load_buf[1024];

// actually load a rom file
// return 0 if successful
int loadrom(int rom) {
	FIL f;
	strncpy(load_fname, pwd, 1024);
	strncat(load_fname, "/", 1024);
	strncat(load_fname, file_names[rom], 1024);

	// initiaze sd again to be sure
	if (sd_init() != 0) return 99;

	int r = f_open(&f, load_fname, FA_READ);
	if (r) {
		status("Cannot open file");
		goto loadrom_end;
	}
	int br, total = 0;
	int size = file_sizes[rom];
	int map_ctrl, rom_type_header, rom_size, ram_size, company;
	// parse SNES header from ROM file
	int off = size & 0x3ff;		// rom header (0 or 512)
	int header_pos;
	DEBUG("off=%d\n", off);
	
	header_pos = 0x7fc0 + off;
	if (parse_snes_header(&f, header_pos, size-off, 0, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
		header_pos = 0xffc0 + off;
		if (parse_snes_header(&f, header_pos, size-off, 1, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
			header_pos = 0x40ffc0 + off;
			if (parse_snes_header(&f, header_pos, size-off, 2, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
				status("Not a SNES ROM file");
				delay(200);
				goto loadrom_close_file;
			}
		}
	}

	// load actual ROM
	snes_ctrl(1);
/*
	// 3-word header
	// word 0: {ram_size, rom_sie, rom_type_header, map_ctrl}
	snes_data(map_ctrl | (rom_type_header << 8) | (rom_size << 16) | (ram_size << 24));
	// word 1: {company, rom_mask[23:0]}
	snes_data(((1024 << (rom_size < 7 ? 12 : rom_size)) - 1) | (company << 24));
	// word 2: {8'b0, ram_mask[23:0]}
	snes_data(ram_size ? (1024 << ram_size) - 1 : 0);
*/
	// Send 64-byte header to snes
	for (int i = 0; i < 64; i += 4) {
		uint32_t *w = (uint32_t *)(load_buf + i);
		snes_data(*w);
	}

	// Send rom content to snes
	if ((r = f_lseek(&f, off)) != FR_OK) {
		status("Seek failure");
		goto loadrom_snes_end;
	}
	do {
		if ((r = f_read(&f, load_buf, 1024, &br)) != FR_OK)
			break;
		for (int i = 0; i < br; i += 4) {
			uint32_t *w = (uint32_t *)(load_buf + i);
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
	status("Success");
	overlay(0);		// turn off OSD

loadrom_snes_end:
	snes_ctrl(0);
loadrom_close_file:
	f_close(&f);
loadrom_end:
	return r;
}

int main() {
	// reg_uart_clkdiv = 94;       // 10800000 / 115200
	reg_uart_clkdiv = 187;       // 21505400 / 115200
	overlay(1);

	uart_init();		// init UART output for DEBUG(...)

	int mounted = 0;
	while(!mounted) {
		for (int attempts = 0; attempts < 255; attempts++) {
			if (f_mount(&fs, "", 0) == FR_OK) {
				mounted = 1;
				break;
			}
		}
		if (!mounted)
			message("Insert SD card and press any key", 1);
	}

	int r = load_option();
	if (r == 2) {	// file corrupt
		clear();
		message("Option file corrupt and is not loaded",1);
	} else if (r == 1) {	// file not exist
		// clear();
		// message("Cannot open option file",1);
	}

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

		delay(300);

		int choice = 0;
		for (;;) {
			int r = joy_choice(12, 2, &choice, OSD_KEY_CODE);
			if (r == 1) break;
		}

		if (choice == 0) {
			int rom;
			delay(300);
			menu_loadrom(&rom);
		} else if (choice == 1) {
			delay(300);
			menu_options();
			continue;
		}
	}
}