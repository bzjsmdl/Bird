bits 32
org 0x1800
kernel_main:
    mov eax, system_call_main
    and eax, 0xFFFF
    mov word [address_low], ax

    mov eax, system_call_main
    shr eax, 16
    mov word [address_high], ax

    lidt [idt_descriptor]
    call shell
    hlt

idt_descriptor: 
    len equ 256*8 - 1
    dw len
    dd idt
times 512 - ($ - $$) db 0
idt:
	times 0x80 dq 0
	address_low dw 0
	dw 0x08
	db 0
	db 0xEE
	address_high dw 0
	times 256 - 0x81 dq 0
%include "bios/shell.asm"
%include "bios/system_call/system_call.asm"