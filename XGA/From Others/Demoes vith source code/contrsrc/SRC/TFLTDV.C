/*      TFL-TDV Wired Party 94 Contribution
 *
 * This demo uses the MIDAS Sound System and the PDFIK data file maker
 * Greetz go to the autors of these kool libs ....
 *
 * Copyright 1994 TFL-TDV Crew
 *
 * nb: TFL means -= The FLamoots =-
 *     TDV means -= The Dark Vision =-
 *
 * call our WHQ: -= Pleasure Access BBS =- +32-2-3461996 SysOp: Green Kawa
 * 
 * contact Type One : llardin@is2.vub.ac.be
 * contact MorFlame : 100346.535@compuserve.com
 *
 * C Main written by Type One :-)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <process.h>
#include "midas.h"

#define false 0
#define true 1
typedef struct {                        /* define type used for buffering */ 
        int base;
        int flag;
} screen;                                

screen          page1,page2,page3;                    /* 3 entities */
screen          *StartAdr,*WorkAdr,*NextAdr,*SwapTmp; /* 3 pointers */
int             Triple;                 /* triple buffering flag */

int MichFlag ;

ushort          scrSync;                /* screen synchronization value */
unsigned char   OldMode;                /* Old GFX Mode */
unsigned char   Panning;                /* Panning value */
unsigned char   RealPan;                /* effective Panning value */
int             RealAdr;                /* effective screen Start adr. */
int             FlipOfs;                /* flipping adr. */
int             ShiftOfs;               /* Scroll offset */
unsigned char   FlipPan;                /* flipping panning */
unsigned char   VBFlag;                 /* Flag */
int             LineCounter = 0;

/************ DataBase parameters *************/
long            OfsinDta=0; /*67874; */         /* offset in DataBase (32 bits) */
char            Datafile[]="tfltdv.dat"; /*"tfltdv.exe";*/ /* name of DataBase */

char            ModName[]="darkflam.mod";
char            Docu[] =
"Usage:\tCONTRAST\t[options]\n\n"
"Options:\n"
"\t-sx\tForce Sound Device x (1 = GUS, 2 = PAS, 3 = WSS, 4 = SB,\n"
"\t\t5 = No Sound)\n"
"\t-pxxx\tForce I/O port xxx (hex) for Sound Device\n"
"\t-ix\tForce IRQ x for Sound Device\n"
"\t-dx\tForce DMA channel x for Sound Device\n"
"\t-mxxxxx\tSet mixing rate to xxxxx Hz\n"
"\t-e\tDisable EMS usage\n"
"\t-t\tDisable ProTracker BPM tempos\n"
"\t-u\tEnable Surround\n"
"\t-oxxx\tForce output mode (8 = 8-bit, 1 = 16-bit, s = stereo, m = mono\n"
"\t     \t                   h, n, l = high / normal / low quality)\n"
"\t-wx\t7-Mode parameters (0 = No VGA compatible, 1 = VGA compatible)\n"
"\t-gxx\tnumber of the starting part (1-17)\n";


char            EndText[] =
"You have watched -= CONTRAST =-, our contribution to the WIRED Party 94 \n\n"
"It wouldn't be possible without the work of the following guyz : \n"
"MorFlame, Type One, Bismark, Sam, Fred, Zoltan, Gopi, Green Kawa, Karma \n"
"Special thxx to Youvi for his Robot pic, to Aldo for the OVNI scan :-), \n"
"to NikoPol & NemRod/Channel38 for the 3D objects and for coding ideas !!!!! \n\n"
"If ya want to contact the TFL-TDV crew, just post your mail to : \n"
"llardin@is2.vub.ac.be (Type One) or 100346.535@compuserve.com (MorFlame) \n\n"
"on BBS just try: STARPORT BBS (mail to Type One) \n"
"                              (mail to MorFlame) \n"
"                 GENESIS BBS  (mail to Type One) \n"
"                              (mail to MorFlame) \n"
"                 PA BBS       (mail to Type One) \n"
"                              (mail to MorFlame TDV) \n\n"
"You can reach us via Pleasure Access BBS (our WHQ): +32-2-3461996 \n\n"
"If ya haven't any Net access, just use the Snail Mail : \n"
"Laurent Lardinois (Type One) , 271 ch. de St Job 1180 Bruxelles - Belgium\n";

uchar           vol;
char            oldPIC;                 /* save default int Mask */

/****************************************************************************\
*
* Some globals and externals demos vars/proc
*
\****************************************************************************/

