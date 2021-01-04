%define    FLOAT 4             ; 4 bytes in float
%define    FLOAT4 16             ; 16 bytes is 4 floats

%define    table r8             ; holds address of M
%define    row_bytes r9
%define    step_vector r10            ; holds address of param (new input) of `step` call
%define    iter r11             ; iterator for copying step_vector to M
%define    tmp r12
%define    tmp2 r13
%define    r r14 ; current row
%define    c r15 ; current column
%define    weight_xmm xmm5
global start, step

section .bss
    COLS RESQ 1
    ROWS RESQ 1
    M RESQ 1
    STEP_V RESQ 1
    WEIGHT RESQ 1
    ROW_BYTES RESQ 1
    TMP_OFFSET RESQ 1

section .text

start:
    push    rbp
    mov     rbp, rsp

    movups [WEIGHT], xmm0 ; save params
    mov [COLS], rdi
    mov [ROWS], rsi
    mov [M], rdx

    imul rdi, FLOAT
    mov [ROW_BYTES], rdi ; save number of bytes in a row

    xor rdx, rdx    ; save offset of tmp part of matrix, where we'll save the increase/decrease
    mov rax, [ROWS]
    mov rdi, 2
    idiv rdi
    imul rax, [COLS]
    imul rax, FLOAT
    mov [TMP_OFFSET], rax

    mov    rsp, rbp
    pop    rbp
    ret

step:
    push    r12                   ; save registers
    push    r13
    push    r14
    push    r15

    push    rbp
    mov     rbp, rsp

    mov [STEP_V], rdi               ; save param
    mov step_vector, [STEP_V] ; load addresses
    mov table, [M]

    movd xmm3, [WEIGHT] 
	shufps xmm3, xmm3, 0h ; ([weight][weight][weight][weight])
	xor eax, eax
	cvtsi2ss xmm3, eax ; ([0][weight][weight][weight])
    movups weight_xmm, xmm3 ; save ([0][weight][weight][weight]) as default

    mov row_bytes, [ROW_BYTES] 
    mov iter, 0

copy_step_v_to_table:
	movups xmm0, [step_vector+iter] ; copy step vector as first row of M
	movups [table+iter], xmm0

    add iter, FLOAT4
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jl copy_step_v_to_table
    
copy_step_v_rest:
    sub iter, FLOAT ; copy rest (when no. columns not divisible by 4)
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jg copy_step_v_rest
    movups xmm0, [step_vector+iter]
	movups [table+iter], xmm0


; calculating pollution
    mov r, [ROW_BYTES]                     ; current row IN ROW_BYTES (current row offset)
rows_loop:
    mov c, 0                               ; current column = 0 (IN BYTES)
cols_loop:
    mov tmp, table
    add tmp, r
    add tmp, c

	movups xmm0, [tmp] ; curr row

    add tmp, 4 ; curr cell
	movd xmm2, [tmp]
	shufps xmm2, xmm2, 0h ; xmm2 = ([curr][curr][curr][curr])
	movaps xmm4, xmm2  ; xmm4 = ([curr][curr][curr][curr])
    
    sub tmp, [ROW_BYTES]
    sub tmp, 4
	movups xmm1, [tmp] ; previous row

	subps xmm2, xmm0 ; substraction: current row neighbours
    subps xmm4, xmm1 ; substraction: previous row neighbours

	addps xmm4, xmm2 ; sum neighbour differences

    movups xmm3, weight_xmm ; load default weight vector

    cmp c, 0 ; left border - set mask ([0][weight][weight][0])
    je mask_0110
    
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT
    cmp c, tmp
    je mask_1100 ; right border - set mask ([weight][weight][0][0])

    mask_1110:
	shufps xmm3, xmm3, 39h ; value not on the border - set mask ([weight][weight][weight][0])
    jmp continue

    mask_0110:
	shufps xmm3, xmm3, 38h
    jmp continue

    mask_1100:
	shufps xmm3, xmm3, 9h

continue:
	mulps xmm4, xmm3 ; apply mask
	haddps xmm4, xmm4 ; sum weighted differences
	haddps xmm4, xmm4

    movd edi, xmm4 ; save sum float
    mov tmp, table
    add tmp, [TMP_OFFSET]
    add tmp, r
    add tmp, c
    add tmp, 4
	mov [tmp], edi

next_col:
    add c, FLOAT
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT

    cmp c, tmp
    jle cols_loop

next_row:
    add r, [ROW_BYTES]
    cmp r, [TMP_OFFSET]
    jle rows_loop


; update pollution values in M
sums_to_M:
    mov r, [ROW_BYTES]                     ; current row IN ROW_BYTES (current row offset)
rows_loop2:
    mov c, FLOAT                               ; current column = 0 (IN BYTES)
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT4
    sub tmp, FLOAT
    cmp c, tmp
    jg rest_cols
cols_loop2:
    mov tmp, table ; load 4 cells of M
    add tmp, r
    add tmp, c

    mov tmp2, table ; load 4 cells of tmp (weighted differences sum)
    add tmp2, [TMP_OFFSET]
    add tmp2, r
    add tmp2, c

	movups xmm0, [tmp] ; update M with values in tmp
	movups xmm1, [tmp2]
	subps xmm0, xmm1
	movups [tmp], xmm0
next_col2:
    add c, FLOAT4
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT4
    sub tmp, FLOAT
    cmp c, tmp
    jle cols_loop2
rest_cols:
    mov tmp, [ROW_BYTES] ; update last colmuns of M (when no. cols non divisible by 4)
    sub tmp, FLOAT
    cmp c, tmp
    jge next_row2

    mov tmp, table ; load 4 cells of M
    add tmp, r
    add tmp, c

    mov tmp2, table ; load 4 cells of tmp (weighted differences sum)
    add tmp2, [TMP_OFFSET]
    add tmp2, r
    add tmp2, c

	movups xmm0, [tmp] ; update single M cell value
	movups xmm1, [tmp2]
    shufps xmm1, xmm1, 0h ; 
	xor eax, eax
	cvtsi2ss xmm1, eax
	shufps xmm1, xmm1, 1h
	subps xmm0, xmm1
	movups [tmp], xmm0

    add c, FLOAT
    jmp rest_cols

next_row2:
    add r, [ROW_BYTES]
    cmp r, [TMP_OFFSET]
    jle rows_loop2

finish:
    mov    rsp, rbp              ; restore register values
    pop    rbp
    pop    r15
    pop    r14
    pop    r13
    pop    r12
    ret
