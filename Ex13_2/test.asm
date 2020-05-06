assume cs:code

code segment
;在屏幕中间显示80个’！’
	start:	mov ax,0b800h
			mov es,ax
			mov di,160*12
			mov bx,offset s - offset se		;设置标号se到s的转移位移
			mov cx,80
		s:	mov byte ptr es:[di],'!'
			add di,2
			int 7ch
		se:	nop
			mov ax,4c00h
			int 21h
code ends
end start