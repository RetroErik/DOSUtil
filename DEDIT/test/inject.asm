; Test helper: place a short DEDIT workflow in the BIOS keyboard buffer.
bits 16
org 100h
push ds
mov ax,40h
mov es,ax
mov bx,[es:1Ch]
mov si,keys
mov cx,key_count
.next:
lodsw
mov [es:bx],ax
add bx,2
cmp bx,3Eh
jb .nowrap
mov bx,1Eh
.nowrap:
loop .next
mov [es:1Ch],bx
pop ds
mov ax,4C00h
int 21h

keys:
dw 5000h       ; Down: select ALPHA.TXT after GAMES
dw 3C00h       ; F2: edit
dw 1C0Dh       ; Enter: accept existing description
dw 3E00h       ; F4: copy
dw 5000h       ; Down: select BETA.COM
dw 3F00h       ; F5: paste
dw 4400h       ; F10: save
dw 011Bh       ; Esc: quit
key_count equ ($-keys)/2
