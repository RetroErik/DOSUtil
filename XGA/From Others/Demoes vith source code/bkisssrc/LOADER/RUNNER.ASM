ideal
jumps
model huge
stack 1024

MAJORVER = 1        ;\ file format version 1.3
MINORVER = 3        ;/
MAXFILES = 50       ;maximum number of files allowed in library
BUFFERSIZE = 4096   ;size of transfer buffer in bytes (less than 64k)
FILES = 30          ;maximum number of 'FILES' in CONFIG.SYS to track


;******************
;*** structures ***
;******************
STRUC ParmBlock
        EnvSgmt     DW  0
        CmdTail     DD  0
        FCB_1       DD  0
        FCB_2       DD  0
        ExecAddr    DD  0
        PgmStack    DD  0
ENDS ParmBlock
STRUC FCB
        Filename    DB  11 DUP (' ')
        Reserved    DB  5 DUP (0)
ENDS FCB
STRUC LibFile
        Fileattr    DB  0
        Filetime    DW  0
        Filedate    DW  0
        Filesize    DD  0
        Filename    DB  13 DUP (0)
        Fileoffset  DD  0
ENDS LibFile
STRUC DTA
        DriveLetter DB  0                   ;+00 byte
        Wildcard    DB  11 DUP (' ')        ;+01 byte(11)
        AttrSearch  DB  0                   ;+0C byte
        Reserved1   DW  0                   ;+0D word
        Reserved2   DW  0                   ;+0F word
        Reserved3   DW  0                   ;+11 word
        Reserved4   DW  0                   ;+13 word
        AttrFound   DB  0                   ;+15 byte
        TimeFound   DW  0                   ;+16 word
        DateFound   DW  0                   ;+18 word
        SizeFound   DD  0                   ;+1A dword
        FileFound   DB  13 DUP (' ')        ;+1E byte(13)
ENDS DTA



;**************
;*** macros ***
;**************
MACRO ErrorMessage ErrorName,ErrorText
    LOCAL @@Message,@@Quit
    PROC    ErrorName
            mov ah,9
            push cs
            pop ds
            mov dx,offset @@Message
            int 21h
            cmp [Handle],0FFFFh
            jz @@Quit
            mov ah,3Eh
            mov bx,[Handle]
            int 21h
@@Quit:     mov ax,4CFFh
            int 21h
@@Message   DB  '***Error*** ',ErrorText,0Dh,0Ah,'$'
    ENDP    ErrorName
ENDM ErrorMessage
MACRO MAKEUPPERCASE letter
    LOCAL @@NotLower
    cmp letter,'a'
    jb @@NotLower
    cmp letter,'z'
    ja @@NotLower
    sub letter,'a'-'A'
@@NotLower:
ENDM MAKEUPPERCASE



SEGMENT     Code
            ASSUME CS:Code, DS:Code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°° Initialization °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        Start
            mov [cs:PSPsegment],es
            push cs                         ;\
            pop ds                          ; \
            mov ah,9                        ;  > display our greeting
            mov dx,offset Hello             ; /
            int 21h                         ;/
            mov ah,30h                      ;\
            int 21h                         ; \ make sure we have DOS 2.x +
            cmp al,3                        ; /
            jb OldDOSversion                ;/

            push cs                         ;\
            pop ds                          ; \ create filename
            mov di,offset LibName           ; /
            call CreateFilename             ;/

            mov ax,[cs:PSPsegment]          ;\
            mov es,ax                       ; \
            mov bx,zzzzzseg                 ;  \
            sub bx,ax                       ;   \ reduce memory overhead
            add bx,2                        ;   /
            mov ah,4Ah                      ;  /
            int 21h                         ; /
            jc ErrorChangingMemory          ;/
            mov ah,49h                      ;\
            mov es,[cs:PSPsegment]          ; \
            mov es,[word es:002Ch]          ;  > free our environment space
            int 21h                         ; /
            jc ErrorChangingMemory          ;/

            ;*** Reading of the JLIB file header ***
            mov ax,3D00h                    ;\
            push cs                         ; \
            pop ds                          ;  \
            mov dx,offset LibName           ;   > try to open the library file
            int 21h                         ;  /
            jc BadLibName                   ; /
            mov [Handle],ax                 ;/
