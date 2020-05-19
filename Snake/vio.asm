; Video input/output
.model small

.code

video_init proc C near 
uses ax
    mov ax, 3h
    int 10h

    mov ax, 0B800h
    mov es, ax
    ret
endp

fill_screen proc C near
arg color:byte, character:byte
uses ax, cx, di
    mov di, 0
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT

    mov al, character
    mov ah, color
    rep stosw
    ret
endp

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@x1, y1              x2, y1@
;@                          @
;@                          @
;@                          @
;@                          @
;@                          @
;@                          @
;@x1, y2              x2, y2@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@
fill_area proc C near
arg x1:byte, y1:byte, x2:byte, y2:byte, color:byte, character:byte
uses ax, bx, cx, dx, si, di
    xor cx, cx
    xor ax, ax

    mov cl, y2
    sub cl, y1
    
    mov al, y1
    mov bx, SCREEN_WIDTH * BYTES_IN_BOX
    mul bx

    push ax
    mov bx, BYTES_IN_BOX
    xor ax, ax
    mov al, x1
    mul bx
    mov dx, ax
    pop ax

    add ax, dx
    mov di, ax

fill_area_iter:
    push cx
    
    xor cx, cx
    mov cl, x2
    sub cl, x1

    mov ax, SCREEN_WIDTH
    sub ax, cx
    mul bx

    mov dx, ax

    mov al, character
    mov ah, color
    rep stosw

    add di, dx

    pop cx
loop fill_area_iter

    ret
endp


; Text printer
text_render proc C near
arg x:byte, y:byte, color:byte, string:word
uses ax, bx, cx, dx, di, si
    xor ax, ax
    mov al, y
    mov bx, SCREEN_WIDTH * BYTES_IN_BOX
    mul bx

    mov di, ax

    xor ax, ax
    mov al, x
    mov bx, BYTES_IN_BOX
    mul bx

    add di, ax
    mov bl, color
    mov si, string
text_render_iter:
    mov al, byte ptr [si]
    cmp al, 0
    je text_render_complete
    mov byte ptr es:[di], al
    inc di
    mov byte ptr es:[di], bl
    inc di
    inc si
    jmp text_render_iter
text_render_complete:
    ret
endp


render_element proc C near
arg point:snake_element
uses ax, bx
    xor ax, ax
    mov al, 1
    add al, point.snake_x

    xor bx, bx
    mov bl, 1
    add bl, point.snake_y

    call fill_area C, word ptr point.snake_x, word ptr point.snake_y, ax, bx, word ptr point.snake_color, word ptr point.snake_character
    ret
endp

check_position proc C near
arg x:byte, y:byte
uses bx, cx, dx, di, si
    xor ax, ax
    mov al, y
    mov bx, SCREEN_WIDTH * BYTES_IN_BOX
    mul bx

    mov di, ax

    xor ax, ax
    mov al, x
    mov bx, BYTES_IN_BOX
    mul bx

    add di, ax

    xor ax, ax
    mov al, byte ptr es:[di]

    ret
endp

move_element proc C near
arg point:word
uses ax, bx, cx, di, si
    xor dx, dx
    mov bx, point
    cmp word ptr [bx].snake_vector, 0
    je move_element_up
    cmp word ptr [bx].snake_vector, 1
    je move_element_right
    cmp word ptr [bx].snake_vector, 2
    je move_element_bottom
    cmp word ptr [bx].snake_vector, 3
    je move_element_left
    jmp move_element_exit
move_element_up:
    dec byte ptr [bx].snake_y
    cmp byte ptr [bx].snake_y, 0
    je move_element_up_reset
    jmp move_element_exit
move_element_up_reset:
    mov byte ptr [bx].snake_y, 23
    jmp move_element_exit
move_element_right:
    inc byte ptr [bx].snake_x
    cmp byte ptr [bx].snake_x, 49
    je move_element_right_reset
    jmp move_element_exit
move_element_right_reset:
    mov byte ptr [bx].snake_x, 1
    jmp move_element_exit
move_element_bottom:
    inc byte ptr [bx].snake_y
    cmp byte ptr [bx].snake_y, 24
    je move_element_bottom_reset
    jmp move_element_exit
