;-------------------------------------------------------
;creator: Elad Ashkcenazi 
;year : 2017
;goal : to create a 32 bit semi-kernel bootable game
;requirements:
;Pentium + cpu
;4 GB of ram	; altouogh as of now the highest address of ram im using is 0x00820200 for the stack
;vesa suported motherboard
;-------------------------------------------------------

;sys_registers_content32:

%xdefine  OGcr0		  1
%xdefine  OGcr4 	  (3 << 8) 
%xdefine  sys_eflags  1 << 8
;some instructions renamed for ease of use:D

%xdefine  pind   		 pinsrd
%xdefine  movx  		 movdqu
%xdefine  movy   		 vmovdqu
%xdefine  move   		 mov
%ideftok  halt			 'db 0xf4,0xeb,0xfd'	;0xf4 is the insruction hlt and 0xeb,0xfd means jmp short -3 to return to hlt forever. 
%ideftok  ud3			 'dw 0xc88e'			;encoded as mov cs,ax(check on turbo debbuger if u dont belive me) but on non 8086 is an illigal instruction, causing a ud# exeption when executed!
%macro 	  zerob			1						;for easier filling sectors and tables with zeroes.
times 	%1 db 0
%endmacro 
%macro 	  zerow			1
times 	%1 dw 0
%endmacro 
%macro 	  zerod			1
times 	%1 dd 0
%endmacro 
%macro 	  zeroq			1
times 	%1 dq 0
%endmacro 
%macro 	  zerox			1
times 	%1 dx 0
%endmacro 
%macro 	  zeroy			1
times 	%1 dy 0
%endmacro 
%macro 	  EOI	0			;end of interrupt irq's , signals the cpu that everhing is back to normal and activates irq's back again, , from what I understand , I need to put that a little before iretd in my irq's interrupt rountime.
	mov	al, 0x20	; set bit 4 and set level 1 of OCW 2
	out	0x20, al	; write to primary PIC command register
%endmacro 
%macro 	  EOI_1	0			;end of interrupt irq's , signals the cpu that everhing is back to normal and activates irq's back again, , from what I understand , I need to put that a little before iretd in my irq's interrupt rountime.
	mov	al, 0x20	; set bit 4 and set level 1 of OCW 2
	out	0x20, al	; write to primary PIC command register
%endmacro 
%macro 	  EOI_2	0			;end of interrupt irq's , signals the cpu that everhing is back to normal and activates irq's back again, , from what I understand , I need to put that a little before iretd in my irq's interrupt rountime.
	mov	al, 0x20	; set bit 4 and set level 1 of OCW 2
	out	0xa0, al	; write to primary PIC command register
%endmacro 
%macro 	  df 	1-*		;define 24-bit values
%rep %0
dw %1 & 0xffff
db (%1 & 0xff0000) >> 16
%rotate 1
%endrep
%endmacro
%macro   disable_video_output 0
	mov al,1
	mov dx,3c4h
	out dx,al
	inc edx
	in al,dx
	and al,~(1<<5)
	out dx,al			
%endmacro

%macro   enable_video_output 0
	mov al,1
	mov dx,3c4h
	out dx,al
	inc edx
	in al,dx
	or al,(1<<5)
	out dx,al			
%endmacro
%macro enter_ring0 0
	xor eax,eax
	dw 0x2e2e
	div eax
%endmacro
;prefixes for some instructions:

%ideftok  use_cs 		 'db 0x2e'	;use_cs + stosb = stosb [{cs:}di],al
%ideftok  use_ds	     'db 0x3e'  ;
%ideftok  use_ss	     'db 0x36'  ;
%ideftok  use_es 		 'db 0x26'  ;
%ideftok  use_fs 		 'db 0x64'  ;
%ideftok  use_gs 		 'db 0x65'  ;
%ideftok  flip_mode		 'db 0x66'  ;if opcode's operand defualt = 32 then operand size = 16 and vice versa.(for example: (flip_mode + inc bp) = inc ebp ) 
%ideftok  use_rep 		 'db 0xf3'  ;
%ideftok  use_lock 		 'db 0xf0'  ;activates ud# when used in non memory and/or non specific instructions. , but doesn't really do something intresting (meaning that it can be added for some instructions as a nop).
;interrupts:

%xdefine  int_functions_loc	 (org_2 + int_functions - bits32)
%xdefine  int0x0_offset	 (int_functions_loc + (interrupt0x0 -int_functions))
%xdefine  int0x1_offset	 (int_functions_loc + (interrupt0x1 -int_functions))
%xdefine  int0x2_offset	 (int_functions_loc + (interrupt0x2 -int_functions))
%xdefine  int0x3_offset	 (int_functions_loc + (interrupt0x1 -int_functions))
%xdefine  int0x6_offset	 (int_functions_loc + (interrupt0x6 -int_functions))
%xdefine  int0x8_offset	 (int_functions_loc + (interrupt0x8 -int_functions))
%xdefine  int0x10_offset   (int_functions_loc + (interrupt0x10 -int_functions))
%xdefine  int0x13_offset   (int_functions_loc + (interrupt0x13 -int_functions))
%xdefine  int0x21_offset   (int_functions_loc + (interrupt0x21 -int_functions))
%xdefine  int0x30_offset   (int_functions_loc + (interrupt0x30 -int_functions))
%xdefine  int0x31_offset   (int_functions_loc + (interrupt0x31 -int_functions))
%xdefine  int0x32_offset   (int_functions_loc + (interrupt0x32 -int_functions))
%xdefine  int0x33_offset   (int_functions_loc + (interrupt0x33 -int_functions))
%xdefine  int0x24_offset   (int_functions_loc + (interrupt0x24 -int_functions))
%xdefine  int0x35_offset   (int_functions_loc + (interrupt0x35 -int_functions))
%xdefine  int0x26_offset   (int_functions_loc + (interrupt0x26 -int_functions))
%xdefine  int0x37_offset   (int_functions_loc + (interrupt0x37 -int_functions))
%xdefine  int0x38_offset   (int_functions_loc + (interrupt0x38 -int_functions))
%xdefine  int0x39_offset   (int_functions_loc + (interrupt0x39 -int_functions))
%xdefine  int0x3a_offset   (int_functions_loc + (interrupt0x3a -int_functions))
%xdefine  int0x3b_offset   (int_functions_loc + (interrupt0x3b -int_functions))
%xdefine  int0x3c_offset   (int_functions_loc + (interrupt0x3c -int_functions))
%xdefine  int0x3d_offset   (int_functions_loc + (interrupt0x3d -int_functions))
%xdefine  int0x3e_offset   (int_functions_loc + (interrupt0x3e -int_functions))
%xdefine  int0x3f_offset   (int_functions_loc + (interrupt0x3f -int_functions))

;integers:

%xdefine  pixels#  320*200
;useful msr register

%xdefine  tsc_reg 				0x10
%xdefine  maximum_clock_reg 	0xe7	;from what I understand : this register literally control the maximum speed of the cpu; theoreticly I can put a very high value in this reg and burn a computer(thats only theoritical because every motherboard has a max value for this register:(
%xdefine  mperf_reg 			0xe7			;same as above
;important locations in ram
%xdefine  org_2      		0x00007e00
%xdefine  text_mem16      	0x0000b800
%xdefine  text_mem			0x000b8000
%xdefine  vid_mem16 		0x0000a000
%xdefine  vid_mem 			0x000a0000
%xdefine  stack_start 		0x80000000	;my stack should be 16mb long , that's enough for even 524288 pushd's:)
%xdefine  stack_end		    0x7f000000
%xdefine  idt_loc           (org_2 + idt - bits32)
;keyboard keys:

%xdefine esc			0x01
%xdefine scrllock 		0x46
%xdefine up 			0x48			;arrow keys are actually exetended keys with 0xe0 at their start! that can bring  alot of bugs into my code!
%xdefine down			0x50
%xdefine left			0x4b
%xdefine right 			0x4d

;i/o ports:

%xdefine	keyboard		0x60
%xdefine	pic1_commands   0x20		;WRITE
%xdefine	pic1_status		0x20		;READ
%xdefine	pic1_primary 	0x21		;READ
%xdefine	pic1_imr		0x21		;WRITE
%xdefine	pic2_commands   0xa0		;WRITE
%xdefine	pic2_status		0xa0		;READ
%xdefine	pic2_primary 	0xa1		;READ
%xdefine	pic2_imr		0xa1		;WRITE
%xdefine	vga_misc_read   0x3cc
%xdefine	vga_misc_write   0x3c2
;structures:

%macro int_gate 1
	DW (%1 & 0ffffh)
	dw 0x10
	db 0
	db 10001110b
	dw ((%1 & 0xffff0000) >> 16)
%endmacro 
%macro int3_gate 1
	DW (%1 & 0ffffh)
	dw 0x10
	db 0
	db 11101110b
	dw ((%1 & 0xffff0000) >> 16)
%endmacro 
%macro trap_gate 1
	DW (%1 & 0ffffh)
	dw 0x10
	db 0
	db 10001111b
	dw ((%1 & 0xffff0000) >> 16)
%endmacro 
%macro trap3_gate 1
	DW (%1 & 0ffffh)
	dw 0x10
	db 0
	db 11101111b
	dw ((%1 & 0xffff0000) >> 16)
%endmacro 

;DISK prperties:

