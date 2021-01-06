%define    FLOAT 4                     ; 4 bytes in float
%define    FLOAT4 16                   ; 16 bytes is 4 floats

%define    table r8                    ; holds address of M
%define    row_bytes r9                ; holds address of ROW_BYTES
%define    step_vector r10             ; holds address of param (new input) of `step` call
%define    iter r11                    ; iterator for copying step_vector to M
%define    tmp r12
%define    tmp2 r13
%define    r r14                       ; current row
%define    c r15                       ; current column

%define    prev_neigh_xmm xmm1
%define    curr_neigh_xmm xmm0
%define    curr1_xmm xmm2
%define    curr2_xmm xmm3
%define    weight_xmm xmm5
%define    mask_xmm xmm4

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

    movups [WEIGHT], xmm0              ; save params
    mov [COLS], rdi
    mov [ROWS], rsi
    mov [M], rdx

    imul rdi, FLOAT
    mov [ROW_BYTES], rdi               ; save number of bytes in a row

    xor rdx, rdx                       ; save offset of tmp part of matrix, where we'll save the increase/decrease
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
    push    r12                        ; save registers
    push    r13
    push    r14
    push    r15

    push    rbp
    mov     rbp, rsp

    mov [STEP_V], rdi                  ; save param
    mov step_vector, [STEP_V]          ; load addresses
    mov table, [M]

    movd weight_xmm, [WEIGHT] 
	shufps weight_xmm, weight_xmm, 0h  ; ([weight][weight][weight][weight])
	xor eax, eax
	cvtsi2ss weight_xmm, eax           ; ([0][weight][weight][weight])

    mov row_bytes, [ROW_BYTES] 
    mov iter, 0

copy_step_v_to_table:
	movups xmm0, [step_vector+iter]    ; copy step vector as first row of M
	movups [table+iter], xmm0

    add iter, FLOAT4
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jl copy_step_v_to_table
    
copy_step_v_rest:
    sub iter, FLOAT                    ; copy rest (when no. columns not divisible by 4)
    mov tmp, iter
    add tmp, FLOAT4
    cmp tmp, row_bytes
    jg copy_step_v_rest
    movups xmm0, [step_vector+iter]
	movups [table+iter], xmm0


                                       ; calculating pollution
    mov r, [ROW_BYTES]                 ; current row IN ROW_BYTES (current row offset)
rows_loop:
    mov c, 0                           ; current column = 0 (IN BYTES)
cols_loop:
    mov tmp, table
    add tmp, r
    add tmp, c

	movups curr_neigh_xmm, [tmp]       ; curr row

    add tmp, 4                         ; curr cell
	movd curr1_xmm, [tmp]
	shufps curr1_xmm, curr1_xmm, 0h    ; curr1_xmm = ([curr][curr][curr][curr])
	movaps curr2_xmm, curr1_xmm        ; curr2_xmm = ([curr][curr][curr][curr])
    
    sub tmp, [ROW_BYTES]
    sub tmp, 4
	movups prev_neigh_xmm, [tmp]       ; previous row

	subps curr1_xmm, curr_neigh_xmm    ; substraction: current row neighbours
    subps curr2_xmm, prev_neigh_xmm    ; substraction: previous row neighbours

	addps curr2_xmm, curr1_xmm         ; sum neighbour differences

    movups mask_xmm, weight_xmm        ; load default weight vector

    cmp c, 0                           ; left border - set mask ([0][weight][weight][0])
    je mask_0110
    
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT
    sub tmp, FLOAT
    sub tmp, FLOAT
    cmp c, tmp
    je mask_1100                       ; right border - set mask ([weight][weight][0][0])

    mask_1110:
	shufps mask_xmm, mask_xmm, 39h     ; value not on the border - set mask ([weight][weight][weight][0])
    jmp continue

    mask_0110:
	shufps mask_xmm, mask_xmm, 38h
    jmp continue

    mask_1100:
	shufps mask_xmm, mask_xmm, 9h

continue:
	mulps curr2_xmm, mask_xmm          ; apply mask
	haddps curr2_xmm, curr2_xmm        ; sum weighted differences
	haddps curr2_xmm, curr2_xmm

    movd edi, curr2_xmm                ; save sum float
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
    mov r, [ROW_BYTES]                 ; current row IN ROW_BYTES (current row offset)
rows_loop2:
    mov c, FLOAT                       ; current column = 0 (IN BYTES)
    mov tmp, [ROW_BYTES]
    sub tmp, FLOAT4
    sub tmp, FLOAT
    cmp c, tmp
    jg rest_cols
cols_loop2:
    mov tmp, table                     ; load 4 cells of M
    add tmp, r
    add tmp, c

    mov tmp2, table                    ; load 4 cells of tmp (weighted differences sum)
    add tmp2, [TMP_OFFSET]
    add tmp2, r
    add tmp2, c

	movups xmm0, [tmp]                 ; update M with values in tmp
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
    mov tmp, [ROW_BYTES]               ; update last colmuns of M (when no. cols non divisible by 4)
    sub tmp, FLOAT
    cmp c, tmp
    jge next_row2

    mov tmp, table                     ; load 4 cells of M
    add tmp, r
    add tmp, c

    mov tmp2, table                    ; load 4 cells of tmp (weighted differences sum)
    add tmp2, [TMP_OFFSET]
    add tmp2, r
    add tmp2, c

	movups xmm0, [tmp]                 ; update single M cell value
	movups xmm1, [tmp2]
    shufps xmm1, xmm1, 0h
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
    mov    rsp, rbp                    ; restore register values
    pop    rbp
    pop    r15
    pop    r14
    pop    r13
    pop    r12
    ret
