#include "picorv32.h"

uint8_t flash_send(uint8_t x) {
    // uart_printf("flash_send: %d\n", x);
	reg_spiflash_byte = x;			// send
	return reg_spiflash_byte;		// receive
}

uint32_t flash_send_word(uint32_t x) {
    // uart_printf("flash_send_word: %x\n", x);
    reg_spiflash_word = x;
    return reg_spiflash_word;
}

uint8_t flash_receive() {
    return flash_send(0xff);
}

uint32_t flash_receive_word() {
    return flash_send_word(0xFFFFFFFF);
}

uint8_t flash_sendrecv(uint8_t x) {
    flash_send(x);
    return flash_receive();
}

void flash_readblock(uint8_t *ptr, int length) {
    int i = 0;
    // uart_printf("flash_readblock: %d\n", length);
    if ((((uint32_t)ptr) & 3) == 0) {   // aligned on word boundaries
        // transfer in 4-byte words. this is about twice as fast
        for (; i+4<=length; i+=4) {
            *(uint32_t *)ptr = flash_receive_word();
            ptr+=4;
        }
    }
    for (; i<length; i++) {
        *ptr++ = flash_receive();
    }
}

void spiflash_read(uint32_t addr, uint8_t *buf, int length) {
    // uart_printf("spiflash_read: %d\n", length);
    reg_spiflash_ctrl = 0;    // CS_N = 0
    // uart_printf("cs_n = 0\n");
    flash_send(0x03);         // read command
    flash_send(addr >> 16);   // address
    flash_send(addr >> 8);
    flash_send(addr & 0xff);
    flash_readblock(buf, length);
    reg_spiflash_ctrl = 1;    // CS_N = 1
}

void spiflash_write_enable() {
    reg_spiflash_ctrl = 0;    // CS_N = 0
    flash_send(0x06);
    reg_spiflash_ctrl = 1;    // CS_N = 1
}

void spiflash_write_disable() {
    reg_spiflash_ctrl = 0;    // CS_N = 0
    flash_send(0x04);
    reg_spiflash_ctrl = 1;    // CS_N = 1
}

// erase a 4KB sector
void spiflash_sector_erase(uint32_t addr) {
    spiflash_write_enable();
    reg_spiflash_ctrl = 0;    // CS_N = 0
    uint32_t x = 0x20;
    x |= ((addr >> 16) & 0xff) << 8;
    x |= ((addr >> 8) & 0xff) << 16;
    x |= (addr & 0xff) << 24;
    flash_send_word(x);
    // flash_send(0x20);
    // flash_send(addr >> 16);   // address
    // flash_send(addr >> 8);
    // flash_send(addr & 0xff);
    reg_spiflash_ctrl = 1;    // CS_N = 1
}

// program 256 bytes
void spiflash_page_program(uint32_t addr, uint8_t *buf) {
    spiflash_write_enable();
    reg_spiflash_ctrl = 0;    // CS_N = 0
    uint32_t x = 0x02;
    x |= ((addr >> 16) & 0xff) << 8;
    x |= ((addr >> 8) & 0xff) << 16;
    x |= (addr & 0xff) << 24;
    flash_send_word(x);
    for (int i = 0; i < 256; i+=4) {
        flash_send_word(*(uint32_t *)(buf+i));
    }
    // flash_send(0x02);
    // flash_send(addr >> 16);   // address
    // flash_send(addr >> 8);
    // flash_send(addr & 0xff);
    // for (int i = 0; i < 256; i++) {
    //     flash_send(buf[i]);
    // }
    reg_spiflash_ctrl = 1;    // CS_N = 1
}

// [1]: write enable, [0]: busy
uint8_t spiflash_read_status1() {
    reg_spiflash_ctrl = 0;    // CS_N = 0
    flash_send(0x05);
    uint8_t status = flash_receive();
    reg_spiflash_ctrl = 1;    // CS_N = 1
    // uart_printf("spiflash_read_status1: %x\n", status);
    return status;
}

void spiflash_ready() {
    int millis = time_millis();
    while (spiflash_read_status1() & 1) 
        if (time_millis() - millis > 1000) {
            uart_printf("spiflash_ready timeout\n");
            return;
        }
}