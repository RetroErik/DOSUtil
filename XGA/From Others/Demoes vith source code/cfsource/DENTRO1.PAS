{$D-,G+,R-,S-}
PROGRAM PaletteStars;
USES
    Dos,MCGA,Font1,Font2,Gfx1,Gfx2;
CONST
     TextData:ARRAY[0..364,0..15] OF Char=(
     '                ',
     '                ',
     '                ',
     '                ',
     'NOW THE CREDITS:',
     '----------------',
     '                ',
     'CODE - THE FAKER',
     '                ',
     'GFX  - ORTHOMAN ',
     '     - SAND AND ',
     '       THE FAKER',
     '----------------',
     '                ',
     'AND THE GREETS: ',
     '                ',
     '     GROUPS:    ',
     '----------------',
     '                ',
     'AVALANCHE       ',
     '                ',
     '  BITCH         ',
     '                ',
     '    CASCADA     ',
     '                ',
     '      DUST      ',
     '                ',
     '        EMF     ',
     '                ',
     '          EPICAL',
     '                ',
     'EXTREME         ',
     '                ',
     '  ICE           ',
     '                ',
     '    IGUANA      ',
     '                ',
     '      IMPHOBIA  ',
     '                ',
     '        INFINITY',
     '                ',
     'LAST VISION     ',
     '                ',
     '  LEGEND DESIGN ',
     '                ',
     '    MAJIC 12 PC ',
     '                ',
     'MENTAL DESIGN   ',
     '                ',
     '  ONYX          ',
     '                ',
     '    PENTAGON    ',
     '                ',
     '      SILENTS PC',
     '                ',
     '        SONIC   ',
     '                ',
     'SURPRISE ! PROD.',
     '                ',
     '  SMA POSSE     ',
     '                ',
     '    TEI         ',
     '                ',
     '      TRITON    ',
     '                ',
     'ULTRAFORCE      ',
     '                ',
     '  VLA           ',
     '                ',
     '    WITAN       ',
     '                ',
     '      XOGRAPHY  ',
     '----------------',
     '                ',
     '   PERSONAL:    ',
     '----------------',
     '                ',
     'ALL GIRLS AROUND',
     '                ',
     '     ALIEN      ',
     '                ',
     '  ALPHA - AXL   ',
     '                ',
     ' ANTIBYTE - S!P ',
     '                ',
     'ANTITRACK - AARD',
     '                ',
     '     AVATAR     ',
     '                ',
     '     AXXON      ',
     '                ',
     '   AYM - PPLK   ',
     '                ',
     '     BABUU      ',
     '                ',
     '    BARFMAN     ',
     '                ',
     '    BIG HURT    ',
     '                ',
     '   BIT BLAZER   ',
     '                ',
     '    BOURBON     ',
     '                ',
     '     BROKER     ',
     '                ',
     '     BUUUD      ',
     '                ',
     ' BURNING CHROME ',
     '                ',
     '      BYTE      ',
     '                ',
     '    CAROLYN     ',
     '                ',
     '  CAPTAIN BIT   ',
     '                ',
     ' CASTERO - PPLK ',
     '                ',
     'CHICKEN - PENTA ',
     '                ',
     '     CLIPIT     ',
     '                ',
     '  CODY - AARD   ',
     '                ',
     '    COOLCAT     ',
     '                ',
     '     CRONOS     ',
     '                ',
     'CYBERSTRIKE - AV',
     '                ',
     '     DARION     ',
     '                ',
     '      DAX       ',
     '                ',
     '  DECKO - VLA   ',
     '                ',
     'DELPH - AARDVARK',
     '                ',
     '    DRAKHAI     ',
     '                ',
     '   DR. SLUDGE   ',
     '                ',
     'DUX - AVALANCHE ',
     '                ',
     ' DYNABYTE - TEI ',
     '                ',
     '     DUMDI      ',
     '                ',
     ' EPICMAN - AARD ',
     '                ',
     '     ERRAND     ',
     '                ',
     '     FAKEII     ',
     '                ',
     'FANTOMAS - PPLK ',
     '                ',
     '     FISCH      ',
     '                ',
     '   FIST - IA    ',
     '                ',
     '      FREQ      ',
     '                ',
     '     FUZZY      ',
     '                ',
     '     GLITCH     ',
     '                ',
     '    GLOGULUS    ',
     '                ',
     '   GORE - FC    ',
     '                ',
     '   GRAYGHOST    ',
     '                ',
     '   GRINDCORE    ',
     '                ',
     '     HACKER     ',
     '                ',
     '   HEADCRASH    ',
     '                ',
     ' HENCHMAN - FC  ',
     '                ',
     '      HERP      ',
     '                ',
     'INFILTRATOR - AA',
     '                ',
     '   JAKE - FC    ',
     '                ',
     ' JCAB - IGUANA  ',
     '                ',
     '  J.O.E. - S!P  ',
     '                ',
     '    KCJONES     ',
     '                ',
     'LEINAD - AVALAN ',
     '                ',
     'LEVIATHAN - SEL ',
     '                ',
     'LORD GOD XEROBE ',
     '                ',
     'LORD LOGICS - AV',
     '                ',
     '    MADMAX 1    ',
     '                ',
     'MAHLZAHN - PENTA',
     '                ',
     '   MAINFRAME    ',
     '                ',
     '    MARFADA9    ',
     '                ',
     '    MEGAFORK    ',
     '                ',
     'METAL HEAD - ICE',
     '                ',
     'MIGUEL INDURAIN ',
     '                ',
     '      MLVC      ',
     '                ',
     ' MORPHEUS - ICE ',
     '                ',
     'MOSTLY HARMLESS ',
     '                ',
     ' MR. DESTROYER  ',
     '                ',
     '  MR. FANATIC   ',
     '                ',
     '     MRFBOT     ',
     '                ',
     '      MUBA      ',
     '                ',
     'NOCTURNUS - INF ',
     '                ',
     '      NOT       ',
     '                ',
     '     NRRPF      ',
     '                ',
     '   OS - BITCH   ',
     '                ',
     'ORTHOMAN - AARD ',
     '                ',
     '     OZONE      ',
     '                ',
     'OZYMANDIA - AARD',
     '                ',
     '     PATCH      ',
     '                ',
     '   PECI - S!P   ',
     '                ',
     '     PELUSA     ',
     '                ',
     '     PENGO      ',
     '                ',
     '     PENMAN     ',
     '                ',
     '   PICHATORO    ',
     '                ',
     '    PIERCER     ',
     '                ',
     '     PRESTO     ',
     '                ',
     '      PRU2      ',
     '                ',
     '      PRU3      ',
     '                ',
     '     RANIK      ',
     '                ',
     '  RAPSCALLION   ',
     '                ',
     '  REEBOK - S!P  ',
     '                ',
     'RENEGADE BITHEAD',
     '                ',
     ' RICK DANGEROUS ',
     '                ',
     '   RIVERWIND    ',
     '                ',
     ' RUNNER - AARD  ',
     '                ',
     '      RWB       ',
     '                ',
     '      SAND      ',
     '                ',
     '   SHADDAM IV   ',
     '                ',
     '     SHARPB     ',
     '                ',
     '     SIRINE     ',
     '                ',
     '   SLAUGHTER    ',
     '                ',
     '    SMARTIE     ',
     '                ',
     'SOUL REBEL - AV ',
     '                ',
     '     SPEEDY     ',
     '                ',
     '  SPIKE - S!P   ',
     '                ',
     '     SQUIZ      ',
     '                ',
     '      TAB       ',
     '                ',
     '      TDK       ',
     '                ',
     '     TENAR      ',
     '                ',
     '   TERMX - IA   ',
     '                ',
     '    THE FOX     ',
     '                ',
     'THE GUILD MASTER',
     '                ',
     '   THE KABAL    ',
     '                ',
     ' THE KNIGHT ORC ',
     '                ',
     '     TIKES      ',
     '                ',
     '      TILT      ',
     '                ',
     '    TONEDEF     ',
     '                ',
     '   TRAVELLER    ',
     '                ',
     '     TRONIX     ',
     '                ',
     '   TRUG - FC    ',
     '                ',
     '     VINIT      ',
     '                ',
     ' VOLVOX - PPLK  ',
     '                ',
     '     WAMSY      ',
     '                ',
     '  WAR DOG - LV  ',
     '                ',
     ' WILDFIRE - FC  ',
     '                ',
     '   WREAM - AV   ',
     '                ',
     '     X-RAY      ',
     '                ',
     'ZAX - AVALANCHE ',
     '                ',
     '      ZEUS      ',
     '                ',
     '     ZIGZAG     ',
     '                ',
     'ZYRIX - EXTREME ',
     '----------------',
     '                ',
     '  END OF TEXT   ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ',
     '                ');
     MultText:ARRAY[0..7] OF String=(
'       HMM... WHAT SHOULD I SAY ...                                          ',
'     WHAT YOU DON''T SEE HERE: THE 8 SCROLLERS ON THE OTHER PAGE!            ',
'   DIFFERENT SPEED AND ROTATING WASN''T POSSIBLE, NEXT TIME MAYBE?           ',
' THIS IS THE MIDDLE LINE --- AND THE MIDDLE OF THIS DENTRO ---               ',
'IT''S THE 26TH DECEMBER AND I FEEL BLUE ...                                  ',
'  THEY SAY, IT''S MY NAME-DAY TODAY ...        AND A KISS FOR AVIVA          ',
'    WELL, ASM''93 WAS REALLY FUN! THOUGH NOT GOOD ORGANIZED ...              ',
'      LOOK OUT TO THE COMING AARDVARK PRODUCTIONS AVAILABLE SOON...          ');
TYPE
    ByteArray=ARRAY[0..65534] OF Byte;
    LineType=ARRAY[0..3,0..79] OF Byte;
    PalType=ARRAY[0..255,1..3] OF Byte;
    OfsType=ARRAY[34..199,0..199] OF Byte;
