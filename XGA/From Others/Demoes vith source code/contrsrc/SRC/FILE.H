/*      FILE.H
 *
 * High-level file I/O for MIDAS Sound System
 *
 * Copyright 1994 Petteri Kangaslampi and Jarno Paananen
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/

#ifndef __FILE_H
#define __FILE_H

#include "rawfile.h"


/****************************************************************************\
*       struct fileFile
*       ---------------
* Description:  File state structure
\****************************************************************************/

typedef struct
{
    rfHandle    rf;
} fileFile;




/****************************************************************************\
*       typedef fileHandle
*       ------------------
* Description: High-level file I/O file handle
\****************************************************************************/

typedef fileFile* fileHandle;



/****************************************************************************\
*       enum fileOpenMode
*       -----------------
* Description:  File opening mode. Used by fileOpen()
\****************************************************************************/

enum fileOpenMode
{
    fileOpenRead = 1,                   /* open file for reading */
    fileOpenWrite = 2,                  /* open file for writing */
    fileOpenReadWrite = 3               /* open file for both reading and
                                           writing */
};



/****************************************************************************\
*       enum fileSeekMode
*       -----------------
* Description:  File seeking mode. Used by fileSeek()
\****************************************************************************/

enum fileSeekMode
{
    fileSeekAbsolute = 1,               /* seek to an absolute position from
                                           the beginning of the file */
    fileSeekRelative = 2,               /* seek to a position relative to
                                           current position */
    fileSeekEnd = 3                     /* seek relative to the end of file */
};



#ifdef __cplusplus
extern "C" {
#endif


/****************************************************************************\
*
* Function:     int fileOpen(char *fileName, int openMode, fileHandle *file);
*
* Description:  Opens a file for reading or writing
*
* Input:        char *fileName          name of file
*               int openMode            file opening mode, see enum rfOpenMode
*               fileHandle *file        pointer to file handle
*
* Returns:      MIDAS error code.
*               File handle is stored in *file.
*
\****************************************************************************/

int CALLING fileOpen(char *fileName, int openMode, fileHandle *file);




/****************************************************************************\
*
* Function:     int fileClose(fileHandle file);
*
* Description:  Closes a file opened with fileOpen().
*
* Input:        fileHandle file         handle of an open file
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING fileClose(fileHandle file);




/****************************************************************************\
*
* Function:     int fileGetSize(fileHandle file, long *fileSize);
*
* Description:  Get the size of a file
*
* Input:        fileHandle file         handle of an open file
*               ulong *fileSize         pointer to file size
*
* Returns:      MIDAS error code.
*               File size is stored in *fileSize.
*
\****************************************************************************/

int CALLING fileGetSize(fileHandle file, long *fileSize);




/****************************************************************************\
*
* Function:     int fileRead(fileHandle file, void *buffer, ulong numBytes);
*
* Description:  Reads binary data from a file
*
* Input:        fileHandle file         file handle
*               void *buffer            reading buffer
*               ulong numBytes          number of bytes to read
*
* Returns:      MIDAS error code.
*               Read data is stored in *buffer, which must be large enough
*               for it.
*
\****************************************************************************/

int CALLING fileRead(fileHandle file, void *buffer, ulong numBytes);




/****************************************************************************\
*
* Function:     int fileWrite(fileHandle file, void *buffer, ulong numBytes);
*
* Description:  Writes binary data to a file
*
* Input:        fileHandle file         file handle
*               void *buffer            pointer to data to be written
*               ulong numBytes          number of bytes to write
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING fileWrite(fileHandle file, void *buffer, ulong numBytes);




/****************************************************************************\
*
* Function:     int fileSeek(fileHandle file, long newPosition, int seekMode);
*
* Description:  Seeks to a new position in file. Subsequent reads and writes
*               go to the new position.
*
* Input:        fileHandle file         file handle
*               long newPosition        new file position
*               int seekMode            file seek mode, see enum rfSeekMode
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING fileSeek(fileHandle file, long newPosition, int seekMode);




/****************************************************************************\
*
* Function:     int fileGetPosition(fileHandle file, long *position);
*
* Description:  Reads the current position in a file
*
* Input:        fileHandle file         file handle
*               long *position          pointer to file position
*
* Returns:      MIDAS error code.
*               Current file position is stored in *position.
*
\****************************************************************************/

int CALLING fileGetPosition(fileHandle file, long *position);



#ifdef __cplusplus
}
#endif



/****************************************************************************\
*       enum fileFunctIDs
*       -----------------
* Description:  ID numbers for high-level file I/O functions
\****************************************************************************/

enum fileFunctIDs
{
    ID_fileOpen = ID_file,
    ID_fileClose,
    ID_fileGetSize,
    ID_fileRead,
    ID_fileWrite,
    ID_fileSeek,
    ID_fileGetPosition
};

#endif
