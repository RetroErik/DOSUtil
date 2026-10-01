ideal
locals
jumps
model huge
stack 100h
p386

TextMode = 0
LoopDemo = 0
MaxScale = 80000h
MinScale = 8000h
ScaleStep = 1000h
TextWait = 120


struc       BallType
Angle       dw ?
AngleStep   dw ?
StepSize    dw ?
Decay       dd ?
Col         dw ?
Row         dw ?
NeedReset   dw 1
ends        BallType

segment     MyData
TextAngle   dw 0
TextScale   dd MinScale
TextMessage db "  well, folks!",0
            db "it's really here!",0
            db " hope it brings",0
            db "great pleasure!",-1,0
TextOffset  dw 0
TextDelay   dw TextWait
MyBall      BallType <>,<>
VisualPage  dw ?                    ;offset of visual page
HiddenPage  dw ?                    ;offset of hidden page
extrn       MyPalette:byte          ;this should be a 256 RGB triplet palette
extrn       HeartImg:byte           ;this should be a 64x64x256 raw image
extrn       FontData:byte           ;this should be a valid JLF font file
ends        MyData

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "sincos.inc"
include     "modex.inc"
include     "bitmap.inc"
include     "drawstrx.inc"
FadeHandler = RefreshScreen
include     "palette.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax

            ;switch over to graphics mode
            @SetModeX M320x200x256,320
            ScrWidth = 320
            ScrHeight = 200
            PageSize = ScrWidth/4*ScrHeight
            mov [VisualPage],0
            mov [HiddenPage],PageSize

            ;load in the palette
            mov si,offset MyPalette
            mov ax,0
            mov cx,256
            @WritePalette

@@MainLoop: ;update the text stuff
            call UpdateText
            jc @@AllDone

            ;draw the screen
            call RefreshScreen

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

            ;clear our hidden buffer
            mov ah,1111b
            @Set_Write_Plane
            mov es,[VGASeg]
            mov di,[HiddenPage]
            mov cx,PageSize/2
            xor ax,ax
            cld
            rep stosw

            ;display the ball
            mov bp,offset MyBall
            mov ax,1
            call CalculateBounce
            push (seg HeartImg) (offset HeartImg)
            push 64 64
            push [HiddenPage]
            push [ds:bp+BallType.Row] [ds:bp+BallType.Col]
            call put_masked_bitmap
            add sp,14

            ;display the ball
            mov bp,offset MyBall+size BallType
            mov ax,2
            call CalculateBounce
            push (seg HeartImg) (offset HeartImg)
            push 64 64
            push [HiddenPage]
            push [ds:bp+BallType.Row] [ds:bp+BallType.Col]
            call put_masked_bitmap
            add sp,14

            ;render the text
            push [HiddenPage] 80 0
            mov ax,[TextOffset]
            add ax,offset TextMessage
            push (seg TextMessage) ax
            push (seg FontData) (offset FontData)
            mov si,[TextAngle]
            mov ebx,[TextScale]
            call _Draw_String
            add sp,14
            add [TextAngle],32
            and [TextAngle],1023

            ;flip to the next page
            mov ax,[VisualPage]
            xchg [HiddenPage],ax
            mov [VisualPage],ax

            ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        UpdateText
            cmp [TextDelay],0
            jnz @@DelayMore

            ;(called at end of line) seek to the next line of the message
            cmp [TextScale],MaxScale
            jb @@IncScale
            mov si,[TextOffset]
@@FindNext: mov al,[byte TextMessage+si]
            inc si
            cmp al,0
            jz @@GotNext
            cmp al,-1
            jz @@GotEnd
            jmp @@FindNext
@@GotNext:  mov [TextOffset],si
            mov [TextDelay],TextWait
            clc
            ret

@@GotEnd:   if LoopDemo eq 0
                stc
            else
                mov [TextOffset],0
                mov [TextDelay],TextWait
                clc
            endif
            ret

            ;get the text really 'abnormal'
@@IncScale: add [TextScale],ScaleStep
            clc
            ret

            ;(called normally) get the text close to 'normal'