VAR
   StartLogoSpr:Pointer;
   FontCh:ARRAY[1..4,0..255] OF ^ByteArray;
   L,Color,Gray,BeginPart:Byte;
   I,J,K,Phase,Radius,StartR,StartG,StartB,OfsLines,Count,RasterLine,C,IncC,
   Dir,LastOfs,Factor,Size,X,Y,XCountCurr,LastCos,CurrCos,Phase2:Integer;
   SpiralTab:ARRAY[0..127] OF Integer;
   BarTab:ARRAY[0..799] OF Byte;
   BarStartTab:ARRAY[0..255] OF Integer;
   SinVertTab:ARRAY[0..127] OF Integer;
   Adr,Start,Shade:Word;
   Cancel:Boolean;
   BarLine:ARRAY[0..319] OF Byte;
   Factors:ARRAY[0..63] OF Integer;
   StartGap:ARRAY[0..63,0..5] OF Integer;
   AardTextSpr:Pointer;
   ScrollText1:String;
   AardPicPal:PalType;
   F:File;
   TextF:Text;
   Line:ARRAY[0..1023] OF Word;
   Line2:ARRAY[0..1023] OF Integer;
   OfsRel,OfsTable:ARRAY[0..1023] OF Integer;
   SinTable:ARRAY[0..255] OF Byte;
   ColorTab,GapTab:ARRAY[0..399] OF Byte;
   StartMap,EndMap,R,G,B,PalSel:Byte;
   XCount,YCount,SizeX,DirX,PhaseX:ARRAY[0..3] OF Integer;
   LineData,LineData2:ARRAY[0..255] OF ^LineType;
   DisplayStart:ARRAY[0..799] OF ShortInt;
   Spr,BallLightSpr,EarthMapSpr:Pointer;
   OfsTable2:^OfsType;
   PlasmaPal:ARRAY[0..127] OF Byte;
   Line640:ARRAY[0..639] OF Byte;
   BallPal,Pal,Palette:PalType;
   SpherePal:ARRAY[0..63] OF ^PalType;
   LightTable:ARRAY[0..255] OF Byte;
   SphereMap:ARRAY[0..15,0..15] OF Word;
   EarthFrame:ARRAY[0..255] OF Byte;
   ArcSinTable:ARRAY[-255..255] OF Real;
   SinTab,CosTab:ARRAY[0..255] OF Integer;
   CheckerSinTab,CheckerCosTab:ARRAY[0..255] OF Integer;
   XLATTable:ARRAY[0..63] OF Byte;
   MultOfsTable:ARRAY[0..31,0..31] OF Byte;
   MultCount:ARRAY[0..7] OF Word;
   SaveInt09,MODData:Pointer;
   Key:ARRAY[0..127] OF Boolean;
   Pressed,Tseng:Boolean;

