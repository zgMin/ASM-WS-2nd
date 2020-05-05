assume cs:codesg

stack segment
	db 16 dup (0)
stack ends

codesg segment
	start:	mov ax,stack
			mov ss,ax
			mov sp,16			;16字节栈空间
			mov ax,cs
			mov ds,ax			
			mov si,offset do0	;ds:si源地址
			mov ax,0
			mov es,ax			
			mov di,200h			;es:di目标地址
			mov cx,offset do0end - offset do0	;cx传输长度
			
			mov es:[0*4],di
			mov es:[0*4+2],es	;设置0号中断向量
			
			cld					;设置标志df=0，方向为正
			rep movsb			;传输
			
			mov ax,1000h
			mov bh,1
			div bh				;会产生溢出的除法
			
			mov ax,4c00h
			int 21h
			
	do0:	jmp short do0start
			db 'divide error!'	
		do0start:
			mov ax,cs
			mov ds,ax
			mov si,202h		;ds:si指向字符串
			
			mov ax,0b800h
			mov es,ax
			mov di,12*160+36*2	;es:di指向显存空间的中间位置
			mov cx,13			;cx为字符串长度
		s:	mov al,[si]
			mov es:[di],al
			inc si
			add di,2
			loop s				;往显存空间里传送字符串
			
			mov ax,4c00h
			int 21h
	do0end:	nop
codesg ends
end start