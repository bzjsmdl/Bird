bits 16
org 0x1000
xor eax, eax
mov es, ax
mov ds, ax
mov di, 0x2800
xor ebx, ebx
get_address_map:
	mov eax, 0x0000E820
	mov edx, 0x534D4150
	mov ecx, 20
	int 15h
	pushf
	cmp eax, 0x534D4150
	jne error
	pop ax
	test ax, 1 ; Why? if CF = 1, CF & 1 -> ZF = 1, but CF failed.
	jne error

	add di, 20
	inc word [num]

	test ebx, ebx
	jne get_address_map
main:
	mov bx, 0x1800
	mov ah, 2
	mov al, 7
	mov ch, 0
	mov cl, 3
	mov dl, 0x80
	mov dh, 0
	int 0x13
	test ah, ah
	jne error

	cli
	lgdt [gdt_descriptor]

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	
	jmp 0x08:init

gdt_descriptor:
	len equ end - gdt - 1
	dw len
	dd gdt

gdt:
	; start
	dq 0
	dq 0x00CF9A000000FFFF   ; kernel code
	dq 0x00CF92000000FFFF   ; kernel data
	dq 0x004096080000FFFF  ; kernel stack
	dq 0x00C0F2200000FFFF ; user data
	dq 0x00C0FA200000FFFF ; user code
	dq 0x0040F6280000FFFF  ; kernel stack
end:
	num dw 0
error:
	mov cx, msg_len
	xor bx, bx
	mov ax, 0xB800
	mov ds, ax
	xor ax, ax
	xor bp, bp
	.main:
		mov bp, bx
		shr bp, 1
		mov al, byte [msg + bp] 
		mov byte ds:[bx], al
		mov byte ds:[bx + 1], 0x0C
		add bx, 2
		loop .main
	hlt
	msg db "Error: The device dosen't supprt this OS!"
	msg_len equ $ - msg

bits 32
init:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ax, 0x18
	mov ss, ax
	mov esp, 0x00090000

	jmp 0x08:0x1800

	times 512 - ($ - $$) db 0