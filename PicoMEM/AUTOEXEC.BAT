@Echo off
COLOR BRI YEL ON BLACK
c:\util\ansi.com /q

Set path=c:\;c:\util\;c:\dos;c:\4dos;c:\util\vc\;c:\util\nc\;c:\mTCP\;c:\util\norton
SET ColorDir=dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat: bri red; gif jpg png:yel; txt me now:gre
SET BLASTER=A220 I5 D1 T3
SET ULTRASND=240,1,1,5,5
SET ULTRADIR=c:\ULTRASND
MODE CON RATE=32 DELAY=1
PROMPT $P$g

IF "%CONFIG%"=="EPCONV"  GOTO EUROPC
IF "%CONFIG%"=="EPEMS"   GOTO EUROPC
IF "%CONFIG%"=="386CONV" GOTO AT386
IF "%CONFIG%"=="386EMS"  GOTO AT386
IF "%CONFIG%"=="386XMS"  GOTO AT386
IF "%CONFIG%"=="386UMB"  GOTO AT386
GOTO CDROM

:EUROPC
keyb no,865
ECHO.
c:\util\zeno13.com
ECHO.
astclock /r
ECHO.
c:\util\freespt.com cd
ECHO.
GOTO CDROM

:AT386
c:\util\tmkbvega.com s x
ECHO.
GOTO CDROM

:CDROM
pminit.exe /k /sb 1 /gus 1
ECHO.

IF "%CONFIG%"=="386EMS" LH shsucdx /Q+ /D:PicoCD1 /L:E
IF "%CONFIG%"=="386XMS" shsucdx /Q+ /D:PicoCD1 /L:E
IF "%CONFIG%"=="386UMB" LH shsucdx /Q+ /D:PicoCD1 /L:E
IF "%CONFIG%"=="EPEMS"  shcdx86 /Q+ /D:PicoCD1 /L:E
ECHO.
SET E=%@CHAR[27]
ECHO %E%[1;37mPicoMEM 2%E%[0m - CPU:%_CPU - Free Conv:%E%[1;37m%@DOSMEM[K]KB%E%[0m - Drives: %E%[1;37mC: - %_LASTDISK:%E%[0m - %E%[1;31mR%E%[1;33me%E%[1;32mt%E%[1;36mr%E%[1;35mo %E%[1;34mE%E%[1;31mr%E%[1;33mi%E%[1;32mk%E%[0m
