org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;#
;# FAT!@ header
;#

jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'  ; 8 bye label
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
dbd_fat_count:              db 2
dbd_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880         ; 2880 * 512 = 1.44MB
bdb_media_description_type: db 0f0H         ; F0 = 3.5 floppy disk
bdb_sectors_per_fat:        dw 9            ; 9 sectors
bdb_sectors_per_track:      dw 18
bdb_heads:                   dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sectors_count:    dd 0

; ex boot record
ebr_drive_number:           db 0
                            db 0 ;reserved
ebd_signature:              db 29h
ebr_volume_id:              db 12h,34h,56h,78h  ; serial number
ebr_volume_label:           db 'WOWZER'    ; 11 bytes, padded with spaces automatically
ebr_system_id:              db 'FAT12   ' ; must be 8 bytes long


;
; code goes here
;

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

    ; read from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl
    mov ax, 1       ; LBA=1
    mov cl, 1       ; 1 sector to read
    mov bx, 0x7E00  ; data comes after the bootloader
    call disk_read


    mov si, msg_hello
    call puts

    jmp .halt

.halt:
    cli         ; disable interrupts
    jmp .halt


; Disk routines

; Converts an LBA address to CHS
; parameters
; - ax: LBA address
; returns
; - cs [bits 0-5]: sector number
; - cx [bits 6-15]: cylinder
; - dh: head

lba_to_chs:

    push ax
    push dx

    xor dx,dx   ; dx = 0
    div word [bdb_sectors_per_track] ; ax = LBA / sectorsPerTrack

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6           ; ch = cylinder
    or  cl, ah

    pop ax
    mov dl, al
    pop ax
    ret


; read sector from a disk
; parameters;
;   ax: LBA address
;   cl: number of sectors to read, < 128
;   dl: drive number
;   es:bs: memory address where to stored data to read is
disk_read:

    push ax     ; save registers to modify
    push bx
    push cx
    push dx
    push di

    push cx     ; save number of sectors to read
    call lba_to_chs
    pop ax

    mov ah, 02h
    mov di, 3       ; count to retry read
    int 13h

.retry:
    pusha
    stc
    int 13h
    jnc .done
    popa
    call disk_reset

    dec di
    test di,di
    jnz .retry

.fail:
    ; all attempts failed
    jmp floppy_error

.done:

    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


;
; Reset disk controller
; Parameters:
; dl: drive number

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h             ; wait for keypress
    jmp 0FFFFh:0        ;jump to beginning of BIOS, reboot



msg_read_failed:    db 'Read from daisk failed!', ENDL, 0
msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h