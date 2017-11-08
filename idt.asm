idtr:
	dw 511			;sizeof sector -1 cuase you have to sub 1.
	dd idt_loc
idt:	
interrupt0x0_gate:		;#number/0 exeption 
    int3_gate  int0x0_offset	
interrupt0x1_gate:		;#DB_exeption used in my single step debug mode.
    int_gate  int0x1_offset	
interrupt0x2_gate:		;#NMI exeption,
    int_gate  int0x2_offset	
interrupt0x3_gate:		;#breakpoint exeption
    trap_gate  int0x1_offset	;this is not a mistake! int 1 routine will serve also as a breakpoint(I don't see much of a diffrence between them so I decided it's best that one routine will serve them both.)
	zeroq (0x6 - 0x4)		
	
interrupt0x6_gate:			;#UD_exeption undefined / invalid instruction , #the_end
	int_gate  int0x6_offset
	zeroq (0x8 - 0x7)

interrupt0x8_gate:			;#double_fault , #the_end
	int_gate  int0x8_offset
	zeroq (0x21 - 0x9)
interrupt0x21_gate:
	trap3_gate  int0x21_offset
	zeroq (0x31 - 0x22)
interrupt0x31_gate:			;interrupts 0x30 - 0x40 will serve as my irq's 0 - 15  handlers  , this specific interrupt is the irq 1's keyboard handler.
	int_gate  int0x31_offset
zerob 512-($-idt)

int_functions:
interrupt0x0:			;divide by zero exeption ; as 0/0 can be 1,2,3,4... or even -1, -2 ,-3 -4... and also i,2i,3i,4i... and  (sqrt i), 2(sqrt i), 3(sqrt i)...(every complex number possiable including 0.)
	pushad
	cli
	mov ebx,[esp+32]
	cmp word [ebx],0x2e2e	; ring 0 password
	jne .real_devision
	mov eax,8
	mov gs,eax
	mov fs,eax
	mov es,eax
	mov ds,eax
	;mov word [esp+32+16],0x10	;ss pointer ;I think it will be best if I leave ss regsiter be from the moment after the os enters Protected Mode
	mov [esp+32+4],cs
	add dword [esp+32],4
	popad
	iretd
.real_devision:
	mov ecx,3e80h
	xor eax,eax
	mov edi,vid_mem
	rep stosd
	call procedores.show_exeption_loc
	mov byte [vid_mem + 320*2 + 1],0fh
	mov dword [vid_mem + 320*3],0x0f000f00
	mov byte [vid_mem + 320*4 + 1],0fh
	halt
;.restart?:
	;in al,0x60
	;cmp al,0x15   ;y pressed
	;je .restore_eax
	;cmp al,0x31   ;n pressed
	;jne .restart?
;	jmp interrupt0x21.restart
	
	
	
	
;.make_division_by_zero_a_nop:
;	mov ebp,2
;	cmp word [ebx],0xf766
;	cmove ebp,3
;	cmp [ebx],
;	add dword [esp+32],ebp
;	popad
;	iretd
	;mov ecx,[ebx]
	;cmp cx,0xf766  ;16 bit devision 
	;je .l16
	;cmp cl,0xf7
	;je .l32
	;jmp .l8
	
.l8:

	
	
interrupt0x1:
	push byte 0
	pushad
	cli
	mov ecx,0x3e80
	mov esi,vid_mem
	mov edi,0xc00000
.l1:
	xchg eax,[esi]
	xchg eax,[edi]
	xchg eax,[esi]
	add esi,4
	add edi,4
	loop .l1
.l2:
	add esp,36			;because pushad
	call procedores.show_exeption_loc
	sub esp,36
	in al,0x60
	cmp al,0x3b	;f1 key
	jne .l2
	mov ecx,0x3e80
	mov esi,vid_mem
	mov edi,0xc00000
.l3:
	xchg eax,[esi]
	xchg eax,[edi]
	xchg eax,[esi]
	add esi,4
	add edi,4
	loop .l3
	pop eax
	popad
	iretd
interrupt0x2:
	iretd
interrupt0x6:					;#UD_exeption
	xor esi,esi
.start:
    mov edi,vid_mem
	mov ecx,1000
	.blind:
	rdseed ebp
	mov si,bp
	rdrand edx
	mov word [edi + esi] ,dx
	shr ebp,0x10
	shr edx,0x10
	mov byte [edi + ebp] ,dl
	loop .blind
	xor eax,eax
	mov cx,0x3e80
	rep stosd
	in al,0x60
	cmp al,0x48
	je .tell_me
	jmp	.start
