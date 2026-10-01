;***********************************************************
;.                                                         *     
;.   ce fichier include contient deux routines n‚c‚ssaires *
;.   aux accŠs fichier en lec/ec .                         *
;.                                                         *     
;*********************************************************** 
lecture proc near
        ;cx     doit contenir la taille
        ;ds:dx  pointe sur le nom
        ;ds:bp  l'adresse de destination
        
        mov     ax,3d42h
        int     21h
        jnc     noerror
        mov     ax,-1
        jmp     abortlec
noerror:
        mov     si,ax
        mov     ax,3f00h
        mov     bx,si
        mov     dx,bp
        int     21h
abortlec:
        ret
lecture endp
;******************************************************************
ecriture proc near
        ;cx      doit contenir la taille 
        ;ds:dx   pointe sur le nom du fichier
        ;bp      doit contenir l'offset d'ecriture DANS le fichier(16bits...)
        ;ds:si   l'adresse de la zone a ecrire
        
        mov     ax,3d42h                ; ouvre le fichier
        int     21h
        jc      abortec
                              ; deplace le pointeur fichier
        push    cx
        mov     bx,ax         ; bx<---handle
        mov     ah,42h
        mov     al,0          ; al<---code de distance (0=from debut)
        mov     cx,0          ; cx<---distance (mot fort)
        mov     dx,bp         ; dx<---distance (mot faible)
        int     21h
        pop     cx
        jc      abortec
        
        mov     dx,si                   ; d‚but de la zone a ecrire
        mov     ax,4000h
        int     21h                     ; ecrit
        
        mov     ah,3eh                  ; ferme fichier
        int     21h
abortec:
        ret
ecriture endp
