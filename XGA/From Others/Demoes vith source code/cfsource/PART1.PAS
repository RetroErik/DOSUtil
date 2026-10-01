{$R-,S-}
PROGRAM PaletteStars;
USES
    Crt,MCGA,Tools;
TYPE
    ByteArray=ARRAY[0..65534] OF Byte;
VAR
   StartLogoSpr:Pointer;
   FontCh:ARRAY[1..2,0..255] OF ^ByteArray;
   Color,Gray:Byte;
   I,J,K,Phase,Radius,StartR,StartG,StartB,OfsLines,Count,RasterLine,C,IncC,
   Dir,LastOfs:Integer;
   SpiralTab:ARRAY[0..127] OF Integer;
   BarTab:ARRAY[0..799] OF Byte;
   BarStartTab:ARRAY[0..255] OF Integer;
   SinVertTab:ARRAY[0..1023] OF Integer;
   Adr,Start:Word;
   Cancel:Boolean;
   BarLine:ARRAY[0..319] OF Byte;
   Factor:ARRAY[0..63] OF Integer;
   StartGap:ARRAY[0..63,0..5] OF Integer;
   AardTextSpr:Pointer;
   ScrollText1:String;
   StandardPal:ARRAY[0..255,1..3] OF Byte;
   F:File;
   Line:ARRAY[0..1023] OF Word;
   Line2:ARRAY[0..1023] OF Integer;
   Pal:ARRAY[0..127] OF Byte;
   OfsRel,OfsTable:ARRAY[0..1023] OF Integer;
   SinTable:ARRAY[0..255] OF Byte;

PROCEDURE LoadFontMCF(Font:Byte; FontName:String);
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
          FontCh[Font,I]:=NIL;
          BlockRead(FontFile,L,4);
          X:=Integer(L);
          Y:=L SHR 16;
          Size:=(X+1)*(Y+1);
          IF X*Y>0 THEN
          BEGIN
               GetMem(FontCh[Font,I],Size+4);
               FontCh[Font,I]^[0]:=Lo(X);
               FontCh[Font,I]^[1]:=Hi(X);
               FontCh[Font,I]^[2]:=Lo(Y);
               FontCh[Font,I]^[3]:=Hi(Y);
               BlockRead(FontFile,FontCh[Font,I]^[4],Size);
          END;
     END;
END;

PROCEDURE PutImageOn(X1,Y1:Integer; P:Pointer);
VAR
   Adr,I,XS,YS:Word;
BEGIN
     Adr:=Word(Y1)*80+X1 SHR 2;
     FOR I:=0 TO 3 DO
     BEGIN
          SetReadMap(I);
          SetWriteMap(1 SHL I);
          ASM
             push ds
             lds si,p
             lodsw
             mov xs,ax
             mov bx,ax
             inc bx
             lodsw
             add si,i
             mov ys,ax
             mov dx,ax
             inc dx
             mov ax,0a000h
             mov es,ax
             mov di,adr
             mov ah,64
             cld
             shr bx,2
     @1:     mov cx,bx
     @2:     lodsb
             add si,3
             cmp al,0
             jz @3
             or es:[di],ah
     @3:     inc di
             loop @2
             add di,80
             sub di,bx
             dec dx
             jnz @1
             pop ds
          END;
     END;
END;

PROCEDURE PutImageOff(X1,Y1:Integer; P:Pointer);
VAR
   Adr,I,XS,YS:Word;
BEGIN
     Adr:=Word(Y1)*80+X1 SHR 2;
     FOR I:=0 TO 3 DO
     BEGIN
          SetReadMap(I);
          SetWriteMap(1 SHL I);
          ASM
             push ds
             lds si,p
             lodsw
             mov xs,ax
             mov bx,ax
             inc bx
             lodsw
             add si,i
             mov ys,ax
             mov dx,ax
             inc dx
             mov ax,0a000h
             mov es,ax
             mov di,adr
             mov ah,191
             cld
             shr bx,2
     @1:     mov cx,bx
     @2:     lodsb
             add si,3
             cmp al,0
             jz @3
             and es:[di],ah
     @3:     inc di
             loop @2
             add di,80
             sub di,bx
             dec dx
             jnz @1
             pop ds
          END;
     END;