move_element_bottom_reset:
    mov byte ptr [bx].snake_y, 1
    jmp move_element_exit
move_element_left:
    dec byte ptr [bx].snake_x
    cmp byte ptr [bx].snake_x, 0
    je move_element_left_reset
    jmp move_element_exit
move_element_left_reset:
    mov byte ptr [bx].snake_x, 48
move_element_exit:
    ret
endp

collision proc C near
arg snake_elements:word, points:word, score_number:word
uses ax, bx, cx, dx, di, si
    mov di, points

collision_points_iter:
    mov dl, byte ptr [di].point_x
    mov dh, byte ptr [di].point_y

    cmp dl, 0
    je collision_exit

    add di, POINT_SIZE
    mov si, snake_elements

collision_elements_iter:
    mov al, byte ptr [si].snake_x
    mov ah, byte ptr [si].snake_y

    add si, ELEMENT_SIZE

    cmp al, 0
    je collision_points_iter

    cmp al, dl
    je collision_elements_equal_x

    jmp collision_elements_iter

collision_elements_equal_x:
    cmp ah, dh
    je collision_elements_equal_y
    jmp collision_elements_iter

collision_elements_equal_y:
    sub si, ELEMENT_SIZE
    sub di, POINT_SIZE

    cmp byte ptr [di].counter, 0
    je collision_point_out_of_counter

    dec byte ptr [di].counter

    xor ax, ax
    mov al, byte ptr [di].vector
    cmp al, 4
    je collision_bonus
    jne collision_direction
collision_bonus:
    mov byte ptr [di].vector, 0
    push di
    mov di, points
collision_bonus_iter:
    cmp byte ptr [di].point_x, 0
    je collision_bonus_completed

    cmp byte ptr [di].counter, 0
    je collision_bonus_iter_next
    inc byte ptr [di].counter

collision_bonus_iter_next:
    add di, POINT_SIZE

    jmp collision_bonus_iter
collision_bonus_completed:
    pop di
    mov byte ptr [di].counter, 0
    push di
    mov di, score_number
    inc byte ptr [di]
    pop di

    call push_snake_element C, snake_elements
    jmp collision_point_out_of_counter
collision_direction:
    mov word ptr [si].snake_vector, ax

collision_point_out_of_counter:
    add si, ELEMENT_SIZE
    add di, POINT_SIZE

    jmp collision_points_iter

collision_exit:
    ret
endp


snake_length proc C near
arg snake_elements:word
uses ax, bx, dx
    xor cx, cx
    mov bx, snake_elements
snake_length_iter:
    cmp byte ptr [bx].snake_x, 0
    je snake_length_exit
    inc cx
    add bx, ELEMENT_SIZE
    jmp snake_length_iter

snake_length_exit:
    ret
endp

vector_length proc C near
arg points:word
uses ax, bx, dx
    xor cx, cx
    mov bx, points
vector_length_iter:
    cmp byte ptr [bx].point_x, 0
    je vector_length_exit
    inc cx
    add bx, POINT_SIZE
    jmp vector_length_iter

vector_length_exit:
    ret
endp

push_snake_element proc C near
arg snake_elements:word
uses ax, bx, cx, dx
    mov bx, snake_elements
    call snake_length C, snake_elements

    mov ax, cx
    dec ax
    mov cx, ELEMENT_SIZE
    mul cx
    add bx, ax

    mov al, byte ptr [bx].snake_x
    mov ah, byte ptr [bx].snake_y
    mov cx, word ptr [bx].snake_vector

    add bx, ELEMENT_SIZE

    mov byte ptr [bx].snake_x, al
    mov byte ptr [bx].snake_y, ah
    mov word ptr [bx].snake_vector, cx

    cmp cx, 0
    je push_snake_element_bottom
    cmp cx, 1
    je push_snake_element_left
    cmp cx, 2
    je push_snake_element_top
    cmp cx, 3
    je push_snake_element_right

push_snake_element_bottom:
    inc byte ptr [bx].snake_y
    jmp push_snake_element_exit
push_snake_element_left:
    dec byte ptr [bx].snake_x
    jmp push_snake_element_exit
push_snake_element_top:
    dec byte ptr [bx].snake_y
    jmp push_snake_element_exit
