;Include file with all offsets to data left by my FAT32Bootsector, and other offset defines
%include "Assembly/Include/Offsets.asm"

;Include file with assembly macros
%include "Assembly/Include/Macros.asm"

[map all labels.map]
;Set segment registers
;And set things which require BIOS interrupts before entering Protected mode
Setup:
  ;Setup DS segment for using data left by my FAT32Bootsector
  push 0x0000
  pop ds
  ;Setup of Stack - just to be sure
  cli
  push 0x0000
  pop ss
  push 0xFFFF
  pop sp
  sti
  ;Set video mode(if bootloader needs to print in protected mode)
  mov ax, 0x0007
  int 0x10

;Load Kernel's ELF32 file from boot FAT32 partition
LoadKernelFile:
  ;Calculate sectors per cluster
  xor eax, eax
  mov al, byte[memBPB+SecPerClus]
  mov bx, word[memBPB+BytsPerSec]
  mul bx
  ;Save bytes per cluster value for later use
  mov word[bytesPerCluster], ax

  mov bx, 0x200
  div bx
  push ax
  ;if calculated value doesn't look correct - display error and exit
  cmp dx, 0x0000
  jne .errorBadData

  pop ax
  mov word [clusSize], ax
  ;Setup segments and registers for buffer
  push BufferSegment
  pop es
  mov dword[BLOCK], 0x00000002
  xor di, di
  ;Search root directory for kernel file
  .rootDirSearch:
  loadCluster dword[BLOCK]
  mov cx, word[bytesPerCluster]
  ;Search current root directory cluster for kernel file
  .clusterSearch:
    ;If whole cluster was searched - load next one
    cmp di, cx
    je .nextCluster
    ;If directory entry is free, just skip it - no need to check filenames
    cmp byte[es:di], 0xE5
    je .nextEntry
    ;If the last directory entry was checked - display error and exit
    cmp byte[es:di], 0x00
    je .fileNotFound
    ;Check if entry has attributes: DIRECTORY or VOLUME_ID
    mov al, byte[es:di+0x0B]
    and al, 0b00011000
    cmp al, 0x00
    ;If it has - skip to next entry
    jne .nextEntry
    ;If entry is valid - check if kernel filename matches entry filename
    filenameCmp di
    cmp al, 0xFF
    ;If it does - file was found, jump to load procedure
    je .fileFound
    ;If it doesn't - check set up next entry to check
    .nextEntry:
      add di, 0x20
      jmp .clusterSearch

  ;Calculate next cluster number of root directory
  .nextCluster:
    nextClusterNumber dword[BLOCK]
    ;If cluster is corrupt - display error and exit
    cmp eax, 0x0FFFFFF7
    je .badCluster
    ;If root directory ended - file wasn't found.  jump to notFound procedure
    cmp eax, 0x0FFFFFF7
    ja .fileNotFound
    ;If next cluster number is valid - save it, and jump to searching that cluster
    mov dword[BLOCK], eax
    jmp .clusterSearch

    ;If file was found, just load it into memory
  .fileFound:
    ;Get first cluster number of the file from kernels directory entry
    xor eax, eax
    mov ax, word [es:di+0x14]
    shl eax, 0x10
    mov ax, word [es:di+0x1A]
    ;Setup register - A buffer for loading clusters
    mov cx, KernelFileSegment
    ;In this loop - just load cluster, calculate next cluster number and check if file ended or is corrupt
    .loop:
      loadCluster eax, cx
      nextClusterNumber eax
      ;check if file is corrupt
      cmp eax, 0x0FFFFFF7
      je .badCluster
      ;check if file ended
      cmp eax, 0x0FFFFFF7
      ja .endOfFile
      ;Set buffer right after loaded cluster - for the next cluster
      mov bx, word[bytesPerCluster]
      shr bx, 0x04
      add cx, bx
      jmp .loop

  ;If there was a bad cluster - display error message and exit
  .badCluster:
  error badClusterError

  ;If file wasn't found - display error message and exit
  .fileNotFound:
  error notFoundError

  ;If there was a corrupted cluster - display error message and exit
  .errorBadData:
  error badDataError

  ;The end of loading file. Whole file is in memory
  .endOfFile:

  .checkElfValid:
  ;Setup of registers for checking ELF file
  push KernelFileSegment
  pop es
  ;Checking if ELF is valid, and compatible
  cmp byte[es:0x0000], 0x7F ;Magic number(s)
  jne .badElf
  cmp byte[es:0x0001], 'E'
  jne .badElf
  cmp byte[es:0x0002], 'L'
  jne .badElf
  cmp byte[es:0x0003], 'F'
  jne .badElf
  cmp byte[es:0x0004], 0x01 ;32Bit architecture
  jne .badElf
  cmp byte[es:0x0005], 0x01 ;Little endian
  jne .badElf
  cmp word[es:0x0012], 0x0003 ;x86 instruction set
  jne .badElf
  jmp .goodElf

  .badElf:
    error badElfError

  .goodElf:
