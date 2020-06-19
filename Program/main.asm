.model small
.stack 100h

zero segment
zero ends

.data
    program_seg_ptr dw ?
    program_seg_offset dw ?
    code_seg_ptr dw ?
    num db 4 dup("0"), "$"
    path db "D:/dist/program.exe", 0
    EPB db 18 dup(?), 
    param db 13, " Program 0000"

    number_buffer db 80, 0, 79 dup(?), "$"

    welcome_message db 80, 0, "# Program Executor", "$"
    resize_memory_block_message db 80, 0, "> Resizing memory block... ", "$"
    loading_program_message db 80, 0, "> Loading program... ", "$"

    number_exec_prog_message db 80, 0, "Enter number of exec programs [0-255]: ", "$"

    input_error_message db 80, 0, "Input error, range [0-255]", "$"
    success_message db 80, 0, "Success", "$"
    error_message db 80, 0, "Error", "$"

    error_file_not_found_message db 80, 0, ": file not found", "$"
    error_no_access_message db 80, 0, ": no access", "$"
    error_no_memory_message db 80, 0, ": no free memory", "$"
    error_enviroment_message db 80, 0, ": rediculous enviroment", "$"
    error_format_message db 80, 0, ": rediculous format", "$"
include sio.asm

.code
start:
    push ds
    push @data
    pop ds

    call printstring C, offset welcome_message
    call printstring C, offset newline
    call printstring C, offset resize_memory_block_message
    pop ax
    mov bx, zero
    sub bx, ax
    call resize_memory_block C, es, bx
    cmp dx, 0
    je resize_memory_block_error_case
    jmp resize_memory_block_success
resize_memory_block_error_case:
    call printstring C, offset error_message
    call printstring C, offset newline
    jmp exit
resize_memory_block_success:
    call printstring C, offset success_message
    call printstring C, offset newline
    mov program_seg_ptr, ax

    call printstring C, offset number_exec_prog_message
    call get_cmd_argument C, 0081h, 0080h, offset number_buffer, 1
    cmp dx, 0
    je input_error
    jmp start_processing
input_error:
    call printstring C, offset input_error_message
    jmp exit
start_processing:
    call printstring C, offset number_buffer
    call getint C, offset number_buffer
    call printstring C, offset newline

    cmp dx, 0
    je input_error

    mov cx, ax
    cmp cx, 0
    jne program_exec_iter
    jmp exit
program_exec_iter:
    call number_to_string C, cx, offset param + 8
    call load_and_exec_program C, offset path, offset param, offset EPB
    call printstring C, offset loading_program_message
    cmp dx, 0
    je program_exec_error
    jmp program_exec_iter_continue
program_exec_error:
    call printstring C, offset error_message
    call printstring C, offset newline
    jmp exit
program_exec_iter_continue:
    call printstring C, offset success_message
    call printstring C, offset newline

    dec cx
    cmp cx, 0
    je exit
    jmp program_exec_iter
exit:
    mov ah, 4ch
    int 21h
end start
