bits 32
%include "bios/system_call/error.asm"
%include "bios/system_call/utils.asm"
system_call_main:
	push ds
	push es

	push eax
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	pop eax

	cmp eax, sclen
	jnb .icn
	jmp dword [system_call_table + eax * 4]
	.icn:
		mov dword [error], InvalidCallNumber
	system_call_return:
		pop es
		pop ds
		iret
	system_call_get_error:
		mov eax, dword [error]
		jmp system_call_return

system_call_table:
	dd system_call_return, system_call_get_error, system_call_putc, system_call_set_cursor,\
	   system_call_enabling_cursor, system_call_PS2_Keyword_get_scan_code, system_call_PS2_Keyword_get_scan_code_set,\
	   system_call_PS2_Keyword_set_scan_code_set
	sclen equ ($ - system_call_table) / 4
error dd NoError

; putc(bl : char, bh : sytle, ecx : offset)
system_call_putc:
	cmp ecx, 2000
	ja .io
	mov byte [0xB8000 + ecx * 2], bl
	mov byte [0xB8001 + ecx * 2], bh
	jmp system_call_return
	.io:
		mov dword [error], InvalidOffset
		xor eax, eax
		jmp system_call_return

; set_cursor(bx : pos) // bx = row * 80 + column
system_call_set_cursor:
	cmp bx, 2000
	ja .ip

	mov dx, 0x3D4
	mov al, 0xF
	out dx, al

	inc dx
	mov al, bl
	out dx, al

	dec dx
	mov al, 0xE
	out dx, al

	inc dx
	mov al, bh
	out dx, al
	jmp system_call_return

	.ip:
		mov dword [error], InvalidPosition
		xor eax, eax
		jmp system_call_return

; enabling_cursor(bl : start_scanline, bh : end_scanline)
system_call_enabling_cursor:
	mov dx, 0x3D4
	mov al, 0x0A
	out dx, al

	inc dx
	in al, dx
	and al, 0xC0
	or al, bl
	out dx, al
	
	dec dx
	mov al, 0x0B
	out dx, al

	inc dx
	in al, dx
	and al, 0xE0
	or al, bh
	out dx, al

	mov eax, 1
	jmp system_call_return

; PS2_Keyword_get_scan_code(ebx : set) -> eax(low), edx(high) : scancode
system_call_PS2_Keyword_get_scan_code:
	push ecx
	xor edx, edx
	xor eax, eax
	xor ecx, ecx
	cmp ebx, .len
	jnb .ips2kscs
	jmp dword [.table + ebx * 4]
	.set1:
		call wait_outbuf_full
		in al, 0x60
		mov byte [.scancode + edx], al
		inc edx
		test ecx, ecx
		jnz .set1_extension_scan_code
		cmp al, 0xE0
		je .set1_extension
		cmp al, 0xE1
		je .set1_pause
		jmp .return

		.set1_pause:
			mov dword [.scancode], 0xE1451DE1
			mov word [.scancode + 4], 0xC59D
			jmp .return
		.set1_extension:
			mov ecx, 1
			jmp .set1
		.set1_extension_scan_code:
			cmp al, 0x2A
			jz .return
			cmp al, 0xB7
			jz .return
			jmp .return
		.set1_print_screen_pressed:
			mov word [.scancode + 2], 0xAAE0
			jmp .return

		.set1_print_screen_released:
			mov word [.scancode + 2], 0x37E0
			jmp .return
	.set2:
		nop
	.set3:
		nop
	.return:
		pop ecx
		mov edx, dword [.scancode]
		mov eax, dword [.scancode + 4]
		jmp system_call_return
	.ips2kscs:
		mov dword [error], Invalid_PS_2_Keybroad_ScanCodeSet
		jmp .return
	.table: dd .return, .set1, .set2, .set3
	.len equ ($ - .table) / 4
	.scancode: dq 0

; PS2_Keyword_get_scan_code_set() -> al : translated_set
system_call_PS2_Keyword_get_scan_code_set:
	push edx
	xor eax, eax

	call wait_inbuf_empty
	mov al, 0xF0
	out 0x60, al


	call wait_outbuf_full
	in al, 0x60
	cmp al, 0xFA
	jne .gps2kr

	call wait_inbuf_empty
	xor al, al
	out 0x60, al

	call wait_outbuf_full
	in al, 0x60
	cmp al, 0xFA
	jne .gps2kr

	call wait_outbuf_full
	in al, 0x60

	.return:
		pop edx
		jmp system_call_return
	.gps2kr:
		xor eax, eax
		mov dword [error], Get_PS_2_KeybroadResend
		jmp .return

; PS2_Keyword_get_scan_code_set(al : raw_set)	
system_call_PS2_Keyword_set_scan_code_set:
	push edx
	xor eax, eax

	call wait_inbuf_empty
	mov al, 0xF0
	out 0x60, al

	call wait_outbuf_full
	in al, 0x60
	cmp al, 0xFA
	jne .gps2kr

	call wait_inbuf_empty
	pop eax
	out 0x60, al

	call wait_outbuf_full
	in al, 0x60
	cmp al, 0xFA
	jne .gps2kr

	.return:
		pop edx
		jmp system_call_return
	.gps2kr:
		xor eax, eax
		mov dword [error], Get_PS_2_KeybroadResend
		jmp .return
