;**********************************
;* FLamoot VGA SetUp include file *
;**********************************

EXTRN _SetVGA: FAR

;*** GFX-mode structure *** 

mode RECORD hgh:5, ver:3, hor:3, col:2, adr:2
;
; rem:   hgh = line doubling factor
;        ver = 0 --> 350 lines display     hor = 0 --> 128 horiz width
;              1     400 big                     1     160
;              2     400                         2     180
;              3     400 60hz                    3     256
;              4     448                         4     320
;              5     480                         5     360
;              6     512                         
;              7     540
;        col = 0 --> 256 colors display    adr = 0 --> planar scheme (X-mode)
;              1     16                          1 --> chained
;              2     4                           2 --> cga
;              3     text 16                     3 --> mono
;
; PS: if you choose a 16 colors display, the horiz width is doubled !!!!!

; predefined modes ....
;-----------------------
m160x67x256c      EQU mode<5,2,1,0,1>  ; 7-mode like
m160x70x256c      EQU mode<4,0,1,0,1>  ; 7-mode like
m160x80x256c      EQU mode<4,2,1,0,1>  ; 7-mode like
m160x100x256c     EQU mode<3,2,1,0,1>  ; 7-mode
m160x200x256p60hz EQU mode<1,3,1,0,0>  ; 7-mode like
m320x67x256c      EQU mode<5,2,4,0,1>
m320x70x256c      EQU mode<4,0,4,0,1>
m320x80x256c      EQU mode<4,2,4,0,1>
m320x100x256c     EQU mode<3,2,4,0,1>
m320x200x256c     EQU mode<1,2,4,0,1>
m320x200x256c60hz EQU mode<1,3,4,0,1>
m320x200x256p60hz EQU mode<1,3,4,0,0>
m320x400x256p     EQU mode<0,2,4,0,0>
m320x400x256pbig  EQU mode<0,1,4,0,0>
m320x480x256p     EQU mode<0,5,4,0,0>

;misc. examples
;--------------
m320x200x256p EQU mode<1,2,4,0,0>
m320x240x256p EQU mode<1,5,4,0,0>
m360x480x256p EQU mode<0,5,5,0,0>
m256x256x256p EQU mode<1,6,3,0,0>
m320x240x16p  EQU mode<1,5,1,1,0>
m640x400x16p  EQU mode<0,2,4,1,0>
m512x512x16p  EQU mode<0,6,3,1,0>
m720x480x16p  EQU mode<0,5,5,1,0>

m320x400x256c EQU mode<0,2,4,0,1>
m320x480x256c EQU mode<0,5,4,0,1>
m320x448x256c EQU mode<0,4,4,0,1>
m256x256x256c EQU mode<1,6,3,0,1>
