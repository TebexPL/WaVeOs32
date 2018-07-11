;DATA. this is where I store all error messages, strings, and predefined data for bootloader

noerror:    db 'No error at all.', 0x00

storageErrorStr: db 'Storage device error.', 0x00

badDataErrorStr: db 'Internal error.', 0x00

notFoundError: db 'OS kernel file was not found.', 0x00

badClusterError: db 'OS kernel file is probably corrupt.', 0x00

rebootStr: db ' press anything to reboot...', 0x00

filename: db kernFilename, 0x00