int             SyncFlag;               /* Synchro bit */
int             FrameCounter;           /* screen synchro WORD */
int             ExitDemo;               /* exit demo FLAG */
int             SpaceBar;               /* Space Bar flag */
int             CPUtime;                /* CPU time FLAG */
int             FadeON;                 /* set _TmpPal flag !!! */
int             VGAcompatible;          /* VGA-compatible flag !!! */
unsigned int    NumPart;                /* Num of Part */ 
extern          char TmpPal;            /* tmp-pal */

extern ModulePlayer *MP;                /* current modplayer */
mpInformation       ReplayInfo;         /* playing infos */


/* Prototypes */

extern          void DoSinusTbl(void);  /* calculate a sinus table */
extern          void Amorce(void);      /* init random generator */
extern          int  GetRandom(void);   /* randomizer */
extern          void MCH_Detect(void);  /* VGA+386 Detection */
extern          void WaitVBL(void);     /* Wait VR */

/************** Zake by Fred ***************/

/* Rotative Zoomer - Type One / GFX: Type One */
extern          void StartZoom(int debpos,int debrow,int finpos,int finrow);  

/* bitmap Distorter - Type One / GFX: Zoltan */
extern          void StartDistort(int debpos,int debrow,int finpos,int finrow);

/* single Plasma - Type One / GFX: Type One */
extern          void StartPlasma(int debpos,int debrow,int finpos,int finrow);

/* double Plasma - Type One / GFX: Type One */
extern          void StartDouble(int debpos,int debrow,int finpos,int finrow);

/* bitmap Transformation - Type One / GFX: Zoltan */
extern          void StartTransf(int debpos,int debrow,int finpos,int finrow); 

/* Multi-fire - Type One */
extern          void StartMulFire(int debpos,int debrow,int finpos,int finrow);

/* IceBerg - Waves effect - Type One / GFX: Zoltan */
extern          void StartIce(int debpos,int debrow,int finpos,int finrow);

/* Ik heb een OVNI gezien !!! - Type One / Scan: Aldo */
extern          void StartSnul(int debpos,int debrow,int finpos,int finrow); 

/* Contrast Title - Type One / GFX: Zoltan & Fred */
extern          void StartTitle(int debpos,int debrow,int finpos,int finrow);

/* Elephant - Fred */
extern          void StartEleph(int debpos,int debrow,int finpos,int finrow);

/* Snake - Fred */
extern          void StartSnake(int debpos,int debrow,int finpos,int finrow);

/* Sam 's Part */
extern          void MyPart (int debpos,int debrow,int finpos,int finrow);

/* StarWars scroller - Bismarck */
extern          void StartStar(int debpos,int debrow,int finpos,int finrow);


/* Shade lines - Bismarck */
extern          void StartShade(int debpos,int debrow,int finpos, int finrow);
   
/* Doom Mapping - Morflame / GFX: Zoltan */
extern          void Morflame1(int debpos,int debrow,int finpos,int finrow);

/* eyes effects - Karma */
extern          void KARMA(int debpos,int debrow,int finpos,int finrow); 

/* 3D dots objects - morphing - Gopi */
extern          void GOPI(int debpos,int debrow,int finpos,int finrow); 

extern          void PutWarning(void);       /* Only-ASM - Type One */
extern          void EndWarning(void);       /* Fade it ... - Type One */
extern          void PutANSI(void);          /* Put ANSI PA BBS - Type One */

void preVR(void);
void immVR(void);
void inVR(void);
void brol(void);

/****************************************************************************\
*
*  Main Code : just detect the HardWare, set the delays and call the ASM parts
*
\****************************************************************************/

