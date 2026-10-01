;this is for the assembly version of the library interface.
;
;Note:  This requires you to be using TASM in IDEAL mode and to 'INCLUDE'
;this module in your code.  It also requires TASM to be in 386 compilation
;mode.  (These restrictions exist because this module is originally from
;my game that I'm working on)

;_jlib_open_library
;_jlib_close_library
;_jlib_open_file
;_jlib_close_file
;_jlib_ftell
;_jlib_filelength
;_jlib_fseek
;_jlib_read_file

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

MAJORVER = 1                        ;\
MINORVER = 3                        ; > file format version 1.3
VERSION_ID = MINORVER*256+MAJORVER  ;/
MAXFILES = 100                      ;maximum number of files allowed in library
SLIDINGREQUEST = 0                  ;set to 1 to enable to do sliding requests

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
STRUC       LibFile
            Fileattr    DB 0
            Filetime    DW 0
            Filedate    DW 0
            Filesize    DD 0
            Filename    DB 13 DUP (0)
            Fileoffset  DD 0
            CurPos      DD 0              ;\ not stored in file
            Opened      DB 0              ;/
ENDS        LibFile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
MACRO       MAKEUPPERCASE LETTER
            LOCAL @@NotLower
            cmp LETTER,'a'
            jb @@NotLower
            cmp LETTER,'z'
            ja @@NotLower
            sub LETTER,'a'-'A'
@@NotLower:
ENDM        MAKEUPPERCASE
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
LibHandle   DW -1                         ;handle for library
NumFiles    DW 0                          ;number of files in library
FileStats   LibFile MAXFILES DUP (<>)     ;file info structures of each file
Wildcard    DB 13 DUP (0)                 ;\   last defined wildcard
MasterAttr  DW 0                          ; \  original search attribute
HandleNext  DB 0                          ;  > if next FindNext should be done
LastMatch   DW 0                          ; /  number of last match
MasterWild  DB 80 DUP (0)                 ;/   original search wildcard
TempBuffer  DB 13 DUP (0)                 ;temporary I/O buffer
HeaderOffset DD 0                         ;offset to start of JLIB file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Sets the library that will be used for all subsequent JLIB file I/O accesses.
;
;           ES:DI ==> filename
;returns:   CARRY set on error
;
PROC        _jlib_open_library
            cmp [LibHandle],-1                  ;is a library already loaded?
            jnz @@Error                         ;  yes -- return error

            ;*** Reading of the JLIB file header ***
            push ds                             ;\
            mov ax,3D00h                        ; \
            mov dx,es                           ;  \
            mov ds,dx                           ;   \
            mov dx,di                           ;    > try to open the library
            int 21h                             ;   /
            pop ds                              ;  /
            jc @@Error                          ; /
            mov [LibHandle],ax                  ;/
;-------- 1.3 changes start here
            mov ax,-4                           ;\
            cwd                                 ; \
            mov cx,dx                           ;  \
            mov dx,ax                           ;   > seek to 4 bytes before end
            mov ax,4202h                        ;  /
            mov bx,[LibHandle]                  ; /
            int 21h                             ;/
            mov ah,3Fh                          ;\
            mov bx,[LibHandle]                  ; \
            mov cx,4                            ;  > read in the offset to start
            mov dx,offset HeaderOffset          ; /
            int 21h                             ;/
            mov ax,4202h                        ;\
            mov bx,[LibHandle]                  ; \
            xor cx,cx                           ;  > find out length of total file
            xor dx,dx                           ; /
            int 21h                             ;/
            sub ax,[word HeaderOffset+0]        ;\
            sbb dx,[word HeaderOffset+2]        ; \ compute offset to start of JLIB
            mov [word HeaderOffset+0],ax        ; /
            mov [word HeaderOffset+2],dx        ;/
            mov ax,4200h                        ;\
            mov bx,[LibHandle]                  ; \
            mov cx,[word HeaderOffset+2]        ;  > seek to start of JLIB
            mov dx,[word HeaderOffset+0]        ; /
            int 21h                             ;/
;-------- 1.3 changes end here
            mov ah,3Fh                          ;\
            mov bx,[LibHandle]                  ; \
            mov cx,8                            ;  \ read in signature and
            mov dx,offset TempBuffer            ;  / file version number
            int 21h                             ; /
            jc @@Error                          ;/
            cmp [dword TempBuffer+0],'biLJ'     ;\
            jnz @@Error                         ; \ check the signarure and
            cmp [word TempBuffer+4],VERSION_ID  ; / file version number
            jnz @@Error                         ;/
            mov cx,[word TempBuffer+6]          ;\
            cmp cx,MAXFILES                     ; \ check the number of files
            ja @@Error                          ; /
            mov [NumFiles],cx                   ;/
            mov ah,3Fh                          ;\
            mov bx,[LibHandle]                  ; \
            mov cx,4                            ;  \ read in the offset to
            mov dx,offset TempBuffer            ;  / the directory structures
            int 21h                             ; /
            jc @@Error                          ;/
            mov ax,4200h                        ;\
            mov bx,[LibHandle]                  ; \
            mov cx,[word TempBuffer+2]          ;  \ seek to the start of the
            mov dx,[word TempBuffer+0]          ;  / directory structures
;-------- 1.3 changes start here
            add dx,[word HeaderOffset+0]
            adc cx,[word HeaderOffset+2]
;-------- 1.3 changes end here
            int 21h                             ; /
            jc @@Error                          ;/
            mov cx,[NumFiles]                   ;\
            mov dx,offset FileStats             ; \
@@Read:     push cx dx                          ;  \
            mov ah,3Fh                          ;   |
            mov bx,[LibHandle]                  ;   |
            mov cx,size LibFile-5               ;   | read in the directory
            int 21h                             ;   | information for each file
            jc @@Error                          ;   |
            pop dx cx                           ;   |
            mov si,dx                           ;   |
            mov [si+LibFile.Opened],0           ;  /
            add dx,size LibFile                 ; /
            loop @@Read                         ;/
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    cmp [LibHandle],-1                  ;do we need to close the file?
            jz @@Error2                         ;  no -- then don't
            mov ah,3Eh                          ;\
            mov bx,[LibHandle]                  ; \ close the library file
            int 21h                             ; /
            mov [LibHandle],-1                  ;/
@@Error2:   stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_open_library
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Closes the current library file
;
;returns:   CARRY set if no library open
;
PROC        _jlib_close_library
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- don't need to close it
            mov ah,3Eh                          ;\
            mov bx,[LibHandle]                  ; \ close the library file
            int 21h                             ; /
            mov [LibHandle],-1                  ;/
            clc                                 ;\ return with success
            ret                                 ;/
@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_close_library
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Opens a file that is stored in the library file for read-only access
;
;           ES:DI ==> ASCIIZ filename to open
;returns:   CARRY set on error
;           AX = file handle (on success)
;
PROC        _jlib_open_file
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error

            mov si,offset TempBuffer            ;\
            call FixFileName                    ; > parse the filename from
            jc @@Error                          ;/  from ES:DI to tempbuffer
            mov ax,cs                           ;\
            mov es,ax                           ; \
            mov di,offset TempBuffer            ;  > match the filename
            call MatchFile                      ; /
            jc @@Error                          ;/

            cmp [si+LibFile.Opened],0           ;is the file already "opened"?
            jnz @@Error                         ;  yes -- return error
            mov [si+LibFile.Opened],1           ;say the file is now opened
            mov [si+LibFile.CurPos],0           ;move file pointer to start
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_open_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Closes the file associated with the specified handle
;
;           BX = file handle
;returns:   CARRY set on error
;
PROC        _jlib_close_file
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error
            cmp bx,[NumFiles]                   ;is the handle out of range?
            jae @@Error                         ;  yes -- return error
            mov ax,size LibFile                 ;\
            mul bx                              ; \ DS:SI ==> file information
            mov si,offset FileStats             ; /
            add si,ax                           ;/
            cmp [si+LibFile.Opened],0           ;is the file opened yet?
            jz @@Error                          ;  no -- return error

            mov [si+LibFile.Opened],0           ;close the file
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_close_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Returns file pointer position on success
;
;           BX = file handle
;returns:   CARRY set on error
;           EAX = file position (on success)
;
PROC        _jlib_ftell
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error
            cmp bx,[NumFiles]                   ;is the handle out of range?
            jae @@Error                         ;  yes -- return error
            mov ax,size LibFile                 ;\
            mul bx                              ; \ DS:SI ==> file information
            mov si,offset FileStats             ; /
            add si,ax                           ;/
            cmp [si+LibFile.Opened],0           ;is the file opened yet?
            jz @@Error                          ;  no -- return error

            mov eax,[si+LibFile.CurPos]         ;EAX = current position
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_ftell
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Returns the length of the file associated with the specified handle
;
;           BX = file handle
;returns:   CARRY set on error
;           EAX = file length (on success)
;
PROC        _jlib_filelength
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error
            cmp bx,[NumFiles]                   ;is the handle out of range?
            jae @@Error                         ;  yes -- return error
            mov ax,size LibFile                 ;\
            mul bx                              ; \ DS:SI ==> file information
            mov si,offset FileStats             ; /
            add si,ax                           ;/
            cmp [si+LibFile.Opened],0           ;is the file opened yet?
            jz @@Error                          ;  no -- return error

            mov eax,[si+LibFile.Filesize]       ;EAX = file size
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_filelength
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;Moves the file pointer according to the position and method code
;
;           BX = file handle
;           CL = method code (0 = start, 1 = current, 2 = end)
;           EAX = offset
;return:    CARRY set on error
;           EAX = current position (on success)
;
PROC        _jlib_fseek
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error
            cmp bx,[NumFiles]                   ;is the handle out of range?
            jae @@Error                         ;  yes -- return error
            push eax                            ;\
            mov ax,size LibFile                 ; \
            mul bx                              ;  \ DS:SI ==> file information
            mov si,offset FileStats             ;  /
            add si,ax                           ; /
            pop eax                             ;/
            cmp [si+LibFile.Opened],0           ;is the file opened yet?
            jz @@Error                          ;  no -- return error

@@Method0:  cmp cl,0                            ;\ mode 0: offset from start
            jz @@CheckPos                       ;/
@@Method1:  cmp cl,1                            ;\
            jnz @@Method2                       ; \
            add eax,[si+LibFile.CurPos]         ;  > mode 1: current offset
            jc @@Error                          ; /  current position
            jmp @@CheckPos                      ;/
@@Method2:  cmp cl,2                            ;\
            jnz @@Error                         ; \ mode 2: offset from end
            add eax,[si+LibFile.Filesize]       ; /
            jc @@Error                          ;/

@@CheckPos: cmp eax,[si+LibFile.Filesize]       ;\ make sure we'll not be past
            ja @@Error                          ;/ the 'end' of the 'file'
            mov [si+LibFile.CurPos],eax         ;save the new position
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_fseek
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;reads a block of count bytes from the file specified by the handle into the
;specified buffer
;
;note:  If 'SLIDINGREQUEST' is nonzero and a value of 'count' is passed that
;       will go past the end of the logical end of file, it will be forced
;       down to the maximum number that will not go past the end.  If it is
;       not defined, then requests that would go past the end will be rejected
;       and an error will be returned
;
;           BX = file handle
;           CX = number of bytes to read
;           ES:DI ==> buffer
;returns:   CARRY set on error
;           CX = number of bytes read (on success)
;
PROC        _jlib_read_file
            cmp [LibHandle],-1                  ;is a library already loaded?
            jz @@Error                          ;  no -- return error
            cmp bx,[NumFiles]                   ;is the handle out of range?
            jae @@Error                         ;  yes -- return error
            mov ax,size LibFile                 ;\
            mul bx                              ; \ DS:SI ==> file information
            mov si,offset FileStats             ; /
            add si,ax                           ;/
            cmp [si+LibFile.Opened],0           ;is the file opened yet?
            jz @@Error                          ;  no -- return error

            push cx                             ;\
            mov ax,4200h                        ; \
            mov bx,[LibHandle]                  ;  \
            mov ecx,[si+LibFile.Fileoffset]     ;   \
            add ecx,[si+LibFile.CurPos]         ;    \ seek to where we're
;-------- 1.3 changes start here
            add ecx,[HeaderOffset]
;-------- 1.3 changes end here
            mov dx,cx                           ;    / supposed to be
            shr ecx,16                          ;   /
            int 21h                             ;  /
            pop cx                              ; /
            jc @@Error                          ;/

            mov eax,[si+LibFile.Filesize]       ;\
            sub eax,[si+LibFile.CurPos]         ; \
            and ecx,0000FFFFh                   ;  |
            cmp ecx,eax                         ;  | figure out the maximum
            jbe @@Okay                          ;  | number of bytes that
IF SLIDINGREQUEST ne 0                          ;  | could be read and check
            mov ecx,eax                         ;  | the request against it
ELSE                                            ;  |
            jmp @@Error                         ; /
ENDIF                                           ;/

@@Okay:     push ds                             ;\
            mov ah,3Fh                          ; \
            mov bx,[LibHandle]                  ;  \
            mov dx,es                           ;   \
            mov ds,dx                           ;    > actually do the read
            mov dx,di                           ;   /
            int 21h                             ;  /
            pop ds                              ; /
            jc @@Error                          ;/
            mov di,ax                           ;DI = number of bytes read

            mov ax,4201h                        ;\
            mov bx,[LibHandle]                  ; \
            xor cx,cx                           ;  \
            xor dx,dx                           ;   \
            int 21h                             ;    \ find out where we
            jc @@Error                          ;    / are now and save it
            shl edx,16                          ;   /
            mov dx,ax                           ;  /
            sub edx,[si+LibFile.Fileoffset]     ; /
;-------- 1.3 changes start here
            sub edx,[HeaderOffset]
;-------- 1.3 changes end here

            mov [si+LibFile.CurPos],edx         ;/

            mov ax,di                           ;AX = number of bytes read
            clc                                 ;\ return with success
            ret                                 ;/

@@Error:    stc                                 ;\ return with error
            ret                                 ;/
ENDP        _jlib_read_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;capitalize filename, make sure there's a period, only allow 8 characters
;for the base name and 3 characters for the extension, doesn't allow
;characters after an asterick
;
;           ES:DI ==> ASCIIZ filename to parse
;           DS:SI ==> buffer to store parsed filename
;
;returns:   CARRY set if no filename passed (null name)
;
PROC        FixFileName
            push si di ax bx dx              ;save what we'll modify
            mov dx,di                        ;ES:DX ==> first byte of filename
            cmp [byte es:di],0               ;\ quit with error, if there's
            jz @@Error                       ;/ nothing given to us
@@FindEnd:  inc di                           ;\
            cmp [byte es:di],0               ; > seek to the end of the name
            jnz @@FindEnd                    ;/
@@FindStart:mov al,[byte es:di]              ;\
            dec di                           ; \
            cmp di,dx                        ;  \
            jz @@GotStart                    ;   | seek back to
            cmp al,'\'                       ;   | the start of
            jz @@IncOne                      ;   | the base name
            cmp al,':'                       ;  /
            jnz @@FindStart                  ; /
@@IncOne:   add di,2                         ;/
@@GotStart: mov ah,8                         ;only copy 8 bytes for the base
@@Basename: mov al,[byte es:di]              ;\
            or al,al                         ; \ load a byte, handling it
            jz @@AddDot                      ; / if it's a NULL
            inc di                           ;/
            cmp al,'.'                       ;if we've found a period, start
            jz @@AddDot                      ;  working on the extension
            MAKEUPPERCASE al                 ;\
            mov [byte ds:si],al              ; > make uppercase and store
            inc si                           ;/
            cmp al,'*'                       ;if we've found an asterick, then
            jz @@Ignore                      ;  ignore all up to period or end
            dec ah                           ;\ only copy 8 characters
            jnz @@Basename                   ;/
@@Ignore:   mov al,[byte es:di]              ;\
            or al,al                         ; \
            jz @@AddDot                      ;  \ skip until a NULL or a
            inc di                           ;  / period is encountered
            cmp al,'.'                       ; /
            jnz @@Ignore                     ;/
@@AddDot:   mov [byte ds:si],'.'             ;\ tack on a period
            inc si                           ;/
            mov ah,3                         ;only copy 3 bytes for the ext
@@Extension:mov al,[byte es:di]              ;\
            inc di                           ; \ load a byte and handle
            or al,al                         ; / it if it's a NULL
            jz @@Done                        ;/
            MAKEUPPERCASE al                 ;\
            mov [byte ds:si],al              ; > make uppercase and store it
            inc si                           ;/
            cmp al,'*'                       ;\ if we copied a '*', then there
            jz @@Done                        ;/ shouldn't be anything after it
            dec ah                           ;\ only copy 3 characters
            jnz @@Extension                  ;/
@@Done:     mov [byte ds:si],0               ;terminate it with a NULL
            clc                              ;signal success (CF = 0)
            jmp @@Quit                       ;
@@Error:    stc                              ;signal error (CF = 1)
@@Quit:     pop dx bx ax di si               ;restore everything
            ret                              ;return
ENDP        FixFileName
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;locates a file structure that matches identically to a specified file
;
;           ES:DI ==> ASCIIZ filename to match
;returns:   DS:SI ==> appropiate structure
;           AX = file number (0 based)
;           carry set if not found
;
PROC        MatchFile
            push bx cx dx
            mov si,offset FileStats          ;SI ==> File structures
            mov cx,[NumFiles]                ;CX = number of files to search
            xor ax,ax                        ;current file number
@@NewFile:  xor bx,bx
@@Compare:  mov dl,[byte ds:si+bx+LibFile.Filename]
            or dl,dl
            jz @@GotIt
            cmp dl,[byte es:di+bx]
            jnz @@Next
            inc bx
            jmp @@Compare
@@Next:     add si,size LibFile
            inc ax
            loop @@NewFile
            stc                              ;signal error (CF = 1)
            jmp @@Quit
@@GotIt:    clc                              ;signal success (CF = 0)
@@Quit:     pop dx cx bx
            ret
ENDP        MatchFile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
