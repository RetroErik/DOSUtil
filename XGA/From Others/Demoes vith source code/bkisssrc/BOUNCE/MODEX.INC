LABEL X320Y200 word
    db      00      ; 0e3h    ; dot clock
    db      02      ; Number of CRTC Registers to update
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      320     ; width
    dw      200     ; height

LABEL X320Y200s word
    db      0e3h    ; dot clock
    db      02      ; Number of CRTC Registers to update
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      320     ; width
    dw      200     ; height

LABEL X320Y240 word
    db      0e3h    ; dot clock
    db      10      ; Number of CRTC Registers to update
    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow (bit 8 of vertical counts)
    dw      04109h  ; cell height (2 to double-scan)
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      00014h  ; turn off dword mode
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      320     ; width
    dw      240     ; height

LABEL X360Y200 word
    db      0e7h    ; dot clock
    db      08      ; Number of CRTC Registers to update
    dw      06b00h  ; horz total
    dw      05901h  ; horz displayed
    dw      05a02h  ; start horz blanking
    dw      08e03h  ; end horz blanking
    dw      05e04h  ; start h sync
    dw      08a05h  ; end h sync
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      360     ; width
    dw      200     ; height

LABEL X360Y240 word
    db      0e7h    ; dot clock
    db      16      ; Number of CRTC Registers to update
    dw      06b00h  ; horz total
    dw      05901h  ; horz displayed
    dw      05a02h  ; start horz blanking
    dw      08e03h  ; end horz blanking
    dw      05e04h  ; start h sync
    dw      08a05h  ; end h sync
    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow (bit 8 of vertical counts)
    dw      04109h  ; cell height (2 to double-scan)
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      00014h  ; turn off dword mode
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      360
    dw      240

LABEL X376Y282 word
    db      0e7h
    db      18
    dw      06e00h  ; horz total
    dw      05d01h  ; horz displayed
    dw      05e02h  ; start horz blanking
    dw      09103h  ; end horz blanking
    dw      06204h  ; start h sync
    dw      08f05h  ; end h sync
    dw      06206h  ; vertical total
    dw      0f007h  ; overflow
    dw      06109h  ; cell height
    dw      0310fh  ;
    dw      03710h  ; v sync start
    dw      08911h  ; v sync end and protect cr0-cr7
    dw      03312h  ; vertical displayed
    dw      02f13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      03c15h  ; v blank start
    dw      05c16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      376
    dw      564

LABEL X320Y400 word
    db      00      ;0e3h    ; dot clock
    db      03      ; Number of CRTC Registers to update
    dw      04009h  ; cell height
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      320     ; width
    dw      400     ; height

LABEL X320Y480 word
    db      0e3h    ; dotclock
    db      10      ; Number of CRTC Registers to update
    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow (bit 8 of vertical counts)
    dw      04009h  ; cell height (2 to double-scan)
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      00014h  ; turn off dword mode
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      320     ; width
    dw      480     ; height

LABEL X360Y400 word
    db      0e7h    ; dot clock
    db      09      ; Number of CRTC Registers to update
    dw      06b00h  ; horz total
    dw      05901h  ; horz displayed
    dw      05a02h  ; start horz blanking
    dw      08e03h  ; end horz blanking
    dw      05e04h  ; start h sync
    dw      08a05h  ; end h sync
    dw      04009h  ; cell height
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      360     ; width
    dw      400     ; height


LABEL X360Y480 word
    db      0e7h
    db      17
    dw      06b00h  ; horz total
    dw      05901h  ; horz displayed
    dw      05a02h  ; start horz blanking
    dw      08e03h  ; end horz blanking
    dw      05e04h  ; start h sync
    dw      08a05h  ; end h sync
    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow
    dw      04009h  ; cell height
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      02d13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      360
    dw      480