int main(int argc, char *argv[])
{
    mpModule    *mod;  /* on y trouve le master volume !!! */
    int         error,i;
    char        *p;

    /* argv[0] is the program name , the
       rest are options which MIDAS should handle */

    if (!strcmp(argv[1],"/?")) { 
       puts(Docu); 
       exit(EXIT_SUCCESS);
    } 

    NumPart = 1;        /* Part 1 by default */
    p = argv[0];
    for(i = 1; (i < argc) && p; i++) {
       for(p = argv[i]; (*p) && (*p != 'g'); p++); /* scan for GOTO parameter */
       if (*p) {
          sscanf((p+1),"%u", &NumPart);
          p = NULL;
       }
    }
    if ( (NumPart >17) || (NumPart == 0) ) {    /* exit if wrong param */
       exit(EXIT_SUCCESS);
    }

    VGAcompatible = 0;  /* No VGA-compatible by default */ 
    p = argv[0];
    for(i = 1; (i < argc) && p; i++) {
       for(p = argv[i]; (*p) && (*p != 'w'); p++); /* scan for 7-mode parameters */
       if (*p) {
          if (*(p+1) == '1') VGAcompatible = 1;
          p = NULL;
       }
    }

    MCH_Detect();  /* Check if we have the right CPU/GFX else Exit ... */


    asm {
        mov ah,0fh /* Save the current Video mode */
        int 10h
        mov OldMode,al
        mov ax,13h  /* Set standard mode 13h 320x200x256 chained */ 
        int 10h    
    }    



/*****************************************************************************\
* 
*   Precalculations ......
*
\*****************************************************************************/

    PutWarning();     /* put G.Lagaffe on the screen */
    Amorce();         /* Init Random number generator */
    DoSinusTbl();     /* calculate 1024 sinus*256 (WORD) */

    Panning = 0;      /* Default */
    ShiftOfs = 0;
    RealPan = 0;
    RealAdr = 0;
    VBFlag = 0;
    FlipOfs = 0;
    FlipPan = 0;
    StartAdr = &page1;
    WorkAdr = &page2;
    NextAdr = &page3;
    StartAdr->flag = false;
    StartAdr->base = 0;
    WorkAdr->flag = false;
    NextAdr->flag = false;  
    Triple = false;
    FadeON = false;

    MichFlag = false ;

/*****************************************************************************\
*
*   MIDAS settings ....
*
\*****************************************************************************/

    /* get Timer screen synchronization value: */
    if ( (error = tmrGetScrSync(&scrSync)) != OK )
        midasError(errorMsg[error]);

    midasSetDefaults();                 /* set MIDAS defaults */
    midasParseEnvironment();            /* parse MIDAS environment string */
    midasParseOptions(argc-1, &argv[1]);    /* let MIDAS parse all options */
    midasInit();                        /* initialize MIDAS Sound System */
    mod = midasPlayModule(ModName, 0);  /* load module and start playing */

    /* Synchronize Timer to screen. preVR() will be called before
       Vertical Retrace, immVR() just after Vertical Retrace starts and
       inVR() some time later during Vertical Retrace. */

    FrameCounter = 0;  /* start counter */
    SyncFlag = 0;
    if ( (error = tmrSyncScr(scrSync, &preVR, &immVR, &inVR)) != OK )
        midasError(errorMsg[error]);

/****************************************************************************\
*
* DEMO-Manager : just call the different Pure-ASM parts of the demo !!!!   
*
\****************************************************************************/

    asm {
        cli
        in  al,021h /* get int mask */
        mov oldPIC,al
        or  al,02h  /* mask keyboard int **/
        out 021h,al
        sti 
    }

    /* Fade Off G.Lagaffe */
    EndWarning();

     
    SpaceBar = 0; /* Don't skip the screen by default */
    if (NumPart > 1) SpaceBar = 1; /* skip if we want it !!! */
    
    ExitDemo = 0; /* Don't exit the demo by default !!!! :-) */
    CPUtime = 0;  /* Don't show CPU time by default ... */

    /* allocate some mem for player infos (4 voices) */
    ReplayInfo.chans = (mpChanInfo *)malloc(4*sizeof(mpChanInfo));


    /* Bismarck's SHADELINES */
    if (NumPart == 1) {
       if (SpaceBar) MP->SetPosition(0x00);
       SpaceBar = 0;
       if (!ExitDemo) StartShade(0x00,0x00,0x00,0x02);  
       NumPart++;
    }

    /* CONTRAST title */
    if (NumPart == 2) { 
       if (SpaceBar) MP->SetPosition(0x03);
       SpaceBar = 0;
       if (!ExitDemo) StartTitle(0x03,0x03,0x04,0x3c); 
       NumPart++;
    }

    /* Do the multi-fire effect */
    if (NumPart == 3) {
       if (SpaceBar) MP->SetPosition(0x05);
       SpaceBar = 0;
       if (!ExitDemo)
       {
          FlipOfs = 80;       /* alternate 80 bytes between each VBL */
          FlipPan = 2;        /* alternate 1 pix between each VBL */
          StartMulFire(0x05,0x1a,0x07,0x2e);  /* Type One's fast+small code */
          FlipPan = 0;
          FlipOfs = 0;         
       }
       NumPart++;
    }

    /* Do the rotative Zoom !!!!! */
    if (NumPart == 4) {
       if (SpaceBar) MP->SetPosition(0x09);
       SpaceBar = 0;
       if (!ExitDemo) StartZoom(0x08,0x13,0x11,0x29); /* Type One's fast+small code */
       NumPart++;
    }

    /* Do the bitmap Distort !!!! */
    if (NumPart == 5) { 
       if (SpaceBar) MP->SetPosition(0x12);
       SpaceBar = 0;
       if (!ExitDemo) StartDistort(0x12,0x00,0x15,0x30); /* Type One's fast+small code */
       NumPart++;
    }

    /* Do the double Plasma !!!! */
    if (NumPart == 6) {
       if (SpaceBar) MP->SetPosition(0x16);
       SpaceBar = 0;
       if (!ExitDemo)
       { 
          FlipOfs=80;                  /* alternate 80 bytes between each VBL */
          StartDouble(0x16,0x00,0x18,0x10); /* Type One's fast+small code */
          FlipOfs=0;
       }
       NumPart++;
    }

    /* Sam's Unlimited bobs */
    if (NumPart == 7) {
       if (SpaceBar) MP->SetPosition(0x18);
       SpaceBar = 0;
       if (!ExitDemo) MyPart (0x18,0x3a,0x1e,0x19) ;
       NumPart++;
    }

    /* Put the Elephant pic */
    if (NumPart == 8) {
       if (SpaceBar) MP->SetPosition(0x1f);
       SpaceBar = 0;
       if (!ExitDemo) StartEleph(0x1f,0x14,0x20,0x40);
       NumPart++;
    }

    /* Gopi's Dots objects */
    if (NumPart == 9) {
       if (SpaceBar) MP->SetPosition(0x21);
       SpaceBar = 0;
       if (!ExitDemo) GOPI(0x20,0x56,0x26,0x00);
       NumPart++;
    }

    /* Do the IceBerg (= Waves) effect !!!! */
    if (NumPart == 10) {
       if (SpaceBar) MP->SetPosition(0x28);
       SpaceBar = 0;
       if (!ExitDemo) StartIce(0x28,0x00,0x40,0x30); /* Type One's incredible code */
       NumPart++;
    }

    /* Morflame's Doom mapping */
    if (NumPart == 11) {
       if (SpaceBar) MP->SetPosition(0x42);
       SpaceBar = 0;
       if (!ExitDemo) Morflame1(0x42,0x00,0x48,0x18);
       NumPart++;
    }

    /* Do the Snul Flash !!!! */
    if (NumPart == 12) {
       if (SpaceBar) MP->SetPosition(0x48);
       SpaceBar = 0;
       if (!ExitDemo) StartSnul(0x48,0x28,0x4a,0x04); /* Type One's ridiculous code */
       NumPart++;
    }

    /* Do the single Plasma !!!! */
    if (NumPart == 13) {
       if (SpaceBar) MP->SetPosition(0x4a);
       SpaceBar = 0;
       if (!ExitDemo) StartPlasma(0x4a,0x24,0x4c,0x24); /* Type One's fast+small code */
       NumPart++;
    } 

    /* Do the bitmap Transformation !!!! */
    if (NumPart == 14) {
       if (SpaceBar) MP->SetPosition(0x4d);
       SpaceBar = 0;
       if (!ExitDemo) StartTransf(0x4d,0x02,0x4f,0x0c); /* Type One's fast+small code */
       NumPart++;
    }   

    /* Karma's eyes effects ... */
    if (NumPart == 15) {
       if (SpaceBar) MP->SetPosition(0x50);
       SpaceBar = 0;
       if (!ExitDemo) KARMA(0x4f,0x30,0x52,0x12); 
       NumPart++;
    } 

    /* Put the Snake pic */
    if (NumPart == 16) {
       if (SpaceBar) MP->SetPosition(0x53);
       SpaceBar = 0;
       if (!ExitDemo) StartSnake(0x52,0x36,0x53,0x3f);
       NumPart++;
    }

    /* Bismarck's StarWar scroller */
    if (NumPart == 17) {
       if (SpaceBar) MP->SetPosition(0x55);
       SpaceBar = 0;
       if (!ExitDemo) StartStar(0x55,0x00,0xff,0x00); /* Bismarck's StarWar scroller */
       NumPart++;
    }

    /* Clear Screen in case of .... */
    asm {
        push es
        push di
        push dx
        push cx
        push ax 
        mov  dx,3c4h
        mov  ax,0f02h
        out  dx,ax
        mov  ax,0a000h
        mov  es,ax
        xor  di,di
        cld
        xor  ax,ax
        mov  cx,32768  /* lame 286 asm :-( */
        rep  stosw

        push ds
        pop  es
        xor  ax,ax     /* Black Pal ! */
        mov  di,OFFSET TmpPal
        mov  cx,384
        rep  stosw

        push si
        mov  dx,3c8h
        xor  al,al
        out  dx,al
        inc  dl
        mov  si,OFFSET TmpPal
        mov  cx,768
        rep  outsb
        pop  si

        pop  ax
        pop  cx
        pop  dx
        pop  di
        pop  es
    }
    
    /* Fade master volume */
    for( vol = (mod->masterVol); vol > 0; vol --) {
         WaitVBL();
         WaitVBL();
         MP->SetMasterVolume(vol);      
    }
    WaitVBL();
    WaitVBL();
    MP->SetMasterVolume(0);



/****************************************************************************\
* END of Da little demo :-)
\****************************************************************************/

    /* stop timer screen synchronization: */
    tmrStopScrSync();   

    FlipOfs = 0;
    FlipPan = 0;
    Panning = 8;
    WorkAdr->flag = false;
    StartAdr->base = 0;
    preVR();
    immVR();

    midasStopModule(mod);               /* stop playing */
    midasClose();                       /* uninitialize MIDAS */

    PutANSI();                          /* Put PA BBS Ansi */

    asm {                               /* back to TEXT mode ! */
        cli
        mov al,oldPIC /* restore default int Mask */
        out 021h,al
        sti
        xor ah,ah
        mov al,OldMode
        int 10h
    } 

    puts(EndText);                      /* Contact us !!! */

    return 0;
}


