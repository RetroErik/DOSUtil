/*      MMEM.H
 *
 * MIDAS Sound System memory handling routines
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __MEM_H
#define __MEM_H


#ifdef __cplusplus
extern "C" {
#endif



/****************************************************************************\
*
* Function:     int memAlloc(unsigned short len, void **blk);
*
* Description:  Allocates a block of conventional memory
*
* Input:        unsigned short len      Memory block length in bytes
*               void **blk              Pointer to memory block pointer
*
* Returns:      MIDAS error code.
*               Pointer to allocated block stored in *blk, NULL if error.
*
\****************************************************************************/

int CALLING memAlloc(unsigned short len, void **blk);



/****************************************************************************\
*
* Function:     int memFree(void *blk);
*
* Description:  Deallocates a memory block allocated with memAlloc()
*
* Input:        void *blk               Memory block pointer
*
* Returns:      MIDAS error code.
*
\****************************************************************************/

int CALLING memFree(void *blk);




/****************************************************************************\
*       enum memFunctIDs
*       ----------------
* Description:  ID numbers for memory handling functions
\****************************************************************************/

enum memFunctIDs
{
    ID_memAlloc = ID_mem,
    ID_memFree
};




#ifdef __cplusplus
}
#endif

#endif