;Set registers, etc. before entering Protected mode
ProtectedModeSetup:
  .disableInterrupts:
    cli
    mov al, 0x80
    out 0x70, al
  .A20Unlock:
    call checkA20
    jc .A20Unlocked
    .BIOSMethod:
      ;Use BIOS interrupt
      mov ax, 0x2401
      int 0x15
      ;Check if this method worked
      call checkA20
      jc .A20Unlocked
    .8042Method:
      ;Use 8042 keyboard controller
      ;Read actual controller output port state
      ps2OutPortIn
      ;Change A20 gate to be enabled
      or al, 0x03
      ;Write controller output port state with a20 enabled
      ps2OutPortOut
      call ps2WaitIn
      ;check if this method worked
      call checkA20
      jc .A20Unlocked
    .fastA20:
      ;Try using fast a20 method
      in al, 0x92
      or al, 2
      out 0x92, al
      ;check if this method worked
      call checkA20
      jc .A20Unlocked

    sti
    error a20Error

    .A20Unlocked:
  ;After A20 line is enabled, enter protected mode
  .loadGDT:
    ;Setup of segment register
    push BootloaderSegment
    pop ds
    ;Loading GDTR
    lgdt [GDTR]
    ;Seting control registerto protected mode
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax
    ;A long jump to set CS selector
    jmp 0x08:dword 0x10000+ProtectedMode

BITS 32
;Set rest of segment registers after entering protected mode
ProtectedMode:
  ;Set rest of segment registers' selectors
  mov ax, 0x0010
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  mov esp, 0x00010000
;Parse kernel's ELF file
ParseKernelELF:
  xor eax,eax
  mov ax, word[KernelFileOffset32+0x2A] ;Load number of bytes per program header entry
  mul word[KernelFileOffset32+0x2C] ;multiply by number of program header entries
  mov word[ELFAllEntryBytes], ax
  mov word[ELFAllEntryBytes+2], dx ;Save calculated value for later
  xor ebx, ebx
  ;check If current program header entry isn't null or incompatible
  .checkHeader:
    mov edi, dword [KernelFileOffset32+0x1C] ;Program header table offset
    cmp dword [KernelFileOffset32+ebx+edi], 0x00000000  ; current header segment type - if zero, skip
    je .nextHeader
    cmp dword [KernelFileOffset32+ebx+edi], 0x00000004 ; current header segment type - if 4, skip
    je .nextHeader
    cmp dword [KernelFileOffset32+edi+ebx], 0x00000001 ; current header segment type - iif not 1, error
    jne .elfError
  ;Setup of registers for clearing program's space in memory
  .clearMemPrep:
    xor al, al
    mov ecx, dword [KernelFileOffset32+edi+ebx+0x14]  ;Size of executable in memory
    mov edi, dword [KernelFileOffset32+edi+ebx+0x08]  ;offset in memory to load executable
  ;Loop clearing program's space in memory
  .clearMem:
    stosb
    loop .clearMem
  ;Setup of registers for copying program's data
  .copyProgramPrep:
    mov edi, dword [KernelFileOffset32+0x1C]
    mov ecx, dword [KernelFileOffset32+edi+ebx+0x10] ;Size of executable in file

    mov esi, KernelFileOffset32
    add esi, dword [KernelFileOffset32+edi+ebx+0x04] ;Offset in file to load executable from

    mov edi, dword [KernelFileOffset32+edi+ebx+0x08] ;Offset in memory to load executable into
  ;Loop copying current part of executable into correct place in memory
  .copyProgram:
    lodsb
    stosb
    loop .copyProgram
  ;Just checks if it wasn't the last program header entry
  ;If it wasnt the last one - select next program header entry
  .nextHeader:
    xor eax,eax
    mov ax, word[KernelFileOffset32+0x2A]
    add ebx, eax
    cmp ebx, dword[ELFAllEntryBytes]
    je ParsedElf
    jmp .checkHeader

    ;If elf is wrong in some way or another
    .elfError:
      ;Print error message, and enter infinite loop
      .printPrep:
        mov esi, BootloaderOffset32
        add esi, protectedElfError
        mov ah, 0x01
        mov edi, 0xB0000
      .printLoop:
        lodsb
        cmp al, 0x00
        je $
        stosw
        jmp .printLoop




  ;After parsing elf - jump to Kernel's entry point
;after parsing ELF, jump to Kernel's entry point
ParsedElf:
  mov ebx, dword[KernelFileOffset32+0x18]
  jmp ebx
  ;END OF BOOTLOADER


BITS 16
%include "Assembly/Include/Routines.asm"


%include "Assembly/Include/Data.asm"
