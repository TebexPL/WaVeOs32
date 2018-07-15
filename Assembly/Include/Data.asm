;DATA. this is where I store all error messages, strings, and predefined data for bootloader

noerror:    db 'No error at all.', 0x00

storageError: db 'Storage device error.', 0x00

badDataError: db 'Internal error.', 0x00

notFoundError: db 'OS kernel file was not found.', 0x00

badClusterError: db 'OS kernel file is probably corrupt.', 0x00

badElfError: db 'OS kernel file is not compatible or corrupt.', 0x00

a20Error: db 'Could not unlock critical CPU function.', 0x00

protectedElfError: db 'ELF Error. Could not load operating system.', 0x00

rebootStr: db ' Press anything to reboot...', 0x00

filename: db kernFilename, 0x00

;Contains pre-set GDT table
GDTtable:
  .null: dq 0x0000000000000000
  .code: dq 0x00CF9C000000FFFF
  .data: dq 0x00CF92000000FFFF
  .tss:  dq 0x0000000000000000
  .none: dq 0x0000000000000000
         dq 0x0000000000000000
         dq 0x0000000000000000
         dq 0x0000000000000000

GDTR:
  .size: dw 0x003F
  .offset: dd (BootloaderSegment*0x10)+GDTtable
