assume cs:code
;dosbox虚拟环境调用int 13h是读写不了数据的，但也别在自己电脑上乱搞啊
stack segment
	db 32 dup (0)
stack ends

code segment
		install:
			mov ax,stack
			mov ss,ax
			mov sp,32			;初始化16字节栈空间
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
			;参数:ah功能号	0读		1写		dx操作的逻辑扇区号		es:bx读出或写入的内存区
			;功能：（0）从dx号扇区读入数据到es:bx	（1）将es:bx数据写入到dx号扇区
			jmp short start
		start:
			push cx
			push si
			cmp ah,1
			ja ok		;ah大于1
			push bx
			jmp turn
		ok:
			pop si
			pop cx
			iret
			
		turn:	;转换为物理编号
			push ax
			mov ax,dx
			mov dx,0		;设置被除数
			mov cx,1440
			div cx
			mov bx,dx
			mov dh,al		;dh 面号
			mov cl,18
			mov ax,bx
			div cl
			mov ch,al		;ch磁道号
			add ah,1
			mov cl,ah		;cl扇区号
			mov dl,0		;dl驱动器号
			pop ax
			mov al,1		;扇区数
			add ah,2		;+2对应调用int 13h的功能号
			pop bx
			int 13h
			jmp ok

		int7ch_end:	nop
code ends
end install