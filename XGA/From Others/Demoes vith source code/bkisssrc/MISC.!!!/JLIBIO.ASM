;this is for the C-version of the library interface

LOCALS
JUMPS
.286

IFDEF s
  DISPLAY "JLBIO Small Model"
  .model small
ELSE
  IFDEF c
    DISPLAY "JLIBIO Compact Model"
    .model compact
  ELSE
     IFDEF l
       DISPLAY "JLIBIO Large Model"
      .model large
     ELSE
       DISPLAY "WARNING: Model was not defined at the command line."
       DISPLAY "         Include in TASM commandline either:  /ds, /dc, or /dl"
       DISPLAY "         Using default small model. ie:  /ds"
       .model small
      ENDIF
  ENDIF
ENDIF

public _jlib_open_library
public _jlib_close_library
public _jlib_open_file
public _jlib_close_file
public _jlib_ftell
public _jlib_filelength
public _jlib_fseek
public _jlib_read_file

MAJORVER = 1         ;\ file format version 1.3
MINORVER = 3         ;/
MAXFILES = 50        ;maximum number of files allowed in library
SLIDINGREQUEST = 0   ;enable this to allow sliding requests (see read_file)


;structures
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
LibFile        STRUC
               Fileattr    DB 0
               Filetime    DW 0
               Filedate    DW 0
               Filesize    DD 0
               Filename    DB 13 DUP (0)
               Fileoffset  DD 0
               CurPos      DD 0              ;\ not stored in file
               Opened      DB 0              ;/
LibFile        ENDS


;macros
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
MAKEUPPERCASE  macro LETTER
               LOCAL @@NotLower
               cmp LETTER,'a'
               jb @@NotLower
               cmp LETTER,'z'
               ja @@NotLower
               sub LETTER,'a'-'A'
@@NotLower:    endm


.data
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
LibHandle   DW -1                       ;handle for library
NumFiles    DW 0                        ;number of files in library
FileStats   LibFile MAXFILES DUP (<>)   ;file info structures of each file
Wildcard    DB 13 DUP (0)               ;\   last defined wildcard
MasterAttr  DW 0                        ; \  original search attribute
HandleNext  DB 0                        ;  > if next FindNext should be done
LastMatch   DW 0                        ; /  number of last match
MasterWild  DB 80 DUP (0)               ;/   original search wildcard
TempBuffer  DB 13 DUP (0)               ;temporary I/O buffer
HeaderOffset DD 0                       ;offset to start of JLIB file


.code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;capitalize filename, make sure there's a period, only allow 8 characters
;for the base name and 3 characters for the extension, doesn't allow
;characters after an asterick
;
;           DS:SI ==> ASCIIZ filename to parse
;           ES:DI ==> buffer to store parsed filename
;
;returns:   ZF set if no filename passed (null name)
;
PROC        FixFileName
            push si di ax bx dx              ;save what we'll modify
            mov dx,si                        ;DS:DX ==> first byte of filename
            cmp byte ptr ds:[si],0           ;\ quit with ZF set, if there's
            jz @@Quit                        ;/ nothing given to us
@@FindEnd:  inc si                           ;\
            cmp byte ptr ds:[si],0           ; > seek to the end of the name
            jnz @@FindEnd                    ;/
            std                              ;\
@@FindStart:lodsb                            ; \
            cmp si,dx                        ;  \
            jz @@GotStart                    ;   | seek back to
            cmp al,'\'                       ;   | the start of
            jz @@IncOne                      ;   | the base name
            cmp al,':'                       ;  /
            jnz @@FindStart                  ; /
@@IncOne:   add si,2                         ;/
@@GotStart: cld                              ;go forward, now
            mov ah,8                         ;only copy 8 bytes for the base
@@Basename: mov al,byte ptr ds:[si]          ;\
            or al,al                         ; \ load a byte, handling it
            jz @@AddDot                      ; / if it's a NULL
            inc si                           ;/
            cmp al,'.'                       ;if we've found a period, start
            jz @@AddDot                      ;  working on the extension
            MAKEUPPERCASE al                 ;\
            mov byte ptr es:[di],al          ; > make uppercase and store
            inc di                           ;/
            cmp al,'*'                       ;if we've found an asterick, then
            jz @@Ignore                      ;  ignore all up to period or end
            dec ah                           ;\ only copy 8 characters
            jnz @@Basename                   ;/
