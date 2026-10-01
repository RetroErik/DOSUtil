{$R-,S-}
PROGRAM HardwareZoom;
USES
    Crt,MCGA,Tools;
CONST
     TextStr:String='STEFAN OHRHALLINGER PRESENTS:   YET ANOTHER ROUNDSCROLLER ...                   ';
TYPE
    LineType=ARRAY[0..3,0..79] OF Byte;
    PalType=ARRAY[0..255,1..3] OF Byte;
VAR
   FontCh:ARRAY[0..255] OF ^ByteArray;
   TextData:ARRAY[0..63,0..15] OF Char;
   Factor,Size,Dir,X,Y,I,J,K,Phase,XCountCurr,LastCos,CurrCos:Integer;
   ColorTab,GapTab:ARRAY[0..399] OF Byte;
   StartMap,EndMap,R,G,B,PalSel:Byte;
   XCount,YCount,SizeX,DirX,PhaseX:ARRAY[0..3] OF Integer;
   LineData:ARRAY[0..255] OF ^LineType;
   DisplayStart:ARRAY[0..799] OF ShortInt;
   Spr,BallLightSpr,EarthMapSpr:Pointer;
   Adr,Shade:Word;
   OfsTable:ARRAY[34..199,0..199] OF Byte;
   Pal:ARRAY[0..255,1..3] OF Byte;
   Line640:ARRAY[0..319] OF Byte;
   Palette:PalType;
   F:File;
   SpherePal:ARRAY[0..63] OF ^PalType;
   LightTable:ARRAY[0..255] OF Byte;
   SphereMap:ARRAY[0..15,0..15] OF Word;
   EarthFrame:ARRAY[0..255] OF Byte;
   ArcSinTable:ARRAY[-255..255] OF Real;
   SinTab,CosTab:ARRAY[0..255] OF Integer;
   XLATTable:ARRAY[0..63] OF Byte;

PROCEDURE LoadFontMCF(FontName:String);
VAR
   FontFile:File;
   I:Byte;
   L:LongInt;
   X,Y:Integer;
   Size:Word;
BEGIN
     Assign(FontFile,FontName+'.MCF');
     Reset(FontFile,1);
     FOR I:=0 TO 255 DO
     BEGIN
          FontCh[I]:=NIL;
          BlockRead(FontFile,L,4);
          X:=Integer(L);
          Y:=L SHR 16;
          Size:=(X+1)*(Y+1);
          IF X*Y>0 THEN
          BEGIN
               GetAdjMem(Pointer(FontCh[I]),Size+4);
               FontCh[I]^[0]:=Lo(X);
               FontCh[I]^[1]:=Hi(X);
               FontCh[I]^[2]:=Lo(Y);
               FontCh[I]^[3]:=Hi(Y);
               BlockRead(FontFile,FontCh[I]^[4],Size);
          END;
     END;
END;

PROCEDURE Set16Pal(Nr:Byte);
VAR
   I:Byte;
BEGIN
     I:=Port[$3DA];
     Port[$3C0]:=$34;
     Port[$3C0]:=Nr;
END;

PROCEDURE Init16Pal;
VAR
   I:Byte;
BEGIN
     I:=Port[$3DA];
     FOR I:=0 TO 15 DO
     BEGIN
          Port[$3C0]:=I;
          Port[$3C0]:=I;
     END;
     Port[$3C0]:=$10;
     Port[$3C0]:=$81;
     Set16Pal(0);
END;

PROCEDURE CalcBall;
VAR
   I,J,X,Y:Integer;
   C:Byte;
BEGIN
     FOR J:=0 TO 15 DO
         FOR I:=0 TO 15 DO
         BEGIN
              X:=I-16;
              Y:=J-16;
              IF Sqr(X)+Sqr(Y)<Sqr(16) THEN
                 C:=16-Round(Sqrt(Sqr(X)+Sqr(Y)))
              ELSE C:=0;
              IF C>15 THEN
                 C:=15;
              SetColor(J SHL 4+I,C SHL 2,C SHL 2,C SHL 2);
         END;
END;

