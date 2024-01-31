#include "picorv32.h"
#include <stdarg.h>
#include <limits.h>

int curx, cury;

void cursor(int x, int y) {
   curx = x;
   cury = y;
}

int _overlay_status;

void overlay(int on) {
   if (on)
      reg_textdisp = 0x01000000;
   else
      reg_textdisp = 0x02000000;
   _overlay_status = on;
}

int overlay_status() {
   return _overlay_status;
}

int putchar(int c)
{
	if (curx >= 0 && curx < 32 && cury >= 0 && cury < 28) {
      reg_textdisp = (curx << 16) + (cury << 8) + c;
      if (c >= 32 && c < 128)
         curx++;
   }
   // new line
   if (c == '\n') {
      curx = 2;
      cury++;
   }
   return c;
}

int print(char *p)
{
	while (*p)
		putchar(*(p++));
   return 0;
}

void print_hex_digits(uint32_t val, int nbdigits) {
   for (int i = (4*nbdigits)-4; i >= 0; i -= 4) {
      putchar("0123456789ABCDEF"[(val >> i) % 16]);
   }
}

void print_hex(uint32_t val) {
   print_hex_digits(val, 8);
}

void print_dec(int val) {
   char buffer[255];
   char *p = buffer;
   if(val < 0) {
      putchar('-');
      print_dec(-val);
      return;
   }
   while (val || p == buffer) {
      *(p++) = val % 10;
      val = val / 10;
   }
   while (p != buffer) {
      putchar('0' + *(--p));
   }
}

int printf(const char *fmt,...)
{
    va_list ap;

    for(va_start(ap, fmt);*fmt;fmt++) {
        if(*fmt=='%') {
            fmt++;
                 if(*fmt=='s') print(va_arg(ap,char *));
            else if(*fmt=='x') print_hex(va_arg(ap,int));
            else if(*fmt=='d') print_dec(va_arg(ap,int));
            else if(*fmt=='c') putchar(va_arg(ap,int));	   
            else if(*fmt=='b') print_hex_digits(va_arg(ap,int), 2);	      // byte
            else if(*fmt=='w') print_hex_digits(va_arg(ap,int), 4);	      // 16-bit word
            else putchar(*fmt);
        } else 
            putchar(*fmt);
    }
    va_end(ap);

    return 0;
}

void clear() {
   for (int i = 0; i < 28; i++) {
      cursor(0, i);
      for (int j = 0; j < 32; j++)
         putchar(' ');
   }
}

int delay_count;
void delay(int ms) {
	for (int i = 0; i < ms; i++) {
      delay_count = 0;
		for (int j = 0; j < 500; j++) {
			delay_count++;
		}
   }
}

void joy_get(int *joy1, int *joy2) {
   uint32_t joy = reg_joystick;
   *joy1 = (joy >> 16) & 0xfff;
   *joy2 = joy & 0xfff;
}

// (R L X A RT LT DN UP START SELECT Y B)
// overlay_key_code: 0xC for SELECT&START, 0x84 for SELECT/RB
int joy_choice(int start_line, int len, int *active, int overlay_key_code) {
   int joy1, joy2;
   int last = *active;
   joy_get(&joy1, &joy2);
   // cursor(20, 27);
   // print_hex_digits(joy1, 2);
   // print(" ");
   // print_hex_digits(joy2, 2);

   if ((joy1 == overlay_key_code) || (joy2 == overlay_key_code)) {
      overlay(!overlay_status());    // toggle OSD
      delay(300);
   }
   if (!overlay_status())           // stop responding when OSD is off
      return 0;

   if ((joy1 & 0x10) || (joy2 & 0x10)) {
      if (*active > 0) (*active)--;
   }
   if ((joy1 & 0x20) || (joy2 & 0x20)) {
      if (*active < len-1) (*active)++;
   }
   if ((joy1 & 0x40) || (joy2 & 0x40))
      return 3;      // previous page
   if ((joy1 & 0x80) || (joy2 & 0x80))
      return 2;      // next page
   if ((joy1 & 0x1) || (joy1 & 0x100) || (joy2 & 0x1) || (joy2 & 0x100))
      return 1;      // confirm

   cursor(0, start_line + (*active));
   print(">");
   if (last != *active) {
      cursor(0, start_line + last);
      print(" ");
      delay(100);     // button debounce
   }

   return 0;      
}

