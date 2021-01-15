.text
.global ppm

@ r0 - M - array containing: 
@   [R0][G0][B0][R1][G1][B1][R2][G2][B2]... 
@   (three components separately for each pixel)
@ r1 - number of rows
@ r2 - number of columns
@ r3 - chosen component (RGB_shift) (1/2/3)
@ [fp, #4] - change (value to add to chosen component)

.balign 4
ppm:
    push {r11}
    add r11, sp, #0
    push {r4}

    sub r3, #1          @ shift is represeted by (1/2/3), but to get the offset in array we need to decrease it
    mul r4, r1, r2      @ r4 = cols * rows
    mov r2, #3
    mul r1, r4, r2      @ r1 = cols * rows * 3 = size
    add r1, r1, r0      @ r1 = end of M (M shifted by size)

    add r0, r0, r3      @ r3 = set M on R/G/B 'column'

	ldr r2, [fp, #4]    @ r2 = change param
    mov r3, r0

_loop:
    cmp r3, r1          @ check if we're past end of array
    bge _finish

    ldrb r4, [r3]       @ load component of pixel
    adds r4, r2         @ add change
    bmi _zero           @ if value is negative, go to write 0
    cmp r4, #255        @ check if we're past max value
    bgt _max            @ if yes, go to write max
    b _next       

    _max:
    mov r4, #255
    b _next

    _zero:
    mov r4, #0

    _next:
    strb r4, [r3]       @ write the computed value
    add r3, #3          @ go to the same component of next pixel
    b _loop

_finish:
	pop {r4}
    add sp, r11, #0
    pop {r11}
	bx lr
