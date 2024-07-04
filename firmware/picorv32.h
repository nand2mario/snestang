#ifndef H_PICO32
#define H_PICO32

#include <stdint.h>
#include <string.h>
#include <stdlib.h>     // for atoi()

#define DEBUG(...) uart_printf(__VA_ARGS__)
// #define DEBUG(...) do {} while(0)

#define reg_textdisp            (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv         (*(volatile uint32_t*)0x02000010)
#define reg_uart_data           (*(volatile uint32_t*)0x02000014)
#define reg_spimaster_byte      (*(volatile uint32_t*)0x02000020)
#define reg_spimaster_word      (*(volatile uint32_t*)0x02000024)
#define reg_romload_ctrl        (*(volatile uint32_t*)0x02000030)
#define reg_romload_data        (*(volatile uint32_t*)0x02000034)
#define reg_joystick            (*(volatile uint32_t*)0x02000040)
#define reg_time                (*(volatile uint32_t*)0x02000050)
#define reg_cycle               (*(volatile uint32_t*)0x02000054)
#define reg_core_id             (*(volatile uint32_t*)0x02000060)
#define reg_spiflash_byte       (*(volatile uint32_t*)0x02000070)
#define reg_spiflash_word       (*(volatile uint32_t*)0x02000074)
#define reg_spiflash_ctrl       (*(volatile uint32_t*)0x02000078)
// Enhanced APU
#define reg_enhanced_apu        (*(volatile uint32_t*)0x02000080)
// Cheats
#define reg_cheats_enabled      (*(volatile uint32_t*)0x020000A0)
#define reg_cheats_loaded       (*(volatile uint32_t*)0x020000C0)
#define reg_cheats_3            (*(volatile uint32_t*)0x020000E0)
#define reg_cheats_2            (*(volatile uint32_t*)0x02000100)
#define reg_cheats_1            (*(volatile uint32_t*)0x02000120)
#define reg_cheats_0            (*(volatile uint32_t*)0x02000140)
#define reg_cheats_data_ready   (*(volatile uint32_t*)0x02000160)
// BSRAM
#define reg_save_bsram          (*(volatile uint32_t*)0x02000180)
#define reg_load_bsram          (*(volatile uint32_t*)0x020001A0)
// System type
#define reg_sys_type            (*(volatile uint32_t*)0x020001C0)
// Aspect Ratio
#define reg_aspect_ratio        (*(volatile uint32_t*)0x020001A0)



// Standard library for PicoRV32 RV32I softcore

// osd printing
extern void cursor(int x, int y);
extern int  printf(const char *fmt,...); /* supports %s, %d, %x */
extern int  getchar();
extern int  putchar(int c);
extern void print_hex(uint32_t v);
extern void print_hex_digits(uint32_t v, int n);
extern void print_dec(int v);
extern int  print(const char *s);
extern void clear();
extern void overlay(int on);
extern char *trimwhitespace(char *str);
extern void delay(int ms);

// uart
extern void uart_init(int clkdiv);    // baudrate = clock_frequency / clkdiv. clock_frequency = 21505400
extern int uart_putchar(int c);
extern void uart_print_hex(uint32_t v);
extern void uart_print_hex_digits(uint32_t v, int n);
extern void uart_print_dec(int v);
extern int uart_print(const char *s);
extern int uart_printf(const char *fmt,...);

// joystick input
extern void joy_get(int *joy1, int *joy2);

// display cursor and let user choose using joystick. 
// this returns immediately
// 0: no choice from user, 1: user chose *active, 2: next page, 3: previous page
extern int joy_choice(int start_line, int len, int *active, int osd_key_code);

// SD card access
extern int sd_init();   /* Return 0 on success, non-zero on failure */
extern uint8_t sd_send_command(uint8_t cmd, uint32_t arg);
extern int sd_readsector(uint32_t sector, uint8_t* buffer, uint32_t sector_count); /* 1:success, 0:failure*/
extern int sd_writesector(uint32_t sector, const uint8_t* buffer, uint32_t sector_count); /* 1:success, 0:failure*/

// communication with snes
extern void snes_ctrl(uint32_t ctrl);   // 1: start loading, 0: end loading
extern void snes_data(uint32_t data);   // 3 word (12-byte) header, followed by 4-byte data words
                                        // header #0: map_ctrl, rom_size, ram_size
                                        // header #1: rom_mask
                                        // header #2: ram_mask

// SPI flash
extern void spiflash_read(uint32_t addr, uint8_t *buf, int length); // read from SPI flash
extern void spiflash_write_enable();
extern void spiflash_write_disable();                               
extern void spiflash_sector_erase(uint32_t addr);                   // erase a 4KB sector
extern void spiflash_page_program(uint32_t addr, uint8_t *buf);     // program 256 bytes
extern uint8_t spiflash_read_status1();                             // [1]: write enable, [0]: busy
extern void spiflash_ready();                                       // wait until flash is not busy

inline int max(int x, int y) {
    if (x > y) return x;
    else       return y;
}

inline int min(int x, int y) {
    if (x < y) return x;
    else       return y;
}

inline int tolower(int c) {
    if (c >= 'A' && c <= 'Z')
        return c + ('a' - 'A');
    else
        return c;
}

inline uint32_t time_millis() {
    return reg_time;
}

inline uint32_t cycle_counter() {
    return reg_cycle;
}

// string functions
// #ifndef strstr
// char *strstr(char *haystack, char *needle);
// #endif

char *strcasestr(char *haystack, char *needle);

#endif