;-------- 1.3 changes start here
            mov ax,-4                       ;\
            cwd                             ; \
            mov cx,dx                       ;  \
            mov dx,ax                       ;   > seek to 4 bytes before end
            mov ax,4202h                    ;  /
            mov bx,[Handle]                 ; /
            int 21h                         ;/
            mov ah,3Fh                      ;\
            mov bx,[Handle]                 ; \
            mov cx,4                        ;  > read in the offset to start
            mov dx,offset HeaderOffset      ; /
            int 21h                         ;/
            mov ax,4201h                    ;\
            mov bx,[Handle]                 ; \
            xor cx,cx                       ;  > find out length of total file
            xor dx,dx                       ; /
            int 21h                         ;/
            sub ax,[word HeaderOffset+0]    ;\
            sbb dx,[word HeaderOffset+2]    ; \ compute offset to start of JLIB
            mov [word HeaderOffset+0],ax    ; /
            mov [word HeaderOffset+2],dx    ;/
            mov ax,4200h                    ;\
            mov bx,[Handle]                 ; \
            mov cx,[word HeaderOffset+2]    ;  > seek to start of JLIB
            mov dx,[word HeaderOffset+0]    ; /
            int 21h                         ;/
;-------- 1.3 changes end here
            mov ah,3Fh                      ;\
            mov bx,[Handle]                 ; \
            mov cx,6                        ;  \ read in signature and
            mov dx,offset Buffer            ;  / file version number
            int 21h                         ; /
            jc FileError                    ;/
            cmp [word Buffer],'LJ'          ;\
            jnz BadSignature                ; \
            cmp [word Buffer+2],'bi'        ;  \ check the signarure and
            jnz BadSignature                ;  / file version number
            cmp [word Buffer+4],MINORVER*256+MAJORVER
            jnz BadSignature                ;/
            mov ah,3Fh                      ;\
            mov bx,[Handle]                 ; \
            mov cx,2                        ;  \ read in number of files
            mov dx,offset NumFiles          ;  / contained in the library
            int 21h                         ; /
            jc FileError                    ;/
            mov cx,[NumFiles]               ;\
            cmp cx,MAXFILES                 ; > check the limit of files
            ja TooManyFiles                 ;/
            mov ah,3Fh                      ;\
            mov bx,[Handle]                 ; \
            mov cx,4                        ;  \ read in the offset to the
            mov dx,offset Transfer          ;  / directory structures
            int 21h                         ; /
            jc FileError                    ;/
            mov ax,4200h                    ;\
            mov bx,[Handle]                 ; \
            mov cx,[word Transfer+2]        ;  \ seek to the beginning of
            mov dx,[word Transfer+0]        ;  / the file structures
;-------- 1.3 changes start here
            add dx,[word HeaderOffset+0]
            adc cx,[word HeaderOffset+2]
;-------- 1.3 changes end here
            int 21h                         ; /
            jc FileError                    ;/
            mov cx,[NumFiles]               ;\
            mov dx,offset FileStats         ; \