PROCEDURE CalcLines;
VAR
   I,J,K:Integer;
   B,Map:Byte;
   LineX:LineType;
BEGIN
     FOR J:=16 TO 254 DO
         IF NOT Odd(J) THEN
         BEGIN
              New(LineData[J]);
              ASM
                 push ds
                 pop es
                 mov di,offset line640
                 xor bx,bx
                 mov dx,j
                 shl dx,1
                 mov cx,640
                 cld
    @1:          mov ax,bx
                 shr ax,8
                 and al,31
                 cmp al,16
                 jl @2
                 neg al
                 add al,31
    @2:          stosb
                 add bx,dx
                 loop @1
              END;
              FOR K:=0 TO 3 DO
              BEGIN
                   Map:=1 SHL K;
                   FOR I:=0 TO 79 DO
                   BEGIN
                        ASM
                           mov si,i
                           shl si,3
                           add si,offset line640
                           mov bl,map
                           cld
@1:                        mov bh,0
                           lodsw
                           and al,bl
                           jnz @2
                           or bh,128
@2:                        and ah,bl
                           jnz @3
                           or bh,64
@3:                        lodsw
                           and al,bl
                           jnz @4
                           or bh,32
@4:                        and ah,bl
                           jnz @5
                           or bh,16
@5:                        lodsw
                           and al,bl
                           jnz @6
                           or bh,8
@6:                        and ah,bl
                           jnz @7
                           or bh,4
@7:                        lodsw
                           and al,bl
                           jnz @8
                           or bh,2
@8:                        and ah,bl
                           jnz @9
                           or bh,1
@9:                        mov b,bh
                        END;
                        LineX[K,I]:=B;
                   END;
              END;
              LineData[J]^:=LineX;
         END;
END;

PROCEDURE PutLine(Nr:Integer);
VAR
   I,J:Integer;
BEGIN
     ASM
        push ds
        mov ax,0a000h
        mov es,ax
        mov bx,nr
        shl bx,2
        add bx,offset linedata
        lds si,[bx]
        cld
        mov ax,0102h
@1:     mov dx,03c4h
        out dx,ax
        xor di,di
        mov cx,20
        db 66h
        rep movsw
        shl ah,1
        cmp ah,10h
        jnz @1
        pop ds
     END;
END;

PROCEDURE DrawFrame;
BEGIN
     ASM
        mov cx,400
        mov bx,y

@1:     mov dx,03c0h
        mov al,34h
        out dx,al
        mov al,bh
        and al,31
        cmp al,16
        jl @1a
        neg al
        add al,31
@1a:    out dx,al
        add bx,factor

        mov dx,03dah
@2:     in al,dx
        test al,1
        jnz @2
@3:     in al,dx
        test al,1
        jz @3
        loop @1
     END;
END;

{
PROCEDURE CalcBall2;
VAR
   I,J,X,Y:Integer;
   C:Byte;
BEGIN
     FOR J:=0 TO 15 DO
         FOR I:=0 TO 15 DO
         BEGIN
              X:=I-8;
              Y:=J-8;
              IF Sqr(X)+Sqr(Y)<Sqr(9) THEN
                 C:=9-Round(Sqrt(Sqr(X)+Sqr(Y)))
              ELSE C:=0;
              IF C>7 THEN
                 C:=7;
              SetColor(J SHL 4+I,C SHL 3,C SHL 3,C SHL 3);
         END;
END;
}

PROCEDURE CalcLines2;
VAR
   I,J,K,L,X,XInc:Integer;
   Map:Byte;
   LineX:LineType;
BEGIN
     FOR J:=16 TO 127 DO
     BEGIN
          New(LineData[J]);
          ASM
             push ds
             pop es
             mov di,offset line640
             xor bx,bx
             mov dx,j
             shl dx,1
             mov cx,640
             cld
@1:          mov ax,bx
             shr ax,8
             and al,15
             stosb
             add bx,dx
             loop @1
          END;
              FOR K:=0 TO 3 DO
              BEGIN
                   Map:=1 SHL K;
                   FOR I:=0 TO 79 DO
                   BEGIN
                        ASM
                           mov si,i
                           shl si,3
                           add si,offset line640
                           mov bl,map
                           cld
