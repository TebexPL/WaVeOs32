;Include file with all offsets to data left by my FAT32Bootsector, and other offset defines
%include "Assembly/Include/Offsets.asm"

;Include file with assembly macros
%include "Assembly/Include/Macros.asm"

[map all labels.map]


;Setup DS segment for using data left by my FAT32Bootsector
  push 0x0000
  pop ds
;Setup of Stack - just to be sure
  cli
  push 0xFFFF
  pop sp
  sti

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
  error badDataErrorStr

  ;The end of loading file. Whole file is in memory
  .endOfFile:
  error noerror




%include "Assembly/Include/Routines.asm"


%include "Assembly/Include/Data.asm"
