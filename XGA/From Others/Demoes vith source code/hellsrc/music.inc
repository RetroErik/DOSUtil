≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±
; MASI Assembly .INC file               Copyright (C) 1992,93 Joshua C. Jensen
€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€
; Version 930808a.
≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Used for driver detection.
dcActive        = 0
dcInactive      = 1

dcEnd           = 0
dcPort          = 1
dcIRQ           = 2
dcMIDIPort      = 3
dcMIDIIRQ       = 4
dcDMAIn         = 5
dcDMAOut8       = 6
dcDMAOut16      = 7

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the function call values to the drivers.
Mus_Init                =  0
Mus_Close               =  1
Mus_Music               =  2
Mus_Sample              =  3
Mus_Speaker             =  4
Mus_Poll                =  5
Mus_ChangeVars          =  6
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the Mus_Music types.
PM_Play         =  1
PM_Pause        =  2
PM_Unpause      =  3
PM_Stop         =  4
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the Mus_Sample types.
Samp_Start      =  1
Samp_Stop       =  2
Samp_Volume     =  3
Samp_Pan        =  4
Samp_Process    =  5
Samp_Status     =  6
Samp_Freq       =  7
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the Mus_Speaker types.
SpeakerOn       =  1
SpeakerOff      =  2
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the S.stereoOn types.
PS_StereoOff    =  1
PS_StereoOn     =  2
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the S.musicBits types.
PS_8Bit         =  0
PS_16Bit        =  1
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the MStatus types.
PS_Playing      =  0
PS_Done         =  1
PS_Paused       =  2
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the loop types for the music (mt_PlayStatus).
PS_NoLoop       =  0
PS_Loop         =  1
PS_LoopPattern  =  2    ; UNSUPPORTED
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; These are the pattern break types (mt_PBreakFlag).
PB_None         =  0
PB_JumpLoop     =  1
PB_Break        =  2
PB_StartMusic   =  3
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; PSFH - The main PSM file header.
struc   PSFH
Sig             db      4 dup (?)
SongName        db      60 dup (?)
SongType        db      ?
SongVer         db      ?
PatternVersion  db      ?
DefaultSpeed    db      ?
DefaultBPM      db      ?
MasterVolume    db      ?
SongLen         dw      ?
NumOrders       dw      ?
NumPatterns     dw      ?
NumSamples      dw      ?
NumChannels     dw      ?
NumProcess      dw      ?
OrdersOfs       dd      ?
PanPosOfs       dd      ?
PatternsOfs     dd      ?
SamplesOfs      dd      ?
CommentOfs      dd      ?
TotalPatternSize dd     ?
Fillers         dd      10 dup (?)
ends    PSFH

struc   SampFH
SName           db      0Dh dup (?)     ; Sample filename.
SComment        db      18h dup (?)     ; Sample comment.
fOffset         dd      ?       ; Offset in file where sample begins.
MemoryLoc       dd      ?       ; Physical Location (RAM/DRAM) of sample in
                                ;  memory.
SampleNum       dw      ?       ; Sample Number.
SType           db      ?
                ; 7 6 5 4 3 2 1 0
                ; ≥ ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒ 0 - Digital, 1 - Synthesized
                ; ≥ ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒ Reserved
                ; ≥ ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒ 0 - 8-bit, 1 - 16-bit.
                ; ≥ ≥ ≥ ≥ ¿ƒƒƒƒƒƒƒ 0 - Signed, 1 - Unsigned
                ; ≥ ≥ ≥ ¿ƒƒƒƒƒƒƒƒƒ 0 - Deltas, 1 - Raw
                ; ≥ ≥ ¿ƒƒƒƒƒƒƒƒƒƒƒ 0 - Loop normally, 1 - Bidirectional
                ; ≥ ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒ 1 - Gravis patch (unsupported)
                ; ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ 0 - No loop, 1 - Loop sample
SLength         dd      ?       ; 0-1 meg
SRepStart       dd      ?       ; 0-SLength
SRepEnd         dd      ?       ; 0-1 meg
FineTune        db      ?       ; Has the pan position in the upper nibble
                ; from 0 - 15.  Since the fine tune is from 0 - 15, this
                ; fits perfectly.  The pan pos is only used if the note
                ; is greater than 60 (not supported).
Volume          db      ?       ; 0-64
C2Freq          dw      ?
ends    SampFH

struc   PatFH
PSize           dw      ?
NumLines        db      ?
NumChannels     db      ?
ends    PatFH

struc   SC
ioPort		dw	?	; card port
cardIRQ         dw      ?
midiIRQ         dw      ?
midiPort        dw      ?
dmaChannelIn    dw      ?
dmaChannelOut   dw      ?
dmaChannelOut16 dw      ?
SamplingRate    dw      ?       ; Sampling rate.
CallsPerSec     dw      ?       ; Calls per second.
mixvolloc       dd      ?       ; 4k/8k/16k volume table and 2-4k buffer.
typeofvol       dw      ?       ; 0 - 16k buffer (64 volume levels)
sizebuf         dw      ?       ; Size of mixing buffer.
stereoOn        dw      ?       ; 0 - Stereo Off (regardless of soundcard).
                                ; 1 - Stereo On (if possible).
musicBits       dw      ?       ; 0 - 8-bit
                                ; 1 - 16-bit
ends    SC