@@Read:     push cx dx                      ;  \
            mov ah,3Fh                      ;   |
            mov bx,[Handle]                 ;   |
            mov cx,size LibFile             ;   | read in the directory
            int 21h                         ;   | information for each file
            jc FileError                    ;   |
            pop dx cx                       ;  /
            add dx,size LibFile             ; /
            loop @@Read                     ;/
            mov ah,3Eh                      ;\
            mov bx,[Handle]                 ; \ close the library file
            mov [Handle],-1                 ; /
            int 21h                         ;/

            ;*** Installation of handler and execution of child ***
            mov ax,3521h                    ;\
            int 21h                         ; \ save the old int 21 vector
            mov [word cs:OldInt21+0],bx     ; /
            mov [word cs:OldInt21+2],es     ;/
            mov ax,2521h                    ;\
            mov dx,seg NewInt21             ; \
            mov ds,dx                       ;  > hook our routine onto int 21
            mov dx,offset NewInt21          ; /
            int 21h                         ;/
            mov [word cs:StackPTR+0],sp     ;\ save the stack for later
            mov [word cs:StackPTR+2],ss     ;/
            mov ax,4B00h                    ;load and execute program
            mov dx,seg ProgramName          ;\
            mov ds,dx                       ; > DS:DX ==> ASCIIZ program name
            mov dx,offset ProgramName       ;/
            mov bx,seg MyParmBlock          ;\
            mov es,bx                       ; > ES:BX ==> parameter block
            mov bx,offset MyParmBlock       ;/
            cld
            mov [word cs:MyParmBlock+offset (ParmBlock).EnvSgmt],0
            mov [word cs:MyParmBlock+0+offset (ParmBlock).CmdTail],offset CommandTail
            mov [word cs:MyParmBlock+2+offset (ParmBlock).CmdTail],seg CommandTail
            mov [word cs:MyParmBlock+0+offset (ParmBlock).FCB_1],offset MyFCB_1
            mov [word cs:MyParmBlock+2+offset (ParmBlock).FCB_1],seg MyFCB_1
            mov [word cs:MyParmBlock+0+offset (ParmBlock).FCB_2],offset MyFCB_2
            mov [word cs:MyParmBlock+2+offset (ParmBlock).FCB_2],seg MyFCB_2
            int 21h                         ;call DOS
            lahf                            ;\ save whether errors occurred
            mov [cs:@@ErrorFlag],ax         ;/
            cli                             ;\
            mov sp,[word cs:StackPTR+0]     ; \ restore the stack
            mov ss,[word cs:StackPTR+2]     ; /
            sti                             ;/
            mov ax,2521h                    ;\
            lds dx,[cs:OldInt21]            ; > restore the int 21h vector
            int 21h                         ;/
            mov ax,cs                       ;\
            mov es,ax                       ; > restore the segments
            mov ds,ax                       ;/
            mov ax,[cs:@@ErrorFlag]         ;\
            test ah,1                       ; > if CARRY was set, handle error
            jnz @@ExecError                 ;/
            mov ax,4C00h                    ;\ terminate program
            int 21h                         ;/
@@ExecError:aam                             ;\
            add ax,'00'                     ; \ convert and store
            xchg ah,al                      ; / error number
            mov [@@ExecNum],ax              ;/
            mov ah,9                        ;\
            mov dx,offset @@ExecMsg         ; > display error message
            int 21h                         ;/
            mov ax,4CFFh                    ;\ terminate program
            int 21h                         ;/
@@ExecMsg   db 'Error number '
@@ExecNum   dw ?
@@ExecMsg2  db ' (decimal) during execution of child process.',0Dh,0Ah,'$'
@@ErrorFlag dw 0    ;high byte is copy of flags, low is value of AL
ENDP        Start
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           DS:DI ==> location to place resulting filename
;
proc        CreateFilename
            mov ax,6200h                ;\
            int 21h                     ; \
            mov es,bx                   ;  > ES:BX ==> environment segment
            mov es,[word es:2Ch]        ; /
            xor bx,bx                   ;/
@@FindStart:cmp [word es:bx],0000h      ;\
            jz @@GotStart               ; \
            inc bx                      ;  > ES:BX ==> filename of program
            jmp @@FindStart             ; /
@@GotStart: add bx,4                    ;/
@@CopyName: mov al,[byte es:bx]         ;\
            inc bx                      ; \
            mov [byte ds:di],al         ;  \ copy the full pathname
            inc di                      ;  /
            or al,al                    ; /
            jnz @@CopyName              ;/
            ret                         ;return
endp        CreateFilename
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;the following data is used only during initialization of program
Hello       DB  'JLIBHOST.COM -- JLib File Host, v','0'+MAJORVER,'.','0'+MINORVER,0Dh,0Ah
            DB  'by  _______  /',0Dh,0Ah
            DB  '       /    /      ÚÄÄÚ¿  ³ÄÂÄÚÄÄÚÄ¿ÚÄ¿ÚÄ¿oÚÄÄÚÄÄÚÄÄ',0Dh,0Ah
            DB  '      /    /       ÃÄ ³ÀÄ¿³ ³ ÃÄ ÃÂÙÃÄÙÃÂÙ³ÀÄ¿ÃÄ ÀÄ¿',0Dh,0Ah
            DB  '/____/    /_____   ÀÄÄ³  ÀÙ ³ ÀÄÄ³ \³  ³ \³ÄÄÙÀÄÄÄÄÙ',0Dh,0Ah
            DB  0Dh,0Ah,'$'
