.text
.global ppm
/*
r0 - M
r1 - cols
r2 - rows
r3 - RGB_shift
[fp, #4] - change
M  r0
*/
.balign 4
ppm:
	push {r11}
	add r11, sp, #0

    sub r3, #1
    
    mul r4, r1, r2      @ r4 = cols*rows, r1, r2 free
    mov r2, #3
    mul r1, r4, r2      @ r1 = cols*rows*3=size, r2 free, r4 free
    add r1, r1, r0      @ r1 = end of M @ PLUS MINUS 3

    add r0, r0, r3      @ set M on R/G/B 'column'

	ldr r2, [fp, #4] @ load change param

    @r4, r3 free

    mov r3, r0

_loop:
    cmp r3, r1
    bge _finish

    ldrb r4, [r3]
    adds r4, r2
    bmi _zero
    cmp r4, #255
    bgt _max

    b _next

    _max:
    mov r4, #255
    b _next

    _zero:
    mov r4, #0

    _next:
    strb r4, [r3]
    add r3, #3
    b _loop

_finish:
	add sp, r11, #0
	pop {r11}
	bx lr
