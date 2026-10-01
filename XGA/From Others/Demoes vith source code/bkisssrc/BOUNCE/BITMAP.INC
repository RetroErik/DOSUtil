;----------------------------------------------------------------------
; put_masked_pbm - write a bitmap from system ram to video ram all zero
; source bitmap bytes indicate destination byte to be left unchanged
;
; void put_masked_bitmap(X, Y, ScrnOffs, Width, Height, char far *Bitmap)
;
;----------------------------------------------------------------------
proc        put_masked_bitmap
arg         X:word,Y:word,ScrnOffs:word,Width:word,Height:word,Bitmap:dword
            push bp                         ;\
;            sub sp,2                        ; > initialize our stack frame
            mov bp,sp                       ;/
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
            mov ah,1                        ; \ send out plane to access
            shl ah,cl                       ; /
            @Set_Write_Plane                ;/
            mov si,[@@Source]
            mov di,[@@Target]

            mov dx,[Height]                 ;DX = number of rows in image
@@RowLoop:  mov cx,[Width]                  ;CX = number of columns in image
            dec cx                          ;     minus one
            mov [@@TempRow],di
@@ColLoop:  mov al,[byte ds:si]             ;\
            add si,4                        ; \
            or al,al                        ;  \ display a pixel
            jz @@NoPixel                    ;  /
            mov [byte es:di],al             ; /
@@NoPixel:  inc di                          ;/
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

;            add sp,2                        ;\ deinitialize the stack frame
            pop bp                          ;/
            ret                             ;return
@@Plane     db ?
@@Source    dw ?
@@Target    dw ?
@@TempRow   dw ?
endp        put_masked_bitmap