LABEL X360Y360 word
    db      0e7h
    db      15
    dw      06b00h  ; horz total
    dw      05901h  ; horz displayed
    dw      05a02h  ; start horz blanking
    dw      08e03h  ; end horz blanking
    dw      05e04h  ; start h sync
    dw      08a05h  ; end h sync
    dw      04009h  ; cell height
    dw      08810h  ; v sync start
    dw      08511h  ; v sync end and protect cr0-cr7
    dw      06712h  ; vertical displayed
    dw      02d13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      06d15h  ; v blank start
    dw      0ba16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      360
    dw      360

LABEL X376Y308 word
    db      0e7h
    db      18
    dw      06e00h  ; horz total
    dw      05d01h  ; horz displayed
    dw      05e02h  ; start horz blanking
    dw      09103h  ; end horz blanking
    dw      06204h  ; start h sync
    dw      08f05h  ; end h sync
    dw      06206h  ; vertical total
    dw      00f07h  ; overflow
    dw      04009h  ;
    dw      0310fh  ;
    dw      03710h  ; v sync start
    dw      08911h  ; v sync end and protect cr0-cr7
    dw      03312h  ; vertical displayed
    dw      02f13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      03c15h  ; v blank start
    dw      05c16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      376
    dw      308

LABEL X376Y564 word
    db      0e7h
    db      18
    dw      06e00h  ; horz total
    dw      05d01h  ; horz displayed
    dw      05e02h  ; start horz blanking
    dw      09103h  ; end horz blanking
    dw      06204h  ; start h sync
    dw      08f05h  ; end h sync
    dw      06206h  ; vertical total
    dw      0f007h  ; overflow
    dw      06009h  ;
    dw      0310fh  ;
    dw      03710h  ; v sync start
    dw      08911h  ; v sync end and protect cr0-cr7
    dw      03312h  ; vertical displayed
    dw      02f13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      03c15h  ; v blank start
    dw      05c16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      376
    dw      564

LABEL X256Y240 word
    db      0e3h    ; dot clock
    db      16      ; Number of CRTC Registers to update

    dw      05f00h  ; horz total
    dw      03f01h  ; horz displayed
    dw      04002h  ;04202h  ; start horz blanking
    dw      0a003h  ;09f03h  ; end horz blanking
    dw      04f04h  ; start h sync
    dw      00405h  ; end h sync

    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow (bit 8 of vertical counts)
    dw      04109h  ; cell height (2 to double-scan)
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end

    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      256
    dw      240

LABEL X256Y70 word
    db      0e3h    ; dot clock
    db      16      ; Number of CRTC Registers to update

    dw      05f00h  ; horz total
    dw      03f01h  ; horz displayed
    dw      04002h  ;04202h  ; start horz blanking
    dw      0a003h  ;09f03h  ; end horz blanking
    dw      04f04h  ; start h sync
    dw      00405h  ; end h sync

    dw      00d06h  ; vertical total
    dw      03e07h  ; overflow (bit 8 of vertical counts)
    dw      04709h  ; cell height (8 to get blocky)
    dw      0ea10h  ; v sync start
    dw      0ac11h  ; v sync end and protect cr0-cr7
    dw      0df12h  ; vertical displayed
    dw      0e715h  ; v blank start
    dw      00616h  ; v blank end

    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      256
    dw      240

LABEL X256Y154 word
    db      0e3h    ; dot clock
    db      18      ; Number of CRTC Registers to update

    dw      05f00h  ; horz total
    dw      03f01h  ; horz displayed
    dw      04002h  ;04202h  ; start horz blanking
    dw      0a003h  ;09f03h  ; end horz blanking
    dw      04f04h  ; start h sync
    dw      00405h  ; end h sync

    dw      06206h  ; vertical total
    dw      00f07h  ; overflow
    dw      04109h  ; CELL HEIGHT
    dw      0310fh  ;
    dw      03710h  ; v sync start
    dw      08911h  ; v sync end and protect cr0-cr7
    dw      03312h  ; vertical displayed
    dw      02f13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      03c15h  ; v blank start
    dw      05c16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      256
    dw      308

