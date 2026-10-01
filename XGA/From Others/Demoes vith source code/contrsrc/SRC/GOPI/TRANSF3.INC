
;---- dots transf - (C) GOPI/TFL-TDV ----
; not very optimized but it's GOPY first try in ASM :-)

;     transf3a               ;rotation zx
;     transf3b               ;rotation zy
;     transf3c               ;rotation xy
;*****************************************************************************
transf3a  macro
          local bcl1,fbcl1,Patch
          MPUSH eax,ebx,cx,edx,esi,edi,ebp,es
  
         mov ax,0a000h
         mov es,ax     ; video seg
         mov dx,3c4h
         mov al,2      ; select bitplane
         out dx,al       

         mov  ax,savptr
         mov  WORD PTR cs:[Patch+3],ax ; save coord buf

;**************
;rotation zx
;**************
         mov  cx,nbdots
         xor  bx,bx
bcl1:    
         ;agrandissement*****
         mov  dl,agr
         mov  al,BYTE PTR gs:XV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:XV[bx],eax

         mov  al,BYTE PTR gs:YV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:YV[bx],eax

         mov  al,BYTE PTR gs:zV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:zV[bx],eax
         ;*******************

         mov    si,agl
         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[cos+si]    ;edi=cos*x

         mov    eax,DWORD PTR gs:yv[bx]
         imul   eax,DWORD PTR[sin+si]    ;eax=sin*y

         sub    edi,eax          ;edi:=edi-eax
         sar    edi,8            ;edi:=edi /256
         mov    ebp,edi          ; save x

         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[sin+si]    ;edi=sin*x

         mov    eax,DWORD PTR gs:yv[bx]
         imul   eax,DWORD PTR[cos+si]    ;eax=cos*y

         add    edi,eax         ;edi=edi+esi
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:yv[bx],edi ;y=ok

         mov    DWORD PTR gs:xv[bx],ebp ;x=ok

         mov    edi,DWORD PTR gs:yv[bx]
         imul   edi,DWORD PTR[cos+si]    ;edi=cos*y
         mov    eax,DWORD PTR gs:zv[bx]
         imul   eax,DWORD PTR[sin+si]    ;eax=sin*z
         sub    edi,eax         ;edi=edi-eax
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:yv[bx],edi ;y=ok

         ;viewdots**********************************************
         mov  edi,DWORD PTR gs:XV[bx] ; x
         add  edi,160
;         cmp  edi,0         ;clip
;         jl   fbcl1         ;clip
;         cmp  edi,320       ;clip
;         jge  fbcl1         ;clip

         mov  esi,DWORD PTR gs:YV[bx] ; y
         add  esi,100
         cmp  esi,0         ;clip
         jl   fbcl1         ;clip
         cmp  esi,200       ;clip
         jge  fbcl1         ;clip

                            ; esi = y    PutPixel rout by Type One ....
                            ; edi = x    
 
         mov     dx,3c5h
         mov     si,WORD PTR [Ytable+esi*2]    ; take the Vertical Offset
         add     si,WORD PTR [Xtable+edi*4+2]  ; take the Horizontal Offset
         add     si,Dest                       ; base
         mov     al,BYTE PTR [Xtable+edi*4]    ; take the corresponding plane
         out     dx,al                         ; enable the right plane
         mov     dl,BYTE PTR gs:VV[bx]
         mov     BYTE PTR es:[si],dl           ; Write pixel onto screen
Patch    LABEL   WORD
         mov     WORD PTR gs:[bx+1234h],si     ; save adr. of dot


fbcl1:
         ;*****************************************************

         add  bx,4

         dec  cx
         jnz  bcl1               ;+ rapide que le loop ?

         MPOP eax,ebx,cx,edx,esi,edi,ebp,es

endm
;*****************************************************************************
transf3b  macro
          local bcl1,fbcl1,Patch
          MPUSH eax,ebx,cx,edx,esi,edi,ebp,es

         mov ax,0a000h
         mov es,ax     ; video seg
         mov dx,3c4h
         mov al,2      ; select bitplane
         out dx,al       
  
         mov  ax,savptr
         mov  WORD PTR cs:[Patch+3],ax ; save coord buf


;**************
;rotation zy
;**************
         mov  cx,nbdots
         xor  bx,bx
