;     transf2a               ;rotation z
;     transf2b               ;rotation x
;     transf2c               ;rotation y
;*****************************************************************************
transf2a  macro
          local bcl1
          MPUSH eax,bx,cx,edx,si,edi,ebp,ds,gs
;**************
;rotation z
;x:=x*cos-y*sin  /256
;y:=x*sin+y*cos  /256
;z:=z
;bousille:=ax,bx,cx,dx,di,si
;optimize en ne calculant pas le z
;**************
         mov  cx,nbdots
         xor  bx,bx
         mov  si,agl
         push ds
         push gs
         pop  ds
         pop  gs 
bcl1:
   
         mov    edi,DWORD PTR xv[bx]
         imul   edi,DWORD PTR gs:[cos+si]   ;edi=cos*x

         mov    eax,DWORD PTR yv[bx]
         imul   eax,DWORD PTR gs:[sin+si]   ;eax=sin*y

         sub  edi,eax           ;edi:=edi-eax
         sar  edi,8             ;edi:=edi /256
         mov  ebp,edi           ;save:=x

         mov    edi,DWORD PTR xv[bx]
         imul   edi,DWORD PTR gs:[sin+si]   ;edi=sin*x

         mov    eax,DWORD PTR yv[bx]
         imul   eax,DWORD PTR gs:[cos+si]   ;eax=cos*y

         add  edi,eax           ;edi=edi+eax
         sar  edi,8             ;edi=edi /256
         mov  DWORD PTR yv[bx],edi ;y=ok

         mov  DWORD PTR xv[bx],ebp ;x=ok
 
         add  bx,4

         dec  cx
         jnz  bcl1              ;+ rapide que le loop ?
      
         MPOP eax,bx,cx,edx,si,edi,ebp,ds,gs

endm
;*****************************************************************************
transf2b  macro
          local bcl1
          MPUSH eax,bx,cx,edx,si,edi,ds,gs

;**************
;rotation x
;x:=x
;y:=y*cos-z*sin  /256
;z:=y*sin+z*cos  /256
;bousille:=ax,bx,cx,dx,di,si
;optimize en ne calculant pas le z
;**************
         mov  cx,nbdots
         xor  bx,bx
         mov  si,agl
         push ds
         push gs
         pop  ds
         pop  gs
bcl1:

         mov    edi,DWORD PTR yv[bx]
         imul   edi,DWORD PTR gs:[cos+si]   ;edi=cos*y

         mov    eax,DWORD PTR zv[bx]
         imul   eax,DWORD PTR gs:[sin+si]   ;eax=sin*z

         sub  edi,eax           ;edi=edi-eax
         sar  edi,8             ;edi=edi /256
         mov  DWORD PTR yv[bx],edi;y=ok

         add  bx,4

         dec  cx
         jnz  bcl1

         MPOP eax,bx,cx,edx,si,edi,ds,gs

endm
;*****************************************************************************
transf2c  macro
          local bcl1
          MPUSH eax,bx,cx,edx,si,edi,ds,gs

;**************
;rotation y
;x:=x*cos-z*sin  /256
;y:=y
;z:=x*sin+z*cos  /256
;bousille:=ax,bx,cx,dx,di,si
;optimize en ne calculant pas le z
;**************
         mov  cx,nbdots
         xor  bx,bx
         mov  si,agl
         push ds
         push gs
         pop  ds
         pop  gs
bcl1:
         mov    edi,DWORD PTR xv[bx]
         imul   edi,DWORD PTR gs:[cos+si]   ;edi=cos*x
        
         mov    eax,DWORD PTR zv[bx]
         imul   eax,DWORD PTR gs:[sin+si]   ;eax=sin*z
      
         sub  edi,eax           ;edi=edi-eax
         sar  edi,8             ;edi=edi /256
         mov  DWORD PTR xv[bx],edi;x=ok

         add  bx,4

         dec  cx
         jnz  bcl1

         MPOP eax,bx,cx,edx,si,edi,ds,gs

endm
;*****************************************************************************