LABEL X256Y282 word
    db      0e3h    ; dot clock
    db      18      ; Number of CRTC Registers to update

    dw      05f00h  ; horz total
    dw      03f01h  ; horz displayed
    dw      04002h  ;04202h  ; start horz blanking
    dw      0a003h  ;09f03h  ; end horz blanking
    dw      04f04h  ; start h sync
    dw      00405h  ; end h sync

    dw      06206h  ; vertical total
    dw      0f007h  ; overflow
    dw      06109h  ; cell height
    dw      0310fh  ;
    dw      03710h  ; v sync start
    dw      08911h  ; v sync end and protect cr0-cr7
    dw      03312h  ; vertical displayed
    dw      02f13h  ; offset
    dw      00014h  ; turn off dword mode
    dw      03c15h  ; v blank start
    dw      05c16h  ; v blank end
    dw      0e317h  ; turn on byte mode
    dw      256
    dw      564


LABEL X256Y200 word
    db      0e3h    ; dot clock
    db      8       ; Number of CRTC Registers to update
    dw      05f00h  ; horz total
    dw      03f01h  ; horz displayed
    dw      04002h  ; start horz blanking
    dw      0a003h  ; end horz blanking
    dw      04f04h  ; start h sync
    dw      00405h  ; end h sync
    dw      00014h  ; turn off dword mode
    dw      0e317h  ; turn on byte mode
    dw      256
    dw      200

LAST_X_MODE        =     17

LABEL ModeTable word    ; Mode X tweak table
    dw      offset X320Y200
    dw      offset X320Y240
    dw      offset X360Y200
    dw      offset X360Y240
    dw      offset X376Y282
    dw      offset X320Y400
    dw      offset X320Y480
    dw      offset X360Y400
    dw      offset X360Y480
    dw      offset X360Y360
    dw      offset X376Y308
    dw      offset X376Y564
    dw      offset X256Y240
    dw      offset X256Y200
    dw      offset X320Y200s
    dw      offset X256Y154
    dw      offset X256Y282
    dw      offset X256Y70

M320x200x256 =0     ;constants for easy calling
M320x240x256 =1
M360x200x256 =2
M360x240x256 =3
M376x282x256 =4
M320x400x256 =5
M320x480x256 =6
M360x400x256 =7
M360x480x256 =8
M360x360x256 =9
M376x308x256 =10
M376x564x256 =11
M256x240x256 =12    ;GREAT modes - ypos is upper byte, xpos is lower
M256x200x256 =13
M320x200x256s=14
M256x154x256 =15
M256x282x256 =16
M256x70x256 =17

InputStatus1=   3dah
Misc_Output =   3c2h
SC_Index    =   3c4h
CRTC_Index  =   3d4h
Graph_Index =   3ceh
Attr_Index  =   3c0h    ;don't forget to clear flipflop & set bit 5 on index
PEL_Write   =   3c8h
PEL_Read    =   3c7h
PEL_Data    =   3c9h

VGASeg          dw  0A000h      ;VGA refresh buffer segment
ModeXWidth      dw  0           ;physical width of current mode (in pixels)
ModeXHeight     dw  0           ;physical height of current mode (in pixels)
_Scrw           dw  0           ;logical width of current mode (in pixels)
ModeXLogWidth   dw  0           ;logical width of current mode (in bytes)
_Mode           dw  0           ;Mode X video number

MACRO @SetModeX DaMode,DaWidth
    mov     ax,DaMode
    mov     cx,DaWidth
    call    _Set_X_Mode
ENDM @SetModeX

;-----------------------------------------------------------------------
;
;   Sets mode # in AX, returns ax=0 if successful, ax=-1 if failed
;   cx= width of screen
;
; SetModeX Adapted for VLA by Draeden,
; Originally written by Themie Gouthas,
; who adapted parts from M. Abrash code.
; (Talk about code reuse!)
;------------------------------------------------------------------------
PROC _Set_X_Mode NEAR
    pusha
    push    es ds

    cld
    mov     bx,cs
    mov     ds,bx
    mov     es,bx

    cmp     ax,LAST_X_MODE      ; have we selected a valid mode?
    jle     @@ValidMode         ; Yes !

    pop     ds es
    popa
    mov     ax,-1               ; idiot.
    ret

