.model small
.stack 100h
.386

SCREEN_WIDTH equ 80
SCREEN_HEIGHT equ 25
BYTES_IN_BOX equ 2

POINT_SIZE equ 4
ELEMENT_SIZE equ 6
BONUS_VECTOR equ 4

; Vector
;   0 - top
;   1 - right
;   2 - bottom
;   3 - left
;   4 - bonus

.data

    score_string db "Score", 0
    score_buffer db 4 dup('0'), 0

vector_point struc
    point_x db ?
    point_y db ?
    vector db ?
    counter db ?
vector_point ends

snake_element struc
    snake_x db ?
    snake_y db ?
    snake_color db ?
    snake_character db ?
    snake_vector dw ?
snake_element ends

    elements db 1
    vector_points_num dw 0
    score dw 0

    snake_bitmap snake_element SCREEN_WIDTH * SCREEN_HEIGHT dup (<0, 0, 255, "+", 1>)
    vector_pointk vector_point<>
    vector_points vector_point SCREEN_WIDTH * SCREEN_HEIGHT dup (<0, 0, 0>)
    
include vio.asm
include sio.asm

.code
start:
    mov ax, @data
    mov ds, ax

    call video_init
        
    call fill_screen C, 50h, " "

    mov snake_bitmap[0].snake_x, 25
    mov snake_bitmap[0].snake_y, 12

    call push_snake_element C, offset snake_bitmap
    call push_snake_element C, offset snake_bitmap
    call push_snake_element C, offset snake_bitmap
iterator:
    call fill_area C, 1, 1, 49, 24, 2, " "

    call fill_area C, 50, 1, 51, 6, 79h, " "
    call fill_area C, 51, 2, 52, 3, 79h, " "
    call fill_area C, 52, 3, 53, 4, 79h, " "
    call fill_area C, 53, 2, 54, 3, 79h, " "
    call fill_area C, 54, 1, 55, 6, 79h, " "

    call fill_area C, 56, 4, 57, 6, 79h, " "
    call fill_area C, 57, 3, 58, 4, 79h, " "
    call fill_area C, 58, 2, 59, 3, 79h, " "
    call fill_area C, 59, 1, 60, 2, 79h, " "
    call fill_area C, 60, 2, 61, 3, 79h, " "
    call fill_area C, 61, 3, 62, 4, 79h, " "
    call fill_area C, 62, 4, 63, 6, 79h, " "
    call fill_area C, 58, 4, 61, 5, 79h, " "

    call fill_area C, 64, 1, 65, 6, 79h, " "
    call fill_area C, 64, 1, 69, 2, 79h, " "
    call fill_area C, 64, 3, 67, 4, 79h, " "
    call fill_area C, 64, 5, 69, 6, 79h, " "

    call fill_area C, 70, 1, 71, 6, 79h, " "
    call fill_area C, 71, 1, 72, 2, 79h, " "
    call fill_area C, 72, 2, 73, 3, 79h, " "
    call fill_area C, 73, 3, 74, 4, 79h, " "
    call fill_area C, 71, 4, 73, 5, 79h, " "

    call text_render C, 51, 10, 57h, offset score_string
    call number_to_string C, score, offset score_buffer
    call text_render C, 51, 11, 57h, offset score_buffer

    mov ah, 01h
    int 16h
    jz continue

    mov ah, 0h
    int 16h

    xor bx, bx
    xor dx, dx

    mov bl, snake_bitmap[0].snake_x
    mov dl, snake_bitmap[0].snake_y
    call snake_length C, offset snake_bitmap

    cmp al, "w"
    je set_vec_0
    cmp al, "d"
    je set_vec_1
    cmp al, "s"
    je set_vec_2
    cmp al, "a"
    je set_vec_3

    jmp continue

set_vec_0:
    call push_vector_point C, bx, dx, 0, cx, offset vector_points
    jmp continue
set_vec_1:
    call push_vector_point C, bx, dx, 1, cx, offset vector_points
    jmp continue
set_vec_2:
    call push_vector_point C, bx, dx, 2, cx, offset vector_points
    jmp continue
set_vec_3:
    call push_vector_point C, bx, dx, 3, cx, offset vector_points

continue:
    call collision C, offset snake_bitmap, offset vector_points, offset score
    call intersection C, offset snake_bitmap
    cmp dx, 1
    je exit

    call check_bonus C, offset vector_points
    cmp cx, 1
    je continue1
    
    call generate_bonus C, offset snake_bitmap, offset vector_points

continue1:
    call render_bonus_vector C, offset vector_points

    xor bx, bx
move_iteration:
    mov al, snake_bitmap[bx].snake_x
    cmp al, 0
    je close

    push bx
    mov di, offset snake_bitmap
    add di, bx
    call move_element C, di
    call render_element C, snake_bitmap[bx]
    pop bx

    add bx, ELEMENT_SIZE
    jmp move_iteration
close:
    mov cx, 1h
    mov dx, 4240h
    mov ah, 86h
    int 15h
    jmp iterator
exit:
    call fill_screen C, 7, " "
    mov ah, 4ch
    int 21h
end start