PROCEDURE ANSIProc; EXTERNAL;
{$L ANSICPFK.OBJ }

PROCEDURE NewInt09; INTERRUPT;
VAR
   KeyCode:Byte;
BEGIN
     ASM
        in al,60h
        mov keycode,al
        in al,61h
        mov ah,al
        or al,80h
        out 61h,al
        mov al,ah
        out 61h,al
        mov al,20h
        out 20h,al
     END;
     IF KeyCode<128 THEN
        Key[KeyCode]:=TRUE
     ELSE Key[KeyCode AND 127]:=FALSE;
END;

PROCEDURE GetAdjMem(VAR P:Pointer; Size:Word);
BEGIN
     IF Word(Size+15)>Size THEN
        Inc(Size,15)
     ELSE Size:=65535;
     GetMem(P,Size);
     IF Ofs(P^)<>0 THEN
        P:=Ptr(Seg(P^)+1,0);
END;

PROCEDURE EndDemo;
BEGIN
     SetModeNr(3);
     ANSIProc;
     SetIntVec($09,SaveInt09);
     Halt;
END;

FUNCTION KeyCheck:Boolean;
BEGIN
     IF Key[1] THEN
        EndDemo;
     IF Pressed THEN
        KeyCheck:=FALSE
     ELSE
     BEGIN
          Pressed:=Key[28] OR Key[57];
          KeyCheck:=Pressed;
     END;
     IF Pressed AND NOT Key[28] AND NOT Key[57] THEN
        Pressed:=FALSE;
END;

PROCEDURE LoadFontMCF(Font:Byte; FontData:Pointer);
VAR
   I,X,Y:Integer;
   LongAdr:LongInt;
BEGIN
     FOR I:=0 TO 255 DO
     BEGIN
          FontCh[Font,I]:=FontData;
          X:=Mem[Seg(FontData^):Ofs(FontData^)];
          Y:=Mem[Seg(FontData^):Ofs(FontData^)+2];
          LongAdr:=LongInt(Seg(FontData^)) SHL 4+Ofs(FontData^);
          IF X*Y<>0 THEN
             Inc(LongAdr,(X+1)*(Y+1));
          Inc(LongAdr,4);
          FontData:=Ptr(LongAdr SHR 4,LongAdr AND 15);
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
             mov bx,ax
             inc bx
             lodsw
             add si,i
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
             mov bx,ax
             inc bx
             lodsw
             add si,i
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
          XP:=Factors[I];
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
         Factors[I]:=65535 DIV (I+8);
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
            SetColor(64+I,0,Ph,0)
     ELSE
     FOR I:=0 TO 63 DO
         SetColor(64+I,0,(191-Ph) SHR 1,0);
END;

FUNCTION Range(Nr:Integer):Boolean;
BEGIN
     Range:=(Phase>=Nr) AND (Phase<=Nr+191);
END;

PROCEDURE DrawRectangle(Ph:Integer);
BEGIN
     DrawLineH4(1399-Ph,Ph-1080,(1400-Ph) SHL 1-2,128);
     DrawLineH4(1399-Ph,Ph-1080,(1400-Ph) SHL 1-1,128);
     DrawLineH4(1399-Ph,Ph-1080,(Ph-1200) SHL 1,128);
     DrawLineH4(1399-Ph,Ph-1080,(Ph-1200) SHL 1+1,128);
     DrawLineV4(1399-Ph,(1400-Ph) SHL 1,(Ph-1200) SHL 1-1,128);
     DrawLineV4(Ph-1080,(1400-Ph) SHL 1,(Ph-1200) SHL 1-1,128);
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

PROCEDURE DrawPlasma;
BEGIN
     ASM
        mov si,offset plasmapal
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
        mov si,offset plasmapal
        cld
        mov bx,start
        shl bx,1
@0:     and bx,1023
        mov ah,byte ptr [bx+offset ofstable]
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
        mov ah,byte ptr [si+offset ofstable]

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
              BallPal[J SHL 4+I,1]:=C SHL 2;
              BallPal[J SHL 4+I,2]:=C SHL 2;
              BallPal[J SHL 4+I,3]:=C SHL 2;
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

