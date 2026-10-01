/*      VGATEXT.H
 *
 * VGA text output routines for MIDAS Module Player
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __VGATEXT_H
#define __VGATEXT_H


#ifdef __cplusplus
extern "C" {
#endif

/****************************************************************************\
*
* Function:     void vgaWriteText(int x, int y, char *txt);
*
* Description:  Writes text on the screen
*
* Input:        int x                   X coordinate of string (up-left
*                                       corner is (1,1))
*               int y                   Y coordinate
*               char *txt               pointer to null-terminated text
*                                       string, which may contain also the
*                                       following special characters:
*                                           \xFF - next char is attribute
*                                           \x7F - next char is RLE count for
*                                               the character following it
*
\****************************************************************************/

void CALLING vgaWriteText(int x, int y, char *txt);


/****************************************************************************\
*
* Function:     void vgaWriteStr(int x, int y, char *str, char attr);
*
* Description:  Writes a string on the screen
*
* Input:        int x                   X coordinate of the string
*               int y                   Y coordinate
*               char *str               pointer to a ASCIIZ string
*               char attr               attribute for the string
*               int txtlen              number of characters to be printed on
*                                       screen - padded with spaces
*
\****************************************************************************/

void CALLING vgaWriteStr(int x, int y, char *str, char attr, int txtlen);



/****************************************************************************\
*
* Function:     void vgaWriteByte(int x, int y, uchar byte, char attr);
*
* Description:  Writes a hex byte on the screen
*
* Input:        int x                   X coordinate
*               int y                   Y coordinate
*               uchar byte              byte to be written
*               char attr               attribute for the byte
*
\****************************************************************************/

void CALLING vgaWriteByte(int x, int y, uchar byte, char attr);



/****************************************************************************\
*
* Function:     void vgaDrawMeter(int x, int y, int val, int max, char mchr,
*               char hlattr, char nattr);
*
* Description:  Draws a meter on the screen
*
* Input:        int x                   X coordinate
*               int y                   Y coordinate
*               int val                 meter value
*               int max                 meter max. value (length)
*               char mchr               character used for meter
*               char hlattr             attribute for highlighted characters
*               char nattr              attribute for normal characters
*
\****************************************************************************/

void CALLING vgaDrawMeter(int x, int y, int val, int max, char mchr,
    char hlattr, char nattr);


#ifdef __cplusplus
}
#endif


#endif
