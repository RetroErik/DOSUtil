///////////////////////////////////////////////////////////

 Windows NT display display driver
 Copyright (C) Ryan Alswede, 2024.             framebuf.dll
 ----------------------------------------------------------
 Runstream (R) XGA208 Windows NT display miniport driver
 Copyright (C) UnalZ, 2008.                    xga.sys

//////////////////////////////////////////////////////////

BACKGROUND:
This driver uses UnalZ miniport sys file with a modded version of 
Microsoft's framebuf.dll to show his 65536 modes that Microsoft's 
orginal display driver xga.dll blocks.

This modded framebuf.dll also corrects the wrong color mask in UnalZ 
miniport xga2.sys driver so that the 65536 colors display correctly.

All modes are frame buffered, acceleration not supported.

INSTALL NOTES:
Back up your data.  This is vintage computing and not everything goes
as planned.  Everything should be considered unknown and untested.  

Have Windows NT Service Pack 6 installed and running.

Copy install package to floppy disk or folder.  

Use the Windows NT Have Disk Option to install the display adapter driver.




   

