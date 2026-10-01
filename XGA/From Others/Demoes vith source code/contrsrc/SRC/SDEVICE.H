/*      SDEVICE.H
 *
 * Sound Device definitions
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __SDEVICE_H
#define __SDEVICE_H


#define SMPMAX 65519                    /* max sample length (65536-16 - 1) */
#define MAXINSTS 256                    /* maximum number of instruments */




/****************************************************************************\
*       enum smpTypes
*       -------------
* Description:  Sample types
\****************************************************************************/

enum smpTypes
{
    smpNone = 0,                        /* no sample */
    smp8bit                             /* 8-bit unsigned sample */
};



/****************************************************************************\
*       enum sdPanning
*       --------------
* Description:  Sound Device panning values. Legal values range from
*               panLeft to panRight, in steps of 1, plus panSurround.
*               Surround sound is played from middle if surround is not
*               enabled.
\****************************************************************************/

enum sdPanning
{
    panLeft = -64,                      /* left speaker */
    panMiddle = 0,                      /* middle (both speakers) */
    panRight = 64,                      /* right speaker */
    panSurround = 0x80                  /* surround sound */
};



/****************************************************************************\
*       enum sdSmpPos
*       -------------
* Description:  Sample positions in memory
\****************************************************************************/

enum dsmSmpPos
{
    sdSmpNone = 0,                   /* no sample */
    sdSmpConv,                       /* conventional memory */
    sdSmpEMS                         /* EMS */
};



/****************************************************************************\
*       enum sdStatus
*       -------------
* Description:  SoundDevice status
\****************************************************************************/

enum sdStatus
{
    sdUnInitialized = 0,
    sdOK
};



/****************************************************************************\
*       enum sdMode
*       -----------
* Description:  Possible SoundDevice output modes
\****************************************************************************/

enum sdMode
{
    sdMono = 1,                         /* mono */
    sdStereo = 2,                       /* stereo */

    sd8bit = 4,                         /* 8-bit output */
    sd16bit = 8,                        /* 16-bit output */

    sdLowQ = 16,                        /* low quality mixing */
    sdNormalQ = 32,                     /* normal quality mixing */
    sdHighQ = 64                        /* high quality mixing */
};



/****************************************************************************\
*       struct SoundDevice
*       ------------------
* Description:  SoundDevice structure. See SDEVICE.TXT for documentation
\****************************************************************************/

typedef struct
{
    ushort      tempoPoll;
    ushort      port;
    uchar       IRQ;
    uchar       DMA;
    ushort      status;
    ushort      modes;              /* Possible modes for this SD, see enum */

    char        *ID;                    /* SD ID string */

    int CALLING (far *Detect)(int *result);
    int CALLING (far *Init)(ushort mixRate, ushort mode);
    int CALLING (far *Close)(void);
    int CALLING (far *GetMixRate)(ushort *mixRate);
    int CALLING (far *GetMode)(ushort *mode);
    int CALLING (far *OpenChannels)(unsigned channels);
    int CALLING (far *CloseChannels)(void);
    int CALLING (far *ClearChannels)(void);
    int CALLING (far *Mute)(int mute);
    int CALLING (far *Pause)(int pause);
    int CALLING (far *SetMasterVolume)(uchar masterVolume);
    int CALLING (far *PlaySound)(unsigned channel, ulong rate);
    int CALLING (far *StopSound)(unsigned channel);
    int CALLING (far *SetRate)(unsigned channel, ulong rate);
    int CALLING (far *GetRate)(unsigned channel, ulong *rate);
    int CALLING (far *SetVolume)(unsigned channel, uchar volume);
    int CALLING (far *SetInstrument)(unsigned channel, ushort inst);
    int CALLING (far *SetPosition)(unsigned channel, ushort pos);
    int CALLING (far *GetPosition)(unsigned channel, ushort *pos);
    int CALLING (far *SetPanning)(unsigned channel, short panning);
    int CALLING (far *GetPanning)(unsigned channel, short *panning);
    int CALLING (far *MuteChannel)(unsigned channel, int mute);
    int CALLING (far *AddInstrument)(void far *sample, int smpType,
        ushort length, ushort loopStart, ushort loopEnd, uchar volume,
        int loop, ushort *instHandle);
    int CALLING (far *RemInstrument)(ushort inst);
    int CALLING (far *SetUpdRate)(ushort updRate);
    int CALLING (far *Play)(int *callMP);
} SoundDevice;



#endif
