/*      LANG.H
 *
 * Destination language dependent macros and conditional compilation
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __LANG_H
#define __LANG_H


#ifdef __TP__
    #define CALLING pascal
    #define GLOBALVAR pascal
#else
    #define CALLING cdecl
    #define GLOBALVAR
#endif


#endif
