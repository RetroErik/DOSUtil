/*      MIDAS.H
 *
 * Simple MIDAS Sound System programming interface
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __MIDAS_H
#define __MIDAS_H


/****************************************************************************\
*      MIDAS header files:
\****************************************************************************/

#include "lang.h"
#include "mtypes.h"
#include "errors.h"
#include "mglobals.h"
#include "mmem.h"
#include "file.h"
#include "sdevice.h"
#include "mplayer.h"
#include "s3m.h"
#include "mod.h"
#include "timer.h"
#include "ems.h"
#include "dma.h"
#include "dsm.h"
#include "vu.h"




/****************************************************************************\
*      MIDAS global variables:
\****************************************************************************/

extern SoundDevice GUS;                 /* Gravis UltraSound Sound Device */
extern SoundDevice PAS;                 /* Pro Audio Spectrum Sound Device */
extern SoundDevice WSS;                 /* Windows Sound System Sound Device*/
extern SoundDevice SB;                  /* Sound Blaster Sound Device */
extern SoundDevice NSND;                /* No Sound Sound Device */

#define NUMSDEVICES 5                   /* total number of Sound Devices */
#define NUMMPLAYERS 2                   /* total number of Module Players */

extern ModulePlayer mpS3M;              /* Scream Tracker 3 Module Player */
extern ModulePlayer mpMOD;              /* Pro Tracker Module Player */

extern SoundDevice *SD;                 /* current Sound Device */
extern ModulePlayer *MP;                /* current Module Player */

extern SoundDevice *midasSoundDevices[NUMSDEVICES]; /* pointers to all Sound
                                                       Devices */
        /* pointers to all Module Players: */
extern ModulePlayer *midasModulePlayers[NUMMPLAYERS];

        /* Amiga Loop Emulation flags for Module Players: */
extern short        midasMPALE[NUMMPLAYERS];




/****************************************************************************\
*      MIDAS constants:
\****************************************************************************/



/****************************************************************************\
*      MIDAS global functions from MIDAS.C:
\****************************************************************************/


#ifdef __cplusplus
extern "C" {
#endif


/****************************************************************************\
*
* Function:     void midasError(char *msg)
*
* Description:  Prints a MIDAS error message to stderr and exits to DOS
*
* Input:        char *msg               Pointer to error message string
*
\****************************************************************************/

void midasError(char *msg);




/****************************************************************************\
*
* Function:     void midasUninitError(char *msg)
*
* Description:  Prints an error message to stderr and exits to DOS without
*               uninitializing MIDAS. This function should only be used
*               from midasClose();
*
* Input:        char *msg               Pointer to error message string
*
\****************************************************************************/

void midasUninitError(char *msg);



/****************************************************************************\
*
* Function:     void midasDetectSD(void)
*
* Description:  Attempts to detect a Sound Device. Sets the global variable
*               SD to point to the detected Sound Device or NULL if no
*               Sound Device was detected
*
\****************************************************************************/

void midasDetectSD(void);



/****************************************************************************\
*
* Function:     void midasInit(void)
*
* Description:  Initializes MIDAS Sound System
*
\****************************************************************************/

void midasInit(void);



/****************************************************************************\
*
* Function:     void midasClose(void)
*
* Description:  Uninitializes MIDAS Sound System
*
\****************************************************************************/

void midasClose(void);



/****************************************************************************\
*
* Function:     void midasSetDefaults(void)
*
* Description:  Initializes MIDAS Sound System variables to their default
*               states. MUST be the first MIDAS function to be called.
*
\****************************************************************************/

void midasSetDefaults(void);



/****************************************************************************\
*
* Function:     void midasParseOption(char *option)
*
* Description:  Parses one MIDAS command line option.
*
* Input:        char *option            Command line option string WITHOUT
*                                       the leading '-' or '/'.
*
* Recognized options:
*       -sx     Force Sound Device x (1 = GUS, 2 = PAS, 3 = WSS, 4 = SB,
*               5 = No Sound)
*       -pxxx   Force I/O port xxx (hex) for Sound Device
*       -ix     Force IRQ x for Sound Device
*       -dx     Force DMA channel x for Sound Device
*       -mxxxx  Set mixing rate to xxxx Hz
*       -oxxx   Force output mode (8 = 8-bit, 1 = 16-bit, s = stereo,
*               m = mono)
*       -e      Disable EMS usage
*       -t      Disable ProTracker BPM tempos
*       -u      Enable Surround sound
*       -v      Disable real VU-meters
*
\****************************************************************************/

void midasParseOption(char *option);



/****************************************************************************\
*
* Function:     void midasParseOptions(int optCount, char **options)
*
* Description:  Parses MIDAS command line options and sets MIDAS variables
*               accordingly.
*
* Input:        int optCount            Number of options
*               char **options          Pointer to an array of pointers to
*                                       option strings.
*
* Also '/' is recognized as a option delimiter.
*
\****************************************************************************/

void midasParseOptions(int optCount, char **options);



/****************************************************************************\
*
* Function:     void midasParseEnvironment(void)
*
* Description:  Parses the MIDAS environment string, which has same format
*               as the command line options.
*
\****************************************************************************/

void midasParseEnvironment(void);



/****************************************************************************\
*
* Function:     mpModule *midasPlayModule(char *fileName, int numEffectChns)
*
* Description:  Loads a module into memory, points MP to the correct Module
*               Player and starts playing it.
*
* Input:        char *fileName          Pointer to module file name
*               int numEffectChns       Number of channels to open for sound
*                                       effects.
*
* Returns:      Pointer to module structure. This function can not fail,
*               as it will call midasError() to handle all error cases.
*
* Notes:        The Sound Device channels available for sound effects are the
*               _first_ numEffectChns channels. So, for example, if you use
*               midasPlayModule("TUNE.MOD", 3), you can use channels 0-2 for
*               sound effects.
*
\****************************************************************************/

mpModule *midasPlayModule(char *fileName, int numEffectChns);



/****************************************************************************\
*
* Function:     void midasStopModule(mpModule *module)
*
* Description:  Stops playing a module, deallocates it and uninitializes
*               the Module Player. Also closes _all_ Sound Device channels,
*               including those opened for effects.
*
\****************************************************************************/

void midasStopModule(mpModule *module);



#ifdef __cplusplus
}
#endif


#endif
