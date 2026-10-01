/****************/
/*** includes ***/
/****************/
#include <stdio.h>
#include <dir.h>
#include <dos.h>
#include <io.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <ctype.h>


#define MAJORVER 1              /* \ version 1.3 */
#define MINORVER 3              /* /             */
#define PROGRAM_VERSION "1.3a"  /* version of library manager */
#define BUFFER_SIZE 4096        /* this defines the temporary buffer size */
#define MAXFILES 200            /* maximum number of files in library */
#define TRUE 1
#define FALSE 0


/******************************************/
/*** macros for defining error messages ***/
/******************************************/
#define ERR_OPEN 1
#define ERR_TEMP 2
#define ERR_LIB_OPEN 3
#define ERR_LIB_BAD 4
#define ERR_LIB_VER 5
#define ERR_NOMEM 6
#define ERR_TOOMANYFILES 7
#define ERR_NOJUNK 8


/*************************************/
/*** values for modes of operation ***/
/*************************************/
#define UNKNOWN -1
#define LIST_FILES 1
#define DIAGNOSTICS 2
#define ADD_FILE 3
#define SUB_FILE 4
#define EXTRACT_FILE 5
#define REMOVE_JUNK 6


/**********************************************/
/*** macros for decoding of file attributes ***/
/**********************************************/
#define ATTR_ARCHIVE(i) (i & 32 ? 'A' : '-')
#define ATTR_READONLY(i) (i & 1 ? 'R' : '-')
#define ATTR_HIDDEN(i) (i & 2 ? 'H' : '-')
#define ATTR_SYSTEM(i) (i & 4 ? 'S' : '-')


/******************/
/*** structures ***/
/******************/
struct header_type {
    char signature[4];
    char majorver, minorver;
    unsigned numfiles;
    unsigned long diroffset;
} JLIB_header;
struct file_info {
    char fileattr;
    struct ftime timedate;
    unsigned long filesize;
    char filename[13];
    unsigned long fileoffset;
} JLIB_directory[MAXFILES];


/*****************/
/*** variables ***/
/*****************/
int mode = UNKNOWN, quietmode = FALSE, swapthem = FALSE;
char *buffer;
char TempName[13] = {"$$JLIB$$.TMP"}, LibName[80], filename[80];
FILE *LibFP, *TempFP;
struct ffblk findfirstblock;
int nextfile, lastfile, getnew, curpos;
unsigned long HeaderOffset;


/******************/
/*** prototypes ***/
/******************/
void list_files(void);
void diagnostics(void);
void add_file(char *filename);
void sub_file(char *filename);
void extract_file(char *filename);
void remove_junk(void);
char *fixfilename (char *filename);
char *shortname (char *filename);
char *pathpart (char *filename);
int get_next_external_name(void);
int get_next_internal_name(void);
void handle_error(int errortype);