END;

PROCEDURE PutChar(Font:Byte; X,Y:Integer; Ch:Char; OnOff:Boolean);
BEGIN
     IF FontCh[Font,Ord(Ch)]<>NIL THEN
        IF OnOff THEN
           PutImageOn(X,Y,FontCh[Font,Ord(Ch)])
        ELSE PutImageOff(X,Y,FontCh[Font,Ord(Ch)]);
END;

PROCEDURE PutString(Font:Byte; X,Y:Integer; S:String; Distance:Integer; OnOff:Boolean);
VAR
   I:Integer;
BEGIN
     FOR I:=1 TO Length(S) DO
     BEGIN
          PutChar(Font,X,Y,S[I],OnOff);
          Inc(X,Distance);
     END;
END;

PROCEDURE SetPixel4(X,Y:Integer; C:Byte);
BEGIN
     SetWriteMap(1 SHL (X AND 3));
     Mem[$A000:Y*80+X SHR 2]:=C;
END;

FUNCTION GetPixel4(X,Y:Integer):Byte;
BEGIN
     SetReadMap(X AND 3);
     GetPixel4:=Mem[$A000:Y*80+X SHR 2];
END;

PROCEDURE MakeStar;
VAR
   I,X,Y,XP,YP:Integer;
   Shift,Value:Byte;
   InRange:Boolean;
BEGIN
     REPEAT
           X:=Integer(Random(500)-250);
           Y:=Integer(Random(800)-400);
     UNTIL (X<-160) OR (X>160) OR (Y<-100) OR (Y>100);
     Shift:=Random(64);
     X:=X SHL 4;
     Y:=Y SHL 4;
     FOR I:=63 DOWNTO 8 DO
     BEGIN
          XP:=Factor[I];
          ASM
             mov cl,0
             mov ax,xp
             mov bx,ax
             imul x
             add dx,160
             or dx,dx
             jl @1
             cmp dx,319
             jg @1
             mov xp,dx
             mov ax,bx
             imul y
             add dx,200
             or dx,dx
             jl @1
             cmp dx,399
             jg @1
             mov yp,dx
             mov cl,1
@1:          mov inrange,cl
          END;
          IF InRange THEN
          BEGIN
               Value:=GetPixel4(XP,YP);
               IF Value<127 THEN
                  SetPixel4(XP,YP,Value AND 64+((I+Shift) AND 63));
          END;
     END;
END;

PROCEDURE CalcFactors;
VAR
   I:Integer;
BEGIN
     FOR I:=8 TO 63 DO
         Factor[I]:=65535 DIV (I+8);
END;

PROCEDURE ActiveTransparent(Nr:Integer);
VAR
   Ph:Integer;
BEGIN
     Ph:=Phase-Nr;
     IF Ph<64 THEN
        SetColor(64+I,127-Ph,63,127-Ph)
     ELSE SetColor(64+I,(Ph-64) SHR 1,63,(Ph-64) SHR 1);
END;

PROCEDURE PassiveTransparent(Nr:Integer);
VAR
   Ph,I:Integer;
BEGIN
     Ph:=Phase-Nr;
     IF Ph<64 THEN
        FOR I:=0 TO 63 DO
            SetColor(64+I,Ph,0,0)
     ELSE
     FOR I:=0 TO 63 DO
         SetColor(64+I,(191-Ph) SHR 1,0,0);
END;

FUNCTION Range(Nr:Integer):Boolean;
BEGIN
     Range:=(Phase>=Nr) AND (Phase<=Nr+191);
END;

PROCEDURE DrawRectangle(Ph:Integer);
BEGIN
     DrawLineH4(1399-Ph,Ph-1080,(1400-Ph) SHL 1-2,129);
     DrawLineH4(1399-Ph,Ph-1080,(1400-Ph) SHL 1-1,129);
     DrawLineH4(1399-Ph,Ph-1080,(Ph-1200) SHL 1,129);
     DrawLineH4(1399-Ph,Ph-1080,(Ph-1200) SHL 1+1,129);
     DrawLineV4(1399-Ph,(1400-Ph) SHL 1,(Ph-1200) SHL 1-1,129);
     DrawLineV4(Ph-1080,(1400-Ph) SHL 1,(Ph-1200) SHL 1-1,129);
