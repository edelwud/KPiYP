; Standart input/output
.model small

.data
    newline db 2, 2, 0Ah, 0Dh, "$"

.code
; Define print string function
; | input:
; string - string offset in memory
printstring proc pascal near
arg string:word
uses ax, dx
    add string, 2 ; header offset
    mov dx, string
    mov ah, 09h
    int 21h
    ret
endp

; Getting char procedure
; | output:
; al - printed char
getchar proc pascal near
uses bx
    push ax
    mov ah, 01h
    int 21h
    mov bl, al
    pop ax
    mov al, bl
    ret
endp

; Putting char to display
; | input:
; char - char to display
putchar proc pascal near
arg char:byte
uses ax, dx
    mov ah, 02h
    mov dl, char
    int 21h
    ret
endp

; Getting string from console
; | input:
; string - empty buffer string
; | output:
; string - buffer filled data
getstring proc pascal near
arg string:word
uses ax, bx
    mov ah, 0ah
    mov dx, string
    int 21h
    
    mov bx, dx
    xor cx, cx
    mov cl, byte ptr [bx + 1]
    add bl, cl
    mov byte ptr [bx + 2], "$"

    call printstring pascal, offset newline
    ret
endp

number_to_string proc C near
arg number:word, string:word
uses ax, bx, cx, dx
    mov ax, number
    mov bl, 10
    mov di, string
    add di, 2

    mov cx, 4
number_to_string_iter:
    div bl

    mov byte ptr [di], ah
    add byte ptr [di], "0"
    
    inc di
    xor ah, ah
loop number_to_string_iter

    mov di, string
    add di, 2
    mov si, string
    add si, 5
number_to_string_reverse:
    cmp di, si
    jae number_to_string_reverse_completed

    mov al, byte ptr [di]
    mov ah, byte ptr [si]
    mov byte ptr [si], al
    mov byte ptr [di], ah
    inc di
    dec si
    jmp number_to_string_reverse
number_to_string_reverse_completed:
    ret
endp

get_cmd_argument proc C near
arg location:word, len:word, dest:word, number:byte
uses ax, bx, cx, si
    mov bx, location
    mov dl, byte ptr es:[0080h]
    
    mov si, dest
    add si, 2

    xor cx, cx
get_cmd_argument_iter:
    mov ax, bx
    sub ax, location
    cmp al, dl
    jae get_cmd_argument_exit

    mov al, byte ptr es:[bx]

    cmp al, ' '
    jne get_cmd_argument_found

    

    inc bx
    jmp get_cmd_argument_iter
get_cmd_argument_found:
    inc cx

    cmp cl, number
    jne get_cmd_argument_skip
    je get_cmd_argument_found_iter
get_cmd_argument_skip:
    inc bx
    mov ax, bx
    sub ax, location

    cmp al, dl
    je get_cmd_argument_exit

    cmp byte ptr es:[bx], ' '
    jne get_cmd_argument_skip

    jmp get_cmd_argument_iter
get_cmd_argument_found_iter:
    mov al, byte ptr es:[bx]

    inc bx
    cmp al, ' '
    je get_cmd_argument_found_completed

    mov byte ptr [si], al
    inc si

    mov ax, bx
    sub ax, location

    cmp al, dl
    je get_cmd_argument_found_completed
    jmp get_cmd_argument_found_iter
get_cmd_argument_found_completed:
    mov byte ptr [si], "$"

    mov ax, si
    mov bx, dest
    add bx, 2
    
    sub ax, bx
    dec bx
    mov byte ptr [bx], al

    mov dx, 1
    ret
get_cmd_argument_exit:
    mov dx, 0
    ret
endp

open_file proc C near
arg file_path_ptr:word
uses bx, cx
    mov di, file_path_ptr
    inc di

    xor bx, bx
    mov bl, byte ptr [di]
    add di, bx
    inc di
    
    mov byte ptr [di], 0

    mov dx, file_path_ptr
    add dx, 2
    mov ah, 3dh
    mov al, 00b
    int 21h

    mov byte ptr [di], "$"

    jc open_file_error
    jmp open_file_exit
open_file_error:
    mov dx, 0
    ret
open_file_exit:
    mov dx, 1
    ret
endp

fill_file_buffer proc C near
arg file_descriptor:word, file_buffer_ptr:word
uses bx, cx
    mov ah, 3fh
    mov cx, BUFSIZ
    mov bx, file_descriptor
    mov dx, file_buffer_ptr
    int 21h
    jc fill_file_buffer_error
    jmp fill_file_buffer_exit
fill_file_buffer_error:
    mov dx, 0
    ret
fill_file_buffer_exit:
    mov dx, 1
    ret
endp

count_empty_lines proc C near
arg file_buffer_ptr: word, buflen: word, flag: word
uses ax, bx, cx
    xor dx, dx
    xor ax, ax
    mov ax, flag
    mov bx, file_buffer_ptr
count_empty_lines_iter:
    cmp byte ptr [bx], 10
    je count_empty_lines_found

    mov word ptr ax, 0
    inc bx
    inc cx
    cmp cx, buflen
    jne count_empty_lines_iter
    jmp count_empty_lines_exit
count_empty_lines_found:
    cmp word ptr ax, 1
    je count_empty_lines_found_new

    inc word ptr ax
    inc bx
    inc cx
    cmp cx, buflen
    jne count_empty_lines_iter
    jmp count_empty_lines_exit
count_empty_lines_found_new:
    inc dx
    inc bx
    inc cx
    cmp cx, buflen
    jne count_empty_lines_iter
    jmp count_empty_lines_exit
count_empty_lines_exit:
    ret
endp

close_file proc C near
arg descriptor:word
uses bx, cx
    mov ah, 3eh
    mov bx, descriptor
    int 21h
    jc close_file_error
    jmp close_file_exit
close_file_error:
    mov dx, 0
    ret
close_file_exit:
    mov dx, 1
    ret
endp

clean_file_buffer proc C near
arg file_buffer_ptr: word
uses ax, cx, es, di
    push @data
    pop es

    mov cx, BUFSIZ
    mov al, 0
    mov di, file_buffer_ptr

    rep stosb
    ret
endp