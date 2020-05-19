; Standart input/output

number_to_string proc C near
arg number:word, string:word
uses ax, bx, cx, dx
    mov ax, number
    mov bl, 10
    mov di, string

    mov cx, 4
number_to_string_iter:
    div bl

    mov byte ptr [di], ah
    add byte ptr [di], "0"
    
    inc di
    xor ah, ah
loop number_to_string_iter

    mov di, string
    mov si, string
    add si, 3
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