END;

PROCEDURE DrawFontBar(I,J:Integer);
BEGIN
     IF I<64 THEN
     BEGIN
          Count:=StartGap[I,J]-StartGap[I,J-1];
          SetOffset(40);
          FOR I:=0 TO 12 DO
          BEGIN
               Wait4Line;
               Inc(RasterLine);
          END;
          SetOffset(0);
          FOR I:=0 TO Count-1 DO
          BEGIN
               Wait4Line;
               Inc(RasterLine);
          END;
     END
     ELSE
     BEGIN
          SetOffset(40);
          IF J=1 THEN
          BEGIN
               Wait4Line;
               Inc(RasterLine);
          END;
          FOR I:=0 TO 10 DO
          BEGIN
               Wait4Line;
               Inc(RasterLine);
          END;
          SetOffset(80);
          Wait4Line;
          Inc(RasterLine);
     END;
END;

{
PROCEDURE DrawFontBar(I,J:Integer);
BEGIN
     IF I<64 THEN
     BEGIN
          Count:=StartGap[I,J]-StartGap[I,J-1];
          ASM
             mov dx,$3d4
             mov ax,$2813
             out dx,ax

             mov cx,13
             mov dx,$3da
@1:          in al,dx
             test al,1
             jnz @1
@2:          in al,dx
             test al,1
             jz @2
             loop @1

             mov dx,$3d4
             mov ax,$0013
             out dx,ax

             mov cx,count
             jcxz @5
             mov dx,$3da
@3:          in al,dx
             test al,1
             jnz @3
@4:          in al,dx
             test al,1
             jz @4
             loop @3
@5:      END;
     END
     ELSE
     BEGIN
          ASM
             mov dx,$3d4
             mov ax,$2813
             out dx,ax

             mov cx,12
             mov al,byte ptr j
             cmp al,1
             jz @0
             dec cx
@0:          mov dx,$3da
@1:          in al,dx
             test al,1
             jnz @1
@2:          in al,dx
             test al,1
             jz @2
             loop @1

             mov dx,$3d4
             mov ax,$5013
             out dx,ax

             mov dx,$3da
@3:          in al,dx
             test al,1
             jnz @3
@4:          in al,dx
             test al,1
             jz @4
          END;
     END;
END;
}

PROCEDURE DrawPlasma;
VAR
   I:Integer;
BEGIN
     ASM
        mov si,offset pal
        xor cx,cx
        mov di,j
        cld
@1:     mov bx,di
        add bx,cx
        and bx,127
        mov [si+bx],cl
        mov bx,di
        add bx,127
        sub bx,cx
        and bx,127
        mov [si+bx],cl
        inc cx
        cmp cx,64
        jnz @1
     END;
     WaitScreen;
     ASM
        xor cx,cx
        mov dx,03c8h
        mov al,128
        out dx,al
        mov si,offset pal
        cld
        mov bx,start
        shl bx,1
@0:     and bx,1023
        mov ah,[bx+offset ofstable]
        mov al,13h
        mov dx,03d4h
        out dx,ax
        inc bx

        mov dx,03dah
@1:     in al,dx
        test al,1
        jnz @1

        mov dx,03c9h
        lodsb
        out dx,al
        mov al,0
        out dx,al
        out dx,al

        mov dx,03dah
@2:     in al,dx
        test al,1
        jz @2

        inc cx
        cmp cx,128
        jnz @0
     END;
     ASM
        mov si,start
        shl si,1
        add si,128
        cld
@0:     and si,1023
        mov ah,[si+offset ofstable]

        mov dx,03dah
@1:     in al,dx
        test al,1
        jnz @1

        mov al,13h
        mov dx,03d4h
        out dx,ax
        inc si

        mov dx,03dah
@2:     in al,dx
        test al,1
        jz @2

        inc cx
        cmp cx,399
        jnz @0
     END;
     WaitRetrace;
END;

