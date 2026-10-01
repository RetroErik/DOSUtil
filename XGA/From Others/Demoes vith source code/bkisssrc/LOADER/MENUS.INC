;HandleMenu
;DisplayMenu
;DisplayChar
;DisplayText
;GetVideoSegment

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
struc       SelectorType
            Row             dw ?
            Column          dw ?
            NumItems        dw ?
            CurrentChoice   dw ?
label       Titles          byte
ends        SelectorType
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
struc       StringType
            StringLength    dw ?
label       Text            byte
ends        StringType
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       DefineTitle padlength,stringtext
            stringlength sizestr <stringtext>
            errif (stringlength-2+4) gt (padlength) "String too long"
            dw padlength
            if (stringlength-2) ge 1
                padwidth = ((padlength)-(stringlength-2+4))/2
                if (padwidth) ge 1
                    db (padwidth) dup ('Í')
                endif
                db "µ ",stringtext," Æ"
                padwidth = (padlength-((stringlength-2+4)+padwidth))
                if (padwidth) ge 1
                    db (padwidth) dup ('Í')
                endif
            else
                db (padlength) dup('Í')
            endif
endm
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       DefineString padlength,stringtext,padvalue
            stringlength sizestr <stringtext>
            errif (stringlength-2) gt (padlength) "String too long"
            dw padlength
            db stringtext
            padwidth = (padlength)-(stringlength-2)
            if (padwidth) ge 1
                db (padwidth) dup (padvalue)
            endif
endm
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       CenterString padlength,stringtext,padvalue
            stringlength sizestr <stringtext>
            errif (stringlength-2) gt (padlength) "String too long"
            dw padlength
            padwidth = ((padlength)-(stringlength-2))/2
            if (padwidth) ge 1
                db (padwidth) dup (padvalue)
            endif
            db stringtext
            padwidth = (padlength-((stringlength-2)+padwidth))
            if (padwidth) ge 1
                db (padwidth) dup (padvalue)
            endif
endm
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;returns:   ES = segment of video memory (0B800h or 0B000h)
proc        GetVideoSegment
            mov ax,40h              ;\ set ES to the BIOS
            mov es,ax               ;/ information area
            mov ax,0B000h           ;default to mono card
            test [word es:4Ah],30h  ;is it a monochrome?
            je @@Quit               ;   yes -- quit, we're done
            mov ax,0B800h           ;set to color card
@@Quit:     mov es,ax               ;point ES to video
            ret                     ;return
endp        GetVideoSegment
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           ES = segment of video memory (0B800h or 0B000h)
;           AL = character
;           AH = attribute
;           CX = column (0 based)
;           DX = row (0 based)
proc        DisplayChar
            push di

            mov di,dx
            shl di,2
            add di,dx
            shl di,4
            add di,cx
            shl di,1
            mov [word es:di],ax

            inc cx

            pop di
            ret
endp        DisplayChar
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           ES = segment of video memory (0B800h or 0B000h)
;           AH = attribute
;           BX = length of string
;           CX = column (0 based)
;           DX = row (0 based)
;           DS:SI ==> text
proc        DisplayText
@@Loop:     lodsb
            call DisplayChar
            dec bx
            jnz @@Loop
            ret
endp        DisplayText
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           ES = segment of video memory (0B800h or 0B000h)
;           DS:SI ==> menu structure
;           AL = base color
;           AH = highlighted color
proc        DisplayMenu
            mov [cs:@@BaseColor],al
            mov [cs:@@HighColor],ah
            mov di,si

            ;*** first row ***
            mov cx,[ds:di+SelectorType.Column]
            mov dx,[ds:di+SelectorType.Row]
            mov al,'É'
            mov ah,[cs:@@BaseColor]
            call DisplayChar

            mov bx,[ds:di+offset  (SelectorType).Titles+offset (StringType).StringLength]
            mov si,di
            add si,offset (SelectorType).Titles+offset (StringType).Text
            call DisplayText

            mov al,'»'
            call DisplayChar

            ;*** second row ***
            mov cx,[ds:di+SelectorType.Column]
            inc dx              ;next row
            mov al,'º'
            mov ah,[cs:@@BaseColor]
            call DisplayChar

            mov bx,[ds:di+offset (SelectorType).Titles+offset (StringType).StringLength]
            mov al,' '