.tell_me:			;where it happened... :D
	call procedores.show_exeption_loc
.l1:
	in al,0x60
	dec al
	jne .l1
	xor eax,eax
	;int 0x21	;reboot , diabled becuse interrupt 0x21 is the next stop of eip after interrup 0x6
interrupt0x8:
	mov esi, end_double - 256*3
	mov eax,2
	pushfd
	push cs
	call interrupt0x21
	mov esi,double_fault_pcx ;org_2 + MENU - bits32
	xor ebx,ebx
	mov eax,1 ;after tring again and again I found out that when an interrupt is called registers are not safe from change and eax is always changed.
	xor ecx,ecx
	pushfd
	push cs
	call interrupt0x21
	halt
interrupt0x21: 	;that's the main os interrupt
	pushad
	or eax,eax
	je near .restart 	
	dec eax
	je near .show_pcx
	dec eax
	je near .set_palette
	cmp eax,13h
	je .gui_320_200
	popad
	iretd
.restart:				;only do a restart to the computer!!!!! fuction 0 (eax == 0)
	xor eax,eax
	mov esi,vid_mem
	mov ecx,0xf3e80f
	rep stosd			;clear the video buffer with black color
	mov al,0x61
	mov dx,0x3c2
	out dx,al			;disable direct access to video buffer to prevent changes to the screen(graphics wise).
;   -----------------------
	mov al,1
	mov dx,3c4h
	out dx,al
	inc edx
	in al,dx
	and al,~(1<<5)
	out dx,al			;diable the display output from obvios reasons.
;		---------------
	halt
	lidt [.illegal_idtr] 	;illigal idtr loader, so even the smallest interrupt or exeption fired will cause a reboot.:)
	jmp 0x0:$				;cs points to the null descriptor, witch will genertate a restart:)
.illegal_idtr:
	dw 0
	dd 0
.show_pcx:		;ebx = x start , ecx = y start ,[esi] -> pcx , function 1 (eax == 1)
	imul ecx,320
	lea  edi,[ecx+ ebx + vid_mem] ;pointer to viodeo buffer
	mov edx,[esi + 8]
	mov ebp,[esi + 0ah]
	and edx,0xffff
	inc edx	;the values represented the langh and hieght of the picture are smaller in 1 from the actual hieght and lengh of the picture.
	inc ebp ;I guess it was intended to write pixels to the screen using technics equivalnt to c#'s 'do' opration , which executed at least one chunk of code.
	and ebp,0xffff
	mov ebx,edx
	;mov [0x7c10],ebp
	add esi,128
.showpcx.first:
	cmp byte [esi],192
	ja .showpcx.second
	movsb
	dec edx
	jne .showpcx.first
	mov edx,ebx
	add edi,320
	sub edi,edx
	dec ebp
	jne .showpcx.first
	popad
	iretd
	
.showpcx.second:
	lodsw
	and al,0x3f
	movzx ecx,al
	xchg al,ah
.@1:
	rep stosb
	;mov [edi],dh
	;inc edi
	;loop .@1
	movzx eax,ah
	sub edx,eax
	jne .showpcx.first
	mov edx,ebx
	add edi,320
	sub edi,edx
	dec ebp
	jne .showpcx.first
	popad
	iretd
	
.set_palette: ;[esi] -> pallete , function 2 (eax == 2)
		mov     dx, 3C8h
        xor     al,al
        out     dx, al
        inc     edx              ; Port 3C9h
        mov     cx, 256*3       ; Copy 256 entries, 3 bytes (RGB) apiece
.palette:
		lodsb
        shr     al, 2           ; PCX stores color values as 0-255 ,  but VGA DAC is only 0-63
        out     dx, al          
        loop     .palette
		popad
		iretd
.gui_320_200:

		mov al,1
		mov dx,3c4h
		out dx,al
		inc edx
		in al,dx
		and al,~(1<<5)
		out dx,al
;		--------------- disable_video_output macro
.gui_360_200:

		mov al,1
		mov dx,3c4h
		out dx,al
		inc edx
		in al,dx
		and al,~(1<<5)
		out dx,al
;		--------------- disable_video_output macro
interrupt0x31:
	pushad
	in al,0x60
	cmp al,0x3b	;f1 key
	jne .end
	
.end:
	EOI_1
	popad
	iretd