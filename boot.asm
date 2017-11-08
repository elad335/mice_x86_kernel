;-------------------------------------------------------
;creator: Elad Ashkcenazi 
;year : 2017
;goal : to create an 'alive and kicking' 32 bit  bootable game
;requirements:	;don't worry , in 2017+ 99.999% of people answer this requirements
;486+ cpu	;some instructions are only supported for this cpu and up
;4 GB of ram	;the highest address of ram im using is 0xf1040400 for the stack, which is perpuselly is almost 4gb
;
;-------------------------------------------------------

org 0x7c00      ; the real memloc that the bios loads the sector into is 0x0000:7c00 and not 0x07c0:0000!-
use16
%include "defines.asm"
%include "bootldr.asm"
;Some of the algoritems used in this project are exteremly smart yet very simple ,if something is hard to to understand just ask me and I will explain to you how it works:)

;-----------------------------------sector2  >= $ = 32 bit pm! ---------------------------------------------    
use32
bits32:
	mov ss,edx
	mov ds,edx
	mov gs,edx		;dont worry, the high 16 bits will not affect anything ,its just the weird way pm works.
	mov fs,edx
	mov es,edx      
	mov esp,stack_start
	
	push byte 0		;turn off If flag,i/o prvlf flags to ring 0 and clear tf flag but also clearing all the flags! all that with only two instructions:D
	popfd
	call is_a20_on?
	call    a20wait
    mov     al,0xad
    out     0x64,al
    call    a20wait
    mov     al,0xdd
    out     0x64,al
	
    call    a20wait
    mov     al,0xae
    out     0x64,al
	call    a20wait
	call is_a20_on?
	in al,0x92
	or al,2
	and al,0xfe
	out 0x92,al
	call is_a20_on?
	in al,0xee
	push noA20
is_a20_on?:
	pushad
	mov edi,0x112345
	mov esi,0x012345
	mov [esi],esi
	mov [edi],edi
	cmpsd
	popad
	jne a20_on
	ret
noA20:
a20_on:
	;------------ ICW 1 - tell pic that we want to initialize him
	mov al,0x11
	out 0x20,al
	out 0xa0,al
	;------------ ICW 2 - tell the pic the interrupts gates we want to use for irq's (our are interrupts 0x30 - 0x37 (irq 0-7) and 0x38 - 0x40 (irq 8- 15)
	mov al,0x30
	out 0x21,al
	mov al,0x38
	out 0xa1,al
	;------------ ICW 3 - pair pic master and slave togheter ( even I don't really know why ICW 3 is needed , stupid Intel.)
	mov al,0x4
	out 0x21,al
	mov al,0x2
	out 0xa1,al
	;------------ ICW 4 (the last one) - specifies intarnal pic configurations :	
	;bit 0 (uPM): set - 80x86 mode , clreared - mcs 80/85 mode
	;bit 1 (AEOI): If set, on the last interrupt acknowledge pulse, controller automatically performs End of Interrupt (EOI) operation.
	;bit 2 (M/S): Only use if BUF (bit 3) is set.
	;bit 3 (BUF): set - buffered, cleared - not in beffered mode.
	;bit 4-7 (should be zero!) : bit 4 (SFNM) controlls Special Fully Nested Mode - from what I read , it's not supported by x86 cpu's (should be 0), bit 5-7 are reserved and must be cleared.
	mov al,1
	out 0x21,al
	out 0xa1,al
	;------------ disables all irq's exept the keyboard irq
	mov al,~2	;0xd , enables only keyboard interrupt.
	out pic1_imr ,al
	mov al,0xff
	out pic2_imr ,al
	;--------------------
	call    a20wait
	mov al,20h
	out 0x64,al
	in al,0x60
	or al,1
	mov ch,al
	call    a20wait
	mov al,60h
	out 0x64,al
	call    a20wait
	mov al,ch
	out 0x60,al
;	-------------------
	lidt [idtr]	;initializing ny interrupt table
	xor eax,eax
	dw 0x2e2e
	div eax
	mov esi, end_menu - 256*3
	mov eax,2
	int 21h
	mov esi,MENU ;org_2 + MENU - bits32
	xor ebx,ebx
	mov eax,1
	xor ecx,ecx
	int 21h
	cli
	disable_video_output
	halt
	;call org_2 + SHOWPCX- bits32 	
.keyboard_led_check:
	call    a20wait
	mov al,0edh			;led command 
	mov dx,0x60
	out dx,al
	call    a20wait
	mov al,7			;caps lock , scroll lock & numlock are active.
	out dx,al
.l1:		;wait exatly 2 seconds before turning off keyboard's led's.
	rdtsc		;modern timer instead of int 1ah,0; returns ticks in edx:eax while edx contains 32 high bits and eax the low ones. ;edx = seconds , eax = eax/(2^32) of a second
	mov ebp,edx
	inc ebp
	inc ebp
	.loop:
	rdtsc
	cmp edx,ebp
	jb .loop
	mov dx,0x60
	mov al,0edh
	out dx,al
	call    a20wait
	xor al,al 
	out dx,al			 ;caps lock , scroll lock & numlock are disable.
main_game:	
	halt
	zerob 512-( $ - bits32 ) ;its a macro , it's defined in "define's - 1 .asm" 
%include "idt.asm"
procedores:
.show_exeption_loc:				;display binary representation of the instruction that causes the exeption using pixels black and white only
	mov ebx,[esp+4]
	mov edi,vid_mem + 320
	mov cl,32
.l1:
	shl ebx,1
	salc 		;0x0f is white, 0 is black ; honestly the best use of this instruction ever:)
	and al,0fh
	stosb
	loop .l1
	sub edi, 352
    mov cl,8
	mov eax,0x0a010a01
	rep stosd
	ret