@@ValidMode:
    mov     [_Mode],ax
    mov     [_Scrw],cx

    mov     ax,13h              ; let the BIOS set standard 256-color
    int     10h                 ;  mode (320x200 linear)

    mov     dx,SC_Index
    mov     ax,0604h
    out     dx,ax               ; disable chain4 mode
    mov     ax,0100h
    out     dx,ax               ; synchronous reset while setting Misc
                                ;  Output for safety, even though clock
                                ;  unchanged
    mov     bx,[_Mode]
    add     bx,bx
    mov     si,[bx + ModeTable]
    lodsb

    or      al,al
    jz      @@DontSetDot
    mov     dx,Misc_Output
    out     dx,al               ; select the dot clock and Horiz
                                ;  scanning rate
@@DontSetDot:
    mov     dx,SC_Index
    mov     ax,0300h
    out     dx,ax               ; undo reset (restart sequencer)

    mov     dx,CRTC_Index       ; reprogram the CRT Controller
    mov     al,11h              ; VSync End reg contains register write
    out     dx,al               ; protect bit
    inc     dx                  ; CRT Controller Data register
    in      al,dx               ; get current VSync End register setting
    and     al,07fh             ; remove write protect on various
    out     dx,al               ; CRTC registers
    dec     dx                  ; CRT Controller Index
    cld
    xor     cx,cx
    lodsb
    mov     cl,al

@@SetCRTParmsLoop:
    lodsw                       ; get the next CRT Index/Data pair
    out     dx,ax               ; set the next CRT Index/Data pair
    dec     cx
    jne     @@SetCRTParmsLoop

    lodsw
    mov     [cs:ModeXWidth],ax
    lodsw
    mov     [cs:ModeXHeight],ax

    mov     dx,SC_Index
    mov     ax,0f02h
    out     dx,ax               ; enable writes to all four planes

                                ; now clear all display memory, 8 pixels
    mov     es,[cs:VGASeg]      ; at a time
    sub     di,di               ; point ES:DI to display memory
    sub     ax,ax               ; clear to zero-value pixels
    mov     cx,8000h            ; # of words in display memory
    rep     stosw               ; clear all of display memory

    ;  Mode X is set, now set the required logical page width.

    mov     cx,[cs:_Scrw]
    shr     cx,2
    mov     [cs:ModeXLogWidth],cx
    shr     cx,1            ;divide by 8
    mov     dx,CRTC_Index
    mov     al,13h
    mov     ah,cl
    out     dx,ax

    pop     ds es
    popa
    xor     ax,ax
    ret
ENDP _Set_X_Mode

컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;*   MISC planar mode routines
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

    ;ah: 0000b : bit 0= plane 0, bit 1=plane 1, etc..
    ;
    ;DESTROYS: al, dx
    ;
MACRO  @Set_Write_Plane
    mov     dx,SC_Index
    mov     al,2
    and     ah,1111b
    out     dx,ax
ENDM   @Set_Write_Plane

    ;ah: plane to latch for read (0-3)
    ;
    ;DESTROYS: al, dx
    ;
MACRO  @Set_Read_Plane
    mov     dx,Graph_Index
    mov     al,4
    out     dx,ax
ENDM   @Set_Read_Plane

    ;ah: write mode (0-3)
    ;
    ;DESTROYS: ax, dx
    ;
MACRO @Set_Write_Mode
    mov     dx,Graph_Index
    mov     al,5
    out     dx,al
    inc     dx
    in      al,dx
    and     al,11111100b    ;clear out write mode bits
    and     ah,00000011b
    or      al,ah
    out     dx,al
ENDM  @Set_Write_Mode

    ;ah: Read mode (0-1)
    ;
    ;DESTROYS: ax, dx
    ;
MACRO @Set_Read_Mode
    mov     dx,Graph_Index
    mov     al,5
    out     dx,al
    inc     dx
    in      al,dx
    and     al,11110111b    ;clear out write mode bits
    shl     ah,3            ;move bit to correct position
    and     ah,00001000b
    or      al,ah
    out     dx,al