PROCEDURE PutLine2(Nr:Integer);
VAR
   I,J:Integer;
BEGIN
     ASM
        push ds
        mov ax,0a000h
        mov es,ax
        mov bx,nr
        shl bx,2
        add bx,offset linedata2
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

PROCEDURE CalcLines2;
VAR
   I,J,K,L,X,XInc:Integer;
   Map:Byte;
   LineX:LineType;
BEGIN
     FOR J:=16 TO 127 DO
     BEGIN
          New(LineData2[J]);
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
              LineData2[J]^:=LineX;
     END;
END;

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
        lds si,dword ptr [si+offset spherepal]
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
     FOR J:=0 TO 15 DO
     BEGIN
          Y:=J-8;
          Y2:=ArcSin((255*Y)/8/256)/Pi*2;
          YSqrt:=Sqrt(1-Sqr(Y/8))*8;
          YSqr:=Sqr(Y);
          FOR I:=0 TO 15 DO
          BEGIN
               X:=I-8;
               IF Sqr(X)+YSqr<64 THEN
               BEGIN
                    X2:=ArcSin(255*X/YSqrt/256)/Pi*2;
                    SphereMap[J,I]:=(10+Round(Y2*15)) SHL 6+16+Round(X2*15)
               END
               ELSE SphereMap[J,I]:=0;
          END;
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
@2:
              END;
         END;
END;

PROCEDURE CalcOfsTable;
VAR
   I,J,CurrY,OldY,K:Integer;
   Fact:Word;
BEGIN
     New(OfsTable2);
     FOR J:=34 TO 199 DO
     BEGIN
          Fact:=Round(256/J*199);
          OldY:=199;
          FOR I:=199 DOWNTO 0 DO
              IF I>J THEN
                 OfsTable2^[J,I]:=0
              ELSE
              BEGIN
                   ASM
                      mov ax,i
                      mov bx,fact
                      mul bx
                      mov dh,dl
                      mov dl,ah
                      mov curry,dx
                   END;
                   OfsTable2^[J,I]:=40*(OldY-CurrY);
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
        mov si,offset aardpicpal
        add si,329
        mov cx,110
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
        mov ax,i
        mov di,ds
        lds si,ofstable2
        sub ax,34
        mov bx,200
        mul bx
        add si,ax
        add si,199
        mov cx,200
        std

        mov dx,3dah
@1:     in al,dx
        test al,1
        jnz @1

@2:     lodsb
        mov ah,al
        mov al,13h
        mov dx,03d4h
        out dx,ax

        cmp cx,90
        jle @3
        mov dx,03c9h
        pop ax
        out dx,al
        pop ax
        out dx,al
        pop ax
        out dx,al

@3:     mov dx,3dah
@4:     in al,dx
        test al,1
        jz @4

        loop @1
     END;
     ASM
        inc si
        cld
        mov cx,200

@1:     mov dx,3dah
        in al,dx
        test al,1
        jnz @1

@2:     lodsb
        mov ah,al
        mov al,13h
        mov dx,3d4h
        out dx,ax

        mov dx,3dah
@3:     in al,dx
        test al,1
        jz @3

        loop @1
        mov ds,di
     END;
     WaitRetrace;
END;

PROCEDURE CalcMultOfsTable;
VAR
   I,J,CurrY,OldY:Integer;
BEGIN
     FOR J:=6 TO 31 DO
     BEGIN
          OldY:=31;
          FOR I:=31 DOWNTO 0 DO
              IF I>J THEN
                 MultOfsTable[J,I]:=0
              ELSE
              BEGIN
                   CurrY:=Round(I/J*31);
                   MultOfsTable[J,I]:=40*(OldY-CurrY);
                   OldY:=CurrY;
              END;
     END;
END;

PROCEDURE PutPartChar(X,Y:Integer; Nr:Integer; TextCh:Char);
BEGIN
     ASM
        push ds
        mov ax,0a000h
        mov es,ax
        mov ax,y
        shl ax,4
        mov di,ax
        shl ax,2
        add di,ax
        mov ax,x
        add ax,start
        mov cl,al
        and cl,3
        shr ax,2
        add di,ax
        mov ax,0102h
        shl ah,cl
        mov dx,03c4h
        out dx,ax
        mov bl,textch
        mov bh,0
        shl bx,2
        add bx,offset fontch+3072
        lds si,[bx]
        add si,4
        add si,nr
        mov cx,31
        cld
@1:     lodsb
        stosb
        add di,79
        stosb
        add di,79
        add si,31
        loop @1
        pop ds
     END;
END;

PROCEDURE SetPal(VAR Palette; Count:Integer);
BEGIN
     ASM
        push ds
        mov dx,03c8h
        mov al,0
        out dx,al
        out dx,al
        out dx,al
        lds si,palette
        mov cx,count
        mov bx,cx
        shl cx,1
        add cx,bx
        inc dx
        cld
        rep outsb
        pop ds
     END;
END;

PROCEDURE SetReg(Reg:Word; Index,Value:Byte);
VAR
   B:Byte;
BEGIN
     CASE Reg OF
          $3C0:BEGIN
                    B:=Port[$3DA];
                    Port[$3C0]:=Index OR $20;
                    Port[$3C0]:=Value;
               END;
          $3C2,$3C3:Port[Reg]:=Value;
          ELSE
          BEGIN
               Port[Reg]:=Index;
               Port[Reg+1]:=Value;
          END;
     END;
END;

PROCEDURE SetModeReg(Reg:String; VAR P);
TYPE
    RegRec=RECORD
                 Reg:Word;
                 Index:Byte;
                 Value:Byte;
           END;
