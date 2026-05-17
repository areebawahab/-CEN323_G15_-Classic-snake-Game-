; ========================================
; COMPLETE CLASSIC SNAKE GAME - 8086 Assembly
; ========================================
; Platform : emu8086
; Authors  : Ayesha Sana, Areeba Wahab
; ========================================

.model small
.stack 100h

.data

; ========================================
; CONSTANTS
; ========================================

GAME_WIDTH        equ 40
GAME_HEIGHT       equ 20
MAX_LENGTH        equ 100

HEAD_CHAR         equ 'O'
BODY_CHAR         equ 'o'
FOOD_CHAR         equ '*'
WALL_CHAR         equ '#'

UP                equ 0
DOWN              equ 1
LEFT              equ 2
RIGHT             equ 3

SNAKE_COLOR       equ 0Ah
FOOD_COLOR        equ 0Ch
WALL_COLOR        equ 0Fh

; ========================================
; GAME VARIABLES
; ========================================

snakeX            db MAX_LENGTH dup(0)
snakeY            db MAX_LENGTH dup(0)

snakeLength       dw 5

direction         db RIGHT
nextDirection     db RIGHT

foodX             db 15
foodY             db 10

score             dw 0
gameOver          db 0

offsetX           db 20
offsetY           db 3

; ========================================
; MESSAGES
; ========================================

titleMsg          db '===== CLASSIC SNAKE GAME =====$'
scoreMsg          db 'Score: $'
gameOverMsg       db 'GAME OVER!$'
restartMsg        db 'Press R to Restart or ESC to Exit$'
controlMsg        db 'Arrow Keys to Move$'

.code

; ========================================
; MAIN PROGRAM
; ========================================

main proc

    mov ax,@data
    mov ds,ax

    mov ah,0
    mov al,03h
    int 10h

StartGame:

    call InitGame
    call DrawBorder
    call DrawUI

    ; Draw initial snake and food
    call DrawSnake
    call DrawFood

GameLoop:

    call CheckInput

    mov al,nextDirection
    mov direction,al

    call EraseTail
    call MoveSnake
    call CheckCollision
    call CheckFood

    call DrawSnake
    call DrawFood
    call UpdateScore

    call Delay

    jmp GameLoop

EndScreen:

    call ShowGameOver

WaitKey:

    mov ah,0
    int 16h

    cmp al,'r'
    je StartGame

    cmp al,'R'
    je StartGame

    cmp ah,01h
    je ExitProgram

    jmp WaitKey

ExitProgram:

    mov ah,4Ch
    int 21h

main endp

; ========================================
; INITIALIZE GAME
; ========================================

InitGame proc

    call ClearScreen

    mov snakeLength,5
    mov score,0
    mov gameOver,0

    mov direction,RIGHT
    mov nextDirection,RIGHT

    ; Snake body positions

    mov snakeX[0],20
    mov snakeY[0],10

    mov snakeX[1],19
    mov snakeY[1],10

    mov snakeX[2],18
    mov snakeY[2],10

    mov snakeX[3],17
    mov snakeY[3],10

    mov snakeX[4],16
    mov snakeY[4],10

    call GenerateFood

    ret

InitGame endp

; ========================================
; CLEAR SCREEN
; ========================================

ClearScreen proc

    push ax
    push bx
    push cx
    push dx

    mov ah,06h
    mov al,0
    mov bh,07h
    mov cx,0000h
    mov dx,184Fh
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax

    ret

ClearScreen endp

; ========================================
; DRAW BORDER
; ========================================

DrawBorder proc

    push ax
    push bx
    push cx
    push dx

    ; Top border

    mov dh,offsetY
    dec dh

    mov dl,offsetX
    dec dl

    mov cx,GAME_WIDTH+2

TopLoop:

    call SetCursor

    mov al,WALL_CHAR
    mov ah,WALL_COLOR
    call PrintChar

    inc dl
    loop TopLoop

    ; Bottom border

    mov dh,offsetY
    add dh,GAME_HEIGHT

    mov dl,offsetX
    dec dl

    mov cx,GAME_WIDTH+2

BottomLoop:

    call SetCursor

    mov al,WALL_CHAR
    mov ah,WALL_COLOR
    call PrintChar

    inc dl
    loop BottomLoop

    ; Side borders

    mov cx,GAME_HEIGHT

    mov dh,offsetY

