ideal
locals
jumps
p386
model huge
stack 100h

TextMode = 0
LoopDemo = 0
AngleInc    = 3
MaxZpos     = 512
MinZpos     = 2
WarpSpeed   = 8
Step        = 15                    ;maximum number of stars per Z level
MaxStars    = MaxZpos/WarpSpeed*Step

struc       Star_Struc
X           dw  0       ;\
Y           dw  0       ; > coordinates of star (if Z < MinZpos, star is dead)
Z           dw  0       ;/
CenterX     dw  0
CenterY     dw  0
OldDi       dw  0       ;where to erase last dot
Color       db  0       ;base color (a number 0-15 is added to it)
ends        Star_Struc


segment     Code
            assume cs:Code, ds:Code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "modex.inc"
include     "drawstr.inc"
FadeHandler = RefreshScreen
include     "palette.inc"
include     "heart.inc"
include     "sincos.inc"
extrn       FontData:byte
extrn       Palette:byte
CurrentPal  db 256 dup(0,0,0)
NumColors   = 5
Cindex      dw 0
ColorChart  db 0,32,64,96,128,160
Index       dw 0
XAngle      dw 0
YAngle      dw 0
Stars       Star_Struc MaxStars DUP (<>)
               ;°°°°°°°°°°°°°°°°°°°°°;
ScrollText  db 0
            db ' this is my version  ',0
            db 'of the old fashioned ',0
            db ' tunnel of love  :)  ',0
            db '                     ',0
            db '                     ',0
            db '                     ',0
            db '     time to go!     ',0
            db -1
ScrollPtr   dw offset ScrollText
ScrollDelay dw 0
ScrollCol   dw 3
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up the segments
            mov ax,Code
            mov ds,ax
            mov es,[VGASeg]

            ;change to graphics mode
            ScreenWidth = 320
            ScreenHeight = 200
            @SetModeX M320x200x256,320

            ;initialize the split screen
            SplitHeight = 24
            ScreenHeight = ScreenHeight - SplitHeight
            mov bx,ScreenHeight*2       ;VGA bug when switching chaining on?
            @Set_Split

            ;other stuff
            mov bx,ScreenWidth/4*SplitHeight
            @Set_Start_Offset
            @ResetLinear

            ;write out our palette
            mov si,offset CurrentPal
            mov di,offset Palette
            call fade_to

            ;clear out the bottom
            xor di,di
            mov cx,SplitHeight*ScreenWidth
            mov al,198
            rep stosb

@@MainLoop: call RefreshScreen
            jc @@AllDone

            ;get stdio.  If something's been pressed, quit
            mov ah,6
            mov dl,0FFh
            int 21h
            jz @@MainLoop

@@AllDone:  call fade_out

            ;return to text mode and quit to DOS
            if TextMode ne 0
                mov ax,0003h
                int 10h
            endif
            mov ax,4C00h
            int 21h
endp        Start
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        RefreshScreen
            ;put some text at the bottom
            cmp [ScrollDelay],0
            jnz @@NoText
@@DecodeIt: mov si,[ScrollPtr]
            cmp [byte si],0
            jz @@EndOfLine
            cmp [byte si],-1
            jz @@EndOfText
            push [VGASeg] 0
            push 2 [ScrollCol]
            push (seg ScrollText) [ScrollPtr]
            push (seg FontData) (offset FontData)
            call _Draw_Letter
            add sp,16
            add [ScrollCol],ax
            inc [ScrollPtr]
            mov [ScrollDelay],2
            jmp @@NoText
@@EndOfLine:inc [ScrollPtr]
            mov [ScrollDelay],80
            mov [ScrollCol],3
            jmp @@NoText
@@EndOfText:if LoopDemo ne 0
                mov [ScrollPtr],offset ScrollText
                mov [ScrollDelay],1     ;cause it will be DEC'd two lines below
                mov [ScrollCol],3
            else
                stc
                ret
            endif