@1:                        mov bh,0
                           lodsw
                           and al,bl
                           jnz @2
                           or bh,128
@2:                        and ah,bl
                           jnz @3
                           or bh,64
@3:                        lodsw
                           and al,bl
                           jnz @4
                           or bh,32
@4:                        and ah,bl
                           jnz @5
                           or bh,16
@5:                        lodsw
                           and al,bl
                           jnz @6
                           or bh,8
@6:                        and ah,bl
                           jnz @7
                           or bh,4
@7:                        lodsw
                           and al,bl
                           jnz @8
                           or bh,2
@8:                        and ah,bl
                           jnz @9
                           or bh,1
@9:                        mov b,bh
                        END;
                        LineX[K,I]:=B;
                   END;
              END;
              LineData[J]^:=LineX;
     END;
END;

{
PROCEDURE DrawFrame2;
BEGIN
     ASM
        mov cx,256
        mov bx,y
        les di,spherepal
        mov di,phase
        neg di
        and di,127
        shl di,8
        mov dx,03c8h
        mov al,0
        out dx,al
        cld

@1:     mov al,es:[di]
        inc di
        mov ah,0
        mov si,ax
        shl si,1
        add si,ax
        add si,offset palette

        mov dx,03dah
@2:     in al,dx
        test al,1
        jz @2

        mov dx,03c9h
        outsb
        outsb
        outsb

        mov dx,03c0h
        mov al,34h
        out dx,al
        mov al,bh
        out dx,al
        add bx,factor

        mov dx,03dah
@3:     in al,dx
        test al,1
        jnz @3
        loop @1

        mov cx,144
        mov di,03dah
        mov dx,03c0h

@4:     mov al,34h
        out dx,al
        mov al,bh
        and al,15
        out dx,al
        add bx,factor

        xchg dx,di
@5:     in al,dx
        test al,1
        jnz @5
@6:     in al,dx
        test al,1
        jz @6
        xchg dx,di
        loop @4
     END;
END;
}

PROCEDURE DrawFrame2;
BEGIN
     ASM
        mov cx,256
        mov bx,y
        mov dx,03c8h
        mov al,0
        out dx,al
        mov di,factor
        cld
        push ds
        mov si,phase
        shr si,1
        and si,63
        shl si,2
        lds si,[si+offset spherepal]
        mov dx,03dah

@1:     in al,dx
        test al,1
        jz @1

        mov dx,03c9h
        outsb
        outsb
        outsb

        mov dx,03c0h
        mov al,34h
        out dx,al
        mov al,bh
        out dx,al
        add bx,di

        mov dx,03dah
@2:     in al,dx
        test al,1
        jnz @2
        loop @1
        pop ds

        mov cx,144
        mov di,03dah
        mov dx,03c0h

@4:     mov al,34h
        out dx,al
        mov al,bh
        and al,15
        out dx,al
        add bx,factor

        xchg dx,di
@5:     in al,dx
        test al,1
        jnz @5
@6:     in al,dx
        test al,1
        jz @6
        xchg dx,di
        loop @4
     END;
END;

FUNCTION ArcSin(X:Real):Real;
BEGIN
     ArcSin:=ArcTan(X/Sqrt(1-Sqr(X)))
END;

PROCEDURE CalcEarth;
VAR
   X,Y,X2,Y2,YSqr,YSqrt:Real;
BEGIN
     FOR I:=-255 TO 255 DO
         ArcSinTable[I]:=ArcSin(I/256)/Pi*2;
     FOR J:=0 TO 15 DO
     BEGIN
          Y:=J-8;
          Y2:=ArcSinTable[Round(255*Y/8)];
          YSqrt:=Sqrt(1-Sqr(Y/8))*8;
          YSqr:=Sqr(Y);
          FOR I:=0 TO 15 DO
          BEGIN
               X:=I-8;
               IF Sqr(X)+YSqr<64 THEN
               BEGIN
                    X2:=ArcSinTable[Round(255*X/YSqrt)];
                    SphereMap[J,I]:=(10+Round(Y2*15)) SHL 6+16+Round(X2*15)
               END
               ELSE SphereMap[J,I]:=0;
          END;
          WriteLn(J);
     END;
