/*      EMS.H
 *
 * EMS heap manager, v1.10
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#ifndef __EMS_H
#define __EMS_H


struct emsHdl;


/****************************************************************************\
*       struct emsBlock
*       ---------------
* Description:  Allocated EMS block structure
\****************************************************************************/

typedef struct emsBlk
{
    ushort      addr;                   /* address of block inside handle
                                           memory area */
    ushort      bytes;                  /* size of block */
    struct emsBlk   *next;              /* pointer to next block in same
                                           handle */
    struct emsBlk   *prev;              /* pointer to previous block */
    ushort      used;                   /* 1 if used, 0 if not */
    struct emsHdl   *handle;                /* handle of the block */
} emsBlock;




/****************************************************************************\
*       struct emsHandle
*       ----------------
* Description:  One EMS handle consisting of four pages. Used internally by
*               heap manager.
\****************************************************************************/

typedef struct emsHdl
{
    ushort      handle;                 /* EMM handle number */
    emsBlock    *block;                 /* pointer to first block */
    struct emsHdl   *next;              /* pointer to next handle */
    struct emsHdl   *prev;              /* pointer to previous handle */
} emsHandle;



#ifdef __cplusplus
extern "C" {
#endif



/****************************************************************************\
*
* Function:     int emsInit(int *emmOK);
*
* Description:  Initializes EMS heap. Must be called before other EMS heap
*               manager functions.
*
* Input:        int *emmOK              pointer to variable containing EMM
*                                       status
*
* Returns:      MIDAS error code.
*               *emmOK contains 1 if Expanded Memory Manager was found (EMS
*               initialized succesfully) or 0 if not. Note that the lack
*               of Expanded Memory Manager is _not_ an error.
*
\****************************************************************************/

int CALLING emsInit(int *emmOK);



/****************************************************************************\
*
* Function:     int emsClose(void);
*
* Description:  Uninitializes EMS heap freeing all allocated blocks. Must be
*               called before program exits if emsInit() has been called.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsClose(void);



/****************************************************************************\
*
* Function:     int emsAlloc(ushort bytes, emsBlock **ems);
*
* Description:  Allocates an EMS memory block
*
* Input:        ushort bytes            number of bytes to be allocated
*               emsBlock **ems          Pointer to EMS Block pointer
*
* Returns:      MIDAS error code.
*               EMS block pointer stored in *ems, NULL if failure
*
\****************************************************************************/

int CALLING emsAlloc(ushort bytes, emsBlock **ems);



/****************************************************************************\
*
* Function:     int emsFree(emsBlock *ems);
*
* Description:  Deallocates an EMS block allocated with emsAlloc
*
* Input:        emsBlock *ems           pointer to block to be deallocated
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsFree(emsBlock *ems);




/****************************************************************************\
*
* Function:     int emsMap(emsBlock *ems, void **memPtr);
*
* Description:  Maps an EMS block to conventional memory.
*
* Input:        emsBlock *ems           pointer to block to be mapped
*               void **memPtr           pointer to conventional memory ptr
*
* Returns:      MIDAS error code.
*               Pointer to the conventional memory area where the block
*               was mapped is stored in *memPtr, NULL if failure.
*
\****************************************************************************/

int CALLING emsMap(emsBlock *ems, void **memPtr);



/****************************************************************************\
*
* Function:     int emsSave(void);
*
* Description:  Saves the EMS status. To be used by TempoTimer. Can only be
*               called once.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsSave(void);



/****************************************************************************\
*
* Function:     int emsRestore(void);
*
* Description:  Restores EMS status saved with emsSave(). To be used by
*               TempoTimer. Can only be called once.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsRestore(void);




/****************************************************************************\
*
* Function:     int emsAllocPages(emsHandle **emsh);
*
* Description:  Allocates 4 pages of EMS memory to a handle. Used internally
*               by EMS heap manager.
*
* Returns:      MIDAS error code.
*               Pointer to a emsHandle structure for the pages stored in
*               *emsh, NULL if failure.
*
\****************************************************************************/

int CALLING emsAllocPages(emsHandle **emsh);




/****************************************************************************\
*
* Function:     int emsFreePages(emsHandle *handle);
*
* Description:  Deallocates an EMS handle allocated by emsAllocPages(). Used
*               internally by EMS heap manager.
*
* Input:        emsHandle *handle       pointer to handle to be deallocated.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsFreePages(emsHandle *handle);




/****************************************************************************\
*
* Function:     int emsSafe(void);
*
* Description:  Sets the EMS safety flag on so that the EMS heap manager
*               can optimize page mappings. Until emsStopSafe() is restored,
*               no other routine than emsMap() must touch the EMS page
*               mappings
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsSafe(void);



/****************************************************************************\
*
* Function:     int emsStopSafe(void);
*
* Description:  Sets the EMS safety flag off.
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING emsStopSafe(void);




/****************************************************************************\
*       enum emsFunctIDs
*       ----------------
* Description:  ID numbers for EMS Heap Manager functions
\****************************************************************************/

enum emsFunctIDs
{
    ID_emsInit = ID_ems,
    ID_emsClose,
    ID_emsAlloc,
    ID_emsFree,
    ID_emsMap,
    ID_emsSave,
    ID_emsRestore,
    ID_emsAllocPages,
    ID_emsFreePages,
    ID_emsSafe,
    ID_emsStopSafe
};


#ifdef __cplusplus
}
#endif


#endif
