assume cs:code
data segment
	db '??/??/?? ??:??:??','$'		;预设格式，以$为结尾
data ends

num segment
	db 9,8,7,4,2,0	;端口号   年月日时分秒
num ends

code segment
		start:
			mov ax,data
			mov ds,ax
			mov si,0			;ds:si 指向预设格式字符串的首地址
			mov ax,num
			mov es,ax
			mov di,0			;es:di 指向时间端口号列表首地址
			mov cx,6			;处理 年月日时分秒 6个信息
		s:	push cx				;保护cx数据
			mov al,es:[di]		;取出端口号
			out 70h,al
			in al,71h			;读入数据
			mov ah,al
			mov cl,4
			shr ah,cl			;ah为十位数码值
			and al,00001111b	;al为个位数码值
			add ah,30h
			add al,30h			;转化为字符
			mov ds:[si],ah
			mov ds:[si+1],al	;写入预设格式字符串中
			add si,3			;指向下一个格式位置
			inc di				;指向下一个端口号
			pop cx				;还原cx数据
			loop s
			
		ok:	mov bh,0		;bh页号
			mov dh,[si]		;dh行号
			mov dl,0		;dl列号
			mov ah,2		;ah子程序号
			int 10h			;放置光标
			
			mov dx,0		;字符串首地址的偏移指针
			mov ah,9		;ah子程序号
			int 21h			;显示			
			
			mov ax,4c00h
			int 21h
code ends
end start