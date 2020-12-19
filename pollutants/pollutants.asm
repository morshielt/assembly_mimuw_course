; %define    r r9                  ; current row
; %define    r_iter r10             ; row iterator (-1/0/1)
; %define    c r11                 ; current column
; %define    c_iter r12            ; column iterator (-1/0/1)
; %define    next_board r13        ; position in M where `next` board starts
; %define    curr_board r14        ; position in M where the current board starts
; %define    tmp r15               ; register used for calculating cell coordinates
; %define    neighbours rbx        ; number of alive neighbours of a cell
%define    table r8             ; holds address of M
%define    iter r9             ; holds address of M
%define    step_vector r10            ; holds address of M
%define    curr r11             ; holds address of M
%define    FLOAT 4             ; holds address of M
%define    FLOAT4 16             ; holds address of M
%define    row_bytes r12
%define    tmp r13
%define    tmp2 r9
%define    r r14
%define    c r15

; %define    steps rdi

global start, step

section .bss
    COLS RESQ 1
    ROWS RESQ 1
    M RESQ 1
    STEP_V RESQ 1
    WEIGHT RESQ 1
    ROW_BYTES RESQ 1
    TMP_OFFSET RESQ 1
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

    imul rdi, FLOAT
    mov [ROW_BYTES], rdi

    xor rdx, rdx
    mov rax, [ROWS]
    mov rdi, 2
    idiv rdi
    ; inc rax
    imul rax, [COLS]
    imul rax, FLOAT
    ; mov rax, QWORD 5
    mov [TMP_OFFSET], rax

    mov    rsp, rbp
    pop    rbp

    ret

step:
    push    r8                   ; save registers
;     push    r13
;     push    r14
;     push    r15
;     push    rbx
    push    rbp
    mov     rbp, rsp

    mov [STEP_V], rdi               ; save params
    mov step_vector, [STEP_V]
    mov table, [M]

    movd xmm3, [WEIGHT] ; mov 32bits
    ; mov rax, 7
    ; mov xmm3, rax ; mov 32bits
	shufps xmm3, xmm3, 0h ; bierze [0..31] 4 razy
	; mask: w w w w
	xor eax, eax ; eax = 0
    ; mov rax, [TMP_OFFSET]
    ; mov rax, rsi
	cvtsi2ss xmm3, eax ; weź 0 z eax i wsadź je jako 0.000000 pod xmm [0..31]
	; mask: 0 w w w
    movups xmm5, xmm3
	; shufps xmm5, xmm3, 39h ; KUUUL, mi też są tylko trzy potrzebne XD

	; xmm3 - w w w 0
    ; movups [table], xmm3
    ; jmp finish




    mov row_bytes, [COLS]
    imul row_bytes, FLOAT

    mov iter, 0
    ; TODO: wygląda jakby przepisywało dobrze ale chór wie bo mi się nie chce sprawdzać
copy_step_v_to_table:
    ; step_vector

    ; // przepisz 0wy wiersz
	movups xmm0, [step_vector+iter]
	movups [table+iter], xmm0

    add iter, FLOAT4
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jl copy_step_v_to_table
    
minus_one_cell:

    sub iter, FLOAT
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jg minus_one_cell
    movups xmm0, [step_vector+iter]
	movups [table+iter], xmm0


    mov r, [ROW_BYTES]                     ; current row IN ROW_BYTES
rows_loop:
    mov c, 0                               ; current column = 0 // IN BYTES
cols_loop:
    mov tmp, table
    add tmp, r
    add tmp, c

	movups xmm0, [tmp] ; curr row

    add tmp, 4
	movd xmm2, [tmp]
	shufps xmm2, xmm2, 0h
	movaps xmm4, xmm2
	; xmm2: r r r r ; r to ta *, current, aktualna komórka
	; xmm4: r r r r
    
    sub tmp, [ROW_BYTES]
    sub tmp, 4
	movups xmm1, [tmp] ; prev row

    subps xmm4, xmm1 ; current - wagi, nwm czy ma być w tą czy w drugą TBH
	subps xmm2, xmm0 ; substract from value in current cell

	addps xmm4, xmm2

    movups xmm3, xmm5

    cmp c, 0 ; left border
    je mask_0110
    
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT
    cmp c, tmp
    je mask_1100

	shufps xmm3, xmm3, 39h ; KUUUL, mi też są tylko trzy potrzebne XD
    jmp continue

    mask_0110:
	shufps xmm3, xmm3, 38h ; KUUUL, mi też są tylko trzy potrzebne XD
    jmp continue
    mask_1100:
	shufps xmm3, xmm3, 9h ; KUUUL, mi też są tylko trzy potrzebne XD
    ; movups [table], xmm3

continue:
	mulps xmm4, xmm3 ; apply mask
	haddps xmm4, xmm4 ; a b c d -> _ _ a+b c+d
	haddps xmm4, xmm4 ; _ _ a+b c+d -> _ _ _ a+b+c+d

    ; movups [table], xmm4
    movd esi, xmm4
    
    mov tmp, table
    add tmp, [TMP_OFFSET]
    add tmp, r
    add tmp, c
    add tmp, 4

	; mov [tmp], DWORD 666
	mov [tmp], esi

next_col:
    add c, FLOAT
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT
    ; sub tmp, FLOAT
    ; sub tmp, FLOAT

    cmp c, tmp
    jle cols_loop

next_row:
    add r, [ROW_BYTES]
    cmp r, [TMP_OFFSET]
    jle rows_loop



sums_to_M:
    mov r, [ROW_BYTES]                     ; current row IN ROW_BYTES
rows_loop2:
    mov c, FLOAT                               ; current column = 0 // IN BYTES
cols_loop2:
    mov tmp, table
    add tmp, r
    add tmp, c

    mov tmp2, table
    add tmp2, [TMP_OFFSET]
    add tmp2, r
    add tmp2, c

	movups xmm0, [tmp]
	movups xmm1, [tmp2]
	subps xmm0, xmm1
	; subps xmm0, xmm0
	movups [tmp], xmm0

next_col2:
    add c, FLOAT4
    ; add c, FLOAT
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT
    jle cols_loop2
    ; TODO: not 3 divisible ughrs
    ; najlepiej przepisać końcówkę ręcznie i jebać może?
; minus_one_cell2:
;     sub iter, FLOAT
;     mov tmp, iter
;     add tmp, FLOAT4
;     cmp tmp, row_bytes
;     jg minus_one_cell2

;     movups xmm0, [step_vector+iter]
; 	movups [table+iter], xmm0

next_row2:
    add r, [ROW_BYTES]
    cmp r, [TMP_OFFSET]
    jle rows_loop2


    ; // TODO:
    ; // iteruj się po wierszach r=1..odpowiedni
    ; //    iteruj się po kolumnie c=1..odpowiednia
    ; //       weź 3 komórki w wierszu r-1 [c-1,c,c+1]
    ; //       weź 3 komórki w wierszu r [c-1,c,c+1]
    ; //       ogarnij sumy ważone jak miało być i wpisz w odp. komórkę tmp



    ; // iteruj się po wierszach r=1..odpowiedni
    ; //    iteruj się po kolumnie c=1..odpowiednia
    ; //       dodaj tmp do oryginalnej tablicy

finish:
    mov    rsp, rbp              ; restore register values
    pop    rbp
;     pop    rbx
;     pop    r15
;     pop    r14
;     pop    r13
    pop    r8
    ret
