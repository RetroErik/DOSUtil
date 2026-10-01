ideal
locals
jumps
p386
model huge
stack 100h


segment     MyCode
            assume cs:MyCode
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
struc       DemoEXEname
Exename     db 13 dup(0)
ends        DemoEXEname
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       HandleError errormessage
            local @@Label
            jnc @@Label
            mov [ErrorFlag],offset errormessage
            jmp AllDone
@@Label:    exitm
endm        HandleError
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "XDETECT.ASM"
include     "MENUS.INC"
include     "PALETTE.INC"
include     "EXECUTE.INC"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
extrn       LoaderFont:byte
extrn       Farewell:byte
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
include     "MUSGUS.INC"
include     "MUSGUS.ASM"
include     "MODLOAD.ASM"
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
NormalAttr  = 1*16+15
HighAttr    = 0*16+15
ErrorFlag   DW 0        ;set to offset of error message and jump to AllDone
ErrorNoVGA  DB 'This demo requires a system with a VGA card installed.',0Dh,0Ah,'$'
ErrorNo386  DB 'This demo requires a system with at least a 386SX processor.',0Dh,0Ah,'$'
ErrorEXE    DB 'Error executing part of demo.',0Dh,0Ah,'$'
ErrorMOD    DB 'Error loading the music file.',0Dh,0Ah,'$'
ErrorMusic  DB 'Error initializing music system.',0Dh,0Ah,'$'
ExeNames    DemoEXEname <'SLIDETXT.EXE'>
            DemoEXEname <'TITLE.EXE'>
            DemoEXEname <'BOUNCE.EXE'>
            DemoEXEname <'CANCEL.EXE'>
            DemoEXEname <'STRETCH.EXE'>
            DemoEXEname <'IRIS.EXE'>
            DemoEXEname <'SINUS.EXE'>
            DemoEXEname <'TUNNEL.EXE'>
            DemoEXEname <'CREDITS.EXE'>
            db 0
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        Start
            ;mov     bx,ss                   ; Shrink Program Segment
            ;mov     ax,es
            ;sub     bx,ax
            ;mov     ax,sp
            ;shr     ax,4
            ;inc     ax
            ;add     bx,ax
            mov bx,64000/16
            mov     ah,4Ah
            int 21h
            mov ax,MyCode                   ;\ set DS to CS
            mov ds,ax                       ;/
            call _x_graphics_card           ;\
            cmp ax,VGAMono                  ; > check for VGA
            HandleError ErrorNoVGA          ;/
            call _x_processor               ;\
            cmp ax,i386sx                   ; > check for 386
            HandleError ErrorNo386          ;/
            call fade_out                   ;fade out the display
            mov ax,0003h                    ;\ change to text mode
            int 10h                         ;/
            mov ax,1100h                    ;\
            mov bx,1000h                    ; \
            mov cx,256                      ;  \
            mov dx,0                        ;   \ load in our special font
            mov bp,cs                       ;   /
            mov es,bp                       ;  /
            mov bp,offset LoaderFont        ; /
            int 10h                         ;/
            mov ah,01h                      ;\
            mov cx,2607h                    ; > turn off the cursor
            int 10h                         ;/
            call GetVideoSegment            ;set ES to the video segment
            mov di,0                        ;\
            mov al,'°'                      ; \
            mov ah,2*16+10                  ;  \ display a block background
            cld                             ;  /
            mov cx,80*25                    ; /
            rep stosw                       ;/
            mov si,offset MessageMsg        ;\
            mov al,3*16+11                  ; \ display our message
            mov ah,3*16+15                  ; /
            call DisplayMenu                ;/
            
            ;*** Prompt user for output device ***
            mov si,offset Soundcard
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            mov [_Soundcard],bx
            shl bx,1
            jmp [word Soundcards+bx]
ENDP        Start
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        SB_only
            ;*** Prompt user for Sound Blaster port ***
            mov si,offset SB_port
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[SB_ports+bx]
            mov [_SB_port],ax

            ;*** Prompt user for Sound Blaster IRQ number ***
            mov si,offset SB_IRQ
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[SB_IRQs+bx]
            mov [_SB_IRQ],ax

            ;*** Prompt user for Mixing rate ***