ENDM  @Set_Read_Mode

    ;bx: starting offset
    ;
    ;DESTROYS: ax, dx
    ;
MACRO @Set_Start_Offset
    mov     dx,CRTC_Index
    mov     al,0ch
    mov     ah,bh       ;write the HIGH byte
    out     dx,ax
    inc     al
    mov     ah,bl       ;write the LOW byte
    out     dx,ax
ENDM  @Set_Start_Offset

    ;ah = pelpan value
    ;
    ;DESTROYS: ax, dx
    ;
MACRO @Set_HPP
    mov     dx,InputStatus1
    in      al,dx           ;dummy input
    mov     dx,Attr_Index
    mov     al,33h
    out     dx,al
    mov     al,ah
    out     dx,al
ENDM

    ;DESTROYS: ax, dx   - sets pixel pan compatibility
    ;
MACRO @Set_PPC
    mov     dx,InputStatus1
    in      al,dx           ;dummy input
    mov     dx,Attr_Index
    mov     al,30h
    out     dx,al
    inc     dx
    in      al,dx
    dec     dx
    or      al,00100000b
    out     dx,al
ENDM

    ;bx: scanline to set split screen at
    ;
    ;DESTROYS: ax, dx
    ;
MACRO @Set_Split
    mov     al,18h
    mov     ah,bl
    mov     dx,CRTC_Index
    out     dx,ax       ;set bits 0-7

    mov     al,09h
    out     dx,al
    inc     dx
    in      al,dx
    mov     ah,bh
    and     ah,00000010b
    shl     ah,5
    and     al,10111111b
    or      al,ah
    out     dx,al       ;set bit 9

    dec     dx
    mov     al,07h
    out     dx,al
    inc     dx
    in      al,dx
    and     al,11101111b
    mov     ah,bh
    and     ah,00000001b
    shl     ah,4
    or      al,ah
    out     dx,al       ;set bit 8
ENDM @Set_Split

MACRO @FullVertWait
 LOCAL @@VR, @@NVR
    mov     dx,InputStatus1
@@VR:
    in      al,dx
    test    al,8
    jz      @@VR                    ;wait until Verticle Retrace starts
@@NVR:
    in      al,dx
    test    al,8
    jnz     @@NVR                   ;wait until Verticle Retrace Ends
ENDM @FullVertWait

MACRO @WaitVert
 LOCAL @@VR
    mov     dx,InputStatus1
@@VR:
    in      al,dx
    test    al,8
    jz      @@VR                    ;wait until Verticle Retrace starts
ENDM  @WaitVert

MACRO @WaitVertEnd
  LOCAL @@NVR
    mov     dx,InputStatus1
@@NVR:
    in      al,dx
    test    al,8
    jnz     @@NVR                   ;wait until Verticle Retrace Ends
ENDM  @WaitVertEnd

    ;si = offset to palette
    ;cx = number of colors to write
    ;al = starting palette register
    ;
    ;DESTROYS: dx,si,cx
    ;
MACRO @WritePalette
    mov     dx,cx
    add     cx,cx
    add     cx,dx
    mov     dx,03c8h
    out     dx,al
    inc     dx
    cld
    rep outsb
ENDM @WritePalette

    ;Changes the mode back to ModeX after a ResetLinear was called
MACRO @ResetModeX
    mov     dx,SC_Index
    mov     ax,0604h
    out     dx,ax               ; disable chain4 mode

    mov     dx,CRTC_Index
    mov     ax,00014h           ; turn off dword mode
    out     dx,ax
    mov     ax,0e317h           ; turn on byte mode
    out     dx,ax
ENDM

    ;changes from ModeX to normal linear mode
    ; only will work with an 320x200 screen w/ screenwidth of 80 bytes
MACRO @ResetLinear
    mov     dx,SC_Index
    mov     ax,0E04h
    out     dx,ax               ; enable chain4 mode

    mov     dx,CRTC_Index       ; reprogram the CRT Controller
    mov     ax,04014h           ; turn on dword mode
    out     dx,ax
    mov     ax,0a317h           ; turn off byte mode
    out     dx,ax
ENDM
