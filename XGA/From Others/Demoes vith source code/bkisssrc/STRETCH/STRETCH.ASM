ideal
locals
jumps
model huge
stack 100h
p386


TextMode = 0
LoopDemo = 0            ;loop infinitely?
AngleStep = 5           ;amount to rotate image
DebugKeys = 0           ;active debugging keys?

segment     MyCode
            assume cs:MyCode, ds:MyData, es:VideoSeg, fs:CompiledTextSeg
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "drawstr.inc"
include     "sincos.inc"
FadeHandler = RefreshScreen
include     "palette.inc"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       WaitForRetrace
            local @@ras1, @@ras2
            mov dx,3dah
@@ras1:     in al,dx
            test al,8
            jnz @@ras1
@@ras2:     in al,dx
            test al,8
            jz @@ras2
endm        WaitForRetrace
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        Start
            ;set up all of the segments
            cld
            mov ax,MyData
            mov ds,ax
            mov ax,VideoSeg
            mov es,ax
            mov ax,CompiledTextSeg
            mov fs,ax

            ;switch over to graphics mode
            mov ax,0013h
            int 10h

            ;load in the palette
            mov si,offset CurrentPal
            mov di,offset HeartPalette
            call fade_to

@@MainLoop: call RefreshScreen
            jc @@AllDone

            ;get stdio.  If something's been pressed, quit
            mov ah,6
            mov dl,0FFh
            int 21h
            jz @@MainLoop
            if DebugKeys ne 0
                cmp al,'1'
                jb @@AllDone
                cmp al,'3'
                ja @@AllDone
                sub al,'0'
                xor ah,ah
                mov [Method],ax
                jmp @@MainLoop
            endif

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
            ;get some text on screen
            cmp [TextDelay],0
            jnz @@NoText
            call MoreText
            if LoopDemo eq 0
                jc @@AllDone
            endif
@@NoText:   dec [TextDelay]

            ;draw a frame
            mov si,[ScalePtr]           ;\
            shl si,1                    ; \
            movsx ebx,[Sine+si]         ;  \
            sal ebx,9                   ;   > SI = angle
            mov si,[Angle]              ;  /  EBX = scaler (16.16 fixed point)
            mov ax,[Method]             ; /
            call DrawFrame              ;/
            add [Angle],AngleStep       ;\ increment the angle
            and [Angle],1023            ;/
            inc [ScalePtr]              ;\ increment the scaler
            and [ScalePtr],1023         ;/

            ;wait for a retrace to complete (for timing)
            WaitForRetrace
            clc

@@AllDone:  ret
endp        RefreshScreen
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc        MoreText
            ;set default time before we return again
            mov [TextDelay],120

            ;clear our text buffer
            cmp [@@DontClear],0
            jnz @@TextLoop
            xor eax,eax
            mov cx,(320*200)/4
            xor di,di
@@Wipe:     mov [dword fs:di],eax
            add di,4
            dec cx
            jnz @@Wipe

            ;render the text
@@TextLoop: mov si,[TextPtr]
            cmp [word si],-1            ;\ have we reached end of text?
            jz @@Restart                ;/    yes -- loop it again
            cmp [word si],-2            ;\ have we reached end of this page?
            jz @@PageDone               ;/    yes -- return
            cmp [word si],-3            ;\ is it a 'wait until angle' command?
            jz @@WaitAngle              ;/    yes -- handle it
            cmp [word si],-4            ;\ is it a 'change method' command?
            jz @@ChangeMethod           ;/    yes -- handle it
            cmp [word si],-5            ;\ is it a 'set delay' command?
            jz @@SetDelay               ;/    yes -- handle it
            push (seg CompiledText) (offset CompiledText)
            push [word si+2] [word si]  ;push the row and column
            add si,4
            push (seg ScrollText) si    ;push the pointer to the text
            push (seg FontData) (offset FontData)
            call _Draw_String
            add sp,16
            mov si,[TextPtr]
            add si,5