Non_GUS:    mov si,offset Replay_Rate
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[Replay_Rates+bx]
            mov [_Replay_Rate],ax

            ;*** Fade out the setup screen ***
            call fade_out

            ;*** Initialize the correct sound device ***
            mov ax,seg SOUNDDEVICE
            mov es,ax
            mov ax,[_Soundcard]         ;\
            dec ax                      ; > set the playback device
            mov [es:SOUNDDEVICE],ax     ;/
            mov ax,[_Replay_Rate]       ;\ set the mixing speed
            mov [es:TIMERSPEED],ax      ;/
            ;mov ax,[_SB_DMA]           ;\ set the DMA
            ;mov [es:SBDMA],ax          ;/
            mov ax,[_SB_IRQ]            ;\ set IRQ number
            mov [es:SBIRQNR],ax         ;/
            mov ax,[_SB_port]           ;\ set the baseport
            mov [es:SBPORT],ax          ;/
            mov [es:MASTERVOLUME],64    ;set the initial volume
            call INITIALIZE
            mov dx,offset ModName       ;\
            call LOADMODULE             ; > load in the module
            HandleError ErrorMOD        ;/
            call STARTPLAYING

            ;*** Run the demo ***
            call DoDemo

            ;*** Deinitialize ourself ***
            push ds
            mov ax,seg SOUNDDEVICE
            mov es,ax
@@DecVol:   WaitForRetrace
            WaitForRetrace
            cmp [es:MASTERVOLUME],0
            jz @@DecVol2
            dec [es:MASTERVOLUME]
            jmp @@DecVol
@@DecVol2:  call STOPPLAYING
            call DEALLOC

            ;*** Quit ***
            jmp AllDone
ENDP        SB_only
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        GUS_only
            ;*** Prompt user for Ultrasound port ***
            mov si,offset GUS_port
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[GUS_ports+bx]
            mov [_GUS_port],ax

            ;*** Prompt user for IRQ number ***
            mov si,offset GUS_IRQ
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[GUS_IRQs+bx]
            mov [_GUS_IRQ],ax

            ;*** Prompt user for MIDI IRQ number ***
            mov si,offset GUS_MIDI
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[GUS_MIDIs+bx]
            mov [_GUS_MIDI],ax

            ;*** Prompt user for DMA in ***
            mov si,offset GUS_DMAin
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[GUS_DMAins+bx]
            mov [_GUS_DMAin],ax
            
            ;*** Prompt user for DMA out ***
            mov si,offset GUS_DMAout
            mov al,NormalAttr
            mov ah,HighAttr
            call HandleMenu
            cmp bx,-1
            jz AllDone
            shl bx,1
            mov ax,[GUS_DMAouts+bx]
            mov [_GUS_DMAout],ax
            
            ;*** Fade out the setup screen ***
            call fade_out

            ;*** Initialize ourself ***
            ;load in the MUSGUS driver
            call MUS_LoadSoundDriver
            HandleError ErrorMusic

            ;initialize the driver with the GUS settings
            mov ax,[_GUS_IRQ]
            mov cx,[_GUS_MIDI]
            mov dx,[_GUS_port]
            mov si,[_GUS_DMAin]
            mov di,[_GUS_DMAout]
            mov bx,0
            call [dword ptr Music]
            HandleError ErrorMusic

            ;set the initial volume
            call MUS_GetInfo
            mov [byte offset MMus+offset (SMus).MaxVolume],128
            call MUS_SetInfo

            ;load in the module
            mov ax,cs
            mov ds,ax
            mov dx,offset ModName
            call MUS_LoadModule
            HandleError ErrorMOD

            ;start playback
            mov ax,[word MusBuf+0]
            mov [Word offset PM_struc+0+offset (PM).MusBuf],ax
            mov ax,[word MusBuf+2]
            mov [Word offset PM_struc+2+offset (PM).MusBuf],ax
            mov [Word offset PM_struc+0+offset (PM).Header],offset PS16Header
            mov [Word offset PM_struc+2+offset (PM).Header],cs
            mov [Word offset PM_struc+0+offset (PM).PatternLoc],offset PatternLoc
            mov [Word offset PM_struc+2+offset (PM).PatternLoc],cs
            mov [Word offset PM_struc+0+offset (PM).InsLoc],offset InsLoc
            mov [Word offset PM_struc+2+offset (PM).InsLoc],cs
            mov [Word offset PM_struc+offset (PM).mt_speed],6
            mov [Word offset PM_struc+offset (PM).mt_counter],5
            mov [Word offset PM_struc+offset (PM).mt_PatternPos],0
            mov [Word offset PM_struc+offset (PM).mt_SongPos],0
            mov cx,cs
            mov si,offset PM_struc
            mov bx,4
            call [dword Music]

            ;*** Run the demo ***
            call DoDemo

            ;*** Deinitialize ourself ***
            mov ax,[word Music+0]
            or ax,[word Music+2]
            jz @@DontFade
