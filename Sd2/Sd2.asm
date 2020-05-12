assume cs:setupsg
setupsg segment
	start:
		;安装主引导程序到第一扇区
		mov ax,initsg
		mov es,ax
		mov bx,0		;es:bx指向主引导程序
		;调用int 13h中断例程
		mov al,1		;扇区数
		mov ch,0		;磁道号
		mov cl,1		;扇区号
		mov dh,0		;磁头号|面号
		mov dl,0		;驱动器号
		mov ah,3		;程序号，写操作
		int 13h
		
		;子程序安装到从第2扇区开始的扇区
		mov ax,syssg
		mov es,ax		;es:bx指向子程序
		mov al,15		;扇区数
		mov cl,2		;扇区号
		mov ah,3		;程序号，写操作
		int 13h
 
		mov ax,4c00h
		int 21h
setupsg ends

initsg segment
	assume cs:initsg
	init_start:
		call clear		;清屏
		call loadsys	;加载子程序
		
		mov ax,2000h
		push ax
		mov ax,0
		push ax
		retf			;跳到2000：0,执行主引导程序
	
	loadsys:
		mov ax,2000h
		mov es,ax
		mov bx,0		;es:bx指向读入的存储位置，2000：0
		;调用int 13h读取系统
		mov al,15		;扇区数
		mov ch,0		;磁道号
		mov cl,2		;扇区号
		mov dh,0		;磁头号|面号
		mov dl,0		;驱动器号
		mov ah,2		;程序号，读操作
		int 13h					
		ret
		
	clear:
		mov ax,0b800h					
		mov ds,ax						;ds显存段地址
		mov bx,0						;bx偏移地址
		mov cx,25*80*2					;cx字符总数
		clear_s:
			mov byte ptr ds:[bx],0			;清除内容
			mov byte ptr ds:[bx+1],07h		;清除格式（前景色为黑）
			add bx,2
			loop clear_s
		ret
	
	init_end:	nop
	db 509-(offset init_end-offset init_start) dup (0)		;用0填充剩下的地方
	db 55h, 0aah				;aa55h作为结束标志
initsg ends