BEGIN
{ General initialization of tables }
     Init13X;
     SetLineRepeat(0);
     LoadFontMCF(2,'32X64TST');
     FOR I:=0 TO 63 DO
         FOR J:=0 TO 5 DO
             StartGap[I,J]:=Round(16*J*Sin(I/64*Pi));
     Assign(F,'STANDARD.PAL');
     Reset(F,1);
     BlockRead(F,StandardPal,768);
     Close(F);
{ Part I - Palette Starfield + Transparent Text }
     LoadSprite('STARTLOG',StartLogoSpr);
     CalcFactors;
     FOR I:=0 TO 255 DO
         SetColor(I,0,0,0);
     SetColor(128,0,0,63);
     SetColor(129,0,0,31);
     PutImage4(70,140,StartLogoSpr^);
     LoadFontMCF(1,'CLEAN16');
     Phase:=0;
     I:=63;
     Gray:=0;
     REPEAT
           IF Phase<63 THEN
              Inc(Gray);
{
           IF Phase>1336 THEN
              Dec(Gray);
}
           IF Phase>=1330 THEN
           BEGIN
                DrawRectangle(Phase);
                IF Phase>=1336 THEN
                   SetColor(129,Phase-1336,Phase-1336,Phase-1336)
                ELSE SetColor(129,0,0,0);
           END;
           IF Phase<1000 THEN
           BEGIN
                MakeStar;
                MakeStar;
                MakeStar;
                MakeStar;
                MakeStar;
           END;
           VerticalRetrace;
           SetColor(I,0,0,0);
           IF I=1 THEN
              SetColor(63,Gray,Gray,Gray)
           ELSE SetColor(I-1,Gray,Gray,Gray);
           IF Phase=100 THEN
              PutString(1,72,40,'',16,TRUE)
           ELSE
           IF Phase=300 THEN
           BEGIN
                PutString(1,72,40,'GREETINGS FOLKS',16,FALSE);
                PutString(1,32,300,'THIS IS OUR NEW',16,TRUE);
           END
           ELSE
           IF Phase=500 THEN
           BEGIN
                PutString(1,32,300,'THIS IS OUR NEW',16,FALSE);
                PutString(1,12,80,'DENTRO CALLED',16,TRUE);
           END
           ELSE
           IF Phase=700 THEN
           BEGIN
                PutString(1,12,80,'DENTRO CALLED',16,FALSE);
                PutString(1,72,280,'COPPER FAKED',16,TRUE);
           END
           ELSE
           IF Phase=900 THEN
           BEGIN
                PutString(1,72,280,'COPPER FAKED',16,FALSE);
                PutString(1,20,40,'STARRING THE FAKER',16,TRUE);
           END
           ELSE
           IF Phase=1100 THEN
           BEGIN
                PutString(1,20,40,'STARRING THE FAKER',16,FALSE);
                PutString(1,0,320,'AND 4999 OTHER STARS',16,TRUE);
           END;
           IF Range(100) THEN
              PassiveTransparent(100)
           ELSE
           IF Range(300) THEN
              PassiveTransparent(300)
           ELSE
           IF Range(500) THEN
              PassiveTransparent(500)
           ELSE
           IF Range(700) THEN
              PassiveTransparent(700)
           ELSE
           IF Range(900) THEN
              PassiveTransparent(900)
           ELSE
           IF Range(1100) THEN
              PassiveTransparent(1100)
           ELSE
           BEGIN
                FOR J:=0 TO 63 DO
                    SetColor(64+I,0,0,0);
           END;
           IF I=1 THEN
              I:=63
           ELSE Dec(I);
           IF Range(100) THEN
              ActiveTransparent(100)
           ELSE
           IF Range(300) THEN
              ActiveTransparent(300)
           ELSE
           IF Range(500) THEN
              ActiveTransparent(500)
           ELSE
           IF Range(700) THEN
              ActiveTransparent(700)
           ELSE
           IF Range(900) THEN
              ActiveTransparent(900)
           ELSE
           IF Range(1100) THEN
              ActiveTransparent(1100)
           ELSE SetColor(64+I,Gray,Gray,Gray);
           Inc(Phase);
           IF NOT Cancel AND KeyPressed THEN
           BEGIN
                Cancel:=TRUE;
                Phase:=1330;
           END;
     UNTIL (Phase=1400) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;
{ Part II - Rotating Logo + Overlaying Copper Bars }
     SetColor(0,63,63,63);
     SetWriteMap(15);
     ASM
        mov ax,0a000h
        mov es,ax
        xor di,di
        mov cx,2800
        db 66h
        xor ax,ax
        cld
        db 66h
        rep stosw
        mov di,20800
        mov cx,2800
        db 66h
        rep stosw
     END;
     FOR I:=140 TO 259 DO
     BEGIN
          DrawLineH4(0,69,I,0);
          DrawLineH4(250,319,I,0);
     END;
     FOR I:=0 TO 63 DO
     BEGIN
{
          Split(I);
}
          VerticalRetrace;
          SetColor(0,63-I,63-I,63-I);
     END;
{
     SetStart(8000);
     SetHorizOfs(0);
}
     FOR I:=0 TO 127 DO
         SpiralTab[I]:=Round(255*Sin(I/64*Pi));
     FOR I:=0 TO 255 DO
         BarStartTab[I]:=127+Round(127*Sin(I/128*Pi));
     FOR I:=0 TO 63 DO
     BEGIN
          BarTab[400+I]:=I;
          BarTab[527-I]:=I;
     END;
     FOR I:=0 TO 399 DO
         BarTab[I]:=0;
     FOR I:=528 TO 799 DO
         BarTab[I]:=0;
     Phase:=0;
     Radius:=0;
     REPEAT
           CLI;
           IF Phase<1312 THEN
           BEGIN
                Start:=128*320+(SpiralTab[(Phase+32) AND 127]*Radius) DIV 256;
                OfsLines:=128+(SpiralTab[Phase AND 127]*Radius*2) DIV 256;
                SetHorizOfs(Start AND 3);
                SetStart(Start SHR 2);
           END
           ELSE
           IF Phase=1312 THEN
           BEGIN
                OfsLines:=0;
                SetStart(0);
                SetHorizOfs(0);
                Split(124);
           END;
           IF Phase<61+9 THEN
              StartR:=255+61+9-Phase
           ELSE
           IF Phase<957 THEN
              StartR:=BarStartTab[Phase AND 255]
           ELSE
           IF Phase>1297 THEN
              StartR:=1297-Phase
           ELSE StartR:=0;
           IF Phase<103 THEN
              StartG:=383
           ELSE
           IF Phase<231+9 THEN
              StartG:=255+231+9-Phase
           ELSE
           IF Phase<1127 THEN
              StartG:=BarStartTab[(Phase+86) AND 255]
           ELSE
           IF Phase>1297 THEN
              StartG:=1297-Phase
           ELSE StartG:=0;
           IF Phase<273 THEN
              StartB:=383
           ELSE
           IF Phase<401+9 THEN
              StartB:=255+401+9-Phase
           ELSE
           IF Phase<1042 THEN
              StartB:=BarStartTab[(Phase+172) AND 255]
           ELSE
           IF Phase>1297 THEN
              StartB:=1297-Phase
           ELSE StartB:=0;
           IF Phase>1297 THEN
           BEGIN
                StartR:=0;
                StartG:=0;
                StartB:=0;
           END;
{
           IF Phase>1367 THEN
           BEGIN
                C:=0;
                IncC:=16128 DIV (64-(Phase-1367));
                FOR I:=0 TO 127 DO
                BEGIN
                     BarTab[400+I]:=C SHR 8;
                     Inc(C,IncC);
                     IF (C<0) OR (C>16383) THEN
                     BEGIN
                          Dec(C,IncC);
                          IncC:=-IncC;
                     END;
                END;
           END;
}
           SetColor(0,0,0,0);
           SetOffset(0);
           VerticalRetrace;
           FOR I:=0 TO 7 DO
           BEGIN
                IF I=OfsLines THEN
                   SetOffset(40);
                Wait4Line;
           END;
           FOR I:=0 TO 383 DO
           BEGIN
                IF I+8=OfsLines THEN
                   SetOffset(40);
                SetColor(0,BarTab[(144+StartR) AND 511],BarTab[(144+StartG) AND 511],BarTab[(144+StartB) AND 511]);
                Wait4Line;
                Inc(StartR);
                Inc(StartG);
                Inc(StartB);
           END;
           SetColor(0,0,0,0);
           FOR I:=0 TO 7 DO
           BEGIN
                IF I=OfsLines THEN
                   SetOffset(40);
                Wait4Line;
           END;
           IF (Phase<256) AND (Phase AND 3=0) THEN
              Inc(Radius);
           Inc(Phase);
           STI;
     UNTIL (Phase=1425) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

