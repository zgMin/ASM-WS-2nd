assume cs:code

code segment
	start:	mov al,2		;颜色
			mov ah,3		;功能号	
			int 7ch
			mov ax,4c00h
			int 21h
code ends
end start