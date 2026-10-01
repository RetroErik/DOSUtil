;this module is a slightly modified version of Patch's original routine
;this adds in a table to translate each column of the text vertically

TransparentText = 1     ;set to 0 to draw backgrounds of letters
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
; int far Draw_String(byte far *fontdata, byte far *string,
;                  word xskip, word pageoffs);
;
PROC            Draw_String far
                push bp                         ;\ set up the stack frame
                mov bp,sp                       ;/

                mov [@@PlaneNum],1102h          ;start at plane 0
                mov [@@ColumnNum],0             ;start at screen column 0

                lgs si,[dword bp + 6]           ;GS:SI ==> start of fontdata
                mov es,[VGASeg]                 ;\ ES:DI ==> video offset
                mov di,[bp + 16]                ;/
                mov cx,[word bp + 14]           ;number of columns to skip
                lfs bp,[dword bp + 10]          ;FS:BP ==> string

@@SkipForward:  movzx bx,[byte fs:bp]           ;BX = next letter
                shl bx,1                        ;*2 = word sized
                mov [@@Save],si                 ;save our font pointer
                add si,[word 3+si+bx]           ;skip to the character's data
                movzx ax,[byte si+1]            ;AX = width of character
                cmp cx,ax                       ;
                jb @@StartWork                  ;
                sub cx,ax                       ;
                mov si,[@@Save]                 ;restore our font pointer
                inc bp                          ;next letter in message
                cmp [byte fs:bp],0              ;\ loop until we reach
                jne @@SkipForward               ;/ a null
                mov ax,-1                       ;say we've reached the end
                jmp @@Quit                      ;quit
@@StartWork:    mov al,[byte si+2]              ;\ AX = height of character *
                mul cl                          ;/      columns to skip
                mov bh,[byte si+1]              ;BH = width of character
                mov bl,[byte si+2]              ;BL = height of character
                add si,3                        ;skip to start of data
                add si,ax                       ;skip past part off screen
                sub bh,cl                       ;set width to part on screen
                mov cx,bx                       ;store width/height in CH/CL
                jmp @@NextColumn                ;get working

@@NextLetter:   movzx bx,[byte fs:bp]           ;load letter from message
                shl bx,1                        ;*2 = word sized
                jz @@NoErrorQuit                ;quit if we reach a null
                mov [@@Save],si                 ;save font pointer
                add si,[word 3+si+bx]           ;point to spot in font file

                mov ch,[byte si+1]              ;get X size
                mov cl,[byte si+2]              ;get Y size
                jcxz @@SkipChar                 ;skip if character is undefined
                add si,3                        ;point to start of data

@@NextColumn:   mov dx,03C4h                    ;\
                mov ax,[@@PlaneNum]             ; > set the write plane
                out dx,ax                       ;/
                mov dx,di                       ;save video pointer
                mov bx,[@@ColumnNum]            ;\
                shl bx,1                        ; > subtract row offset
                add di,[HeartPath+bx]           ;/
                mov bl,cl                       ;BL = height of character
@@ColumnLoop:   mov al,[byte gs:si]             ;\
                inc si                          ; \
                if TransparentText ne 0         ;  \
                    or al,al                    ;   \
                    jz @@DontPlot               ;    \ draw a single column
                endif                           ;    /
                mov [byte es:di],al             ;   /
@@DontPlot:     add di,[ModeXLogWidth]          ;  /
                dec bl                          ; /
                jnz @@ColumnLoop                ;/

                mov di,dx                       ;restore video pointer
                rol [byte @@PlaneNum+1],1       ;go to next plane
                adc di,0                        ;move to next byte if needed
                inc [@@ColumnNum]               ;go to next column
                cmp [@@ColumnNum],ScreenWidth   ;\ quit if we've filled
                jae @@NoErrorQuit               ;/ the width of the screen
                dec ch                          ;\ loop until all columns in
                jnz @@NextColumn                ;/ character are done
@@SkipChar:     mov si,[@@Save]                 ;restore our font pointer
                inc bp                          ;next letter in message
                jmp @@NextLetter                ;do the next letter

@@NoErrorQuit:  xor ax,ax                       ;signal no error
@@Quit:         pop bp                          ;restore the stack frame
                ret                             ;return
@@ColumnNum     dw ?
@@PlaneNum      dw ?
@@Save          dw ?
ENDP            Draw_String
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
