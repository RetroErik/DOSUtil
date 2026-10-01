ideal
locals
jumps
model huge
stack 100h
p386

TextMode = 0
ScrollRate = 4
Heart1XAngleInc = 14
Heart1YAngleInc = 12
Heart2XAngleInc = 13
Heart2YAngleInc = 15
TinyHeartHeight = 64
TinyHeartWidth = 64

segment     MyData
ScrollText  db "            well all good things must come to an end...  "
            db "greets go out to joakim rosqvist (dr.hex), andrew welch, "
            ;db "gavin, "
            db "gavin scarman, "        ;(happy Gavin?)
            db "kim davies, patch, jason williams, phil carlisle, "
            db "james torrance, michael j. black, and everyone else who "
            db "enjoyed my last demo!  i'd also like to say hi to everyone "
            db "else in the pc demo scene.  bye for now!",0
ScrollCol   dw 0
Heart1_x    dw 135
Heart1_y    dw 50
Heart2_x    dw 618
Heart2_y    dw 835
VisualPage  dw ?                    ;offset of visual page
HiddenPage  dw ?                    ;offset of hidden page
CurrentPal  db 256 dup(0,0,0)       ;a black palette
include     "hartpath.inc"          ;heights of different levels in bitmap
include     "sincos.inc"            ;our sine/cosine table
extrn       PaletteData:byte        ;this should be a RGB triplet palette
extrn       FontData:byte           ;this should be a valid JLF font
extrn       TinyHeartData:byte      ;this should have the above dimensions
ends        MyData

segment     BitmapSeg
extrn       BigHeartData:byte       ;this should be a 320x200x256 bitmap
ends        BitmapSeg

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
FadeHandler = RefreshScreen
include     "palette.inc"
include     "modex.inc"
include     "drawstrx.inc"
include     "bitmap.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax

            ;switch over to graphics mode
            @SetModeX M320x200x256,320
            ScreenWidth = 320
            ScreenHeight = 200
            PageSize = (ScreenWidth*ScreenHeight)/4
            mov [VisualPage],0
            mov [HiddenPage],PageSize

            ;load in the palette
            mov si,offset CurrentPal
            mov di,offset PaletteData
            call fade_to

@@MainLoop: call RefreshScreen
            jc @@AllDone

            ;get stdio.  If something's been pressed, quit
            mov ah,6
            mov dl,0FFh
            int 21h
            jz @@MainLoop

@@AllDone:  call fade_out

            ;change back to text mode and quit
            if TextMode ne 0
                mov ax,0003h
                int 10h
            endif
            mov ax,4C00h
            int 21h
endp        Start
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        RefreshScreen
            ;wait for a retrace to complete (for timing)
            @WaitVertEnd

            ;reset the starting offset
            mov bx,[VisualPage]
            @Set_Start_Offset

            ;wait for a retrace to start (for timing)
            @WaitVert

            ;display the heart background (wipes out entire screen)
            mov ax,BitmapSeg
            mov fs,ax
            mov si,offset BigHeartData
            mov bx,[HiddenPage]
            call DisplayBitmap

            ;display the text
            push [HiddenPage]
            push [ScrollCol]
            push (seg ScrollText) (offset ScrollText)
            push (seg FontData) (offset FontData)
            call Draw_String
            add sp,12
            add [ScrollCol],ScrollRate
            push ax

            ;draw on the hearts
            call DrawHearts
            
            ;flip to the next page
            mov ax,[VisualPage]
            xchg [HiddenPage],ax
            mov [VisualPage],ax

            pop ax
            or ax,ax
            jnz @@EndText

            clc
            ret

@@EndText:  stc
            ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        DrawHearts
            ;calculate the position and draw it
            push (seg TinyHeartData) (offset TinyHeartData)
            push TinyHeartHeight TinyHeartWidth
            push [HiddenPage]
            mov si,[Heart1_y]                               ;\
            shl si,1                                        ; \
            movsx eax,[Sine+si]                             ;  \
            sal eax,8                                       ;   > AX = row
            imul eax,eax,(ScreenHeight-TinyHeartHeight)/2   ;  /
            shr eax,16                                      ; /
            add ax,(ScreenHeight-TinyHeartHeight)/2         ;/
            push ax
            mov si,[Heart1_x]                               ;\
            shl si,1                                        ; \
            movsx eax,[Cosine+si]                           ;  \
            sal eax,8                                       ;   > AX = column
            imul eax,eax,(ScreenWidth-TinyHeartWidth)/2     ;  /
            shr eax,16                                      ; /
            add ax,(ScreenWidth-TinyHeartWidth)/2           ;/
            push ax
            call add_bitmap
            add sp,14

            ;update the angles
            add [Heart1_x],Heart1XAngleInc
            and [Heart1_x],1023
            add [Heart1_y],Heart1YAngleInc
            and [Heart1_y],1023

            ;calculate the position
            push (seg TinyHeartData) (offset TinyHeartData)
            push TinyHeartHeight TinyHeartWidth
            push [HiddenPage]
            mov si,[Heart2_y]                               ;\
            shl si,1                                        ; \
            movsx eax,[Sine+si]                             ;  \
            sal eax,8                                       ;   > AX = row
            imul eax,eax,(ScreenHeight-TinyHeartHeight)/2   ;  /
            shr eax,16                                      ; /
            add ax,(ScreenHeight-TinyHeartHeight)/2         ;/
            push ax
            mov si,[Heart2_x]                               ;\
            shl si,1                                        ; \
            movsx eax,[Cosine+si]                           ;  \
            sal eax,8                                       ;   > AX = column
            imul eax,eax,(ScreenWidth-TinyHeartWidth)/2     ;  /
            shr eax,16                                      ; /
            add ax,(ScreenWidth-TinyHeartWidth)/2           ;/
            push ax
            call add_bitmap
            add sp,14

            ;update the angles
            add [Heart2_x],Heart2XAngleInc
            and [Heart2_x],1023
            add [Heart2_y],Heart2YAngleInc
            and [Heart2_y],1023

            ret
endp        DrawHearts
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
            end     Start