;NowRunning  DB  'Now running under a JLIB Host environment.',0Dh,0Ah,'$'
;WelcomeBack DB  'Welcome back to reality.',0Dh,0Ah,'$'
PSPsegment  DW  0                   ;our PSP segment
StackPTR    DD  0                   ;saved stack pointer
MyParmBlock ParmBlock <>            ;\
MyFCB_1     FCB <>                  ; \
MyFCB_2     FCB <>                  ;  > used for executing child process
ProgramName DB 'LOADER.EXE',0       ; /
CommandTail DB 0,127 DUP (0Dh)      ;/
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;the following are all of the error messages, each created using a macro
ErrorMessage ErrorChangingMemory,'Error during memory management.'
ErrorMessage OldDOSversion,'This requires DOS 2.0 or higher.'
ErrorMessage NoCommandLine,<'Bad command line syntax.',0Dh,0Ah,9,'JLIBHOST ®libname.JLB¯ ®program.EXE¯ ®parameters¯'>
ErrorMessage BadLibName,'Error opening specified library.'
ErrorMessage BadSignature,'Bad library format.'
ErrorMessage TooManyFiles,'Too many files in library.'
ErrorMessage FileError,'Error during file I/O.'
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°° Library functions °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;the following data is needed by the library functions to access files
OldInt21    DD 0                        ;old interrupt vector
LibName     DB 127 DUP (0)              ;full filename of library file
Handle      DW 0FFFFh                   ;
Handle2     DW 0FFFFh                   ;
NumFiles    DW 0                        ;number of files in library
FileStats   LibFile MAXFILES DUP (<>)   ;file info structures of each file
Buffer      DB 13 DUP (0)               ;
Wildcard    DB 13 DUP (0)               ;\   last defined wildcard
MasterAttr  DW 0                        ; \  original search attribute
HandleNext  DB 0                        ;  > if next FindNext should be caught
LastMatch   DW 0                        ; /  number of last match
MasterWild  DB 80 DUP (0)               ;/   original search wildcard
HandleList  DW FILES DUP (0)            ;list of which handles are what
Transfer    DB BUFFERSIZE DUP (0)       ;transfer buffer (for dumping files)
HeaderOffset DD 0                       ;offset to start of JLIB file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;capitalize filename, make sure there's a period, only allow 8 characters
;for the base name and 3 characters for the extension, doesn't allow
;characters after an asterick
;
;           DS:DX ==> ASCIIZ filename
;returns:   prepared filename is in 'Buffer'
;           ZF set if no filename passed (null name)
PROC        FixFileName
            push si bx ax                   ;save what we'll modify
            mov si,dx                       ;DS:SI ==> source name
            cmp [byte ds:si],0              ;\ quit with ZF set, if there's
            jz @@Quit                       ;/ nothing given to us
@@FindEnd:  inc si                          ;\
            cmp [byte ds:si],0              ; > seek to the end of the name
            jnz @@FindEnd                   ;/
            std                             ;\
@@FindStart:lodsb                           ; \
            cmp si,dx                       ;  \
            jz @@GotStart                   ;   | seek back to
            cmp al,'\'                      ;   | the start of
            jz @@IncOne                     ;   | the base name
            cmp al,':'                      ;  /
            jnz @@FindStart                 ; /
@@IncOne:   add si,2                        ;/
@@GotStart: mov bx,offset Buffer            ;CS:BX ==> place for final name
            cld                             ;go forward, now
            mov ah,8                        ;only copy 8 bytes for the base
@@Basename: mov al,[byte ds:si]             ;\
            or al,al                        ; \ load a byte, handling it
            jz @@AddDot                     ; / if it's a NULL
            inc si                          ;/
            cmp al,'.'                      ;if we've found a period, start
            jz @@AddDot                     ;  working on the extension
            MAKEUPPERCASE al                ;\
            mov [byte cs:bx],al             ; > make uppercase and store
            inc bx                          ;/
            cmp al,'*'                      ;if we've found an asterick, then
            jz @@Ignore                     ;  ignore all up to period or end
            dec ah                          ;\ only copy 8 characters
            jnz @@Basename                  ;/
@@Ignore:   mov al,[byte ds:si]             ;\
            or al,al                        ; \
            jz @@AddDot                     ;  \ skip until a NULL or a
            inc si                          ;  / period is encountered
            cmp al,'.'                      ; /
            jnz @@Ignore                    ;/