MENU:	
incbin "PROJECT-exp7.pcx"
end_menu:
double_fault_pcx:
incbin "double_fault.pcx"
end_double:
vga_defualt_pallete:
df 0x000000, 0x0000a8, 0x00a800, 0x00a8a8, 0xa80000, 0xa800a8, 0xa85400, 0xa8a8a8, 0x545454, 0x5454fc, 0x54fc54, 0x54fcfc, 0xfc5454, 0xfc54fc, 0xfcfc54, 0xfcfcfc, 0x000000, 0x141414, 0x202020, 0x2c2c2c, 0x383838, 0x444444, 0x505050, 0x606060, 0x707070, 0x808080, 0x909090, 0xa0a0a0, 0xb4b4b4, 0xc8c8c8, 0xe0e0e0, 0xfcfcfc, 0x0000fc, 0x4000fc, 0x7c00fc, 0xbc00fc, 0xfc00fc, 0xfc00bc, 0xfc007c, 0xfc0040, 0xfc0000, 0xfc4000, 0xfc7c00, 0xfcbc00, 0xfcfc00, 0xbcfc00, 0x7cfc00, 0x40fc00, 0x00fc00, 0x00fc40, 0x00fc7c, 0x00fcbc, 0x00fcfc, 0x00bcfc, 0x007cfc, 0x0040fc, 0x7c7cfc, 0x9c7cfc, 0xbc7cfc, 0xdc7cfc, 0xfc7cfc, 0xfc7cdc, 0xfc7cbc, 0xfc7c9c, 0xfc7c7c, 0xfc9c7c, 0xfcbc7c, 0xfcdc7c, 0xfcfc7c, 0xdcfc7c, 0xbcfc7c, 0x9cfc7c, 0x7cfc7c, 0x7cfc9c, 0x7cfcbc, 0x7cfcdc, 0x7cfcfc, 0x7cdcfc, 0x7cbcfc, 0x7c9cfc, 0xb4b4fc, 0xc4b4fc, 0xd8b4fc, 0xe8b4fc, 0xfcb4fc, 0xfcb4e8, 0xfcb4d8, 0xfcb4c4, 0xfcb4b4, 0xfcc4b4, 0xfcd8b4, 0xfce8b4, 0xfcfcb4, 0xe8fcb4, 0xd8fcb4, 0xc4fcb4, 0xb4fcb4, 0xb4fcc4, 0xb4fcd8, 0xb4fce8, 0xb4fcfc, 0xb4e8fc, 0xb4d8fc, 0xb4c4fc, 0x000070, 0x1c0070, 0x380070, 0x540070, 0x700070, 0x700054, 0x700038, 0x70001c, 0x700000, 0x701c00, 0x703800, 0x705400, 0x707000, 0x547000, 0x387000, 0x1c7000, 0x007000, 0x00701c, 0x007038, 0x007054, 0x007070, 0x005470, 0x003870, 0x001c70, 0x383870, 0x443870, 0x543870, 0x603870, 0x703870, 0x703860, 0x703854, 0x703844, 0x703838, 0x704438, 0x705438, 0x706038, 0x707038, 0x607038, 0x547038, 0x447038, 0x387038, 0x387044, 0x387054, 0x387060, 0x387070, 0x386070, 0x385470, 0x384470, 0x505070, 0x585070, 0x605070, 0x685070, 0x705070, 0x705068, 0x705060, 0x705058, 0x705050, 0x705850, 0x706050, 0x706850, 0x707050, 0x687050, 0x607050, 0x587050, 0x507050, 0x507058, 0x507060, 0x507068, 0x507070, 0x506870, 0x506070, 0x505870, 0x000040, 0x100040, 0x200040, 0x300040, 0x400040, 0x400030, 0x400020, 0x400010, 0x400000, 0x401000, 0x402000, 0x403000, 0x404000, 0x304000, 0x204000, 0x104000, 0x004000, 0x004010, 0x004020, 0x004030, 0x004040, 0x003040, 0x002040, 0x001040, 0x202040, 0x282040, 0x302040, 0x382040, 0x402040, 0x402038, 0x402030, 0x402028, 0x402020, 0x402820, 0x403020, 0x403820, 0x404020, 0x384020, 0x304020, 0x284020, 0x204020, 0x204028, 0x204030, 0x204038, 0x204040, 0x203840, 0x203040, 0x202840, 0x2c2c40, 0x302c40, 0x342c40, 0x3c2c40, 0x402c40, 0x402c3c, 0x402c34, 0x402c30, 0x402c2c, 0x40302c, 0x40342c, 0x403c2c, 0x40402c, 0x3c402c, 0x34402c, 0x30402c, 0x2c402c, 0x2c4030, 0x2c4034, 0x2c403c, 0x2c4040, 0x2c3c40, 0x2c3440, 0x2c3040, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000
a20wait:
	in      al,0x64
	test    al,2
    jnz     a20wait
	ret
a20wait2:
	in      al,0x64
	test    al,1
	jnz     a20wait
	ret
	