struc           pt_Offsets
pt_doramp       dd      ?
pt_volequ       dd      ?
pt_SetVoice     dd      ?
pt_PlayVol      dd      ?
pt_PlayNote     dd      ?
pt_PeriodSet    dd      ?
pt_PeriodSet2   dd      ?
pt_StartChannel dd      ?
pt_StartOver    dd      ?
pt_ExtTempo     dd      ?
ends            pt_Offsets

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; This structure is passed back to the main program from the PSM file loader.
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
struc           PSMStruc
PSM             PSFH    <>      ; The File Header.
OrdersLoc       dd      ?       ; The Orders Location in memory.
PanPosLoc       dd      ?       ; The Pan Position Location.
PatBigLoc       dd      ?       ; The beginning location that the patterns
        ; were loaded into.  This is provided as an easy way to quickly
        ; free ALL of the patterns.
        ;
        ; Size: PSFH.TotalPatternSize for freeing.
PatLoc          dd      ?       ; The Pattern Segment:Offsets Location.
        ; This points to a buffer of segments and offsets specifying the
        ; location of each pattern.
SampLoc         dd      ?       ; The Samples Location.
        ; This points to a buffer of segments and offsets specifying the
        ; location of each sample structure.
        ;
        ; Size:
MChannels       dd      ?
ends            PSMStruc

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; This structure is the primary music playing structure.
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
struc           PM
reserved        db      0 ; I-  ; 0-Off, 1-On
MStatus         db      0 ; -O  ; Music status
MaxVolume       db      0 ; IO  ; Max volume of song.
SongLen         dw      0 ; I-  ; Length of song, from PSFH.
NumChannels     dw      0 ; I-  ; Number of module channels to play.
ProcessChannels dw      0 ; I-  ; Number of module channels to process.
MaxChannels     dw      0 ; I-  ; Maximum channels to mix.
TruePanning     db      0 ; I-  ; Turns on balanced left/right panning (1-On)
OrdersLoc       dd      0 ; I-  ; Location of sequences in RAM.
SamplesLoc      dd      0 ; I-  ; Location of segment sample structures in RAM.
PatternsLoc     dd      0 ; I-  ; Location of the patterns segments.
ChannelsLoc     dd      0 ; I-  ; Location of channel MS structs = NumChannels.
Expansion       db      40 dup (0) ; Expansion room
                ;  Protracker specific stuff.
mt_BPM          db      0 ; IO  ; Default music BPM (Cmd G1).
mt_speed        db      0 ; IO  ; Current speed (Cmd G0).
mt_counter      db      0 ; IO  ; Current counter.
mt_SongPos      dw      0 ; IO  ; Current song position.
mt_PatternPos   dd      0 ; IO  ; Current pattern position segment and offset.
mt_PlayStatus   db      0 ; IO  ; Current playing status
mt_NumLines     dw      0 ; IO  ; Number of lines in this pattern.
mt_CurLine      dw      0 ; IO  ; Current pattern line we are on.
mt_PBreakFlag   db      0 ; IO  ; Pattern Break Flags
mt_PBreakPos    dw      0 ; IO  ; Line number to break to.
mt_PeriodTable  dd      0 ; -O  ; Location of the Period Table.
mt_LineBuf      dd      0 ; -O  ; Location of the Line Number Offset Table.
ends            PM

struc           MS
Note            db      0
Instrument      db      0
Data            db      0
Cmd             db      0
SType           db      0
Start           dd      0
SLength         dd      0
LoopStart       dd      0
LoopEnd         dd      0
ONote           db      0
PNote           db      0
Period          dw      0
Volume          db      0
FineTune        db      0
C2Freq          dw      0
VSlideDirec     db      0
VSlideSpeed     db      0
TonePortDirec   db      0
TonePortSpeed   db      0
WantedPeriod    dw      0
VibratoCmd      db      0
VibratoPos      db      0
TremoloCmd      db      0
TremoloPos      db      0
WaveControl     db      0
GlissFunk       db      0
MasterVolume    db      0
DecVolume       db      0
SampleNum       db      0
sc_Mode         db      0
sc_PanPosition  db      0
sc_Voice        db      0
sc_Vol          dw      0
sc_Note         dw      0
ends            MS

≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±
  ; Volume Commands
  cFineVolUp        = 01
  cVolSlideUp       = 02
  cFineVolDown      = 03
  cVolSlideDown     = 04

  ; Portamento Commands
  cFinePortaUp      = 10
  cPortaUp          = 11
  cFinePortaDown    = 12
  cPortaDown        = 13
  cTonePort         = 14
  cSetGliss         = 15
  cTPortVolUp       = 16
  cTPortVolDown     = 17

  ; Vibrato Commands
  cVibrato          = 20
  cSetVibWaveform   = 21
  cVibVolUp         = 22
  cVibVolDown       = 23

  ; Tremolo Commands
  cTremolo          = 30
  cSetTremControl   = 31

  ; Sample Offset Commands
  cSampleOffset     = 40
  cRetrigNote       = 41
  cNoteCut          = 42
  cNoteDelay        = 43

  ; Position Change Commands
  cPositionJump     = 50
  cPatternBreak     = 51
  cJumpLoop         = 52
  cPatternDelay     = 53

  ; Speed Change Commands
  cSetSpeed         = 60
  cSetBPM           = 61

  ; Misc. Commands
  cArpeggio         = 70
  cSetFineTune      = 71
  cSetBalance       = 72
≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±

segment         PTSeg
global          PT_MUS:proc
ends            PTSeg

segment         SBSeg
global          SB_MUS:proc
ends            SBSeg

segment         GUSSeg
global          GUS_MUS:proc
ends            GUSSeg

segment         PSMLoaderSeg

global          Loader_MUS:proc

ends            PSMLoaderSeg
