; ============================================================
; SNAKE GAME for DOSBox - NASM flat binary (.COM)
; Assemble: nasm -f bin snake.asm -o snake.com
; Controls: W/A/S/D to move, R to restart, ESC to quit
; ============================================================

BITS 16
ORG 100h

; ---- constants ----
GAME_W      EQU 38
GAME_H      EQU 18
MAX_LEN     EQU 200
OFF_X       EQU 1
OFF_Y       EQU 3

DIR_UP      EQU 0
DIR_DOWN    EQU 1
DIR_LEFT    EQU 2
DIR_RIGHT   EQU 3

start:
    mov  ax, cs
    mov  ds, ax
    mov  es, ax
    mov  ax, 0003h
    int  10h

.restart:
    call init_game
    call draw_border
    call draw_title
    call draw_food
    call draw_snake

.game_loop:
    call check_input
    cmp  byte [game_over], 1
    je   .dead
    call move_snake
    cmp  byte [game_over], 1
    je   .dead
    call draw_food
    call draw_snake
    call show_score
    call delay
    jmp  .game_loop

.dead:
    call show_gameover

.wait_key:
    xor  ah, ah
    int  16h
    cmp  al, 'r'
    je   .restart
    cmp  al, 'R'
    je   .restart
    cmp  al, 27
    je   .quit
    jmp  .wait_key

.quit:
    mov  ax, 4C00h
    int  21h

; ============================================================
init_game:
    mov  ax, 0600h
    mov  bh, 07h
    xor  cx, cx
    mov  dx, 184Fh
    int  10h

    mov  word [snake_len], 5
    mov  word [score], 0
    mov  byte [game_over], 0
    mov  byte [direction], DIR_RIGHT
    mov  byte [next_dir], DIR_RIGHT

    mov  byte [sx+0],  14
    mov  byte [sy+0],  9
    mov  byte [sx+1],  13
    mov  byte [sy+1],  9
    mov  byte [sx+2],  12
    mov  byte [sy+2],  9
    mov  byte [sx+3],  11
    mov  byte [sy+3],  9
    mov  byte [sx+4],  10
    mov  byte [sy+4],  9

    mov  byte [food_x], 20
    mov  byte [food_y], 9
    call gen_food
    ret

; ============================================================
draw_border:
    mov  dh, OFF_Y - 1
    mov  dl, OFF_X - 1
    mov  cx, GAME_W + 2
.top:
    call set_cursor
    mov  al, 0DBh
    mov  bl, 0Fh
    call print_char
    inc  dl
    loop .top

    mov  dh, OFF_Y + GAME_H
    mov  dl, OFF_X - 1
    mov  cx, GAME_W + 2
.bot:
    call set_cursor
    mov  al, 0DBh
    mov  bl, 0Fh
    call print_char
    inc  dl
    loop .bot

    mov  dh, OFF_Y
    mov  cx, GAME_H
.sides:
    push cx
    mov  dl, OFF_X - 1
    call set_cursor
    mov  al, 0DBh
    mov  bl, 0Fh
    call print_char
    mov  dl, OFF_X + GAME_W
    call set_cursor
    mov  al, 0DBh
    mov  bl, 0Fh
    call print_char
    inc  dh
    pop  cx
    loop .sides
    ret

; ============================================================
draw_title:
    mov  dh, 0
    mov  dl, 10
    call set_cursor
    mov  si, title_str
    call print_str
    mov  dh, 1
    mov  dl, 10
    call set_cursor
    mov  si, ctrl_str
    call print_str
    ret

; ============================================================
check_input:
    mov  ah, 01h
    int  16h
    jz   .no_key
    xor  ah, ah
    int  16h
    cmp  al, 27
    je   .esc
    cmp  al, 'w'
    je   .up
    cmp  al, 'W'
    je   .up
    cmp  al, 's'
    je   .down
    cmp  al, 'S'
    je   .down
    cmp  al, 'a'
    je   .left
    cmp  al, 'A'
    je   .left
    cmp  al, 'd'
    je   .right
    cmp  al, 'D'
    je   .right
    jmp  .no_key
.esc:
    mov  byte [game_over], 1
    jmp  .no_key
.up:
    cmp  byte [direction], DIR_DOWN
    je   .no_key
    mov  byte [next_dir], DIR_UP
    jmp  .no_key
.down:
    cmp  byte [direction], DIR_UP
    je   .no_key
    mov  byte [next_dir], DIR_DOWN
    jmp  .no_key
.left:
    cmp  byte [direction], DIR_RIGHT
    je   .no_key
    mov  byte [next_dir], DIR_LEFT
    jmp  .no_key
.right:
    cmp  byte [direction], DIR_LEFT
    je   .no_key
    mov  byte [next_dir], DIR_RIGHT
.no_key:
    ret

; ============================================================
move_snake:
    mov  al, [next_dir]
    mov  [direction], al

    mov  al, [sx]
    mov  bl, [sy]

    cmp  byte [direction], DIR_UP
    jne  .chk_down
    dec  bl
    jmp  .got_head
.chk_down:
    cmp  byte [direction], DIR_DOWN
    jne  .chk_left
    inc  bl
    jmp  .got_head
.chk_left:
    cmp  byte [direction], DIR_LEFT
    jne  .go_right
    dec  al
    jmp  .got_head
.go_right:
    inc  al

