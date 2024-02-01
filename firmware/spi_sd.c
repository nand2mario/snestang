
// Original author: Bruno Levy
// https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/FIRMWARE/LIBFEMTORV32/spi_sd.c
//
// Changes by nand2mario, 1/2014
// - Use byte-based PIO instead of bit-banging
// - Simplified initialization process

#include "picorv32.h"

// SD over SPI: https://onlinedocs.microchip.com/pr/GUID-F9FE1ABC-D4DD-4988-87CE-2AFD74DEA334-en-US-3/index.html?GUID-48879CB2-9C60-4279-8B98-E17C499B12AF
// http://www.dejazzer.com/ee379/lecture_notes/lec12_sd_card.pdf
// https://electronics.stackexchange.com/questions/77417/what-is-the-correct-command-sequence-for-microsd-card-initialization-in-spi
// send and receive a byte over SPI to sd card
uint8_t spi_send(uint8_t x) {
	reg_spimaster_byte = x;			// send
	return reg_spimaster_byte;		// receive
}

uint8_t spi_receive() {
    return spi_send(0xFF);
}

uint8_t spi_sendrecv(uint8_t x) {
    spi_send(x);
    return spi_receive();
}

void spi_readblock(uint8_t *ptr, int length) {
    int i;
    for (i=0;i<length;i++) {
        *ptr++ = spi_receive();
    }
}

void spi_writeblock(const uint8_t *ptr, int length) {
    int i;
    for (i=0;i<length;i++) {
        spi_send(*ptr++);
    }
}

#define CMD0_GO_IDLE_STATE              0
#define CMD1_SEND_OP_COND               1
#define CMD8_SEND_IF_COND               8
#define CMD17_READ_SINGLE_BLOCK         17
#define CMD24_WRITE_SINGLE_BLOCK        24
#define CMD32_ERASE_WR_BLK_START        32
#define CMD33_ERASE_WR_BLK_END          33
#define CMD38_ERASE                     38
#define ACMD41_SD_SEND_OP_COND          41
#define CMD55_APP_CMD                   55
#define CMD58_READ_OCR                  58

#define CMD_START_BITS                  0x40
#define CMD0_CRC                        0x95
#define CMD8_CRC                        0x87

#define OCR_SHDC_FLAG                   0x40
#define CMD_OK                          0x01

#define CMD8_3V3_MODE_ARG               0x1AA

#define ACMD41_HOST_SUPPORTS_SDHC       0x40000000

#define CMD_START_OF_BLOCK              0xFE
#define CMD_DATA_ACCEPTED               0x05

static int sdhc_card = 0;

uint8_t sd_send_command(uint8_t cmd, uint32_t arg) {
    uint8_t response = 0xFF;
    uint8_t status;

    // If non-SDHC card, use byte addressing rather than block (512) addressing
    if(!sdhc_card) {
        switch (cmd) {
            case CMD17_READ_SINGLE_BLOCK:
            case CMD24_WRITE_SINGLE_BLOCK:
            case CMD32_ERASE_WR_BLK_START:
            case CMD33_ERASE_WR_BLK_END:
		        arg *= 512;
		        break;
        }
    }

    spi_send(cmd | CMD_START_BITS);
    spi_send((arg >> 24));
    spi_send((arg >> 16));
    spi_send((arg >> 8));
    spi_send((arg >> 0));    

    // CRC required for CMD8 (0x87) & CMD0 (0x95) - default to CMD0
    spi_send((cmd == CMD8_SEND_IF_COND) ? CMD8_CRC : CMD0_CRC);    

    // Wait for response (i.e MISO not held high)
    int count = 0;
    while((response = spi_receive()) == 0xff) {
        if(count > 500) {
                break;
        }
        ++count;   
    }

    // CMD58 has a R3 response
    if(cmd == CMD58_READ_OCR && response == 0x00) {
        // Check for SDHC card
        status = spi_receive();
        if(status & OCR_SHDC_FLAG) {
                sdhc_card = 1;
        } else {
                sdhc_card = 0;
        }
        // Ignore other response bytes for now
        spi_receive();
        spi_receive();
        spi_receive();
    }

    // Additional 8 clock cycles over SPI
    spi_send(0xFF);

    return response;
}

int flag;