@@DecVol:   call MUS_GetInfo
            dec [Byte offset MMus+offset (SMus).MaxVolume]
            call MUS_SetInfo
            WaitForRetrace
            cmp [Byte offset MMus+offset (SMus).MaxVolume],0
            ja @@DecVol

@@DontFade: call MUS_FreeModule
            call MUS_FreeSoundDriver

            ;*** Quit ***
            jmp AllDone
ENDP        GUS_only
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        No_Music
            ;*** Fade out the setup screen ***
            call fade_out

            ;*** Run the demo ***
            call DoDemo

            ;*** Quit ***
            jmp AllDone
ENDP        No_Music
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        DoDemo
            mov [@@Filename],offset ExeNames
@@ExeLoop:  mov ax,0C00h                    ;\ clear the keyboard buffer
            int 21h                         ;/
            mov ax,cs                       ;\
            mov ds,ax                       ; \ execute the section
            mov dx,[@@Filename]             ; /
            call ExecuteProgram             ;/
            mov [ErrorFlag],offset ErrorEXE
            jc @@Quit
            add [@@Filename],size DemoEXEname
            mov si,[@@Filename]
            cmp [byte si],0
            jnz @@ExeLoop
            mov [ErrorFlag],0
            mov ax,0003h                    ;\ change back to text mode
            int 10h                         ;/
            mov ah,01h                      ;\
            mov cx,2607h                    ; > turn off the cursor
            int 10h                         ;/
@@Quit:     ret
@@Filename  dw ?
ENDP        DoDemo
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        AllDone
            mov ax,0003h                    ;\ change back to text mode
            int 10h                         ;/
            call GetVideoSegment            ;set ES to the video segment
            mov ax,cs                       ;\
            mov ds,ax                       ; \
            mov si,offset Farewell          ;  \
            xor di,di                       ;   > display our leaving message
            mov cx,4000                     ;  /
            cld                             ; /
            rep movsb                       ;/
            mov ah,2                        ;\
            xor bh,bh                       ; \
            mov dh,22                       ;  > position the cursor
            xor dl,dl                       ; /
            int 10h                         ;/
            cmp [ErrorFlag],0               ;\
            jz @@Quit                       ; \
            mov ah,9                        ;  \
            mov dx,cs                       ;   > display an error message
            mov ds,dx                       ;  / (if needed)
            mov dx,[ErrorFlag]              ; /
            int 21h                         ;/
@@Quit:     mov ax,4C00h                    ;\ terminate program
            int 21h                         ;/
ENDP        AllDone
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;related to playing the music
ModName     db 'NEVER.MOD',0
_Soundcard  dw ?
_SB_port    dw 220h
_SB_IRQ     dw 7
_SB_DMA     dw 1
_Replay_Rate dw ?
_GUS_port   dw ?
_GUS_IRQ    dw ?
_GUS_MIDI   dw ?
_GUS_DMAin  dw ?
_GUS_DMAout dw ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;related to the sound output selection menus
MessageMsg  SelectorType <18,45,3,0>
            DefineTitle 30,""
            CenterString 30,"Bytes & Kisses"
            CenterString 30,"Version 1.0"
            CenterString 30,""
Soundcard   SelectorType <5,5,10,0>
            DefineTitle 30,"Sound Output Device"
            CenterString 30,"No digital output  (Nothing)"," "
            CenterString 30,"Gravis Ultrasound   (Stereo)"," "
            CenterString 30,"Mono DAC on LPT1      (Mono)"," "
            CenterString 30,"Mono DAC on LPT2      (Mono)"," "
            CenterString 30,"Sound Blaster         (Mono)"," "
            CenterString 30,"Internal speaker      (Mono)"," "
            CenterString 30,"DAC on LPT1+LPT2    (Stereo)"," "
            CenterString 30,"Sound Blaster Pro   (Stereo)"," "
            CenterString 30,"Stereo DAC on LPT1  (Stereo)"," "
            CenterString 30,"Stereo DAC on LPT2  (Stereo)"," "