END;

PROCEDURE DrawEarth(Phase:Integer);
VAR
   I,J:Integer;
BEGIN
     FOR J:=0 TO 15 DO
         FOR I:=0 TO 15 DO
         BEGIN
              ASM
                 mov ax,ds
                 mov es,ax
                 mov di,offset earthframe
                 mov ax,j
                 shl ax,4
                 add di,ax
                 add di,i
                 mov si,j
                 shl si,4
                 add si,i
                 shl si,1
                 add si,offset spheremap
                 cld
                 lodsw
                 or ax,ax
                 jz @1
                 push ds
                 lds si,earthmapspr
                 mov si,phase
                 add si,ax
                 add si,4
                 movsb
                 pop ds
                 jmp @2
@1:              mov al,0
                 stosb
@2:           END;
         END;
END;

PROCEDURE CalcOfsTable;
VAR
   I,J,CurrY,OldY,K:Integer;
BEGIN
     FOR J:=34 TO 199 DO
     BEGIN
          OldY:=199;
          FOR I:=199 DOWNTO 0 DO
              IF I>J THEN
                 OfsTable[J,I]:=0
              ELSE
              BEGIN
                   CurrY:=Round(I/J*199);
                   OfsTable[J,I]:=40*(OldY-CurrY);
                   OldY:=CurrY;
              END;
     END;
END;

PROCEDURE ShowPicture;
BEGIN
     ASM
        mov bx,i
        sub bx,34
        mov ax,397
        mul bx
        mov bx,ax

        mov di,offset xlattable
        push ds
        pop es
        mov cx,64
        cld
@0:     mov al,64
        sub al,cl
        mov ah,0
        mul bx
        mov al,dl
        stosb
        loop @0

        mov dx,03c8h
        mov al,0
        out dx,al
        inc dx
        mov si,offset pal
        add si,767
        mov cx,256
        mov bx,offset xlattable
        std
@1:     lodsb
        xlat
        push ax
        lodsb
        xlat
        push ax
        lodsb
        xlat
        push ax
        loop @1
     END;
     WaitScreen;
     ASM
        mov si,offset ofstable
        mov ax,i
        sub ax,34
        mov bx,200
        mul bx
        add si,ax
        add si,199
        mov cx,200
        std

        mov dx,$3da
@1:     in al,dx
        test al,1
        jnz @1

@2:     lodsb
        mov ah,al
        mov al,13h
        mov dx,03d4h
        out dx,ax

        mov dx,03c9h
        pop ax
        out dx,al
        pop ax
        out dx,al
        pop ax
        out dx,al

        mov dx,$3da
@3:     in al,dx
        test al,1
        jz @3

        loop @1
     END;
     ASM
        inc si
        cld
        mov cx,200

@1:     mov dx,$3da
        in al,dx
        test al,1
        jnz @1

@2:     lodsb
        mov ah,al
        mov al,13h
        mov dx,$3d4
        out dx,ax

        cmp cx,144
        jle @4
        mov dx,03c9h
        pop ax
        out dx,al
        pop ax
        out dx,al
        pop ax
        out dx,al

@4:     mov dx,$3da
@5:     in al,dx
        test al,1
        jz @5

        loop @1
     END;
     WaitRetrace;
END;

