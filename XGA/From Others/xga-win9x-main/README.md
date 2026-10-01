# xga-win9x
An alternative driver for the IBM XGA-2/Nth Double Edge video cards.

Sorry, no XGA-1 or PS/2 Model 90 planar.

This driver delivers detection of more than 1 MB of VRAM and enables
funky high-color modes.

```
SUPPORTED MODES:
 XGA-2 | Double Edge Modes------
   Resolution  Number   Refresh
   Pixels      Colors   Hz
   -----------------------------
   640x480     256      60
   640x480     65536    60

   800x600     256      60
   800x600     256      72
   800x600     65536    72

   1024x768    16       60
   1024x768    256      60
   1024x768    256      72
   1024x768    256      75
   1024x768*   65536    70

   1280x1024*  256      60
   ------------------------------
              *Requires 2 MB Card
```

KNOWN ISSUES:
Blank Screen Under W95 in MS-DOS Mode:

Create a DOSSTART.BAT in the C:\WINDOWS directory. It contains only one line:
```
mode co80
```