Soundcards  dw No_Music,GUS_only,Non_GUS,Non_GUS,SB_only,Non_GUS,Non_GUS
            dw SB_only,Non_GUS,Non_GUS
SB_port     SelectorType <3,35,7,1>
            DefineTitle 25,"Sound Blaster Port"
            CenterString 25,"210h"," "
            CenterString 25,"220h"," "
            CenterString 25,"230h"," "
            CenterString 25,"240h"," "
            CenterString 25,"250h"," "
            CenterString 25,"260h"," "
            CenterString 25,"270h"," "
SB_ports    dw 210h,220h,230h,240h,250h,260h,270h
SB_IRQ      SelectorType <14,25,2,1>
            DefineTitle 25,"Sound Blaster IRQ"
            CenterString 25,"IRQ 5"," "
            CenterString 25,"IRQ 7"," "
SB_IRQs     dw 5,7
Replay_Rate SelectorType <7,45,11,0>
            DefineTitle 30,"Select Replay Rate"
            CenterString 30," 4000 Hz     (real slow)"," "
            CenterString 30," 8000 Hz           (286)"," "
            CenterString 30,"12000 Hz           (286)"," "
            CenterString 30,"16000 Hz      (some 286)"," "
            CenterString 30,"20000 Hz      (some 286)"," "
            CenterString 30,"24000 Hz      (some 286)"," "
            CenterString 30,"28000 Hz           (386)"," "
            CenterString 30,"32000 Hz           (386)"," "
            CenterString 30,"36000 Hz      (some 386)"," "
            CenterString 30,"44100 Hz      (some 386)"," "
            CenterString 30,"62799 Hz  (some 386/486)"," "
Replay_Rates dw 298,149,99,74,60,50,43,37,33,27,19
GUS_port    SelectorType <3,40,6,1>
            DefineTitle 25,"Ultrasound Port"
            CenterString 25,"210h"," "
            CenterString 25,"220h"," "
            CenterString 25,"230h"," "
            CenterString 25,"240h"," "
            CenterString 25,"250h"," "
            CenterString 25,"260h"," "
GUS_ports   dw 210h,220h,230h,240h,250h,260h
GUS_IRQ     SelectorType <10,17,7,4>
            DefineTitle 25,"Ultrasound IRQ"
            CenterString 25,"IRQ 2"," "
            CenterString 25,"IRQ 3"," "
            CenterString 25,"IRQ 5"," "
            CenterString 25,"IRQ 7"," "
            CenterString 25,"IRQ 11"," "
            CenterString 25,"IRQ 12"," "
            CenterString 25,"IRQ 15"," "
GUS_IRQs    dw 2,3,5,7,11,12,15
GUS_MIDI    SelectorType <14,35,7,3>
            DefineTitle 30,"Ultrasound MIDI IRQ"
            CenterString 30,"IRQ 2"," "
            CenterString 30,"IRQ 3"," "
            CenterString 30,"IRQ 5"," "
            CenterString 30,"IRQ 7"," "
            CenterString 30,"IRQ 11"," "
            CenterString 30,"IRQ 12"," "
            CenterString 30,"IRQ 15"," "
GUS_MIDIs   dw 2,3,5,7,11,12,15
GUS_DMAin   SelectorType <10,45,5,4>
            DefineTitle 30,"Ultrasound DMA in"
            CenterString 30,"DMA 1"," "
            CenterString 30,"DMA 3"," "
            CenterString 30,"DMA 5"," "
            CenterString 30,"DMA 6"," "
            CenterString 30,"DMA 7"," "
GUS_DMAins  dw 1,3,5,6,7
GUS_DMAout  SelectorType <15,15,5,4>
            DefineTitle 30,"Ultrasound DMA out"
            CenterString 30,"DMA 1"," "
            CenterString 30,"DMA 3"," "
            CenterString 30,"DMA 5"," "
            CenterString 30,"DMA 6"," "
            CenterString 30,"DMA 7"," "
GUS_DMAouts dw 1,3,5,6,7
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ends        MyCode
include     "GOLDPLAY.INC"
            end Start