{ Phase III - Bouncing Scroller }

     ASM
        mov dx,03c8h
        mov al,0
        out dx,al
        out dx,al
        out dx,al
        mov si,offset standardpal
        mov cx,768
        inc dx
        cld
        rep outsb
     END;
     SetColor(128,0,0,63);
     Port[$3C0]:=$10;
     Port[$3C0]:=Port[$3C1] OR $20;
     SetLineRepeat(0);
     Split(200);
     ScrollText1:='A A A A AAAA';
     Phase:=0;
     SetWriteMap(15);
     REPEAT
           CLI;
           SetStart($8000+Phase SHR 2);
           SetHorizOfs(Phase AND 3);
           SetWriteMap(1 SHL (Phase AND 3));
           FOR J:=0 TO 4 DO
           BEGIN
                FOR I:=0 TO 11 DO
                    Mem[$A800:(1+J*13+I)*80+Phase SHR 2+79]:=FontCh[2,Ord(ScrollText1[1+(Phase SHR 5) MOD
                        Length(ScrollText1)])]^[4+(J*12+I) SHL 5+Phase AND 31];
                Mem[$A800:(J*13)*80+Phase SHR 2+79]:=0;
           END;
           SetOffset(0);
           RasterLine:=0;
           SetColor(0,0,0,0);
           VerticalRetrace;
           IF Phase AND 127<64 THEN
              Count:=81-StartGap[Phase AND 127,5]
           ELSE Count:=81+StartGap[Phase AND 63,3];
           FOR I:=0 TO Count-1 DO
           BEGIN
                Wait4Line;
                Inc(RasterLine);
           END;
           FOR I:=1 TO 5 DO
               DrawFontBar(Phase AND 127,I);
           FOR I:=RasterLine TO 199 DO
               Wait4Line;
           SetOffset(120);
           StartR:=337;
           FOR I:=0 TO 189 DO
           BEGIN
                IF I=14 THEN
                   SetOffset(80);
                IF I=70 THEN
                   SetOffset(40);
                SetColor(0,BarTab[StartR],BarTab[StartR],BarTab[StartR]);
                Wait4Line;
                Inc(StartR);
           END;
           Inc(Phase);
           STI;
     UNTIL KeyPressed;
     SetWriteMap(15);
     ASM
        mov ax,0a800h
        mov es,ax
        xor di,di
        mov cx,8192
        db 66h
        xor ax,ax
        cld
        db 66h
        rep stosw
     END;
     IF KeyPressed THEN
        WaitKey;

