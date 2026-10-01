ideal
locals
jumps
model huge
stack 100h
p386

TextMode = 0


segment     MyData
ScrollText  db "jl enterprises",0
            db "presents",0
            db "its second",0
            db "demo ever!",0
            dw -1
ScrollPtr   dw offset ScrollText
MyPalette   db 0,0,0,   8,8,8,   16,16,16,   24,24,24,   32,32,32
            db 40,40,40,   48,48,48,   56,56,56,   63,63,63
            db 247 dup (0,0,0)
extrn       FontData:byte           ;this should be a valid JLF font
ends        MyData

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "drawstrx.inc"
include     "modex.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax

            ;switch over to graphics mode
            @SetModeX M320x200x256,320*4
            ScrWidth = 320
            ScrHeight = 200
            PageSize = ScrWidth/4*ScrHeight

            ;load in the palette
            mov si,offset MyPalette
            mov ax,0
            mov cx,256
            @WritePalette

@@MainLoop: ;reset the starting offset
            mov bx,0
            @Set_Start_Offset

            ;clear our text buffer
            mov ah,1111b
            @Set_Write_Plane
            mov es,[VGASeg]
            mov di,0
            mov cx,(PageSize/2)*4
            xor ax,ax
            cld
            rep stosw

            ;if we've reached the end of the text, do something
            mov si,[ScrollPtr]
            cmp [word si],-1
            jnz @@GotText
            jmp @@AllDone

            ;render the text
@@GotText:  push 0
            push 80 320+0
            push (seg ScrollText) [ScrollPtr]
            push (seg FontData) (offset FontData)
            call _Draw_String
            add sp,14

            ;seek to the next line of text
            mov si,[ScrollPtr]
@@FindEnd:  lodsb
            or al,al
            jnz @@FindEnd
            mov [ScrollPtr],si

            ;slide the text by really quickly
            mov bx,0
@@Slide:    @FullVertWait
            @Set_Start_Offset
            add bx,4
            cmp bx,(320*2)/4
            jb @@Slide

            ;display the text so that it's readable
            mov bx,(320/4)
            @Set_Start_Offset

            ;pause for a bit
            mov cx,45
@@Pause:    @FullVertWait
            loop @@Pause

            ;get the text off the screen
            mov bx,0
            @Set_Start_Offset

            ;pause some more
            mov cx,30
@@Pause2:   @FullVertWait
            loop @@Pause2

            ;get stdio.  If something's been pressed, quit
            mov ah,6
            mov dl,0FFh
            int 21h
            jz @@MainLoop

@@AllDone:  ;change back to text mode and quit
            if TextMode ne 0
                mov ax,0003h
                int 10h
            endif
            mov ax,4C00h
            int 21h
endp        Start
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
            end     Start
