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
			;参数：dh行号	dl列号	cl颜色	ds:si字符串首地址
			;功能：显示以0为结尾的字符串
		show_str:
			;参数	dh行号，dl列号，cl颜色，ds：si字符串首地址
			;返回	无
			;功能	在屏幕dh行dl列，显示cl色的ds：si处字符串
			push ax
			push bx
			push cx
			push dx
			push di
			push si
			push es	;保护寄存器数据
			mov ax,0b800h
			mov es,ax	;es显示的段地址	
			mov di,0		;di显示的偏移指针
			mov al,0a0h	
			mul dh
			mov dh,0	
			add ax,dx
			add ax,dx
			mov bx,ax		;bx行列偏移量
			mov al,cl 		;al颜色量
			mov ch,0
		s0:	
			mov cl,ds:[si]	
			jcxz ok			;判断是否结束
			mov es:[bx+di],cl	;显示内容
			mov es:[bx+di+1],al	;控制颜色
			add di,2
			inc si
			loop s0
		ok:	pop es
			pop si
			pop di
			pop dx
			pop cx
			pop bx
			pop ax	;还原寄存器
			iret
	do7cend:	nop
codesg ends
end install