void snes_ctrl(uint32_t ctrl) {
   reg_romload_ctrl = ctrl;
}
extern void snes_data(uint32_t data) {
   reg_romload_data = data;
}

// char getchar_prompt(char *prompt)
// {
// 	int32_t c = -1;

// 	if (prompt)
// 		print(prompt);

// 	while (c == -1) {
// 		c = reg_uart_data;
// 	}
// 	return c;
// }

// int getchar()
// {
// 	return getchar_prompt(0);
// }

/* 
 * Needed to prevent the compiler from recognizing memcpy in the
 * body of memcpy and replacing it with a call to memcpy
 * (infinite recursion) 
 */ 
// #pragma GCC optimize ("no-tree-loop-distribute-patterns")

void* memcpy(void * dst, void const * src, size_t len) {
   uint32_t * plDst = (uint32_t *) dst;
   uint32_t const * plSrc = (uint32_t const *) src;

   // If source and destination are aligned,
   // copy 32s bit by 32 bits.
   if (!((uint32_t)src & 3) && !((uint32_t)dst & 3)) {
      while (len >= 4) {
	 *plDst++ = *plSrc++;
	 len -= 4;
      }
   }

   uint8_t* pcDst = (uint8_t *) plDst;
   uint8_t const* pcSrc = (uint8_t const *) plSrc;
   
   while (len--) {
      *pcDst++ = *pcSrc++;
   }
   
   return dst;
}

/*
 * Super-slow memset function.
 * TODO: write word by word.
 */ 
void* memset(void* s, int c, size_t n) {
   uint8_t* p = (uint8_t*)s;
   for(size_t i=0; i<n; ++i) {
       *p = (uint8_t)c;
       p++;
   }
   return s;
}

int memcmp(const void *s1, const void *s2, size_t n) {
   uint8_t *p1 = (uint8_t *)s1;
   uint8_t *p2 = (uint8_t *)s2;
   for (int i = 0; i < n; i++) {
      if (*p1 != *p2)
         return (*p1) < (*p2) ? -1 : 1;
      p1++;
      p2++;
   }
   return 0;
}

int strcmp(const char* s1, const char* s2)
{
   while(*s1 && (*s1 == *s2)) {
      s1++;
      s2++;
   }
   return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

char* strncat(char* destination, const char* source, size_t num)
{
   int i, j;
   for (i = 0; destination[i] != '\0'; i++);
   for (j = 0; source[j] != '\0' && j < num; j++) {
      destination[i + j] = source[j];
   }
   destination[i + j] = '\0';
   return destination;
}

char *strncpy(char* _dst, const char* _src, size_t _n) {
   size_t i = 0;
   char *r = _dst;
   while(i++ != _n && (*_dst++ = *_src++));
   return r;
}

char *strchr(const char *s, int c) {
   while (*s) {
      if (*s == c)
         return (char *)s;
      s++;
   }
   return (char *)0;
}

char *strrchr(const char *s, int c) {
   char *r = 0;
   do {
      if (*s == c)
         r = (char*) s;
   } while (*s++);
   return r;
}

size_t strlen(const char *s) {
   size_t r = 0;
   while (*s != '\0') {
      r++;
      s++;
   }
   return r;
}

int isspace(int c) {
	return (c == '\t' || c == '\n' ||
	    c == '\v' || c == '\f' || c == '\r' || c == ' ' ? 1 : 0);
}

char *trimwhitespace(char *str) {
   char *end;
   // Trim leading space
   while(isspace((unsigned char)*str)) str++;

   if(*str == 0)  // All spaces?
      return str;

   // Trim trailing space
   end = str + strlen(str) - 1;
   while(end > str && isspace((unsigned char)*end)) end--;

   // Write new null terminator character
   end[1] = '\0';

   return str;
}

int atoi(const char *str) {
   int sign = 1, base = 0, i = 0;
 
   // if whitespaces then ignore.
   while (str[i] == ' ') {
      i++;
   }
 
   // sign of number
   if (str[i] == '-' || str[i] == '+') {
      if (str[i] == '-')
         sign = -1;
      i++;
   }
 
   // checking for valid input
   while (str[i] >= '0' && str[i] <= '9') {
      // handling overflow test case
      if (base > INT_MAX / 10
         || (base == INT_MAX / 10 && str[i] - '0' > 7)) {
         if (sign == 1)
            return INT_MAX;
         else
            return INT_MIN;
      }
      base = 10 * base + (str[i++] - '0');
   }
   return sign == -1 ? -base : base;
}