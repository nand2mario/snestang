
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

FATFS fs;

int main() {
	uint8_t a, b, c, d;
	a = 1; b = 2; c = 3; d = 4;
	reg_uart_clkdiv = 94;       // 10800000 / 115200

    cursor(2, 10);
	//     01234567890123456789012345678901
    print("~~~ Welcome to SoCDEMO ~~~");
	cursor(2, 12);
	print("1) Test SD card\n");
	cursor(2, 13);
	print("2) List root\n");
	cursor(2, 15);
	print("Version: ");
	print(__DATE__);

	cursor(2, 27);
	print("Init SD card... ");
	f_mount(&fs, "", 0);
	print("done");

	while (1) {
	}

}