; Real-Time Ray-Casting, Morflame octobre 1994
; requiert une table de cosinus/sinus * 512 en dword (… inclure dans le 
; main).
; code optimis‚. Une plus grande rapidit‚ serait obtenue en pr‚calculant
; des tables (estim‚ … +/- 1Mb pour un affichage extra!)
; si une couleur 0 est rencontr‚e dans le bitmap, une colonne verticale est
; trac‚e, et la position x actuelle est lock‚e via le vecteur flags.
; Ainsi, tout ce qui est derriŠre n'est pas calcul‚.

; Constantes
      Angle_vue EQU 60*4
      Angle_vue_div_2 EQU 30*4
      
;---------------------------------------------------------------------------
MRF_TEXT ENDS
_DATA2 SEGMENT
    cam_x DWORD 320*512
    cam_y DWORD 1600*512
    cam_angle WORD 90*4         ; * 4 pour accŠs rapide table dword
    cam_angle_minus_k WORD ?
    cam_angle_plus_k WORD ?
    angle       WORD ?
    wx          DWORD ?
    wy          DWORD ?
    px          DWORD ?
    py          DWORD ?
    mx          DWORD ?
    my          DWORD ? 
    a_x         DWORD ?
    a_y         DWORD ?
    b_x         DWORD ?
    b_y         DWORD ?
    xdiff       DWORD ?
    ydiff       DWORD ?
    xstep       DWORD ?
    ystep       DWORD ?
    flags       byte 320 dup (0)        ; pour le clipping des murs
    i WORD ?
    j WORD ?
    k WORD ?
;---------------------------------------------------------------------------
; Carte de l'environnement
;---------------------------------------------------------------------------
    EVEN
    map LABEL BYTE 
	db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
	db 2,2,0,2,2,2,0,2,2,2,2,2,0,0,0,2
	db 2,2,0,2,2,2,0,2,2,2,2,2,0,0,0,2
	db 2,2,0,0,2,2,0,2,2,2,2,2,0,0,0,2
	db 2,2,0,0,2,2,0,2,2,2,2,2,0,0,0,2
	db 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
	db 2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,2
	db 2,0,0,2,0,2,2,2,0,0,0,2,0,0,0,2
	db 2,2,0,2,0,2,2,2,2,2,0,2,0,0,0,2
	db 2,0,0,2,0,0,0,0,0,0,0,2,0,0,0,2
	db 2,2,0,2,0,0,0,0,0,0,0,2,0,0,0,2
	db 2,0,0,2,0,0,0,0,0,0,0,2,0,0,0,2
	db 2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,2
	db 0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,2
	db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
	db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
;---------------------------------------------------------------------------
_DATA2 ENDS
MRF_TEXT SEGMENT
;------------------------------------------------------------------------------
Tourne_Droite MACRO vitesse
LOCAL saut        
	sub     cam_angle, 4*vitesse         ; 4=1ø
	cmp     cam_angle, 0
	jge     saut
	mov     cam_angle, 359*4
saut:
ENDM
;------------------------------------------------------------------------------
Tourne_Gauche MACRO vitesse       
LOCAL saut        
	add     cam_angle, 4*vitesse         ; 4=1ø
	cmp     cam_angle, 359*4
	jle     saut
	mov     cam_angle, 0
saut:
ENDM
;***************************************************************************
EFFACE_MUR MACRO label_fin
LOCAL fin, bcl3
	mov     bx, bp 
bcl3:   mov     byte ptr es:[bx],00h            ; ligne vert de dx … bp
	sub     bx, 80
	cmp     bx, dx
	jge     bcl3
ENDM
;***************************************************************************
TRAITE_MUR MACRO label_fin
LOCAL fin, bcl3
	cmp     al, 0                           ; couleur noire (0) ?
	jnz     fin
	
	; D‚termination de la couleur du mur 

	mov     ax, i                           ; profondeur
	sub     ax, 102
	shr     ax, 1                           ; position dans palette
	mov     bl, 80
	sub     bl, al        
	mov     al, bl
 
	mov     bx, bp                          ; si oui alors mur !
      ;  sub     bx, 80

