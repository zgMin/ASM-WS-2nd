assume cs:code
data segment
	db 10 dup (0)
data ends

code segment
	start:	
			mov ax,12666
			mov bx,data
			mov ds,bx
			mov si,0
			call dtoc
			mov dh,8
			mov dl,3
			mov cl,2
			call show_str
			
			mov ax,4c00h
			int 21h	
	show_str:
			;参数	dh行号，dl列号，cl颜色，ds：si字符串首地址
			;返回	无
			;作用	在屏幕dh行dl列，显示cl色的ds：si处字符串
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
			ret
			
	divdw:	
			;参数	ax:dd数据的低16位	dx:dd数据的高16位	cx:除数
			;返回	ax:结果的低16位		dx:结果的高16位		cx:余数
			;作用	dd除法,放溢出
			;算法	X/N=int(H/N)*65536+[rem(H/N)*65536+L]/N
			push bx
			push ax
			mov ax,dx
			mov dx,0;
			div cx
			mov bx,ax	;H/N结果的高16位
			pop ax
			div cx
			mov cx,dx	;余数
			mov dx,bx	;结果的高16位
			pop bx
			ret
			
	dtoc:	
			;参数	ax是word数据	ds:si 字符串首地址
			;返回	无
			;作用	将word数据转换成表示十进制数的字符串，0为结尾
			push ax
			push bx
			push dx
			push si
			push cx		;保护寄存器数据
			mov bx,10
		s1:	mov dx,0
			div bx
			add dx,30h
			push dx		;进栈，用于逆序
			mov cx,ax
			inc cx
			inc si	;记录字符串位数(包括0)
			loop s1
			mov cx,si
			mov si,0
		s2:	pop ds:[si]		;出栈，逆序
			inc si
			loop s2
			
			pop cx
			pop si
			pop dx
			pop bx
			pop ax		;还原寄存器
			ret
			
code ends
end start