BEGIN

     { Big Zoom of Ball, 32x32 }

     FOR I:=0 TO 255 DO
     BEGIN
          SinTab[I]:=Round(64*Sin(I/64*Pi));
          CosTab[I]:=Round(200*Cos(I/64*Pi));
     END;
     SetModeNr($0D);
     Init16Pal;
     CalcBall;
     CalcLines;
     SetOffset(0);
     Factor:=16;
     Dir:=2;
     Phase:=0;
     REPEAT
           CLI;
           IF Phase AND 511<118 THEN
              Factor:=16+Byte(Phase) SHL 1
           ELSE
           IF Phase AND 511<256 THEN
              Factor:=250
           ELSE
           IF Phase AND 511<374 THEN
              Factor:=250-(Phase AND 127) SHL 1
           ELSE Factor:=16;
           PutLine(Factor);
           X:=SinTab[Byte(Phase)]+64;
           SetHorizOfs(X AND 3);
           SetStart(X SHR 2);
           Y:=CosTab[Byte(Phase)];
           Y:=Y*Factor;
           SetOffset(0);
           WaitScreen;
           DrawFrame;
           WaitRetrace;
           SetOffset(40);
           Inc(Factor,Dir);
           IF (Factor=16) OR (Factor=250) THEN
              Dir:=-Dir;
           Inc(Phase);
           STI;
     UNTIL (Phase=1280) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

     { Animated Zoom, 16x16 }

     FOR I:=0 TO 255 DO
     BEGIN
          SinTab[I]:=Round(64*Sin(I/64*Pi));
          CosTab[I]:=Round(200*Cos(I/64*Pi));
     END;
     CalcEarth;
     Assign(F,'EARTH.MAP');
     Reset(F,1);
     BlockRead(F,Palette,768);
     GetAdjMem(EarthMapSpr,1344);
     BlockRead(F,EarthMapSpr^,1344);
     Close(F);
     Assign(F,'BALLIGHT.SPR');
     Reset(F,1);
     Seek(F,4);
     BlockRead(F,LightTable,256);
     Close(F);
     FOR I:=0 TO 63 DO
     BEGIN
          DrawEarth(I);
          GetAdjMem(Pointer(SpherePal[I]),768);
          FOR J:=0 TO 255 DO
          BEGIN
               SpherePal[I]^[J,1]:=(Palette[EarthFrame[J],1]*LightTable[J]) SHR 8;
               SpherePal[I]^[J,2]:=(Palette[EarthFrame[J],2]*LightTable[J]) SHR 8;
               SpherePal[I]^[J,3]:=(Palette[EarthFrame[J],3]*LightTable[J]) SHR 8;
          END;
     END;
     CalcLines2;
     SetOffset(0);
     Factor:=16;
     Dir:=1;
     Phase:=0;
     SetOffset(0);
     REPEAT
           CLI;
           IF Phase AND 511<111 THEN
              Factor:=126-Phase AND 127
           ELSE
           IF Phase AND 511<256 THEN
              Factor:=16
           ELSE
           IF Phase AND 511<367 THEN
              Factor:=16+Phase AND 127
           ELSE Factor:=126;
           PutLine(Factor);
           X:=SinTab[Byte(Phase)]+64;
           SetHorizOfs(X AND 3);
           SetStart(X SHR 2);
           Y:=CosTab[Byte(Phase)];
           Y:=Y*Factor;
           WaitScreen;
           DrawFrame2;
           WaitRetrace;
           Inc(Phase);
           STI;
     UNTIL (Phase=1536) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

     { Checkers }

     SetStart(0);
     SetHorizOfs(0);
     FOR I:=0 TO 255 DO
     BEGIN
          SinTab[I]:=Round(128*Sin(I/64*Pi));
          CosTab[I]:=Round(128*Cos(I/64*Pi));
     END;
     FOR J:=0 TO 7 DO
         FOR I:=0 TO 15 DO
         BEGIN
              IF (I AND 1=1) XOR (J AND 1=1) THEN
                 R:=63
              ELSE R:=0;
              IF (I AND 2=2) XOR (J AND 2=2) THEN
                 G:=63
              ELSE G:=0;
              IF (I AND 4=4) XOR (J AND 4=4) THEN
                 B:=63
              ELSE B:=0;
              SetColor(J SHL 4+I,R,G,B);
         END;
     FOR I:=0 TO 15 DO
         SetColor(128+I,0,0,0);
     StartMap:=0;
     EndMap:=1;
     SetOffset(0);
     FOR I:=0 TO 2 DO
     BEGIN
          SizeX[I]:=1;
          DirX[I]:=1;
          IF SizeX[I]>127 THEN
          BEGIN
               SizeX[I]:=255-SizeX[I];
               DirX[I]:=-1;
          END;
          PhaseX[I]:=32*I;
     END;
     Phase:=0;
     REPEAT
           CLI;
           PalSel:=0;
           FOR I:=StartMap TO EndMap-1 DO
               YCount[I]:=SinTab[PhaseX[I]]-200;
           FOR I:=StartMap TO EndMap-1 DO
           BEGIN
                WHILE YCount[I]>SizeX[I] SHL 2 DO
                      Dec(YCount[I],SizeX[I] SHL 2);
                WHILE YCount[I]<0 DO
                      Inc(YCount[I],SizeX[I] SHL 2);
                IF YCount[I]>SizeX[I] SHL 1 THEN
                BEGIN
                     Dec(YCount[I],SizeX[I] SHL 1);
                     PalSel:=PalSel XOR (1 SHL I);
                END;
           END;
           WaitScreen;
           FOR J:=0 TO 359 DO
           BEGIN
                ASM
                   mov bx,offset ycount
                   mov si,offset sizex
                   cld
                   lodsw
                   shl ax,1
                   mov dx,[bx]
                   cmp startmap,0
                   jg @1a
                   cmp ax,dx
                   jnz @1
                   xor byte ptr palsel,1
                   mov word ptr [bx],0