bcl3:   mov     byte ptr es:[bx], al            ; ligne vert de dx … bp
	sub     bx, 80
	cmp     bx, dx
	jg      bcl3
	mov     bx, cx
	mov     byte ptr flags[bx], 1           ; flag on, pos x lock‚e !
	jmp     label_fin
fin:                                            ; si non alors sol/plafond !
ENDM
;***************************************************************************
TRAITE_MUR2 MACRO label_fin
LOCAL fin, bcl3

IFNDEF posx                
MRF_TEXT ENDS
_DATA2 SEGMENT

   posx word ?

_DATA2 ENDS
MRF_TEXT SEGMENT
ENDIF        
	cmp     al, 0                           ; couleur noire (0) ?
	jnz     fin                             ; si oui alors mur !
	
	push    cx
	push    si
	push    edi
	push    fs
	
	LSFS    wall, si
	mov     eax, esi                        ; position x
	shr     eax, 9                          ; divis‚ par 512
	mov     ebx, edi                        ; position y
	shr     ebx, 9                          ; divis‚ par 512
	add     eax, ebx                        ; x+y
	and     ax, 07Fh                        ; modulo 128
	mov     posx, ax                        ; cx contient le x du bitmap
	
	mov     bx, dx                          ; position depart (haut)
	xor     eax, eax                        ; incr‚ment dans le bitmap
	mov     si, i                           ; la profondeur (100-200)
	shl     si, 2
	mov     ecx, Hauteur_Mur[si]
	mov     esi, ecx

bcl3:   add     eax, esi                        ; incr‚mentation en y du bmp
	mov     edi, eax
	shr     edi, 2
	add     di, posx                        ; on ajoute pos x =offset bmp
	
	mov     cl, byte ptr fs:[di]

	mov     byte ptr es:[bx], cl
	
	add     bx, 80                          ; un pixel plus bas ...
	cmp     bx, bp
	jle     bcl3

	
	mov     bx, cx
	mov     byte ptr flags[bx], 1           ; flag on, pos x lock‚e !
	
	pop     fs
	pop     edi
	pop     si
	pop     cx
	
	jmp     label_fin

fin:                                            ; si non alors sol/plafond !

ENDM

;***************************************************************************

TROUVE_BITMAP MACRO
	push    ebx
	mov     eax, esi                        ; trouver le bon bitmap
	shr     eax, 9+7
	mov     ebx, edi
	shr     ebx, 9+7                        ; div 512*128
	shl     ebx, 4                          ; * 16
	add     ebx, eax        
	xor     eax, eax
	
	mov     al, map[ebx]        
	shl     eax, 14
	pop     ebx

ENDM        

;***************************************************************************
	

;***************************************************************************
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*             FLOORS, Basse r‚solution (pour vieilles b‚canes)            *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;***************************************************************************


FLOORS_LOW_DETAIL PROC
	push    bp
	mov     bp, sp

	LSFS    mapping, ax
	LSGS    ceil, ax
	mov     k, angle_vue_div_2
;------------------------------------------ Charge segment VGA
	mov     ax, 0A000h
	mov     es, ax 
;------------------------------------------ Pr‚calculations
	mov     ax, cam_angle
	sub     ax, k
	cmp     ax, 0
	jge     @F
	add     ax, 360*4
@@:     mov     cam_angle_minus_k, ax
	mov     ax, cam_angle
	add     ax, k
	cmp     ax, 360*4
	jl      @F
	sub     ax, 360*4
@@:     mov     cam_angle_plus_k, ax
;------------------------------------------ mise … 0 des flags
	mov     bx, 64
bcl0:   mov     byte ptr flags[bx], 0
	dec     bx
	jnz     bcl0
;------------------------------------------ Boucles imbriqu‚es
OUT_16  SC_Index, 0F02h                 ; choix des plan 1-4

