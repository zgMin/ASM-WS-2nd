assume cs:code
stack segment
	db 16 dup (0)
stack ends

code segment
		install:
			cli					;IF=0禁止可屏蔽中断，防止中断指向错误地址
			mov ax,stack
			mov ss,ax
			mov sp,16			;初始化16字节栈空间
			mov ax,cs
			mov ds,ax
			mov si,offset int9	;ds:si指向int9
			
			mov ax,0
			mov es,ax
			mov di,204h			;es:di指向int9的安装地址
			
			mov cx,offset int9_end-offset int9	;cx为int9程序长度
			cld					;df=0,正向
			rep movsb			;传输int9程序
			
			mov ax,es:[9*4]
			mov es:[200h],ax
			mov ax,es:[9*4+2]
			mov es:[202h],ax	;保存原int9例程的入口地址
			
			mov word ptr es:[9*4],204h
			mov word ptr es:[9*4+2],0	;设置int9的中断向量表
			sti					;IF=1允许可屏蔽中断
			
			mov ax,4c00h
			int 21h
			
		int9:	
			push ax
			push cx
			push ds
			push si				;保护寄存器数据
			
			in al,60h			;读入键盘扫描码
			;以下为模拟调用原int9中断例程
			pushf				;标志寄存器入栈
			call dword ptr cs:[200h]	;调用原int9
			
			cmp al,1eh+80h		;1eh为A的通码，+80h为其断码
			jne	ok				;非松开A
			;以下是松开A后的操作
			mov ax,0b800h
			mov ds,ax
			mov si,0			;ds:si指向显存空间的第一个位置
			mov cx,80*25		;一页共有80行，25列，合计2000字符
		out_c:					;循环输出字符‘A’
			mov byte ptr [si],'A'
			add si,2			;下一个输出位置
			loop out_c
		ok:	pop si
			pop ds
			pop cx
			pop ax				;还原寄存器数据
			iret				;返回
		int9_end:	nop
code ends
end install