@@2ndLoop:  call DisplayChar
            dec bx
            jnz @@2ndLoop

            mov al,'º'
            call DisplayChar

            ;*** display all of the choices ***
            mov cx,[ds:di+SelectorType.NumItems]        ;CX = number to do
            mov bx,cx
            sub bx,[ds:di+SelectorType.CurrentChoice]   ;BX = no. of choice
            mov si,di
            add si,offset (SelectorType).Titles
            add si,[word si+(StringType).StringLength]
            add si,size StringType                      ;SI ==> 1st choice
            inc dx              ;next row

@@3rdLoop:  push cx bx si

            mov ah,[cs:@@BaseColor]     ;\
            mov al,[cs:@@HighColor]     ; \
            cmp bx,cx                   ;  \ set [@@Temp] to color to use
            jz @@GotColor               ;  / for item name
            mov al,ah                   ; /
@@GotColor: mov [cs:@@Temp],al          ;/

            mov cx,[ds:di+SelectorType.Column]
            mov al,'º'
            mov ah,[cs:@@BaseColor]
            call DisplayChar

            mov ah,[cs:@@Temp]
            mov bx,[ds:si+StringType.StringLength]
            add si,offset (StringType).Text
            call DisplayText

            mov al,'º'
            mov ah,[cs:@@BaseColor]
            call DisplayChar

            pop si bx cx
            inc dx                              ;start on next row
            add si,[ds:si+StringType.StringLength]
            add si,size StringType              ;point to next string
            dec cx
            jnz @@3rdLoop                       ;loop until we're done

            ;*** last row ***
            mov cx,[ds:di+SelectorType.Column]
            mov al,'È'
            mov ah,[cs:@@BaseColor]
            call DisplayChar

            mov bx,[ds:di+offset (SelectorType).Titles+offset (StringType).StringLength]
            mov al,'Í'
@@4thLoop:  call DisplayChar
            dec bx
            jnz @@4thLoop

            mov al,'¼'
            call DisplayChar

            ret

@@BaseColor db  ?
@@HighColor db  ?
@@Temp      db  ?
endp        DisplayMenu
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           ES = segment of video memory (0B800h or 0B000h)
;           DS:SI ==> menu structure
;           AL = base color
;           AH = highlighted color
;returns:   BX = selected choice (-1 if escape was pressed)
proc        HandleMenu
            mov [cs:@@BaseColor],al
            mov [cs:@@HighColor],ah

@@Update:   push si
            mov al,[cs:@@BaseColor]
            mov ah,[cs:@@HighColor]
            call DisplayMenu
            pop si

@@Wait:     mov ah,7
            int 21h
            cmp al,27       ;Escape
            jz @@Escape
            cmp al,13       ;Enter
            jz @@Quit
            cmp al,0
            jnz @@Wait
            mov ah,7
            int 21h
            cmp al,48h      ;Cursor-Up
            jz @@Up
            cmp al,50h      ;Cursor-Down
            jz @@Down
            jmp @@Wait
@@Up:       mov ax,[ds:si+offset (SelectorType).CurrentChoice]
            dec ax
            cmp ax,-1
            jg @@Up1
            mov ax,[ds:si+offset (SelectorType).NumItems]
            dec ax
@@Up1:      mov [ds:si+offset (SelectorType).CurrentChoice],ax
            jmp @@Update
@@Down:     mov ax,[ds:si+offset (SelectorType).CurrentChoice]
            inc ax
            cmp ax,[ds:si+offset (SelectorType).NumItems]
            jb @@Down1
            xor ax,ax
@@Down1:    mov [ds:si+offset (SelectorType).CurrentChoice],ax
            jmp @@Update

@@Escape:   mov bx,-1
            ret
@@Quit:     mov bx,[ds:si+offset (SelectorType).CurrentChoice]
            ret

@@BaseColor db  ?
@@HighColor db  ?
endp        HandleMenu
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