mov     cx, 98 
LSFS    _DATA, ax
mov     di, Dest ; fs:[_WorkAdr] ;current_page  ; une des deux pages actives !
mov     dx, word ptr fs:[di] ;current_page
mov     bp, word ptr fs:[di]
LSFS    mapping, ax
add     dx, 80-1                        ; idem ceil
add     bp, 80*200-1                     ; position d‚part floor
;------------------------------------------ Nø1
bcl1:   mov     i, cx
	mov     di, cx
	shl     di, 2
	mov     si, cam_angle_minus_k   ; si est bien positionn‚ dans cos/sin
	mov     ebx, view_distance[di]
	mov     eax, cosinus_2[si]        ; calcul de a_x
	imul    eax, ebx
	add     eax, cam_x
	mov     a_x, eax
	mov     eax, sinus_2[si]          ; calcul de a_y
	imul    eax, ebx
	add     eax, cam_y
	mov     a_y, eax
	mov     si, cam_angle_plus_k    ; si est bien positionn‚ dans cos/sin
	mov     ecx, cosinus_2[si]        ; calcul de b_x
	imul    ecx, ebx
	add     ecx, cam_x
	mov     eax, sinus_2[si]          ; calcul de b_y
	imul    eax, ebx
	add     eax, cam_y
	sub     eax, a_y                ; eax = ydiff (by-ay)
	sub     ecx, a_x                ; ecx = xdiff (bx-ax)
	sar     eax, 6                  ; diviser par view_width
	sar     ecx, 6                  ; (=256) si 1pt pr‚cision
					; (=128) si 2pts pr‚cision
	mov     ystep, eax
	mov     xstep, ecx
	add     i, 100 
;------------------------------------------        
	mov     cx, 64                          ; cx = j
	mov     esi, a_x
	mov     edi, a_y
;------------------------------------------ Nø2
bcl2:   mov     bx, cx                          ; position x lock‚e ?
	cmp     byte ptr flags[bx], 0
	jnz     fbcl2

	mov     eax, esi
	shr     eax, 9
	sub     eax, 32
	and     eax, 7Fh    ; 0000 0000 0000 0000 0000 0000 0111 1111y
	
	mov     ebx, edi   
	shr     ebx, 2
	and     ebx, 3F00h  ; 0000 0000 0000 0000 0011 1111 0000 0000y
	add     ebx, eax                                   ;1 ?
	
	TROUVE_BITMAP
	add     ebx, eax        
	
	mov     al, byte ptr fs:mapping[ebx]    ; couleur du sol

	TRAITE_MUR fbcl2        
	
	mov     es:[bp], al                     ; double pixel sol
	mov     al, byte ptr gs:ceil[ebx]       ; couleur du plafond        
	mov     bx, dx
	mov     es:[bx], al                     ; double pixel plafond
fbcl2:  add     esi, xstep
	add     edi, ystep
	dec     bp                              ; offset_pix_floor-=1
	dec     dx                              ; offset_pix_ceil-=1
	dec     cx
	jnz     bcl2

fbcl1:  add     dx, 144
	sub     bp, 16

	sub     i, 100
	mov     cx, i
	dec     cx
	cmp     cx, 15 
	jnz     bcl1

; ----------------------------------------- Effacement de ce qui reste
	mov     si, 64

eff:  
	cmp     byte ptr flags[si], 0   
	jnz     @F
	Efface_Mur

@@:     dec     bp
	dec     dx
	dec     si
	jnz     eff

	pop     bp
	ret

FLOORS_LOW_DETAIL ENDP



;***************************************************************************
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*             FLOORS, Moyenne r‚solution (pour les bonnes b‚canes)        *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;***************************************************************************

FLOORS_MEDIUM_DETAIL PROC
	push    bp
	mov     bp, sp

	LSFS    mapping, ax
	LSGS    ceil, ax
	mov     k, angle_vue_div_2
;------------------------------------------ Charge segment VGA
	mov     ax, 0A000h
	mov     es, ax 
;------------------------------------------ Pr‚calculations
	mov     ax, cam_angle
	sub     ax, k
	cmp     ax, 0
	jge     @F
	add     ax, 360*4
@@:     mov     cam_angle_minus_k, ax
	mov     ax, cam_angle
	add     ax, k
	cmp     ax, 360*4
	jl      @F
	sub     ax, 360*4