@@AddDot:   mov [byte cs:bx],'.'            ;\ tack on a period
            inc bx                          ;/
            mov ah,3                        ;only copy 3 bytes for the ext
@@Extension:lodsb                           ;\  load a byte and handle
            or al,al                        ; > it if it's a NULL
            jz @@Done                       ;/
            MAKEUPPERCASE al                ;\
            mov [byte cs:bx],al             ; > make uppercase and store it
            inc bx                          ;/
            cmp al,'*'                      ;\ if we copied a '*', then there
            jz @@Done                       ;/ shouldn't be anything after it
            dec ah                          ;\ only copy 3 characters
            jnz @@Extension                 ;/
@@Done:     mov [byte cs:bx],0              ;\ terminate it with a NULL
            or al,1               ;clear ZF ;/
@@Quit:     pop ax bx si                    ;restore everything
            ret                             ;return
ENDP        FixFileName
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;locates a file structure that matches identically to a specified file
;
;           ASCIIZ filename to match is in 'Buffer'
;returns:   SI ==> appropiate structure
;           AX = file number (0 based)
;           carry set if not found
PROC        MatchFile
            push di bx cx dx
            xor ax,ax
            mov si,offset FileStats
            mov cx,[cs:NumFiles]
            mov di,offset Buffer
@@NewFile:  xor bx,bx
@@Compare:  mov dl,[byte cs:si+bx+offset (LibFile).Filename]
            or dl,dl
            jz @@GotIt
            cmp dl,[byte cs:di+bx]
            jnz @@Next
            inc bx
            jmp @@Compare
@@Next:     add si,size LibFile
            inc ax
            loop @@NewFile
            stc                     ;signal error
            jmp @@Quit
@@GotIt:    clc                     ;signal success
@@Quit:     pop dx cx bx di
            ret
ENDP        MatchFile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;locates a file structure that matches a specified wildcard
;
;           ASCIIZ wildcard to match is in 'Wildcard'
;           AX = file number from last call (-1 for first time)
;returns:   if CF clear then
;               SI ==> appropiate structure
;               AX = file number (0 based)
;           else
;               no more matching files or invalid starting number
;           endif
PROC        MatchWild
            push di bx cx dx bp
            mov bx,ax                   ;\
            inc bx                      ; \ make sure the start value is okay
            cmp bx,[cs:NumFiles]        ; /
            jae @@NoMore                ;/
            inc ax                      ;AX = first entry to check
            push ax                     ;\
            mov bx,size LibFile         ; \
            mul bx                      ;  \ SI ==> first structure to check
            mov si,offset FileStats     ;  /
            add si,ax                   ; /
            pop ax                      ;/
            mov cx,[cs:NumFiles]        ;\
            sub cx,ax                   ; > CX = number of files to check
            inc cx                      ;/
            mov di,offset Wildcard      ;DI ==> wildcard string
@@NewFile:  xor bx,bx
            mov bp,offset (LibFile).Filename
@@Compare:  mov dl,[byte cs:di+bx]      ;DL = wildcard letter
            mov dh,[byte cs:si+bp]      ;DH = filename letter
            inc bx
            inc bp
            cmp dl,'.'                  ;\
            jz @@GotDot                 ; \
            cmp dh,'.'                  ;  \
            jnz @@NoDot                 ;   > period ('.')
@@GotDot:   cmp dl,dh                   ;  /
            jnz @@NoMatch               ; /
            jmp @@Compare               ;/
@@NoDot:    or dl,dl                    ;\
            jz @@GotNull                ; \
            or dh,dh                    ;  \
            jnz @@NoNull                ;   > null (0h)
@@GotNull:  cmp dh,dl                   ;  /
            jz @@Found                  ; /
            jmp @@NoMatch               ;/
@@NoNull:   cmp dl,'?'                  ;\ question mark ('?')
            jz @@Compare                ;/
            cmp dl,'*'                  ;\
            jnz @@NotStar               ; \
@@Ignore:   mov dl,[byte cs:si+bp]      ;  \
            cmp dl,'.'                  ;   |
            jz @@Compare                ;   | asterick ('*')
            or dl,dl                    ;   |
            jz @@Compare                ;  /
            inc bp                      ; /
            jmp @@Ignore                ;/
