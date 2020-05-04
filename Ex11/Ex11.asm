assume cs:codesg
datasg segment
	db "Beginner's All-purpose Symbolic Instruction Code.",0
datasg ends

stack segment
	db 16 dup (0)
stack ends

codesg segment
	begin:	mov ax,stack
			mov ss,ax		;16字节栈空间
			mov ax,datasg
			mov ds,ax
			mov si,0
			call letterc
			
			mov ax,4c00h
			int 21h
	
	letterc:	
			;参数: ds:si指向字符串首地址
			;功能：将以0为结尾的字符串中的小写字母转换为大写字母
			push cx			;保护cx寄存器数据
			push ax			;保护ax寄存器数据
			mov ah,0
		s0:		
			mov al,ds:[si]
			mov cx,ax
			cmp al,97		
			jnb s			;ascii值不小于97，即>=‘a’
			jmp next
		s:	cmp al,122
			jna turn		;ascii值不大于97，即<=‘z’
			jmp next
		turn:	
			and al,11011111b	;转化字母
			mov ds:[si],al		;将数据写回空间
		next:
			inc cx
			inc si			;偏移指针指向下一个字符
			loop s0
		pop ax				;还原ax寄存器
		pop cx				;还原cx寄存器
		ret					;子程序返回
codesg ends
end begin