@@Ignore:   mov al,byte ptr ds:[si]          ;\
            or al,al                         ; \
            jz @@AddDot                      ;  \ skip until a NULL or a
            inc si                           ;  / period is encountered
            cmp al,'.'                       ; /
            jnz @@Ignore                     ;/
@@AddDot:   mov byte ptr es:[di],'.'         ;\ tack on a period
            inc di                           ;/
            mov ah,3                         ;only copy 3 bytes for the ext
@@Extension:lodsb                            ;\  load a byte and handle
            or al,al                         ; > it if it's a NULL
            jz @@Done                        ;/
            MAKEUPPERCASE al                 ;\
            mov byte ptr es:[di],al          ; > make uppercase and store it
            inc di                           ;/
            cmp al,'*'                       ;\ if we copied a '*', then there
            jz @@Done                        ;/ shouldn't be anything after it
            dec ah                           ;\ only copy 3 characters
            jnz @@Extension                  ;/
@@Done:     mov byte ptr es:[di],0           ;\ terminate it with a NULL
            or al,1               ;clear ZF  ;/
@@Quit:     pop dx bx ax di si               ;restore everything
            ret                              ;return
ENDP        FixFileName
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;locates a file structure that matches identically to a specified file
;
;           ES:DI ==> ASCIIZ filename to match
;
;returns:   DS:SI ==> appropiate structure
;           AX = file number (0 based)
;           carry set if not found
;
PROC        MatchFile
            push bx cx dx
            mov ax,seg FileStats             ;\
            mov ds,ax                        ; > DS:SI ==> File structures
            mov si,offset FileStats          ;/
            mov cx,[NumFiles]                ;CX = number of files to search
            xor ax,ax                        ;current file number
@@NewFile:  xor bx,bx
@@Compare:  mov dl,byte ptr ds:[si+bx].Filename
            or dl,dl
            jz @@GotIt
            cmp dl,byte ptr es:[di+bx]
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
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;     extern int jlib_open_library (char far *file)
;
;Sets the library that will be used for all subsequent JLIB file I/O accesses.
;This procedure will close previous library, if one is still loaded.
;
;returns:   0 = success
;           -1 = error
;
PROC        _jlib_open_library
            ARG file:dword
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di ds                    ;save what we'll modify

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@LoadIt                      ;  no -- don't need to close it
            mov ah,3Eh                       ;\
            mov bx,[LibHandle]               ; \ close the library file
            int 21h                          ; /
            mov [LibHandle],-1               ;/

            ;*** Reading of the JLIB file header ***
@@LoadIt:   push ds                          ;\
            mov ax,3D00h                     ; \
            lds dx,[file]                    ;  \
            int 21h                          ;   > try to open the library
            pop ds                           ;  /
            jc @@Error                       ; /
            mov [LibHandle],ax               ;/
;-------- 1.3 changes start here
            mov ax,-4                        ;\
            cwd                              ; \
            mov cx,dx                        ;  \
            mov dx,ax                        ;   > seek to 4 bytes before end
            mov ax,4202h                     ;  /
            mov bx,[LibHandle]               ; /
            int 21h                          ;/
            mov ah,3Fh                       ;\
            mov bx,[LibHandle]               ; \
            mov cx,4                         ;  > read in the offset to start
            mov dx,offset HeaderOffset       ; /
            int 21h                          ;/
            mov ax,4202h                     ;\
            mov bx,[LibHandle]               ; \
            xor cx,cx                        ;  > find out length of total file
            xor dx,dx                        ; /
            int 21h                          ;/
            sub ax,word ptr [HeaderOffset+0] ;\
            sbb dx,word ptr [HeaderOffset+2] ; \ compute offset to start of JLIB
            mov word ptr [HeaderOffset+0],ax ; /
            mov word ptr [HeaderOffset+2],dx ;/
            mov ax,4200h                     ;\
            mov bx,[LibHandle]               ; \
            mov cx,word ptr [HeaderOffset+2] ;  > seek to start of JLIB
            mov dx,word ptr [HeaderOffset+0] ; /
            int 21h                          ;/
;-------- 1.3 changes end here
            mov ah,3Fh                       ;\
            mov bx,[LibHandle]               ; \
            mov cx,6                         ;  \ read in signature and
            mov dx,offset TempBuffer         ;  / file version number
            int 21h                          ; /
            jc @@Error                       ;/
            cmp word ptr [TempBuffer],'LJ'   ;\
            jnz @@Error                      ; \
            cmp word ptr [TempBuffer+2],'bi' ;  \ check the signarure and
            jnz @@Error                      ;  / file version number
            cmp word ptr [TempBuffer+4],MINORVER*256+MAJORVER
            jnz @@Error                      ;/
            mov ah,3Fh                       ;\
            mov bx,[LibHandle]               ; \
            mov cx,2                         ;  \ read in number of files
            mov dx,offset NumFiles           ;  / contained in the library
            int 21h                          ; /
            jc @@Error                       ;/
            mov cx,[NumFiles]                ;\
            cmp cx,MAXFILES                  ; > check the limit of files
            ja @@Error                       ;/
            mov ah,3Fh                       ;\
            mov bx,[LibHandle]               ; \
            mov cx,4                         ;  \ read in the offset to
            mov dx,offset TempBuffer         ;  / the directory structures
            int 21h                          ; /
            jc @@Error                       ;/
            mov ax,4200h                     ;\
            mov bx,[LibHandle]               ; \
            mov cx,word ptr [TempBuffer+2]   ;  \ seek to the start of the
            mov dx,word ptr [TempBuffer+0]   ;  / directory structures
;-------- 1.3 changes start here
            add dx,word ptr [HeaderOffset+0]
            adc cx,word ptr [HeaderOffset+2]
;-------- 1.3 changes end here
            int 21h                          ; /
            jc @@Error                       ;/
            mov cx,[NumFiles]                ;\
            mov dx,offset FileStats          ; \
@@Read:     push cx dx                       ;  \
            mov ah,3Fh                       ;   |
            mov bx,[LibHandle]               ;   |
            mov cx,size LibFile-5            ;   | read in the directory
            int 21h                          ;   | information for each file
            jb @@Error                       ;   |
            pop dx cx                        ;   |
            mov si,dx                        ;   |
            mov ds:[si].Opened,0             ;  /
            add dx,size LibFile              ; /
            loop @@Read                      ;/

            xor ax,ax                        ;indicate success
            jmp @@Done                       ;return back to main program
@@Error:    cmp [LibHandle],-1               ;do we need to close the library?
            jz @@Error2                      ;  no -- then don't
            mov ah,3Eh                       ;\
            mov bx,[LibHandle]               ; \ close the library file
            int 21h                          ; /
            mov [LibHandle],-1               ;/
@@Error2:   mov ax,-1                        ;indicate failure
@@Done:     pop ds di si bp                  ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_open_library
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;     extern int jlib_close_library (void)
;
; Closes the current library file
;
; Returns 0 on success, -1 on failure
;
PROC        _jlib_close_library
            push si di                       ;save what we'll modify
            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- don't need to close it
            mov ah,3Eh                       ;\
            mov bx,[LibHandle]               ; \ close the library file
            int 21h                          ; /
            mov [LibHandle],-1               ;/
            xor ax,ax                        ;indicate success
            jmp short @@Done                 ;return
@@Error:    mov ax,-1                        ;indicate error
@@Done:     pop di si                        ;restore what we saved
            ret                              ;return
ENDP        _jlib_close_library
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;     extern int jlib_open_file (char far *file)
;
; Opens a file that is stored in the library file for read-only
; access
;
; Returns file handle on success, -1 on failure
;
PROC        _jlib_open_file
            ARG file:dword
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di ds                    ;save what we'll modify

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error

            lds si,[file]                    ;DS:SI ==> source filename
            mov ax,@data                     ;\
            mov es,ax                        ; > ES:DI ==> target buffer
            mov di,offset TempBuffer         ;/
            call FixFileName                 ;parse the filename
            jz @@Error                       ;if nothing passed, return error
            call MatchFile                   ;match the filename
            jc @@Error                       ;if nothing matched, return error

            pop ds
            push ds
            cmp [si].Opened,0                ;is the file already "opened"?
            jnz @@Error                      ;  yes -- return error
            mov [si].Opened,1                ;say the file is now opened
            mov word ptr [si+0].CurPos,0     ;\ move the file position to
            mov word ptr [si+2].CurPos,0     ;/ the beginning of the file
            jmp @@Quit                       ;return

@@Error:    mov ax,-1                        ;indicate error
@@Quit:     pop ds di si bp                  ;restore the caller's stack frame
            ret                              ;return
ENDP        _jlib_open_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;   extern long jlib_close_file (int handle)
;
; Closes the file associated with the specified handle
;
; Returns 0 on success, -1 on failure
;
PROC        _jlib_close_file
ARG         handle:word
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di                       ;save SI and DI, too

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error
            mov ax,[NumFiles]                ;\
            cmp [handle],ax                  ; > if the handle is out of range
            jae @@Error                      ;/  then return an error
            mov ax,size LibFile              ;\
            mul [handle]                     ; \ DS:SI ==> file information
            mov si,offset FileStats          ; /
            add si,ax                        ;/
            cmp ds:[si].Opened,0             ;is the file opened yet?
            jz @@Error                       ;  no -- return error

            mov ds:[si].Opened,0             ;close the file
            jmp @@Done                       ;return

@@Error:    mov ax,-1                        ;\ indicate error
@@Done:     pop di si bp                     ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_close_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;   extern long jlib_ftell (int handle)
;
; Returns file pointer position on success, -1 on failure
;
PROC        _jlib_ftell
ARG         handle:word
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di                       ;save SI and DI, too

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error
            mov ax,[NumFiles]                ;\
            cmp [handle],ax                  ; > if the handle is out of range
            jae @@Error                      ;/  then return an error
            mov ax,size LibFile              ;\
            mul [handle]                     ; \ DS:SI ==> file information
            mov si,offset FileStats          ; /
            add si,ax                        ;/
            cmp ds:[si].Opened,0             ;is the file opened yet?
            jz @@Error                       ;  no -- return error

            mov ax,word ptr [si+0].CurPos    ;\ DX:AX ==> current position
            mov dx,word ptr [si+2].CurPos    ;/
            jmp @@Done                       ;return

@@Error:    mov ax,-1                        ;\ indicate error
            mov dx,-1                        ;/
@@Done:     pop di si bp                     ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_ftell
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;   extern long jlib_filelength (int handle)
;
; Returns the length of the file associated with the specified handle
;
; Returns file length on success, -1 on failure
;
PROC        _jlib_filelength
ARG         handle:word
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di                       ;save SI and DI, too

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error
            mov ax,[NumFiles]                ;\
            cmp [handle],ax                  ; > if the handle is out of range
            jae @@Error                      ;/  then return an error
            mov ax,size LibFile              ;\
            mul [handle]                     ; \ DS:SI ==> file information
            mov si,offset FileStats          ; /
            add si,ax                        ;/
            cmp ds:[si].Opened,0             ;is the file opened yet?
            jz @@Error                       ;  no -- return error

            mov ax,word ptr [si+0].Filesize  ;\ DX:AX ==> current position
            mov dx,word ptr [si+2].Filesize  ;/
            jmp @@Done                       ;return

@@Error:    mov ax,-1                        ;\ indicate error
            mov dx,-1                        ;/
@@Done:     pop di si bp                     ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_filelength
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;   extern long jlib_fseek (int handle, long position, char method_code)
;
; Moves the file pointer according to the position and method code
;
; Returns file pointer position on success, -1 on failure
;
PROC        _jlib_fseek
ARG         handle:word,position:dword,method_code:byte
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP insead of SP
            push si di                       ;save SI and DI, too

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error
            mov ax,[NumFiles]                ;\
            cmp [handle],ax                  ; > if the handle is out of range
            jae @@Error                      ;/  then return an error
            mov ax,size LibFile              ;\
            mul [handle]                     ; \ DS:SI ==> file information
            mov si,offset FileStats          ; /
            add si,ax                        ;/
            cmp ds:[si].Opened,0             ;is the file opened yet?
            jz @@Error                       ;  no -- return error

            cmp al,0                         ;\
            jnz @@Method1                    ; \
@@Method0:  xor ax,ax                        ;  > mode 0: start from beginning
            xor dx,dx                        ; /
            jmp @@AddOffset                  ;/
@@Method1:  cmp al,1                         ;\
            jnz @@Method2                    ; \
            mov ax,word ptr [si+0].CurPos    ;  > mode 1: start from location
            mov dx,word ptr [si+2].CurPos    ; /
            jmp @@AddOffset                  ;/
@@Method2:  cmp al,2                         ;\
            jnz @@Error                      ; \ mode 2: start from end
            mov ax,word ptr [si+0].Filesize  ; /
            mov dx,word ptr [si+2].Filesize  ;/

