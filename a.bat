@echo off
nasm -f bin .\bios\shell.asm -o .\shell.bin
nasm -f bin .\bios\system_call\system_call.asm -o .\system_call.bin
nasm -f bin .\bios\main.asm -o .\main.bin
nasm -f bin .\bios\kernel.asm -o .\kernel.bin
nasm -f bin .\bios\entry.asm -o .\disk.img
d:\qemu\qemu-system-x86_64.exe -hda .\disk.img -monitor stdio