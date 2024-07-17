// Simple firmware for SNESTang
// nand2mario, 2024.1
//
// Needs xpack-gcc risc-v gcc: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/
// Use build.bat to build. Then burn firmware.bin to SPI flash address 0x500000 with Gowin programmer.

#include <stdbool.h>
#include <stdio.h>
#include "picorv32.h"
#include "fatfs/ff.h"
#include "firmware.h"

uint32_t CORE_ID;
enum {
    CORE_NES  =  1,
    CORE_SNES =  2,
    CORE_GB   =  3
}core_ids;

#define OPTION_FILE "/snestang.ini"
#define OPTION_INVALID 2

#define OPTION_OSD_KEY_SELECT_START 1
#define OPTION_OSD_KEY_SELECT_RIGHT 2
#define OPTION_OSD_KEY_HOME         3

#define CHEATS_MAX_NUMBER 16

#define MENU_OPTIONS_OFFSET_COL1_X      2
#define MENU_OPTIONS_OFFSET_COL2_X      16
#define MENU_OPTIONS_OFFSET_Y           12

enum {
    MENU_OPTIONS_RETURN = 0,
    MENU_OPTIONS_NOTHING = 1,
    MENU_OPTIONS_OSD_HOT_KEY,
    MENU_OPTIONS_BACKUP_BSRAM,
    MENU_OPTIONS_ENHANCED_APU,
    MENU_OPTIONS_CHEATS,
    MENU_OPTIONS_SAVE_BSRAM,
    MENU_OPTIONS_LOAD_BSRAM,
    MENU_OPTIONS_SYSTEM,
    MENU_OPTIONS_ASPECT,
    MENU_OPTIONS_COUNT
}menu_options_values;

enum{
    MAIN_OPTIONS_LOAD_ROM = 0,
    MAIN_OPTIONS_LOAD_CORE,
    MAIN_OPTIONS_OPTIONS,
    MAIN_OPTIONS_NOTHING,
    MAIN_OPTIONS_VERSION,
    MAIN_OPTIONS_COUNT
};

// SNES BSRAM is mapped at address 7MB 
volatile uint8_t *SNES_BSRAM = (volatile uint8_t *)0x07000000;
volatile uint8_t *NES_BSRAM = (volatile uint8_t *)0x00006000;

uint8_t *nes_bsram_starting_address = (uint8_t *)0x006000;			// directly read into BSRAM
const uint32_t nes_bsram_size = (0x8000 - 0x6000);

int option_osd_key;
#define OSD_KEY_CODE (option_osd_key == OPTION_OSD_KEY_SELECT_START ? 0xC : (option_osd_key == OPTION_OSD_KEY_SELECT_RIGHT ? 0x84 : 0x24))
bool option_backup_bsram;
bool option_enhanced_apu;
bool option_cheats_enabled;
bool option_sys_type_is_pal;

bool flag_load_nes_bsram;

uint32_t option_aspect_ratio;

static bool rom_loaded = false;

bool snes_running;
int snes_ramsize;
bool nes_backup_valid;		// whether it is okay to save
bool snes_backup_valid;		// whether it is okay to save
char snes_backup_name[256];
char nes_backup_name_bsram[256] = "";
char nes_backup_save_str_bsram[] = "saves/";
char nes_backup_path_bsram[266] = "";
char snes_backup_path[266] = "saves/";
uint16_t nes_bsram_crc16;
uint16_t snes_bsram_crc16;
uint32_t snes_backup_time;

char load_fname[1024];
char load_buf[1024];

int save_bsram(void);
int load_bsram(void);

// Enhanced APU - enable
void enhanced_apu_enable(void){
   reg_enhanced_apu = 1;
}
// Enhanced APU - disable
void enhanced_apu_disable(void){
   reg_enhanced_apu = 0;
}

