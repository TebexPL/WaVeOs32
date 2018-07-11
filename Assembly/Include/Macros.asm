;Macros help with using routines. macros preserve register values automatically, and even have predefined values for registers before calling routines

;comments before each macro shows how to use it


;strOut 'offset', 'segment'             <- segment is optional(default value is this bootloader's segment)
;EXAMPLE: strOut noerror                <- Displays some text on the screen
%macro strOut 1-2 BootloaderSegment
  push bx
  push es
  push %2
  pop es
  mov bx, %1
  call strOutRoutine
  pop es
  pop bx
  %endmacro


;loadSectors 'LBA', 'Segment', 'Offset', 'numOfSectors'     <- Segment, offset and number of sectors are optional

;(segment and offset are Buffer in default, and number of sectors is default one)

;EXAMPLE: loadSectors 0x00000000                           <- Loads first sector from boot device into Buffer
%macro loadSectors 1-4 BufferSegment, 0x0000, 0x0001
  push eax
  push es
  push di
  push dx

  mov eax, %1
  push %2
  pop es
  mov di, %3
  mov dx, %4
  call loadSectorsRoutine

  pop dx
  pop di
  pop es
  pop eax
  %endmacro

;loadCluster 'clusterNum', 'segment', 'offset'         <- Segment and offset are optional (in default segment and offset are set to Buffer)
;EXAMPLE: loadCluster 0x00000002               <- Loads third cluster from boot partition(FAT32)
%macro loadCluster 1-3 BufferSegment, 0x0000
  push eax
  push es
  push di

  mov eax, %1
  push %2
  pop es
  mov di, %3
  call loadClusterRoutine
  pop di
  pop es
  pop eax
  %endmacro

;error 'errrorMessage'            <-Displays error message and waits for user input. after user input, it reboots the computer
;EXAMPLE: error noerror       <-Displays No error message, waits for user input and after this, reboots computer
%macro error 1
  strOut %1
  strOut rebootStr
  xor ah, ah
  int 0x16
  mov al, 0xFE
  out 0x64, al
  jmp $
  %endmacro

;This macro is made specifically for comparing filename in directory entry, with kernel filename in memory
;filenameCmp '8.3FilenameOffset', 'Segment'    <- Segment is optional
%macro filenameCmp 1-2 BufferSegment
  push es
  push di
  push %2
  pop es
  mov di, %1
  call filenameCmpRoutine

  pop di
  pop es
  %endmacro

;nextClusterNumber 'currentClusterNumber'     <-loads next FAT32 cluster number of the same file
;EXAMPLE: nextClusterNumber 0x00000002    <- loads next cluster number into EAX

;Return value is stored in EAX
%macro nextClusterNumber 1
  mov eax, %1
  call nextClusterNumberRoutine
  %endmacro
