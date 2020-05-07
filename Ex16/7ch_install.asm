assume cs:code
stack segment
	db 16 dup (0)
stack ends

code segment
		install:
			mov ax,stack
			mov ss,ax
			mov sp,16			;初始化16字节栈空间
			mov ax,cs
			mov ds,ax
			mov si,offset int7ch	;ds:si指向int7ch
			
			mov ax,0
			mov es,ax
			mov di,204h			;es:di指向int7ch的安装地址
			
			mov cx,offset int7ch_end-offset int7ch	;cx为int7ch程序长度
			cld					;df=0,正向
			rep movsb			;传输int7ch程序
			
			mov ax,es:[7ch*4]
			mov es:[200h],ax
			mov ax,es:[7ch*4+2]
			mov es:[202h],ax	;保存原int7ch例程的入口地址
			
			cli
			mov word ptr es:[7ch*4],204h
			mov word ptr es:[7ch*4+2],0	;设置int7ch的中断向量表
			sti
			
			mov ax,4c00h
			int 21h
			
		int7ch:	
			;参数:ah功能号	0清屏	1设置前景色	2设置背景色	3向上滚动一行
			;	  对于2、3，al代表颜色值（0，1，2，3，4，5，6，7）
			;功能：设置屏幕属性（1）清屏（2）设置前景色（3）设置背景色（4）向上滚动一行
			jmp short start
		table dw cls - int7ch + 204h,frontcolor - int7ch + 204h,backcolor - int7ch + 204h,uproll - int7ch + 204h
		start:
			push bx					
			push si					;保护寄存器数据
			cmp ah,3
			ja int7ch_ok			;防止程序号超过3
			mov bl,ah
			mov bh,0
			add bx,bx				;bx为在table中的偏移
			mov si, offset install - offset int7ch	+ 204h	;si为table的偏移
			call word ptr table[bx+si]	;调用[bx+si]
		int7ch_ok:
			pop si
			pop bx					;还原寄存器数据
			iret					;返回
			
		cls:
			push cx
			push ds
			push si				;保护寄存器
			mov cx,0b800h
			mov ds,cx
			mov si,0			;ds:si指向显存空间的第一个位置
			mov cx,80*25		;一页共有80行，25列，合计2000字符
			;循环输出字符‘ ’
			out_c:
				mov byte ptr [si],' '
				add si,2			;下一个输出位置
				loop out_c
			pop si
			pop ds
			pop cx				;还原寄存器
			ret
			
		frontcolor:
			push cx
			push ds
			push si
			mov cx,0b800h
			mov ds,cx
			mov si,1			;ds:si指向显存空间
			mov cx,2000
			;更改前景色
			fcs:
				and byte ptr [si],11111000b
				or [si],al
				add si,2		;指向下一个位置
				loop fcs
			pop si
			pop ds
			pop cx				;还原寄存器
			ret
			
		backcolor:
			push cx
			push ds
			push si
			mov cl,4
			shl al,cl			;al左移四位
			mov cx,0b800h
			mov ds,cx
			mov si,1			;ds:si指向显存空间
			mov cx,2000
			;更改背景色
			bcs:
				and byte ptr [si],10001111b
				or [si],al
				add si,2		;指向下一个位置
				loop bcs
			pop si
			pop ds
			pop cx				;还原寄存器
			ret
			
		uproll:
			push es
			push ds
			push di
			push si
			push cx				;保护寄存器
			
			mov cx,0b800h
			mov es,cx
			mov ds,cx
			mov si,160			;ds:si指向第n+1行,源地址
			mov di,0			;es:di指向第n行，目标地址
			cld					;df=0，方向为正
			mov cx,24			;处理一页，共24行
			;向上复制
			copy:
				push cx
				mov cx,160		;一行总长160字节
				rep movsb		;按字节复制
				pop cx
				loop copy
			;清空最后一行
			mov cx,80			;只清空内容
			mov si,0
			s1:	mov byte ptr es:[160*24+si],' '
				add si,2		;指向下一个位置
				loop s1
				
			pop cx
			pop si
			pop di
			pop ds
			pop es				;还原寄存器
			ret
				
		
		int7ch_end:	nop
code ends
end install