SideLoop:

    ; Left wall

    mov dl,offsetX
    dec dl

    call SetCursor

    mov al,WALL_CHAR
    mov ah,WALL_COLOR
    call PrintChar

    ; Right wall

    mov dl,offsetX
    add dl,GAME_WIDTH

    call SetCursor

    mov al,WALL_CHAR
    mov ah,WALL_COLOR
    call PrintChar

    inc dh
    loop SideLoop

    pop dx
    pop cx
    pop bx
    pop ax

    ret

DrawBorder endp

; ========================================
; DRAW UI
; ========================================

DrawUI proc

    push dx

    mov dh,0
    mov dl,22
    call SetCursor

    lea dx,titleMsg
    mov ah,09h
    int 21h

    mov dh,1
    mov dl,28
    call SetCursor

    lea dx,controlMsg
    mov ah,09h
    int 21h

    call UpdateScore

    pop dx

    ret

DrawUI endp

; ========================================
; UPDATE SCORE
; ========================================

UpdateScore proc

    push ax
    push dx

    mov dh,23
    mov dl,2
    call SetCursor

    lea dx,scoreMsg
    mov ah,09h
    int 21h

    mov ax,score
    call PrintNumber

    pop dx
    pop ax

    ret

UpdateScore endp
; ========================================
; CHECK INPUT (EMU8086 FIX)
; ========================================

CheckInput proc

    push ax

    ; Check keyboard buffer
    mov ah,01h
    int 16h

    jz EndInput

    ; Read key
    mov ah,00h
    int 16h

    ; Arrow keys scan codes

    cmp ah,48h
    je MoveUpKey

    cmp ah,50h
    je MoveDownKey

    cmp ah,4Bh
    je MoveLeftKey

    cmp ah,4Dh
    je MoveRightKey

    jmp EndInput

MoveUpKey:

    cmp direction,DOWN
    je EndInput

    mov nextDirection,UP
    jmp EndInput

MoveDownKey:

    cmp direction,UP
    je EndInput

    mov nextDirection,DOWN
    jmp EndInput

MoveLeftKey:

    cmp direction,RIGHT
    je EndInput

    mov nextDirection,LEFT
    jmp EndInput

MoveRightKey:

    cmp direction,LEFT
    je EndInput

    mov nextDirection,RIGHT

EndInput:

    pop ax
    ret

CheckInput endp

; ========================================
; MOVE SNAKE
; ========================================

MoveSnake proc

    push ax
    push bx
    push cx
    push si

    mov cx,snakeLength
    dec cx

    mov si,cx

MoveBody:

    cmp si,0
    jle MoveHead

    mov bx,si
    dec bx

    mov al,snakeX[bx]
    mov snakeX[si],al

    mov al,snakeY[bx]
    mov snakeY[si],al

    dec si
    jmp MoveBody

MoveHead:

    mov al,snakeX[0]
    mov bl,snakeY[0]

    cmp direction,UP
    je MoveUp

    cmp direction,DOWN
    je MoveDown

    cmp direction,LEFT
    je MoveLeft

    cmp direction,RIGHT
    je MoveRight

MoveUp:
    dec bl
    jmp SaveHead

MoveDown:
    inc bl
    jmp SaveHead

MoveLeft:
    dec al
    jmp SaveHead

MoveRight:
    inc al

SaveHead:

    mov snakeX[0],al
    mov snakeY[0],bl

    pop si
    pop cx
    pop bx
    pop ax

    ret

MoveSnake endp

; ========================================
; CHECK COLLISION
; ========================================

CheckCollision proc

    push ax
    push bx
    push cx
    push si

    mov al,snakeX[0]
    mov bl,snakeY[0]

    ; Wall collision

    cmp al,0
    jl Collision

    cmp al,GAME_WIDTH-1
    jg Collision

    cmp bl,0
    jl Collision

    cmp bl,GAME_HEIGHT-1
    jg Collision

    ; Self collision

    mov cx,snakeLength
    mov si,1

SelfLoop:

    cmp si,cx
    jge NoCollision

    mov ah,snakeX[si]
    cmp ah,al
    jne NextPart

    mov ah,snakeY[si]
    cmp ah,bl
    jne NextPart

    jmp Collision

NextPart:

    inc si
    jmp SelfLoop

Collision:

    mov gameOver,1

