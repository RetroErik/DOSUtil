        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include file.inc

public  _flopenlib, _flcloselib, _flopenfile, _flreadfile

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
tokeninfo       dw      256 dup(?)

libnum          db      ?               ; number of files in library
libhandle       dw      ?               ; file handle of library
libheaderoff    dd      0               ; off of library header from end

filetogo        dd      ?               ; length of selected file to go

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Open a library file
; In:
;   EDX -> lib filename
; Out:
;   V86R_BX - ?
;   CF=0 - lib opened succesfully
;   CF=1 - lib not found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_flopenlib:
        call _openfile
        jc short flopenlibd
        push eax bx ecx edx
        mov ax,v86r_bx
        mov libhandle,ax
        mov eax,-1
        mov bl,2
        call _lseekfile
        mov edx,offset libnum
        mov ecx,1
        call _readfile
        movzx eax,byte ptr [edx]
        shl eax,3
        mov ecx,eax
        inc eax
        neg eax
        mov libheaderoff,eax
        call _lseekfile
        mov edx,offset tokeninfo
        call _readfile
        pop edx ecx bx eax
flopenlibd:
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Close a library file
; Out:
;   V86R_BX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_flcloselib:
        push ax
        mov ax,libhandle
        mov v86r_bx,ax
        call _closefile
        pop ax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Select a file from library
; In:
;   EAX - space padded token name (all 4 characters are used)
; Out:
;   V86R_BX - ?
;   CF=0 - file found
;   CF=1 - file not found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_flopenfile:
        push eax ebx ecx edx
        movzx ecx,libnum
        mov edx,ecx
        shl edx,3
        add edx,offset tokeninfo
        mov ebx,libheaderoff
flopenfilel0:
        sub edx,8
        sub ebx,[edx+4]
        cmp eax,[edx]
        loopne flopenfilel0
        stc
        jne short flopenfiled
        mov ax,libhandle
        mov v86r_bx,ax
        mov eax,ebx
        mov bl,2
        call _lseekfile
        mov eax,[edx+4]
        mov filetogo,eax
flopenfiled:
        pop edx ecx ebx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Read from a selected file
; In:
;   ECX - bytes to read
;   EDX -> buffer to read to
; Out:
;   EAX - bytes read
;   V86R_BX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_flreadfile:
        push ecx
        mov ax,libhandle
        mov v86r_bx,ax
        mov eax,filetogo
        cmp eax,ecx
        ja short flreadfilef0
        mov ecx,eax
flreadfilef0:
        xor eax,eax
        jecxz flreadfiled
        sub filetogo,ecx
        call _readfile
flreadfiled:
        pop ecx
        ret


code32  ends
        end

