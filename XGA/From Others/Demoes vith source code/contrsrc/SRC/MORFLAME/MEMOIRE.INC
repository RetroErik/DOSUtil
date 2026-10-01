;--------------------------------------------------------------------------   
;    ACHTUNG !  VERSION DANGEREUSE ....PAS DE TRAITEMENT D'ERREURS !!!!
;--------------------------------------------------------------------------   
  LSDS MACRO reg1, reg2
    mov reg2, reg1
    mov ds, reg2
  ENDM
;--------------------------------------------------------------------------   
  LSES MACRO reg1, reg2
    mov reg2, reg1
    mov es, reg2
  ENDM
;--------------------------------------------------------------------------   
  LSFS MACRO reg1, reg2
    mov reg2, reg1
    mov fs, reg2
  ENDM
;--------------------------------------------------------------------------   
  LSGS MACRO reg1, reg2
    mov reg2, reg1
    mov gs, reg2
  ENDM
;--------------------------------------------------------------------------   
NEW MACRO nom, mem 
  LOCAL suite, erreur2, fin
  ; d‚clare et alloue mem byte … un pointeur
   MRF_TEXT ENDS
   _DATA2 SEGMENT
      nom word ?
   _DATA2 ENDS
   MRF_TEXT SEGMENT
     mov        ah, 48h
     mov        bx, mem
     shr        bx, 4
     inc        bx
     int        21h
     mov        nom, ax
fin:  
ENDM          
;--------------------------------------------------------------------------   
  FREE MACRO nom
  ; LibŠre la m‚moire point‚e par nom
     mov        ax, nom
     mov        es, ax
     mov        ah, 49h
     int        21h
  ENDM
