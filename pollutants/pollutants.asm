; %define    r r9                  ; current row
; %define    r_iter r10             ; row iterator (-1/0/1)
; %define    c r11                 ; current column
; %define    c_iter r12            ; column iterator (-1/0/1)
; %define    next_board r13        ; position in M where `next` board starts
; %define    curr_board r14        ; position in M where the current board starts
; %define    tmp r15               ; register used for calculating cell coordinates
; %define    neighbours rbx        ; number of alive neighbours of a cell
%define    table r8             ; holds address of M
; %define    steps rdi

global start, step

section .bss
    COLS RESQ 1
    ROWS RESQ 1
    M RESQ 1
    WEIGHT RESQ 1
; section .data
;     CTR DQ 0
section .text

start:
    push    rbp
    mov     rbp, rsp

    movups [WEIGHT], xmm0
    movups xmm3, xmm0 ; mov 32bits
    mov [COLS], rdi               ; save params
    mov [ROWS], rsi
    mov [M], rdx


    mov    rsp, rbp
    pop    rbp

    ret

step:
;     push    r12                   ; save registers
;     push    r13
;     push    r14
;     push    r15
;     push    rbx
    push    rbp
    mov     rbp, rsp

    movd xmm3, [WEIGHT] ; mov 32bits
    ; mov rax, 7
    ; mov xmm3, rax ; mov 32bits
	shufps xmm3, xmm3, 0h ; bierze [0..31] 4 razy
	; mask: w w w w
	xor eax, eax ; eax = 0
	cvtsi2ss xmm3, eax ; weź 0 z eax i wsadź je jako 0.000000 pod xmm [0..31]
	; mask: 0 w w w
	shufps xmm3, xmm3, 39h ; KUUUL, mi też są tylko trzy potrzebne XD
	; xmm3 - w w w 0

    mov r9, [M]
	movups xmm0, [r9]
	addps xmm0, xmm3
    movups [r9], xmm0

; step_loop:
;     mov tmp, [COLS]              ; tmp = cols * rows
;     imul tmp, [ROWS]

;     mov curr_board, [CTR]        ; current boards shift
;     imul curr_board, tmp 

;     xor [CTR], BYTE 1            ; flip 0/1
;     mov next_board, [CTR]        ; calculated board shift
;     imul next_board, tmp

;     mov r, 0                     ; current row = 0

; rows_loop:
;     mov c, 0                     ; current column = 0

; cols_loop:
;     mov neighbours, 0            ; current cell alive neighbours = 0

;     mov r_iter, -1               ; neighbouring row offset = -1
; neighbour_r_loop:                ; neighbouring rows (r-1, r, r+1)    
;     mov tmp, r
;     add tmp, r_iter
;     cmp tmp, 0
;     jl next_neighbour_row        ; r + r_iter < 0 (out of bounds)
;     cmp tmp, [ROWS]
;     jge next_neighbour_row       ; r + r_iter >= ROWS (out of bounds)
    
;     mov c_iter, -1               ; neighbouring column offset = -1

; neighbour_c_loop:                ; neighbouring columns (c-1, c, c+1)    
;     mov tmp, c
;     add tmp, c_iter
;     cmp tmp, 0
;     jl next_neighbour_col        ; c + c_iter < 0 (out of bounds)
;     cmp tmp, [COLS]
;     jge next_neighbour_col       ; c + c_iter >= COLS (out of bounds)

;     mov tmp, r                   ; calculating position of the neighbour in M
;     add tmp, r_iter
;     imul tmp, [COLS]
;     add tmp, c
;     add tmp, c_iter
;     add tmp, curr_board

;     cmp [table + tmp], BYTE '1'  ; check `is neighbour alive?`
;     jne next_neighbour_col       ; not alive
;     inc neighbours               ; alive => neighbours++

; next_neighbour_col: 
;     inc c_iter
;     cmp c_iter, 1
;     jle neighbour_c_loop

; next_neighbour_row:
;     inc r_iter
;     cmp r_iter, 1
;     jle neighbour_r_loop

; neighbours_counted:   
;     mov tmp, r
;     imul tmp, [COLS]
;     add tmp, c
;     add tmp, curr_board

;     cmp [table + tmp], BYTE '1'  ; if we counted in alive cell itself => neighbours--
;     jne eval_cell
;     dec neighbours

; eval_cell:
;     cmp neighbours, 3            ; 3 alive neighbours => cell alive
;     je live
;     cmp neighbours, 2            ; not 2 neighbours => cell dead
;     jne die
;     cmp [table + tmp], BYTE '1'  ; 2 neibours and cell was alive => cell alive
;     je live

;     die:                         ; write cell to next board as dead
;     mov tmp, r
;     imul tmp, [COLS]
;     add tmp, c
;     add tmp, next_board

;     mov [table + tmp], BYTE '0'
;     jmp next

;     live:                        ; write cell to next board as alive
;     mov tmp, r
;     imul tmp, [COLS]
;     add tmp, c
;     add tmp, next_board

;     mov [table + tmp], BYTE '1'

; next:                            ; go check next cell in column/row
;     inc c
;     cmp c, [COLS]
;     jne cols_loop    

;     inc r
;     cmp r, [ROWS]
;     jne rows_loop

; next_step:
;     dec steps
;     cmp steps, 0
;     jnz step_loop

; finish:
    mov    rsp, rbp              ; restore register values
    pop    rbp
;     pop    rbx
;     pop    r15
;     pop    r14
;     pop    r13
;     pop    r12
    ret
