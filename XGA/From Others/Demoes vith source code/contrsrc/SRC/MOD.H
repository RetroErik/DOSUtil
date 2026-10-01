/*      MOD.H
 *
 * ProTracker Module Player, v1.10
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __MOD_H
#define __MOD_H


/****************************************************************************\
*       struct modInstHdr
*       -----------------
* Description:  Protracker module instrument header. Note that all 16-bit
*               fields are big-endian.
\****************************************************************************/

typedef struct
{
    char        iname[22];              /* instrument name */
    ushort      slength;                /* sample length */
    uchar       finetune;               /* sample finetune value */
    uchar       volume;                 /* sample default volume */
    ushort      loopStart;              /* sample loop start, in words */
    ushort      loopLength;             /* sample loop length, in words */
} modInstHdr;



/****************************************************************************\
*       struct modHeader
*       ----------------
* Description:  Protracker module file header
\****************************************************************************/

typedef struct
{
    char        songName[20];           /* song name */
    modInstHdr  instruments[31];        /* instrument headers */
    uchar       songLength;             /* song length */
    uchar       unused;                 /* unused by Protracker, used to be
                                           song restart position */
    uchar       orders[128];            /* pattern playing orders */
    char        sign[4];                /* module signature */
} modHeader;




/****************************************************************************\
*       .MTM stuff. Not used currently
\****************************************************************************/

typedef struct
{
        char    iName[22];
        ulong   sLength;
        ulong   loopStart;
        ulong   loopEnd;
        uchar   fineTune;
        uchar   volume;
        struct  attributes
        {
            int bits : 1;
            int unsused : 7;
        } attr;
} mtmInstHdr;


typedef struct
{
        char        sign[3];
        uchar       version;
        char        sName[20];
        ushort      numTracks;
        uchar       lastPattern;
        uchar       lastOrder;
        ushort      lenComment;
        uchar       numInsts;
        uchar       attribute;
        uchar       beatsPerTrack;
        uchar       amountTracks;
        uchar       panPositions[32];
        mtmInstHdr  instruments[];
} mtmHdr;



/****************************************************************************\
*       struct modChannel
*       -----------------
* Description:  Protracker Module Player internal channel structure
\****************************************************************************/

typedef struct
{
    uchar   note;
    uchar   inst;
    uchar   cmd;
    uchar   info;
    uchar   comp;

    uchar   sample;
    uchar   volume;

    ushort  period;
    ushort  snote;
    uchar   loff;
    uchar   coff;
    ushort  toperi;
    uchar   notepsp;
    uchar   retrigc;

    uchar   status;

    uchar   vibcmd;
    uchar   vibpos;

    uchar   trecmd;
    uchar   trepos;

    uchar   volbar;
    ushort  playoff;
} modChannel;



extern ModulePlayer mpMOD;              /* Protracker Module Player */



#ifdef __cplusplus
extern "C" {
#endif


/****************************************************************************\
*
* Function:     int modLoadModule(char *fileName, SoundDevice *SD,
*                   mpModule **module);
*
* Description:  Loads a Protracker module into memory
*
* Input:        char *fileName          name of module file to be loaded
*               SoundDevice *SD         Sound Device which will store the
*                                       samples
*               mpModule **module       pointer to variable which will store
*                                       the module pointer.
*
* Returns:      MIDAS error code.
*               Pointer to module structure is stored in *module.
*
\****************************************************************************/

int CALLING modLoadModule(char *fileName, SoundDevice *SD, mpModule **module);



/****************************************************************************\
*
* Function:     int modFreeModule(mpModule *module, SoundDevice *SD);
*
* Description:  Deallocates a Protracker module
*
* Input:        mpModule *module        module to be deallocated
*               SoundDevice *SD         Sound Device that has stored the
*                                       samples
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING modFreeModule(mpModule *module, SoundDevice *sd);


int CALLING modConvertSample(uchar *sample, ushort length);
int CALLING modConvertTrack(void *track, ushort type, ushort *trackLen);

int CALLING modIdentify(uchar *header, int *recognized);
int CALLING modInit(SoundDevice *SD);
int CALLING modClose(void);
int CALLING modPlayModule(mpModule *module, ushort firstSDChannel,
    ushort numSDChannels, ushort loopStart, ushort loopEnd);
int CALLING modStopModule(void);
int CALLING modSetInterrupt(void);
int CALLING modRemoveInterrupt(void);
int CALLING modPlay(void);
int CALLING modSetPosition(ushort pos);
int CALLING modGetInformation(mpInformation *info);



/****************************************************************************\
*       enum modFunctIDs
*       ----------------
* Description:  ID numbers for Protracker Module Player functions
\****************************************************************************/

enum modFunctIDs
{
    ID_modIdentify = ID_mod,
    ID_modInit,
    ID_modClose,
    ID_modLoadModule,
    ID_modFreeModule,
    ID_modPlayModule,
    ID_modStopModule,
    ID_modSetInterrupt,
    ID_modRemoveInterrupt,
    ID_modPlay,
    ID_modSetPosition,
    ID_modGetInformation,
    ID_modConvertSample,
    ID_modConvertTrack
};





#ifdef __cplusplus
}
#endif


#endif
