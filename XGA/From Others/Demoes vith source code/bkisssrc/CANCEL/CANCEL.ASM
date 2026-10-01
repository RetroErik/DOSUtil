ideal
locals
jumps
model huge
stack 100h
p386

NumFrames = 2500
Layer1XAngleInc = 4
Layer1YAngleInc = 2
Layer2XAngleInc = 3
Layer2YAngleInc = 5
TextMode = 0

segment     MyData
FramesLeft  dw NumFrames
Layer1_pos  dw ?
Layer1_x    dw 0
Layer1_y    dw 45
Layer2_pos  dw ?
Layer2_x    dw 180
Layer2_y    dw 270
VisualPage  dw ?                    ;offset of visual page
HiddenPage  dw ?                    ;offset of hidden page
CurrentPal  db 256 dup(0,0,0)
extrn       PaletteData:byte        ;this should be a RGB triplet palette
ends        MyData

segment     BitmapSeg
extrn       BitmapData:byte         ;this should be a 320x200x256 bitmap
ends        BitmapSeg

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "sincos.inc"
include     "modex.inc"
FadeHandler = RefreshScreen
include     "palette.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax

            ;switch over to graphics mode
            @SetModeX M320x80x256,320
            ScreenWidth = 320
            ScreenHeight = 80
            PageSize = (ScreenWidth*ScreenHeight)/4
            mov [VisualPage],0
            mov [HiddenPage],PageSize

            ;load in the palette
            mov si,offset CurrentPal
            mov di,offset PaletteData
            call fade_to

@@MainLoop: call RefreshScreen

            ;if we've done enough, then quit
            dec [FramesLeft]
            jz @@AllDone

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

            call MovePointers
            call RenderBuffer

            ;flip to the next page
            mov ax,[VisualPage]
            xchg [HiddenPage],ax
            mov [VisualPage],ax

            ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        RenderBuffer
            ;set the active plane
            mov ah,1111b
            @Set_Write_Plane

            ;set up our pointers
            mov es,[VGASeg]             ;\ ES:DI ==> hidden page
            mov di,[HiddenPage]         ;/
            mov ax,BitmapSeg
            mov fs,ax
            mov si,[Layer1_pos]
            add si,offset BitmapData
            mov bx,[Layer2_pos]
            add bx,offset BitmapData

            ;start doing the work
            mov dx,ScreenHeight
@@RowLoop:      mov cx,ScreenWidth/4
@@ColLoop:          mov al,[byte fs:si]
                    inc si
                    xor al,[byte fs:bx]
                    inc bx
                    mov [byte es:di],al
                    inc di
                dec cx
                jnz @@ColLoop
                add si,(320-ScreenWidth/4)
                add bx,(320-ScreenWidth/4)
            dec dx
            jnz @@RowLoop

            ret
endp        RenderBuffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        MovePointers
            ;calculate the position
            mov si,[Layer1_y]                   ;\
            shl si,1                            ; \
            movsx eax,[Sine+si]                 ;  \
            sal eax,8                           ;   > AX = row for block
            imul eax,eax,(200-ScreenHeight)/2   ;  /
            shr eax,16                          ; /
            add ax,200/2-(ScreenHeight/2)       ;/
            imul di,ax,320                      ;DI = AX * 320
            mov si,[Layer1_x]                   ;\
            shl si,1                            ; \
            movsx eax,[Cosine+si]               ;  \
            sal eax,8                           ;   > AX = column for block
            imul eax,eax,(320-ScreenWidth/4)/2  ;  /
            shr eax,16                          ; /
            add ax,320/2-(ScreenWidth/4/2)      ;/
            add di,ax                           ;DI = DI + AX
            mov [Layer1_pos],di                 ;save the position

            ;update the angles
            add [Layer1_x],Layer1XAngleInc
            and [Layer1_x],1023
            add [Layer1_y],Layer1YAngleInc
            and [Layer1_y],1023

            ;calculate the position
            mov si,[Layer2_y]                   ;\
            shl si,1                            ; \
            movsx eax,[Sine+si]                 ;  \
            sal eax,8                           ;   > AX = row for block
            imul eax,eax,(200-ScreenHeight)/2   ;  /
            shr eax,16                          ; /
            add ax,200/2-(ScreenHeight/2)       ;/
            imul di,ax,320                      ;DI = AX * 320
            mov si,[Layer2_x]                   ;\
            shl si,1                            ; \
            movsx eax,[Cosine+si]               ;  \
            sal eax,8                           ;   > AX = column for block
            imul eax,eax,(320-ScreenWidth/4)/2  ;  /
            shr eax,16                          ; /
            add ax,320/2-(ScreenWidth/4/2)      ;/
            add di,ax                           ;DI = DI + AX
            mov [Layer2_pos],di                 ;save the position

            ;update the angles
            add [Layer2_x],Layer2XAngleInc
            and [Layer2_x],1023
            add [Layer2_y],Layer2YAngleInc
            and [Layer2_y],1023

            ret
endp        MovePointers
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
            end     Start
