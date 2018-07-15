
;DATA LEFT BY MY FAT32Bootsector


;DAP for extended bios interrupts
%define DAP 0x7E00  ;DAP for Extended BIOS Interrupts
    %define Dsize 0x7E00
    %define Dnull 0x7E01
    %define Dsectors 0x7E02
    %define Doffset 0x7E04
    %define Dsegment 0x7E06
    %define Daddress 0x7E08
    ;End of DAP

%define BPB 0x7E10    ;(DWORD) LBA of BPB sector
%define FAT 0x7E14    ;(DWORD) LBA of first FAT sector
%define DATA 0x7E18   ;(QWORD) LBA of first DATA sector
%define BLOCK 0x7E20  ;(DWORD) Temporary value of LBA or cluster number
%define Secsize 0x7E24;(DWORD) Size of one sector(in bytes)
%define DEV 0x7E28    ;(BYTE)  Current device(for bios interrupts)
%define memBPB 0x8000 ;(Structure) address in memory of BIOS Parameter Block of partition we're booted of


;DATA set by "Proper bootloader"(this bootloader)

%define bytesPerCluster 0x7E29; (word) size of one cluster in bytes
%define clusSize 0x7E2B; (word) size of one cluster in 0x200 (512 for noobs) byte sectors

%define BootloaderSegment  0x1000   ; Address(segment) of this bootloader in memory
%define BufferSegment      0x2000   ; Address(segment) of buffer in memory(for storing temporary data)
%define KernelFileSegment  0x3000   ; Address(segment) of place in memory where Kernel file will be loaded
%define KernelFileOffset32 0x30000  ; Address(32bit, linear) of place in memory where Kernel file is loaded
%define BootloaderOffset32 0x10000  ; Address(32bit, linear) of this bootloader in memory

%define A20CheckLow 0x7E2D ; address(offset) of test DWORD in low memory for checking if a_20 line is unlocked
%define A20CheckHi  0x7E3D ; address(offset) of test DWORD after one megabyte for checking if a_20 line is unlocked

%define ELFAllEntryBytes 0x7E2D ; some temporary data for ELF parsing


;FAT BPB offsets:
%define jmpBoot    0x00; I3
%define OEMName    0x03; S8
%define BytsPerSec 0x0B; W
%define SecPerClus 0x0D; B
%define RsvdSecCnt 0x0E; W
%define NumFATs    0x10; B
%define RootEntCnt 0x11; W
%define TotSec16   0x13; W
%define Media      0x15; B
%define FATSz16    0x16; W
%define SecPerTrk  0x18; W
%define NumHeads   0x1A; W
%define HiddSec    0x1C; D
%define TotSec32   0x20; D
;F32 at offset 36
%define FATSz32    0x24; D
%define ExtFlags   0x28; W
%define FSVer      0x2A; W
%define RootClus   0x2C; D
%define FSInfo     0x30; W
%define BkBootSec  0x32; W
%define Reserved   0x34; S12
%define DrvNum     0x40; B
%define Reserved1  0x41; B
%define BootSig    0x42; B
%define VolID      0x43; D
%define VolLab     0x47; S11
%define FilSysType 0x52; S8
