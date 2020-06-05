.model small
.stack 100h
.data
    BUFSIZ equ 1024
    CMD_BUFSIZ equ 80

    file_path db CMD_BUFSIZ, 0, CMD_BUFSIZ dup(?)
    file_buffer db BUFSIZ dup(?)
    file_desc dw ?
    read_size dw ?
    read_bytes_buffer db CMD_BUFSIZ, 0, 4 dup("0"), "$"
    scan_empty_lines_buffer db CMD_BUFSIZ, 0, 4 dup("0"), "$"
    empty_lines dw 0
    new_line_ended db 1

    program_info_message db CMD_BUFSIZ, 0, "# New line counter", "$"
    cmd_process_message db CMD_BUFSIZ, 0, "Processing cmd arguments...", "$"
    file_path_message db CMD_BUFSIZ, 0, "Path from cmd: ", "$"
    file_success_opened_message db CMD_BUFSIZ, 0, "File success opened", "$"
    file_part_readed_message db CMD_BUFSIZ, 0, "Read bytes: ", "$"

    file_scanning_message db CMD_BUFSIZ, 0, "Scanning file...", "$"
    file_scanning_completed_message db CMD_BUFSIZ, 0, "Scanning completed, empty lines found: ", "$"

    file_close_message db CMD_BUFSIZ, 0, "Closing file...", "$"
    file_close_success_message db CMD_BUFSIZ, 0, "Successfully closed", "$"

    error_cmd_process_message db CMD_BUFSIZ, 0, "Cannot find cmd argument", "$"

    error_open_file_message db CMD_BUFSIZ, 0, "Cannot open file: ", "$"
    error_open_file_not_found_file_message db CMD_BUFSIZ, 0, "not found file", "$"
    error_open_file_not_found_path_message db CMD_BUFSIZ, 0, "not found path", "$"
    error_open_file_overflow_message db CMD_BUFSIZ, 0, "too many opened files", "$"
    error_open_file_access_denied_message db CMD_BUFSIZ, 0, "access denied", "$"
    error_open_file_access_mode_message db CMD_BUFSIZ, 0, "invalid access mode", "$"

    error_read_file_message db CMD_BUFSIZ, 0, "Cannot read file: ", "$"
    error_read_file_descriptor_message db CMD_BUFSIZ, 0, "invalid descriptor", "$"

    error_close_file_message db CMD_BUFSIZ, 0, "Cannot close file: ", "$"
    error_close_file_descriptor_message db CMD_BUFSIZ, 0, "invalid descriptor", "$"


include sio.asm

.code
start:
    push @data
    pop ds

    call printstring C, offset program_info_message
    call printstring C, offset newline


    call printstring C, offset cmd_process_message
    call printstring C, offset newline

    mov ax, 0080h
    mov bx, 0081h

    xor cx, cx

    call get_cmd_argument C, bx, ax, offset file_path, 1
    cmp dx, 0
    je error_cmd_process
    jne arguemnt_found
error_cmd_process:
    call printstring C, offset error_cmd_process_message
    call printstring C, offset newline
    jmp exit
arguemnt_found:
    call printstring C, offset file_path_message
    call printstring C, offset file_path
    call printstring C, offset newline

    call open_file C, offset file_path
    cmp dx, 0
    je error_open_file

    mov word ptr file_desc, ax
    jmp file_success_opened
error_open_file:
    call printstring C, offset error_open_file_message

    cmp ax, 02h
    je error_open_file_not_found_file
    jne error_open_file_next_1
error_open_file_not_found_file:
    call printstring C, offset error_open_file_not_found_file_message
    call printstring C, offset newline
    jmp exit
error_open_file_next_1:
    cmp ax, 03h
    je error_open_file_not_found_path
    jne error_open_file_next_2
error_open_file_not_found_path:
    call printstring C, offset error_open_file_not_found_file_message
    call printstring C, offset newline
    jmp exit
error_open_file_next_2:
    cmp ax, 04h
    je error_open_file_overflow
    jne error_open_file_next_3
error_open_file_overflow:
    call printstring C, offset error_open_file_overflow_message
    call printstring C, offset newline
    jmp exit
error_open_file_next_3:
    cmp ax, 05h
    je error_open_file_access_denied
    jne error_open_file_next_4
error_open_file_access_denied:
    call printstring C, offset error_open_file_access_denied_message
    call printstring C, offset newline
    jmp exit
error_open_file_next_4:
    cmp ax, 0Ch
    je error_open_file_access_mode
    jne error_open_file_next_5
error_open_file_access_mode:
    call printstring C, offset error_open_file_access_mode_message
    call printstring C, offset newline
    jmp exit
error_open_file_next_5:
    jmp exit
file_success_opened:
    call printstring C, offset file_success_opened_message
    call printstring C, offset newline

    call printstring C, offset file_scanning_message
    call printstring C, offset newline

    mov byte ptr [new_line_ended], 1
file_reader:
    call fill_file_buffer C, word ptr file_desc, offset file_buffer 
    cmp dx, 0
    je error_read_file

    cmp cx, 0
    je first_reading
    jmp continue_3
first_reading:
    cmp byte ptr [file_buffer], 10
    je increase_empty_lines
    jmp continue_3
increase_empty_lines:
    mov byte ptr empty_lines, 1
    mov byte ptr new_line_ended, 1
continue_3:
    inc cx

    mov word ptr read_size, ax
    jmp readed_file_part
error_read_file:
    call printstring C, offset error_read_file_message

    cmp ax, 06h
    je error_read_file_descriptor
    jmp exit
error_read_file_descriptor:
    call printstring C, offset error_read_file_descriptor_message
    call printstring C, offset newline
    jmp exit
readed_file_part:
    call printstring C, offset file_part_readed_message
    call number_to_string C, word ptr read_size, offset read_bytes_buffer
    call printstring C, offset read_bytes_buffer
    call printstring C, offset newline

    cmp word ptr read_size, 0
    jne read_more
    jmp continue
read_more:
    call count_empty_lines C, offset file_buffer, word ptr read_size, offset new_line_ended
    add word ptr empty_lines, dx
    call clean_file_buffer C, offset file_buffer

    jmp file_reader
continue:
    call printstring C, offset file_scanning_completed_message
    call number_to_string C, word ptr empty_lines, offset scan_empty_lines_buffer
    call printstring C, offset scan_empty_lines_buffer
    call printstring C, offset newline

    call printstring C, offset file_close_message
    call printstring C, offset newline

    call close_file C, word ptr file_desc
    cmp dx, 0
    je error_close_file
    jmp file_close_success
error_close_file:
    cmp ax, 06h
    je error_close_file_descriptor
    jmp exit
error_close_file_descriptor:
    call printstring C, offset error_close_file_descriptor_message
    call printstring C, offset newline
    jmp exit
file_close_success:
    call printstring C, offset file_close_success_message
exit:
    mov ah, 4ch
    int 21h
end start
