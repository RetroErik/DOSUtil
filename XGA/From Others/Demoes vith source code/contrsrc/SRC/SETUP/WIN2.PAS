{***************************************************************************
*  WinDummy : appel‚ par un Close sur la variable fichier OUTPUT           *
**------------------------------------------------------------------------**
*  Entr‚e : F = variable fichier Output de type TextRec                    *
*  Sortie : Doit renvoyer 0 par d‚finition (= pas d'erreur)                *
*  Variables globales : n‚ant                                              *
***************************************************************************}

{$F+}    { doit ˆtre FAR }

function WinDummy( var f : TextRec ) : integer;

begin
  WinDummy := 0;    { Retourne syst‚matiquement 0 }
end;

{$F-}

{***************************************************************************
*  WinWriteln : d‚clench‚ par Turbo Pascal lors d'un appel … WRITE ou      *
*               WRITELN associ‚ … la variable fichier OUTPUT               *
**------------------------------------------------------------------------**
*  Entr‚e : F = variable fichier Output de type TextRec                    *
*  Sortie : Doit renvoyer 0 par d‚finition (= pas d'erreur)                *
*  Variables globales : Write2View/R, WritelnX/RW, WritelnY/RW,            *
*                       WritelnPtr/RW, ViewX1/R, ViewY1/R, ViewX2/R,       *
*                       ViewY2/R                                           *
***************************************************************************}

{$F+}   { Doit ˆtre FAR }

function WinWriteln( var f : TextRec ) : integer;

var i    : integer;    { Compteur d'it‚rations }
    Carptr : BPTR;     { Pointe sur le caractŠre … afficher  }

begin
  with f do    { Traite la variable fichier }
    begin
      Carptr := BPTR( BufPtr );  { Pointe sur le premier caractŠre }
      if ( Write2View ) then  { Faut-il tenir compte de la zone de visualisation ? }
        begin  { Oui, fait ‚ventuellement d‚filer la zone }
          for i := 1 to BufPos do { Parcourt les caractŠres }
            begin
              case Carptr^ of   { Traite le caractŠre courant }

                7 : begin    { BEL : Emet un signal sonore }
                      Sound( 880 );  { Lance le signal }
                      Delay( 750 );  { Attend 3/4 seconde }
                      NoSound;   { Coupe le signal }
                    end;

                8 : begin   { Backspace (BS): Revient en arriŠre }
                      if ( WritelnX = ViewX1 ) then { D‚but de ligne ? }
                        begin   { Oui, revient … la ligne pr‚c‚dente }
                          WritelnX := ViewX2;  { en derniŠre colonne }
                          dec( WritelnY );      { de la ligne pr‚c.  }
                        end
                      else   { Mˆme ligne }
                        dec( WritelnX );  { Recule d'une colonne }
                      WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                    end;

               10 : begin     { Linefeed (LF): Incr‚mente la ligne d'affichage  }
                      if ( WritelnY = ViewY2 ) then { Est-ce la derniŠre ligne de la zone de visualisation ? }
                        WinScrollUp( ViewX1, ViewY1+1, ViewX2,
                                     ViewY2, 1, WritelnCol )
                      else   { Pas besoin de faire d‚filer la zone de visualisation }
                        begin
                          inc( WritelnY );
                          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                        end;
                    end;

               13 : begin             { CR: Revient au d‚but de la ligne }
                      WritelnX := ViewX1;
                      WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                    end;

               else   { Autre caractŠre : affiche tel quel }
                 begin
                   {-- Ecrit le code ASCII et l'attribut en m‚moire vid‚o--}

                   WritelnPtr^.Caractere := Carptr^;
                   WritelnPtr^.Attribut := WritelnCol;

                   {-- Avance le pointeur sur le caractŠre suivant -------}

                   inc( PTRREC( WritelnPtr ).Ofs, 2 );
                   inc( WritelnX );  { Incr‚mente la colonne }
                   if ( WritelnX > ViewX2 ) then  { Limite de la zone de visualisation ? }
                     begin  { Oui  }
                       WritelnX := ViewX1;  { Ligne suivante }
                       if ( WritelnY = ViewY2 ) then  { Est-ce la derniŠre de la zone de visualisation ?}
                         begin  { Oui, fait d‚filer la zone }
                           WinScrollUp( ViewX1, ViewY1+1, ViewX2,
                                        ViewY2, 1, WritelnCol );
                           WritelnX := ViewX1;  { Bord gauche }

                           WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                         end
                       else  { Pas besoin de faire d‚filer la zone de visualisation }
                         begin
                           inc( WritelnY );
                           WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                         end;
                     end;
                 end;
              end;
              inc( PTRREC( Carptr ).Ofs );{ Pointe sur le caractŠre suivant }
           end;
        end
      else   { Ne tient pas compte de la zone de visualisation , ‚crit simplement dans la m‚moire vid‚o }
        begin
          for i := 1 to BufPos do  { Parcourt les caractŠres }
            begin
              case Carptr^ of   { Traite le caractŠre courant }

                7 : begin  { BEL : Emet un signal sonore }
                      Sound( 880 ); { Lance le signal  }
                      Delay( 750 ); { Attend 3/4 seconde }
                      NoSound;      { Coupe le signal }
                    end;

                8 : begin  { Backspace (BS): Revient en arriŠre }
                      if ( WritelnX = 0 ) then { D‚but de ligne ? }
                        begin          { Oui, revient … la ligne pr‚c‚dente }
                          WritelnX := NbCol - 1;  { en derniŠre colonne }
                          dec( WritelnY );       { de la ligne }
                        end
                      else                  { Mˆme ligne }
                        dec( WritelnX );     { Recule d'une colonne }
                      WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                    end;

               10 : begin     { Linefeed (LF): Incr‚mente la ligne d'affichage }
                      inc( WritelnY );
                      WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                    end;

               13 : begin             { CR: Revient au d‚but de la ligne }
                      WritelnX := 0;
                      WritelnPtr := GetVioPtr( WritelnX, WritelnY );
                    end;

               else           { Autre caractŠre : afficher tel quel }
                 begin
                   {-- Ecrit le code ASCII et l'attribut en m‚moire vid‚o--}


                   WritelnPtr^.Caractere := Carptr^;
                   WritelnPtr^.Attribut := WritelnCol;

                   {-- Avance le pointeur sur le caractŠre suivant --------------}

                   inc( PTRREC( WritelnPtr ).Ofs, 2 );
                   inc( WritelnX );   { Incr‚mente la colonne }
                   if ( WritelnX = NbCol ) then    { Fin de ligne ? }
                     begin   { Oui  }
                       WritelnX := 0;   { Passe … la suivante }
                       inc( WritelnY );
                     end;
                 end;
              end;
              inc( PTRREC( Carptr ).Ofs );{ Pointe sur le caractŠre suivant }
           end;
        end;
      BufPos := 0;    { Tous les caractŠres ont ‚t‚ trait‚s }
    end;
  WinWriteln := 0;  { Retourne 0 }
end;

{$F-}

{***************************************************************************
*  OutputOpen : d‚clench‚ par Turbo Pascal au premier appel de WRITE       *
*               ou de WRITELN, aprŠs que la variable fichier Output        *
*               ait ‚t‚ d‚tourn‚e par WinInit                              *
**------------------------------------------------------------------------**
*  Entr‚e : F = variable fichier Output de type TextRec                    *
*  Sortie : Doit renvoyer 0 par d‚finition (= pas d'erreur)                *
*  Variables globales : n‚ant *                                            *
****************************************************************************}

{$F+} { Doit ˆtre FAR }

function OutputOpen( var f : TextRec ) : integer;

begin
  with f do      { Traite la variable fichier }
    begin
      InOutFunc := @WinWriteln; { Fixe l'adresse de la fonction de sortie }
      FlushFunc := @WinWriteln; { "Flush" correspond ici … "Out" }
      CloseFunc := @WinDummy;   { Close n'est pas pris en compte  }
    end;
  OutputOpen := 0;  { Retourne syst‚matiquement 0 }
end;

{$F-}

{**************************************************************************
*  ScrollHori : fait d‚filer une zone de l'‚cran                          *
*               d'un certain nombre de colonnes                           *
*               vers la gauche ou la droite                               *
**-----------------------------------------------------------------------**
*  Entr‚es :x1, y1    = Coordonn‚es du coin sup‚rieur gauche de la zone   *
*           x2, y2    = Coordonn‚es du coin unf‚rieur droit de la zone    *
*           Nombre    = Nombre de colonnes … d‚caler                      *
*           Couleur   = Couleur o— attribut des colonnes lib‚r‚es         *
*           AGauche   = TRUE  : D‚filement vers la gauche                 *
*                       FALSE : D‚filement vers la droite                 *
*  Information        : Si la couleur est ‚gale … la constante NO_CLEAR,  *
*                       les colonnes lib‚r‚es ne sont pas effac‚es        *
*  Variable globale   : LigneOfs/R                                        *
**************************************************************************}

procedure ScrollHori( x1, y1, x2, y2, Nombre, Couleur : byte;
                         AGauche : boolean );

var de,         { Copie de ... }
    a   : VPTR; { ... … }
    Byte2Copy,  { Nombre d'octets par ligne }
    ActLigne  : integer;   { Ligne actuelle }

begin
 Byte2Copy := (x2 - x1 + 1) shl 1;  { Nombre d'octets }
 de := GetVioPtr( x1, y1 );
 if AGauche then     { Vers la gauche ?  }
   a := GetVioPtr( x1 - Nombre, y1 ) { Oui }
 else    { Vers la droite  }
   a := GetVioPtr( x1 + Nombre, y1 );

 for ActLigne := y1 to y2 do    {  Parcourt les lignes }
   begin
     Move( de^, a^, Byte2Copy );  { Copie la ligne }
     inc( PTRREC( de ).Ofs, LigneOfs );
     inc( PTRREC( a ).Ofs, LigneOfs );
   end;

 {-- Efface ‚ventuellement les colonnes lib‚r‚es -----}

 if Couleur <> NO_CLEAR then  { Efface ?  }
  if AGauche then   { Vers la gauche  }
    WinFill( x2-Nombre+1, y1, x2, y2, ' ', Couleur)
  else   { Vers la droite }
    WinFill( x1, y1, x1+Nombre-1, y2, ' ', Couleur);
end;

{**************************************************************************
*  WinScrollDown : fait d‚filer une zone de l'‚cran                       *
*                 d'un certain nombre de lignes vers le bas               *
**-----------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone     *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone      *
*            Nombre = Nombre de lignes … remonter                         *
*            Couleur = Couleur ou attribut des lignes lib‚r‚es            *
*  Information    : Si la couleur est ‚gale … la constante NO_CLEAR,      *
*            les lignes lib‚r‚es ne sont pas effac‚es                     *
*  Variables globales : LigneOfs/R                                        *
**************************************************************************}

procedure WinScrollDown( x1, y1, x2, y2, Nombre, Couleur : byte );

var de,    { Copie de ...}
    a    : VPTR;   { ... … }
    Byte2Copy,   { Nombre d'octets par ligne }
    ActLigne  : integer; { Ligne actuelle }

begin
 Byte2Copy := (x2 - x1 + 1) shl 1;   { Nombre d'octets }
 de  := GetVioPtr( x1, y2 );  { Pointe sur la ligne … d‚placer }
 a   := GetVioPtr( x1, y2 + Nombre );  { Nouvelle position }

 for ActLigne := y1 to y2 do    { Parcourt les diff‚rentes lignes  }
   begin
     Move( de^,a^, Byte2Copy ); { Copie la ligne }
     dec( PTRREC( de ).Ofs, LigneOfs );
     dec( PTRREC( a  ).Ofs, LigneOfs );
   end;

 if Couleur <> NO_CLEAR then  { Efface les lignes lib‚r‚es ? }
   WinFill( x1, y1, x2, y1+Nombre-1, ' ', Couleur);    { Oui }
end;

{**************************************************************************
*  WinScrollUp : fait d‚filer une zone de l'‚cran                         *
*                 d'un certain nombre de lignes vers le haut              *
**-----------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone     *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone      *
*            Nombre = Nombre de lignes … remonter                         *
*            Couleur = Couleur ou attribut des lignes lib‚r‚ess           *
*  Information    : Si la couleur est ‚gale … la constante NO_CLEAR,      *
*            les lignes lib‚r‚es ne sont pas effac‚es                     *
*  Variables globales : LigneOfs/R                                        *
***************************************************************************}

procedure WinScrollUp( x1, y1, x2, y2, Nombre, Couleur : byte );

var de,     { Copie de ... }
    a      : VPTR;   { ... … }
    Byte2Copy,    { Nombre d'octets par ligne }
    ActLigne  : integer; { Ligne actuelle }

begin
 Byte2Copy := (x2 - x1 + 1) shl 1;   { Nombre d'octets }
 de   := GetVioPtr( x1, y1 );    { Pointe sur la ligne … d‚placer }
 a    := GetVioPtr( x1, y1 - Nombre ); { Nouvelle position}

 for ActLigne := y1 to y2 do  { Parcourt les diff‚rents caractŠres }
   begin
     Move( de^,a^, Byte2Copy );  { Copie la ligne }
     inc( PTRREC( de  ).Ofs, LigneOfs );
     inc( PTRREC( a  ).Ofs, LigneOfs );
   end;

 if Couleur <> NO_CLEAR then   { Efface les lignes lib‚r‚es ? }
   WinFill( x1, y2+1-Nombre, x2, y2, ' ', Couleur);    { Oui }
end;

{***************************************************************************
*  WinScrollLeft : fait d‚filer une zone de l'‚cran                        *
*                  d'une certain nombre de colonnes vers la gauche         *
**------------------------------------------------------------------------**
*  Entr‚es : cf WinScrollUp, WinScrollDown                                 *
*  Variables globales : n‚ant                                              *
***************************************************************************}

procedure WinScrollLeft( x1, y1, x2, y2, Nombre, Couleur : byte );

begin
  ScrollHori( x1, y1, x2, y2, Nombre, Couleur, TRUE );
end;

{***************************************************************************
*  WinScrollRight: fait d‚filer une zone de l'‚cran                        *
*                  d'un certain nombre de colonnes vers la droite          *
**------------------------------------------------------------------------**
*  Entr‚es : cf WinScrollUp, WinScrollDown                                 *
*  Variables globales : n‚ant                                              *
***************************************************************************}

procedure WinScrollRight( x1, y1, x2, y2, Nombre, Couleur : byte );

begin
  ScrollHori( x1, y1, x2, y2, Nombre, Couleur, FALSE );
end;

{***************************************************************************
*  WinMoveUp : d‚place la fenˆtre active vers le haut                      *
**------------------------------------------------------------------------**
*  Entr‚e : Nombre = Nombre de lignes du d‚placement                       *
*  Information     : le programme appelant doit s'assurer que la fenˆtre   *
*                    ne sort pas des limites de l'‚cran                    *
*  Variables globales : vLigne/RW, vColonne/RW, Write2View/R, ViewY1/W,    *
*                       ViewY2/W, WritelnY/W                               *
***************************************************************************}

procedure WinMoveUp( Nombre : byte );

var BufPtr : VPTR;  { Pointe sur un buffer de travail }
    Largeur,  { Nombre de colonnes de la fenˆtre }
    Hauteur,  { Nombre de lignes de la fenˆtre }
    BufLen : integer;  { Taille du buffer de travail en octets }

{-- GetPtr est une fonction locale qui renvoie un pointeur sur le d‚but d'une ligne dans le buffer de la fenˆtre active --}

function GetPtr( Ligne : integer ) : pointer;

begin
  GetPtr := @ActBufPtr^[ Ligne * Largeur ];
end;

{-------------------------------------------------------------------------}

begin
  with ActWinPtr^ do    { AccŠde au descripteur de la fenˆtre active }
    begin
      Largeur := x2 - x1 + 1;
      Hauteur := y2 - y1 + 1;
      BufLen := Largeur * Nombre shl 1;
      GetMem( BufPtr, BufLen );   { Alloue un buffer temporaire }
      GetScr( x1, y1-Nombre, x2, y1-1, BufPtr );
      WinScrollUp ( x1, y1, x2, y2, Nombre, NO_CLEAR );
      PutScr( x1, y2-Nombre+1, x2, y2, GetPtr( Hauteur - Nombre ) );
      Move( GetPtr( 0 )^, GetPtr(Nombre)^, Largeur * (Hauteur-Nombre) shl 1);
      Move( BufPtr^, GetPtr( 0 )^, BufLen );

      {-- Si le curseur se trouve … l'int‚rieur de la fenˆtre, il doit  -}
      {-- aussi ˆtre d‚plac‚                                            -}

      if ( (x1 <= vColonne ) and (x2 >= vColonne ) and
           (y1 <= vLigne ) and (y2 >= vLigne ) ) then
        WinSetCursor( vColonne , vLigne - Nombre );

      {-- En mode Write2View, la position d'affichage pour Write et ------}
      {-- Writeln doit ˆtre recal‚e -------}

      if ( Write2View ) then   { Est-on en mode Write2View ? }
        begin   { Oui  }
          dec( WritelnY, Nombre );   { Ajuste la position }
          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
        end;

      dec( y1, Nombre );    { Met … jour les coordonn‚es de la fenˆtre }
      dec( y2, Nombre );
      FreeMem( BufPtr, BufLen ); { LibŠre le buffer temporaire }
    end;
  dec( ViewY1, Nombre );   { D‚place la zone de visualisation }
  dec( ViewY2, Nombre );
end;

{***************************************************************************
*  WinMoveDown : d‚place la fenˆtre active vers le bas                     *
*                                                                          *
**------------------------------------------------------------------------**
*  Entr‚e : Nombre = Nombre de lignes du d‚placement                       *
*  Information    : le programme appelant doit s'assurer que la fenˆtre ne *
*                   sort pas des limites de l'‚cran                        *
*  Variables globales : vLigne/RW, vColonne/RW, Write2View/R, ViewY1/W,    *
*                       ViewY2/W, WritelnY/W                               *
***************************************************************************}

procedure WinMoveDown( Nombre : byte );

var BufPtr : VPTR;  { Pointe sur un buffer de travail }
    Largeur,   { Nombre de colonnes de la fenˆtre }
    Hauteur,   { Nombre de lignes de la fenˆtre }
    BufLen : integer;  { Taille du buffer de travail en octets }

{-- GetPtr est une fonction locale qui retourne un pointeur sur le d‚but d'une ligne dans le buffer de la fenˆtre active -- }

function GetPtr( Ligne : integer ) : pointer;

begin
  GetPtr := @ActBufPtr^[ Ligne * Largeur ];
end;

{--------------------------------------------------------------------------}

begin
  with ActWinPtr^ do  { AccŠde au descripteur de la fenˆtre active }
    begin
      Largeur := x2 - x1 + 1;
      Hauteur := y2 - y1 + 1;
      BufLen := Largeur * Nombre shl 1;
      GetMem( BufPtr, BufLen );  { Alloue un buffer temporaire }
      GetScr( x1, y2+1, x2, y2+Nombre, BufPtr );
      WinScrollDown( x1, y1, x2, y2, Nombre, NO_CLEAR );
      PutScr( x1, y1, x2, y1+Nombre-1, GetPtr( 0 ) );
      Move( GetPtr(Nombre)^, GetPtr( 0 )^, Largeur * (Hauteur-Nombre) shl 1);
      Move( BufPtr^, GetPtr( Hauteur - Nombre )^, BufLen );

      {-- Si le curseur se trouve … l'int‚rieur de la fenˆtre, il doit  -}
      {-- aussi ˆtre d‚plac‚                                            -}

      if ( (x1 <= vColonne ) and (x2 >= vColonne ) and
           (y1 <= vLigne ) and (y2 >= vLigne ) ) then
        WinSetCursor( vColonne , vLigne + Nombre );

      {-- En mode Write2View, la position d'affichage pour Write et ------}
      {-- Writeln doit ˆtre recal‚e -------}

      if ( Write2View ) then  { Est-on en mode Write2View ? }
        begin  { Oui }
          inc( WritelnY, Nombre );   { Ajuste la position }
          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
        end;

      inc( y1, Nombre ); { Met … jour les coordonn‚es de la fenˆtre }
      inc( y2, Nombre );
      FreeMem( BufPtr, BufLen );  { LibŠre le buffer temporaire }
    end;
  inc( ViewY1, Nombre );   { D‚place la zone de visualisation  }
  inc( ViewY2, Nombre );   
end;

{***************************************************************************
*  WinMoveRight : d‚place la fenˆtre active vers la droite                 *
**------------------------------------------------------------------------**
*  Entr‚e : Nombre = Nombre de colonnes du d‚placement                     *
*  Information    : le programme appelant doit s'assurer que la fenˆtre ne *
*                   sort pas des limites de l'‚cran                        *
*  Variables globales : vLigne/RW, vColonne/RW, Write2View/R, ViewX1/W,    *
*                       ViewX2/W, WritelnX/W                               *
***************************************************************************}

procedure WinMoveRight( Nombre : byte );

var BufPtr,   { Pointe sur un buffer de travail }
    LBufPtr   : VPTR;  { Pointeur courant }
   Byte2Copy,  { Nombre d'octets … copier }
    Ligne,     { Compteur de lignes }
    EndLigne,  { idem }
    Largeur,   { Nombre de colonnes de la fenˆtre }
    Hauteur,   { Nombre de lignes de la fenˆtre }
    BufLen    : integer;  { Taille du buffer de travail en octets }

{-- GetPtr est une fonction locale qui retourne un pointeur sur le d‚but d'une ligne dans le buffer de la fenˆtre active -- }

function GetPtr( Ligne, Colonne : integer ) : pointer;

begin
  GetPtr := @ActBufPtr^[ Ligne * Largeur + Colonne ];
end;

{-------------------------------------------------------------------------}

begin
  with ActWinPtr^ do   { AccŠde … la fenˆtre active }
    begin
      Largeur := x2 - x1 + 1;
      Hauteur := y2 - y1 + 1;
      BufLen := Hauteur * Nombre shl 1;
      GetMem( BufPtr, BufLen );  { Alloue un buffer temporaire }
      GetScr( x2+1, y1, x2+Nombre, y2, BufPtr );
      ScrollHori( x1, y1, x2, y2, Nombre, NO_CLEAR, FALSE );

      Byte2Copy := ( Largeur - Nombre ) shl 1;
      LBufPtr := BufPtr;   { Pointe sur le d‚but du buffer }
      EndLigne := Hauteur - 1;
      for Ligne:=0 to EndLigne do  { Parcourt les lignes une … une }
        begin
          PutScr( x1, Ligne+y1, x1+Nombre-1, Ligne+y1,
                        GetPtr( Ligne, 0 ) );
          Move( GetPtr( Ligne, Nombre )^, GetPtr( Ligne, 0 )^, Byte2Copy );
          Move( LBufPtr^, GetPtr( Ligne, Largeur - Nombre )^, Nombre shl 1 );
          inc( PTRREC( LBufPtr ).Ofs, Nombre shl 1 );
        end;

      {-- Si le curseur se trouve … l'int‚rieur de la fenˆtre, il doit  -}
      {-- aussi ˆtre d‚plac‚                                            -}

      if ( (x1 <= vColonne ) and (x2 >= vColonne ) and
           (y1 <= vLigne ) and (y2 >= vLigne ) ) then
        WinSetCursor( vColonne + Nombre , vLigne );

      {-- En mode Write2View, la position d'affichage pour Write et ------}
      {-- Writeln doit ˆtre recal‚e -------}

      if ( Write2View ) then   { Est-on en mode Write2View ? }
        begin  { Oui }
          inc( WritelnX, Nombre );  { Ajuste la position d'affichage }
          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
        end;

      inc( x1, Nombre ); { Met … jour les coordonn‚es de la fenˆtre }
      inc( x2, Nombre );
      FreeMem( BufPtr, BufLen ); { LibŠre le buffer temporaire }
    end;
  inc( ViewX1, Nombre );   { D‚place la zone de visualisation }
  inc( ViewX2, Nombre );
end;

{***************************************************************************
*  WinMoveLeft : d‚place la fenˆtre active vers la gauche                  *
**------------------------------------------------------------------------**
*  Entr‚e : Nombre = Nombre de colonnes du d‚placement                     *
*  Information    : le programme appelant doit s'assurer que la fenˆtre ne *
*                   sort pas des limites de l'‚cran                        *
*  Variables globales : vLigne/RW, vColonne/RW, Write2View/R, ViewX1/W,    *
*                       ViewX2/W, WritelnX/W                               *
***************************************************************************}

procedure WinMoveLeft( Nombre : byte );

var BufPtr,   { Pointe sur un buffer de travail }
    LBufPtr   : VPTR;  { Pointeur courant }
    Byte2Copy,  { Nombre d'octets … copier }
    Ligne,      { Compteur de lignes }
    EndLigne,   { idem }
    Largeur,    { Nombre de colonnes de la fenˆtre }
    Hauteur,    { Nombre de lignes de la fenˆtre }
    BufLen    : integer;   { Taille du buffer de travail en octets }

{-- GetPtr est une fonction locale qui retourne un pointeur sur le d‚but d'une ligne dans le buffer de la fenˆtre active -- }

function GetPtr( Ligne, Colonne : integer ) : pointer;

begin
  GetPtr := @ActBufPtr^[ Ligne * Largeur + Colonne ];
end;

{-------------------------------------------------------------------------}

begin
  with ActWinPtr^ do  { AccŠde au descripteur de la fenˆtre active }
    begin
      Largeur := x2 - x1 + 1;
      Hauteur := y2 - y1 + 1;
      BufLen := Hauteur * Nombre shl 1;
      GetMem( BufPtr, BufLen ); { Alloue un buffer temporaire }
      GetScr( x1-Nombre, y1, x1-1, y2, BufPtr );
      ScrollHori( x1, y1, x2, y2, Nombre, NO_CLEAR, TRUE );

      Byte2Copy := ( Largeur - Nombre ) shl 1;
      LBufPtr := BufPtr;  { Pointe sur le d‚but du buffer }
      EndLigne := Hauteur - 1;
      for Ligne:=0 to EndLigne do  { Parcourt les lignes une … une  }
        begin
          PutScr( x2-Nombre+1, Ligne+y1, x2, Ligne+y1,
                        GetPtr( Ligne, Largeur - Nombre ) );
          Move( GetPtr( Ligne, 0 )^, GetPtr( Ligne, Nombre )^, Byte2Copy );
          Move( LBufPtr^, GetPtr( Ligne, 0 )^, Nombre shl 1 );
          inc( PTRREC( LBufPtr ).Ofs, Nombre shl 1 );
        end;

      {-- Si le curseur se trouve … l'int‚rieur de la fenˆtre, il doit  -}
      {-- aussi ˆtre d‚plac‚                                            -}

      if ( (x1 <= vColonne ) and (x2 >= vColonne ) and
           (y1 <= vLigne ) and (y2 >= vLigne ) ) then
        WinSetCursor( vColonne + Nombre , vLigne );

      {-- En mode Write2View, la position d'affichage pour Write et ------}
      {-- Writeln doit ˆtre recal‚e -------}

      if ( Write2View ) then   { Est-on en mode Write2View ? }
        begin   { Oui }
          dec( WritelnX, Nombre );  { Ajuste la position }
          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
        end;

      dec( x1, Nombre ); { Met … jour les coordonn‚es de la fenˆtre }
      dec( x2, Nombre );
      FreeMem( BufPtr, BufLen );  { LibŠre le buffer temporaire }
    end;
  dec( ViewX1, Nombre );  { D‚place la zone de visualisation }
  dec( ViewX2, Nombre );
end;

{***************************************************************************
*  WinMove : d‚place la fenˆtre active                                     *
*                                                                          *
**------------------------------------------------------------------------**
*  Entr‚es : x, y : Nouvelles coordonn‚es du coin sup‚rieur gauche de la   *
*                   fenˆtre                                                *
*  Information    : le programme appelant doit s'assurer que la fenˆtre ne *
*                   sort pas des limites de l'‚cran                        *
*  Variables globales : vLigne/RW, vColonne/RW, Write2View/R, ViewX1/W,    *
*                     ViewX2/W, ViewY1/W, ViewY2/W, WritelnX/W, WritelnY/W *
*  Variable globale : n‚ant                                                *
***************************************************************************}

procedure WinMove( x, y : byte );

var BufPtr : VPTR;   { Pointe sur un buffer temporaire }
    DeltaX,      { Distance entre l'ancienne et la nouvelle }
    DeltaY,      { position de la fenˆtre }
    Largeur,     { Nombre de colonnes de la fenˆtre }
    Hauteur,     { Nombre de lignes de la fenˆtre }
    BufLen : integer;  { Taille du buffer temporaire en octet }

begin
  with ActWinPtr^ do  { AccŠde au descripteur de la fenˆtre active }
    begin
      Largeur := x2 - x1;
      Hauteur := y2 - y1;
      BufLen := ( Hauteur + 1 ) * ( Largeur + 1 ) shl 1;
      GetMem( BufPtr, BufLen ); { Alloue un buffer temporaire }
      GetScr( x1, y1, x2, y2, BufPtr ); { Stocke la fenˆtre active dans le tampon }
      PutScr( x1, y1, x2, y2, @Buffer ); { Restaure la zone recouverte }

      DeltaX := x - x1;   { Distance en nombre de colonnes }
      DeltaY := y - y1;   { Distance en nombre de lignes }

      {-- Si le curseur se trouve … l'int‚rieur de la fenˆtre, il doit  -}
      {-- aussi ˆtre d‚plac‚                                            -}

      if ( (x1 <= vColonne ) and (x2 >= vColonne ) and
           (y1 <= vLigne ) and (y2 >= vLigne ) ) then
        WinSetCursor( vColonne - x1 + x, vLigne - y1 + y );

      {-- En mode Write2View, la position d'affichage pour Write et ------}
      {-- Writeln doit ˆtre recal‚e -------}

      if ( Write2View ) then { Est-on en mode Write2View ? }
        begin
          dec( WritelnX, x1 - x );
          dec( WritelnY, y1 - y );
          WritelnPtr := GetVioPtr( WritelnX, WritelnY );
        end;

      x1 := x;    { Fixe les nouvelles coordonn‚es de la fenˆtre }
      x2 := x + Largeur - 1;
      y1 := y;
      y2 := y + Hauteur - 1;

      GetScr( x, y, x2, y2, @Buffer ); { M‚morise la zone recouverte }
      PutScr( x, y, x2, y2, BufPtr );  { Puis affiche la nouvelle fenˆtre }

      FreeMem( BufPtr, BufLen ); { LibŠre le buffer temporaire }
    end;
  inc( ViewX1, DeltaX );  { D‚place la zone de visualisation  }
  inc( ViewX2, DeltaX );  
  inc( ViewY1, DeltaY );
  inc( ViewY2, DeltaY );
end;
{***************************************************************************
*  WinInFront : ramŠne une fenˆtre au premier plan                         *
*                                                                          *
**------------------------------------------------------------------------**
*  Entr‚e : Key = Num‚ro de la fenˆtre qui lui a ‚t‚ attribu‚ par          *
*                  l'une des fonctions WinOpen ou WinOpenShadow            *
*  Sorties: True, si bon d‚roulement                                       *
*           False, si pas assez de m‚moire                                 *
*  Variables globales : LigneOfs/R, ActWinPtr/RW, FirstWinPtr/RW, NbLig/R, *
*            NbCol/R                                                       *
***************************************************************************}

function WinInFront( Key : integer ) : boolean;

var DummyWD : WINDES;  { Descripteur fictif }
RunWiP,   { Pointe sur la liste des fenˆtres }
    WiP     : WIPTR;  { Pointe sur la fenˆtre … traiter }
    TempBuf,    { Buffer temporaire pour stocker une fenˆtre }
    WinBuf,     { Copie de la m‚moire vid‚o }
    WinNrBuf,   { Contenu de la fenˆtre … traiter }
    VioCopy,    { Pointe sur la copie la m‚moire vid‚o }
    Ancien,      { Pointe sur un buffer d'‚cran de travail }
    Nouveau  : VPTR;  { Pointe sur le buffer du nouvel ‚cran }
    Nr,  { Num‚ro de la fenˆtre … traiter dans la liste }
    TempLen,    { Taille du buffer temporaire }
    VioLen,     { Nombre d'octets de la m‚moire vid‚o }
    AwiLen,     { Taille de la fenˆtre … traiter }
    i, j    : integer;   { Compteurs }

{-- les proc‚dures locales Get et Put opŠrent sur les diff‚rents }
{ buffers qui ‚mulent la m‚moire vid‚o --}

procedure Get( x1, y1, x2, y2 : byte; VioPtr, BufPtr : pointer );

var nbytes : integer;   { Nombre d'octets … copier par ligne }

begin
  nbytes := ( x2 - x1 + 1 ) shl 1;  { Octets par ligne }
  inc( PTRREC( VioPtr ).Ofs, (x1 + y1 * NbCol) shl 1 );
  while y1 <= y2 do  { Parcourt les lignes }
    begin
      Move( VioPtr^, BufPtr^, nbytes);
      inc( PTRREC( VioPtr ).Ofs, LigneOfs );
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );  { Passe … la ligne suivante }
    end;
end;

procedure Put( x1, y1, x2, y2 : byte; VioPtr, BufPtr : pointer );

var nbytes : integer;   { Nombre d'octets … copier par ligne }

begin
  nbytes := ( x2 - x1 + 1 ) shl 1;  { Octets par ligne }
  inc( PTRREC( VioPtr ).Ofs, (x1 + y1 * NbCol) shl 1 );
  while y1 <= y2 do   { Parcourt les lignes }
    begin
      Move( BufPtr^, VioPtr^, nbytes );
      inc( PTRREC( VioPtr ).Ofs, LigneOfs );
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );  { Passe … la ligne suivante }
    end;
end;

{--------------------------------------------------------------------------}

begin

  {-- WiP va pointer sur la fenˆtre … traiter ---------------}

  WiP := FirstWinPtr;   { WiP pointe d'abord sur la 1re fenˆtre}
  Nr := 0;              { qui porte le num‚ro 0 }
  while WiP^.Handle <> Key do    { Est-ce le bon num‚ro ? }
    begin  { Non }
      WiP := WiP^.NextWin;   { Passe … la fenˆtre suivante }
      inc( Nr );     { Incr‚mente le num‚ro }
    end;

  if ( WiP = ActWinPtr ) then { La fenˆtre est-elle d‚j… au premier plan ? }
    begin  { Oui, c'est termin‚ }
      WinInFront := TRUE;
      exit;
    end;

  {-- Alloue 5 buffers pour stocker des parties de la m‚moire vid‚o  . ---}
  {-- ( deux d'entre eux ne seront utilis‚s que plus tard ) --}


  VioLen := NbLig * NbCol shl 1; { Nombres d'octets de la m‚moire vid‚o }
  if MaxAvail <= VioLen * 5 then  { Assez de place pour 5 buffers ? }
    begin  { Non }
      WinInFront := false;  { Signale une erreur }
      exit;  { et retourne … l'appelant }
    end;

  {-- Il reste de la place sur le tas, on reporte la position du curseur --}
  {-- et la zone de visualisation dans le descripteur de la fenˆtre active }
  DummyWD := Wip^;   { M‚morise le descripteur actuel }

  Wip^.curc   := vColonne;
  Wip^.curl   := vLigne;
  Wip^.ViewX1 := ViewX1;
  Wip^.ViewY1 := ViewY1;
  Wip^.ViewX2 := ViewX2;
  Wip^.ViewY2 := ViewY2;

  {-- Fixe la position du curseur et la zone de visualisation de la nouvelle fenˆtre -- }
  with Wip^.NextWin^ do
    begin
      WinSetView( ViewX1, ViewY1, ViewX2, ViewY2 );
      WinSetCursor( curc, curl );
    end;

  {-- Reporte des donn‚es de la fenˆtre … traiter dans son successeur------}
  {-- actuel ------}

  with Wip^.NextWin^ do
    begin
      ViewX1 := DummyWD.ViewX1;
      ViewY1 := DummyWD.ViewY1;
      ViewX2 := DummyWD.ViewX2;
      ViewY2 := DummyWD.ViewY2;
      curc   := DummyWD.curc;
      curl   := DummyWD.curl;
    end;

  GetMem( Nouveau,  VioLen);  { Buffer servant … construire le nouvel ‚cran }
  GetMem( Ancien,   VioLen);  { Buffer servant … travailler sur les fenˆtres }
  GetMem( VioCopy, VioLen);  { Copie de la m‚moire d'‚cran }

  {-- Copie le contenu de la m‚moire vid‚o dans les buffers VioCopy et Nouveau  }

  GetScr( 0, 0, NbCol-1, NbLig-1, VioCopy );
  Move( VioCopy^, Nouveau^, VioLen ); { Sauvegarde du contenu de la RAM Video }

  {-- Ferme toutes les fenˆtres situ‚es au-dessus de la fenˆtre de travail dans le buffer Nouveau -- }

  RunWip := ActWinPtr;  { Pointe sur la fenˆtre active (=la derniŠre) }
  for i:=NbWin-1 downto Nr+1 do  { Parcourt les fenˆtres }
    with RunWiP^ do
      begin
        Put( x1, y1, x2, y2, Nouveau, @Buffer );
        RunWiP := LastWin; { Pointe sur la fenˆtre pr‚c‚dente }
      end;

  {-- Stocke le contenu de la fenˆtre … traiter dans un buffer s‚par‚ d‚sign‚ par WinNrBuf --}

  with WiP^ do
    begin
      if ( ( Attribut and WIN_OMBRE ) <> 0 ) then
        begin  { Ne pas recopier l'ombre }
          AwiLen := (x2-x1+1-ShadowX) * (y2-y1+1-ShadowY) shl 1; { Taille du buffer }
          GetMem( WinNrBuf, AwiLen );  { R‚serve de la place }
          Get( x1, y1, x2-ShadowX, y2-ShadowY, Nouveau, WinNrBuf );
          Put( x1, y1, x2, y2, Nouveau, @Buffer );  { Efface la fenˆtre }
        end
      else  { Il n'y a pas d'ombre, donc recopie int‚grale }
        begin
          AwiLen := (x2 - x1 + 1) * (y2 - y1 + 1) shl 1; { Taille du buffer }
          GetMem( WinNrBuf, AwiLen ); { R‚serve de la place }
          Get( x1, y1, x2, y2, Nouveau, WinNrBuf ); { TransfŠre le contenu de la fenˆtre dans le buffer }
          Put( x1, y1, x2, y2, Nouveau, @Buffer ); { Efface la fenˆtre }       end;
    end;

  {-- AmŠne les fenˆtres situ‚es au-dessus de la fenˆtre … traiter
   dans le buffer Nouveau et stocke le contenu situ‚ en-dessous }

  for i:=Nr+1 to NbWin-1 do  { Parcourt les fenˆtres }
    begin
      Move( VioCopy^, Ancien^, VioLen );  { Copie la m‚moire vid‚o dans le buffer Ancien }
      RunWiP := ActWinPtr;  { WiP pointe sur la derniŠre fenˆtre }

      {-- Efface dans le buffer Ancien les fenˆtres situ‚es au-dessus de la fenˆtre i ----------}
      for j:=NbWin-1 downto i+1 do
        with RunWiP^ do
          begin
            Put( x1, y1, x2, y2, Ancien, @Buffer );  { Efface la fenˆtre }
            RunWiP := LastWin; { WiP pointe sur la pr‚c‚dente }
          end;

      {-- Recherche dans le buffer Nouveau le contenu situ‚ au-dessous de--}
      {-- la fenˆtre i et copie ensuite la fenˆtre i dans le buffer Nouveau }

      with RunWiP^ do
        begin
          Get( x1, y1, x2, y2, Nouveau, @Buffer );  { Contenu au-dessous de la fenˆtre }

          {-- Si la fenˆtre possŠde une ombre, il faut la recalculer }

          if ( ( Attribut and WIN_OMBRE ) <> 0 ) then
            begin   { Reconstitue l'ombre }
              TempLen := ( x2-x1+1-ShadowX ) * ( y2-y1+1-ShadowY ) shl 1;
              GetMem( TempBuf, TempLen ); { Alloue un buffer temporaire }
              Get( x1, y1, x2 - ShadowX, y2 - ShadowY, Ancien, TempBuf );
              Put( x1, y1, x2 - ShadowX, y2 - ShadowY, Nouveau, TempBuf );
              WinShadow( x2-ShadowX+1, y1+ShadowY, x2, y2, Nouveau );
              WinShadow( x1+ShadowX, y2-ShadowY+1, x2-ShadowX, y2, Nouveau );
            end
          else  { Pas d'ombre … reconstituer }
            begin
              TempLen := (x2 - x1 + 1) * (y2 - y1 + 1) shl 1;
              GetMem( TempBuf, TempLen ); { Alloue un buffer temporaire }
              Get( x1, y1, x2, y2, Ancien, TempBuf );
              Put( x1, y1, x2, y2, Nouveau, TempBuf );
            end;
          FreeMem( TempBuf, TempLen );  { LibŠre le buffer temporaire }
        end;
    end;


  {-- Note le contenu situ‚ en-dessous de la nouvelle premiŠre fenˆtre et transfŠre cette fenˆtre dans le buffer Nouveau }

  with WiP^ do
    begin
      Get( x1, y1, x2, y2, Nouveau, @Buffer );
      if ( ( Attribut and WIN_OMBRE ) <> 0 ) then
        begin  { Il y a une ombre … recalculer }
          Put( x1, y1, x2-ShadowX, y2-ShadowY, Nouveau, WinNrBuf );
          WinShadow( x2-ShadowX+1, y1+ShadowY, x2, y2, Nouveau );
          WinShadow( x1+ShadowX, y2-ShadowY+1, x2-ShadowX, y2, Nouveau );
        end
      else  { Pas d'ombre }
        Put( x1, y1, x2, y2, Nouveau, WinNrBuf );
    end;

  {-- D‚place le descripteur de la fenˆtre trait‚e … la fin de la liste chaŒn‚e -}

  Wip^.NextWin^.LastWin := WiP^.LastWin;
  if WiP = FirstWinPtr then  { Est-ce que WIP ‚tait la premiŠre fenˆtre ? }
    FirstWinPtr := WiP^.NextWin  { Oui, c'est son successeur qui va ˆtre en premiŠre position }
  else  { Non, WIP a encore un successeur }
    Wip^.LastWin^.NextWin := WiP^.NextWin;

  Wip^.NextWin := nil;   { Plus de fenˆtre aprŠs WIP }
  Wip^.LastWin := ActWinPtr;  { le pr‚d‚cesseur est l'ancienne fenˆtre courante }
  ActWinPtr^.NextWin := WiP;   { qui pointe maintenant sur WIP ÿ}
  ActWinPtr := WiP;
  ActBufPtr := @Wip^.Buffer;

  {-- Affiche le nouvel ‚cran --}

  PutScr( 0, 0, NbCol-1, NbLig-1, Nouveau );

  {-- LibŠre les buffers allou‚s    }

  FreeMem( WinNrBuf, AwiLen );
  FreeMem( Nouveau,  VioLen);
  FreeMem( Ancien,   VioLen);
  FreeMem( VioCopy, VioLen);

  WinInFront := TRUE;        { Tout est bien qui finit bien }
end;
