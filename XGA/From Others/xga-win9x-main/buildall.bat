@echo off
c:\windows\command\doskey
REM call C:\DDK\Ddkenv.bat 32 net
set sdkroot=C:\MSTOOLS
set ddkroot=C:\DDK
set MASM_ROOT=C:\MASM611
set C16_ROOT=C:\MSVC
set C32_ROOT=C:\MSVC20
set WIN16=
set include=%ddkroot%\%2\inc;%ddkroot%\inc32;%sdkroot%\include;%_include%;%ddkroot%\inc16;%sdkroot%\inc16
set lib=%ddkroot%\lib;%sdkroot%\lib;%_lib%
path=%ddkroot%\%2\bin;%ddkroot%\bin;%sdkroot%\bin;%_path%
set PATH=C:\MSVC20\BIN;%PATH%
set INCLUDE=C:\MSVC20\INCLUDE;C:\MSVC20\MFC\INCLUDE;%INCLUDE%
set LIB=C:\MSVC20\LIB;C:\MSVC20\MFC\LIB;%LIB%
SET PATH=C:\MASM611\BIN;%PATH%
SET LIB=C:\MASM611\LIB
SET INCLUDE=C:\MASM611\INCLUDE
SET INIT=C:\MASM611\INIT
SET HELPFILES=C:\MASM611\HELP\*.HLP
mkdir C:\MASM611\TMP
SET TMP=C:\MASM611\TMP
set MASTER_MAKE=1
set DDKROOT=c:\ddk

@echo on

cd mini
nmake clean
nmake
pause
copy *.drv ..
cd ..

cd vdd
nmake clean
nmake
copy *.vxd ..
cd ..

pause
