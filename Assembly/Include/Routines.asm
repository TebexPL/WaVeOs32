;ROUTINES which take care of some smaller jobs
;Comments before each routine explain which registers have to be set before calling theese routines
;or which registers have value from routine after it ends executing



;EAX - cluster numner
;es:di - target segment:offset
loadClusterRoutine:
  push ebx

  and eax, 0x0FFFFFFF

  xor ebx, ebx
  mov bx, word [clusSize]
  mul ebx
  add eax, dword[DATA]
  loadSectors eax, es, di, bx


  pop ebx
  ret

;DX - sectors
;es:di - seg:off
;eax - LBA
loadSectorsRoutine:
  ;preserve non specified register
  push cx
  ;Set up DAP
  mov word [Dsectors], dx
  mov word [Doffset], di
  mov word [Dsegment], es
  mov dword [Daddress], eax
  mov dword [Daddress+4], 0x00000000
  ;Set loop for retrying after error
  mov cx, 0x0005
  ;Loop in which actual bios call is used
  .repeat:
    cmp cx, 0x0000
    je .errorHW
    ;Setup for bios interrupt
    mov ah, 0x42
    mov dl, byte[DEV]
    mov si, DAP
    ;Decrease loop counter
    dec cx
    ;Actual bios call
    int 0x13
    ;If error occurs, retry
    jc .repeat
    ;If no error - restore preserved register and return form procedure
    pop cx
    ret

  ;If after retrying a few times, the error still occurs - display error message and halt
  .errorHW:
    error storageErrorStr

;es:bx - string address
strOutRoutine:
  push ax
  mov ah, 0x0E
  .loop:
    mov al, byte[es:bx]
    cmp al, 0x00
    je .end
    int 0x10
    inc bx
    jmp .loop

  .end:
    pop ax
    ret

;es:di - filename segment:offset

;RETURN: al - 0x00=not equal, 0xFF equal
filenameCmpRoutine:
  push si
  push cx
  push ds
  push di
  push 0x1000
  pop ds
  mov si, filename
  mov cx, 0x000B
  .loop:
  lodsb
  cmp byte[es:di], al
  jne .notEq
  inc di
  loop .loop


  .eq:
    pop di
    pop ds
    pop cx
    pop si
    mov al, 0xFF
    ret

  .notEq:
    pop di
    pop ds
    pop cx
    pop si
    mov al, 0x00
    ret

;EAX - current cluster number

;RETURN: eax - next cluster number
nextClusterNumberRoutine:
  push ecx
  push edx
  push es

  and eax, 0x0FFFFFFF

  xor ecx, ecx
  mov cl, 0x04
  mul ecx
  mov ecx, 0x00000200
  div ecx
  add eax, dword[FAT]
  push 0x2000
  pop es
  loadSectors eax, es
  mov eax, dword [es:edx]
  and eax, 0x0FFFFFFF

  pop es
  pop edx
  pop ecx
  ret
