;*****************************************************************************
transf1  macro
         local bcl1
         MPUSH ax,bx,cx,dx,ds
;**************
;agrandissement
;sp‚cifi‚ par agr(byte)
;bousille:ax,bx,cx,dx
;**************
         xor  bx,bx
         mov  cx,nbdots
         mov  dl,agr
         push gs
         pop  ds 
bcl1:
         mov  al,BYTE PTR XV[bx]
         imul dl
         mov  WORD PTR XV[bx],ax

         mov  al,BYTE PTR YV[bx]
         imul dl
         mov  WORD PTR YV[bx],ax 

         mov  al,BYTE PTR zV[bx]
         imul dl
         mov WORD PTR zV[bx],ax

         add  bx,4

         dec  cx
         jnz  bcl1
         MPOP ax,bx,cx,dx,ds
endm
;*****************************************************************************