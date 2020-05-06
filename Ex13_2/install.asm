assume cs:codesg

stack segment
	db 16 dup (0)
stack ends

codesg segment
	install:	
			mov ax,stack
			mov ss,ax
			mov sp,16			;16字节栈空间
			;以下为中断例程的安装
			mov ax,cs
			mov ds,ax			
			mov si,offset do7c	;ds:si源地址
			mov ax,0
			mov es,ax			
			mov di,200h			;es:di目标地址
			mov cx,offset do7cend - offset do7c	;cx传输长度
			
			mov es:[7ch*4],di
			mov es:[7ch*4+2],es	;设置7c号中断向量
			
			cld					;设置标志df=0，方向为正
			rep movsb			;传输

			
			mov ax,4c00h
			int 21h
			
	do7c:	
			;参数：cx循环次数	bx位移
			;功能：loop指令
		lp:	push bp
			mov bp,sp
			dec cx			;cx-1
			jcxz lpret		;cx=0跳转结束
			add [bp+2],bx	;修改偏移地址，进行跳转
		lpret:
			pop bp
			iret
	do7cend:	nop
codesg ends
end install