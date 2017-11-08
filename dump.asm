org 0x7c00
bits 16
DW 0X6066 ;pushad eax,ecx,edx,ebx,esp,ebp,esi,edi
push gs
push fs
push es
push ss
push ds
push cs
xor di,di
mov ax,0xb800
mov es,ax
mov ah,0x0f
pop dx		;16 bit segment registers
call l2
pop dx
call l2
pop dx
call l2
pop dx
call l2
pop dx
call l2
pop dx
call l2
pop edx		;32 bit general perpuse regsters
call l1
pop edx
call l1
pop edx
call l1
pop edx
call l1
pop edx
call l1
pop edx
call l1
pop edx
call l1
pop edx
call l1
cli
db  0xf4,0xeb,0xfc
l1:
mov cx,32
.start:
mov al,30h
shl edx,1
adc al,0
stosw
loop .start
add di,48*2
ret
l2:
mov cx,16
mov al,30h
.start:
shl dx,1
adc al,0
stosw
loop .start
add di,64*2 
ret




