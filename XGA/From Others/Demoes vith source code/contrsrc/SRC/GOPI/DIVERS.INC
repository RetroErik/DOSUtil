;*****************************************************************************
Free_Keyboard MACRO
         push    ax
         push    es
         mov     ax,40h              ; !!! Vider buffer clavier !!! ;-)
         mov     es,ax
         mov     ax,es:[001ah]
         mov     es:[001ch],ax
         pop     es
         pop     ax
ENDM
;*****************************************************************************