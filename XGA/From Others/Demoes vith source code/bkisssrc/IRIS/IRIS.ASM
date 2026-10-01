ideal
locals
jumps
model huge
stack 100h
p386

NumFrames = 2500
TextMode = 0
Layer1XAngleInc = 2
Layer1YAngleInc = 6
Layer2XAngleInc = 4
Layer2YAngleInc = 3

segment     MyData
FramesLeft  dw NumFrames
Layer1_pos  dw ?
Layer1_x    dw 0
Layer1_y    dw 45
Layer2_pos  dw ?
Layer2_x    dw 180
Layer2_y    dw 270
FrameNumber dw 0                    ;number of frames we've done so far
VisualPage  dw ?                    ;offset of visual page
HiddenPage  dw ?                    ;offset of hidden page
CurrentPal  db 256 dup(0,0,0)       ;initial palette (all black)
extrn       PaletteData:byte        ;this should be a RGB triplet palette
include     "sincos.inc"
ends        MyData

segment     MyCode
            assume cs:MyCode, ds:MyData, es:VideoSegment, fs:DataTableSeg
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
FadeHandler = RefreshScreen
include     "palette.inc"
include     "modex.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax
            mov ax,VideoSegment
            mov es,ax
            mov ax,DataTableSeg
            mov fs,ax

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

            ;render the screen
            call RenderBuffer
            call MovePointers

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
            mov di,[HiddenPage]
            mov si,[Layer1_pos]
            mov bx,[Layer2_pos]

            ;start doing the work
            mov dx,ScreenHeight
@@RowLoop:      mov cx,ScreenWidth/4
@@ColLoop:          mov al,[byte fs:si]
                    inc si
                    add al,[byte fs:bx]
                    jnz @@okay
                    inc al
@@okay:             inc bx
                    mov [byte es:di],al
                    inc di
                dec cx
                jnz @@ColLoop
                add si,(256-ScreenWidth/4)
                add bx,(256-ScreenWidth/4)
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
            imul eax,eax,(256-ScreenHeight)/2   ;  /
            shr eax,16                          ; /
            add ax,256/2-(ScreenHeight/2)       ;/
            shl ax,8                            ;\
            mov di,ax                           ;/ DI = AX * 256
            mov si,[Layer1_x]                   ;\
            shl si,1                            ; \
            movsx eax,[Cosine+si]               ;  \
            sal eax,8                           ;   > AX = column for block
            imul eax,eax,(256-ScreenWidth/4)/2  ;  /
            shr eax,16                          ; /
            add ax,256/2-(ScreenWidth/4/2)      ;/
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
            imul eax,eax,(256-ScreenHeight)/2   ;  /
            shr eax,16                          ; /
            add ax,256/2-(ScreenHeight/2)       ;/
            shl ax,8                            ;\
            mov di,ax                           ;/ DI = AX * 256
            mov si,[Layer2_x]                   ;\
            shl si,1                            ; \
            movsx eax,[Cosine+si]               ;  \
            sal eax,8                           ;   > AX = column for block
            imul eax,eax,(256-ScreenWidth/4)/2  ;  /
            shr eax,16                          ; /
            add ax,256/2-(ScreenWidth/4/2)      ;/
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

segment     VideoSegment at 0A000h
VideoBuffer db 0FFFFh dup (?)
ends        VideoSegment

segment     DataTableSeg
extrn       DataTable:byte
ends        DataTableSeg

            end     Start
