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

alloc_memory_block proc C near
arg block_size: word
    mov ah, 48h
    mov bx, block_size
    int 21h
    jc alloc_memory_block_error
    jmp alloc_memory_block_exit
alloc_memory_block_error:
    mov dx, 0
    ret
alloc_memory_block_exit:
    mov dx, 1
    ret
endp

resize_memory_block proc C near
arg seg_ptr: word, block_size: word
uses ax, bx, cx, es
    push seg_ptr
    pop es
    mov bx, block_size
    mov ah, 4ah
    int 21h
    jc resize_memory_block_error
    jmp resize_memory_block_exit
resize_memory_block_error:
    mov dx, 0
    ret
resize_memory_block_exit:
    mov dx, 1
    ret
endp

load_and_exec_program proc C near
arg program_path_ptr: word, cmd_ptr: word, EPB_ptr: word
uses ax, bx, cx, es
    push ds
    pop es

    mov dx, program_path_ptr
    mov bx, EPB_ptr

    add bx, 2
    mov ax, cmd_ptr
    mov word ptr [bx], ax
    
    add bx, 2
    mov word ptr [bx], ds

    mov bx, EPB_ptr

    mov ax, 4b00h
    int 21h
    jc load_and_exec_program_error
    jmp load_and_exec_program_exit
load_and_exec_program_error:
    mov dx, 0
    ret
load_and_exec_program_exit:
    mov dx, 1
    ret
endp

getint proc C near
arg number_buffer_ptr: word
uses bx, cx
    mov bx, number_buffer_ptr
    add bx, 2

    xor ax, ax
    xor cx, cx
getint_iter:
    mov cl, byte ptr [bx]
    
    cmp cl, '$' 
    je getint_exit

    cmp cl, "0"
    jl getint_iter_error
    cmp cl, "9"
    ja getint_iter_error
    
    push bx
    mov bx, 10
    mul bx
    jo getint_iter_error
    pop bx

    sub cl, '0'
    add al, cl
    jc getint_iter_error

    inc bx
    jmp getint_iter
getint_iter_error:
    mov dx, 0
    ret
getint_exit:
    mov dx, 1
    ret
endp