@1:                inc word ptr [bx]
                   cmp endmap,1
                   jz @4

@1a:               add bx,2

                   lodsw
                   shl ax,1
                   mov dx,[bx]
                   cmp startmap,1
                   jg @2a
                   cmp ax,dx
                   jnz @2
                   xor byte ptr palsel,2
                   mov word ptr [bx],0
@2:                inc word ptr [bx]
                   cmp endmap,2
                   jz @4

@2a:               add bx,2

                   lodsw
                   shl ax,1
                   mov dx,[bx]
                   cmp ax,dx
                   jnz @3
                   xor byte ptr palsel,4
                   mov word ptr [bx],0
@3:                inc word ptr [bx]
                   add bx,2
@4:
                END;
                ASM
                   mov dx,03c0h
                   mov al,34h
                   out dx,al
                   mov al,palsel
                   out dx,al

                   mov dx,03dah
@1:                in al,dx
                   test al,1
                   jnz @1
@2:                in al,dx
                   test al,1
                   jz @2
                END;
           END;
           Set16Pal(8);
           WaitRetrace;
           FOR I:=StartMap TO EndMap-1 DO
           BEGIN
                Inc(SizeX[I],DirX[I]);
                IF (SizeX[I]=16) AND (DirX[I]=-1) OR (SizeX[I]=127) THEN
                   DirX[I]:=-DirX[I];
           END;
           FOR I:=StartMap TO EndMap-1 DO
           BEGIN
                ASM
                   mov cx,i
                   mov ah,1
                   shl ah,cl
                   mov al,2
                   mov dx,03c4h
                   out dx,ax
                END;
                XCountCurr:=CosTab[PhaseX[I]]-160;
                ASM
                   mov si,i
                   shl si,1
                   add si,offset sizex
                   lodsw
                   shl ax,1
                   mov bx,xcountcurr
@1:                cmp bx,ax
                   jle @2
                   sub bx,ax
                   jmp @1
@2:                or bx,bx
                   jge @3
                   add bx,ax
                   jmp @2
@3:                xor dx,dx
                   shr ax,1
                   cmp bx,ax
                   jle @4
                   sub bx,ax
                   inc dx
@4:                mov si,ax
                END;
                ASM
                   mov ax,0a000h
                   mov es,ax
                   xor di,di
                   mov dh,20
                   cld
@0:                xor ax,ax
                   mov cx,16
@1:                shl ax,1
                   or al,dl
                   cmp bx,si
                   jnz @2
                   xor bx,bx
                   xor dl,1
