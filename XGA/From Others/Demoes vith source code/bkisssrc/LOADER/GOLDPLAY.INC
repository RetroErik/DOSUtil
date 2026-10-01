;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; The Externals
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�


SEGMENT _MODPLAY 'MODPLAYSEG'
;Procedures

EXTRN  INITIALIZE:FAR            ; Initializes the modplayer for given
                                 ; sounddevice and replayrate

EXTRN  LOADMODULE:FAR            ; Loads the Module into memory

EXTRN  STARTPLAYING:FAR          ; Starts playing the module

EXTRN  STOPPLAYING:FAR           ; Stops playing the module

EXTRN  DEALLOC:FAR               ; Deallocates and erases the module
                                 ; from memory

EXTRN  ASKINIT:FAR

;Variables

EXTRN  SOUNDDEVICE:WORD          ; The Sounddevice number

EXTRN  TIMERSPEED:WORD           ; The replayrate 1193182/Hertz

EXTRN  SBDMA:WORD                ; SoundBlaster's DMA-Channel

EXTRN  SBIRQNR:WORD              ; SoundBlaster's IRQ-Number

EXTRN  SBPORT:WORD

;Special_Variables

EXTRN  BAR1,BAR2,BAR3,BAR4:WORD  ; Selfdecrementing Bars, see the docs

EXTRN  SHOWPATTERNS:Word         ; Shows the patterns

EXTRN  MASTERVOLUME:Word         ; Mastervolume from 0 to 64
ENDS    _MODPLAY