VAR
   RegFile:File OF RegRec;
   RegSet:ARRAY[0..36] OF RegRec ABSOLUTE P;
BEGIN
     Port[$3D4]:=$11;
     Port[$3D5]:=Port[$3D5] AND $7F;
     FOR I:=0 TO 35 DO
         WITH RegSet[I] DO
              SetReg(Reg,Index,Value);
     ClearScreen;
END;

PROCEDURE InitPartI;
BEGIN
     LoadFontMCF(2,@BluGreen);
     FOR I:=0 TO 63 DO
         FOR J:=0 TO 5 DO
             StartGap[I,J]:=Round(16*J*Sin(I/64*Pi));
     Move(@AardCpFkPal^,AardPicPal,768);
     StartLogoSpr:=@StartLogSpr;
     CalcFactors;
     LoadFontMCF(1,@WildFont);
END;

PROCEDURE InitPartII;
BEGIN
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
END;

PROCEDURE InitPartIV;
BEGIN
     FOR I:=0 TO 127 DO
         SinVertTab[I]:=Round(144*Sin(I*Pi/64));
END;

PROCEDURE InitPartV;
BEGIN
     FOR I:=0 TO 511 DO
     BEGIN
          Line[I]:=152+Round(70*Sin(I*Pi/256));
          Line[512+I]:=Line[I];
     END;
     FOR I:=0 TO 127 DO
     BEGIN
          Line2[I]:=Round(40*Sin(I*Pi/64));
          FOR J:=1 TO 7 DO
              Line2[J SHL 7+I]:=Line2[I];
     END;
     FOR I:=0 TO 1023 DO
         Inc(Line[I],Line2[I]);
END;

PROCEDURE InitPartVI;
BEGIN
     CalcMultOfsTable;
     LoadFontMCF(4,@Hollow);
     FOR K:=0 TO 7 DO
         MultCount[K]:=0;
END;

PROCEDURE InitPartVII;
BEGIN
     FOR I:=0 TO 255 DO
         SinTable[I]:=32+Round(31*Sin(I/128*Pi));
     FOR I:=0 TO 127 DO
     BEGIN
          OfsRel[I]:=Round(8*Sin(I/64*Pi));
          FOR J:=1 TO 7 DO
              OfsRel[J SHL 7+I]:=OfsRel[I];
     END;
     LastOfs:=OfsRel[0];
     OfsTable[0]:=80;
     FOR I:=1 TO 1023 DO
     BEGIN
          IF OfsRel[I]<>LastOfs THEN
             OfsTable[I]:=80+LastOfs-OfsRel[I]
          ELSE OfsTable[I]:=80;
          LastOfs:=OfsRel[I];
     END;
END;

PROCEDURE InitPartVIII;
BEGIN
     FOR I:=0 TO 127 DO
     BEGIN
          FOR J:=0 TO 1 DO
          BEGIN
               SinTab[J SHL 7+I]:=Round(64*Sin(I/64*Pi));
               CosTab[J SHL 7+I]:=Round(200*Cos(I/64*Pi));
          END;
     END;
     CalcBall;
     CalcLines;
END;

PROCEDURE InitPartIX;
VAR
   P:Pointer;
BEGIN
     CalcEarth;
     Move(@EarthMapData^,Palette,768);
     GetAdjMem(EarthMapSpr,1344);
     P:=@EarthMapData;
     P:=Ptr(Seg(P^),Ofs(P^)+768);
     Move(P^,EarthMapSpr^,1344);
     P:=@BalLightSpr;
     P:=Ptr(Seg(P^),Ofs(P^)+4);
     Move(P^,EarthMapSpr^,1344);
{
     Move(Ptr(Seg(@EarthMapData^),Ofs(@EarthMapData^)+768)^,EarthMapSpr^,1344);
     Move(Ptr(Seg(@BalLightSpr^),Ofs(@BalLightSpr^)+4)^,LightTable,256);
}
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
END;

PROCEDURE InitPartX;
BEGIN
     FOR I:=0 TO 127 DO
     BEGIN
          FOR J:=0 TO 1 DO
          BEGIN
               CheckerSinTab[J SHL 7+I]:=Round(128*Sin(I/64*Pi));
               CheckerCosTab[J SHL 7+I]:=Round(128*Cos(I/64*Pi));
          END;
     END;
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
END;

PROCEDURE InitPartXI;
BEGIN
     CalcOfsTable;
     FOR I:=0 TO 99 DO
     BEGIN
          DisplayStart[I]:=Round(20*Sin(I/50*Pi));
          FOR J:=1 TO 7 DO
              DisplayStart[J*100+I]:=DisplayStart[I];
     END;
END;

PROCEDURE InitPartXIII;
BEGIN
     LoadFontMCF(3,@Clean16);
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
END;

{ Part I - Palette Starfield + Transparent Text }

PROCEDURE PartI;
BEGIN
     Init13X;
     SetLineRepeat(0);
     SwitchOff;
     FOR I:=0 TO 255 DO
         SetColor(I,0,0,0);
     SetPal(@StartLogPal^,256);
     PutImage4(70,140,StartLogoSpr^);
     SwitchOn;
     Phase:=0;
     I:=63;
     Gray:=0;
     REPEAT
           CLI;
           IF Phase<63 THEN
              Inc(Gray);
           IF Phase>=1330 THEN
           BEGIN
                DrawRectangle(Phase);
                IF Phase>=1336 THEN
                   SetColor(128,Phase-1336,Phase-1336,Phase-1336)
                ELSE SetColor(128,0,0,0);
           END;
           IF Phase<1250 THEN
           BEGIN
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
           IF NOT Cancel AND KeyCheck THEN
           BEGIN
                Cancel:=TRUE;
                Phase:=1330;
           END;
           STI;
     UNTIL (Phase=1400) OR KeyCheck;