@2:                inc bx
                   loop @1
                   xchg al,ah
                   stosw
                   dec dh
                   jnz @0
                END;
           END;
           FOR I:=EndMap TO 2 DO
           BEGIN
                SetWriteMap(1 SHL I);
                ASM
                   mov ax,0a000h
                   mov es,ax
                   xor di,di
                   mov cx,10
                   db 66h
                   xor ax,ax
                   cld
                   db 66h
                   rep stosw
                END;
           END;
           FOR I:=0 TO StartMap-1 DO
           BEGIN
                SetWriteMap(1 SHL I);
                ASM
                   mov ax,0a000h
                   mov es,ax
                   xor di,di
                   mov cx,10
                   db 66h
                   xor ax,ax
                   cld
                   db 66h
                   rep stosw
                END;
           END;
           FOR I:=0 TO 2 DO
           BEGIN
                IF PhaseX[I]=128 THEN
                   PhaseX[I]:=0
                ELSE Inc(PhaseX[I]);
           END;
           Inc(Phase);
           IF Phase=512 THEN
              EndMap:=2
           ELSE
           IF Phase=1024 THEN
              EndMap:=3
           ELSE
           IF Phase=2048 THEN
              StartMap:=1
           ELSE
           IF Phase=2560 THEN
              StartMap:=2;
           STI;
     UNTIL KeyPressed OR (Phase=3072);
     IF KeyPressed THEN
        WaitKey;

     { Screen wobbler }

     Init13X;
     Port[$3D4]:=9;
     Port[$3D5]:=Port[$3D5] AND $F0;
     CalcOfsTable;
     LoadSprite('KEWLAARD',Spr);
     LoadPalette('KEWLAARD');
     SetColor(0,0,0,0);
     FOR I:=0 TO 255 DO
         GetColor(I,Pal[I,1],Pal[I,2],Pal[I,3]);
     FOR I:=0 TO 3 DO
     BEGIN
          SetWriteMap(1 SHL I);
          ASM
             push ds
             mov ax,0a000h
             mov es,ax
             mov ax,i
             lds si,spr
             add si,ax
             add si,4
             mov dx,198
             cld
@1:          mov di,050h
             mov cx,80
@2:          movsb
             add si,3
             loop @2
             sub si,320
             mov cx,80
@3:          movsb
             add si,3
             loop @3
             mov ax,es
             add ax,0ah
             mov es,ax
             dec dx
             jnz @1
             pop ds
          END;
     END;
     FOR I:=0 TO 3 DO
     BEGIN
          SetWriteMap(1 SHL I);
          ASM
             push ds
             mov ax,0afb7h
             mov es,ax
             mov ax,i
             lds si,spr
             add si,ax
             add si,4
             mov dx,198
             cld
@1:          mov di,050h
             mov cx,80
@2:          movsb
             add si,3
             loop @2
             sub si,320
             mov cx,80
@3:          movsb
             add si,3
             loop @3
             mov ax,es
             sub ax,0ah
             mov es,ax
             dec dx
             jnz @1
             pop ds
          END;
     END;
     Port[$3D4]:=$11;
     Port[$3D5]:=Port[$3D5] AND $7F;
     FOR I:=0 TO 799 DO
         DisplayStart[I]:=Round(20*Sin(I/50*Pi));
     Phase:=0;
     K:=0;
     REPEAT
           CLI;
           VerticalRetrace;
           J:=(Phase MOD 200) SHL 1;
           IF Phase<63 THEN
              Inc(K)
           ELSE
           IF Phase>960 THEN
              Dec(K);
           ASM
              mov si,offset displaystart
              add si,j
              mov cx,280
              cld
@0:           lodsb
              cbw
              mov bx,k
              imul bx
              add ah,86
              mov dx,03dah
@1:           in al,dx
              test al,1
              jnz @1
              mov dx,03d4h
              mov al,4
              out dx,ax
              mov dx,03dah
@2:           in al,dx
              test al,1
              jz @2
              loop @0
           END;
           Inc(Phase);
           STI;
     UNTIL (Phase=512) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

     { Screen rotate off }

     I:=199;
     Dir:=-1;
     Adr:=0;
     Phase:=0;
     REPEAT
           CLI;
           IF I>=34 THEN
              ShowPicture
           ELSE
           IF (I=33) AND (Dir=-1) THEN
           BEGIN
                Adr:=$8000-Adr;
                SetStart(Adr);
           END
           ELSE VerticalRetrace;
           Inc(I,Dir);
           IF (I=1) OR (I=199) THEN
              Dir:=-Dir;
           Inc(Phase);
           STI;
     UNTIL (Phase=970) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