@@FindEnd:  lodsb                       ;\
            or al,al                    ; > seek to the end of this row
            jnz @@FindEnd               ;/
            mov [TextPtr],si
            jmp @@TextLoop              ;else do the next line

@@WaitAngle:mov [TextDelay],1
            mov [@@DontClear],1
            mov ax,[word si+2]
            sub ax,[Angle]
            cmp ax,0
            jg @@WaitRet
            cmp ax,-AngleStep
            jle @@WaitRet
            add [TextPtr],4
            mov [@@DontClear],0
            mov [TextDelay],120
            jmp @@TextLoop
@@WaitRet:  clc
            ret
@@DontClear db 0

@@ChangeMethod:
            mov ax,[word si+2]
            mov [Method],ax
            add [TextPtr],4
            jmp @@TextLoop

@@SetDelay: mov ax,[word si+2]
            mov [TextDelay],ax
            add [TextPtr],4
            jmp @@TextLoop

@@PageDone: add [TextPtr],2
            clc
            ret

@@Restart:  if LoopDemo ne 0
                mov [TextPtr],offset ScrollText
                clc
            else
                stc
            endif
            ret
endp        MoreText
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           AX = stretch method (1 = none, 2 = full stretch, 3 = 45ø stretch)
;           SI = angle (0 to 1023)
;           EBX = scale factor (16.16 fixed point)
;
proc        DrawFrame
            cmp ax,1
            jz @@Normal
            cmp ax,2
            jz @@Full
            cmp ax,3
            jz @@45
            ret