//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void main(void)
{
    /******************************/
    /*** print out our greeting ***/
    /******************************/
    printf("JLIB.EXE -- JLib File Manager, v%s\n", PROGRAM_VERSION);
    printf("by  _______  /\n");
    printf("       /    /      ÚÄÄÚ¿  ³ÄÂÄÚÄÄÚÄ¿ÚÄ¿ÚÄ¿oÚÄÄÚÄÄÚÄÄ\n");
    printf("      /    /       ÃÄ ³ÀÄ¿³ ³ ÃÄ ÃÂÙÃÄÙÃÂÙ³ÀÄ¿ÃÄ ÀÄ¿\n");
    printf("/____/    /_____   ÀÄÄ³  ÀÙ ³ ÀÄÄ³ \\³  ³ \\³ÄÄÙÀÄÄÄÄÙ\n\n");


    /*****************************************/
    /*** determine which mode is requested ***/
    /*****************************************/
    if      (_argc >= 3 && strcmp(strupr(_argv[1]), "/V") == 0) mode = LIST_FILES;
    else if (_argc >= 3 && strcmp(strupr(_argv[1]), "/T") == 0) mode = DIAGNOSTICS;
    else if (_argc >= 4 && strcmp(strupr(_argv[1]), "/A") == 0) mode = ADD_FILE;
    else if (_argc >= 4 && strcmp(strupr(_argv[1]), "/D") == 0) mode = SUB_FILE;
    else if (_argc >= 4 && strcmp(strupr(_argv[1]), "/E") == 0) mode = EXTRACT_FILE;
    else if (_argc >= 3 && strcmp(strupr(_argv[1]), "/R") == 0) mode = REMOVE_JUNK;
    if (_argc >= 3) {
        strncpy(LibName, strupr(_argv[2]), 75);
        if (strchr(shortname(LibName), '.') == NULL) strcat(LibName, ".JLB");
    }
    if (_argc >= 4) {
        nextfile = 3; lastfile = _argc;
    } else {
        nextfile = lastfile = 0;
    }
    getnew = TRUE; curpos = 0;


    /*******************************/
    /*** display help, if needed ***/
    /*******************************/
    if (mode == UNKNOWN) {
        printf("syntax:  JLIB /V ®library.JLB¯                  (to view contents)\n");
        printf("         JLIB /T ®library.JLB¯                  (run diagnostics)\n");
        printf("         JLIB /A ®library.JLB¯ ®filename.EXT¯   (to add a file)\n");
        printf("         JLIB /D ®library.JLB¯ ®filename.EXT¯   (to delete file)\n");
        printf("         JLIB /E ®library.JLB¯ ®filename.EXT¯   (to extract file)\n");
        printf("         JLIB /R ®library.JLB¯                  (remove junk data)\n");
        exit(1);
    }


    /*****************************************************/
    /*** open the library and read the file informaion ***/
    /*****************************************************/
    printf("Opening %.12s...", fixfilename(LibName));
    if ((LibFP = fopen(LibName, "rb")) != NULL) {
        int i;

        fseek(LibFP, -1L * sizeof(HeaderOffset), SEEK_END);
        fread(&HeaderOffset, sizeof(HeaderOffset), 1, LibFP);
        HeaderOffset = filelength(fileno(LibFP)) - HeaderOffset;
        fseek(LibFP, HeaderOffset, SEEK_SET);
        fread(&JLIB_header, sizeof(struct header_type), 1, LibFP);
        if (strncmp(JLIB_header.signature, "JLib", 4) != 0) handle_error(ERR_LIB_BAD);
        if (JLIB_header.majorver != MAJORVER || JLIB_header.minorver != MINORVER) handle_error(ERR_LIB_VER);
        fseek(LibFP, HeaderOffset + JLIB_header.diroffset, SEEK_SET);
        for (i = 0; i < JLIB_header.numfiles; i++) {
            fread(&JLIB_directory[i], sizeof(struct file_info), 1, LibFP);
        }
    } else if (mode == ADD_FILE) {
        HeaderOffset = 0;
        if ((LibFP = fopen(LibName, "w+b")) == NULL) handle_error(ERR_LIB_OPEN);
        strncpy(JLIB_header.signature, "JLib", 4);
        JLIB_header.majorver = MAJORVER;
        JLIB_header.minorver = MINORVER;
        JLIB_header.numfiles = 0;
        JLIB_header.diroffset = sizeof(struct header_type);
        fwrite(&JLIB_header, sizeof(struct header_type), 1, LibFP);
    } else {
        printf("\n");
        handle_error(ERR_LIB_OPEN);
    }
    printf("\n");


    /*************************************************************/
    /*** make a temporary file if we're going to modify things ***/
    /*************************************************************/
    if (mode == ADD_FILE || mode == SUB_FILE) {
        unsigned long copysize, blocksize;

        copysize = filelength(fileno(LibFP));
        fseek(LibFP, 0, SEEK_SET);
        if ((TempFP = fopen(TempName, "w+b")) == NULL) handle_error(ERR_TEMP);
        if ((buffer = malloc(BUFFER_SIZE)) == NULL) handle_error(ERR_NOMEM);

        while (copysize) {
            blocksize = (copysize > BUFFER_SIZE ? BUFFER_SIZE : copysize);
            fread(buffer, sizeof(char), blocksize, LibFP);
            fwrite(buffer, sizeof(char), blocksize, TempFP);
            copysize -= blocksize;
        }

        free(buffer);
    }


    /*************************************************************/
    /*** dispatch to the correct code for the specified action ***/
    /*************************************************************/
    switch (mode) {
        case LIST_FILES:
            list_files();
            break;
        case DIAGNOSTICS:
            diagnostics();
            break;
        case ADD_FILE:
            swapthem = TRUE;
            while (get_next_external_name()) add_file(filename);
            break;
        case SUB_FILE:
            swapthem = TRUE;
            while (get_next_internal_name()) {sub_file(filename); curpos--;}
            break;
        case EXTRACT_FILE:
            while (get_next_internal_name()) extract_file(filename);
            break;
        case REMOVE_JUNK:
            remove_junk();
            break;
        default: break;
    }


    /*************************/
    /*** close the library ***/
    /*************************/
    fcloseall();
    if (swapthem) {
        unlink(LibName);
        rename(TempName, LibName);
    } else {
        unlink(TempName);
    }


    /*****************************/
    /*** terminate the program ***/
    /*****************************/
    exit(0);
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void list_files(void)
{
    unsigned i, linecount = 9;
    unsigned long totalsize; 

    printf("Filename     Size       Date       Time     Attr Offset     End\n");
    printf("ÍÍÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍ ÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ\n");
    for (i = 0; i < JLIB_header.numfiles; i++, linecount++) {
        printf("%-12.12s %10lu %02.2i-%02.2i-%04.4i %02.2i:%02.2i:%02.2i %c%c%c%c %10lu %10lu\n",
            JLIB_directory[i].filename, JLIB_directory[i].filesize, JLIB_directory[i].timedate.ft_month,
            JLIB_directory[i].timedate.ft_day, JLIB_directory[i].timedate.ft_year + 1980,
            JLIB_directory[i].timedate.ft_hour, JLIB_directory[i].timedate.ft_min,
            JLIB_directory[i].timedate.ft_tsec * 2, ATTR_ARCHIVE(JLIB_directory[i].fileattr),
            ATTR_READONLY(JLIB_directory[i].fileattr), ATTR_HIDDEN(JLIB_directory[i].fileattr),
            ATTR_SYSTEM(JLIB_directory[i].fileattr), JLIB_directory[i].fileoffset,
            JLIB_directory[i].fileoffset+JLIB_directory[i].filesize-1);
        if (linecount % 22 == 0) {
            printf("\nPress any key to continue listing...");
            if (!getch()) getch();
            printf("\n");
        }
    }
    printf("ÍÍÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍ ÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ ÍÍÍÍÍÍÍÍÍÍ\n");
    if (JLIB_header.numfiles == 0) {
        totalsize = 0;
    } else {
        totalsize = JLIB_directory[JLIB_header.numfiles-1].fileoffset + \
            JLIB_directory[JLIB_header.numfiles-1].filesize - JLIB_header.numfiles * \
            sizeof(struct file_info) - sizeof(struct header_type);
    }
    printf("%12u %10lu\n", JLIB_header.numfiles, totalsize);
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void diagnostics(void)
{
    char buffer[6];
    unsigned i, errorsfound = 0;
    unsigned long reallength, datalength, lastbyte;


    printf("There are %lu bytes stored before start of library.\n", HeaderOffset);
    lastbyte = sizeof(struct header_type) - 1;
    datalength = sizeof(struct header_type) + JLIB_header.numfiles * sizeof(struct file_info);
    for (i = 0; i < JLIB_header.numfiles; i++) {
        if (lastbyte + 1 != JLIB_directory[i].fileoffset) {
            printf("Gap in data between file \"%.12s\" and previous data\n", JLIB_directory[i].filename);
            errorsfound++;
        }
        lastbyte = JLIB_directory[i].fileoffset + JLIB_directory[i].filesize - 1;
        datalength += JLIB_directory[i].filesize;
    }
    datalength += sizeof(HeaderOffset);
    if (lastbyte + 1 != JLIB_header.diroffset) {
        printf("Gap in data between last file and directory information\n");
        errorsfound++;
    }
    reallength = filelength(fileno(LibFP)) - HeaderOffset;
    if (datalength < reallength) {
        printf("Library is %lu bytes longer than expected.\n", reallength - datalength);
        errorsfound++;
    } else if (datalength > reallength) {
        printf("Library is %lu bytes shorter than expected.\n", datalength - reallength);
        errorsfound++;
    }
    printf("%s error%s detected.\n", (errorsfound ? itoa(errorsfound, \
            buffer, 10) : "No"), (errorsfound != 1 ? "s" : ""));
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void add_file(char *filename)
{
    FILE *FP;
    unsigned i;
    char *buffer;
    unsigned long copysize, blocksize, ourlength;


    /***********************************************/
    /*** if the file is already there, update it ***/
    /***********************************************/
    for (i = 0; i < JLIB_header.numfiles; i++) {
        if (strncmp(JLIB_directory[i].filename, fixfilename(filename), 13) == 0) {
            printf("updating %s...", fixfilename(filename));
            quietmode = TRUE;
            sub_file(filename);
            add_file(filename);
            quietmode = FALSE;
            printf("done\n");
            return;
        }
    }


    /************************/
    /*** open up the file ***/
    /************************/
    if (!quietmode) printf("adding %s...", fixfilename(filename));
    if ((FP = fopen(filename, "rb")) == NULL) {
        printf("Error opening file\n", filename);
        return;
    }


    /*******************************************/
    /*** set up a structure for the new file ***/
    /*******************************************/
    i = JLIB_header.numfiles;
    JLIB_header.numfiles++;
    if (JLIB_header.numfiles > MAXFILES) handle_error(ERR_TOOMANYFILES);
    strncpy(JLIB_directory[i].filename, fixfilename(filename), 12);
    JLIB_directory[i].filesize = filelength(fileno(FP));
    JLIB_directory[i].fileattr = 0;
    getftime(fileno(FP), &JLIB_directory[i].timedate);
    if (i != 0) {
        JLIB_directory[i].fileoffset = JLIB_directory[i-1].fileoffset + JLIB_directory[i-1].filesize;
    } else {
        JLIB_directory[i].fileoffset = sizeof(struct header_type);
    }
    JLIB_header.diroffset += JLIB_directory[i].filesize;


    /******************************/
    /*** write out a new header ***/
    /******************************/
    fseek(TempFP, HeaderOffset, SEEK_SET);
    fwrite(&JLIB_header, sizeof(struct header_type), 1, TempFP);


    /*********************************************/
    /*** copy over the data of the file to add ***/
    /*********************************************/
    if ((buffer = malloc(BUFFER_SIZE)) == NULL) handle_error(ERR_NOMEM);
    fseek(TempFP, HeaderOffset+JLIB_directory[i].fileoffset, SEEK_SET);
    copysize = filelength(fileno(FP));
    fseek(FP, 0, SEEK_SET);
    while (copysize) {
        blocksize = (copysize > BUFFER_SIZE ? BUFFER_SIZE : copysize);
        fread(buffer, sizeof(char), blocksize, FP);
        fwrite(buffer, sizeof(char), blocksize, TempFP);
        copysize -= blocksize;
        if (!quietmode) printf(".");
    }
    free(buffer);


    /**********************************************/
    /*** write out the new directory structures ***/
    /**********************************************/
    fseek(TempFP, HeaderOffset+JLIB_header.diroffset, SEEK_SET);
    fwrite(JLIB_directory, sizeof(struct file_info), JLIB_header.numfiles, TempFP);

    
    /****************************************/
    /*** write out our pointer at the end ***/
    /****************************************/
    fseek(TempFP, HeaderOffset+JLIB_header.diroffset + JLIB_header.numfiles * \
            sizeof(struct file_info), SEEK_SET);
    ourlength = sizeof(ourlength) + ftell(TempFP) - HeaderOffset;
    fwrite(&ourlength, sizeof(ourlength), 1, TempFP);
    chsize(fileno(TempFP), ourlength + HeaderOffset);

    fclose(FP);
    if (!quietmode) printf("done\n");
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void sub_file(char *filename)
{
    char *buffer;
    unsigned i, entrynumber, found = FALSE;
    unsigned long copysize, blocksize, sourcepos, targetpos, filesize, ourlength;


    /********************************************/
    /*** check to see if the file is in there ***/
    /********************************************/
    if (!quietmode) printf("deleting %s...", fixfilename(filename));
    for (i = 0; i < JLIB_header.numfiles; i++) {
        if (strncmp(JLIB_directory[i].filename, fixfilename(filename), 13) == 0) {
            found = TRUE;
            entrynumber = i;
            break;
        }
    }
    if (!found) {
        printf("Error--file not in library\n");
        return;
    }


    /******************************/
    /*** write out a new header ***/
    /******************************/
    JLIB_header.numfiles--;
    JLIB_header.diroffset -= JLIB_directory[entrynumber].filesize;
    fseek(TempFP, HeaderOffset, SEEK_SET);
    fwrite(&JLIB_header, sizeof(char), sizeof(struct header_type), TempFP);
    JLIB_header.numfiles++;     /* just for now (we'll fix it later) */


    /*************************************************************/
    /*** figure out how much data after the file must be moved ***/
    /*************************************************************/
    copysize = 0;
    for (i = entrynumber + 1; i < JLIB_header.numfiles; i++) {
        copysize += JLIB_directory[i].filesize;
    }
    sourcepos = HeaderOffset + JLIB_directory[entrynumber+1].fileoffset;
    targetpos = HeaderOffset + JLIB_directory[entrynumber].fileoffset;


    /********************************************/
    /*** move the data after the file forward ***/
    /********************************************/
    if ((buffer = malloc(BUFFER_SIZE)) == NULL) handle_error(ERR_NOMEM);
    while (copysize) {
        blocksize = (copysize > BUFFER_SIZE ? BUFFER_SIZE : copysize);
        fseek(TempFP, sourcepos, SEEK_SET);
        fread(buffer, sizeof(char), blocksize, TempFP);
        fseek(TempFP, targetpos, SEEK_SET);
        fwrite(buffer, sizeof(char), blocksize, TempFP);
        copysize -= blocksize;
        sourcepos += blocksize;
        targetpos += blocksize;
        if (!quietmode) printf(".");
    }
    free(buffer);


    /*************************************************************/
    /*** update our directory structures to reflect the change ***/
    /*************************************************************/
    filesize = JLIB_directory[entrynumber].filesize;
    for (i = entrynumber + 1; i < JLIB_header.numfiles; i++) {
        JLIB_directory[i - 1] = JLIB_directory[i];
        JLIB_directory[i - 1].fileoffset -= filesize;
    }
    JLIB_header.numfiles--;     /* told 'ya I'd change it back */


    /**********************************************/
    /*** write out the new directory structures ***/
    /**********************************************/
    fseek(TempFP, HeaderOffset + JLIB_header.diroffset, SEEK_SET);
    fwrite(JLIB_directory, sizeof(struct file_info), JLIB_header.numfiles, TempFP);


    /********************************************************************/
    /*** write out our pointer at the end and chop off any extra data ***/
    /********************************************************************/
    fseek(TempFP, HeaderOffset+JLIB_header.diroffset + JLIB_header.numfiles * \
            sizeof(struct file_info), SEEK_SET);
    ourlength = sizeof(ourlength) + ftell(TempFP) - HeaderOffset;
    fwrite(&ourlength, sizeof(ourlength), 1, TempFP);
    chsize(fileno(TempFP), ourlength + HeaderOffset);

    if (!quietmode) printf("done\n");
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void extract_file(char *filename)
{
    unsigned i, entrynumber, found = FALSE;
    char *buffer;
    FILE *FP;
    unsigned long copysize, blocksize;


    /********************************************/
    /*** check to see if the file is in there ***/
    /********************************************/
    if (!quietmode) printf("extracting %s...", fixfilename(filename));
    for (i = 0; i < JLIB_header.numfiles; i++) {
        if (strncmp(JLIB_directory[i].filename, fixfilename(filename), 13) == 0) {
            found = TRUE;
            entrynumber = i;
            break;
        }
    }
    if (!found) {
        printf("Error--file not in library\n");
        return;
    }


    /******************************************************/
    /*** open up the output file and write out the data ***/
    /******************************************************/
    if ((buffer = malloc(BUFFER_SIZE)) == NULL) handle_error(ERR_NOMEM);
    if ((FP = fopen(filename, "w+b")) == NULL) {
        printf("Error opening output file.\n");
        return;
    }
    fseek(LibFP, HeaderOffset + JLIB_directory[entrynumber].fileoffset, SEEK_SET);
    copysize = JLIB_directory[entrynumber].filesize;
    while (copysize) {
        blocksize = (copysize > BUFFER_SIZE ? BUFFER_SIZE : copysize);
        fread(buffer, sizeof(char), blocksize, LibFP);
        fwrite(buffer, sizeof(char), blocksize, FP);
        copysize -= blocksize;
        if (!quietmode) printf(".");
    }
    fclose(FP);
    free(buffer);
    if (!quietmode) printf("done\n");
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void remove_junk(void)
{
    char *buffer;
    unsigned long copysize, blocksize;

    if (HeaderOffset == 0) handle_error(ERR_NOJUNK);
    if ((buffer = malloc(BUFFER_SIZE)) == NULL) handle_error(ERR_NOMEM);
    if ((TempFP = fopen(TempName, "w+b")) == NULL) handle_error(ERR_TEMP);
    printf("removing %lu bytes of junk data...", HeaderOffset);
    fseek(LibFP, HeaderOffset, SEEK_SET);
    copysize = filelength(fileno(LibFP)) - HeaderOffset;
    while (copysize) {
        blocksize = (copysize > BUFFER_SIZE ? BUFFER_SIZE : copysize);
        fread(buffer, sizeof(char), blocksize, LibFP);
        fwrite(buffer, sizeof(char), blocksize, TempFP);
        copysize -= blocksize;
        printf(".");
    }
    fclose(LibFP); fclose(TempFP);
    unlink(LibName);
    rename(TempName, LibName);
    free(buffer);
    printf("\n");
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
char *fixfilename (char *filename)
{
    int i, j;
    char *p, buffer[80];

    // chop off the drive or path
    if ((p = strrchr(filename, '\\')) != NULL) {
        strncpy(buffer, strupr(p + 1), 80);
    } else if ((p = strrchr(filename, ':')) != NULL) {
        strncpy(buffer, strupr(p + 1), 80);
    } else {
        strncpy(buffer, strupr(filename), 80);
    }

    // remove any extra letters after astericks
    for (i = 0; i < strlen(buffer); i++) {
        if (buffer[i] == '*') {
            for (j = i + 1; j < strlen(buffer); j++) {
                if (buffer[j] == '.' || buffer[j] == 0) break;
            }
            if (j > i + 1) strcpy(&buffer[i+1], &buffer[j]);
        }
    }

    // make sure there's a period in it
    if ((p = strrchr(buffer, '.')) == NULL) {
        j = '.'; strcat(buffer, (char *) &j);
    }

    // limit the length of the filename to 8.3
    for (i = 0, j = 0; i < strlen(buffer); i++, j++) {
        if (buffer[i] == '.') {
            if (j > 8) strcpy(&buffer[8], &buffer[i]);
            break;
        }
    }
    *(strchr(buffer, '.')+4) = 0;

    return(buffer);
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
char *shortname (char *filename)
{
    char *p;

    if ((p = strrchr(filename, '\\')) != NULL) {
        return(strupr(p + 1));
    } else if ((p = strrchr(filename, ':')) != NULL) {
        return(strupr(p + 1));
    } else {
        return(strupr(filename));
    }
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
char *pathpart (char *filename)
{
    char *p;
    char buffer[80];

    strncpy(buffer, filename, 80);
    if ((p = strrchr(buffer, '\\')) != NULL) {
        *(p+1) = 0;
    } else if ((p = strrchr(filename, ':')) != NULL) {
        *(p+1) = 0;
    } else {
        buffer[0] = 0;
    }
    return(buffer);
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
int get_next_external_name(void)
{
    int done;

    while (TRUE) {
        if (getnew) {
            if (nextfile >= lastfile) return(FALSE);
            done = findfirst(_argv[nextfile], &findfirstblock, 0);
            getnew = FALSE;
        } else {
            done = findnext(&findfirstblock);
        }
        if (done) {
            nextfile++;
            getnew = TRUE;
        } else {
            strcpy(filename, pathpart(_argv[nextfile]));
            strcat(filename, findfirstblock.ff_name);
            if (strncmp(filename, fixfilename(LibName), 13) != 0 &&
                strncmp(filename, TempName, 13) != 0) return(TRUE);
        }
    }
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
int get_next_internal_name(void)
{
    int match, i, pointer1, pointer2;
    char wildcard[13];

    while (TRUE) {
        if (nextfile >= lastfile) return(FALSE);
        for (; curpos < JLIB_header.numfiles; curpos++) {
            strcpy(wildcard, fixfilename(_argv[nextfile]));
            pointer1 = pointer2 = 0; match = UNKNOWN;
            while (match == UNKNOWN && pointer1 <= strlen(wildcard) && \
                    pointer2 <= strlen(JLIB_directory[curpos].filename)) {
                switch (wildcard[pointer1]) {
                    case 0:
                        if (JLIB_directory[curpos].filename[pointer2] == 0) {
                            match = TRUE;
                        } else {
                            match = FALSE;
                        }
                        break;
                    case '*':
                        if (JLIB_directory[curpos].filename[pointer2] == '.' ||
                                JLIB_directory[curpos].filename[pointer2] == 0) {
                            pointer1++;
                        } else {
                            pointer2++;
                        }
                        break;
                    case '?':
                        pointer1++; pointer2++;
                        break;
                    default:
                        if (wildcard[pointer1] != JLIB_directory[curpos].filename[pointer2]) {
                            match = FALSE;
                        } else {
                            pointer1++; pointer2++;
                        }
                        break;
                }
            }
            if (match == TRUE) {
                strcpy(filename, JLIB_directory[curpos].filename);
                curpos++;
                return(TRUE);
            }
        }
        nextfile++; curpos = 0;
    }
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
void handle_error(int errortype)
{
    fcloseall();
    printf("***Error*** ");
    switch (errortype) {
        case ERR_OPEN: printf("Cannot open file\n"); break;
        case ERR_TEMP: printf("Cannot create temporary file\n"); break;
        case ERR_LIB_OPEN: printf("Cannot open library\n"); break;
        case ERR_LIB_BAD: printf("Bad or corrupted library file\n"); break;
        case ERR_LIB_VER: printf("Unknown library version\n"); break;
        case ERR_NOMEM: printf("Insufficient memory\n"); break;
        case ERR_TOOMANYFILES: printf("Too many files in library\n"); break;
        case ERR_NOJUNK: printf("No junk data to remove\n"); break;
        default: printf("Unknown error\n"); break;
    }
    exit(errortype);
}
//°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
