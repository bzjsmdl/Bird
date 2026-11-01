bits 16
org 0x7c00

; init
mov ax, 0xB800
mov es, ax
mov ds, ax
mov cx, 2000
mov ax, 0x0720
xor di, di
cld
rep stosw

xor ax, ax
mov es, ax
mov ss, ax
mov sp, 0x8000

; ready go to bootloader -- Open A20 Line
cli      ; disable interrupts

call wait_inbuf_empty ; wait for input buffer to become empty
mov al, 0xAD
out 0x64,al     ; disable keyboard

call wait_inbuf_empty
mov al, 0xD0
out 0x64, al  ; write a command

call wait_outbuf_full  ; wait for output buffer to become full
in al, 0x60
push ax    ; read 0x60 port and save it

call wait_inbuf_empty
mov al, 0xD1   
out 0x64, al    ; write a command

call wait_inbuf_empty
pop ax
or al, 2
out 0x60, al   ; set 0x60 port's bit 1(second bit) to open A20

call wait_inbuf_empty
mov al, 0xAE  
out 0x64, al    ; reactivate keyboard
 
call wait_inbuf_empty
sti    ; reactivate interrupts

mov bx, 0x1000
mov ah, 2
mov al, 1
mov ch, 0
mov cl, 2
mov dh, 0
mov dl, 0x80
int 0x13
test ah, ah
jnz error

jmp 0:0x1000

wait_inbuf_empty:
    in al, 0x64
    test al, 2
    jnz wait_inbuf_empty 
    ret
wait_outbuf_full:
    in al, 0x64
    test al, 1
    jz wait_outbuf_full
    ret
error:
    mov byte ds:[0], 'E'
    mov byte ds:[1], 0x0C
    hlt
times 510 - ($ - $$) db 0
dw 0xAA55
incbin "main.bin"
incbin "kernel.bin"