bcl1:    
         ;agrandissement*****
         mov  dl,agr
         mov  al,BYTE PTR gs:XV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:XV[bx],eax

         mov  al,BYTE PTR gs:YV[bx]
         imul dl
         cwde 
         mov  DWORD PTR gs:YV[bx],eax

         mov  al,BYTE PTR gs:zV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:zV[bx],eax
         ;*******************

         mov    si,agl

         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[cos+si]   ;edi=cos*x

         mov    eax,DWORD PTR gs:yv[bx]
         imul   eax,DWORD PTR[sin+si]   ;eax=sin*y

         sub    edi,eax         ;edi:=edi-eax
         sar    edi,8           ;edi:=edi /256
         mov    ebp,edi         ;save:=x

         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[sin+si]   ;edi=sin*x

         mov    eax,DWORD PTR gs:yv[bx]
         imul   eax,DWORD PTR[cos+si]   ;eax=cos*y

         add    edi,eax         ;edi=edi+eax
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:yv[bx],edi ;y=ok

         mov    DWORD PTR gs:xv[bx],ebp ;x=ok

         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[cos+si]   ;edi=cos*x
         mov    eax,DWORD PTR gs:zv[bx]
         imul   eax,DWORD PTR[sin+si]   ;eax=sin*z
         sub    edi,eax         ;edi=edi-eax
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:xv[bx],edi ;x=ok
      
         ;viewdots**********************************************
         mov  edi,DWORD PTR gs:XV[bx] ; x
         add  edi,160
       ;  cmp  edi,0         ;clip
       ;  jl   fbcl1         ;clip
       ;  cmp  edi,320       ;clip
       ;  jge  fbcl1         ;clip

         mov  esi,DWORD PTR gs:YV[bx] ; y
         add  esi,100
         cmp  esi,0         ;clip
         jl   fbcl1         ;clip
         cmp  esi,200       ;clip
         jge  fbcl1         ;clip

                            ; esi = y    PutPixel rout by Type One ....
                            ; edi = x    
 
         mov     dx,3c5h
         mov     si,WORD PTR [Ytable+esi*2]    ; take the Vertical Offset
         add     si,WORD PTR [Xtable+edi*4+2]  ; take the Horizontal Offset
         add     si,Dest                       ; base
         mov     al,BYTE PTR [Xtable+edi*4]    ; take the corresponding plane
         out     dx,al                         ; enable the right plane
         mov     dl,BYTE PTR gs:VV[bx]
         mov     BYTE PTR es:[si],dl           ; Write pixel onto screen
Patch    LABEL   WORD
         mov     WORD PTR gs:[bx+1234h],si     ; save adr. of dot


fbcl1:
         ;*****************************************************

         add  bx,4

         dec  cx
         jnz  bcl1               ;+ rapide que le loop ?

         MPOP eax,ebx,cx,edx,esi,edi,ebp,es

endm
;*****************************************************************************
transf3c  macro
          local bcl1,fbcl1,Patch
          MPUSH eax,ebx,cx,edx,esi,edi,ebp,es

         mov ax,0a000h
         mov es,ax     ; video seg
         mov dx,3c4h
         mov al,2      ; select bitplane
         out dx,al       
  
         mov  ax,savptr
         mov  WORD PTR cs:[Patch+3],ax ; save coord buf


;**************
;rotation xy
;**************
         mov  cx,nbdots
         xor  bx,bx

bcl1:    
         ;agrandissement*****
         mov  dl,agr
         mov  al,BYTE PTR gs:XV[bx]
         imul dl
         cwde 
         mov  DWORD PTR gs:XV[bx],eax

         mov  al,BYTE PTR gs:YV[bx]
         imul dl
         cwde 
         mov  DWORD PTR gs:YV[bx],eax

         mov  al,BYTE PTR gs:zV[bx]
         imul dl
         cwde
         mov  DWORD PTR gs:zV[bx],eax

         ;*******************
         mov    si,agl

         mov    edi,DWORD PTR gs:yv[bx]
         imul   edi,DWORD PTR[cos+si]  ;edi=cos*y

         mov    eax,DWORD PTR gs:zv[bx]
         imul   eax,DWORD PTR[sin+si]  ;eax=sin*z

         sub    edi,eax         ;edi=edi-eax
         sar    edi,8           ;edi=edi /256
         mov    ebp,edi         ;y=ok

         mov    edi,DWORD PTR gs:yv[bx]
         imul   edi,DWORD PTR[sin+si]  ;edi=sin*y
 
         mov    eax,DWORD PTR gs:zv[bx]
         imul   eax,DWORD PTR[cos+si]  ;eax=cos*z

         add    edi,eax         ;edi=edi+eax
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:zv[bx],edi ;z=ok
         mov    DWORD PTR gs:yv[bx],ebp ;y=ok

         mov    edi,DWORD PTR gs:xv[bx]
         imul   edi,DWORD PTR[cos+si]  ;edi=cos*x

         mov    eax,DWORD PTR gs:zv[bx]
         imul   eax,DWORD PTR[sin+si]  ;eax=sin*z
         sub    edi,eax         ;edi=edi-eax
         sar    edi,8           ;edi=edi /256
         mov    DWORD PTR gs:xv[bx],edi ;x=ok
      
         ;viewdots**********************************************
         mov  edi,DWORD PTR gs:XV[bx] ; x
         add  edi,160
      ;   cmp  edi,0         ;clip
      ;   jl   fbcl1         ;clip
      ;   cmp  edi,320       ;clip
      ;   jge  fbcl1         ;clip

         mov  esi,DWORD PTR gs:YV[bx] ; y
         add  esi,100
         cmp  esi,0         ;clip
         jl   fbcl1         ;clip
         cmp  esi,200       ;clip
         jge  fbcl1         ;clip

                            ; esi = y    PutPixel rout by Type One ....
                            ; edi = x    
 
         mov     dx,3c5h
         mov     si,WORD PTR [Ytable+esi*2]    ; take the Vertical Offset
         add     si,WORD PTR [Xtable+edi*4+2]  ; take the Horizontal Offset
         add     si,Dest                       ; base
         mov     al,BYTE PTR [Xtable+edi*4]    ; take the corresponding plane
         out     dx,al                         ; enable the right plane
         mov     dl,BYTE PTR gs:VV[bx]
         mov     BYTE PTR es:[si],dl           ; Write pixel onto screen
Patch    LABEL   WORD
         mov     WORD PTR gs:[bx+1234h],si     ; save adr. of dot


fbcl1:
         ;*****************************************************

         add bx,4

         dec  cx
         jnz  bcl1           ;+ rapide que le loop ?

         MPOP eax,ebx,cx,edx,esi,edi,ebp,es

endm
;*****************************************************************************
