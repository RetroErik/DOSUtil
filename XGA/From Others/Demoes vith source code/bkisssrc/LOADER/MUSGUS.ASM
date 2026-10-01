SoundFile       db      'MUSGUS.INF',0      ;filename of the driver to load
Music           dd      0                   ;far ptr to the driver in memory
MusBuf          dd      0                   ;far ptr to the driver's temp buf
MMus            SMus    <>
PM_struc        PM      <>
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc            MUS_GetInfo
                mov bx,9                    ;return status in MMus block
                mov cx,1
                mov si,seg MMus
                mov di,offset MMus
                call [dword cs:Music]
                ret
endp            MUS_GetInfo
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc            MUS_SetInfo
                mov bx,0Ah                  ;update settings from MMus block
                mov si,seg MMus
                mov di,offset MMus
                call [dword cs:Music]
                ret
endp            MUS_SetInfo
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;returns:       CARRY set if error
proc            MUS_LoadSoundDriver
                ;make sure a driver is not loaded yet
                mov ax,[word cs:Music+0]
                or ax,[word cs:Music+2]
                jnz @@Error

                ;reset all of our variables
                mov [cs:@@Handle],0
                mov [cs:@@Segment],0
                mov [cs:@@Segment2],0

                ;open up the file
                push ds
                mov ax,3D00h
                mov dx,cs
                mov ds,dx
                mov dx,offset SoundFile
                int 21h
                pop ds
                jc @@Error
                mov [cs:@@Handle],ax

                ;find the length of the driver
                mov ax,4202h
                mov bx,[cs:@@Handle]
                xor cx,cx
                xor dx,dx
                int 21h
                mov [cs:@@Size],ax

                ;allocate memory for the driver
                mov ah,48h
                mov bx,[cs:@@Size]
                add bx,15
                shr bx,4
                int 21h
                jc @@Error
                mov [cs:@@Segment],ax

                ;allocate 4K for the driver's temporary buffer
                mov ah,48h
                mov bx,(4096/16)
                int 21h
                jc @@Error
                mov [cs:@@Segment2],ax

                ;move the file pointer back to the beginning
                mov ax,4200h
                mov bx,[cs:@@Handle]
                xor cx,cx
                xor dx,dx
                int 21h

                ;read in the driver
                push ds
                mov ah,3Fh
                mov bx,[cs:@@Handle]
                mov cx,[cs:@@Size]
                mov ds,[cs:@@Segment]
                mov dx,0
                int 21h
                pop ds

                ;close the file
                mov ah,3Eh
                mov bx,[cs:@@Handle]
                int 21h

                ;return with success
                mov ax,[cs:@@Segment]
                mov [word cs:Music+2],ax
                mov [word cs:Music+0],0
                mov ax,[cs:@@Segment2]
                mov [word cs:MusBuf+2],ax
                mov [word cs:MusBuf+0],0
                clc
                ret

@@Error:        cmp [cs:@@Handle],0
                jz @@Error1
                mov ah,3Eh
                mov bx,[cs:@@Handle]
                int 21h
@@Error1:       cmp [cs:@@Segment],0
                jz @@Error2
                push es
                mov ah,49h
                mov es,[cs:@@Segment]
                int 21h
                pop es
@@Error2:       cmp [cs:@@Segment2],0
                jz @@Error3
                push es
                mov ah,49h
                mov es,[cs:@@Segment2]
                int 21h
                pop es
@@Error3:       stc
                ret
@@Handle        dw      0
@@Segment       dw      0
@@Segment2      dw      0
@@Size          dw      0
endp            MUS_LoadSoundDriver
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;returns:       CARRY set on error
proc            MUS_FreeSoundDriver
                ;make sure a driver is loaded first
                mov ax,[word cs:Music+0]
                or ax,[word cs:Music+2]
                jz @@Error

                ;stop playing (if it is)
                mov bx,5                    ;stop playing
                call [dword ptr cs:Music]

                ;deinitialize the driver
                mov bx,1                    ;close down player
                call [dword ptr cs:Music]

                ;free the memory associated with the driver
                push es
                mov ah,49h
                mov es,[word cs:Music+2]
                int 21h
                pop es
                mov [word cs:Music+0],0
                mov [word cs:Music+2],0

                ;free the memory associated with the driver's temp buffer
                push es
                mov ah,49h
                mov es,[word cs:MusBuf+2]
                int 21h
                pop es
                mov [word cs:MusBuf+2],0
                mov [word cs:MusBuf+0],0

                ;return with success
                clc
                ret

@@Error:        ;return with error
                stc
                ret
endp            MUS_FreeSoundDriver
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