// return 0: success, 1: no option file found, 2: option file corrupt
int load_option()  {
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
        uart_printf("key=%s, value=%s\r\n", key, value);
        // message("see below",1);

        // now handle all key-value pairs
        if (strcmp(key, "osd_key") == 0) {
            option_osd_key = atoi(value);
            uart_printf("osd_key: %d\r\n", option_osd_key);
            if (option_osd_key <= 0) {
                r = OPTION_INVALID;
                goto load_option_close;
            }
        } else if (strcmp(key, "backup_bsram") == 0) {
            uart_printf("backup_bsram: %d\r\n", value);
            if (strcasecmp(value, "true") == 0)
                option_backup_bsram = true;
            else
                option_backup_bsram = false;
            uart_printf("option_backup_bsram: %d\r\n", option_backup_bsram);
        } else if (strcmp(key, "enhanced_apu") == 0) {
            uart_printf("enhanced_apu: %d\r\n", value);
            if (strcasecmp(value, "true") == 0)
                option_enhanced_apu = true;
            else
                option_enhanced_apu = false;
            uart_printf("option_enhanced_apu: %d\r\n", option_enhanced_apu);
            reg_enhanced_apu = (uint32_t)option_enhanced_apu;
            uart_printf("reg_enhanced_apu: %d\r\n", reg_enhanced_apu);
        } else if (strcmp(key, "cheats_enabled") == 0) {
            uart_printf("cheats_enabled: %d\r\n", value);
            if (strcasecmp(value, "true") == 0)
                option_cheats_enabled = true;
            else
                option_cheats_enabled = false;
            uart_printf("option_cheats_enabled: %d\r\n", option_cheats_enabled);
            reg_cheats_enabled = (uint32_t)option_cheats_enabled;
            uart_printf("reg_cheats_enabled: %d\r\n", reg_cheats_enabled);
        } else if (strcmp(key, "system") == 0) {
            uart_printf("system: %d\r\n", value);
            if (strcasecmp(value, "false") == 0)
                option_sys_type_is_pal = false;
            else
                option_sys_type_is_pal = true;
            uart_printf("option_sys_type_is_pal: %d\r\n", option_sys_type_is_pal);
            reg_sys_type = (uint32_t)option_sys_type_is_pal;
            uart_printf("reg_sys_type: %d\r\n", reg_sys_type);
        } else if (strcmp(key, "aspect_ratio") == 0) {
            uart_printf("aspect_ratio: %d\r\n", value);
            if (strcasecmp(value, "0") == 0)
                option_aspect_ratio = 0;
            else
                option_aspect_ratio = 1;
            uart_printf("option_aspect_ratio: %d\r\n", option_aspect_ratio);
            reg_aspect_ratio = option_aspect_ratio;
            uart_printf("reg_aspect_ratio: %d\r\n", reg_aspect_ratio);
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
    else if(option_osd_key == OPTION_OSD_KEY_SELECT_RIGHT)
        f_puts("2\n", &f);
    else
        f_puts("3\n", &f);
    f_puts("backup_bsram=", &f);
    if (option_backup_bsram)
        f_puts("true\n", &f);
    else
        f_puts("false\n", &f);
	f_puts("enhanced_apu=", &f);
	if (option_enhanced_apu){
		f_puts("true\n", &f);
	}
	else{
		f_puts("false\n", &f);
	}
	f_puts("cheats_enabled=", &f);
	if (option_cheats_enabled){
		f_puts("true\n", &f);
	}
	else{
		f_puts("false\n", &f);
	}
    f_puts("system=", &f);
	if (option_sys_type_is_pal){
		f_puts("true\n", &f);
	}
	else{
		f_puts("false\n", &f);
	}
    f_puts("aspect_ratio=", &f);
	if (option_aspect_ratio){
		f_puts("1\n", &f);
	}
    else{
		f_puts("0\n", &f);
	}
		
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
    DEBUG("load_dir: %s, start=%d, len=%d\r\n", dir, start, len);
    int cnt = 0;
    int r = 0;
    DIR d;
    file_len = 0;
    // initiaze sd again to be sure
    int init_ok = 0;
    for (int i = 0; i <= 10; i++)
        if (sd_init() == 0) {
            init_ok = 1;
            break;
        }
    if (!init_ok) return 99;

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
    DEBUG("load_dir: count=%d\r\n", cnt);
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
                    if (idx != 0 && file_dir[i])
                        print("/");
                }
            }
            delay(300);
            while (1) {
                int r = joy_choice(TOPLINE, file_len, &active, OSD_KEY_CODE);
                if(r == 4) 
                    return 1;   // return to main menu
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
                        int res;
                        if (CORE_ID == 1)
                            res = loadnes(active);
                        else
                            res = loadsnes(active);
                        if (res != 0) {
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

uint8_t corebuf[256];
uint32_t t_ready, t_flash, t_file, t_parse;

void write_flash(uint8_t *corebuf, uint32_t addr, int cnt) {
    uint32_t start = cycle_counter();
    // uart_printf("Writing %d bytes at %x\n", cnt, addr);
    if ((addr & 0xfff) == 0) {	// whole 4KB, erase sector first
        uint32_t t = cycle_counter();
        spiflash_ready();
        t_ready += cycle_counter() - t;
        spiflash_sector_erase(addr);
        // uart_printf("Sector erased\n");
    }
    uint32_t t = cycle_counter();
    spiflash_ready();
    t_ready += cycle_counter() - t;
    spiflash_page_program(addr, corebuf);
    if ((addr & 0xfff) == 0) {
        status("");
        printf("%d KB written", addr >> 10);
    }
    t_flash += cycle_counter() - start;
    spiflash_ready();
}

// return true: verify OK
bool verify_flash(uint8_t *corebuf, uint32_t addr, int cnt) {
    // uart_printf("Verifying %d bytes at %x\n", cnt, addr);
    uint8_t buf[256];
    spiflash_read(addr, buf, 256);
    for (int j = 0; j < cnt; j++) {
        if (buf[j] != corebuf[j]) {
            uart_printf("Verify error at %x: %d != %d. Data read:\r\n", addr+j, buf[j], corebuf[j]);
            for (int i = 0; i < 256; i++) {
                if (i > 0 && i % 16 == 0)
                    uart_print("\r\n");
                uart_print_hex_digits(buf[i], 2);
                uart_print(" ");
            }
            uart_print("\r\n");
            return false;
        }
    }
    if ((addr & 0xfff) == 0) {
        status("");
        printf("%d KB verified", addr >> 10);
    }
    return true;
}

static unsigned int load_buf_off;            // next available pos in load_buf
static unsigned int load_buf_len;            // length of data in load_buf   

// load a line into buf (max length *len), *len is updated to actual length of string
// this uses load_buf[] internally
void read_line(FIL *fp, char *buf, int *len) {
    int br;
    int i = 0;
    bool done = false;
    while (!done) {
        for (; !done && i + 1 < *len && load_buf_off < load_buf_len; i++, load_buf_off++) {
            buf[i] = load_buf[load_buf_off];
            if (load_buf[load_buf_off] == '\n')
                done = true;
        }
        if (i == *len)
            done = true;
        if (!done) {
            // load more data
            load_buf_off = 0;
            if (f_eof(fp))
                break;
            f_read(fp, load_buf, 1024, &load_buf_len);
        }
    }
    buf[i] = 0;
    *len = i;
}

static char line_buf[4096];         // .fs file has max 3.5K lines

void load_core(char *fname, int verify) {
    FIL f;
    int binfile = strcasestr(fname, ".bin") != NULL;      // 1: bin        
    t_ready = 0; t_flash = 0, t_file = 0; t_parse = 0;
    if (binfile)
        uart_printf("Loading bin file: %s\r\n", fname);
    else
        uart_printf("Loading fs file: %s\r\n", fname);
    if (verify && !binfile) {
        message("Verify only supported for .bin files", 1);
        return;
    }

    if (f_open(&f, fname, FA_READ) != FR_OK) {
        message("Cannot open core file", 1);
        return;
    }
    int addr = 0;
    char *s = load_buf;
    unsigned int cnt = 0;
    int bol = 1;
    int br;
    while (!f_eof(&f) && (binfile || addr < 32*1024)) { // write only 32KB for .fs
        if (binfile) {
            uint32_t t = cycle_counter();
            f_read(&f, corebuf, 256, &cnt);
            t_file += cycle_counter() - t;
            if (verify) {
                if (!verify_flash(corebuf, addr, cnt))
                    return;
            } else
                write_flash(corebuf, addr, cnt);
            addr += cnt;
            cnt = 0;
        } else {        // parse .fs file
            uint32_t t = cycle_counter();
            if (f_eof(&f)) continue;
            int len = 4096;
            read_line(&f, line_buf, &len);
            // message(line_buf, 0);
            t_file += cycle_counter() - t;
            if (s[0] == '/' && s[1] == '/') {
                // comment, skip the whole line
                continue;
            }
            for (int i = 0; i+8 <= len; i+=8) {	// add a byte to buf
                uint32_t t2 = cycle_counter();
                if (s[i] > '1' || s[i] < '0') break;
                uint8_t b = ((s[i]-'0') << 7) + ((s[i+1]-'0') << 6) +
                        ((s[i+2]-'0') << 5) + ((s[i+3]-'0') << 4) +
                        ((s[i+4]-'0') << 3) + ((s[i+5]-'0') << 2) +
                        ((s[i+6]-'0') << 1) + (s[i+7]-'0');
                corebuf[cnt] = b;
                if (cnt < 16) {
                    char ss[9];
                    strncpy(ss, s+i, 9);
                    uart_printf("[%s]=", ss);
                    uart_print_hex_digits(b, 2);
                    uart_print(" ");
                }
                cnt++;
                t_parse += cycle_counter() - t2;
                if (cnt == 256) {				// write a page
                    uart_printf("Writing at %x:", addr);
                    for (int j = 0; j < 16; j++) {
                        uart_print_hex_digits(corebuf[j], 2);
                        uart_print(" ");
                    }
                    uart_print("\r\n");
                    write_flash(corebuf, addr, cnt);
                    addr += cnt;
                    cnt = 0;
                }
            }
        }
    }
    // write remaining data in buffer
    if (cnt > 0) {
        write_flash(corebuf, addr, cnt);
        addr += cnt;
    }
    spiflash_write_disable();
    f_close(&f);

    const uint32_t MS = 21500;
    uart_printf("File read cycles: %d, parse cycles: %d, flash total cycles: %d, flash wait cycles: %d\r\n", t_file, t_parse, t_flash, t_ready);
    uart_printf("File read time: %d ms, parse time: %d ms, flash total time: %d ms, flash wait time: %d ms\r\n", t_file / MS, t_parse / MS, t_flash / MS, t_ready / MS);
    if (verify)
        message("Core matches", 1);
    else
        message("Core ready. Pls reboot", 1);
}

void menu_select_core(int verify) {
    int total, choice=0, draw=1;
    int r = load_dir("/cores", 0, PAGESIZE, &total);
    if (r != 0) {
        clear();
        message("Need .bin in /cores", 1);
        return;
    }
    delay(300);

    for (;;) {
        if (draw) {
            clear();
            cursor(2, 2);
            print("<< Return to main menu");        // this replaces ".."
            if (total > PAGESIZE) total = PAGESIZE;
            for (int i = 1; i < total; i++) {
                cursor(2, i+2);
                print(file_names[i]);
            }
            draw = 0;
        }
        int r = joy_choice(2, total, &choice, OSD_KEY_CODE);
        if(r == 4) 
            return;
        if (r == 1) {
            if (choice == 0)
                return;
            else {
                char *p;
                // p = strcasestr(file_names[choice], ".fs");
                // if (p == NULL)
                p = strcasestr(file_names[choice], ".bin");
                if (p == NULL) {
                    message("Only .bin supported", 1);
                    draw = 1;
                    continue;
                }
                
                // load core
                strncpy(load_fname, "/cores/", 1024);
                strncat(load_fname, file_names[choice], 1024);
                load_core(load_fname, verify);
                return;
            }
        }
    }
}

void _menu_select_core() {
    uint8_t buf[256];
    uart_printf("begin select_core\r\n");
    spiflash_read(0*1024*1024, buf, 256);
    for (int i = 0; i < 256; i++) {
        if (i > 0 && i % 16 == 0)
            uart_printf("\r\n");
        uart_print_hex_digits(buf[i], 2);
        uart_print(" ");
    }
    uart_printf("\r\n");
    
    status("Check UART for log");
    uart_printf("end select_core\r\n");
}

// load a cheats file.
// return 0 if successful
int load_cheats(int cheat_file) {
	FIL f;
	strncpy(load_fname, pwd, 1024);
	strncat(load_fname, "/", 1024);
	strncat(load_fname, file_names[cheat_file], 1024);

	DEBUG("load cheats start\r\n");

	// check extension .sfc or .smc
	char *p = strcasestr(file_names[cheat_file], ".cwz");
	if (p == NULL) {
		status("Only .cwz supported");
		goto load_cheats_end;
	}

	// initiaze sd again to be sure
	if (sd_init() != 0) return 99;

	int r = f_open(&f, load_fname, FA_READ);
	if (r) {
		status("Cannot open file");
		reg_cheats_loaded = 0;
		goto load_cheats_end;
	}
	int off = 0, br, total = 0;
	int size = file_sizes[cheat_file];

	// Parse here
	BYTE s[16];
	UINT rc;
	uint8_t cheat_counter = 0;
	for(int i=0; i<CHEATS_MAX_NUMBER; ++i){
		f_read(&f, s, 16, &rc);
		reg_cheats_data_ready = 0;
		s[2] = (uint8_t)i+1;
		reg_cheats_3 = (uint32_t)((uint16_t)(s[2] << 8) | (uint8_t)s[3]);
		reg_cheats_2 = (uint32_t)((uint16_t)(s[6] << 8) | (uint8_t)s[7]);
		reg_cheats_1 = (uint32_t)((uint16_t)(s[10] << 8) | (uint8_t)s[11]);
		reg_cheats_0 = (uint32_t)((uint16_t)(s[14] << 8) | (uint8_t)s[15]);

		cheat_counter++;

		reg_cheats_data_ready = 1;
		while(reg_cheats_data_ready == 1);
		// delay(1000);
	}

	bool cheats_loaded = (cheat_counter == CHEATS_MAX_NUMBER);
	if((reg_cheats_enabled)&&(option_cheats_enabled)&&(cheats_loaded)){
		reg_cheats_loaded = 1;
		status("Cheats loaded!");
	}
	else{
		reg_cheats_loaded = 1;
		status("Error loading");
	}
	reg_cheats_data_ready = 0;

load_cheats_close_file:
	f_close(&f);
load_cheats_end:
	return r;
}

// return 0: user chose a cheat file (*choice), 1: no choice made, -1: error
// file chosen: pwd / file_name[*choice]
int menu_load_cheats(int *choice) {
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
                if(r == 4) 
                    return 1;   // return to main menu
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
						// actually load a cheat file
						*choice = active;
						int res;
						if (CORE_ID == 1)
							res = load_cheats(active);
						else
							res = load_cheats(active);
						if (res != 0) {
							message("Cannot load cheat file",1);
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
			status("Error opening directory");
			printf(" %d", r);
			return -1;
		}
	}
}

void menu_cheats_options() {
	int choice = 0;
	int cheat_file;
	while (1) {
		clear();
		cursor(8, 10);
		print("--- Cheats ---");

		cursor(2, 12);
		print("<< Return to main menu");
		cursor(2, 14);
		print("Cheats:");
		cursor(16, 14);
		if (option_cheats_enabled)
			print("On");
		else
			print("Off");
		cursor(2, 15);
		print("Load cheat file");
	

		delay(300);

		for (;;) {
            int r = joy_choice(12, 4, &choice, OSD_KEY_CODE);
            if(r == 4) 
                return;
			if (r == 1) {
				if (choice == 0) {
					return;
				} else if (choice == 1) {
					// nothing
				} else {
					if (choice == 2) {
						option_cheats_enabled = !option_cheats_enabled;
						reg_cheats_enabled = option_cheats_enabled;
					} else if (choice == 3) {
						delay(300);
						menu_load_cheats(&cheat_file);
						// continue;
					}
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

// Return 0 if success
int save_bsram(void){
    FIL f;
    FILINFO fno;
    int r = 0;

    if (f_stat(snes_backup_path, &fno) != FR_OK) {
        if (f_mkdir(snes_backup_path) != FR_OK) {
            status("Cannot create /saves");
            uart_printf("Cannot create /saves\r\n");
            return 1;
        }
    }
    if(nes_backup_name_bsram == ""){
        status("ERROR: invalid name!");
        return 1;
    }
    if(nes_backup_path_bsram == ""){
        status("ERROR: invalid path!");
        return 1;
    }
    if (f_open(&f, nes_backup_path_bsram, (FA_WRITE | FA_CREATE_ALWAYS)) != FR_OK) {
        status("Cannot write save file");
        uart_printf("Cannot write save file");
        return 1;
    }
    unsigned int bw;
    if (f_write(&f, nes_bsram_starting_address, nes_bsram_size, &bw) != FR_OK || bw != nes_bsram_size) {
        status("ERROR: BSRAM not saved!");
        uart_printf("Write failure, bw=%d\r\n", bw);
        r = 2;
        return 1;
    }
    status("BSRAM saved!");

	f_close(&f);
    return 0;
}

// 1 if error
// 0 if OK
int load_bsram(void){
    nes_backup_valid = false;
    FILINFO fno;

    reg_load_bsram = 1;
    delay(250);

    if (f_stat(nes_backup_path_bsram, &fno) != FR_OK) {
        if (f_mkdir(nes_backup_path_bsram) != FR_OK) {
            status("Cannot create /saves");
            return 1;
        }
    }
    uart_printf("Loading bsram from: %s\r\n", nes_backup_path_bsram);
    FIL f;
    if (f_open(&f, nes_backup_path_bsram, FA_READ) != FR_OK) {
        nes_backup_valid = true;
        status("Cannot open bsram file, assuming new");
        return 1;
    }

    uint8_t *p = nes_bsram_starting_address;	
    unsigned int load = 0;
    
    while (load < nes_bsram_size) {
        int br;
        if (f_read(&f, p, 1024, &br) != FR_OK || br < 1024) 
            break;
        p += br;
        load += br;
    }
    nes_backup_valid = true;
    f_close(&f);
    int crc = gen_crc16(nes_bsram_starting_address, nes_bsram_size);
    // uart_printf("Bsram backup loaded %d bytes CRC=%x.\n", load, crc);
    status("BSRAM loaded!");

    nes_bsram_crc16 = gen_crc16(nes_bsram_starting_address, nes_bsram_size);

    delay(250);
    reg_load_bsram = 0;
	return 0;
}

void menu_options() {
	int choice = 0;
	while (1) {
		clear();
		cursor(8, 10);
		print("--- Options ---");

        // Return to main menu
		cursor(MENU_OPTIONS_OFFSET_COL1_X, MENU_OPTIONS_OFFSET_Y);
		print("<< Return to main menu");
        // OSD hot key
		cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_OSD_HOT_KEY));
		print("OSD hot key:");
		cursor(MENU_OPTIONS_OFFSET_COL2_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_OSD_HOT_KEY));
		if (option_osd_key == OPTION_OSD_KEY_SELECT_START)
			print("SELECT&START");
		else if(option_osd_key == OPTION_OSD_KEY_SELECT_RIGHT)
			print("SELECT&RIGHT");
		else
			print("HOME");
		// Backup BSRAM
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_BACKUP_BSRAM));
		print("Backup BSRAM:");
		cursor(MENU_OPTIONS_OFFSET_COL2_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_BACKUP_BSRAM));
		if (option_backup_bsram)
			print("Yes");
		else
			print("No");
		// Enhanced APU
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_ENHANCED_APU));
		print("Enhanced APU:");
		cursor(MENU_OPTIONS_OFFSET_COL2_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_ENHANCED_APU));
		if (option_enhanced_apu)
			print("Yes");
		else
			print("No");
		// Cheats
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_CHEATS));
		print("Cheats");
        // Save BSRAM
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_SAVE_BSRAM));
		print("Save BSRAM");
        // Load BSRAM
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_LOAD_BSRAM));
		print("Load BSRAM");
        // System - NTSC/DENDY or PAL
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_SYSTEM));
		print("System:");
        cursor(MENU_OPTIONS_OFFSET_COL2_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_SYSTEM));
        if(!option_sys_type_is_pal)
			print("NTSC/DENDY");
		else
			print("PAL");
        // Aspect Ratio
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_ASPECT));
        print("Aspect:");
        cursor(MENU_OPTIONS_OFFSET_COL2_X, (MENU_OPTIONS_OFFSET_Y+MENU_OPTIONS_ASPECT));
        if(!option_aspect_ratio)
			print("1:1");
		else
			print("8:7");

		delay(300);

		for (;;) {
            int r = joy_choice(12, 10, &choice, OSD_KEY_CODE);
            if(r == 4) 
                return;
			if (r == 1) {
				if (choice == MENU_OPTIONS_RETURN) {
					return;
				} else if (choice == MENU_OPTIONS_NOTHING) {
					// nothing
				} else {
					if (choice == MENU_OPTIONS_OSD_HOT_KEY) {
						if (option_osd_key == OPTION_OSD_KEY_SELECT_START)
							option_osd_key = OPTION_OSD_KEY_SELECT_RIGHT;
						else if (option_osd_key == OPTION_OSD_KEY_SELECT_RIGHT)
							option_osd_key = OPTION_OSD_KEY_HOME;
						else
							option_osd_key = OPTION_OSD_KEY_SELECT_START;
					} else if (choice == MENU_OPTIONS_BACKUP_BSRAM) {
						option_backup_bsram = !option_backup_bsram;
					} else if (choice == MENU_OPTIONS_ENHANCED_APU) {
						option_enhanced_apu = !option_enhanced_apu;
						reg_enhanced_apu = !reg_enhanced_apu;
					} else if (choice == MENU_OPTIONS_CHEATS) {
						delay(300);
						menu_cheats_options();
						//continue;
					} else if (choice == MENU_OPTIONS_SAVE_BSRAM) {
						delay(300);
						save_bsram();
						//continue;
					}else if (choice  == MENU_OPTIONS_LOAD_BSRAM) {
						delay(300);
						load_bsram();
						//continue;
					} else if (choice == MENU_OPTIONS_SYSTEM) {
						option_sys_type_is_pal = !option_sys_type_is_pal;
                        reg_sys_type = (uint32_t)option_sys_type_is_pal;
                    } else if (choice == MENU_OPTIONS_ASPECT) {
						option_aspect_ratio = !option_aspect_ratio;
                        reg_aspect_ratio = (uint32_t)option_aspect_ratio;
                    }
                    // 
					if((choice != MENU_OPTIONS_CHEATS)&&(choice != MENU_OPTIONS_SAVE_BSRAM)&&(choice != MENU_OPTIONS_LOAD_BSRAM)){
						status("Saving options...");
					    if (save_option()) {
						    message("Cannot save options to SD",1);
						    break;
                        }
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
int parse_snes_header(FIL *fp, int pos, int file_size, int typ, char *hdr,
                      int *map_ctrl, int *rom_type_header, int *rom_size,
                      int *ram_size, int *company) {
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

    DEBUG("pos=%x, type=%d, map_ctrl=%d, rom=%d, ram=%d, checksum=%x, checksum_comp=%x, reset=%x, score=%d\r\n", 
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

// actually load a rom file. if bsram backup is needed, also loads the backup.
// return 0 if successful
int loadsnes(int rom) {
    FIL f;
    int r=1;
    strncpy(load_fname, pwd, 1024);
    strncat(load_fname, "/", 1024);
    strncat(load_fname, file_names[rom], 1024);

    // check extension .sfc or .smc
    char *p = strcasestr(file_names[rom], ".sfc");
    if (p == NULL)
        p = strcasestr(file_names[rom], ".smc");
    if (p == NULL) {
        status("Only .smc or .sfc supported");
        goto loadsnes_end;
    }
    // snes_backup_name = <base>.srm
    int base_len = p-file_names[rom];
    strncpy(snes_backup_name, file_names[rom], base_len);
    strcpy(snes_backup_name+base_len, ".srm");

    // initiaze sd again to be sure
    if (sd_init() != 0) return 99;

    r = f_open(&f, load_fname, FA_READ);
    if (r) {
        status("Cannot open file");
        goto loadsnes_end;
    }
    unsigned int br, total = 0;
    int size = file_sizes[rom];
    int map_ctrl, rom_type_header, rom_size, ram_size, company;
    // parse SNES header from ROM file
    int off = size & 0x3ff;		// rom header (0 or 512)
    int header_pos;
    DEBUG("off=%d\r\n", off);
    
    header_pos = 0x7fc0 + off;
    if (parse_snes_header(&f, header_pos, size-off, 0, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
        header_pos = 0xffc0 + off;
        if (parse_snes_header(&f, header_pos, size-off, 1, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
            header_pos = 0x40ffc0 + off;
            if (parse_snes_header(&f, header_pos, size-off, 2, load_buf, &map_ctrl, &rom_type_header, &rom_size, &ram_size, &company)) {
                status("Not a SNES ROM file");
                delay(200);
                goto loadsnes_close_file;
            }
        }
    }

    // load actual ROM
    snes_ctrl(1);		// enable game loading, this resets SNES
    snes_running = false;

    // Send 64-byte header to snes
    for (int i = 0; i < 64; i += 4) {
        uint32_t *w = (uint32_t *)(load_buf + i);
        snes_data(*w);
    }

    // Send rom content to snes
    if ((r = f_lseek(&f, off)) != FR_OK) {
        status("Seek failure");
        goto loadsnes_snes_end;
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

    // load BSRAM backup
    snes_ramsize = ram_size == 0 ? 0 : ((1 << ram_size) << 10);
    if (snes_ramsize > 0)
        memset((uint8_t *)0x700000, 0, snes_ramsize);		// clear BSRAM
    backup_load(snes_backup_name, snes_ramsize);

    status("Success");
    snes_running = true;

    overlay(0);		// turn off OSD

loadsnes_snes_end:
    snes_ctrl(0);	// turn off game loading, this starts SNES
loadsnes_close_file:
    f_close(&f);
loadsnes_end:
	return r;
}

// load a NES rom file.
// return 0 if successful
int loadnes(int rom) {
    FIL f;
    int r=1;
    strncpy(load_fname, pwd, 1024);
    strncat(load_fname, "/", 1024);
    strncat(load_fname, file_names[rom], 1024);
    int i=0;
    for(int i=0; i<266; ++i)
        nes_backup_path_bsram[i] = '\0';
    i = 0;
    while(file_names[rom][i] != '\0')
        ++i;
    memset(nes_backup_path_bsram, '\0', 266);
    strncpy(nes_backup_name_bsram, file_names[rom], (i-4));
    strcat(nes_backup_path_bsram, nes_backup_save_str_bsram);
    strcat(nes_backup_path_bsram, nes_backup_name_bsram);

    DEBUG("loadnes start\r\n");

    // check extension .sfc or .smc
    char *p = strcasestr(file_names[rom], ".nes");
    if (p == NULL) {
        status("Only .nes supported");
        goto loadnes_end;
    }

    // initiaze sd again to be sure
    if (sd_init() != 0) return 99;

    r = f_open(&f, load_fname, FA_READ);
    if (r) {
        status("Cannot open file");
        goto loadnes_end;
    }
    unsigned int off = 0, br, total = 0;
    unsigned int size = file_sizes[rom];

    // load actual ROM
    snes_ctrl(1);		// enable game loading, this resets SNES
    snes_running = false;

    // Send rom content to snes
    if ((r = f_lseek(&f, off)) != FR_OK) {
        status("Seek failure");
        goto loadnes_nes_end;
    }
    int bsram_counter = 0;
    do {
        if ((r = f_read(&f, load_buf, 1024, &br)) != FR_OK)
            break;
        total += br;    // bytes
        // if((total >= 0x6000)&&(total < 0x8000)){
        //     memset((nes_bsram_starting_address + bsram_counter), 0, br);
        //     bsram_counter++;
        // }
        for (int i = 0; i < br; i += 4) {
            uint32_t *w = (uint32_t *)(load_buf + i);
            snes_data(*w);				// send actual ROM data
        }
        if ((total & 0xfff) == 0) {	// display progress every 4KB
            status("");
            printf("%d/%dK", total >> 10, size >> 10);
        }
    } while (br == 1024);
    f_close(&f);

    // Load BSRAM
    if(option_backup_bsram){
        // uint32_t nes_bsram_local;
        // memset(nes_bsram_starting_address, 0, 0x2000);
        // r = load_bsram();
    }
    
    DEBUG("loadnes: %d bytes\r\n", total);
    status("Success");
    snes_running = true;

loadnes_nes_end:
	snes_ctrl(0);	// turn off game loading, this starts the core
loadnes_end:
    overlay(0);		// turn off OSD
	return r;
}

void backup_load(char *name, int size) {
    snes_backup_valid = false;
    if (!option_backup_bsram || size == 0) return;
    FILINFO fno;
    uint8_t *bsram = (uint8_t *)0x700000;			// directly read into BSRAM

    if (f_stat(snes_backup_path, &fno) != FR_OK) {
        if (f_mkdir(snes_backup_path) != FR_OK) {
            status("Cannot create /saves");
            uart_printf("Cannot create /saves\r\n");
            goto backup_load_crc;
        }
    }
    strcat(snes_backup_path, snes_backup_name);
    uart_printf("Loading bsram from: %s\r\n", snes_backup_name);
    FIL f;
    if (f_open(&f, snes_backup_path, FA_READ) != FR_OK) {
        nes_backup_valid = true;					// new save file, mark as valid
        uart_printf("Cannot open bsram file, assuming new\r\n");
        goto backup_load_crc;
    }
    uint8_t *p = bsram;	
    unsigned int load = 0;
    while (load < size) {
        int br;
        if (f_read(&f, p, 1024, &br) != FR_OK || br < 1024) 
            break;
        p += br;
        load += br;
    }
    snes_backup_valid = true;
    f_close(&f);
    int crc = gen_crc16(bsram, size);
    uart_printf("Bsram backup loaded %d bytes CRC=%x.\r\n", load, crc);

backup_load_crc:
    snes_bsram_crc16 = gen_crc16(bsram, size);
	return;
}

// return 0: successfully saved, 1: BSRAM unchanged, 2: file write failure
int backup_save(char *name, int size) {
    if (!option_backup_bsram || !snes_backup_valid || size == 0) return 1;
    char path[266] = "/saves/";
    FIL f;
    uint8_t *bsram = (uint8_t *)0x700000;		// directly read from BSRAM
    int r = 0;

    // first check if BSRAM content is changed since last save
    int newcrc = gen_crc16(bsram, size);
    uart_printf("New CRC: %x, size=%d\r\n", newcrc, size);
    if (newcrc == snes_bsram_crc16)
        return 1;

    strcat(path, snes_backup_name);
    if (f_open(&f, path, FA_WRITE | FA_CREATE_ALWAYS) != FR_OK) {
        status("Cannot write save file");
        uart_printf("Cannot write save file");
        return 2;
    }
    unsigned int bw;
    // for (int off = 0; off < size; off += bw) {
    // 	if (f_write(&f, bsram, 1024, &bw) != FR_OK) {
    if (f_write(&f, bsram, size, &bw) != FR_OK || bw != size) {
        status("Write failure");
        uart_printf("Write failure, bw=%d\r\n", bw);
        r = 2;
        goto bsram_save_close;
    }
    // }
    snes_bsram_crc16 = newcrc;

bsram_save_close:
	f_close(&f);
	return r;
}

int backup_success_time;
void backup_process() {
    if (!snes_running || !option_backup_bsram || snes_ramsize == 0)
        return;
    int t = time_millis();
    if (t - snes_backup_time >= 10000) {
        // need to save
        int r;
        if(CORE_ID == CORE_SNES )
            r = backup_save(snes_backup_name, snes_ramsize);
        else if(CORE_ID == CORE_NES )
            r = save_bsram();
        else 
            return;
        if (r == 0)
            backup_success_time = t;
        if (backup_success_time != 0) {
            status("");
            printf("BSRAM saved %ds ago ", (t-backup_success_time)/1000);
            print_hex_digits(snes_bsram_crc16, 4);
        }
        snes_backup_time = t;
    }
}

#define CRC16 0x8005

uint16_t gen_crc16(const uint8_t *data, uint16_t size) {
    uint16_t out = 0;
    int bits_read = 0, bit_flag;

    /* Sanity check: */
    if(data == NULL)
        return 0;

    while(size > 0)
    {
        bit_flag = out >> 15;

        /* Get next bit: */
        out <<= 1;
        out |= (*data >> bits_read) & 1; // item a) work from the least significant bits

        /* Increment bit counter: */
        bits_read++;
        if(bits_read > 7)
        {
            bits_read = 0;
            data++;
            size--;
        }

        /* Cycle check: */
        if(bit_flag)
            out ^= CRC16;

    }

    // item b) "push out" the last 16 bits
    int i;
    for (i = 0; i < 16; ++i) {
        bit_flag = out >> 15;
        out <<= 1;
        if(bit_flag)
            out ^= CRC16;
    }

    // item c) reverse the bits
    uint16_t crc = 0;
    i = 0x8000;
    int j = 0x0001;
    for (; i != 0; i >>=1, j <<= 1) {
        if (i & out) crc |= j;
    }

    return crc;
}

int main() {
    CORE_ID = reg_core_id;
    overlay(1);

    // initialize UART
    reg_uart_clkdiv = 187; // 21505400 / 115200;

    // Init reg_load_bsram
    reg_load_bsram = 0;

    // Init system type
    reg_sys_type = (option_sys_type_is_pal ? (uint32_t)0x01 : (uint32_t)0x00);

    sd_init();
    delay(100);
    DEBUG("CORE_ID=%d\r\n", CORE_ID);
    
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
        switch(CORE_ID){
        case 1:
            print("=== Welcome to NESTang ===");
            break;
        case 2:
            print("~~~ Welcome to SNESTang ~~~");
            break;
        case 3:
            print("... Welcome to GBTang ...");
            break;
        default:
            print("ERR: undefined COREID");
            break;
        }


        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MAIN_OPTIONS_LOAD_ROM));
        print("1) Load ROM from SD card\n");
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MAIN_OPTIONS_LOAD_CORE));
        print("2) Select core\n");
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MAIN_OPTIONS_OPTIONS));
        print("3) Options\n");
        // cursor(2, 15);
        // print("4) Verify core\n");
        cursor(MENU_OPTIONS_OFFSET_COL1_X, (MENU_OPTIONS_OFFSET_Y+MAIN_OPTIONS_VERSION));
        print("Version: ");
        print(__DATE__);

        delay(300);

        int choice = 0;
        for (;;) {
            int r = joy_choice(12, 3, &choice, OSD_KEY_CODE);
            if (r == 1) break;
        }

        if (choice == MAIN_OPTIONS_LOAD_ROM) {
            int rom;
            delay(300);
            menu_loadrom(&rom);
        } else if (choice == MAIN_OPTIONS_LOAD_CORE) {
            menu_select_core(0);
        } else if (choice == MAIN_OPTIONS_OPTIONS) {
            delay(300);
            menu_options();
            continue;
        } else if (choice == 3) {
            menu_select_core(1);
        }
    }
}
