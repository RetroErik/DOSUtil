/*      TIMER.H
 *
 * TempoTimer, v1.10
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __TIMER_H
#define __TIMER_H

#ifdef __cplusplus
extern "C" {
#endif


/****************************************************************************\
*
* Function:     int tmrGetScrSync(ushort *scrSync);
*
* Description:  Calculates the screen synchronization value for timer
*
* Input:        ushort *scrSync         pointer to screen synchronization
*                                       value
*
* Returns:      MIDAS error code.
*               Screen syncronization value used with tmrSyncScr() is stored
*               in *scrSync.
*
\****************************************************************************/

int CALLING tmrGetScrSync(ushort *scrSync);




/****************************************************************************\
*
* Function:     int tmrInit(void);
*
* Description:  Initializes TempoTimer.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrInit(void);




/****************************************************************************\
*
* Function:     int tmrClose(void);
*
* Description:  Uninitializes TempoTimer. MUST be called if and ONLY if
*               tmrInit() has been called.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrClose(void);




/****************************************************************************\
*
* Function:     int tmrPlay(void (*play)(), SoundDevice *SD);
*
* Description:  Starts playing music with the timer. Update rate set to 50Hz.
*
* Input:        void (*play)()          Music playing function
*               SoundDevice *SD         Sound Device used for playing
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrPlay(void (*play)(), SoundDevice *SD);




/****************************************************************************\
*
* Function:     int tmrStop(void);
*
* Description:  Stops playing music with the timer.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrStop(void);




/****************************************************************************\
*
* Function:     int tmrSyncScr(ushort sync, void (*preVR)(), void (*immVR)(),
*               void (*inVR)());
*
* Description:  Synchronizes the timer to screen refresh.
*
* Input:        ushort sync             Screen synchronization value returned
*                                       by tmrGetScrSync().
*               void (*preVR)()         Pointer to the routine that will be
*                                       called BEFORE Vertical Retrace
*               void (*immVR)()         Pointer to the routine that will be
*                                       called immediately after Vertical
*                                       Retrace starts
*               void (*inVR)()          Pointer to the routine that will be
*                                       called some time during Vertical
*                                       Retrace
*
* Returns:      MIDAS error code
*
* Notes:        preVR() and immVR() functions must be as short as possible
*               and do nothing else than update counters or set some VGA
*               registers to avoid timer synchronization problems. inVR()
*               can take a longer time and can be used for, for example,
*               setting the palette.
*
\****************************************************************************/

int CALLING tmrSyncScr(ushort sync, void (*preVR)(), void (*immVR)(),
    void (*inVR)());




/****************************************************************************\
*
* Function:     int tmrStopScrSync(void);
*
* Description:  Stops synchronizing the timer to the screen.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrStopScrSync(void);



/****************************************************************************\
*
* Function:     int tmrSetUpdRate(ushort updRate);
*
* Description:  Sets the timer update rate, ie. the rate at which the music
*               playing routine is called
*
* Input:        ushort updRate          updating rate, in 100*Hz (5000=50Hz)
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING tmrSetUpdRate(ushort updRate);


#ifdef __cplusplus
}
#endif


/****************************************************************************\
*       enum tmrFunctIDs
*       ----------------
* Description:  ID numbers for TempoTimer functions
\****************************************************************************/

enum tmrFunctIDs
{
    ID_tmrGetScrSync = ID_tmr,
    ID_tmrInit,
    ID_tmrClose,
    ID_tmrPlay,
    ID_tmrStop,
    ID_tmrSyncScr,
    ID_tmrStopScrSync,
    ID_tmrSetUpdRate
};



#endif