{ Roundscroller with Greetings }

     LastCos:=Round(200*Sqrt(Cos(Pi/2)));
     FOR I:=139 DOWNTO 0 DO
     BEGIN
          CurrCos:=Round(140*Sqrt(Cos(I/280*Pi)));
          GapTab[139-I]:=CurrCos-LastCos+1;
          IF GapTab[139-I]>7 THEN
             GapTab[139-I]:=224
          ELSE GapTab[139-I]:=GapTab[139-I] SHL 5;
          GapTab[260+I]:=GapTab[139-I];
          LastCos:=CurrCos;
     END;
     FOR I:=0 TO 199 DO
     BEGIN
          ColorTab[I]:=Round(63*Sin((I+56)/512*Pi));
          ColorTab[399-I]:=ColorTab[I];
     END;
     FOR I:=140 TO 259 DO
         GapTab[I]:=32;
     FOR I:=0 TO 1023 DO
         TextData[I SHR 4,I AND 15]:=TextStr[1+I MOD Length(TextStr)];
     MCGAOn;
     SetModeReg('256X400');
     Unchain;
     ClearScreen;
     FOR I:=0 TO 15 DO
         SetColor(I,31,I SHL 2,I SHL 2);
     LoadFontMCF('CLEAN16');
     Phase:=0;
     K:=0;
     VerticalRetrace;
     REPEAT
           CLI;
           ASM
              mov bx,phase
              shl bx,7
              mov dx,03d4h
              mov al,0ch
              mov ah,bh
              out dx,ax
              inc ax
              mov ah,bl
              out dx,ax

              mov dx,03dah
@2:           in al,dx
              test al,8
              jnz @2
           END;
           ASM
              mov cx,400
              xor si,si
              cld

@0:           mov dx,03c8h
              mov al,0
              out dx,al
              inc dx
              push si
              add si,offset colortab
              lodsb
              mul byte ptr k
              mov al,ah
              out dx,al
              mov al,0
              out dx,al
              out dx,al

              mov dx,03dah
@1:           in al,dx
              test al,1
              jnz @1

              mov dx,03d4h
              mov al,13h
              pop si
              push si
              add si,offset gaptab
              mov ah,[si]
              out dx,ax

              mov dx,03dah
@2:           in al,dx
              test al,1
              jz @2

              pop si
              inc si
              loop @0
           END;
           FOR I:=0 TO 15 DO
               ASM
                  cld
                  push ds
                  pop es
                  mov di,offset linedata
                  mov bx,i
                  shl bx,2
                  mov si,phase
                  push si
                  shr si,4
                  and si,63
                  shl si,4
                  add si,i
                  add si,offset textdata
                  lodsb
                  mov ah,0
                  shl ax,2
                  mov si,offset fontch
                  add si,ax
                  lds si,[si]
                  pop si
                  and si,15
                  shl si,4
                  add si,4
                  mov cx,16
@1:               lodsb
                  mov es:[di+bx],al
                  add bl,64
                  adc bl,0
                  loop @1
                  push es
                  pop ds
               END;
           FOR I:=0 TO 1 DO
               ASM
                  mov ax,0a000h
                  mov es,ax
                  mov di,phase
                  shl di,1
                  add di,i
                  shl di,6
                  add di,0c000h
                  mov bx,di
                  mov si,offset linedata
                  mov dx,03c4h
                  cld
                  mov ax,0102h
                  out dx,ax
                  mov cx,16
                  db 66h
                  rep movsw
                  mov ax,0202h
                  out dx,ax
                  mov cx,16
                  mov di,bx
                  db 66h
                  rep movsw
                  mov ax,0402h
                  out dx,ax
                  mov cx,16
                  mov di,bx
                  db 66h
                  rep movsw
                  mov ax,0802h
                  out dx,ax
                  mov cx,16
                  mov di,bx
                  db 66h
                  rep movsw
               END;
           Inc(Phase);
           IF Phase<255 THEN
              Inc(K)
           ELSE
           IF Phase>1024-256 THEN
              Dec(K);
           STI;
     UNTIL (Phase=1024) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;
     SetModeNr(3);
END.