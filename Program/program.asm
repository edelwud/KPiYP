.model small
.stack 100h

.data
    BUFSIZ equ 256
    cmd_buffer db BUFSIZ dup(?)
    space db 80, 0, ' ', "$"
    exec_message db 80, 0, " executed", "$"
include sio.asm

.code
start:
    push @data
    pop ds

    call get_cmd_argument C, 0081h, 0080h, offset cmd_buffer, 1
    call printstring C, offset cmd_buffer

    call get_cmd_argument C, 0081h, 0080h, offset cmd_buffer, 2
    call printstring C, offset space
    call printstring C, offset cmd_buffer
    call printstring C, offset exec_message
    call printstring C, offset newline

    mov ah, 4ch
    int 21h
end start