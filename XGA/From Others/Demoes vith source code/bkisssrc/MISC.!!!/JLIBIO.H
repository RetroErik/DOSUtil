#ifndef _JLIBIO_H_
#define _JLIBIO_H_

#define SEEK_START 0
#define SEEK_CUR   1
#define SEEK_END   2

#ifdef __cplusplus
extern "C" {
#endif
/*같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같*/

/* select the active library */
int jlib_open_library (char far *file);

/* disable the use of the current library */
int jlib_close_library (void);

/* 'open' a file contained in the current library */
int jlib_open_file (char far *file);

/* 'close' a file contained in the current library */
int jlib_close_file (int handle);

/* return the current location within a specific 'file' */
long jlib_ftell (int handle);

/* return the total length of a specific 'file' */
long jlib_filelength (int handle);

/* move the read pointer to a specific location */
long jlib_fseek (int handle, long position, char method_code);

/* read a buffer of data from a 'file' */
int jlib_read_file (int handle, char far *buffer, int count);

/*같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같*/
#ifdef __cplusplus
}
#endif

#endif