@@NoText:   dec [ScrollDelay]

            ;make some more stars
            call MakeStar
            add [XAngle],AngleInc*2
            and [XAngle],1023
            add [YAngle],AngleInc
            and [YAngle],1023

            ;wait for a full vertical retrace (for timing)
            @FullVertWait

            ;draw the stars
            call DisplayStars

            clc
            ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;finds 1st available slot for a star and puts it there
proc        MakeStar
            mov bp,Step
            ;search for first available slot
            mov si,offset Stars
@@TryAgain: cmp [si+Star_Struc.Z],MinZpos
            jg @@NextStar

@@GotOne:   ;generate a color for the star
            mov di,[Cindex]
            mov al,[ColorChart+di]
            mov [si+Star_Struc.Color],al

            ;get the next default point list pointer
            mov di,[Index]
            imul di,size Point_Type
            add di,offset DefaultPoints

            ;generate an X coordinate for the star
            mov ax,[di+Point_Type.X]
            sal ax,5
            mov [si+Star_Struc.X],ax

            ;generate a Y coordinate for the star
            mov ax,[di+Point_Type.Y]
            sal ax,5
            mov [si+Star_Struc.Y],ax

            ;generate a Z coordinate for the star
            mov [si+Star_Struc.Z],MaxZpos

            ;generate a Center X for the star
            mov di,[XAngle]
            shl di,1
            mov ax,(ScreenWidth/2)-80
            imul [Cosine+di]
            shl edx,16
            mov dx,ax
            sar edx,8
            add edx,ScreenWidth/2
            mov [si+Star_Struc.CenterX],dx

            ;generate a Center Y for the star
            mov di,[YAngle]
            shl di,1
            mov ax,(ScreenHeight/2)-50
            imul [Sine+di]
            shl edx,16
            mov dx,ax
            sar edx,8
            add edx,ScreenHeight/2
            mov [si+Star_Struc.CenterY],dx

            ;update all of these pointers
            inc [Index]
            cmp [Index],NumDefaultPoints
            jb @@IndexOK
            mov [Index],0
@@IndexOK:  inc [Cindex]
            cmp [Cindex],NumColors
            jb @@ColorOK
            mov [Cindex],0
@@ColorOK:  dec bp
            jz @@Quit

@@NextStar: add si,size Star_Struc
            cmp si,offset Stars+MaxStars*size Star_Struc
            jb @@TryAgain
@@Quit:     ret
endp        MakeStar
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;update the display
proc        DisplayStars
            mov si,offset Stars
@@Search:   cmp [si+Star_Struc.Z],MinZpos
            jle @@NextStar

            ;erase the old star
            mov di,[si+Star_Struc.OldDi]
            mov [byte es:di],0

            ;compute screen Y coordinate
            mov ax,[si+Star_Struc.Y]
            cwd
            idiv [si+Star_Struc.Z]
            add ax,[si+Star_Struc.CenterY]
            cmp ax,ScreenHeight
            jae @@KillStar
            imul di,ax,ScreenWidth          ;DI = row * ScreenWidth
add di,ScreenWidth*SplitHeight

            ;compute screen X coordinate
            mov ax,[si+Star_Struc.X]
            cwd
            idiv [si+Star_Struc.Z]
            add ax,[si+Star_Struc.CenterX]
            cmp ax,ScreenWidth
            jae @@KillStar
            add di,ax                       ;DI = row * ScreenWidth + col
            mov [si+Star_Struc.OldDi],di    ;save it

            ;calculate the color
            mov ax,[si+Star_Struc.Z]
            shr ax,4
            add al,[si+Star_Struc.Color]
            mov [byte es:di],al

            ;move the star closer
            mov ax,WarpSpeed
            sub [si+Star_Struc.Z],ax
            jmp @@NextStar

@@KillStar: mov [si+Star_Struc.Z],0
@@NextStar: add si,size Star_Struc
            cmp si,offset Stars+MaxStars*size Star_Struc
            jb @@Search
            ret
endp        DisplayStars
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        Code
            end Start
