;----------------------------------------------------------------------
;
; void add_bitmap(X, Y, ScrnOffs, Width, Height, char far *Bitmap)
;
;----------------------------------------------------------------------
proc        add_bitmap
arg         X:word,Y:word,ScrnOffs:word,Width:word,Height:word,Bitmap:dword
            push bp                         ;\ initialize our stack frame
            mov bp,sp                       ;/
            push ds si
            cld                             ;clear the direction flag
            mov es,[VGASeg]                 ;\
            mov ax,[Y]                      ; \
            mul [ModeXLogWidth]             ;  \
            mov di,[ScrnOffs]               ;   \ ES:DI ==> video segment position
            add di,ax                       ;   /
            mov cx,[X]                      ;  /
            shr cx,2                        ; /
            add di,cx                       ;/
            lds si,[Bitmap]                 ;DS:SI ==> Bitmap data
            mov [@@Plane],0                 ;Set plane counter to 0
            mov [@@Source],si               ;\ save our pointers
            mov [@@Target],di               ;/
@@PlaneLoop:mov cl,[@@Plane]                ;\
            mov ah,1                        ; \ send out plane to write to
            shl ah,cl                       ; /
            @Set_Write_Plane                ;/
            mov ah,[@@Plane]                ;\ send out the plane to read from
            @Set_Read_Plane                 ;/
            
            mov si,[@@Source]
            mov di,[@@Target]

            mov dx,[Height]                 ;DX = number of rows in image
@@RowLoop:  mov cx,[Width]                  ;CX = number of columns in image
            dec cx                          ;     minus one
            mov [@@TempRow],di
@@ColLoop:  mov al,[byte ds:si]             ;\
            add si,4                        ; \
            add [byte es:di],al             ;  \ write the pixel
            jnc @@NoCarry                   ;  /
            mov [byte es:di],0FFh           ; /
@@NoCarry:  inc di                          ;/
            sub cx,4                        ;\ do the next column
            jnc @@ColLoop                   ;/
            mov di,[@@TempRow]
            add di,[ModeXLogWidth]
            dec dx                          ;\ do the next row
            jnz @@RowLoop                   ;/
            inc [@@Source]                  ;\
            inc [@@Plane]                   ; \ do the next plane
            cmp [@@Plane],4                 ; /
            jnz @@PlaneLoop                 ;/

            pop si ds
            pop bp                          ;deinitialize the stack frame
            ret                             ;return
@@Plane     db ?
@@Source    dw ?
@@Target    dw ?
@@TempRow   dw ?
endp        add_bitmap


;----------------------------------------------------------------------
;
; void sub_bitmap(X, Y, ScrnOffs, Width, Height, char far *Bitmap)
;
;----------------------------------------------------------------------
proc        sub_bitmap
arg         X:word,Y:word,ScrnOffs:word,Width:word,Height:word,Bitmap:dword
            push bp                         ;\ initialize our stack frame
            mov bp,sp                       ;/
            push ds si
            cld                             ;clear the direction flag
            mov es,[VGASeg]                 ;\
            mov ax,[Y]                      ; \
            mul [ModeXLogWidth]             ;  \
            mov di,[ScrnOffs]               ;   \ ES:DI ==> video segment position
            add di,ax                       ;   /
            mov cx,[X]                      ;  /
            shr cx,2                        ; /
            add di,cx                       ;/
            lds si,[Bitmap]                 ;DS:SI ==> Bitmap data
            mov [@@Plane],0                 ;Set plane counter to 0
            mov [@@Source],si               ;\ save our pointers
            mov [@@Target],di               ;/
@@PlaneLoop:mov cl,[@@Plane]                ;\
            mov ah,1                        ; \ send out plane to write to
            shl ah,cl                       ; /
            @Set_Write_Plane                ;/
            mov ah,[@@Plane]                ;\ send out the plane to read from
            @Set_Read_Plane                 ;/
            
            mov si,[@@Source]
            mov di,[@@Target]

            mov dx,[Height]                 ;DX = number of rows in image
@@RowLoop:  mov cx,[Width]                  ;CX = number of columns in image
            dec cx                          ;     minus one
            mov [@@TempRow],di
@@ColLoop:  mov al,[byte ds:si]             ;\
            add si,4                        ; \ write the pixel
            sub [byte es:di],al             ; /
            jnc @@NoCarry
            mov [byte es:di],0
@@NoCarry:  inc di                          ;/
            sub cx,4                        ;\ do the next column
            jnc @@ColLoop                   ;/
            mov di,[@@TempRow]
            add di,[ModeXLogWidth]
            dec dx                          ;\ do the next row
            jnz @@RowLoop                   ;/
            inc [@@Source]                  ;\
            inc [@@Plane]                   ; \ do the next plane
            cmp [@@Plane],4                 ; /
            jnz @@PlaneLoop                 ;/

            pop si ds
            pop bp                          ;deinitialize the stack frame
            ret                             ;return
@@Plane     db ?
@@Source    dw ?
@@Target    dw ?
@@TempRow   dw ?
endp        sub_bitmap