@@Normal:   shl si,1                    ;SI = current angle offset
            mov ecx,10000h              ;
            movsx eax,[Cosine+si]       ;\
            sal eax,8                   ; \ calculate cos(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@X_add],eax           ;/
            movsx eax,[Sine+si]         ;\
            sal eax,8                   ; \ calculate sin(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@Y_add],eax           ;/
            shr si,1                    ;\
            add si,256                  ; \ rotate 90ø
            and si,1023                 ; /
            shl si,1                    ;/
            movsx eax,[Cosine+si]       ;\
            sal eax,8                   ; \ calculate cos(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@X_lineadd],eax       ;/
            movsx eax,[Sine+si]         ;\
            sal eax,8                   ; \ calculate sin(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; /  16.16 fixed point format
            mov [@@Y_lineadd],eax       ;/
            jmp @@Go                    ;start rendering!
@@Full:     shl si,1                    ;SI = current angle offset
            mov ecx,10000h              ;
            movsx eax,[Cosine+si]       ;\
            sal eax,8                   ; \
            imul ebx                    ;  \ calculate cos(SI) and convert to
            idiv ecx                    ;  / 16.16 fixed point format
            mov [@@X_add],eax           ; /
            mov [@@Y_lineadd],eax       ;/
            movsx eax,[Sine+si]         ;\
            sal eax,8                   ; \
            imul ebx                    ;  \ calculate sin(SI) and convert to
            idiv ecx                    ;  / 16.16 fixed point format
            mov [@@Y_add],eax           ; /
            mov [@@X_lineadd],eax       ;/
            jmp @@Go                    ;start rendering!
@@45:       shl si,1                    ;SI = current angle offset
            mov ecx,10000h              ;
            movsx eax,[Cosine+si]       ;\
            sal eax,8                   ; \ calculate cos(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@X_add],eax           ;/
            movsx eax,[Sine+si]         ;\
            sal eax,8                   ; \ calculate sin(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@Y_add],eax           ;/
            shr si,1                    ;\
            add si,256                  ; \ rotate 90ø
            and si,1023                 ; /
            shl si,1                    ;/
            movsx eax,[Cosine+si]       ;\
            sal eax,8                   ; \ calculate cos(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; / 16.16 fixed point format
            mov [@@Y_lineadd],eax       ;/
            movsx eax,[Sine+si]         ;\
            sal eax,8                   ; \ calculate sin(SI) and convert to
            imul ebx                    ;  >
            idiv ecx                    ; /  16.16 fixed point format
            mov [@@X_lineadd],eax       ;/

@@Go:       mov di,offset VideoBuffer   ;ES:DI ==> refresh buffer
            mov [@@Col],0               ;\ set initial position in bitmap
            mov [@@Row],0               ;/
            mov cx,200                  ;CX = number of rows
@@RowLoop:      push cx                     ;save CX
                mov cx,160                  ;CX = number of columns
                mov eax,[@@Col]             ;\ load position into registers
                mov ebx,[@@Row]             ;/
@@ColLoop:          mov dx,[word fs:di]
                    mov esi,ebx
                    mov ebp,eax
                    shr esi,16
                    shr ebp,16
                    and si,63
                    and bp,63
                    shl si,6
                    add ebx,[@@Y_add]
                    add eax,[@@X_add]
                    add dl,[byte ds:si+bp+offset HeartImage]
                    mov esi,ebx
                    mov ebp,eax
                    shr esi,16
                    shr ebp,16
                    and si,63
                    and bp,63
                    shl si,6
                    add ebx,[@@Y_add]
                    add dh,[byte ds:si+bp+offset HeartImage]
                    add eax,[@@X_add]
                    mov [word es:di],dx
                    add di,2
                dec cx
                jnz @@ColLoop
                mov eax,[@@X_lineadd]       ;\
                add [@@Col],eax             ; \ update our variables
                mov eax,[@@Y_lineadd]       ; /
                add [@@Row],eax             ;/
                pop cx                      ;restore CX
            dec cx                      ;\ loop until all rows done
            jnz @@RowLoop               ;/
            ret                         ;return
@@X_add     dd 0        ;amount to add to Col after each pixel
@@Y_add     dd 0        ;amount to add to Row after each pixel
@@X_lineadd dd 0        ;amount to add to Col after each row
@@Y_lineadd dd 0        ;amount to add to Row after each row
@@Col       dd 0        ;current Column in bitmap (modulo 64)
@@Row       dd 0        ;current Row in bitmap (modulo 64)
endp        DrawFrame
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode

macro       DefineText X,Y,text
            dw X,Y
            db text,0
endm        DefineText

macro       Delay time
            dw -5,time
endm        Delay

macro       ChangeMethod method
            dw -4,method
endm        ChangeMethod

macro       WaitUntilAngle theta
            dw -3,(theta-1024/4) AND 1023
endm        WaitUntilAngle

macro       EndOfPage
            dw -2
endm        EndOfPage

macro       EndOfText
            dw -1
endm        EndOfText

segment     MyData
Angle       dw 0                    ;0 to 1023 (0 = 1024 = 360ø)
Scale       dd 0                    ;scale factor (16.16 fixed point)
Method      dw 1                    ;rendering method
ScalePtr    dw 0
label       ScrollText byte
            ;DefineText 10,50,"jeff rules!"     ;too objectionable :)
            DefineText 61,100,"isn't this"
            DefineText 41,150,"really cool?"
            WaitUntilAngle 128
            ChangeMethod 2
            Delay 30
            EndOfPage

            DefineText 36,40,"there's even"
            DefineText 46,90,"transparent"
            DefineText 96,140,"text!"
            WaitUntilAngle 640
            ChangeMethod 3
            Delay 45
            EndOfPage

            WaitUntilAngle 128
            ChangeMethod 2
            Delay 30
            EndOfPage

            DefineText 30,53,"having fun?"
            WaitUntilAngle 640
            ChangeMethod 1
            DefineText 45,90,"well you"
            DefineText 30,135,"shouldn't be!"
            Delay 80
            EndOfPage
            EndOfText
TextDelay   dw 0
TextPtr     dw offset ScrollText
CurrentPal  db 256 dup(0,0,0)
extrn       HeartImage:byte     ;this should be a 64x64x256 raw image
extrn       HeartPalette:byte   ;this should be a 256 color triplet map
extrn       FontData:byte       ;this should be a valid JLF font
ends        MyData

segment     CompiledTextSeg
label       CompiledText byte
ends        CompiledTextSeg

segment     VideoSeg at 0A000h
VideoBuffer db 320*200 dup (?)
ends        VideoSeg

            end     Start
