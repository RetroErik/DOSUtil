;
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³   Inlcude file for ASM programs using PDFIK v1.00á   ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³   (C)opyright 1992-1993 by NAPALM / Psychose, Inc.   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;

EXTRN PDFIK_ASM : FAR   ; Main routine (external)

PARAM_STRUC     STRUC   ; Structure to pass & receive parameters
Function        db ?    ; Function number
DtaSeg          dw ?    ; Segment of related datas
DtaOfsPdf       dw ?    ; Offset in DtaSeg of datafile name (ASCIIZ)
DtaOfsFil       dw ?    ; Offset in DtaSeg of file name     (ASCIIZ)
OfsInPdf        dd ?    ; Offset from beginning of Datafile
OfsInFil        dd ?    ; Offset from beginning of File
NumBytes        dd ?    ; Number of bytes to decompress
BufSeg          dw ?    ; Segment of buffer where to unpack the data
BufOfs          dw ?    ; Offset in BufSeg
FlatMode        db ?    ; 0=No 32BMM, 1=32BMM use/compatible.
MemMode         db ?    ; Memory mode of output buffer (see 32BMM ref.)
MemHandle       dw ?    ; Handle of output buffer (32BMM support)
LinearOfs       dd ?    ; 32bit linear offset of output buffer (32BMM support)
NormSize        dd ?    ; Size of the normal file (unpacked)
PackSize        dd ?    ; Size in the datafile (packed)
ErrorCode       db ?    ; Return code from PDFIK
PARAM_STRUC     ENDS    ; End of structure