@@:     mov     cam_angle_plus_k, ax
;------------------------------------------ mise … 0 des flags
	mov     bx, 130
bcl0:   mov     byte ptr flags[bx], 0
	dec     bx
	jnz     bcl0

;---------------------------------------------------------------------------
;                               PLANS 1-2
;---------------------------------------------------------------------------

;------------------------------------------ Boucles imbriqu‚es
OUT_16  SC_Index, 0302h                 ; choix des plan 1-2

mov     cx, 98
LSFS    _DATA, ax
mov     di, Dest ;fs:[_WorkAdr] ;current_page  ; une des deux pages actives !
mov     dx, word ptr fs:[di] ;current_page
mov     bp, word ptr fs:[di]
LSFS    mapping, ax
add     dx, 80-1                         ; idem ceil
add     bp, 80*200-1                     ; position d‚part floor
;------------------------------------------ Nø1
bcl1:   mov     i, cx
	mov     di, cx
	shl     di, 2
	mov     si, cam_angle_minus_k   ; si est bien positionn‚ dans cos/sin
	mov     ebx, view_distance[di]
	mov     eax, cosinus_2[si]        ; calcul de a_x
	imul    eax, ebx
	add     eax, cam_x
	mov     a_x, eax
	mov     eax, sinus_2[si]          ; calcul de a_y
	imul    eax, ebx
	add     eax, cam_y
	mov     a_y, eax
	mov     si, cam_angle_plus_k    ; si est bien positionn‚ dans cos/sin
	mov     ecx, cosinus_2[si]        ; calcul de b_x
	imul    ecx, ebx
	add     ecx, cam_x
	mov     eax, sinus_2[si]          ; calcul de b_y
	imul    eax, ebx
	add     eax, cam_y
	sub     eax, a_y                ; eax = ydiff (by-ay)
	sub     ecx, a_x                ; ecx = xdiff (bx-ax)
	sar     eax, 6                  ; diviser par view_width
	sar     ecx, 6                  ; (=256) si 1pt pr‚cision
					; (=128) si 2pts pr‚cision
	mov     ystep, eax
	mov     xstep, ecx
	add     i, 100 
;------------------------------------------        
	mov     cx, 128                           ; cx = j
	mov     esi, a_x
	mov     edi, a_y
;------------------------------------------ Nø2
bcl2:   mov     bx, cx                          ; position x lock‚e ?
	cmp     byte ptr flags[bx], 0
	jnz     fbcl2
	
	mov     eax, esi
	shr     eax, 9
	sub     eax, 32
	and     eax, 7Fh    ; 0000 0000 0000 0000 0000 0000 0111 1111y
	
	mov     ebx, edi   
	shr     ebx, 2
	and     ebx, 3F00h  ; 0000 0000 0000 0000 0011 1111 0000 0000y
	add     ebx, eax                                   ;1 ?
	
	TROUVE_BITMAP
	add     ebx, eax        
	
	mov     al, byte ptr fs:mapping[ebx]    ; couleur du sol
	
	TRAITE_MUR fbcl2        

	mov     es:[bp], al                     ; double pixel sol
	mov     al, byte ptr gs:ceil[ebx]       ; couleur du plafond        
	mov     bx, dx
	mov     es:[bx], al                     ; double pixel plafond
fbcl2:  add     esi, xstep
	add     edi, ystep
	dec     bp                              ; offset_pix_floor-=1
	dec     dx                              ; offset_pix_ceil-=1
	sub     cx, 2
	jnz     bcl2

fbcl1:  add     dx, 144 
	sub     bp, 16
	sub     i, 100
	mov     cx, i
	dec     cx
	cmp     cx, 15
	jnz     bcl1

; ----------------------------------------- Effacement de ce qui reste
	
	mov     si, 128
eff:  
	cmp     byte ptr flags[si], 0
	jnz     @F
	Efface_Mur

@@:     dec     bp
	dec     dx
	sub     si, 2
	jnz     eff

;------------------------------------------ mise … 0 des flags
	mov     bx, 128
