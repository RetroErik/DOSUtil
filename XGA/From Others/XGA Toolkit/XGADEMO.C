/*
	XGAKIT package demo program
	This program just demonstrates the use of the XGAKIT routines

	by Bert Tyler of Tyler Software
	CIS ID:  73477,433
	(from Internet/BITNET: 73477.433@compuserve.com)
	
*/

unsigned int intpixels[1024];	/* pixel arrays (can hold a scan line) */
unsigned char pixels[1024];

unsigned char palette[512][3];	/* palette values */

int debug = 0;			/* for my own testing purposes */

main() {
int capabilities, i, j;

/*  so, does this guy really have an XGA adapter? */
if (! (capabilities = xga_detect())) {
	puts("...but you have no XGA adapter\n");
	exit(1);
	}

/* make a fancy palette with 64 shades of red, green, blue, then grey */
/* then double it up to make color-cycling easier */
for (i = 0; i < 256; i++)
	for (j = 0; j < 3; j++)
		palette[i][j] = 0;
for (i = 0; i < 64; i++) {
	j = i << 2;
	palette[i    ][0] = palette[i+64 ][1] = palette[i+128][2] = j; 
	palette[i+192][0] = palette[i+192][1] = palette[i+192][2] = j; 
	}
for (i = 0; i < 256; i++)
	for (j = 0; j < 3; j++)
		palette[i+256][j] = palette[i][j];

/* loop until he chooses option 0 (or presses the ESC key) */
for (;;) {

	system("cls");

	puts("XGAKIT Demo program");
	puts("by Bert Tyler  (CIS ID: 73477,433 - 73477.433@compuserve.com)");
	puts("");

	/* tell the user what his hardware looks like */
	if ((capabilities & 8) == 0)
		puts("\nYou have an XGA adapter with 512K of memory");
	else
		puts("\nYou have an XGA adapter with 1MB of memory");
	if ((capabilities & 4) == 0)
		puts("     It is attached to a low-rez monitor");
	else
		puts("     It is attached to a high-rez monitor");
	if ((capabilities & 2) == 0)
		puts("     The monitor is a monochrome monitor");
	else
		puts("     The monitor is a color monitor");
	if ((capabilities & 16) == 0)
		puts("     The XGA is currently also your VGA adapter");
	else
		puts("     The XGA is part of a dual-monitor setup");

	puts("\n\n What do you want to do?");
	puts("   0 = end this demo");
	puts("   1 = demo 132-column    text     mode");
	puts("   2 = demo 1024x768x256  graphics mode  (a,b)");
	puts("   3 = demo 1024x768x16   graphics mode  (b)");
	puts("   4 = demo 640x480x256   graphics mode");
	puts("   5 = demo 640x480x65536 graphics mode  (a)");
	puts("   6 = demo 800x600x16    graphics mode  (c)");
	puts("   7 = demo 800x600x256   graphics mode  (c)");
/*
        (when I get this one working, I'll get rid of this comment)
	puts("   8 = demo 800x600x65536 graphics mode  (c)");
*/
	puts(" ");
	puts("(a) - requires 1MB of video memory");
	puts("(b) - requires a 1024x768-capable monitor");
	puts("(c) - requires an 800x600-capable monitor");
	puts(" ");

	i = getch();
	j = i - '0';
	switch(i) {
		case '0':
		case 27 :
			exit(0);		/* end-of-program */
			break;
		case '1':
			if ((capabilities & 16) == 0) {
				xga_mode(1);	/* 132-char text mode */
				puts("\n\nThis is the XGA's DOS-compatible 132-column text mode");
				puts("C programs can write to the screen with dull-normal 'printf()' and 'puts()' statements");
				}
			else
				puts("That can only be done on a single-monitor setup\n");
			puts("\n\n Press any key to continue...");
			break;
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
			if (!xga_mode(j)) {	/* graphics modes */
				puts("\n\n Your hardware can't run that mode");
				puts("\n\n Press any key to continue...");
				}
			else	{
				if (j == 2) demoscreen(1024, 768, 256);
				if (j == 3) demoscreen(1024, 768, 16);
				if (j == 4) demoscreen(640,  480, 256);
				if (j == 5) demoscreen(640,  480, -1);
				if (j == 6) demoscreen(800,  600, 16);
				if (j == 7) demoscreen(800,  600, 256);
				if (j == 8) demoscreen(800,  600, -1);
				}
			break;
		/* debugging code leftover from testing this stuff */
		case 'd':
		case 'D':
			debug = 1 - debug;	/* flip-flop debug flag */
			break;
		default :
			break;
		}
/*
	puts("\007");
*/
	getch();
	xga_mode(0);	/* switch back to VGA-compatible text mode */

	/* debugging code leftover from testing this stuff */
	if (debug && j >= 2 && j <= 5) {	/* prove we can read */
		for (i = 0; i < 100; i+= 10)	/*    pixels, too */
		printf(" %d %d %d %d %d %d %d %d %d %d\n",
			intpixels[i+0],intpixels[i+1],intpixels[i+2],
			intpixels[i+3],intpixels[i+4],intpixels[i+5],
			intpixels[i+6],intpixels[i+7],intpixels[i+8],
			intpixels[i+9]);
		getch();
		}

	}

}

demoscreen(int rows, int cols, int colors)
{
unsigned int i, j, k, l, r, g, b;

/* generate a simple image - then, for 16/256 color modes, color-cycle it */
/* exit when a key is pressed */

if (colors > 0) {			/* 16 and 256 color modes */
	xga_setpalette(&palette[16]);		/* set the palette */
	k = 0;
	for (j = 0; j < cols; j++) {	/* generate a test pattern */
		if (++k >= colors) k = 0;
		l = k;
		for (i = 0; i < rows; i++) {
			if (++l >= colors) l = 0;
			pixels[i] = l;
/*
			xga_putpixel(i, j, l);
*/
			}
		xga_putline(j, 0, rows-1, pixels);
		if (kbhit()) {		/* user bail-out */
			break;
			}
		}

/*	testing - cycle the palette until a key is hit */
	i = 16;
	while (kbhit() == 0) {
		if (++i >= 256) i = 0;
		xga_setpalette(&palette[i]);
		}
	}
else	{				/* 65536 "true color" mode */
	g = 0;
	for (j = 0; j < cols; j++) {	/* generate a test pattern */
		if (++g >= 64) g = 0;
		r = 0;
		b = 0;
		if (j >= 256) b = 16;
		for (i = 0; i < rows; i++) {
			if (++r >= 32) {
				r = 0;
				if (++b >= 32) b = 0;
				}
			l = (r << 11) + (g << 5) + b;
			if ((i < 3 || i >= rows-3) ||
			    (j < 3 || j >= cols-3)) 
				l = (31 << 11) + (63 << 5) + 31;
			intpixels[i] = l;
/*
			xga_putpixel(i,j,l);
*/
			}
		xga_putline(j, 0, rows-1, intpixels);
		if (kbhit()) {		/* user bail-out */
			break;
			}
		}

	}

/* read back a row, just for test purposes */
/*
for (i = 0; i < rows; i++)
	intpixels[i] = xga_getpixel(i, 2);
*/
if (colors > 0) {
	xga_getline(2, 0, rows-1, pixels);
	for (i = 0; i < rows; i++)
		intpixels[i] = pixels[i];
	}
else
	xga_getline(2, 0, rows-1, intpixels);

}
