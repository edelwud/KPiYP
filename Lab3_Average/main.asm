.model small
.stack 100h
.386

.data
    define_number_count db 80, 0, "Enter numbers count: ", "$"
    define_retry db 80, 0, "Retry", 0Ah, 0Dh, "$"
    define_elements_count db 80, 0, "Elements count: ", "$"
    define_elements_sum db 80, 0, "Elements sum: ", "$"
    define_average_result db 80, 0, "Average: ", "$"
    define_error_message db 80, 0, "Error!", "$"
    define_entering_symbol dw ">"

    numbers_count_string db 80, 0, 79 dup(?)
    numbers_count_buffer db 80, 0, 79 dup(?)
    numbers_count db ?

    result_number_string db 80, 0, 79 dup(?)
    result_number dw 0, 0

    buffer db 80, 0, 79 dup(?)
    buffer_number db 80, 0, 79 dup(?)

    division_buffer db 80, 0, 79 dup(?)
    division_integer db 80, 0, 79 dup(?)
    division_factorial db 80, 0, 79 dup(?)

include sio.asm

.code
exit_2:
    call printstring pascal, offset define_error_message
    mov ah, 4ch
    int 21h
start:
    mov ax, @data
    mov ds, ax

    call printstring pascal, offset define_number_count
    call getnumber pascal, offset buffer, offset numbers_count_string
    call number_parser pascal, offset numbers_count_string
    call print_number pascal, dx, ax, offset numbers_count_buffer

    call printstring pascal, offset define_elements_count
    call printstring pascal, offset numbers_count_buffer
    call printstring pascal, offset newline
    mov cx, ax
    cmp cx, 0
    je exit_2
    push cx
    iter:
        jmp readvalue
        error:
            call printstring pascal, offset define_retry
        readvalue:
            call putchar pascal, define_entering_symbol
            call getnumber pascal, offset buffer, offset buffer_number
            call number_parser pascal, offset buffer_number
            cmp bx, 0
            je error

            cmp word ptr result_number, dx
            je adding
            jne substruction
            adding:
                add word ptr result_number[2], ax
                jmp complete
            substruction:
                cmp word ptr result_number[2], ax
                jb change_sign
                jmp subbing
                change_sign:
                    cmp word ptr result_number, 0
                    je set_null
                    mov word ptr result_number, 0
                    jmp swap
                    set_null:
                        mov word ptr result_number, 1
                    swap:
                        sub ax, word ptr result_number[2]
                        mov word ptr result_number[2], ax
                        jmp complete
                subbing:
                    sub word ptr result_number[2], ax
    complete:
        loop iter
    
    call printstring pascal, offset define_elements_sum
    call print_number pascal, word ptr result_number[0], word ptr result_number[2], offset result_number_string
    call printstring pascal, offset result_number_string
    call printstring pascal, offset newline

    pop ax
    call printstring pascal, offset define_average_result
    call division pascal, word ptr result_number[0], word ptr result_number[2], ax, offset division_buffer

exit:
    mov ah, 4ch
    int 21h
end start