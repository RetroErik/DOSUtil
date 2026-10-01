/*      DMA.H
 *
 * DMA handling routines, v1.10
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __DMA_H
#define __DMA_H



/****************************************************************************\
*       struct dmaBuffer
*       ----------------
* Description:  DMA playing buffer
\****************************************************************************/

typedef struct
{
    ushort      segment;                /* segment of the buffer (offset */
                                        /* must be zero) */
    ulong       address;                /* buffer physical start address */
    ushort      length;                 /* length of buffer, MULTIPLE OF 16 */
    void        *memBlk;                /* internal, used for unallocating */
    short       channel;                /* channel on which the buffer is
                                           being played or -1 */
} dmaBuffer;



/****************************************************************************\
*
* Function:     int dmaAllocBuffer(ushort size, dmaBuffer *buf);
*
* Description:  Allocates a DMA buffer (totally inside a 64K physical page)
*
* Input:        ushort size             size of buffer in bytes
*               dmaBuffer *buf          ptr to buffer structure to be filled
*
* Returns:      MIDAS error code.
*               DMA buffer data is strored in *buf.
*
\****************************************************************************/

int CALLING dmaAllocBuffer(ushort size, dmaBuffer *buf);



/****************************************************************************\
*
* Function:     int dmaFreeBuffer(dmaBuffer *buf);
*
* Description:  Deallocates an allocated DMA buffer
*
* Input:        dmaBuffer *buf          ptr to buffer to be deallocated
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING dmaFreeBuffer(dmaBuffer *buf);



/****************************************************************************\
*
* Function:     int dmaPlayBuffer(dmaBuffer *buf, ushort channel,
*                                 ushort autoInit);
*
* Description:  Plays a DMA buffer
*
* Input:        dmaBuffer *buf          buffer to be player
*               ushort channel          DMA channel number
*               ushort autoInit         use autoinitialization?
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING dmaPlayBuffer(dmaBuffer *buf, ushort channel, ushort autoInit);




/****************************************************************************\
*
* Function:     int dmaStop(ushort channel);
*
* Description:  Stops DMA playing
*
* Input:        ushort channel          DMA channel number
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING dmaStop(ushort channel);



/****************************************************************************\
*
* Function:     int dmaGetPos(dmaBuffer *buf, ushort *pos);
*
* Description:  Gets the DMA playing position
*
* Input:        dmaBuffer *buf          buffer that is being played
*               ushort *pos             pointer to return value
*
* Returns:      MIDAS error code.
*               DMA playing position from the beginning of the buffer,
*               in bytes, is stored in *pos.
*
\****************************************************************************/

int CALLING dmaGetPos(dmaBuffer *buf, ushort *pos);




/****************************************************************************\
*       enum dmaFunctIDs
*       ----------------
* Description:  ID numbers for DMA handling functions
\****************************************************************************/

enum dmaFunctIDs
{
    ID_dmaAllocBuffer = ID_dma,
    ID_dmaFreeBuffer,
    ID_dmaPlayBuffer,
    ID_dmaStop,
    ID_dmaGetPos
};


#endif