{ Part IV - Vertical bars as well as horizontal ones }

     Split(511);
     SetHorizOfs(0);
     LoadPalette('STANDARD');
     FOR I:=0 TO 127 DO
         SinVertTab[I]:=Round(144*Sin(I*Pi/64));
     Phase:=0;
     Start:=21000;
     SetStart(Start);
     REPEAT
           CLI;
           ASM
              mov di,offset barline
              mov ax,ds
              mov es,ax
              mov cx,160
              xor ax,ax
              rep stosw
           END;
           FOR J:=1 TO 8 DO
               IF (Phase>23+(8-J)*72) AND (Phase<23+1512-256+J*72) THEN
               BEGIN
                    K:=144+SinVertTab[(Phase+J SHL 3) AND 127];
                    ASM
                       mov ax,ds
                       mov es,ax
                       mov di,offset barline
                       add di,k
                       mov cx,8
                       add cx,j
                       mov ax,j
                       shl ax,4
                       add al,15
@1:                    stosb
                       dec ax
                       loop @1
                       mov cx,8
                       add cx,j
                       inc ax
@2:                    stosb
                       inc ax
                       loop @2
                    END;
               END;
           IF Phase<512+32 THEN
              K:=0
           ELSE
           FOR I:=0 TO 3 DO
           BEGIN
                SetWriteMap(1 SHL I);
                ASM
                   mov si,offset barline
                   mov ax,0a000h
                   mov es,ax
                   mov di,start
                   add si,i
                   mov cx,40
                   cld