@@NotStar:  cmp dl,dh                   ;\ if it matches up, then go
            jz @@Compare                ;/ on to the next character
@@NoMatch:  add si,size LibFile         ;point to the next structure
            inc ax                      ;increment our counter
            loop @@NewFile              ;loop until we've searched all
@@NoMore:   pop bp dx cx bx di          ;\
            stc                         ; > quit unsucessfully
            ret                         ;/
@@Found:    pop bp dx cx bx di          ;\
            clc                         ; > quit sucessfully
            ret                         ;/
ENDP        MatchWild
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°° Interrupt handlers °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        NewInt21 FAR
            cmp ah,3Dh
            jz OpenFile
            cmp ah,3Eh
            jz CloseFile
            cmp ah,4Eh
            jz FindFirst
            cmp ah,4Fh
            jz FindNext
            cmp ah,4Bh
            jz Execute

            jmp [dword cs:OldInt21]
ENDP        NewInt21
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           AL = access mode (0 = read, 1 = write, 2 = read/write)
;           DS:DX ==> ASCIIZ filename
;returns:   AX = file handle
;
;(to temporarily dump a file to disk, set AX = 0, DS:DX ==> filename)
;(will return an internal pointer in AX to be passed to CloseFile later)
;(if -1 is returned, then the file is not contained in the library)
;(remember to pushf before far calling this routine to simulate an interrupt)
PROC        OpenFile FAR
            push ds es bx cx dx si di ax
            call FixFileName
            jz @@CallOld
            call MatchFile
            jc @@CallOld

            ;*** Open up the library and dump out the file requested ***
            mov ax,3D00h                            ;\
            push cs                                 ; \
            pop ds                                  ;  \
            mov dx,offset LibName                   ;   \ reopen the library
            pushf                                   ;   /
            call [dword cs:OldInt21]                ;  /
            jc @@CallOld                            ; /
            mov [Handle],ax                         ;/
            mov ax,4200h                            ;\
            mov bx,[Handle]                         ; \
            mov cx,[word si+2+LibFile.Fileoffset]   ;  \ position the pointer
            mov dx,[word si+0+LibFile.Fileoffset]   ;  /
;-------- 1.3 changes start here
            add dx,[word HeaderOffset+0]
            adc cx,[word HeaderOffset+2]
;-------- 1.3 changes start here
            pushf                                   ; /
            call [dword cs:OldInt21]                ;/
            mov ah,3Ch                              ;\
            xor cx,cx                               ; \
            mov dx,si                               ;  \
            add dx,offset (LibFile).Filename        ;   > create the file
            pushf                                   ;  /
            call [dword cs:OldInt21]                ; /
            mov [Handle2],ax                        ;/
            mov cx,[word si+0+LibFile.Filesize]     ;\ DX:CX ==> size to copy
            mov dx,[word si+2+LibFile.Filesize]     ;/
@@CopyLoop: or dx,dx                                ;\
            jnz @@CopyBig                           ; \
            cmp cx,BUFFERSIZE                       ;  \
            jbe @@CopySmall                         ;   \
@@CopyBig:  push cx dx                              ;    |
            mov ah,3Fh                              ;    |
            mov bx,[Handle]                         ;    |
            mov cx,BUFFERSIZE                       ;    |
            mov dx,offset Transfer                  ;    |
            pushf                                   ;    |
            call [dword cs:OldInt21]                ;    |
            mov ah,40h                              ;    |
            mov bx,[Handle2]                        ;    |
            mov cx,BUFFERSIZE                       ;    |
            mov dx,offset Transfer                  ;    | dump the data from
            pushf                                   ;    | the library into a
            call [dword cs:OldInt21]                ;    | separate file
            pop dx cx                               ;    | (a decompression
            sub cx,BUFFERSIZE                       ;    | scheme could be
            sbb dx,0                                ;    | implemented here
            jmp @@CopyLoop                          ;    | if file compression
@@CopySmall:jcxz @@CopyDone                         ;    | were to be added)
            push cx                                 ;    |
            mov ah,3Fh                              ;    |
            mov bx,[Handle]                         ;    |
            mov dx,offset Transfer                  ;    |
            pushf                                   ;    |
            call [dword cs:OldInt21]                ;    |
            mov ah,40h                              ;    |
            mov bx,[Handle2]                        ;    |
            pop cx                                  ;   /
            mov dx,offset Transfer                  ;  /
            pushf                                   ; /
            call [dword cs:OldInt21]                ;/
