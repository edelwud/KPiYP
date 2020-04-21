; Helpers for standart input/output in MS DOS
.model small

.data
    newline db 2, 0, 0Ah, 0Dh, "$"
    base db 10

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

; Getting integer from console
; | output:
; ax - integer
getint proc pascal near
arg number:word
uses cx
    xor ax, ax
    xor cx, cx
    mov ch, 10
getint_iterator:
    push ax
    call getchar
    cmp al, 0dh
    je getint_break
    sub al, "0"
    mov cl, al
    pop ax
    mul ch
    add al, cl
    jmp getint_iterator
getint_break:
    pop ax
    ret
endp

; Print integer
; | input:
; number - integer
printint proc pascal near
arg number:word
uses ax, bx, cx, dx
    mov ax, number
    mov bl, 10
    xor cx, cx
    xor dx, dx
printint_iterator:
    div bl
    inc cx
    
    mov dl, ah
    push dx

    cmp al, 0
    je printint_break
    
    xor ah, ah

    jmp printint_iterator
printint_break:
    pop ax
    xor ah, ah
    add ax, 30h
    call putchar pascal, ax
    loop printint_break
    ret
endp

check_char_number proc pascal near
arg x:word
    mov dx, 1

    cmp x, "0"
    jl check_char_number_error
    cmp x, "9"
    ja check_char_number_error
    jmp check_char_number_exit
    check_char_number_error:
        xor dx, dx
    check_char_number_exit:
        ret
endp

getnumber proc pascal near
arg string:word, dest:word
uses ax, cx, dx, di
    call getstring pascal, string

    mov bx, string
    mov cl, byte ptr [bx + 1]
    add bx, 2

    mov di, dest
    mov byte ptr [di + 1], cl 
    mov byte ptr [di], 80
    add di, 2

    xor ax, ax

    sign_checker:
        cmp byte ptr [bx], "+"
        je plus_flag
        cmp byte ptr [bx], "-"
        je minus_flag

        mov al, byte ptr [bx]
        call check_char_number pascal, ax

        cmp dx, 0
        je getnumber_error
        mov byte ptr [di], "+"
        jmp writer

        plus_flag:
            mov byte ptr [di], "+"
            sub byte ptr [di - 1], 1
            dec cx
            inc bx
            jmp writer
        minus_flag:
            mov byte ptr [di], "-"
            sub byte ptr [di - 1], 1
            dec cx
            inc bx

    writer:
        mov al, byte ptr [bx]
        inc bx
        call check_char_number pascal, ax
        cmp dx, 0
        je getnumber_error
        
        inc di
        mov byte ptr [di], al
    loop writer

    jmp getnumber_exit

    getnumber_error:
        xor bx, bx
        call putchar pascal, "!"
    getnumber_exit:
        mov byte ptr [di + 1], "$"
        ret
endp

number_parser proc pascal near
arg number:word
uses bx, cx
    mov bx, number
    add bx, 2
    xor dx, dx
    mov dl, byte ptr [bx]
    push dx

    xor cx, cx
    mov cl, byte ptr [bx - 1]

    xor dx, dx ; counter
    xor ax, ax ; result

    number_parse:
        cmp dx, cx
        je number_parser_completed
        inc bx
        push dx
        xor dx, dx
        mov dl, byte ptr [bx]
        sub dl, "0"

        push dx
        xor dx, dx
        mov dl, base
        mul dx
        pop dx

        add ax, dx
        pop dx
        inc dx
        jmp number_parse

    number_parser_completed:
        pop bx
        mov dx, 1
        cmp bx, "-"
        je number_parser_minus_flag
        jmp number_parser_plus_exit

        number_parser_minus_flag:
            xor dx, dx
        number_parser_plus_exit:  
            ret
endp

print_number proc pascal near
arg sign:word, number:word, result:word
uses ax, bx, cx, dx
    mov ax, number
    mov cl, base
    mov bx, result
    add bx, 2

    cmp sign, 1
    je print_number_plus_flag
    cmp sign, 0
    je print_number_minus_flag

    print_number_plus_flag:
        mov byte ptr [bx], "+"
        inc bx
        jmp print_number_writer
    print_number_minus_flag:
        mov byte ptr [bx], "-"
        inc bx

    print_number_writer:
        cmp ax, 0
        je print_number_completed
        xor dx, dx
        div cx
        add dx, "0"
        mov byte ptr [bx], dl
        inc bx
        jmp print_number_writer
        
    print_number_completed:
        cmp word ptr number, 0
        je print_number_create
        jne print_number_complete
        print_number_create:
            mov byte ptr [bx], "0"
            inc bx
        print_number_complete:
            mov byte ptr [bx], "$"

        dec bx
        mov di, result
        add di, 3
        print_number_reverse:
            cmp bx, di
            jbe print_number_exit
            mov al, byte ptr [bx]
            mov ah, byte ptr [di]
            mov byte ptr [bx], ah
            mov byte ptr [di], al
            dec bx
            inc di
            jmp print_number_reverse
        print_number_exit:
            ret
endp


division proc pascal near
arg sign:word, number:word, count:word, div_buffer:word
uses ax, bx, cx, dx, di, si
    mov ax, number
    mov bx, count

    xor dx, dx
    div bx

    call print_number pascal, sign, ax, div_buffer
    call printstring pascal, div_buffer
    call putchar pascal, "."

    mov cx, 4

    division_iter:
        mov ax, dx
        xor dx, dx
        mov dl, base
        mul dx
        xor dx, dx
        div bx
        add ax, "0"
        call putchar pascal, ax
    loop division_iter

    ret
endp