NoCollision:

    pop si
    pop cx
    pop bx
    pop ax

    ret

CheckCollision endp

; ========================================
; CHECK FOOD
; ========================================

CheckFood proc

    push ax
    push bx

    mov al,snakeX[0]
    mov bl,snakeY[0]

    cmp al,foodX
    jne EndFood

    cmp bl,foodY
    jne EndFood

    inc snakeLength
    inc score

    call GenerateFood

EndFood:

    pop bx
    pop ax

    ret

CheckFood endp

; ========================================
; GENERATE FOOD
; ========================================

GenerateFood proc

    push ax
    push bx
    push dx

    mov ah,00h
    int 1Ah

    mov ax,dx
    xor dx,dx

    mov bx,GAME_WIDTH
    div bx

    mov foodX,dl

    mov ax,dx
    xor dx,dx

    mov bx,GAME_HEIGHT
    div bx

    mov foodY,dl

    pop dx
    pop bx
    pop ax

    ret

GenerateFood endp

; ========================================
; DRAW SNAKE
; ========================================

DrawSnake proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,snakeLength
    mov si,0

DrawLoop:

    cmp si,cx
    jge DrawDone

    mov dl,snakeX[si]
    add dl,offsetX

    mov dh,snakeY[si]
    add dh,offsetY

    call SetCursor

    cmp si,0
    je DrawHead

    mov al,BODY_CHAR
    mov ah,SNAKE_COLOR
    call PrintChar
    jmp NextSegment

DrawHead:

    mov al,HEAD_CHAR
    mov ah,SNAKE_COLOR
    call PrintChar

NextSegment:

    inc si
    jmp DrawLoop

DrawDone:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

DrawSnake endp

; ========================================
; ERASE TAIL
; ========================================

EraseTail proc

    push ax
    push bx
    push dx

    mov bx,snakeLength
    dec bx

    mov dl,snakeX[bx]
    add dl,offsetX

    mov dh,snakeY[bx]
    add dh,offsetY

    call SetCursor

    mov al,' '
    mov ah,07h
    call PrintChar

    pop dx
    pop bx
    pop ax

    ret

EraseTail endp

; ========================================
; DRAW FOOD
; ========================================

DrawFood proc

    push ax
    push dx

    mov dl,foodX
    add dl,offsetX

    mov dh,foodY
    add dh,offsetY

    call SetCursor

    mov al,FOOD_CHAR
    mov ah,FOOD_COLOR
    call PrintChar

    pop dx
    pop ax

    ret

DrawFood endp

; ========================================
; SHOW GAME OVER
; ========================================

ShowGameOver proc

    push dx

    mov dh,12
    mov dl,34
    call SetCursor

    lea dx,gameOverMsg
    mov ah,09h
    int 21h

    mov dh,14
    mov dl,20
    call SetCursor

    lea dx,restartMsg
    mov ah,09h
    int 21h

    pop dx

    ret

ShowGameOver endp

; ========================================
; DELAY (FIXED)
; ========================================

Delay proc

    push cx
    push dx

    mov cx,25

DelayOuter:

    mov dx,3000

DelayInner:

    dec dx
    cmp dx,0
    jne DelayInner

    loop DelayOuter

    pop dx
    pop cx

    ret

Delay endp

; ========================================
; SET CURSOR
; DH = ROW
; DL = COLUMN
; ========================================

SetCursor proc

    push ax
    push bx

    mov ah,02h
    mov bh,0
    int 10h

    pop bx
    pop ax

    ret

SetCursor endp

; ========================================
; PRINT CHARACTER
; ========================================

PrintChar proc

    push ax
    push bx
    push cx

    mov bl,ah
    mov bh,0
    mov cx,1

    mov ah,09h
    int 10h

    pop cx
    pop bx
    pop ax

    ret

PrintChar endp

; ========================================
; PRINT NUMBER
; ========================================

PrintNumber proc

    push ax
    push bx
    push cx
    push dx

    mov bx,10
    mov cx,0

ConvertLoop:

    xor dx,dx
    div bx

    push dx
    inc cx

    cmp ax,0
    jne ConvertLoop

PrintLoop:

    pop dx

    add dl,'0'

    mov ah,02h
    int 21h

    loop PrintLoop

    pop dx
    pop cx
    pop bx
    pop ax

    ret

PrintNumber endp

end main