@1:                mov al,[si]
                   mov ah,[si+4]
                   add si,8
                   stosw
                   loop @1
                END;
           END;
           IF (Phase>=1120) AND (Phase<1120+112) THEN
              K:=Phase-832
           ELSE
           IF (Phase>=1120+112) AND (Phase<1120+144) THEN
              K:=400
           ELSE
           IF (Phase>=1120+144) AND (Phase<1120+256) THEN
              K:=1664-Phase
           ELSE
           IF Phase=1120+256 THEN
           BEGIN
                SetWriteMap(15);
                FillChar(Ptr($A000,21000)^,81,0);
                Start:=11040-16*80;
                SetStart(Start);
           END;
           SetOffset(0);
           WaitScreen;
           ASM
              mov si,offset barline
           END;
           FOR I:=0 TO 319 DO
           BEGIN
                IF I=K THEN
                   SetOffset(40);
                ASM
@1:                mov dx,$3da
                   in al,dx
                   test al,1
                   jnz @1

                   lodsb
                   cmp al,0
                   jnz @1a
                   mov dx,$3c8
                   out dx,al
                   inc dx
                   out dx,al
                   out dx,al
                   out dx,al
                   jmp @1b
@1a:               mov dx,$3c7
                   out dx,al
                   inc dx
                   inc dx
                   in al,dx
                   mov bh,al
                   in al,dx
                   mov bl,al
                   in al,dx
                   mov ah,al
                   mov al,0
                   dec dx
                   out dx,al
@1b:
                   mov dx,$3da
@4:                in al,dx
                   test al,1
                   jz @4
                   mov dx,$3c9
                   mov al,bh
                   out dx,al
                   mov al,bl
                   out dx,al
                   mov al,ah
                   out dx,al
                END;
           END;
           SetColor(0,0,0,0);
           FOR I:=0 TO 79 DO
           BEGIN
                IF K-320=I THEN
                   SetOffset(40);
                Wait4Line;
           END;
           WaitRetrace;
           Inc(Phase);
           STI;
     UNTIL (Phase=2048) OR KeyPressed;
     SetWriteMap(15);
     ASM
        mov ax,0a000h
        mov es,ax
        xor di,di
        mov cx,8192
        db 66h
        xor ax,ax
        cld
        db 66h
        rep stosw
     END;
     IF KeyPressed THEN
        WaitKey;

{ Phase V - Vertical Overlaying Sine Bars }

     SetStart(0);
     SetOffset(0);
     FOR I:=0 TO 1023 DO
         Line[I]:=152+Round(70*Sin(I*Pi/256)+Round(40*Sin(I*Pi/64)));
     FOR I:=0 TO 1023 DO
         Line2[I]:=Round(50*Sin(I*Pi/64));
     I:=0;
     FOR I:=1 TO 6 DO
         SetColor(I,I SHL 3+15,I SHL 3+15,0);
     Phase:=0;
     K:=0;
     Rechain;
     REPEAT
           CLI;
           IF Phase<400 THEN
              Inc(K)
           ELSE
           IF Phase>1024-400 THEN
              Dec(K);
           IF I>=1023 THEN
              I:=0
           ELSE Inc(I,4);
           SetOffset(0);
           WaitScreen;
           ASM
              mov ax,0a000h
              mov es,ax
              xor di,di
              mov cx,80
              db 66h
              xor ax,ax
              cld
              db 66h
              rep stosw
              mov si,i
              mov bx,si
           END;
           ASM
              mov cx,k
              cld
              mov dx,03dah
@1:           in al,dx
              test al,1
              jz @1
              mov di,[offset line+si]
              add di,[offset line2+bx]
              and di,7fffh
              add si,2
              and si,1023
              add bx,4
              and bx,1023
