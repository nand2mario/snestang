#include "picorv32.h"
#include <stdarg.h>

int putchar(int c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
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

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	if (prompt)
		print(prompt);

	while (c == -1) {
		c = reg_uart_data;
	}
	return c;
}

int getchar()
{
	return getchar_prompt(0);
}

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

char *strchr(const char *s, int c) {
   while (*s) {
      if (*s == c)
         return (char *)s;
      s++;
   }
   return (char *)0;
}
