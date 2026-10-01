ideal
locals
jumps
model huge
stack 100h
p386

TextMode = 0
NumFrames = 4000                    ;number of frames to do before quitting
MaxBobs = 75                        ;maximum number of active bobs
HeartWidth = 32                     ;\ dimensions of the image
HeartHeight = 25                    ;/
XRadius = 120                       ;\ radius of path
YRadius = 60                        ;/
Phase1Inc = 2                       ;\ amount to add to phase
Phase2Inc = 3                       ;/

segment     MyData
FramesLeft  dw NumFrames            ;number of frames left
BobBuffer   dd MaxBobs dup (-1)     ;our buffer containing X and Y of each bob
NextSlot    dw 0                    ;pointer into next available slot
Row         dw 100                  ;\ computed coordinates
Col         dw 100                  ;/
Angle       dw 0                    ;\
Phase1      dw 2*1024               ; > used during computation
Phase2      dw 2*1024               ;/
extrn       HeartImage:byte         ;this is the image
extrn       PaletteData:byte        ;this should be a RGB triplet palette
ends        MyData

segment     MyCode
            assume cs:MyCode, ds:MyData
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "sincos.inc"
include     "modex.inc"
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

            ;load in the palette
            mov si,offset PaletteData
            mov cx,256
            mov al,0
            @WritePalette

@@MainLoop: call RefreshScreen

            dec [FramesLeft]
            jz @@AllDone
            
            ;get stdio.  If something's been pressed, quit
            mov ah,6
            mov dl,0FFh
            int 21h
            jz @@MainLoop

@@AllDone:  call DeleteAll

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
            ;wait for a retrace (for timing)
            @FullVertWait

            ;compute the coordinates of the next bob
            call ComputePos

            ;get a pointer to the next slot
            mov si,[NextSlot]
            shl si,2
            add si,offset BobBuffer

            ;erase the old bob, if the slot is occupied
            cmp [dword ds:si],-1
            jz @@EmptySlot
            push (seg HeartImage) (offset HeartImage)
            push HeartHeight HeartWidth
            push 0
            push [word ds:si+2] [word ds:si+0]
            call sub_bitmap
            add sp,14

@@EmptySlot:;save the coordinates
            mov ax,[Col]
            mov [word ds:si+0],ax
            mov ax,[Row]
            mov [word ds:si+2],ax

            ;display the bob
            push (seg HeartImage) (offset HeartImage)
            push HeartHeight HeartWidth
            push 0
            push [Row] [Col]
            call add_bitmap
            add sp,14

            ;update our pointer
            inc [NextSlot]
            cmp [NextSlot],MaxBobs
            jb @@Quit
            mov [NextSlot],0
@@Quit:     ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        DeleteAll
            ;wait for a retrace (for timing)
            @FullVertWait

            ;get a pointer to the next slot
            mov si,[NextSlot]
            shl si,2
            add si,offset BobBuffer

            cmp [dword ds:si],-1
            jz @@EmptySlot
            cmp [dword ds:si],-2
            jz @@Quit
            ;erase the old bob, if the slot is occupied
            push (seg HeartImage) (offset HeartImage)
            push HeartHeight HeartWidth
            push 0
            push [word ds:si+2] [word ds:si+0]
            call sub_bitmap
            add sp,14
            mov [dword ds:si],-2
@@EmptySlot:;update our pointer
            inc [NextSlot]
            cmp [NextSlot],MaxBobs
            jb DeleteAll
            mov [NextSlot],0
            jmp DeleteAll

@@Quit:     ret
endp        DeleteAll
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        ComputePos
            ;compute the column
            mov ax,[Angle]
            imul [Phase1]
            mov bl,ah
            mov bh,dl
            shr bx,2
            xor bh,bh
            mov al,[Cosine+bx]
            mov ah,XRadius
            imul ah
            sar ax,6
            add ax,(ScreenWidth-HeartWidth)/2
            mov [Col],ax

            ;compute the row
            mov ax,[Angle]
            imul [Phase2]
            mov bl,ah
            mov bh,dl
            shr bx,2
            xor bh,bh
            mov al,[Sine+bx]
            mov ah,YRadius
            imul ah
            sar ax,6
            add ax,(ScreenHeight-HeartHeight)/2
            mov [Row],ax

            ;increment angle
            inc [Angle]
            and [Angle],1023

            ;increment phase 1
            add [Phase1],Phase1Inc
            cmp [Phase1],5*1024
            jb @@Phase1Ok
            sub [Phase1],5*1024
@@Phase1Ok:
            ;increment phase 2
            add [Phase2],Phase2Inc
            cmp [Phase2],5*1024
            jb @@Phase2Ok
            sub [Phase2],5*1024
@@Phase2Ok:
            ret
endp        ComputePos
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
            end     Start
