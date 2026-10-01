{**************************************************************************
*  W I N : une unit‚ de routines permettant l'accŠs direct … la m‚moire   *
*          vid‚o et la gestion de fenˆtres                                *
**-----------------------------------------------------------------------**
*  Auteur           : MICHAEL TISCHER                                     *
*  D‚velopp‚ le     : 17.03.1989                                          *
*  DerniŠre MAJ     : 21.09.1989                                          *
**************************************************************************}

unit Win;

interface
uses Dos, Crt;      { Inclusion des unit‚s n‚cessaires }

{-- D‚claration des fonctions et proc‚dures susceptibles d'ˆtre  ---------}
{-- appel‚es par un autre programme                                 ------}

function  VG            ( Offset : integer ) : byte;
function  VD            ( Offset : integer ) : byte;
function  VH            ( Offset : integer ) : byte;
function  VB            ( Offset : integer ) : byte;
function  WinOpen       ( x1, y1, x2, y2 : byte ) : integer;
function  WinOpenShadow ( x1, y1, x2, y2 : byte ) : integer;
function  WinInFront    ( Key : integer ) : boolean;
function  WhereX        : integer;
function  WhereY        : integer;
function  WinGetChar    ( Colonne, Ligne : byte ) : char;
function  WinGetCol     ( Colonne, Ligne : byte ) : byte;
procedure WinWrite2View ( Doit : boolean );
procedure WinPutChar    ( Colonne, Ligne : byte; Caractere : char;
                          Couleur : byte );
procedure WinSetCursor  ( Colonne, Ligne : byte );
procedure WinDefCursor  ( Debut, Fin : byte );
procedure WinHideCursor;
procedure WinBlockCursor;
procedure WinLineCursor;
procedure WinSetView    ( x1, y1, x2, y2 : byte);
procedure WinGetView    ( var x1, y1, x2, y2 : byte );
procedure GotoXY        ( X, Y : integer );
procedure TextColor     ( Color : byte );
procedure TextBackground( Color : byte );
procedure ClrScr;
procedure WinClose      ( ReDraw : boolean );
procedure WinPrint      ( Colonne, Ligne, Couleur : byte; Sortie : string );
procedure WinFill       ( x1, y1, x2, y2 : byte; Caractere : char;
                          Couleur : byte );
function  WinStRep      ( Caractere : char; Nombre : byte ) : string;
procedure WinFrame      ( x1, y1, x2, y2, Cadre, Couleur : byte );
procedure WinScrollDown ( x1, y1, x2, y2, Nombre, Couleur : byte );
procedure WinScrollUp   ( x1, y1, x2, y2, Nombre, Couleur : byte );
procedure WinScrollLeft ( x1, y1, x2, y2, Nombre, Couleur : byte );
procedure WinScrollRight( x1, y1, x2, y2, Nombre, Couleur : byte );
procedure WinMoveUp     ( Nombre : byte );
procedure WinMoveDown   ( Nombre : byte );
procedure WinMoveRight  ( Nombre : byte );
procedure WinMoveLeft   ( Nombre : byte );
procedure WinMove       ( x, y : byte );
procedure WinColor      ( x1, y1, x2, y2, Couleur : byte );

{-- Constantes publiques  ------------------------------------------------}

const {-- les constantes suivantes repr‚sentent le contenu de VioCarte -}

      MDA       = 0;           {  MDA und HGC   }
      CGA       = 1;
      EGA       = 2;
      EGA_MONO  = 3;           { EGA avec moniteur MDA }
      VGA       = 4;
      VGA_MONO  = 5;           { VGA avec moniteur analogique monochr. }
      MCGA      = 6;
      MCGA_MONO = 7;           { MCGA avec moniteur analogique monochr.}

      {-- Constantes pour la proc‚dure WinFrame ---------}

      CAD_SIM    = 1;    { Cadre simple  }
      CAD_DOU    = 2;    { Cadre double  }
      CAD_POI    = 3;    { Cadre pointill‚ }
      CAD_PLE    = 4;    { Cadre plein }

      NO_CLEAR     = 255;  { pour les proc‚dures WinScroll }
      WinOpenError = -1;   { Fenˆtre impossible … ouvrir }
      MAX_COLS     = 132;  { Certaines cartes VGA supportent 132 colonnes }

      {-- Couleurs ----------------------------------------------------}

      NOIR        =  0;
      BLEU        =  1;
      VERT        =  2;
      CYAN        =  3;
      ROUGE       =  4;
      MAGENTA     =  5;
      BRUN        =  6;
      GRISCLAIR   =  7;
      GRISFONCE   =  8;
      BLEUCLAIR   =  9;
      VERTCLAIR   = 10;
      CYANCLAIR   = 11;
      ROUGECLAIR  = 12;
      MAGENTACLAIR= 13;
      JAUNE       = 14;
      BLANC       = 15;

{-- Variables globales ‚galement accessibles … d'autres programmes -----}

var Color : boolean;  { TRUE pour les cartes couleur }
    VioCarte,         { Code d‚crivant la carte vid‚o }
    NbLig,           { Nombre de lignes d'‚cran }
    NbCol    : byte;  { Nombre de colonnes d'‚cran }

{-- Constantes typ‚es, publiques -------------------------------------}

const Write2View : boolean = TRUE;  { Pour que Writeln tienne compte des }
                                    { limites de la zone de visualisation }
      ShadowX    : byte = 2;        { Largeur d'une ombre en colonnes }
      ShadowY    : byte = 1;        { Profondeur d'une ombre en lignes}

implementation

{-- Constantes internes au module ----------------------------------------}

const {-- Attribut de la fenˆtre------------------------------------------}

      WIN_OMBRE = 1;       { Bit 0: La fenˆtre n'a pas d'ombre }

{-- D‚clarations de types internes au module -----------------------------}

type BPTR     = ^byte;   { Pointe sur un octet }

     VEL      = record   { D‚crit un couple caractŠre-attribut }
                  case boolean of      
                    true  : ( Caractere, Attribut : byte );
                    false : ( Contenu : word );
                end;

     VPTR     = ^VEL;   { Pointe sur un couple caractŠre-attribut }

     VELARRAY = array [0..9999] of VEL;  { Buffer de fenˆtre }

     VELARPTR = ^VELARRAY;    { Pointe sur un buffer de fenˆtre}

     WIPTR    = ^WINDES;      { Pointe sur un descripteur de fenˆtre }

     WINDES   = record       { Descripteur de fenˆtre }
                  Attribut,  { Attribut de la fenˆtre }
                  Handle,    { Num‚ro servant de cl‚ d'accŠs … la fenˆtre }
                  x1, y1,    { Coordonn‚es des coins de la fenˆtre }
                  x2, y2,
                  ViewX1, ViewY1, { Coordonn‚es de la zone }
                  ViewX2, ViewY2, { de visualisation }
                  curc, curl    : byte; { Coordonn‚es du curseur avant
                                          ouverture }
                  lastwin,     { Lien avec la fenˆtre pr‚c‚dente ...}
                  nextwin       : WIPTR; { ...et avec la suivante  }
                  buffer        : byte;   { D‚but du buffer de la
                                            fenˆtre }
                end;

     PTRREC   = record     { Permet d'acc‚der aux }
                  Ofs : word;   { composants d'un pointeur }
                  Seg : word;   { quel qu'il soit }
                end;

     HANDLES  = array [0..63] of byte; { Tableau de bits pour m‚moriser }              
                                       { les num‚ros des fenˆtres }

     HANDPTR  = ^HANDLES;    { Pointe sur le tableau des num‚ros }

{-- Variables globales internes au module ----------------------------}

var VioSeg      : word;   { Segment de la m‚moire vid‚o }
    LigneOfs   : integer; { Nombre d'octets dans une ligne }
    WritelnX,      { Colonne d'affichage pour Writeln }
    WritelnY,      { Ligne d'affichage pour Writeln }
    vLigne,        { Position courante du curseur }
    vColonne,
    ViewX1,        { Coin sup‚rieur gauche de la zone de visualisation  }
    ViewY1,        { par rapport … la totalit‚ de l'‚cran }
    ViewX2,        { Coin inf‚rieur droit de la zone de visualisation }
    ViewY2      : byte;  { par rapport … la totalit‚ de l'‚cran }

    WritelnPtr  : VPTR; { Pointe sur la position d'affichage de WinWriteln}
    FirstWinPtr : WIPTR; { Pointe sur le premier descripteur de fenˆtre }
    ActBufPtr   : VELARPTR; { Pointe sur le buffer courant }
    HaPtr       : HANDPTR;  { Pointe sur le tableau des num‚ros }

{-- Variables globales initialis‚es (constantes typ‚es )    --------------}

const NbWin    : integer = 0;  { Nombre de fenˆtres ouvertes }
      ActWinPtr : WIPTR = nil;  { Pointe sur le descripteur courant }
      WritelnCol: byte = $07;   { Couleur d'affichage pour Writeln }

{**************************************************************************
*  VG : renvoie une abscisse relative au bord gauche de la fenˆtre        *
*       active                                                            *
**-----------------------------------------------------------------------**
*  Entr‚e : Offset = Distance … partir du bord gauche de la fenˆtre       *
*  Sortie : Nombre de colonnes en coordonn‚es absolues                    *
*  Information    : Si aucune fenˆtre n'est ouverte, c'est la totalit‚ de *
*                   l'‚cran qui sert de cadre de r‚f‚rence                *
*  Variables globales : ViewX1/R                                          *
**************************************************************************}
function VG( Offset : integer ) : byte;

begin
  VG:= ViewX1 + Offset;
end;


{**************************************************************************
*  VD : renvoie une abscisse relative au bord droit de la fenˆtre         *
*       active                                                            *
**-----------------------------------------------------------------------**
*  Entr‚e : Offset = Distance … partir du bord droit de la fenˆtre        *
*  Sortie : Nombre de colonnes en coordonn‚es absolues                    *
*  Information    : Si aucune fenˆtre n'est ouverte, c'est la totalit‚ de *
*                   l'‚cran qui sert de cadre de r‚f‚rence                *
*  Variables globales : ViewX2/R                                          *
**************************************************************************}
function VD( Offset : integer ) : byte;

begin
  VD := ViewX2 + Offset;
end;

{**************************************************************************
*  VH : renvoie une ordonn‚e relative au bord sup‚rieur de la fenˆtre     *
*       active                                                            *
**-----------------------------------------------------------------------**
*  Entr‚e : Offset = Distance … partir du bord sup‚rieur de la fenˆtre    *
*  Sortie : Nombre de lignes en coordonn‚es absolues                      *
*  Information    : Si aucune fenˆtre n'est ouverte, c'est la totalit‚ de *
*                   l'‚cran qui sert de cadre de r‚f‚rence                *
*  Variables globales : ViewY1/R                                          *
***************************************************************************}

function VH( Offset : integer ) : byte;

begin
  VH := ViewY1 + Offset;
end;

{***************************************************************************
*  VB : renvoie une ordonn‚e relative au bord inf‚rieur de la fenˆtre      *
*       active                                                             *
**------------------------------------------------------------------------**
*  Entr‚e : Offset = Distance … partir du bord inf‚rieur de la fenˆtre     *
*  Sortie : Nombre de lignes en coordonn‚es absolues                       *
*  Information    : Si aucune fenˆtre n'est ouverte, c'est la totalit‚ de  *
*                   l'‚cran qui sert de cadre de r‚f‚rence                 *
*  Variables globales : ViewY2/R                                           *
***************************************************************************}

function VB( Offset : integer ) : byte;

begin
  VB := ViewY2 + Offset;
end;

{***************************************************************************
*  GetVioPtr : retourne un pointeur sur un caractŠre donn‚ de la m‚moire   *
*              vid‚o                                                       *
**------------------------------------------------------------------------**
*  Entr‚e : Ligne, Colonne = Coordonn‚es du caractŠre                      *
*  Sortie : Pointeur sur caractŠre en m‚moire vid‚o, de type  VPTR         *
*  Information    : L'origine des coordonn‚es (0/0) est le coin sup‚rieur  *
*                   gauche de l'‚cran                                      *
*  Variables globales : VioSeg/R, NbCol/R                                  *
***************************************************************************}

function GetVioPtr( Colonne, Ligne : byte ) : VPTR;

begin
  GetVioPtr := Ptr( VioSeg, ( NbCol * Ligne + Colonne ) shl 1);
end;

{***************************************************************************
*  WinGetChar : indique le code ASCII d'un caractŠre se trouvant … un      *
*               emplacement donn‚                                          *
**------------------------------------------------------------------------**
*  Entr‚es : Ligne, Colonne = Coordonn‚es du caractŠres                    *
*  Sortie : le code ASCII du caractŠre                                     *
*                                                                          *
*  Variables globales : VioSeg/R, NbCol/R                                  *
***************************************************************************}

function  WinGetChar( Colonne, Ligne : byte ) : char;

begin
  WinGetChar := chr(Mem[VioSeg : (NbCol * Ligne + Colonne ) shl 1]);
end;

{***************************************************************************
*  WinGetCol : indique la couleur d'un caractŠre se trouvant … un          *
*              emplacement donn‚                                           *
**------------------------------------------------------------------------**
*  Entr‚es : Ligne, Colonne = Coordonn‚es du caractŠre                     *
*  Sortie : le code couleur du caractŠre                                   *
*  Variables globales : VioSeg/R, NbCol/R                                  *
***************************************************************************}

function  WinGetCol( Colonne, Ligne : byte ) : byte;

begin
  WinGetCol := Mem[VioSeg : (NbCol * Ligne + Colonne ) shl 1 + 1];
end;

{***************************************************************************
*  WinPutChar : ‚crit un caractŠre et son attribut directement dans la     *
*               m‚moire vid‚o                                              *
**------------------------------------------------------------------------**
*  Entr‚e : Ligne, Colonne = Coordonn‚es du caractŠre                      *
*            Caractere     = CaractŠre … afficher                          *
*            Couleur       = Couleur ou attribut  du caractŠre             *
*  Information    : l'origine des coordonn‚es est le point (0,0) situ‚     *
*                   au coin sup‚rieur gauche de l'‚cran                    *
                                                                           *
*  Variables globales : VioSeg/R, NbCol/R                                  *
***************************************************************************}

procedure WinPutChar( Colonne, Ligne : byte; Caractere : char; Couleur : byte );

var OfsPos : integer; { Offset de la position du caractŠre en m‚m. vid‚o }

begin
  OfsPos := (NbCol * Ligne + Colonne ) shl 1;   { Calcule l'offset }
  Mem[ VioSeg : OfsPos ] := ord( Caractere );  { Ecrit le caractŠre et   }
  Mem[ VioSeg : OfsPos + 1 ] := Couleur;  { l'attribut en m‚moire vid‚o }
end;

{***************************************************************************
*  WinSetCursor : positionne le curseur clignotant                         *
**------------------------------------------------------------------------**
*  Entr‚e : Ligne, Colonne = nouvelle position du curseur                  *
*  Variables globales : vLigne/W, vColonne/W                               *
***************************************************************************}

procedure WinSetCursor( Colonne, Ligne : byte );

var Regs : Registers;  { Registres utilis‚s par l'interruption }

begin
  Regs.ah := 2;  { Num‚ro de la fonction Set Cursor }
  Regs.bh := 0;  { Page d'‚cran concern‚e }
  Regs.dh := Ligne;  { Transmet la ligne souhait‚e }
  vLigne  := Ligne;
  Regs.dl := Colonne;  { Transmet la colonne souhait‚e }
  vColonne := Colonne;
  intr($10, Regs);   { Appelle l'interruption du BIOS vid‚o }
end;
{***************************************************************************
*  WinDefCursor : d‚finit l'aspect du curseur                              *
**------------------------------------------------------------------------**
*  Entr‚e : Debut  = Ligne de d‚but du curseur                             *
*           Fin    = Ligne de fin du curseur                               *
*  Variable globale : n‚ant                                                *
***************************************************************************}

procedure WinDefCursor( Debut, Fin : byte );

var Regs : Registers;   { Registres utilis‚s par l'interruption }

begin
  Regs.ah := 1;   { Num‚ro de la fonction }
  Regs.ch := Debut;  { Charge les lignes de d‚but et de fin }
  Regs.cl := Fin;
  intr($10, Regs);  { D‚clenche l'interruption du BIOS vid‚o }
end;

{***************************************************************************
*  WinHideCursor : retire le curseur de l'‚cran                            *
**------------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                          *
*  Variable globale : NbLig/R                                              *
***************************************************************************}

procedure WinHideCursor;

begin
  WinSetCursor( 0, NbLig + 1 );  {Place le curseur en dehors de l'‚cran }
end;

{***************************************************************************
*  WinBlockCursor : d‚finit le curseur comme un rectangle recouvrant       *
*                   le caractŠre situ‚ en-dessous                          *
**------------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                          *
*  Variable globale : Color/R                                              *
***************************************************************************}

procedure WinBlockCursor;

begin
  if ( Color ) then    { Carte couleur ? }
    WinDefCursor( 0, 7 )  { Oui }
  else     { Carte monochrome }
    WinDefCursor( 0, 13 );
end;

{***************************************************************************
*  WinLineCursor : d‚finit le curseur comme un tiret s'‚tendant            *
*                  sur les deux derniŠres lignes de trame                  *
**------------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                          *
*  Variable globale : Color/R                                              *
***************************************************************************}

procedure WinLineCursor;

begin
  if ( Color ) then  { Carte couleur ? }
    WinDefCursor( 6, 7 )      { Oui }
 else   { Carte monochrome }
    WinDefCursor( 12, 13 );
end;

{***************************************************************************
*  WinSetView : d‚finit une zone de l'‚cran comme zone de visualisation    *
*               … laquelle se r‚fŠrent les fonctions VG, VD, VH, VB        *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone      *
  x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone                  *
*  Variables globales : ViewX1/W, ViewX2/W, ViewY1/W, ViewY2/W             *
***************************************************************************}

procedure WinSetView( x1, y1, x2, y2 : byte);

begin
  ViewX1 := x1;    { M‚morise les coordonn‚es dans }
  ViewY1 := y1;    { les variables globales }
  ViewX2 := x2;
  ViewY2 := y2;
end;

{***************************************************************************
*  WinGetView : indique la zone de visualisation actuelle                  *
*                                                                          *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone      *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone       *
*  Information    : la zone de visualisation sert de cadre de r‚f‚rence    *
*                   aux fonctions VG, VD, VH, VB                           *
*  Variables globales : ViewX1/R, ViewX2/R, ViewY1/R, ViewY2/R             *
***************************************************************************}

procedure WinGetView( var x1, y1, x2, y2 : byte );

begin
  x1 := ViewX1;   { Prend les coordonn‚es dans   }
  y1 := ViewY1;   { les variables globales       }
  x2 := ViewX2;
  y2 := ViewY2;
end;

{***************************************************************************
*  WinWrite2View: active ou d‚sactive la prise en compte par Writeln       *
*                 de la zone de visualisation actuelle                     *
**------------------------------------------------------------------------**
*  Entr‚es : Doit = TRUE : fait respecter la zone de visualisation         *
*                   FALSE: d‚signe l'‚cran dans sa totalit‚ comme          *
*                          r‚f‚rence d'affichage.                          *
*                          Pas de d‚filement en fin d'‚cran                *
*  Globals : Write2View/W                                                  *
***************************************************************************}

procedure WinWrite2View( Doit : boolean );

begin
  Write2View := Doit; { M‚morise un indicateur }
end;


{**************************************************************************
*  WhereX : retourne la colonne d'affichage de la prochaine instruction   *
*           Writeln appliqu‚e … la variable fichier OUTPUT                *
**-----------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                         *
*  Sortie : cf supra                                                      *
*  Variables globales : WritelnX/R                                        *
**************************************************************************}

function WhereX : integer;

begin
  WhereX := WritelnX;  { Retourne la colonne d'affichage }
end;

{***************************************************************************
*  WhereY : retourne la ligne d'affichage de la prochaine instruction      *
*           Writeln appliqu‚e … la variable fichier OUTPUT                 *
**------------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                          *
*  Sortie : cf supra                                                       *
*  Variables globales : WritelnY/R                                         *
***************************************************************************}

function WhereY : integer;

begin
  WhereY := WritelnY;   { Retourne la ligne d'affichage }
end;

{**************************************************************************
*  TextColor : fixe la couleur des caractŠres pour l'affichage            *
*              par Writeln                                                *
**-----------------------------------------------------------------------**
*  Entr‚e : Col = la couleur de caractŠre choisie (0-15)                  *
*  Variables globales : WritelnCol/RW                                     *
**************************************************************************}

procedure TextColor( Color : byte );

begin
  WritelnCol := ( WritelnCol and $F0 ) or Color;  { Met la couleur }
end;

{***************************************************************************
*  TextBackground : fixe la couleur de fond pour l'affichage               *
*                   par Writeln .                                          *
**------------------------------------------------------------------------**
*  Entr‚e : Col = la couleur de fond choisie (0-15)                        *
*  Variables globales : WritelnCol/RW                                      *
***************************************************************************}

procedure TextBackground( Color : byte );

begin
  WritelnCol := ( WritelnCol and $0F ) or ( Color shl 4 );  { Met la couleur }
end;

{***************************************************************************
*  ClrScr : efface l'‚cran                                                 *
**------------------------------------------------------------------------**
*  Entr‚e : n‚ant                                                          *
*  Information    : Remplace la proc‚dure homonyme de l'unit‚ Crt          *
*  Variables globales : NbCol/R, NbLig/R, WritelnCol/R                     *
***************************************************************************}

procedure ClrScr;

begin
  WinFill( 0, 0, NbCol-1, NbLig-1, ' ', WritelnCol );
end;

{**************************************************************************
*  GotoXY : remplace la proc‚dure GotoXY de l'unit‚ CRT                   *
*           fixe la position d'affichage pour le prochain appel           *
*           de la proc‚dure Writeln d‚tourn‚e                             *
**-----------------------------------------------------------------------**
*  Entr‚es : X = Colonne d'affichage                                      *
*            Y = Ligne d'affichage                                        *
*  Information    : le curseur visible n'est pas affect‚                  *
*  Variables globales : WritelnX/W, WritelnY/W, WritelnPtr/W              *
**************************************************************************}

procedure GotoXY( X, Y : integer );

begin
  WritelnX := X;   { M‚morise la position dans la variable globale }
  WritelnY := Y;
  WritelnPtr := GetVioPtr( x, y ); { Pointe sur la nouvelle position }
end;

{***************************************************************************
*  GetScr : m‚morise dans un buffer une zone de l'‚cran                    *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone      *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone       *
*            BufPtr = Pointe sur le buffer destin‚ … stocker la zone       *
*  Information    : Le buffer contient les lignes sous forme lin‚aire      *
*                   juxtapos‚e                                             *
*  Variables globales : n‚ant                                              *
***************************************************************************}

procedure GetScr( x1, y1, x2, y2 : byte; BufPtr : pointer );

var nbytes : integer;  { Nombre d'octets … copier par ligne }

begin
  nbytes := ( x2 - x1 + 1 ) shl 1;   { Octets par ligne }
  while y1 <= y2 do   { Parcourt les lignes }
    begin
      Move( GetVioPtr(x1, y1)^, BufPtr^, nbytes);
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );     { Y1 = ligne suivante }
    end;
end;

{****************************************************************************
*  PutScr : copie directement le contenu d'un buffer dans la m‚moire vid‚o  *
**-------------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche de la zone       *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone        *
*            BufPtr = Pointe sur le buffer … recopier dans la m‚moire vid‚o *
*  Information    : Le buffer doit ˆtre au format d‚fini par PutScr         *
*  Variables globales : n‚ant                                               *
****************************************************************************}

procedure PutScr( x1, y1, x2, y2 : byte; BufPtr : pointer );

var nbytes : integer;  { Nombre d'octets … copier par ligne }

begin
  nbytes := ( x2 - x1 + 1 ) shl 1;  { Octets par ligne }
  while y1 <= y2 do   { Parcourt les lignes }
    begin
      Move( BufPtr^, GetVioPtr(x1, y1)^, nbytes);
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );        { Y1 = ligne suivante }
    end;
end;

{***************************************************************************
*  WinOpen : ouvre une fenˆtre                                             *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1 = Coordonn‚es du coin sup‚rieur gauche                 *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit                  *
*  Sortie : Num‚ro (handle) permettant d'acc‚der par la suite              *
*            la fenˆtre                                                    *
*  Information    : Si la fenˆtre n'a pas pu ˆtre ouverte en raison du     *
*                   manque de m‚moire sur le tas, le num‚ro retourn‚ a     *
*                   la valeur WinOpenError (-1)                            *
*  Variables globales : vLigne/R, vColonne/R, ViewX1/R, ViewX2/R,          *
*                       ViewY1/R, ViewY2/R, NbWin/W, FirstWinPtr/RW,       *
*                       ActWInPtr/RW, HaPtr^/RW                            *
***************************************************************************}

function WinOpen( x1, y1, x2, y2 : byte ) : integer;

var i, j,    { Compteurs d'it‚rations }
    Key,     { M‚morise le num‚ro d'accŠs }
    BufLen : integer;  { Taille du buffer }
    WinPtr : WIPTR;    { Decsripteur de fenˆtre }
begin
  BufLen := ( x2 - x1 + 1 ) * ( y2 - y1 + 1 ) shl 1;
  if MaxAvail >= BufLen + SizeOf( WINDES ) - 1 then
    begin   { Il reste assez de m‚moire }
      GetMem( WinPtr, BufLen + SizeOf( WINDES ) - 1 );
      WinPtr^.x1      := x1;    { TransfŠre les coordonn‚es }
      WinPtr^.x2      := x2;    { de la fenˆtre }
      WinPtr^.y1      := y1;    { dans le descripteur }
      WinPtr^.y2      := y2;
      WinPtr^.curc    := vColonne;  { M‚morise ‚galement la position }                     
                                     { actuelle du curseur }
      WinPtr^.curl    := vLigne; 
      WinPtr^.ViewX1  := ViewX1; { TransfŠre les coordonn‚es }
      WinPtr^.ViewY1  := ViewY1; { de la zone de visualisation }
      WinPtr^.ViewX2  := ViewX2; { dans le descripteur }
      WinPtr^.ViewY2  := ViewY2; 
      WinPtr^.Attribut:= 0;      { Pas encore d'attribut }
      WinPtr^.LastWin := ActWinPtr;  { Lien avec la fenˆtre pr‚c‚dente }
      WinPtr^.NextWin := NIL;    { Pas encore de successeur }

      GetScr( x1, y1, x2, y2, @WinPtr^.Buffer );
      ActBufPtr := VELARPTR(@WinPtr^.Buffer);  { Pointe sur le buffer }

      WinSetView( x1, y1, x2, y2 ); { Zone de visualisation = la fenˆtre }

      if ActWinPtr <> NIL then  { Existait-il d‚j… une autre fenˆtre ? }
        ActWinPtr^.NextWin := WinPtr {Oui, la relie … la nouvelle }
      else  { Non la pr‚sente est la premiŠre et la seule fenˆtre  }
        FirstWinPtr := WinPtr; { Pointe sur la premiŠre fenˆtre }
      ActWinPtr := WinPtr; { Pointe sur la fenˆtre active }

      inc( NbWin );  { Incr‚mente le nombre de fenˆtres ouvertes }

      {-- Recherche un num‚ro libre point‚ par HaPtr ---------}

      Key := 0;   { num‚ro = rang du bit }
      while (HaPtr^[ Key shr 3 ] and ( 1 shl (Key and 7) )) <> 0 do
        inc( Key );  { Num‚ro d‚j… attribu‚, passe au suivant }
      HaPtr^[ Key shr 3 ] := HaPtr^[ Key shr 3 ] or ( 1 shl ( Key and 7 ));
      WinPtr^.Handle := Key;   { M‚morise le num‚ro dans le descripteur }
      WinOpen := Key;   { Passe le num‚ro au programme appelant }
    end
  else  { Pas assez de m‚moire pour le descripteur et le buffer associ‚ }
    WinOpen := -1;
end;

{***************************************************************************
*  WinClose : referme la derniŠre fenˆtre ouverte                          *
**------------------------------------------------------------------------**
*  Entr‚e : Redraw = TRUE : le contenu de l'‚cran recouvert par la         *
*                            fenˆtre est restaur‚                          *
*  Information    : Le programme appelant doit s'assurer qu'au moment de   *
*                   l'appel de la proc‚dure il reste au moins une fenˆtre  *
*                   ouverte                                                *
*  Variables globales : ActWinPtr/RW, FirstWinPtr/RW, HaPTr^/RW, NbWin/W   *
***************************************************************************}

procedure WinClose( ReDraw : boolean );

var WinPtr : WIPTR;  { Pointe sur le descripteur actuel }

begin
  with ActWinPtr^ do
    begin
      {-- Restitue le num‚ro de la fenˆtre --------------------}

      HaPtr^[ Handle shr 3 ] := HaPtr^[ Handle shr 3 ] and
                                               not( 1 shl ( Handle and 7 ));

      if ReDraw then   { Faut-il reconstituer l'‚cran ? }
        PutScr( x1, y1, x2, y2, @Buffer ); { Oui  }
      WinSetView( ViewX1, ViewY1, ViewX2, ViewY2 );  { ancienne zone de visualisation }
      WinSetCursor( curc, curl ); { RamŠne le cusreur … son ancienne position }
      WinPtr := ActWinPtr;  { M‚morise le pointeur sur le descript. actuel }
      ActWinPtr := LastWin;  { Pointe sur le descripteur pr‚c‚dent }
      if LastWin <> NIL then   { Plus de fenˆtre ouverte ? }
        ActWinPtr^.NextWin := NIL  { Oui, plus de successeur }
      else   { Non }
        FirstWinPtr := NIL;  { Ne pointe sur rien }

      {-- LibŠre la m‚moire allou‚e pour le descripteur ---}
      FreeMem( WinPtr, (x2-x1+1) * (y2-y1+1) shl 1 + SizeOf(WINDES) - 1);

      ActBufPtr := VELARPTR(@ActWinPtr^.Buffer); { Pointe sur le buffer }

      dec( NbWin );  { D‚cr‚mente le nombre de fenˆtres ouvertes }
    end;
end;

{***************************************************************************
*  WinStRep : construit une chaŒne de caractŠres r‚p‚titifs                *
**------------------------------------------------------------------------**
*  Entr‚e : Caractere = le caractŠre … r‚p‚ter                             *
*              Nombre = Nombre de r‚p‚titions ou longueur de la chaŒne     *
*  Sortie : la chaŒne construite                                           *
*  Variable globale : n‚ant                                                *
***************************************************************************}

function WinStRep( Caractere : char; Nombre : byte ) : string;

var StrepString : String;   { Pour contenir la chaŒne }

begin
  StrepString[0] := chr( Nombre );
  FillChar( StrepString[1], Nombre, Caractere );
  WinStRep := StrepString;
end;

{***************************************************************************
*  WinPrint : ‚crit une chaŒne directement dans la m‚moire vid‚o           *
**------------------------------------------------------------------------**
*  Entr‚es : Colonne, Ligne = Position d'affichage                         *
*            Couleur         = Couleur ou attribut du caractŠre … afficher *
*            Sortie          = ChaŒne … afficher                           *
*  Information : - Si la chaŒne d‚passe la fin de la ligne, l'affichage se *
*                  poursuit … la ligne suivante                            *
*                - Si la fin de l'‚cran ou de la fenˆtre active est        *
*                  atteinte, il n'y a pas de d‚filement vers le haut       *
*  Variable globale : n‚ant                                                *
***************************************************************************}

procedure WinPrint( Colonne, Ligne, Couleur : byte; Sortie : string );

var VioPtr : VPTR;     { Pointe sur la m‚moire vid‚o }
    i, j   : byte;     { Compteurs d'it‚rations }

begin
  VioPtr := GetVioPtr( Colonne, Ligne ); { Charge un pointeur }
  j := length( Sortie ); { D‚termine la longueur de la chaŒne }
  for i:=1 to j do   { Parcourt les caractŠres de la chaŒne }
    begin
      VioPtr^.Caractere := ord( Sortie[i] ); { Met le caractŠre et }
      VioPtr^.Attribut := Couleur;  { son attribut dans la m‚moire vid‚o }
      inc( PTRREC( VioPtr ).Ofs, 2 ); { Passe au caractŠre suivant }
    end;
end;

{***************************************************************************
*  WinFill : remplit une zone de l'‚cran avec un caractŠre et une          *
*            couleur donn‚s                                                *
**------------------------------------------------------------------------**
*  Entr‚es: x1, y1  = Coordonn‚es du coin sup‚rieur gauche de la zone      *
*            x2, y2 = Coordonn‚es du coin inf‚rieur droit de la zone       *
*            Caractere,                                                    *
*            Couleur   = le caractŠre et son attribut                      *
*  Variable globale : n‚ant                                                *
***************************************************************************}
procedure WinFill( x1, y1, x2, y2 : byte; Caractere : char; Couleur : byte );

var Ligne : string;  { M‚morise une ligne de caractŠres }

begin
  Ligne := WinStRep( Caractere, x2-x1+1 );    { Fabrique une ligne }
  while y1 <= y2 do      { Parcourt la zone ligne par ligne }
    begin
      WinPrint( x1, y1, Couleur, Ligne );  { Affiche la ligne fabriqu‚e }
      inc( y1 );   { Passe … la ligne suivante }
    end;
end;

{***************************************************************************
*  WinFrame : trace un cadre autour d'une zone de l'‚cran                  *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1  = Coordonn‚es du coin sup‚rieur gauche de la zone     *
*            x2, y2  = Coordonn‚es du coin inf‚rieur droit de la zone      *
*            Cadre   = l'une des constantes CAD_SIM, CAD_DOU, etc          *
*            Couleur = Couleur (attribut) du cadre                         *
*  Variable globale : n‚ant                                                *
***************************************************************************}

procedure WinFrame( x1, y1, x2, y2, Cadre, Couleur : byte );

type CadStruc = record   { Liste des caractŠres formant le cadre }
                SupGauche,
                SupDroite,
                InfGauche,
                InfDroite,
                Vertical,
                Horizontal  : char;
              end;

const CadCaractere : array[1..4] of CadStruc =  { Types de cadres disponibles }
       (
        ( SupGauche   : 'Ú'; SupDroite  : '¿'; InfGauche  : 'À';
          InfDroite : 'Ù'; Vertical    : '³'; Horizontal  : 'Ä' ),
        ( SupGauche   : 'É'; SupDroite  : '»'; InfGauche  : 'È';
          InfDroite : '¼'; Vertical    : 'º'; Horizontal  : 'Í' ),
        ( SupGauche   : '±'; SupDroite  : '±'; InfGauche  : '±';
          InfDroite : '±'; Vertical    : '±'; Horizontal  : '±' ),
        ( SupGauche   : 'Û'; SupDroite  : 'Û'; InfGauche  : 'Û';
          InfDroite : 'Û'; Vertical    : 'Û'; Horizontal  : 'Û' )
       );

var StrepBuf : string;  { Stocke une ligne horizontale }
    Ligne    : byte;   { Compteur }

begin
 with CadCaractere[ Cadre ] do
   begin
     WinPutChar( x1, y1, SupGauche, Couleur );  { Dessine les quatre }
     WinPutChar( x2, y1, SupDroite, Couleur );  { coins du cadre }
     WinPutChar( x1, y2, InfGauche, Couleur );
     WinPutChar( x2, y2, InfDroite, Couleur );

     StrepBuf := WinStRep( Horizontal, x2-x1-1 );  { puis les deux lignes }
     WinPrint( x1+1, y1, Couleur, StrepBuf );      { horizontales }
     WinPrint( x1+1, y2, Couleur, StrepBuf );           

     dec( y2 );   { Fixe la fin de la boucle qui suit }
     for Ligne:=y1+1 to y2 do  { Parcourt les lignes }
       begin                   { et trace les verticales  }
         WinPutChar( x1, Ligne, Vertical, Couleur );
         WinPutChar( x2, Ligne, Vertical, Couleur );
       end;
   end;
end;

{***************************************************************************
*  WinColor : remplit une zone de l'‚cran avec un attribut donn‚           *
*             sans modifier les caractŠres de la zone                      *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1  = Coordonn‚es du coin sup‚rieur gauche de la zone     *
*            x2, y2  = Coordonn‚es du coin inf‚rieur droit de la zone      *
*            Couleur = la nouvelle couleur des caractŠres                  *
*  Variable globale : LigneOfs/R                                           *
***************************************************************************}

procedure WinColor( x1, y1, x2, y2, Couleur : byte );

var VioPtr : VPTR;   { Pointe sur la m‚moire vid‚o }
    Ligne,    { Compteur de lignes }
    Colonne,  { Compteur de colonnes }
    DeltaX : integer; { Diff‚rence entre deux lignes  }

begin
  VioPtr := GetVioPtr( x1, y1 ); { Pointe sur le premier caractŠre }
  DeltaX := LigneOfs - ( (x2-x1) shl 1 ) - 2;  { Offset de x2 … x1 }

  for Ligne:=y1 to y2 do   { Parcourt les lignes }
    begin    { Parcourt les colonnes }
      for Colonne:=x1 to x2 do
        begin
          VioPtr^.Attribut := Couleur;  { Enregistre la couleur  }
          inc( PTRREC(VioPtr).Ofs, 2 ); { Augmente l'offset de 2 }
        end;
      inc( PTRREC(VioPtr).Ofs, DeltaX );
    end;
end;

{***************************************************************************
*  WinShadow : dessine une ombre                                           *
**------------------------------------------------------------------------**
*  Entr‚es : x1, y1  = Coordonn‚es du coin sup‚rieur gauche de l'ombre     *
*            x2, y2  = Coordonn‚es du coin inf‚riur droit de l'ombre       *
*            BufPtr  = Pointeur d‚signant le buffer … manipuler            *
*                      Information. En mode couleur, l'ombre est g‚n‚r‚e   *
*                      par modification des attributs des caractŠres,      *
*                      tandis qu'en mode monochrome, les caractŠres        *
*                      recouverts par l'ombre sont remplac‚s par  '±'      *
*  Variables globales : NbCol/R, Color/R, LigneOfs/R                       *
***************************************************************************}

procedure WinShadow( x1, y1, x2, y2 : byte; BufPtr : VPTR );

var Attribut : byte;   { Attribut … manipuler }
    Ligne,             { Compteur de lignes }
    Colonne,           { Compteur de colonnes }
    DeltaX   : integer;  { Distance … parcourir sur une ligne }

begin
  inc( PTRREC( BufPtr ).Ofs, ( y1 * NbCol + x1 ) shl 1 );  { Charge le pointeur }
  DeltaX := LigneOfs - ( (x2-x1) shl 1 ) - 2;  { Offset de x2 … x1 }

  if ( Color ) then   { Mode couleur ? }
    for Ligne := y1 to y2 do   { Parcourt les lignes }
      begin   { Parcourt les caractŠres d'une ligne }
        for Colonne := x1 to x2 do
          begin
            Attribut := BufPtr^.Attribut;  { Attribut du caractŠre }

            {-- Change la couleur de fond ----------------------------}

            if Attribut and 128 <> 0 then { Fond clair ? }
              Attribut := Attribut and 128  { Oui, modifie le bit 7 }
            else   { Non, fond normal }
              Attribut := Attribut and 15;  { Met un fond sombre }

            {-- Change la couleur du caractŠre ------------------------}

            if Attribut and 8 <> 0 then  { CaractŠre clair ? }
              Attribut := Attribut and (255 - 8); { Oui, modifie le bit 3 }
              BufPtr^.Attribut := Attribut;  { Remet l'attribut dans la m‚moire vid‚o }
            inc( PTRREC(BufPtr).Ofs, 2 );  { Pointe sur le caractŠre suivant }
          end;
        inc( PTRREC(BufPtr).Ofs, DeltaX );  { Pointe sur la ligne suivante}
      end
  else   { Non, mode monochrome }
    for Ligne := y1 to y2 do   { Parcourt les lignes }
      begin    { Parcourt les caractŠres d'une ligne }
        for Colonne := x1 to x2 do
          begin
            BufPtr^.Contenu := ord( '±' ) + ( $7 shl 8 );  { Fixe l'attribut }
            inc( PTRREC(BufPtr).Ofs, 2 );  { Passe au caractŠre suivant }
          end;
        inc( PTRREC(BufPtr).Ofs, DeltaX ); { Passe … la ligne suivante }
      end
end;

{***************************************************************************
*  WinOpenShadow : ouvre une nouvelle fenˆtre et dessine son ombre         *
**------------------------------------------------------------------------**
*  Entr‚es: x1, y1  = Coordonn‚es du coins sup‚rieur gauche                *
*           x2, y2  = Coordonn‚es du coin inf‚rieur droit                  *
*  Information    : - la largeur et la profondeur de l'ombre sont fix‚es   *
*                     par les variables globales ShadowX et ShadowY        *
*                   - les coordonn‚es transmises ne doivent pas inclure    *
*                     l'ombre et doivent ˆtre choisies de telle sorte qu'il*
*                     reste de la place pour dessiner l'ombre sur l'‚cran  *
*                   - en mode couleur, l'ombre est g‚n‚r‚e par modification*
*                     des attributs des caractŠres, tandis qu'en mode      *
*                     monochrome, les caractŠres recouverts par l'ombre    *
*                     sont remplac‚s par  '±'                              *
*  Variables globales : ActWinPTr^/W                                       *
***************************************************************************}

function WinOpenShadow( x1, y1, x2, y2 : byte ) : integer;

var  Handle : integer;   { Num‚ro de la fenˆtre ouverte }

begin
  Handle := WinOpen( x1, y1, x2 + ShadowX, y2 + ShadowY);
  if ( Handle <> WinOpenError ) then
    begin
      ActWinPtr^.Attribut := WIN_OMBRE; { La fenˆtre a une ombre }
      WinSetView( x1, y1, x2, y2 ); { L'ombre est en dehors de la zone de visualisation }
      WinShadow( x2+1, y1+1, x2+ShadowX, y2+ShadowY, VPTR(ptr(VioSeg,0)) );
      WinShadow( x1+ShadowX, y2+1, x2, y2+ShadowY, VPTR(ptr(VioSeg,0)) );
    end;
  WinOpenShadow := Handle; { Renvoie le num‚ro de la fenˆtre }
end;

{$I win2.pas}
{***************************************************************************
*  WinInit : Initialise l'unit‚ Win.                                       *
*  Variables globales : VioCarte/W, NbCol/W, NbLig/W, Color/W, VioSeg/W,   *
*                       HaPtr/W, LigneOfs/W                                *
***************************************************************************}

procedure WinInit;

const VioMode : array [0..11] of byte = ( MDA, CGA, 0, EGA, EGA_MONO, 0,
                                          VGA_MONO,  VGA, 0, MCGA,
                                          MCGA_MONO, MCGA );

      EgaMode : array [0..2] of byte  = ( EGA, EGA, EGA_MONO );

var Regs : Registers;   { Registres du processeur pour les interruptions }

begin
  VioCarte := $ff;    { Pas encore de carte vid‚o d‚tect‚e }

  {-- teste s'il y a une carte VGA ou MCGA ---------------------}

  Regs.ax := $1a00;  { Invoque la fonction 1Ah du BIOS vid‚o }
  intr($10, Regs);   
  if Regs.al = $1a then    { VGA ou MCGA? }
    begin                  { Oui }
      VioCarte := VioMode[ Regs.bl-1 ];  { Cherche le code dans la table }
      Color := not( ( VioCarte = MDA ) or ( VioCarte = EGA_MONO ) );
    end
  else    { Ni VGA ni MCGA }
    begin    { Est-ce de l'EGA ?  }
      Regs.ah := $12;  { Appelle la fonction 12h avec BL=10h }
      Regs.bl := $10;   
      intr($10, Regs);  { dans le BIOS vid‚o }
      if Regs.bl <> $10 then  { EGA ? }
        begin                 { Oui }
          VioCarte := EgaMode[ (Regs.cl shr 1) div 3 ]; { Cherche le code }
          Color := VioCarte <> EGA_MONO;
        end;
    end;

  {-- Fixe le pointeur sur la m‚moire vid‚o -----------------------------}

  Regs.ah := 15;    { Recherche le mode vid‚o actuel }
  intr($10, Regs);  { en apelant une interrution du BIOS vid‚o  }
  if Regs.al = 7 then   { Mode monochrome ? }
    VioSeg := $b000   { Oui, d‚but de m‚moire vid‚o en B000 }
  else                { Non, mode couleur }
    VioSeg := $b800;  { D‚but de m‚moire vid‚o en B800 }

  if VioCarte = $ff then   { ni EGA, ni VGA ni MCGA }
    begin     { Oui }
      if Regs.al = 7 then VioCarte := MDA
                     else VioCarte := CGA;
      NbLig := 25;     { Mode 25 lignes }
      Color := not( ( Regs.al=0 ) or ( Regs.al=2 ) or ( Regs.al=7 ) );
    end
  else     { = EGA, VGA ou MCGA, lit le nombre de lignes ...}
   NbLig := BPTR( Ptr( $40, $84 ) )^ + 1;

  NbCol := BPTR( Ptr( $40, $4a ) )^;  {... et de colonnes }
  LigneOfs := NbCol shl 1;  { D‚placement jusqu'au d‚but de la }
                            { ligne suivante } 

  Regs.ah := 5;    { S‚lectionne la page d'‚cran active }
  Regs.al := 0;    { Page 0 }
  intr($10, Regs); { par l'interruption du BIOS vid‚o }

  Regs.ah := 3;    { Lit la position actuelle du curseur }
  Regs.bh := 0;    { en page 0 }
  intr($10, Regs); { par l'interruption du BIOS vid‚o }
  vLigne  := Regs.dh;   { M‚morise la position du curseur }
  vColonne := Regs.dl;
  WinSetView(0, 0, NbCol-1, NbLig-1);  { Zone de visualisation = }
                                       { la totalit‚ de l'‚cran }
  New( HaPtr );   { R‚serve de la place pour le tableau des num‚ros }
  FillChar( HaPtr^, SizeOf( HaPtr^ ), 0 ); { Initialise le tableau }

  {-- Dirige la variable fichier  OUTPUT vers des routines de sortie         internes -----------}

  with TextRec( Output ) do   { Manipule la variable OUTPUT }
    begin
      Handle   := $FFFF;    { Valeur attendue par Turbo Pascal 
      Mode     := fmClosed; { P‚riph‚rique fern‚ }
      BufSize  := SizeOf( Buffer ); { Fixe la taille et l'adresse  }
      BufPtr   := @Buffer;           { du buffer  }
      OpenFunc := @OutputOpen;  { Adresse de la proc‚dure Open }
      Name[0]  := #0;           { Pas de nom pour le moment }
    end;
  Rewrite( Output );    { Initialise la variable fichier }

  {-- Affichage par Writeln … partir de la position actuelle du curseur --}
  {   en page 0 }
  WritelnX := vColonne;
  WritelnY := vLigne;
  WritelnPtr := GetVioPtr( vColonne, vLigne );

end;
{**--------------------------------------------------------------------**}
{** Ici commence le code de l'unit‚                                    **}
{**--------------------------------------------------------------------**}

begin
  WinInit;       { Invoque la proc‚dure d'initialisation }
end.



