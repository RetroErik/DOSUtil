ideal
locals
jumps
model huge
stack 100h
p386

TextMode = 0
CupidWidth = 144
CupidHeight = 79
PanScrollRate = 1

segment     MyData
PanPosition dw 0
extrn       MyPalette:byte          ;this should be a 256 RGB triplet palette
extrn       MyImage:byte            ;this should be a 320x200x256 image
ends        MyData

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
extrn       MyCupid:byte            ;an image with the above dimensions
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "modex.inc"
include     "bitmap.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax

            ;switch over to graphics mode
            @SetModeX M320x200x256,320*4
            ScreenWidth = 320
            ScreenHeight = 200

            ;load in the palette
            mov si,offset MyPalette
            mov ax,0
            mov cx,256
            @WritePalette

            ;set the starting scroll location
            mov bx,[PanPosition]
            @Set_Start_Offset

            ;paste on the left cupid
            push (seg MyCupid) (offset MyCupid)
            push CupidHeight CupidWidth
            push 0
            push ((ScreenHeight-CupidHeight)/2) (ScreenWidth+(ScreenWidth-CupidWidth))
            call put_masked_bitmap
            add sp,14

            ;paste on the main image
            push (seg MyImage) (offset MyImage)
            push 200 320
            push 0
            push 0 (ScreenWidth+ScreenWidth)
            call put_masked_bitmap
            add sp,14

            ;paste on the right cupid
            push (seg MyCupid) (offset MyCupid)
            push CupidHeight CupidWidth
            push 0
            push ((ScreenHeight-CupidHeight)/2) (ScreenWidth+ScreenWidth+ScreenWidth)
            call put_masked_bitmap
            add sp,14

@@ScrollTo: ;wait for the vertical retrace to pass
            @WaitVertEnd

            ;update the screen's position
            mov bx,[PanPosition]
            @Set_Start_Offset

            ;wait for the vertical retrace to start
            @WaitVert

            ;scroll over
            add [PanPosition],PanScrollRate
            cmp [PanPosition],(ScreenWidth+ScreenWidth)/4
            jb @@ScrollTo

            ;make sure it's where it's supposed to be
            mov bx,(ScreenWidth+ScreenWidth)/4
            @Set_Start_Offset
            
            ;pause
            mov cx,60
@@Delay:    @FullVertWait
            loop @@Delay

@@ScrollFrom:;wait for the vertical retrace to pass
            @WaitVertEnd

            ;update the screen's position
            mov bx,[PanPosition]
            @Set_Start_Offset

            ;wait for the vertical retrace to start
            @WaitVert

            ;scroll over
            add [PanPosition],PanScrollRate
            cmp [PanPosition],(ScreenWidth+ScreenWidth+ScreenWidth+ScreenWidth)/4
            jb @@ScrollFrom

            ;change back to text mode and quit
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
