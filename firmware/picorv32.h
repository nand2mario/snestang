#ifndef H_PICO32
#define H_PICO32

#include <stdint.h>
#include <string.h>

#define reg_textdisp (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
// #define reg_uart_data (*(volatile uint32_t*)0x02000008)
// #define reg_uart_data (*(volatile uint32_t*)0x02000010)

// Standard library for PicoRV32 RV32I softcore

extern void cursor(int x, int y);
extern int  printf(const char *fmt,...); /* supports %s, %d, %x */
extern int  getchar();
extern int  putchar(int c);
extern void print_hex(uint32_t v);
extern void print_dec(int v);
extern int  print(char *s);
// extern void* memset(void* s, int c, size_t n);
// extern void* memcpy(void * dst, void const * src, size_t len);
// extern int memcmp(const void *s1, const void *s2, size_t n);
// extern char *strchr(const char *s, int c);

// SD card access
extern int sd_init();   /* Return 0 on success, non-zero on failure */
extern uint8_t sd_send_command(uint8_t cmd, uint32_t arg);
extern int sd_readsector(uint32_t sector, uint8_t* buffer, uint32_t sector_count); /* 1:success, 0:failure*/
extern int sd_writesector(uint32_t sector, const uint8_t* buffer, uint32_t sector_count); /* 1:success, 0:failure*/

#endif