int sd_init() {
    int retries = 0;
    uint8_t response = 0xFF;
    uint8_t sd_version;

    retries = 0;
    do {
        response = sd_send_command(CMD0_GO_IDLE_STATE, 0);
        if(retries++ > 8) {
            DEBUG("SD init failure: CMD0\n");
            return -1;
        }
    } while(response != CMD_OK);

    spi_send(0xff);
    spi_send(0xff);

    // Set to default to compliance with SD spec 2.x
    sd_version = 2; 

    // Send CMD8 to check for SD Ver2.00 or later card
    flag = 1;
    retries = 0;
    do {
        // Request 3.3V (with check pattern)
        response = sd_send_command(CMD8_SEND_IF_COND, CMD8_3V3_MODE_ARG);
        if(retries++ > 8) {
            // No response then assume card is V1.x spec compatible
            sd_version = 1;
            break;
        }
    } while(response != CMD_OK);
   
    retries = 0;
    do {
        // Send CMD55 (APP_CMD) to allow ACMD to be sent
        response = sd_send_command(CMD55_APP_CMD,0);
        // delay(100);
        // Inform attached card that SDHC support is enabled
        response = sd_send_command(ACMD41_SD_SEND_OP_COND, ACMD41_HOST_SUPPORTS_SDHC);
        if(retries++ > 8) {
	        // CS_H(1);
            DEBUG("SD init failure: ACMD41\n");
	        return -2;
        }
    } while(response != 0x00);

    // Query card to see if it supports SDHC mode   
    if (sd_version == 2) {
        retries = 0;
        do {
	        response = sd_send_command(CMD58_READ_OCR, 0);
	        if(retries++ > 8)
	            break;
        } while(response != 0x00);
    } else {
       // Standard density only
       sdhc_card = 0;
    }

    DEBUG("SD init complete. sdhc_card=%d, sd_version=%d\n", sdhc_card, sd_version);
    return 0;
}

int sd_readsector(uint32_t start_block, uint8_t *buffer, uint32_t sector_count) {
    uint8_t response;
    uint32_t ctrl;
    int retries = 0;
    int i;
    DEBUG("sd_readsector: %d %d\n", start_block, sector_count);
    if (sector_count == 0)
        return 0;
    while (sector_count--) {
        // Request block read
        response = sd_send_command(CMD17_READ_SINGLE_BLOCK, start_block++);
        if(response != 0x00) {
            DEBUG("sd_readsector: Bad response %x\n", response);
            return 0;
        }

        // Wait for start of block indicator
        while(spi_receive() != CMD_START_OF_BLOCK) {
            // Timeout
            if(retries > 5000) {
                DEBUG("sd_readsector: Timeout\n");
                return 0;
            }
            ++retries;
        }

        // Perform block read (512 bytes)
        spi_readblock(buffer, 512);

        buffer += 512;

        // Ignore 16-bit CRC
        spi_receive();
        spi_receive();

        // Additional 8 SPI clocks
        spi_sendrecv(0xFF);
    }
    return 1;
}

int sd_writesector(uint32_t start_block, const uint8_t *buffer, uint32_t sector_count) {
    uint8_t response;
    int retries = 0;
    int i;

    DEBUG("sd_writesector: %d %d\n", start_block, sector_count);
    while (sector_count--) {
        // Request block write
        response = sd_send_command(CMD24_WRITE_SINGLE_BLOCK, start_block++);
        if(response != 0x00) {
            DEBUG("sd_writesector: Bad response %x\n", response);
            return 0;
        }

        // Indicate start of data transfer
        spi_send(CMD_START_OF_BLOCK);

        // Send data block
        spi_writeblock(buffer, 512);
        buffer += 512;

        // Send CRC (ignored)
        spi_send(0xff);
        spi_send(0xff);

        // Get response
        response = spi_receive(0xFF);

        if((response & 0x1f) != CMD_DATA_ACCEPTED) {
            DEBUG("sd_writesector: Data rejected %x\n", response);
            return 0;
        }

        // Wait for data write complete
        while(spi_sendrecv(0xFF) == 0) {
            // Timeout
	        if(retries > 5000) {
                DEBUG("sd_writesector: Timeout\n");
                return 0;
            }
	        ++retries;
        }

        // Additional 8 SPI clocks
        spi_send(0xff);

	    retries = 0;
	
        // Wait for data write complete
        while(spi_sendrecv(0xFF) == 0) {
            // Timeout
            if(retries > 5000) {
                DEBUG("sd_writesector: Timeout\n");
                return 0;
            }
            ++retries;
        }
    }
    return 1;
}