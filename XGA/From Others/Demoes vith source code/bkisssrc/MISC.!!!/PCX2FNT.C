/**************************************************************************
 PCX2FNT - by Lee Hamel (Patch), hamell@cx.pdx.edu, *Avalanche* coder
 July 14th, 1993
**************************************************************************/
#if defined(__SMALL__) || defined(__TINY__)
#error Cannot be compiled as small or tiny
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

struct PCXHEAD {
    char    manufacturer;
    char    version;
    char    encoding;
    char    bits_per_pixel;
    int     xmin,ymin;
    int     xmax,ymax;
    int     hres;
    int     vres;
    char    palette[48];
    char    reserved;
    char    colour_planes;
    int     bytes_per_line;
    int     palette_type;
    char    filler[58];
} header;
unsigned int width, depth, bytes, i, i1, i2, i3, charcount = 0;
unsigned char palette[768];
unsigned char charrows, charsinrow[20];
unsigned char buffer[256], charorder[256], xysizes[512], showflag;
FILE *infile, *outfile;
unsigned char *tempptr, *charptr, *rowptr, *picture, *fonts[256];
char pcxfile[20],cfgfile[20],fntfile[20];
/****************************************************************************/
void Read_PCX_Line(unsigned int vidoffset)
{
    unsigned char c, run;
    unsigned int n = 0;

    asm cld
    asm mov         di,[vidoffset]

    do {
        c = fgetc(infile) & 0xff;
        if ((c & 0xc0) == 0xc0) {           /* if it's a run of bytes field */

            run = c & 0x3f;                   /* and off the high bits */
            c = fgetc(infile);                /* get the run byte */
            n += run;                         /* run the byte */
            buffer[c] = 1;
            for (i2 = 0; i2 < run; i2++) *picture++ = c;

            if (showflag) {
                asm mov     ax,0a000h
                asm mov     es,ax
                asm mov     al,[c]
                asm xor     ch,ch
                asm mov     cl,[run]
                asm rep     stosb

            }
        } else {
            n++;
            buffer[c] = 1;
            *picture++ = c;

            if (showflag) {
                asm mov     ax,0a000h
                asm mov     es,ax
                asm mov     al,[c]
                asm stosb
            }
        }
    }
    while (n < bytes);
}
/****************************************************************************/
void Unpack_PCX_File(void)
{
    if ((infile = fopen(pcxfile,"rb")) != NULL) {
        if (fread((char *)&header,1,sizeof(struct PCXHEAD),infile) == sizeof(struct PCXHEAD)) {
            if (header.manufacturer == 0x0a && header.version == 5) {
                if (!fseek(infile,-769L,SEEK_END)) {
                    if (fgetc(infile) == 0x0c && fread(palette,1,768,infile) == 768) {
                        fseek(infile,128L,SEEK_SET);
                        width = header.xmax - header.xmin + 1;
                        depth = header.ymax - header.ymin + 1;
                        bytes = header.bytes_per_line;

                        for (i = 0; i < 768; i++) palette[i] = palette[i] >> 2;

                        if (showflag) {
                            asm mov     ax,0013h
                            asm int     10h
                            asm mov     ax,1012h
                            asm xor     bx,bx
                            asm mov     cx,256
                            asm mov     dx,offset palette
                            asm int     10h
                        }

                        if ((rowptr = picture = (unsigned char *) malloc(64000)) == NULL) {
                            printf("Insufficient memory\n");
                            exit(0);
                        }

                        for (i = 0; i < depth; i++) Read_PCX_Line(i * 320);

                        if (showflag) {
                            asm xor     ax,ax
                            asm int     16h
                            asm mov     ax,0003h
                            asm int     10h
                        }
                    } else {printf("Error reading palette\n"); exit(0);}
                } else {printf("Error seeking to palette\n"); exit(0);}
            } else {printf("Not a 256 color PCX file\n"); exit(0);}
        } else {printf("Error reading %s\n",pcxfile); exit(0);}
        fclose(infile);
    } else {printf("Error opening %s\n",pcxfile); exit(0);}
}
/****************************************************************************/
void Get_CFG_File(char *cfgfile)
{
    char tempstr[80],temp1[5],temp2[5],num[5];
    FILE *fp;

    for (i = 0; i < 512; i++) xysizes[i] = 0;

    i = 0;
    if ((fp = fopen(cfgfile,"rt")) != NULL) {
        do {
            fgets(tempstr,80,fp);
        } while (tempstr[0] == ';' || tempstr[0] == '\n');

        sscanf(tempstr,"%s = %d",tempptr,& charrows);
        fgets(tempstr,80,fp);
        tempptr = strchr(tempstr,'=');
        tempptr += 2;

        for (i = 0; i < charrows; i++) {
            sscanf(tempptr,"%d",& charsinrow[i]);

            while (*tempptr != ' ') tempptr++;
            tempptr++;
        }

        i = 0;
        while (fgets(tempstr,80,fp) != NULL) {
            if (tempstr[0] != ';' && tempstr[0] != '\n') {
                if (sscanf(tempstr,"%s = %s x %s",num,temp1,temp2) != -1) {
                    charorder[i++] = atoi(num);
                    charcount++;
                    xysizes[2*atoi(num) + 0] = atoi(temp1);
                    xysizes[2*atoi(num) + 1] = atoi(temp2);
                }
            }
        }
        fclose(fp);
    } else {
        fcloseall();
        printf("Could not open file %s\n",cfgfile);
        exit(1);
    }
}
/****************************************************************************/
void Dump_Fonts(void)
{
    unsigned int ord = 0, xsize, ysize, highesty;

    for (i = 0; i < charrows; i++) {
        /* reset pointer to UL corner of character row */
        /* +320 to skip over blank row */

        highesty = 0;                       /* longest font initialize */
        rowptr += 320;
        picture = rowptr;

        for (i3 = 0; i3 < charsinrow[i]; i3++) {
            /* UL corner of char */
            charptr = picture;
            xsize = xysizes[charorder[ord]*2];
            ysize = xysizes[(charorder[ord]*2)+1];

            if (ysize > highesty) highesty = ysize;

            tempptr = fonts[charorder[ord]] = \
                    (unsigned char *) malloc((size_t) xsize * ysize);

            for (i1 = 0; i1 < xsize; i1++)    /* X value */ {
                for (i2 = 0; i2 < ysize; i2++)  /* Y value */ {
                    *tempptr++ = *picture;
                    picture += 320;
                }
                picture++;                      /* next column over */
                picture -= 320*ysize;           /* back to top of column */
            }

            ord++;                            /* next char in order */
            picture = charptr + xsize + 1;    /* jump to next UL corner */
        }

        /* Jump to start of next char row */
        rowptr += (320 * highesty);
    }

    i1 = 515;
    for (i = 0; i < 256; i++) {
        xsize = xysizes[i*2];
        ysize = xysizes[(i*2)+1];
        fwrite(&i1, 2, 1, outfile);
        i1 += (xysizes[i * 2] * xysizes[(i * 2) + 1]) + 3;
    }

    for (i = 0; i < 256; i++) {
        xsize = xysizes[i*2];
        ysize = xysizes[(i*2)+1];
        if (xsize == 0 && ysize == 0) {
            fprintf(outfile,"%c%c%c",i,0,0);
        } else {
            fprintf(outfile,"%c%c%c",i,xsize,ysize);
            for (i1 = 0, charptr = fonts[i]; i1 < xsize * ysize; i1++) \
                    fprintf(outfile,"%c",*charptr++);
        }
    }

    for (i = 0; i < charcount; i++) free((unsigned char *) fonts[i]);
}
/****************************************************************************/
void Help(char helptype)
{
    if (helptype == 1) {
        printf("FNT format\n");
        printf("ÄÄÄÄÄÄÄÄÄÄ\n");
        printf("byte 0   - 2  : string signature 'JLF' (for error checking)\n");
        printf("word 3   - 514: offset of all 256 ASCII chars, relative to byte 0\n");
        printf("byte 515 -    : data for the fonts\n");
        printf("                1st byte is the char in the ASCII table\n");
        printf("                2nd byte is the X size (width)\n");
        printf("                3rd byte is the Y size (height)\n");
        printf("                X*Y bytes of the font - saved column by column\n");
        printf("                       top to bottom, left to right\n\n");
        printf("Fonts are expected to be in the following format:\n");
        printf("ÚÄÂÄÂÄÂÄÂÄÂÄÄÂÄÄÄÄ  Note the 0s along the top row and far right column.\n");
        printf("0 0 0 0 0 0 Ä´      This is an example of the pixel placement of an A.\n");
        printf("0 1 1 1 0 0 Ä´      The 1s represent where the different colors are at.\n");
        printf("1 1 1 1 1 0 Ä´      When drawing the fonts, make sure each lettter has a\n");
        printf("1 1 0 1 1 0 Ä´      border along the top side, otherwise the conversion\n");
        printf("1 1 1 1 1 0 Ä´      algorithm will mess up.  Just stack all of your fonts\n");
        printf("1 1 0 1 1 0 Ä´      on top of each other and side by side, save the picture\n");
        printf("1 1 0 1 1 0 Ä´      as a PCX, and you're done!\n");
    } else {
        printf("Usage: pcx2fnt [-FNT] PCXFILE [-SHOW]\n");
        printf("where: -FNT       - show the FNT format\n");
        printf("       PCXFILE    - the PCX file to read (no extension)\n");
        printf("       -SHOW      - show the PCX on the screen\n\n");
        printf("Example call: pcx2fnt fontfile -show\n");
        printf("- This will read the file FONTFILE, show it to the screen, and\n");
        printf("  will read the configuration information from FONTFILE.CFG.\n\n");
        printf("Example FONTFILE.CFG:\n");
        printf("charrows = 4\n");
        printf("charsinrow = 3 4 5 6\n");
        printf("065 = 10 x 10\n\n");
        printf("The program expects 4 rows of fonts with 3 fonts in the 1st row, 4 in the 2nd,\n");
        printf("5 in the 3rd, and 6 in the 4th.  065 represents ASCII char A, and it is a\n");
        printf("10 x 10 bitmap.  The file FONTFILE.FNT will be created.  Use a paint\n");
        printf("program to figure out the pixel count.  The blank border along the top and\n");
        printf("right of each font DOES NOT count as part of the height or width!\n");
    }
    exit(1);
}
/****************************************************************************/
void main(int argc, char *argv[])
{
    printf("PCX2FNT - Converts a PCX pic to FNT format\n");
    printf("    by Patch (hamell@rigel.cs.pdx.edu)    \n");
    printf("ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ\n");

    if (stricmp("-FNT",argv[1]) == 0) Help(1);
    if (argc == 1) Help(0);
    strcpy(pcxfile,argv[1]);
    strcpy(cfgfile,argv[1]);
    strcpy(fntfile,argv[1]);
    strcat(pcxfile,".pcx");
    strcat(cfgfile,".cfg");
    strcat(fntfile,".jlf");
    showflag = (stricmp("-SHOW",argv[2]) == 0);
    printf("PCX file:  %s\n",strupr(pcxfile));
    printf("CFG file:  %s\n",strupr(cfgfile));
    printf("JLF file:  %s\n",strupr(fntfile));
    printf("Show PCX:  %s\n\n",(showflag ? "yes" : "no"));

    printf("Reading config file...\n");
    Get_CFG_File(cfgfile);

    printf("Loading PCX file...\n");
    Unpack_PCX_File();

    printf("Converting...\n");
    if ((outfile = fopen(fntfile,"wb")) == NULL) {printf("Error opening output file.\n"); exit(0); }
    fprintf(outfile,"JLF");
    Dump_Fonts();
    fclose(outfile);

    free((unsigned char *) picture);
    exit(0);
}
/****************************************************************************/
