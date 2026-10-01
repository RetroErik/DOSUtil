;                             GUSMOD v2.10
;            By Joshua C. Jensen (CyberStrike of Renaissance)
;                        Copyright (C) 1992,1993
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

struc           PM
MusBuf          dd    ?
Header          dd      ?
PatternLoc      dd      ?
InsLoc          dd      ?
mt_speed        dw      ?
mt_counter      dw      ?
mt_SongPos      dw      ?
mt_PatternPos   dw      ?
ends            PM

struc   SampleRec
sname           db      16h dup (?)
length          dw      ?
volume          dw      ?
repeat          dw      ?
replen          dw      ?
ends    SampleRec

struc    PS16Sample
volume          dw    ?
length          dw      ?
repeat          dw      ?
replen          dw      ?
ends    PS16Sample

struc   HS
Sig             db    5 dup (?)
SongName        db    75 dup (?)
SongLen         db    ?
numpatterns     db    ?
commentofs      dd    ?
Sequences       db    128 dup (?)
Samples         db    31*size PS16Sample dup (?)
ends    HS

;ณ Original Amiga equates by Lars "Zap" Hamre.  Converted to IBM structure   ณ
;ณ by Joshua C. Jensen.                                                      ณ
struc           MS
note            db    ?
cmd             db      ?
cmdlo           db      ?
start           dd      ?
length          dd      ?
loopstart       dd      ?
replen          dd      ?
period          dw      ?
finetune        db      ?
volume          db      ?
toneportdirec   db      ?
toneportspeed   db      ?
wantedperiod    dw      ?
vibratocmd      db      ?
vibratopos      db      ?
tremolocmd      db      ?
tremolopos      db      ?
wavecontrol     db      ?
glissfunk       db      ?
sampleoffset    db      ?
pattpos         db      ?
loopcount       db      ?
funkoffset      db      ?
wavestart       dd      ?
reallength      dw      ?
MasterVolume    db      ?
SampleNum       db      ?
sc_Mode         db      ?
sc_PanPosition  db      ?
sc_Voice        db      ?
sc_Vol          dw      ?
sc_Note         dw      ?
DecVolume       db      ?
ends            MS

struc           SMus
HeaderLoc       dd      ?
PatternLoc      dd      ?
AnalyzerLoc     dd      ?
InsLoc          dd      ?
NumPatterns     dw      ?
mt_speed        db      ?
mt_counter      db      ?
mt_PatternPos   dw      ?
mt_SongPos      db      ?
songlen         db      ?
ChannelLoc      dd      ?
PlayStatus      db      ?
EditPat         dw      ?
EditSeg         dw      ?
EditOfs         dw      ?
MaxVolume       db      ?
mt_PeriodTable  dd      ?
ends            SMus