.got_head:
    push ax
    push bx

    ; erase tail
    mov  si, [snake_len]
    dec  si
    mov  dl, [sx + si]
    add  dl, OFF_X
    mov  dh, [sy + si]
    add  dh, OFF_Y
    call set_cursor
    mov  al, ' '
    mov  bl, 07h
    call print_char

    pop  bx
    pop  ax

    ; wall collision
    cmp  al, 0
    jl   .collision
    cmp  al, GAME_W - 1
    jg   .collision
    cmp  bl, 0
    jl   .collision
    cmp  bl, GAME_H - 1
    jg   .collision

    ; self collision
    mov  cx, [snake_len]
    mov  si, 1
.self_loop:
    cmp  si, cx
    jge  .no_self
    cmp  al, [sx + si]
    jne  .next_self
    cmp  bl, [sy + si]
    je   .collision
.next_self:
    inc  si
    jmp  .self_loop
.no_self:

    ; shift body
    mov  cx, [snake_len]
    dec  cx
    mov  si, cx
.shift:
    cmp  si, 1
    jl   .shift_done
    mov  dl, [sx + si - 1]
    mov  [sx + si], dl
    mov  dl, [sy + si - 1]
    mov  [sy + si], dl
    dec  si
    jmp  .shift
.shift_done:

    mov  [sx], al
    mov  [sy], bl

    ; food check
    cmp  al, [food_x]
    jne  .no_food
    cmp  bl, [food_y]
    jne  .no_food
    inc  word [snake_len]
    cmp  word [snake_len], MAX_LEN
    jl   .len_ok
    mov  word [snake_len], MAX_LEN
.len_ok:
    inc  word [score]
    call gen_food
.no_food:
    ret

.collision:
    mov  byte [game_over], 1
    ret

; ============================================================
gen_food:
    push ax
    push bx
    push dx
    mov  ah, 00h
    int  1Ah
    mov  ax, dx
    xor  dx, dx
    mov  bx, GAME_W - 2
    div  bx
    inc  dl
    mov  [food_x], dl
    mov  ax, dx
    add  ax, [score]
    xor  dx, dx
    mov  bx, GAME_H - 2
    div  bx
    inc  dl
    mov  [food_y], dl
    pop  dx
    pop  bx
    pop  ax
    ret

; ============================================================
draw_snake:
    push cx
    push si
    mov  cx, [snake_len]
    xor  si, si
.loop:
    cmp  si, cx
    jge  .done
    mov  dl, [sx + si]
    add  dl, OFF_X
    mov  dh, [sy + si]
    add  dh, OFF_Y
    call set_cursor
    cmp  si, 0
    je   .head
    mov  al, 'o'
    mov  bl, 0Ah
    call print_char
    jmp  .next
.head:
    mov  al, 'O'
    mov  bl, 0Bh
    call print_char
.next:
    inc  si
    jmp  .loop
.done:
    pop  si
    pop  cx
    ret

; ============================================================
draw_food:
    mov  dl, [food_x]
    add  dl, OFF_X
    mov  dh, [food_y]
    add  dh, OFF_Y
    call set_cursor
    mov  al, '*'
    mov  bl, 0Ch
    call print_char
    ret

; ============================================================
show_score:
    mov  dh, OFF_Y + GAME_H + 1
    mov  dl, 2
    call set_cursor
    mov  si, score_str
    call print_str
    mov  ax, [score]
    call print_num
    ret

; ============================================================
show_gameover:
    mov  dh, OFF_Y + GAME_H/2
    mov  dl, 13
    call set_cursor
    mov  si, over_str
    call print_str
    mov  dh, OFF_Y + GAME_H/2 + 2
    mov  dl, 8
    call set_cursor
    mov  si, restart_str
    call print_str
    call show_score
    ret

; ============================================================
set_cursor:
    push ax
    push bx
    mov  ah, 02h
    mov  bh, 0
    int  10h
    pop  bx
    pop  ax
    ret

; ============================================================
print_char:
    push ax
    push bx
    push cx
    mov  ah, 09h
    mov  bh, 0
    mov  cx, 1
    int  10h
    ; advance cursor
    mov  ah, 03h
    xor  bh, bh
    int  10h
    inc  dl
    mov  ah, 02h
    int  10h
    pop  cx
    pop  bx
    pop  ax
    ret

; ============================================================
print_str:
    push ax
    push bx
.loop:
    mov  al, [si]
    cmp  al, '$'
    je   .done
    mov  bl, 07h
    call print_char
    inc  si
    jmp  .loop
.done:
    pop  bx
    pop  ax
    ret

; ============================================================
print_num:
    push ax
    push bx
    push cx
    push dx
    mov  bx, 10
    mov  cx, 0
.conv:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  .conv
.print:
    pop  dx
    add  dl, '0'
    mov  al, dl
    mov  bl, 0Fh
    call print_char
    loop .print
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; ============================================================
delay:
    push cx
    push dx
    mov  cx, 8
.outer:
    mov  dx, 0FFFFh
.inner:
    dec  dx
    jnz  .inner
    loop .outer
    pop  dx
    pop  cx
    ret

; ============================================================
title_str   db '=== SNAKE GAME ===  W/A/S/D to move$'
ctrl_str    db 'Eat * to grow  |  ESC = quit  |  R = restart$'
score_str   db 'Score: $'
over_str    db '*** GAME OVER ***$'
restart_str db 'Press R to restart, ESC to quit$'

snake_len   dw 5
score       dw 0
game_over   db 0
direction   db DIR_RIGHT
next_dir    db DIR_RIGHT
food_x      db 20
food_y      db 9

sx  times MAX_LEN db 0
sy  times MAX_LEN db 0