syssg segment
	assume cs:syssg
	menu:						;这里存放菜单
		jmp near ptr menushow			;显示菜单
		menu_num dw offset m0,offset m1,offset m2,offset m3,offset m4,offset m5,offset m6
		m0 db "------ MENU ------",0
		m1 db "1) reset pc",0
		m2 db "2) start system",0							
		m3 db "3) clock",0
		m4 db "4) set clock",0
		m5 db "5) shutdown",0
		m6 db "copyright @ 2020 Zgm,Inc.All rights reserved.",0
	time_str db '??/??/?? ??:??:??',0		;预设格式，以0为结尾
	time_num db 9,8,7,4,2,0	;端口号   年月日时分秒
	pos db 0,1,3,4,6,7,9,10,12,13,15,16		;时间位置，共12个
	systable dw sys_reset,sys_start,sys_clock,sys_setclock,sys_shutdown	;功能表
	
	menushow:
		;菜单显示
		mov dh,5		;行
		mov dl,30		;列
		mov bp,0		;菜单偏移指针
		mov ax,cs
		mov ds,ax		;ds指向menu_num的段地址
		mov cx,6		;菜单条数
		menushow_s:
			push cx
			mov si,menu_num[bp]		;ds:si指向字符串首地址
			mov cl,2				;cl样式，绿字
			call sys_showstr		;字符串显示，以0为结尾
			add bp,2				;指向下一个menu_num
			add dh,2				;下移两行
			pop cx
			loop menushow_s			;显示菜单
		mov si,offset m6
		mov dh,23					;行
		mov dl,18					;列
		mov cl,2					;绿字
		call sys_showstr			;显示字符串
		
	sys_input:
		;处理用户键盘输入
		mov ah,0	;程序号
		int 16h		;等待用户键入,ah	扫描码，al	ASCII码
		mov bx,0
		mov bl,al	;ASCII码转给bx
		mov al,30h
		sub bl,al	;ASCII码转换为序列号1-5
		sub bl,1	;1-5映射为0-4
		
		cmp bx,0
		jb input_cycle	;小于0
		cmp bx,4
		ja input_cycle	;大于4
		add bx,bx
		call word ptr systable[bx]	;调用对应功能	
	input_cycle:
		jmp short sys_input
		
	sys_reset:
		;重启计算机
		mov ax,0ffffh
		push ax
		mov ax,0h
		push ax
		retf			;cs:ip返回到ffff:0处即为重启
		
	sys_start:
		;引导现有系统启动
		call cls		;清屏
		
		mov ax,0
		mov es,ax
		mov bx,7c00h	;es:bx指向0:7c00h，把硬盘里的系统读到此处
		
		;调用13h中断例程，读取系统到内存
		mov al,1		;扇区数
		mov ch,0		;磁道号
		mov cl,1		;扇区号
		mov dh,0		;磁头号|面号
		mov dl,80h		;驱动器号,80h是c盘
		mov ah,2		;程序号，读操作
		int 13h	
		
		mov ax,0
		push ax
		mov ax,7c00h
		push ax
		retf			;返回到0:7c00h处，执行现有系统
		
	sys_clock:
		call cls			;清屏
		show_s:
			call clockshow		;显示时钟
			in al,60h			;读入键盘扫描码
			cmp al,01h			;按下ESC
			in al,60h			;吞掉松开是产生的扫描码，防止键盘缓存区满掉
			je remenu
			jmp show_s					;循环显示时钟
		
	remenu:						;返回菜单
		call cls			;清屏
		pop ax				;pop掉调用时的ip指针
		call menushow		;返回菜单界面	
		
	sys_setclock:
		;设置时钟
		call cls		;清屏
		mov bp,0
		mov ax,cs
		mov es,ax
		call clockshow
		set_s:
			mov si,offset time_str
			mov dh,13					;行
			mov dl,21					;列
			mov cl,2					;绿字
			call sys_showstr			;显示字符串
				
			mov bh,0		;bh页号
			mov dh,13		;dh行号
			mov dl,21		;dl列号
			add dl,pos[bp]
			mov ah,2		;ah子程序号
			int 10h			;放置光标
				
			mov ah,0
			int 16h				;等待用户键入
			mov bx,ax			;bh扫描码,bl为ASCII
			cmp bh,01h			;按下ESC
			je remenu			;返回菜单
			cmp bh,1ch			;按下回车
			je set_save		;保存设置并返回菜单
				
			cmp bh,4bh			;左方向⬅
			jne ne1
			cmp bp,0
			je ne2				;防止超出左边界
			dec bp				;光标左移
		ne1:
			cmp bh,4dh			;右方向→
			jne ne2
			cmp bp,11
			je ne2				;防止超出右边界
			inc bp				;光标右移
		ne2:		
			;以下排除非数字键
			cmp bh,02h			;1
			jb set_s
			cmp bh,0bh			;0
			ja set_s			
			;jmp clock_change	;更改显示	
			clock_change:
				mov al,pos[bp]
				mov ah,0
				mov si,ax
				mov time_str[si],bl	;写入预设格式字符串中
				jmp set_s
		set_save:
			mov si,0
			mov di,0			;偏移指针
			mov cx,6			;处理 年月日时分秒 6个信息
			save_s:	
				push cx				;保护cx数据
				mov al,time_num[di]		;取出端口号
				out 70h,al
				mov ah,time_str[si]
				mov al,time_str[si+1]	;读出设置中的数据
				sub ah,30h
				sub al,30h				;转化为BCD码
				mov cl,4
				shl ah,cl
				or al,ah				;还原数据
				out 71h,al				;将数据写入CMOS
				add si,3			;指向下一个格式位置
				inc di				;指向下一个端口号
				pop cx				;还原cx数据
				loop save_s
			jmp remenu
				
		
	clockshow:;显示时钟
			mov ax,cs
			mov ds,ax
			mov si,0
			mov di,0			;偏移指针
			mov cx,6			;处理 年月日时分秒 6个信息
		clock_s:	
			push cx				;保护cx数据
			mov al,time_num[di]		;取出端口号
			out 70h,al
			in al,71h			;读入数据
			mov ah,al
			mov cl,4
			shr ah,cl			;ah为十位数码值
			and al,00001111b	;al为个位数码值
			add ah,30h
			add al,30h			;转化为字符
			mov time_str[si],ah
			mov time_str[si+1],al	;写入预设格式字符串中
			add si,3			;指向下一个格式位置
			inc di				;指向下一个端口号
			pop cx				;还原cx数据
			loop clock_s
		mov si,offset time_str
		mov dh,13					;行
		mov dl,21					;列
		mov cl,2					;绿字
		call sys_showstr			;显示字符串	
		ret
		
	sys_shutdown:
		;关机
		mov ax,5301H
		xor bx,bx		;bx和flag同时置零
		xor cx,cx
		int 15H
		mov ax,530EH
		xor bx,bx
		mov cx,102H
		int 15H
		mov ax,5307H
		mov bx,1
		mov cx,3
		int 15H
		
	cls:
		;清屏
		mov ax,0b800h					
		mov ds,ax						;ds显存段地址
		mov bx,0						;bx偏移地址
		mov cx,25*80*2					;cx字符总数
		cls_s:
			mov byte ptr ds:[bx],0			;清除内容
			mov byte ptr ds:[bx+1],07h		;清除格式（前景色为黑）
			add bx,2
			loop cls_s
		ret
	
	sys_showstr:
		;显示以0为结尾的字符串
		;参数： dh行号	dl列号	cl颜色	ds:si指向字符串首地址
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
	
syssg ends

end start