bcl0_2: mov     byte ptr flags[bx], 0
	dec     bx
	jnz     bcl0_2

;---------------------------------------------------------------------------
;                               PLANS 3-4
;---------------------------------------------------------------------------

;------------------------------------------ Boucles imbriqu‚es
OUT_16  SC_Index, 0C02h                 ; choix des plan 3-4


mov     cx, 98 
LSFS    _DATA, ax
mov     bp, Dest ;fs:[_WorkAdr] ;current_page  ; une des deux pages actives !
mov     dx, word ptr fs:[bp] ;current_page
mov     bp, word ptr fs:[bp]
LSFS    mapping, ax
add     dx, 80-1                         ; idem ceil
add     bp, 80*200-1                     ; position d‚part floor
;------------------------------------------ Nø1
bcl1_2:   mov     i, cx
	mov     di, cx
	shl     di, 2
	mov     si, cam_angle_minus_k   ; si est bien positionn‚ dans cos/sin
	mov     ebx, view_distance[di]
	mov     eax, cosinus_2[si]        ; calcul de a_x
	imul    eax, ebx
	add     eax, cam_x
	mov     a_x, eax
	mov     eax, sinus_2[si]          ; calcul de a_y
	imul    eax, ebx
	add     eax, cam_y
	mov     a_y, eax
	mov     si, cam_angle_plus_k    ; si est bien positionn‚ dans cos/sin
	mov     ecx, cosinus_2[si]        ; calcul de b_x
	imul    ecx, ebx
	add     ecx, cam_x
	mov     eax, sinus_2[si]          ; calcul de b_y
	imul    eax, ebx
	add     eax, cam_y
	sub     eax, a_y                ; eax = ydiff (by-ay)
	sub     ecx, a_x                ; ecx = xdiff (bx-ax)
	sar     eax, 7                  ; diviser par view_width
	sar     ecx, 7                  ; (=256) si 1pt pr‚cision
					; (=128) si 2pts pr‚cision
	
	mov     ystep, eax
	mov     xstep, ecx
	
	add     i, 100 
;------------------------------------------        
	mov     cx, 128                           ; cx = j
	
	mov     esi, a_x                ; d‚part dans la map 
	mov     edi, a_y
	sub     esi, xstep
	sub     edi, ystep

	shl     xstep, 1                  
	shl     ystep, 1
;------------------------------------------ Nø2
bcl2_2: mov     bx, cx                           ; position x lock‚e ?
	
	cmp     byte ptr flags[bx], 0
	jnz     fbcl2_2
	

	mov     eax, esi
	shr     eax, 9
	sub     eax, 32
	and     eax, 7Fh    ; 0000 0000 0000 0000 0000 0000 0111 1111y
	
	mov     ebx, edi   
	shr     ebx, 2
	and     ebx, 3F00h  ; 0000 0000 0000 0000 0011 1111 0000 0000y
	add     ebx, eax                                   ;1 ?
	
	TROUVE_BITMAP
	add     ebx, eax        
	mov     al, byte ptr fs:mapping[ebx]    ; couleur du sol

	TRAITE_MUR fbcl2_2

	mov     es:[bp], al                     ; double pixel sol
	mov     al, byte ptr gs:ceil[ebx]       ; couleur du plafond        
	mov     bx, dx
	mov     es:[bx], al                     ; double pixel plafond
fbcl2_2:  
	add     esi, xstep
	add     edi, ystep
	dec     bp                              ; offset_pix_floor-=1
	dec     dx                              ; offset_pix_ceil-=1
	sub     cx, 2
	jnz     bcl2_2

fbcl1_2:add     dx, 144 
	sub     bp, 16
	sub     i, 100
	mov     cx, i
	dec     cx
	cmp     cx, 15
	jnz     bcl1_2

; ----------------------------------------- Effacement de ce qui reste
	
	mov     si, 128
eff2:  
	cmp     byte ptr flags[si], 0
	jnz     @F
	Efface_Mur

@@:     dec     bp
	dec     dx
	sub     si, 2
	jnz     eff2

	pop     bp
	ret

FLOORS_MEDIUM_DETAIL ENDP