@@CopyDone: mov ah,3Eh                              ;\
            mov bx,[Handle]                         ; \
            mov [Handle],-1                         ;  > close the library
            pushf                                   ; /
            call [dword cs:OldInt21]                ;/
            mov ah,3Eh                              ;\
            mov bx,[Handle2]                        ; \
            mov [Handle2],-1                        ;  > close the output
            pushf                                   ; /
            call [dword cs:OldInt21]                ;/


            ;*** let DOS open the temporary file ***
            pop ax
            cmp ah,3Dh              ;check to see if it's an internal call
            jnz @@Internal          ;   if yes -- then just return a pointer
            mov dx,si
            add dx,offset (LibFile).Filename
            pushf
            call [dword cs:OldInt21]
            mov di,ax
            shl di,1
            add di,offset HandleList
            mov [word di],si
            pop di si dx cx bx es ds
            ret 2
@@Internal: mov ax,si
            pop di si dx cx bx es ds
            ret 2
@@CallOld:  pop ax di si dx cx bx es ds
            cmp ah,3Dh
            jz @@CallOld2
            mov ax,-1
            ret 2
@@CallOld2: jmp [dword cs:OldInt21]
ENDP        OpenFile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           BX = file handle
;
;(to delete an internally dumped, temporary file, set AX = 0, SI = pointer)
;(if a -1 is passed in SI, this function has no effect)
;(remember to pushf before far calling this routine to simulate an interrupt)
PROC        CloseFile FAR
            push ax bx cx dx si di ds es

            cmp ah,3Eh
            jnz @@Internal

            ;*** if it's ours, set SI to its structure, else call DOS ***
            mov di,bx
            shl di,1
            add di,offset HandleList
            cmp [word cs:di],0
            jz @@CallOld
            mov si,[word cs:di]
            mov [word cs:di],0

            ;*** close the file ***
            mov ah,3Eh
            pushf
            call [dword cs:OldInt21]

@@Internal: ;*** and delete the temporary file ***
            cmp si,-1
            jz @@Quit
            mov ah,41h
            push cs
            pop ds
            mov dx,si
            add dx,offset (LibFile).Filename
            int 21h

@@Quit:     pop es ds di si dx cx bx ax
            clc
            ret 2
@@CallOld:  pop es ds di si dx cx bx ax
            jmp [dword cs:OldInt21]
ENDP        CloseFile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           CX = attributes to search for
;           DS:DX ==> ASCIIZ filespec
;returns:   AX = error code, if CF set
;           DTA contains search information
PROC        FindFirst FAR
            push ds es ax bx cx dx si di

            mov [cs:MasterAttr],cx          ;save original search attribute
            mov si,dx                       ;\
            mov di,offset MasterWild        ; \
            push cs                         ;  \
            pop es                          ;   \ save the original wildcard
            mov cx,79                       ;   /
            rep movsb                       ;  /
            xor al,al                       ; /
            stosb                           ;/
            call FixFileName                ;\ process and parse the filespec
            jz @@CallOld                    ;/
            cld                             ;\
            mov ax,cs                       ; \
            mov ds,ax                       ;  |
            mov es,ax                       ;  | transfer the wildcard
            mov si,offset Buffer            ;  | into storage
            mov di,offset Wildcard          ;  |
            mov cx,12                       ; /
            rep movsb                       ;/
            mov ah,2Fh                      ;\
            pushf                           ; > ES:BX ==> current DTA
            call [dword cs:OldInt21]        ;/
            mov di,bx                       ;\
            mov cx,size DTA                 ; \ blank out the DTA
            xor al,al                       ; /
            rep stosb                       ;/
            mov ax,-1                       ;\
            call MatchWild                  ; \  do the search and save
            jc @@CallOld                    ;  > what is needed to continue
            mov [cs:LastMatch],ax           ; /  where we left off
            mov [cs:HandleNext],1           ;/
            mov di,bx                       ;\
            add di,offset (DTA).AttrFound   ; \ copy over the stats about
            mov cx,22                       ; / the file into the DTA
            rep movsb                       ;/
            pop di si dx cx bx ax es ds     ;\
            clc                             ; > return with a successful find
            ret 2                           ;/