@1b:          mov ax,$0201
              stosw
              mov ax,$0403
              stosw
              mov ax,$0605
              stosw
              mov ax,$0506
              stosw
@2:           in al,dx
              test al,1
              jnz @2
              mov ax,$0304
              stosw
              mov ax,$0102
              stosw
              loop @1
           END;
           SetOffset(40);
           IF K<399 THEN
           BEGIN
                Wait4Line;
                SetOffset(0);
           END;
           WaitRetrace;
           Inc(Phase);
           STI;
     UNTIL (Phase=1024) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;

{ Part VI - Plasma }

     FOR I:=0 TO 255 DO
         SinTable[I]:=32+Round(31*Sin(I/128*Pi));
     FOR I:=0 TO 1023 DO
         OfsRel[I]:=Round(8*Sin(I/20));
     LastOfs:=OfsRel[0];
     OfsTable[0]:=80;
     FOR I:=1 TO 1023 DO
     BEGIN
          IF OfsRel[I]<>LastOfs THEN
             OfsTable[I]:=80+LastOfs-OfsRel[I]
          ELSE OfsTable[I]:=80;
          LastOfs:=OfsRel[I];
     END;
     SwitchOff;
     Unchain;
     SetLineRepeat(0);
     FOR I:=0 TO 63 DO
     BEGIN
          SetColor(128+I,I,0,0);
          SetColor(255-I,I,0,0);
     END;
     SetOffset(80);
     FOR I:=0 TO 639 DO
     BEGIN
          Adr:=I SHR 2;
          SetWriteMap(1 SHL (I AND 3));
          FOR J:=0 TO 399 DO
          BEGIN
               ASM
                  mov ah,0
                  mov bx,i
                  shr bx,1
                  mov bh,0
                  mov al,[offset sintable+bx]
                  mov bx,j
                  shl bx,1
                  mov bh,0
                  add al,[offset sintable+bx]
                  shr bx,2
                  mov bh,0
                  add al,[offset sintable+bx]
                  mov bx,i
                  add bx,j
                  shr bx,1
                  mov bh,0
                  add al,[offset sintable+bx]

                  mov bx,i
                  sub bx,j
                  mov bh,0
                  add al,[offset sintable+bx]
                  adc ah,0
{
                  mov bx,639
                  sub bx,i
                  push ax
                  mov ax,j
                  mul bx
                  shr ax,7
                  mov bl,al
                  pop ax
                  add al,[offset sintable+bx]
                  adc ah,0
                  push ax
                  mov bx,j
                  inc bx
                  mov ax,i
                  div bx
                  shr ax,5
                  mov bl,al
                  pop ax
                  add al,[offset sintable+bx]
                  adc ah,0
}
                  mov bx,j
                  shl bx,1
                  mov bh,0
                  add al,[offset sintable+bx]
                  adc ah,0
                  mov color,al
                  and al,127
                  add al,128
                  mov bx,0a000h
                  mov es,bx
                  mov di,adr
                  stosb
               END;
{
               Color:=(SinTable[Byte(I SHR 1)]+
                       SinTable[Byte(J SHR 1)]+
                       SinTable[Byte((I+J) SHR 1)]+
                       SinTable[Byte(J SHL 1)]+
                       SinTable[Byte((I-J) SHR 1)]+
                       SinTable[Byte(((639-I)*(J)) SHR 7)]+
                       SinTable[Byte((I DIV (J+1)) SHR 5)]+
                       SinTable[Byte(J SHL 1)]) SHR 1;
               Mem[$A000:Adr]:=128+Color AND 127;
}
               Inc(Adr,160);
          END;
     END;
     SwitchOn;
     J:=0;
     Start:=0;
     Dir:=1;
     SetStart(40);
     REPEAT
           CLI;
           DrawPlasma;
           Inc(Start,Dir);
           IF (Start=0) OR (Start=1023) THEN
              Dir:=-Dir;
           Inc(J,2);
           IF J>127 THEN
              J:=0;
           STI;
     UNTIL (Phase=1024) OR KeyPressed;
     IF KeyPressed THEN
        WaitKey;
     SetModeNr(3);
END.