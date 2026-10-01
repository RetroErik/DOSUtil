#*      UHA.MAK
#*
#* Makefile for MIDAS C-language examples
#*
#* Copyright 1994 Petteri Kangaslampi and Jarno Paananen
#*
#* This file is part of the MIDAS Sound System, and may only be
#* used, modified and distributed under the terms of the MIDAS
#* Sound System license, LICENSE.TXT. By continuing to use,
#* modify or distribute this file you indicate that you have
#* read the license and understand and accept it fully.
#*


# Compiler directories:

BCDIR = c:\bc
LIBDIR = $(BCDIR)\lib
# MIDASDIR = c:\wired\source\src 
MIDASDIR =

# Compilers and options:

CC = bcc
CCOPTS = -c -3 -G -ml -I$(BCDIR)\include;$(MIDASDIR)
ASM = tasm
ASMOPTS = -zi -UT310 -ml -m9 -i$(MIDASDIR)
LINK = tlink
LINKOPTS = -c -3 -s  



# MIDASLIB = $(MIDASDIR)\midas.lib
MIDASLIB = midas.lib

c_exp : tfltdv.exe
        touch c_exp


tfltdv.exe : tfltdv.obj $(MIDASLIB)
        $(LINK) $(LINKOPTS) $(LIBDIR)\c0l.obj tfltdv.obj @tflobjs, tfltdv, , $(LIBDIR)\cl.lib $(MIDASLIB)

tfltdv.obj : tfltdv.c
        $(CC) $(CCOPTS) tfltdv.c