push_snake_element_right:
    inc byte ptr [bx].snake_x
    jmp push_snake_element_exit
push_snake_element_exit:
    ret
endp


intersection proc C near
arg snake_elements:word
uses ax, bx, cx, di, si
    mov di, snake_elements
    xor dx, dx

intersection_iter1:
    mov al, byte ptr [di].snake_x
    mov ah, byte ptr [di].snake_y

    cmp al, 0
    je intersection_exit

    add di, ELEMENT_SIZE
    mov si, di
intersection_iter2:
    mov bl, byte ptr [si].snake_x
    mov bh, byte ptr [si].snake_y

    cmp bl, 0
    je intersection_iter1
    
    add si, ELEMENT_SIZE

    cmp al, bl
    je intersection_x_equals

    jmp intersection_iter2
intersection_x_equals:
    cmp ah, bh
    je intersection_y_equals
    jmp intersection_iter2

intersection_y_equals:
    mov dx, 1
intersection_exit:
    ret
endp

push_vector_point proc C near
arg x:byte, y:byte, vector_id:byte, counter_id:word, points:word
uses ax, bx, cx, dx
    mov bx, points
    call vector_length C, bx

    mov ax, cx
    mov cx, POINT_SIZE
    mul cx

    add bx, ax
    mov al, x
    mov ah, y

    mov byte ptr[bx].point_x, al
    mov byte ptr[bx].point_y, ah

    mov cx, counter_id
    mov al, vector_id
    mov byte ptr[bx].counter, cl
    mov byte ptr[bx].vector, al

    ret
endp

random_number proc C near
arg from:byte, to:byte
uses bx, cx, dx, ds
    push 0040h
    pop ds
    
    xor bx, bx
    xor ax, ax
    xor dx, dx

    mov ax, word ptr ds:006ch
    mov bl, to
    sub bl, from
    div bx
    add dl, from
    mov ax, dx
    ret
endp


; BONUS
check_bonus proc C near
arg points:word
uses bx, ax, dx
    xor cx, cx
    mov bx, points

check_bonus_iter:
    mov al, byte ptr [bx].point_x
    mov ah, byte ptr [bx].vector

    cmp al, 0
    je check_bonus_exit

    add bx, POINT_SIZE

    cmp ah, BONUS_VECTOR
    je check_bonus_completed
    jmp check_bonus_iter

check_bonus_completed:
    mov cx, 1

check_bonus_exit:
    ret
endp

render_bonus_vector proc C near
arg points:word
uses ax, bx, cx, dx
    xor cx, cx
    mov bx, points

render_bonus_vector_iter:
    mov dl, byte ptr [bx].point_x
    mov dh, byte ptr [bx].point_y
    mov ah, byte ptr [bx].vector

    cmp dl, 0
    je render_bonus_vector_exit

    add bx, POINT_SIZE

    cmp ah, BONUS_VECTOR
    je render_bonus_vector_completed
    jmp render_bonus_vector_iter

render_bonus_vector_completed:
    mov cx, 1
    
    xor ax, ax
    xor cx, cx

    mov al, dl
    mov bx, ax
    add bx, 1

    mov cl, dh
    mov dx, cx
    add dx, 1
    call fill_area C, ax, cx, bx, dx, 79h, " "

render_bonus_vector_exit:
    ret
endp

generate_bonus proc C near
arg snake_elements:word, vectors:word
uses ax, bx, cx, dx, si
generate_bonus_main_iter:
    call random_number C, 1, 24
    mov bh, al
    call random_number C, 1, 49
    mov bl, al

    mov si, snake_elements
    
generate_bonus_iter:
    mov al, byte ptr [si].snake_x
    mov ah, byte ptr [si].snake_y

    add si, ELEMENT_SIZE

    cmp al, 0
    je generate_bonus_completed

    cmp al, bl
    je generate_bonus_equal_x

    jmp generate_bonus_iter

generate_bonus_equal_x:
    cmp ah, bh
    je generate_bonus_main_iter
    jmp generate_bonus_iter

generate_bonus_completed:
    xor cx, cx
    xor dx, dx

    mov cl, bl
    mov dl, bh

    call push_vector_point C, cx, dx, 4, 1, vectors
    ret
endp