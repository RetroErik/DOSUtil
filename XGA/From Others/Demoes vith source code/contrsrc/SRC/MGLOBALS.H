/*      MGLOBALS.H
 *
 * MIDAS Sound System global variables
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __MGLOBALS_H
#define __MGLOBALS_H


extern short GLOBALVAR useEMS;          /* should EMS be used? */
extern short GLOBALVAR forceEMS;        /* should _only_ EMS be used? */
extern short GLOBALVAR loadError;       /* module loading error */
extern short GLOBALVAR ALE;             /* should Amiga loops be emulated */
extern short GLOBALVAR ptTempo;         /* should PT modules use tempo */
extern short GLOBALVAR usePanning;      /* should PT modules use cmd 8 for
                                           panning? */
extern short GLOBALVAR surround;        /* should Surround be enabled?
                                           (mainly for GUS)*/
extern short GLOBALVAR realVU;          /* use real VU meters? */

#endif