END;

{ Part II - Rotating Logo + Overlaying Copper Bars }

PROCEDURE PartII;
BEGIN
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
          VerticalRetrace;
          SetColor(0,63-I,63-I,63-I);
     END;
     Phase:=0;
     Radius:=0;
     REPEAT
           CLI;
           IF Phase<1312 THEN
           BEGIN
                ASM
                   mov si,phase
                   add si,32
                   and si,127
                   shl si,1
                   mov ax,word ptr [si+offset spiraltab]
                   imul radius
                   mov al,ah
                   mov ah,dl
                   add ax,128*320
                   mov start,ax

                   mov si,phase
                   and si,127
                   shl si,1
                   mov ax,word ptr [si+offset spiraltab]
                   shl ax,1
                   imul radius
                   mov al,ah
                   mov ah,dl
                   add ax,128
                   mov ofslines,ax
                END;
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
                ASM
                   mov dx,3c8h
                   mov al,0
                   out dx,al
                   inc dx
                   mov si,144
                   add si,startr
                   and si,511
                   add si,offset bartab
                   outsb
                   mov si,144
                   add si,startg
                   and si,511
                   add si,offset bartab
                   outsb
                   mov si,144
                   add si,startb
                   and si,511
                   add si,offset bartab
                   outsb

                   mov dx,3dah
@1:                in al,dx
                   test al,1
                   jnz @1
                   mov dx,3dah
@2:                in al,dx
                   test al,1
                   jz @2
                END;
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
     UNTIL (Phase=1425) OR KeyCheck;
END;

{ Phase III - Bouncing Scroller }

PROCEDURE PartIII;
BEGIN
     Port[$3D4]:=$11;
     Port[$3D5]:=Port[$3D5] AND $7F;
     Port[$3D4]:=1;
     Port[$3D5]:=Port[$3D5]-1;
     SetPal(@BluGreenPal^,64);
     Port[$3C0]:=$10;
     Port[$3C0]:=Port[$3C1] OR $20;
     SetLineRepeat(0);
     Split(201);
     ScrollText1:='THIS DENTRO IS THE FORMAL ANNOUNCATION OF OUR COMING LARGE DEMO ...             ';
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
                    Mem[$A800:(1+J*13+I)*80+Phase SHR 2+79]:=FontCh[2,Ord(ScrollText1[1+Phase SHR 5])]^
                       [4+(J*6+I SHR 1) SHL 5+Phase AND 31];
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
     UNTIL (Phase=2048+512) OR KeyCheck;
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
     Port[$3D4]:=1;
     Port[$3D5]:=Port[$3D5]+1;
END;

{ Part IV - Vertical bars as well as horizontal ones }

PROCEDURE PartIV;
BEGIN
     SetPal(@StandardXPal^,128);
     Split(511);
     SetHorizOfs(0);
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
           FOR J:=2 TO 8 DO
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
                       dec al
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
     UNTIL (Phase=2048-64) OR KeyCheck;
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
END;

{ Phase V - Vertical Overlaying Sine Bars }

PROCEDURE PartV;
BEGIN
     SetStart(0);
     SetOffset(0);
     I:=0;
     FOR I:=1 TO 6 DO
         SetColor(I,I SHL 3+15,I SHL 3+15,0);
     Phase:=0;
     K:=0;
     Start:=0;
     Rechain;
     REPEAT
           CLI;
           IF Phase<200 THEN
              Inc(K,2)
           ELSE
           IF Phase>768-80 THEN
              Inc(Start);
           IF I>=1023 THEN
              I:=0
           ELSE Inc(I,4);
           SetStart(Start);
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
              mov di,word ptr [offset line+si]
              add di,word ptr [offset line2+bx]
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
     UNTIL (Phase=768) OR KeyCheck;
END;

{ Part VI - Multi Scroller }

PROCEDURE PartVI;
VAR
   Ph:Integer;
BEGIN
     Init13X;
     SetPal(@StandardXPal^,256);
     SetLineRepeat(0);
     Start:=0;
     Ph:=127;
     Dir:=-1;
     Start:=0;
     Phase:=0;
     REPEAT
           CLI;
           FOR I:=0 TO 7 DO
           BEGIN
                PutPartChar(319,1+I*62,Start AND 31,MultText[I,1+MultCount[I] SHR 5]);
                Inc(MultCount[I]);
           END;
           SetHorizOfs(Start AND 3);
           SetStart(Start SHR 2);
           Inc(Start);
           SetOffset(0);
           VerticalRetrace;
           Wait4Line;
           Phase2:=Ph SHR 2;
           FOR I:=0 TO 7 DO
           BEGIN
                ASM
                   mov cx,phase2
                   shl cl,1
                   mov ax,i
                   and ax,1
                   inc ax
                   xor bx,bx
                   rcr al,1
                   jnc @1
                   mov ah,cl
@1:                rcr al,1
                   jnc @2
                   mov bl,cl
@2:                rcr al,1
                   jnc @3
                   mov bh,cl
@3:                mov dx,03c8h
                   mov al,151
                   out dx,al
                   inc dx
                   mov al,ah
                   out dx,al
                   mov al,bl
                   out dx,al
                   mov al,bh
                   out dx,al
                END;
                ASM
                   mov si,phase2
                   shl si,5
                   add si,31
                   add si,offset multofstable
                   mov cx,32
                   std
@1:                lodsb
                   mov ah,al
                   mov al,13h
                   mov dx,03d4h
                   out dx,ax
                   or ah,ah
                   jnz @2
                   mov ax,i
                   or ax,ax
                   jnz @5
