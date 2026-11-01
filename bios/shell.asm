bits 32
shell:
    call init
    
    push msg
    call print
    add esp, 4

    push file
    call print
    add esp, 4

    ret
data:
    msg db "Bird OS --- v 1.0.0", 10, 0
    file db "/root/> ", 0
    offset dd 0
; int init()
init:
    push ebx

    mov eax, 4
    mov bl, 14
    mov bh, 15
    int 80h

    .return:
        pop ebx
        ret
; int print(char* str) // return value is an offset
print:
    push ebp
    mov ebp, esp
    push ecx
    push ebx
    push esi
    push edx
    mov esi, dword [ebp + 8]
    xor ecx, ecx
    xor ebx, ebx
    mov edx, dword [offset]
    .main:
        mov bl, byte [esi + ecx]
        cmp bl, 0
        je .return
        cmp bl, 10
        je .nl

        push ecx
        mov eax, 2
        mov bh, 0x07
        add ecx, edx
        int 80h
        pop ecx

        .next:
            inc ecx
            jmp .main
        .nl:
            add edx, 80
            lea esi, [esi + ecx + 1]
            xor ecx, ecx
            jmp .main
    .return:
        add edx, ecx
        mov dword [offset], edx

        mov eax, 3
        mov ebx, edx
        int 80h

        pop edx
        pop esi
        pop ebx
        pop ecx
        pop ebp
        ret
