/*      DSM.H
 *
 * Digital Sound Mixer, v1.11
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __DSM_H
#define __DSM_H


#define VOLLEVELS 33
#define VOLSHIFT 1




/****************************************************************************\
*       struct dsmChannel
*       -----------------
* Description:  DSM channel data
\****************************************************************************/

typedef struct
{
    ushort      pos;                    /* mixing position */
    ushort      posl;                   /* mixing position fraction */
    ulong       rate;                   /* playing rate in Hz */
    ushort      inst;                   /* instrument number */
    uchar       *sample;                /* current sample data */
    uchar       smpType;                /* current sample type */
    uchar       smpPos;                 /* current sample position */
    ushort      slength;                /* current sample length */
    ushort      loopStart;              /* current sample loop start */
    ushort      loopEnd;                /* current sample loop end */
    uchar       looping;                /* 1 if current sample is looping */
    uchar       instChanged;            /* 1 if instrument has been changed
                                           (Amiga Loop Emulation) */
    char        panning;                /* panning information */
    uchar       volume;                 /* playing volume (0-64) */
    uchar       muted;                  /* 1 if channel muted, 0 if not */
    uchar       hasData;                /* 1 if channel has data to be played,
                                           0 if not */
} dsmChannel;



/****************************************************************************\
*       struct dsmInstrument
*       --------------------
* Description:  DSM internal instrument structure
\****************************************************************************/

typedef struct
{
    void        *sample;                /* pointer to sample data */
    uchar       smpType;                /* sample type */
    uchar       smpPos;                 /* sample position. see enum
                                           dsmSmpPos */
    ushort      slength;                /* sample length */
    ushort      loopStart;              /* sample loop start */
    ushort      loopEnd;                /* sample loop end */
    uchar       volume;                 /* default playing volume */
    uchar       looping;                /* 1 if looping sample, 0 if not */
    uchar       inuse;                  /* 1 if sample is in use, 0 if not
                                           (removed using dsmRemInstrument) */
} dsmInstrument;



#ifdef __cplusplus
extern "C" {
#endif



/****************************************************************************\
*      DSM functions. See documentation on Sound Device member functions
\****************************************************************************/

int CALLING dsmInit(ushort mixRate, ushort mode);
int CALLING dsmClose(void);
int CALLING dsmOpenChannels(unsigned channels);
int CALLING dsmCloseChannels(void);
int CALLING dsmGetMixRate(ushort *mixRate);
int CALLING dsmGetMode(ushort *mode);
int CALLING dsmClearChannels(void);
int CALLING dsmMute(int mute);
int CALLING dsmPause(int pause);
int CALLING dsmSetMasterVolume(uchar masterVolume);
int CALLING dsmPlaySound(unsigned channel, ulong rate);
int CALLING dsmStopSound(unsigned channel);
int CALLING dsmSetRate(unsigned channel, ulong rate);
int CALLING dsmGetRate(unsigned channel, ulong *rate);
int CALLING dsmSetVolume(unsigned channel, uchar volume);
int CALLING dsmSetInstrument(unsigned channel, ushort inst);
int CALLING dsmSetPosition(unsigned channel, ushort pos);
int CALLING dsmGetPosition(unsigned channel, ushort *pos);
int CALLING dsmSetPanning(unsigned channel, short panning);
int CALLING dsmGetPanning(unsigned channel, short *panning);
int CALLING dsmMuteChannel(unsigned channel, int mute);
int CALLING dsmAddInstrument(void far *sample, int smpType, ushort length,
                     ushort loopStart, ushort loopEnd, uchar volume,
                     int loop, ushort *instHandle);
int CALLING dsmRemInstrument(ushort inst);
int CALLING dsmSetUpdRate(ushort updRate);
int CALLING dsmPlay(int *callMP);


#ifdef __cplusplus
}
#endif



extern dmaBuffer    dsmBuffer;          /* mixing buffer */
extern ushort       dsmDMAPos;


/****************************************************************************\
*       enum dsmFunctIDs
*       ----------------
* Description:  ID numbers for DSM functions
\****************************************************************************/

enum dsmFunctIDs
{
    ID_dsmInit = ID_dsm,
    ID_dsmClose,
    ID_dsmOpenChannels,
    ID_dsmCloseChannels,
    ID_dsmGetMixRate,
    ID_dsmGetMode,
    ID_dsmClearChannels,
    ID_dsmMute,
    ID_dsmPause,
    ID_dsmSetMasterVolume,
    ID_dsmPlaySound,
    ID_dsmStopSound,
    ID_dsmSetRate,
    ID_dsmGetRate,
    ID_dsmSetVolume,
    ID_dsmSetInstrument,
    ID_dsmSetPosition,
    ID_dsmGetPosition,
    ID_dsmSetPanning,
    ID_dsmGetPanning,
    ID_dsmMuteChannel,
    ID_dsmAddInstrument,
    ID_dsmRemInstrument,
    ID_dsmSetUpdRate,
    ID_dsmPlay,
    ID_dsmMixData
};



#endif
