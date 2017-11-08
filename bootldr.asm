;-------------------------------------------------------
;creator: Elad Ashkcenazi 
;year : 2017
;goal : to create a 32 bit semi-kernel bootable game
;requirements:	;don't worry , in 2017+ 99.999% of people answer this requirements
;64 bit and AVX capable cpu
;4 GB of ram	;altouogh as of now the highest address of ram im using is 0x00820200 for the stack
;-------------------------------------------------------
org 0x7c00
;include "defines.asm"
	cli
	xor dh,dh ; dl contains disk number!!
	mov si, msg0
	xor di,di
	mov ds,di
	mov [0x84],dx	;protecting the disk number from anything that could happen as you can see:)
	mov ecx,0xc0000080   ; EFER (64 bit config MSR register)
	rdmsr
	or eax,1 << 8	; 64bit's bit setting.
	wrmsr
	mov dx,3d4h
	mov al,0ah
	out dx,al
	inc dx
	mov al,3fh
	out dx,al
	mov ax,0xec00
	mov bl,2
	int 15h
;	----------- disable the cursur in text mode. 
	push text_mem16
	pop es	  
	mov ah,0fh	  ;future use(hint ,hint :its a char color)
	mov dx,0x60		  ;keyboard port
first_msg:		;optimized from using the 10h int
	lodsb		
	stosw		;ah = color ; al = char ; es:di = video memory	; ds:si = msg0
	cmp byte [si],3 	;♥ simbol
	je .l1
	cmp [si],dh		;dx = 0060 so it works, saved one byte from doing cmp [si],0
	jne first_msg
	add di,24*2		;80(lengh of 1 line)-56(lengh of text line)*2
	inc si
	jmp first_msg
.l1:
	mov al ,0bah		;mov ax,38bah is not neccerlly
	mov di ,81*2+1
.color:
	inc ah
	and ah,0x3f
	or ah ,0x38		;always turning off bit 11 but setting bits 10,9,8 and saving the low 4 bits . this is because we want to increase the char color but preventing the background from any change. 
	mov byte [es:di],ah
	inc di
	scasb			;optimized from cmp byte [es:di+1],186
	je esc?
	jmp .color
;	-----------	
esc?:	
	in al,dx
	dec al
	jne esc?
;	----------------
	mov byte [es:53*2+1],0x39
.end:
	in al,dx
	or al,al
	jns .end
	mov dx,bx
	mov si,DAP
	mov ah,0x42
	int 13h
	mov byte [0x7dfe],0x4000  ; allocate thee first 1 GB of the usb stick to ram.
	.l1:
	mov si,DAP
	mov dx,[0x84]
	mov ah,0x42
	add [DAP.sector],128
	int 13h
	dec byte [0x7dfe]
	jne .l1
;	----------------
	mov ax,0x2401
	int 15h
	
	jmp 0:org_2
	msg0: dw 0xcdc9,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0xcdcd,0x2d5b,0xcd5d,0x0e5b,0xcd5d,0x785b,0xbb5d
	 db 0x0
	 db 186,"welcome to Resting Bitch OS v0.00.64a                 ",186,00h
	 db 186,"please press esc to do stuff...                       ",186,00h
	 db 200,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,188,3
	
DAP:
	dw 0x10
	dw 0x7f 		     ;number of sectors to read + 1
	dw 0xffff			;offset
	dw 0xffff			;

.sector:	dq 1		;
;
;gdtr:
;	dw  gdt.end - gdt - 1	 ; gdt size -1
;	dd  gdt ;linear address of the gdt
;gdt:			;exetremely temporerly gdt table!,  ensures that DAP offsets above 0x100000 are handled propely.
;	dq 0		 ;null descriptor
;.@data:
;	dw 0ffffh	   ;segment limit first 16 bit
;	dw 0		 ;base first 16 bit
;	db 0		 ;base 24-17 another bits 
;	db 10010010b	 ;accsess byte 
;	db 10101111b	 ;high 4 bits (flags) low 4 bits (limit 4 last bits)(limit is 20 bit!)
;	db 0		 ;base 8 highest bits
;.@code:
;	dw 0ffffh	   ;segment limit first 16 bit
;	dw 0		 ;base first 16 bit
;	db 0		 ;base 24-17 another bits 
;	db 10011010b	 ;accsess byte 
;	db 10101111b	 ;high 4 bits (flags) low 4 bits (limit 4 last bits)(limit is 20 bit!)
;	db 0		 ;base 8 highest bits
;.end:
times 510-($ - $$) db 0 ;$$ = start of the file = 0x7c00 , learn more about zero macros in "define's - 1.asm"
 dw 0xaa55		 ; boot signature
 