/****************************************************************************\
*
* Function:     void preVR(void)
*
* Description:  Function that is called before Vertical Retrace. Sets the
*               new screen start address
*
\****************************************************************************/

void preVR(void)
{

/*  asm {
    push ax
    push dx
    mov  dx,3c8h
    xor  al,al
    out  dx,al
    inc  dl
    mov  al,63
    out  dx,al
    out  dx,al
    out  dx,al
    pop  dx
    pop  ax
   }
*/


  if (!MichFlag) {

    if (WorkAdr->flag) {           /* if working buffer completed */
       SwapTmp = StartAdr;         /* swap the screen buffers */
       StartAdr = WorkAdr;         /* show our new frame */
       WorkAdr->flag = false;      /* back to false */
       if (Triple) {               /* swap with 3rd buf if triple-buffering */
          WorkAdr = NextAdr;
          NextAdr = SwapTmp;
          NextAdr->flag = false;
       }
       else WorkAdr = SwapTmp;
       SyncFlag = 1;               /* turn on synchro bit */
    }

    RealAdr = StartAdr->base + ShiftOfs;
    if (VBFlag) RealAdr += FlipOfs;/* Calculate effective adr. */

    asm {
      mov dx,3D4h
      mov bx,RealAdr
      mov al,0Ch
      mov ah,bh                    /* MSB of screen start adr. */
      out dx,ax
      inc al
      mov ah,bl                    /* LSB of screen start adr. */
      out dx,ax
    } 

  }

  FrameCounter++;                /* inc the Video synchro counter */
/*
  asm {
    push ax
    push dx
    mov  dx,3c8h
    xor  al,al
    out  dx,al
    inc  dl
    out  dx,al
    out  dx,al
    out  dx,al
    pop  dx
    pop  ax
   }
*/


}



/****************************************************************************\
*
* Function:     void immVR(void)
*
* Description:  Function that is called immediately when Vertical Retrace
*               starts. Sets the new Horizontal Pixel Panning value
*
\****************************************************************************/

void immVR(void)
{

   RealPan = Panning;                  /* calculate effective panning val. */
   if (VBFlag) RealPan = (RealPan + FlipPan) & 7;

   asm {
     mov dx,3C0h
     mov al,33h                        /* New horizontal panning */
     out dx,al
     inc dl
     in  al,dx
     and al,0f8h                       /* 4 bits used */
     or  al,RealPan
     dec dl
     out dx,al
   }

   LineCounter = 0;

}




/****************************************************************************\
*
* Function:     void inVR(void)
*
* Description:  Function that is called some time during Vertical Retrace.
*               Calculates new Horizontal Pixel Panning and screen start
*               address values
*
\****************************************************************************/

void inVR(void)
{

  VBFlag ^= 1;                          /* XOR 1 */

  if(FadeON) {                          /* set new pal ??? */
    asm {
      mov si,OFFSET TmpPal
      mov dx,3c8h
      xor al,al
      out dx,al 
      inc dl
      mov cx,768
      rep outsb
    }
  }

}