@@AddOffset:add ax,word ptr [position+0]     ;\ add in the offset
            adc ax,word ptr [position+2]     ;/
            jc @@Error                       ;signal error, if we overflowed
            cmp dx,word ptr [si+2].Filesize  ;\
            ja @@Error                       ; \  make sure new position is
            jb @@Okay                        ;  > less than or equal to the
            cmp ax,word ptr [si+0].Filesize  ; /  length of the file
            jae @@Error                      ;/
@@Okay:     mov word ptr [si+0].CurPos,ax    ;\ save the new position
            mov word ptr [si+2].CurPos,dx    ;/
            jmp @@Done                       ;return with the current position
@@Error:    mov ax,-1                        ;\ indicate error
            mov dx,-1                        ;/
@@Done:     pop di si bp                     ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_fseek
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
;     extern int jlib_read_file (int handle, char far *buffer, int count)
;
;reads a block of count bytes from the file specified by the handle into the
;specified buffer
;
;note:  If 'SLIDINGREQUEST' is nonzero and a value of 'count' is passed that
;       will go past the end of the logical end of file, it will be forced
;       down to the maximum number that will not go past the end.  If it is
;       not defined, then requests that would go past the end will be rejected
;       and an error will be returned
;also:  Note that this function returns 0 on failure, while most of the others
;       return -1 on failure
;
;Returns number of bytes read on success, or 0 on failure
;
PROC        _jlib_read_file
            ARG handle:word,buffer:dword,count:word
            push bp                          ;preserve caller's stack frame
            mov bp,sp                        ;use BP instead of SP
            push si di ds                    ;save what we'll modify

            cmp [LibHandle],-1               ;is a library already loaded?
            jz @@Error                       ;  no -- return error
            mov ax,size LibFile              ;\
            mul [handle]                     ; \ DS:SI ==> file information
            mov si,offset FileStats          ; /
            add si,ax                        ;/
            cmp ds:[si].Opened,0             ;is the file opened yet?
            jz @@Error                       ;  no -- return error

            mov ax,4200h                     ;\
            mov bx,[LibHandle]               ; \
            mov dx,word ptr [si+0].Fileoffset;  \
            mov cx,word ptr [si+2].Fileoffset;   \ seek to where we're
            add dx,word ptr [si+0].CurPos    ;   / supposed to be
            adc cx,word ptr [si+2].CurPos    ;  /
;-------- 1.3 changes start here
            add dx,word ptr [HeaderOffset+0]
            adc cx,word ptr [HeaderOffset+2]
;-------- 1.3 changes end here
            int 21h                          ; /
            jc @@Error                       ;/

            mov ax,word ptr [si+0].Filesize  ;\
            mov dx,word ptr [si+2].Filesize  ; \
            sub ax,word ptr [si+0].CurPos    ;  | figure out the maximum no.
            sbb dx,word ptr [si+2].CurPos    ;  | of bytes that could be read
            mov cx,[count]                   ;  | and compare the request with
            or dx,dx                         ;  | it, forcing to the maximum
            jnz @@Okay                       ;  | allowed if it will go past
            cmp ax,cx                        ;  | the end of the file.
IF SLIDINGREQUEST NE 0
            jae @@Okay                       ; /
            mov cx,ax                        ;/
ELSE
            jb @@Error
ENDIF

@@Okay:     push ds                          ;\
            mov ah,3Fh                       ; \
            mov bx,[LibHandle]               ;  \
            lds dx,[buffer]                  ;   \ actually do the read
            int 21h                          ;  /
            pop ds                           ; /
            jc @@Error                       ;/
            mov di,ax                        ;DI = number of bytes read

            mov ax,4201h                     ;\
            mov bx,[LibHandle]               ; \
            xor cx,cx                        ;  \
            xor dx,dx                        ;   \
            int 21h                          ;    \ find out where we are now
            jc @@Error                       ;    / and save it
            sub ax,word ptr [si+0].Fileoffset;   /
            sbb dx,word ptr [si+2].Fileoffset;  /
;-------- 1.3 changes start here
            sub ax,word ptr [HeaderOffset+0]
            sbb dx,word ptr [HeaderOffset+2]
;-------- 1.3 changes end here
            mov word ptr [si+0].CurPos,ax    ; /
            mov word ptr [si+2].CurPos,dx    ;/

            mov ax,di                        ;return the number of bytes read
            jmp @@Done                       ;return
@@Error:    xor ax,ax                        ;signal error
@@Done:     pop ds di si bp                  ;restore caller's stack frame
            ret                              ;return
ENDP        _jlib_read_file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
            END
