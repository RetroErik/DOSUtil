;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
Header:
MODsongname     db      20 dup (?)
MODsamples      db      31*size SampleRec dup (?)
MODsonglen      db      ?
MODrestart      db      ?
MODsequences    db      128 dup (?)
MODsignature    dd      ?
HeaderSize      =       $-Header
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SigCopy         db      'PS16þ'
PS16Header:
Sig             db      'PS16þ'
SongName        db      75 dup (0)
SongLen         db      0
numpatterns     db      0
commentofs      dd      0
Sequences       db      128 dup (0)
Samples         db      31*size PS16Sample dup (0)
PS16Size        =       $-PS16Header
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PatternLoc      dw      64 dup (0)
InsLoc          dd      32 dup (0)
Handle          dw      0
ModSegment      dw      0
ModLoaded       dw      0
TopOfData       dw      0
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;               DS:DX ==> ASCIIZ filename to load
;returns:       CARRY on error
proc            MUS_LoadModule near
                pusha
                push    ds es

                cmp [cs:ModLoaded],0
                jnz @@Error

                mov     ax,3D00h
                int     21h
                jc      @@Error
                mov     [cs:Handle],ax

                ;set [TopOfData] to the segment of the largest piece
                ;of memory possible. (we'll trim it down later)
                mov ah,48h
                mov bx,0FFFFh
                int 21h
                mov ah,48h
                int 21h
                mov [cs:TopOfData],ax
                mov [cs:ModSegment],ax

                mov     ax,cs
                mov     ds,ax
                mov     es,ax
                call    MUS_ReadMod

                ;trim down on the amount of memory needed
                mov ah,4Ah
                mov bx,[cs:TopOfData]
                sub bx,[cs:ModSegment]
                add bx,2
                mov es,[cs:ModSegment]
                int 21h

                mov [cs:ModLoaded],1

                mov     ah,3Eh
                mov     bx,[cs:Handle]
                int     21h
@@Exit:         pop     es ds
                popa
                clc
                ret

@@Error:        pop es ds
                popa
                stc
                ret
endp            MUS_LoadModule
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;returns:       CARRY set on error
proc            MUS_FreeModule
                cmp [cs:ModLoaded],0
                jz @@Error

                mov ah,49h
                mov es,[cs:ModSegment]
                int 21h
                mov [cs:ModLoaded],0

                clc
                ret
@@Error:        stc
                ret
endp            MUS_FreeModule
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc            MUS_ConvertHeader
                ; Clear Header
                pusha
                push    ds
                mov     ax,cs
                mov     ds,ax
                mov     es,ax
                mov     di,offset PS16Header
                mov     al,0
                mov     cx,PS16Size
                rep     stosb

                mov     si,offset SigCopy
                mov     di,offset Sig
                mov     cx,5
                rep     movsb
                mov     si,offset MODsongname
                mov     di,offset SongName
                mov     cx,20
                rep     movsb
                mov     al,26
                stosb
                mov     al,[MODsonglen]
                mov     [SongLen],al
                mov     si,offset MODsequences
                mov     di,offset Sequences
                mov     cx,128
                rep     movsb

                mov     bp,31
                mov     si,offset MODsamples+(offset (SampleRec).length)
                mov     di,offset Samples
@@FlipLoop:     mov     ax,[si+4]
                xchg    ah,al
                mov     cx,ax
                mov     bx,[si+6]
                xchg    bh,bl
                add     ax,bx
                mov     dx,[si]
                xchg    dh,dl
                cmp     ax,dx
                jbe     @@OKRepeat
                shr     cx,1
@@OKRepeat:     shl     dx,1
                mov     [di+PS16Sample.length],dx
                mov     ax,[si+2]
                mov     [di+PS16Sample.volume],ax
                shl     bx,1
                mov     [di+PS16Sample.replen],bx
                shl     cx,1
                mov     [di+PS16Sample.repeat],cx
@@OKSample:     add     si,size SampleRec
                add     di,size PS16Sample
                dec     bp
                jne     @@FlipLoop
                pop     ds
                popa
                ret
endp            MUS_ConvertHeader
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
LocInList       dw      ?
proc            MUS_ReadMod near
                push    ds
                mov     ax,3F00h                ; Read the header
                mov     bx,[cs:Handle]
                mov     dx,offset Header
                mov     cx,HeaderSize
                int     21h

                cmp     [Word cs:MODsignature],'.M'
                jnz     @@CheckFLT4
                cmp     [Word cs:MODsignature+2],'.K'
                jz      @@31Ins
@@CheckFLT4:    cmp     [Word cs:MODsignature],'LF'
                jnz     @@15Ins
                cmp     [Word cs:MODsignature+2],'4T'
                jz      @@31Ins
@@15Ins:        mov     si,offset Header+20+15*30
                mov     di,offset MODsonglen
                mov     cx,134
                rep     movsb
                mov     di,offset Header+20+15*30
                mov     cx,16*30
                mov     al,0
                rep     stosb
                mov     ax,4200h
                mov     bx,[cs:Handle]
                mov     cx,0
                mov     dx,258h
                int     21h

@@31Ins:        call    MUS_ConvertHeader
                call    MUS_LoadPatterns
                mov     cx,31
                mov     bx,offset MODsamples+(offset (SampleRec).length)
@@FlipLoop:
                mov     dx,[cs:bx]      ; Flip length
                xchg    dh,dl
                shl     dx,1
                mov     [cs:bx],dx
                mov     ax,[cs:bx+6]    ; Flip repeat length
                xchg    ah,al
                shl     ax,1
                mov     [cs:bx+6],ax
                mov     ax,[cs:bx+4]    ; Flip repeat
                xchg    ah,al
                shl     ax,1
                mov     [cs:bx+4],ax
@@OKSample:     add     bx,size SampleRec
                loop    @@FlipLoop

                mov     cx,31
                mov     bx,offset MODsamples+(offset (SampleRec).length)
                mov     [Word cs:LocInList],0
                mov     si,0            ; Location in DRAM to begin
                mov     di,0
@@DoSamples:    push    cx
                mov     ax,[cs:bx]
                or      ax,ax
                jz      @@ZeroByteSample
                mov     cx,ax           ; Save for read from disk.
                push    bx
                mov     bx,[cs:LocInList]
                mov     [Word cs:bx+InsLoc],di
                mov     [Word cs:bx+InsLoc+2],si
                add     [Word cs:LocInList],4
                mov     ax,[cs:Handle]
                mov     dx,[cs:TopOfData]
                mov     bx,0Dh
                call    [dword ptr cs:Music]
                pop     bx
                jmp     @@Bottom
@@ZeroByteSample:
                push    bx
                mov     bx,[cs:LocInList]
                mov     [Word cs:bx+InsLoc],0
                mov     [Word cs:bx+InsLoc+2],0f000h
                add     [Word cs:LocInList],4
                pop     bx
@@Bottom:       add     bx,size SampleRec
                pop     cx
                loop    @@DoSamples
@@Skip:         
                pop     ds
                ret
endp            MUS_ReadMod
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
proc            MUS_GetHighestBlock near
                mov     si,offset MODsequences
                mov     cx,128
                xor     ax,ax
@@SetBlock:     mov     ah,al
                jmp     @@BotLoop
@@SearchLoop:   lodsb
                cmp     al,ah
                jg      @@SetBlock
@@BotLoop:      loop    @@SearchLoop
                mov     al,ah
                inc     al
                xor     ah,ah                   ; Clear ah.
                ret
endp            MUS_GetHighestBlock
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
MUS_Match       dw      1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,912
                dw      856,808,762,720,678,640,604,570,538,508,480,453
                dw      428,404,381,360,339,320,302,285,269,254,240,226
                dw      214,202,190,180,170,160,151,143,135,127,120,113
                dw      107,101,95,90,85,80,75,71,67,63,60,56,0
proc            MUS_LoadMatcher
                mov     ax,[si]
                xchg    ah,al
                and     ax,0FFFh
                or      ax,ax
                jz      @@Done
                mov     bx,offset MUS_Match
                mov     cx,0
@@NoteMatcher:  cmp     ax,[cs:bx]
                jae     @@Found
                add     bx,2
                inc     cx
                cmp     cx,61
                jnz     @@NoteMatcher
                mov     ax,0
                ret
@@Found:        mov     ax,cx
                inc     ax
@@Done:         ret
endp            MUS_LoadMatcher
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PatSeg          dw      0
Buf4            dw      0
proc            MUS_LoadPatterns near
                mov     cx,64
                mov     di,offset PatternLoc
                xor     ax,ax
                rep     stosw

                call    MUS_GetHighestBlock
                mov     [cs:numpatterns],al
                mov     ax,[cs:TopOfData]
                sub     ax,4096/16
                mov     [cs:PatSeg],ax
                add     ax,1024/16
                mov     [cs:Buf4],ax
                mov     es,ax

                mov     si,offset PatternLoc
                mov     cx,0
@@BlockReadLoop:
                push    cx si
                mov     cx,1024
                mov     bx,[cs:Handle]
                mov     ax,[cs:PatSeg]
                mov     ds,ax
                xor     dx,dx
                mov     ax,3F00h                ; Load in the block.
                int     21h
                mov     cx,0                    ; Channels
                mov     di,0
                mov     ax,[cs:Buf4]
                mov     es,ax
                mov     ax,0
                stosw
                mov     al,64
                stosb
@@ChannelLoop:  push    cx
                mov     si,0
                shl     cx,2
                add     si,cx
                mov     cx,0
@@LineLoop:     push    cx
                cmp     [Word si],0
                jnz     @@ItsThere
                cmp     [Word si+2],0
                jz      @@NothingSkip
@@ItsThere:     mov     al,cl
                stosb
                call    MUS_LoadMatcher
                mov     bl,[si]
                and     bl,0F0h
                shl     bl,2
                or      al,bl
                stosb
                mov     ax,[si+2]
                stosw
@@NothingSkip:  pop     cx
                add     si,16
                inc     cx
                cmp     cx,64
                jnz     @@LineLoop
                mov     al,-1
                stosb
                pop     cx
                inc     cx
                cmp     cx,4
                jnz     @@ChannelLoop
                mov     cx,4
@@CLoop:        mov     al,-1
                stosb
                inc     cx
                cmp     cx,16
                jnz     @@CLoop
                mov     bx,di
                mov     di,0
                mov     cx,bx
                mov     ax,bx
                stosw
                shr     bx,4
                inc     bx
                pop     si
                push    si
                mov     ax,[cs:TopOfData]
                mov     [cs:si],ax
                add     [Word cs:TopOfData],bx
                push    ds
                mov     ax,es
                mov     ds,ax
                mov     ax,[cs:si]
                mov     es,ax
                mov     di,0
                mov     si,0
                rep     movsb
                pop     ds
                pop     si cx
                add     si,2
                inc     cx
                cmp     cl,[cs:numpatterns]
                jnz     @@BlockReadLoop
                clc
                ret
endp            MUS_LoadPatterns
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
