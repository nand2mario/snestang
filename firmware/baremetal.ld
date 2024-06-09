/*
 * linker control script for 'bare metal' executables.
 * Ensures that _start defined in start.S is put at address 0
 * Uses the first 2MB of RAM.
 */
MEMORY
{
    FLASH (RX): ORIGIN = 0x00000, LENGTH = 100K
    RAM  (RWX): ORIGIN = 100K, LENGTH = 0x1e7000
}
SECTIONS
{
    .text :
    {
        start.o (.text)
        *(.text)
        _end = .;           /* as expected by syscalls.c */
    } >FLASH

    /* global and static variable with initial values */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        . = ALIGN(4);
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */
        *(.sdata)           /* .sdata sections */
        *(.sdata*)          /* .sdata* sections */
        . = ALIGN(4);
        _edata = .;
    }

    /* global and static variables without initial values. initialized to 0 by start.S */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* start of bss, used by startup code */
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;         /* end of bss, used by startup code */
    }

    .heap :
    {
        . = ALIGN(4);
        _heap_start = .;    /* define a global symbol at heap start */
    }
}
