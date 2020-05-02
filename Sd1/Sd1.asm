assume cs:code
data segment
	db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
	db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
	db '1993','1994','1995'
	;以上表示21个年份(Byte字节) 0~53H
	dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
	dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000
	;以上表示21个年份的年收入(double word ) 54H~0a7H
	dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226
	dw 11542,14430,15257,17800
	;以上表示21个年份的雇员人数(word)	0a8H~0d1H
data ends

data2 segment
	db 16 dup(0)
data2 ends

stack segment
	db 32 dup (0)
stack ends

table segment
	db 21 dup ('year summ ne ??0')
table ends

code segment
	start:	mov ax,stack
			mov ss,ax
			mov sp,32			;初始化32byte栈空间ss:sp
			mov ax,data2
			mov ds,ax
			mov si,0		;存储显示内容的空间ds:si
			mov ax,data
			mov es,ax
			mov bx,0		;原始数据es:bx
			mov di,54H		;总收入的偏移指针
			mov bp,0a8H		;雇员的偏移指针
			mov dh,1		;行号，第2行开始
			mov cx,21		;循环次数，共21年/行
		s:	push cx			;保护循环次数的寄存器
			mov cx,4		;逐位处理年份，共四位
			y_s:
				mov al,es:[bx]
				mov [si],al
				inc si
				inc bx
				loop y_s
			mov dl,5		;列号，第6列开始
			mov cl,2		;样式，绿字
			mov si,0
			call far ptr show_str		;显示年份
			
			push dx			;保护dx的数据
			mov ax,es:[di]	;总收入的低16位
			mov dx,es:[di+2]	;总收入的高16位
			call far ptr dtoc	;转换字符串
			pop dx			;还原dx数据
			add dl,10		;列号偏移
			mov cl,2		;样式，绿字
			call far ptr show_str		;显示总收入
			
			
			push dx			;保护dx的数据
			mov ax,es:[bp]	;雇员的低16位
			mov dx,0		;雇员的高16位
			call far ptr dtoc	;转换字符串
			pop dx			;还原dx数据
			add dl,11		;列号偏移
			mov cl,2		;样式，绿字
			call far ptr show_str		;显示雇员
			
			push dx			;保护dx的数据
			mov ax,es:[di]	;总收入的低16位
			mov dx,es:[di+2]	;总收入的高16位
			mov cx,es:[bp]		;雇员数据
			call far ptr divdw	;计算人均收入
			call far ptr dtoc	;转换字符串
			pop dx			;还原dx数据
			add dl,10		;列号偏移
			mov cl,2		;样式，绿字
			call far ptr show_str		;显示人均收入
			
			add di,4		;移到下一总收入数据
			add bp,2		;移到下一个雇员数据
			inc dh			;移至下一行
			pop cx			;取出循环次数的寄存器
			loop s
			
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
			retf
			
	divdw:	
			;参数	ax:dd数据的低16位	dx:dd数据的高16位	cx:除数
			;返回	ax:结果的低16位		dx:结果的高16位		cx:余数
			;作用	dd除法,防溢出
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
			retf
			
	dtoc:	
			;参数	ax是dword数据低16位		dx是高16位		ds:si 字符串首地址
			;返回	无
			;作用	将dword数据转换成表示十进制数的字符串，以0为结尾
			push ax
			push dx
			push si
			push cx		
			push di		;保护寄存器数据
			
			mov di,0
		s1:	mov cx,10	;设置除数
			call far ptr divdw
			add cx,30h	;余数转换成字符串
			push cx		;进栈，用于逆序
			mov cx,ax
			inc cx		;当商为0时循环结束
			inc di	;记录字符串位数
			loop s1
			mov cx,di
		s2:	pop ax
			mov ds:[si],al			;出栈，逆序
			inc si
			loop s2
			mov byte ptr ds:[si],0		;末尾0
			
			pop di
			pop cx
			pop si
			pop dx
			pop ax		;还原寄存器
			retf
			
code ends
end start