@2:                mov dx,03dah
@3:                in al,dx
                   test al,1
                   jnz @3
@4:                in al,dx
                   test al,1
                   jz @4
@5:                loop @1
                END;
                ASM
                   mov cx,32
                   inc si
                   cld
@1:                lodsb
                   mov ah,al
                   mov al,13h
                   mov dx,03d4h
                   out dx,ax
                   or ah,ah
                   jz @5
                   mov dx,03dah
@3:                in al,dx
                   test al,1
                   jnz @3
@4:                in al,dx
                   test al,1
                   jz @4
@5:                loop @1
                END;
                Phase2:=37-Phase2;
           END;
           SetOffset(40);
           Inc(Ph,Dir);
           IF (Ph=24) OR (Ph=127) THEN
              Dir:=-Dir;
           Inc(Phase);
           STI;
     UNTIL (Phase=2048+384) OR KeyCheck;
END;

{ Part VII - Plasma }

PROCEDURE PartVII;
BEGIN
     SetStart(0);
     FOR I:=0 TO 255 DO
         SetColor(I,0,0,0);
     FOR I:=0 TO 63 DO
     BEGIN
          SetColor(128+I,I,0,0);
          SetColor(255-I,I,0,0);
     END;
     SetOffset(80);
     SwitchOff;
     FOR I:=30 TO 609 DO
     BEGIN
          Adr:=I SHR 2;
          SetWriteMap(1 SHL (I AND 3));
          ASM
             mov ax,0a000h
             mov es,ax
             mov di,adr
          END;
          FOR J:=0 TO 399 DO
          BEGIN
               ASM
                  mov si,offset sintable
                  xor ax,ax
                  mov bx,i
                  shr bx,1
                  mov bh,0
                  mov al,[bx+si]
                  mov bx,j
                  shr bx,2
                  mov bh,0
                  add al,[bx+si]
                  mov bx,i
                  add bx,j
                  shr bx,1
                  mov bh,0
                  add al,[bx+si]
                  mov bx,j
                  shl bx,1
                  mov bh,0
                  add al,[bx+si]
                  push ax
                  mov bx,i
                  sub bx,j
                  sar bx,1
                  mov bh,0
                  mov dl,[bx+si]
                  mov bx,j
                  shr bx,1
                  mov bh,0
                  add dl,[bx+si]
                  push dx
                  mov bx,639
                  sub bx,i
                  mov ax,j
                  mul bx
                  shr ax,7
                  mov bx,ax
                  mov bh,0
                  pop dx
                  add dl,[bx+si]
                  push dx
                  mov ax,i
                  xor dx,dx
                  mov bx,j
                  inc bx
                  div bx
                  shr ax,5
                  mov bx,ax
                  mov bh,0
                  pop dx
                  add dl,[bx+si]
                  mov dh,0
                  pop ax
                  add ax,dx
                  shr ax,1
                  and al,127
                  add al,128
                  stosb
                  add di,159
               END;
          END;
     END;
     Unchain;
     SwitchOn;
     J:=0;
     Start:=0;
     Dir:=1;
     SetStart(40);
     Phase:=0;
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
           Inc(Phase);
     UNTIL (Phase=1024) OR KeyCheck;
END;

{ Part VIII - Big Zoom of Ball, 32x32 }

PROCEDURE PartVIII;
BEGIN
     SetModeNr($0D);
     Init16Pal;
     SetPal(BallPal,256);
     SetOffset(0);
     Factor:=16;
     Dir:=2;
     Phase:=0;
     REPEAT
           CLI;
           IF Phase AND 511<118 THEN
              Factor:=16+Byte(Phase) SHL 1
           ELSE
           IF Phase AND 511<394 THEN
              Factor:=250
           ELSE Factor:=250-(Phase-394) SHL 1;
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
     UNTIL (Phase=768) OR KeyCheck;
END;

{ Part IX - Animated Zoom, 16x16 }

PROCEDURE PartIX;
BEGIN
     Factor:=16;
     Dir:=1;
     Phase:=0;
     SetOffset(0);
     REPEAT
           CLI;
           IF Byte(Phase)<111 THEN
              Factor:=126-Byte(Phase)
           ELSE
           IF Byte(Phase)<222 THEN
              Factor:=16+Byte(Phase)-111
           ELSE Factor:=127;
           PutLine2(Factor);
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
     UNTIL (Phase=1024) OR KeyCheck;
END;

{ Part X - Overlaying Checkers }

PROCEDURE PartX;
BEGIN
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
     SetStart(0);
     SetHorizOfs(0);
     FOR I:=0 TO 15 DO
         SetColor(128+I,0,0,0);
     StartMap:=0;
     EndMap:=1;
     SetOffset(0);
     Phase:=0;
     REPEAT
           CLI;
           PalSel:=0;
           FOR I:=StartMap TO EndMap-1 DO
               YCount[I]:=CheckerSinTab[PhaseX[I]]-200;
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
                XCountCurr:=CheckerCosTab[PhaseX[I]]-160;
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
           IF Phase=1536 THEN
              StartMap:=1
           ELSE
           IF Phase=2048 THEN
              StartMap:=2;
           STI;
     UNTIL (Phase=2048+256) OR KeyCheck;
END;

{ Part XI - Screen wobbler }

PROCEDURE PartXI;
BEGIN
     Init13X;
     SwitchOff;
     SetPal(@AardCpFkPal^,256);
     SetLineRepeat(0);
     Spr:=@AardCpFkSpr;
     SetColor(0,0,0,0);
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
     SwitchOn;
     Phase:=0;
     K:=0;
     REPEAT
           CLI;
           VerticalRetrace;
           J:=(Phase MOD 200) SHL 1;
           IF Phase<63 THEN
              Inc(K)
           ELSE
           IF Phase>448 THEN
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
     UNTIL (Phase=512) OR KeyCheck;