@@CallOld:  mov [cs:HandleNext],0           ;\
            pop di si dx cx bx ax es ds     ; > start searching thru DOS
            jmp [dword cs:OldInt21]         ;/
ENDP        FindFirst
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        FindNext FAR
            push ds dx es ax bx cx si di

            cmp [cs:HandleNext],0           ;\ if we're not supposed to
            jz @@CallOld                    ;/ handle this, then don't
            mov ax,[cs:LastMatch]           ;\
            call MatchWild                  ; \ continue searching, then save
            jc @@StartOld                   ; / what's needed to continue
            mov [cs:LastMatch],ax           ;/
            push cs                         ;\ DS:SI ==> file structure
            pop ds                          ;/
            mov ah,2Fh                      ;\
            pushf                           ; > ES:BX ==> current DTA
            call [dword cs:OldInt21]        ;/
            mov di,bx                       ;\
            mov cx,size DTA                 ; \ blank out the DTA
            xor al,al                       ; /
            rep stosb                       ;/
            mov di,bx                       ;\
            add di,offset (DTA).AttrFound   ; \ copy over the stats about
            mov cx,22                       ; / the file into the DTA
            rep movsb                       ;/
            pop di si cx bx ax es dx ds     ;\
            clc                             ; > return with a successful find
            ret 2                           ;/
@@StartOld: mov [cs:HandleNext],0           ;\
            pop di si cx bx ax es           ; \
            mov ah,4Eh                      ;  \
            mov cx,[cs:MasterAttr]          ;   \
            push cs                         ;    \
            pop ds                          ;     > start searching thru DOS
            mov dx,offset MasterWild        ;    /
            pushf                           ;   /
            call [dword cs:OldInt21]        ;  /
            pop dx ds                       ; /
            ret 2                           ;/
@@CallOld:  pop di si cx bx ax es dx ds     ;\ continue searching thru DOS
            jmp [dword cs:OldInt21]         ;/
ENDP        FindNext
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           DS:DX ==> ASCIIZ filename to run
;           ES:BX ==> Parameter block for exec function
;returns:   AX = error code, if CF set
PROC        Execute FAR
            mov [cs:@@Temp],si
            mov si,[cs:ExecSavePtr]
            cmp si,MaxExecNests*size ExecSaveType
            jae @@Error
            add [cs:ExecSavePtr],size ExecSaveType

            ;temporarily dump out the file
            push ax
            xor ax,ax
            pushf
            call OpenFile
            mov [cs:offset ExecSave+si+offset (ExecSaveType).FilePointer],ax
            pop ax

            ;let DOS execute it
            mov [word cs:offset ExecSave+si+0+offset (ExecSaveType).StackPointer],sp
            mov [word cs:offset ExecSave+si+2+offset (ExecSaveType).StackPointer],ss
            mov si,[cs:@@Temp]
            pushf                       ;\ simulate an int 21h to old handler
            call [dword cs:OldInt21]    ;/

            ;get the system back to normality
            cli
            mov [cs:@@Temp],si
            mov si,[cs:ExecSavePtr]
            mov sp,[word cs:offset ExecSave+si-size ExecSaveType+0+offset (ExecSaveType).StackPointer]
            mov ss,[word cs:offset ExecSave+si-size ExecSaveType+2+offset (ExecSaveType).StackPointer]
            pushf
            push ax
            sti

            ;delete our temporary file
            xor ax,ax
            mov si,[cs:offset ExecSave+si-size ExecSaveType+offset (ExecSaveType).FilePointer]
            pushf
            call CloseFile

            ;deallocate this program's slot on our stack
            sub [cs:ExecSavePtr],size ExecSaveType

            ;return (with current flag settings)
            pop ax
            popf
            mov si,[cs:@@Temp]
            ret 2
@@Error:    stc
            mov ax,5        ;return with 'access denied'
            ret 2
@@Temp      dw ?
ENDP        Execute
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
MaxExecNests = 10
ExecSavePtr dw 0
struc       ExecSaveType
            StackPointer dd ?
            FilePointer dw ?
ends        ExecSaveType
ExecSave    ExecSaveType MaxExecNests dup (<>)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ENDS        Code

SEGMENT     zzzzzseg
            DB 16 DUP(?)
ENDS        zzzzzseg

            END     Start