@@DelayMore:cmp [TextScale],MinScale
            jbe @@Delay2
            sub [TextScale],ScaleStep
            clc
            ret
@@Delay2:   dec [TextDelay]
            clc
            ret
endp        UpdateText
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;calculate the position of the ball
;
;           DS:BP ==> ball structure
;           AX = ball number (1 or 2)
;
proc        CalculateBounce
            mov [@@Type],ax
            cmp [ds:bp+BallType.NeedReset],0
            jz @@CalcRow

@@ResetIt:  ;initialize some things
            cmp [@@Type],1
            jz @@Type1
            jmp @@Type2
@@Type1:    mov [ds:bp+BallType.Angle],256          ;ball's current position
            mov [ds:bp+BallType.AngleStep],17       ;ball's progression rate
            mov [ds:bp+BallType.Col],0              ;\ reset the position
            mov [ds:bp+BallType.Row],0              ;/
            mov [ds:bp+BallType.StepSize],3         ;direction and step size
            mov [ds:bp+BallType.Decay],00010000h    ;how much until it stops
            mov [ds:bp+BallType.NeedReset],0        ;say it's been initialized
            jmp @@CalcRow
@@Type2:    mov [ds:bp+BallType.Angle],256          ;ball's current position
            mov [ds:bp+BallType.AngleStep],17       ;ball's progression rate
            mov [ds:bp+BallType.Col],ScrWidth-64    ;\ reset the position
            mov [ds:bp+BallType.Row],0              ;/
            mov [ds:bp+BallType.StepSize],-3        ;direction and step size
            mov [ds:bp+BallType.Decay],00010000h    ;how much until it stops
            mov [ds:bp+BallType.NeedReset],0        ;say it's been initialized


@@CalcRow:  ;calculate row of the ball
            mov si,[ds:bp+BallType.Angle]           ;\
            shl si,1                                ; \ EAX = sin(Angle)
            movsx eax,[Sine+si]                     ; /
            sal eax,8                               ;/
            cdq                                     ;\
            xor eax,edx                             ; > EAX = abs(EAX)
            sub eax,edx                             ;/
            mul [ds:bp+BallType.Decay]              ;\ EAX = EAX ù Decay
            shrd eax,edx,16                         ;/
            imul eax,(ScrHeight-64)                 ;\
            add eax,8000h                           ; > EAX = CINT(EDX ù
            shr eax,16                              ;/      (ScrHeight-64))
            mov dx,(ScrHeight-64)                   ;\
            sub dx,ax                               ; > Row = ScrHeight - EAX
            mov [ds:bp+BallType.Row],dx             ;/

            ;calculate the column of the ball (reflecting if necessary)
            mov ax,[ds:bp+BallType.StepSize]
            add [ds:bp+BallType.Col],ax
            cmp [ds:bp+BallType.Col],0
            jl @@OtherWay
            cmp [ds:bp+BallType.Col],ScrWidth-64
            jl @@ChkBounce
@@OtherWay: neg [ds:bp+BallType.StepSize]
            mov ax,[ds:bp+BallType.StepSize]
            add [ds:bp+BallType.Col],ax

            ;handle bouncing
@@ChkBounce:cmp [ds:bp+BallType.Row],ScrHeight-64-2 ;\ if we're not hitting
            jb @@DontSub                            ;/ the bottom then jump
            mov eax,0000F000h                       ;\
            mul [ds:bp+BallType.Decay]              ; \ decrease decay
            shrd eax,edx,16                         ; / slightly
            mov [ds:bp+BallType.Decay],eax          ;/
@@DontSub:  cmp [ds:bp+BallType.Decay],0000028Fh    ;
            jl @@ResetIt                            ;

            ;update angle
            mov ax,[ds:bp+BallType.AngleStep]       ;\
            add [ds:bp+BallType.Angle],ax           ; > update the angle
            and [ds:bp+BallType.Angle],1023         ;/

            ret
@@Type      dw ?
endp        CalculateBounce
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
            end     Start
