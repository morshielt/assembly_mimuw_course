%define    r r8
%define    j r9
%define    c r10
%define    i r11
; %define    cols r11                       ;
; %define    rows r13                       ;
%define    to_shift r14                      ;
%define    from_shift r15
; %define    tmp2 rax
%define    neighbours rbx
%define    table rcx ; current row
%define    steps rdi
; %define    c rdx ; current column
%define    tmp rax



global start, run

section .bss
    COLS RESQ 1
    ROWS RESQ 1
    T RESQ 1
    CTR RESQ 1

; section .data
    ; int ctr = 0;
    ; CTR DB 0x0
section .text
start:
    mov [COLS], rdi
    mov [ROWS], rsi
    mov [T], rdx
    mov rax, 0
    mov [CTR], rax
    ret
    

    ; lea rcx, [rel COLS]
    ; mov rcx, rdi
    ; lea rcx, [rel ROWS]
    ; mov rcx, rsi
    ; lea rcx, [rel T]
    ; mov rcx, rdx

run:

    ; push    r8
    ; push    r9
    ; push    r10
    ; push    r12
    ; push    r14
    ; push    r15
    ; push    rbx
    ; push    rcx
    ; push    rdx
    ; push    rdi
    ; push    rbp
    ; mov    rbp, rsp                    ; restore register values


    ; mov steps, rdi

    ; xor r8, r8
    ; xor r9, r9
    ; xor r10, r10
    ; xor r12, r12
    ; xor r14, r14
    ; xor r15, r15

    ; xor rbx, rbx
    ; xor rcx, rcx
    ; xor rax, rax
    mov table, [T]

step_loop:
    ; for (size_t step = 0; step < steps; step++) {
    mov tmp, [COLS] ; tmp = cols * rows
    imul tmp, [ROWS]

    ;     int from = (ctr % 2) * cols * rows;
    mov from_shift, [CTR]
    imul from_shift, tmp
    ; cmp from_shift, 0
    ; jne next_step



    ;     int to = ((from + 1) % 2) * cols * rows;
    xor [CTR], BYTE 1 ; flip 0/1
    mov to_shift, [CTR]
    imul to_shift, tmp




    mov r, 0 ; current row column   rc = 0

rows_loop:
    mov c, 0
    ;     for (size_t r = 0; r < rows; r++) {
    ;         for (size_t c = 0; c < cols; c++) {

    ;             int neighbours = 0;

cols_loop:
    mov neighbours, 0

    mov j, -1
j_row_loop:
    ;             for (int j = -1; j <= 1; j++) {
        ;     (r + j >= 0 && r + j < rows) gud
    
    mov tmp, r
    add tmp, j
    cmp tmp, 0
    jl skip_row         ; r + j < 0
    cmp tmp, [ROWS]
    jge skip_row        ; r + ; >= ROWS
    
    mov i, -1
i_col_loop:
    ;                 for (int i = -1; i <= 1; i++) {   


    ; c + i >= 0 && c + i < cols
    mov tmp, c
    add tmp, i
    cmp tmp, 0
    jl skip_col     ; c + i < 0
    cmp tmp, [COLS]
    jge skip_col ; c + i >= COLS

    mov tmp, r
    add tmp, j
    imul tmp, [COLS]
    add tmp, c
    add tmp, i
    add tmp, from_shift

    cmp [table + tmp], BYTE '1'
    jne skip_col
    inc neighbours
    ;                     if (c + i >= 0 && c + i < cols && r + j >= 0 &&
    ;                         r + j < rows) {
    ;                         if (T[(r + j) * cols + (c + i) + from] == '1')
    ;                             neighbours++;
    ;                     }
skip_col: 
    inc i
    cmp i, 1
    jle i_col_loop

skip_row:
    inc j
    cmp j, 1
    jle j_row_loop

eval:
    mov tmp, r
    imul tmp, [COLS]
    add tmp, c
    add tmp, from_shift

    ;             if (T[r * cols + c + from] == '1') neighbours--;
    cmp [table + tmp], BYTE '1' ; if we counted alive cell itself, subtract 1
    jne eval_neighbours
    dec neighbours

eval_neighbours:
    cmp neighbours, 3
    je live
    cmp neighbours, 2
    jne die
    cmp [table + tmp], BYTE '1'
    je live

    die:
    mov tmp, r
    imul tmp, [COLS]
    add tmp, c
    add tmp, to_shift

    mov [table + tmp], BYTE '0'
    jmp next

    live:
    mov tmp, r
    imul tmp, [COLS]
    add tmp, c
    add tmp, to_shift

    mov [table + tmp], BYTE '1'


    ;             if (neighbours == 3 ||
    ;                 (neighbours == 2 && T[r * cols + c + from] == '1')) {
    ;                 T[r * cols + c + to] = '1';
    ;             } else {
    ;                 T[r * cols + c + to] = '0';
    ;             }
    ;         }
    
next:
    inc c
    cmp c, [COLS]
    jne cols_loop    

    inc r
    cmp r, [ROWS]
    jne rows_loop

next_step:
   ; TODO: uncomment 
    dec steps
    cmp steps, 0
    jnz step_loop




;;;;;;;
    ; mov    rsp, rbp                    ; restore register values
    ; pop    rbp
    ; pop    rdi
    ; pop    rdx
    ; pop    rcx
    ; pop    rbx
    ; pop    r15
    ; pop    r14
    ; pop    r12
    ; pop    r10
    ; pop    r9
    ; pop    r8
    ret