END;

{ Part XII - Screen rotate off }

PROCEDURE PartXII;
BEGIN
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
     UNTIL (Phase=970) OR KeyCheck;
END;

{ Part XIII - Roundscroller with Greetings }

PROCEDURE PartXIII;
BEGIN
     ClearScreen;
     MCGAOn;
     SetModeReg('256X400',@R256X400Reg^);
     Unchain;
     FOR I:=0 TO 15 DO
         SetColor(I,31,I SHL 2,I SHL 2);
     Phase:=0;
     K:=0;
     VerticalRetrace;
     REPEAT
           CLI;
           SetColor(0,0,0,0);
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
           SetColor(0,0,0,0);
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
                  shl si,4
                  add si,i
                  add si,offset textdata
                  lodsb
                  mov ah,0
                  shl ax,2
                  mov si,offset fontch+2048
                  add si,ax
                  lds si,[si]
                  pop ax
                  and ax,15
                  shl ax,4
                  add ax,4
                  add si,ax
                  mov cx,16
@1:               lodsb
                  mov es:[di+bx],al
                  add bl,64
                  adc bl,0
                  loop @1
                  push es
                  pop ds
               END;
           FOR L:=0 TO 1 DO
           BEGIN
                IF Tseng THEN
                   ASM
                      mov dx,03cdh
                      mov al,l
                      out dx,al
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
           END;
           Inc(Phase);
           IF Phase<255 THEN
              Inc(K)
           ELSE
           IF Phase=5696-256 THEN
              Dec(K);
           STI;
     UNTIL (Phase=5696) OR KeyCheck;
END;

FUNCTION CheckForVGA:Boolean;
BEGIN
     ASM
        xor bx,bx
        mov ax,01a00h
        int 10h
        cmp bl,7
        jb @1
        cmp bl,0ch
        ja @1
        mov @result,true
        jmp @2
@1:     mov @result,false
@2:
     END;
END;

FUNCTION CheckFor386:Boolean;
BEGIN
     ASM
        pushf
        xor ah,ah
        push ax
        popf
        pushf
        pop ax
        and ah,0f0h
        cmp ah,0f0h
        je @1
        mov ah,0f0h
        push ax
        popf
        pushf
        pop ax
        and ah,0f0h
        jz @1
        popf
        mov @result,true
        jmp @2
@1:     mov @result,false
@2:
     END;
END;

FUNCTION CheckForVirtual:Boolean;
BEGIN
     ASM
        smsw ax
        test al,1
        jz @1
        mov @result,true
        jmp @2
@1:     mov @result,false
@2:
     END;
END;

PROCEDURE DetectTseng;
VAR
   Dummy,OldValue,NewValue,Value:Byte;
BEGIN
     Port[$3BF]:=3;
     IF Port[$3CC] AND 1=1 THEN
        Port[$3D8]:=$A0
     ELSE Port[$3B8]:=$A0;
     Dummy:=Port[$3DA];
     Port[$3C0]:=$16;
     OldValue:=Port[$3C1];
     Dummy:=Port[$3DA];
     Port[$3C0]:=$16;
     NewValue:=OldValue XOR $10;
     Port[$3C0]:=NewValue;
     Dummy:=Port[$3DA];
     Port[$3C0]:=$16;
     Value:=Port[$3C1];
     Dummy:=Port[$3DA];
     Port[$3C0]:=$16;
     Port[$3C0]:=OldValue;
     Tseng:=Value=NewValue;
END;

PROCEDURE CheckIt;
BEGIN
     Write('Detecting available memory ... ');
     InitPartII;
     InitPartIV;
     InitPartV;
     InitPartVII;
     InitPartX;
     IF MemAvail>160000 THEN
        WriteLn(' Ok, ',MemAvail-160000,' bytes more than needed.')
     ELSE
     BEGIN
          WriteLn(' not enough found! About',160000-MemAvail,' bytes more needed to run this.',#7);
          Halt(3);
     END;
     Write('Detecting VGA ... ');
     InitPartI;
     InitPartVI;
     IF CheckForVGA THEN
        WriteLn('Ok.')
     ELSE
     BEGIN
          WriteLn('not found! You need a VGA card to run this.',#7);
          Halt(1);
     END;
     Write('Detecting 386 ... ');
     InitPartVIII;
     IF CheckFor386 THEN
        WriteLn('Ok.')
     ELSE
     BEGIN
          WriteLn('not found! You need at least a 386 processor to run this.',#7);
          Halt(2);
     END;
     Write('Detecting processor mode ... ');
     InitPartIX;
     IF CheckForVirtual THEN
        WriteLn(' Ok, running in V8086 mode.')
     ELSE WriteLn(' Ok, running in native 80386 mode.');
     InitPartXI;
     InitPartXIII;
     DetectTseng;
END;

BEGIN
     ASM
        mov ax,3
        int $10
     END;
     CheckIt;
     FOR I:=0 TO 127 DO
         Key[I]:=FALSE;
     Pressed:=FALSE;
     GetIntVec($09,SaveInt09);
     SetIntVec($09,@NewInt09);
     IF ParamCount<>0 THEN
        Val(ParamStr(1),BeginPart,I)
     ELSE BeginPart:=0;
     PartI;
     PartII;
     PartIII;
     PartIV;
     PartV;
     PartVI;
     PartVII;
     PartVIII;
     PartIX;
     PartX;
     PartXI;
     PartXII;
     PartXIII;
     EndDemo;
END.
