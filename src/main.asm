org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main

puts:
    ; save ther registers we will modify
    push si
    push ax

.loop:
    lodsb       ; load the next character in al
    or al, al   ; trigger flags using al to check if al is zero
    jz .done    ; if al = 0 the flag is triggered and we jump

    mov ah, 0x0e    ; select interrupt mode (write in tty mode)
    int 0x10        ; video interrupt write

    jmp .loop
.done:
    pop ax
    pop si
    ret

main:
    ; setup data segments
    mov ax, 0
    mov ds, ax
    mov es, ax

    ;setup stack
    mov ss, ax
    mov sp, 0x7C00  ; stack grows down so we have to place it lower in memory, if at top it can overwrite stuff

    mov si, msg_hello
    call puts

    hlt

.halt:
    jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h