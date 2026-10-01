/*++

Copyright (c) 1991-1992  Microsoft Corporation

Module Name:

    xga.h

Abstract:

    This module contains the global structures and definitions used
    by the xga driver.

Environment:

    Kernel mode

Revision History:
// *********************************************************
	-Ryan Alswede added High Color modes for XGA-2 and modes for XGA1
	XGA2_MODE_640x480x65536x73Hz
	XGA2_MODE_640x480x65536x60Hz	
	XGA1_MODE_800x600x8x70Hz
	XGA2_MODE_800x600x65536x60Hz	
	XGA2_MODE_800x600x65536x70Hz
	XGA1_MODE_800x600x65536x72Hz
	XGA2_MODE_800x600x65536x77Hz
	XGA2_MODE_1024x768x65536x70Hz
	XGA2_MODE_1024x768x65536x60Hz
	-Removed unsupport or orphaned modes
	-Resized for screen fit 256 Color modes
	
// *********************************************************
--*/

#include "devioctl.h"
#include "miniport.h"

#include "ntddvdeo.h"
#include "video.h"
#include "xga.h"

#if defined(ALLOC_PRAGMA)
#pragma data_seg("PAGE")
#endif

//
// Last slot at which an adapter was found.
//

ULONG XgaSlot = 0;
LONG BusNumber = -1;

//
// This variable determines if we are going to run the XGA with the
// coprocessor (FALSE) or jsut as a banked frame buffer (TRUE);
//

BOOLEAN framebufMode = FALSE;

//
// Mode set tables
//
MODE_REGISTER_DATA_TABLE XGA2_MODE_640x480x65536x73Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x67,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x67,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x55,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x5A,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x07,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x07,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xE8,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEB,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xA0,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x58, 0x3D,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_640x480x65536x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x63,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x63,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x55,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x61,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x0C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x0C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xEA,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEC,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xA0,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x58, 0x24,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x65536x72Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x82,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x82,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6A,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x79,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x6C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x6C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x57,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xC8,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x5D,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x65536x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x83,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x83,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6C,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x7C,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x73,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x73,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x58,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5C,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xC8,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x4F,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x65536x70Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x82,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x82,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6A,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x79,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x6C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x6C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x57,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xC8,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x59,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA1_MODE_800x600x65536x70Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x82,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x82,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6A,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x79,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x6C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x6C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x57,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xC8,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x54, 0x0C,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA1_MODE_800x600x8x70Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x82,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x82,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6A,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x79,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x6C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x6C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x57,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x64,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x54, 0x0C,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x65536x77Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x82,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x82,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6A,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x79,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x6C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x6C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x57,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xC8,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x63,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA1_MODE_640x480x8x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x63,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x63,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x55,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x61,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x0C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x0C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xEA,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEC,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x50,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x54, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_640x480x8x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x63,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x63,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x55,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x61,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x0C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x0C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xEA,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEC,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x50,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x24,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_640x480x8x72Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x67,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x67,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x55,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x5A,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x07,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x07,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xE8,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEB,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x50,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x3D,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x8x56Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x7F,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x7F,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x69,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x72,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x70,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x70,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x58,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5A,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x64,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x47,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0x07,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x8x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x84,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x84,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x6C,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x7C,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x73,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x73,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x58,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x5C,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x64,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x4F,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0x07,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_800x600x8x72Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x81,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x63,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x63,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x81,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x70,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x7F,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x99,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0x57,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0x57,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x99,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0x7C,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x82,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x64,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x63,
INDEX_REG,        0x54, 0x81,
INDEX_REG,        0x50, 0x07,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA1_MODE_640x480x65536x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0x63,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x4F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x4F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0x63,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x54,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x61,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x20,
INDEX_REG,        0x1E, 0x02,
INDEX_REG,        0x20, 0x0C,
INDEX_REG,        0x21, 0x02,
INDEX_REG,        0x22, 0xDF,
INDEX_REG,        0x23, 0x01,
INDEX_REG,        0x24, 0xDF,
INDEX_REG,        0x25, 0x01,
INDEX_REG,        0x26, 0x0C,
INDEX_REG,        0x27, 0x02,
INDEX_REG,        0x28, 0xEA,
INDEX_REG,        0x29, 0x01,
INDEX_REG,        0x2A, 0xEC,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0xA0,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x54, 0x00,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_1024x768x8x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0xA3,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x7F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x7F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0xA3,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x8D,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x9E,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x25,
INDEX_REG,        0x21, 0x03,
INDEX_REG,        0x22, 0xFF,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0xFF,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x25,
INDEX_REG,        0x27, 0x03,
INDEX_REG,        0x28, 0x02,
INDEX_REG,        0x29, 0x03,
INDEX_REG,        0x2A, 0x08,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x80,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x80,
INDEX_REG,        0x54, 0x81,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_1024x768x8x70Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x03,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0xAA,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x7F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x7F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0xAA,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x86,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0xA9,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x2E,
INDEX_REG,        0x21, 0x03,
INDEX_REG,        0x22, 0xFF,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0xFF,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x2e,
INDEX_REG,        0x27, 0x03,
INDEX_REG,        0x28, 0xFF,
INDEX_REG,        0x29, 0x02,
INDEX_REG,        0x2A, 0x07,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x80,
INDEX_REG,        0x44, 0x00,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x03,
INDEX_REG,        0x58, 0x8D,
INDEX_REG,        0x54, 0x81,
INDEX_REG,        0x50, 0x07,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_1024x768x65536x60Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0xA5,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x7F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x7F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0xA5,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x8D,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x9E,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x25,
INDEX_REG,        0x21, 0x03,
INDEX_REG,        0x22, 0xFF,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0xFF,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x25,
INDEX_REG,        0x27, 0x03,
INDEX_REG,        0x28, 0x02,
INDEX_REG,        0x29, 0x03,
INDEX_REG,        0x2A, 0x08,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x00,
INDEX_REG,        0x44, 0x01,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x80,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

MODE_REGISTER_DATA_TABLE XGA2_MODE_1024x768x65536x70Hz[] = {

INT_ENABLE_REG,   0x00, 0x00,
INT_STATUS_REG,   0x00, 0xFF,
OP_MODE_REG,      0x00, 0x04,
INDEX_REG,        0x64, 0x00,
APP_CTL_REG,      0x00, 0x00,
APP_INDEX_REG,    0x00, 0x00,
VMEM_CONTROL_REG, 0x00, 0x00,
MEMACC_MODE_REG,  0x00, 0x04,
INDEX_REG,        0x50, 0x01,
INDEX_REG,        0x50, 0x00,
INDEX_REG,        0x10, 0xA7,
INDEX_REG,        0x11, 0x00,
INDEX_REG,        0x12, 0x7F,
INDEX_REG,        0x13, 0x00,
INDEX_REG,        0x14, 0x7F,
INDEX_REG,        0x15, 0x00,
INDEX_REG,        0x16, 0xA7,
INDEX_REG,        0x17, 0x00,
INDEX_REG,        0x18, 0x88,
INDEX_REG,        0x19, 0x00,
INDEX_REG,        0x1A, 0x99,
INDEX_REG,        0x1B, 0x00,
INDEX_REG,        0x1C, 0x00,
INDEX_REG,        0x1E, 0x00,
INDEX_REG,        0x20, 0x25,
INDEX_REG,        0x21, 0x03,
INDEX_REG,        0x22, 0xFF,
INDEX_REG,        0x23, 0x02,
INDEX_REG,        0x24, 0xFF,
INDEX_REG,        0x25, 0x02,
INDEX_REG,        0x26, 0x25,
INDEX_REG,        0x27, 0x03,
INDEX_REG,        0x28, 0x02,
INDEX_REG,        0x29, 0x03,
INDEX_REG,        0x2A, 0x08,
INDEX_REG,        0x2C, 0xFF,
INDEX_REG,        0x2D, 0xFF,
INDEX_REG,        0x36, 0x00,
INDEX_REG,        0x40, 0x00,
INDEX_REG,        0x41, 0x00,
INDEX_REG,        0x42, 0x00,
INDEX_REG,        0x43, 0x00,
INDEX_REG,        0x44, 0x01,
INDEX_REG,        0x54, 0x01,
INDEX_REG,        0x70, 0x00,
INDEX_REG,        0x51, 0x04,
INDEX_REG,        0x58, 0x8A,
INDEX_REG,        0x54, 0x80,
INDEX_REG,        0x50, 0xC7,
INDEX_REG,        0x55, 0x00,
INDEX_REG,        0x60, 0x00,
INDEX_REG,        0x61, 0x00,
INDEX_REG,        0x62, 0x00,
INDEX_REG,        0x63, 0x00,
INDEX_REG,        0x64, 0xFF,
END_OF_SWITCH
};

//
// Video mode table - Lists the information about each individual mode
//

XGA_VIDEO_MODE XgaModes[] = {
{
	
  XGA1_MODE_640x480x65536x60Hz,   	// Mode setting table for XGA 1
  XGA2_MODE_640x480x65536x60Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      640,                         // X Resolution, in pixels
      480,                         // Y Resolution, in pixels
      1280,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      60,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,                           // Number Blue pixels in DAC
      0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
	
  NULL,							   // Mode setting table for XGA 1
  XGA2_MODE_640x480x65536x73Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      640,                         // X Resolution, in pixels
      480,                         // Y Resolution, in pixels
      1280,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      73,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,                           // Number Blue pixels in DAC
      0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
	
  NULL,  	                // Mode setting table for XGA 1
  XGA2_MODE_800x600x65536x72Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      800,                         // X Resolution, in pixels
      600,                         // Y Resolution, in pixels
      1600,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      72,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   
      0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes             
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
	
  XGA1_MODE_800x600x65536x70Hz,  	// Mode setting table for XGA 1
  XGA2_MODE_800x600x65536x70Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      800,                         // X Resolution, in pixels
      600,                         // Y Resolution, in pixels
      1600,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      70,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   
	  0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes                 
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
	
  NULL,						     // Mode setting table for XGA 1
  XGA2_MODE_800x600x65536x60Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      800,                         // X Resolution, in pixels
      600,                         // Y Resolution, in pixels
      1600,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      60,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   
	  0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes                 
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
}, 
{
	
  NULL,         				// Mode setting table for XGA 1
  XGA2_MODE_1024x768x65536x60Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      1024,                         // X Resolution, in pixels
      768,                         // Y Resolution, in pixels
      2048,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      60,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   						 // Mask for Blue Pixels in non-palette modes
	  0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes                 
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
  NULL,         					// Mode setting table for XGA 1
  XGA2_MODE_1024x768x65536x70Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      1024,                         // X Resolution, in pixels
      768,                         // Y Resolution, in pixels
      2048,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      70,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   						 // Mask for Blue Pixels in non-palette modes
	  0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes                 
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
	
  NULL,							// Mode setting table for XGA 1
  XGA2_MODE_800x600x65536x77Hz,     // Mode setting table for XGA 2
    {
      sizeof(VIDEO_MODE_INFORMATION), // Size of the mode informtion structure
      0,                           // Mode index used in setting the mode
      800,                         // X Resolution, in pixels
      600,                         // Y Resolution, in pixels
      1600,                         // Screen stride, in bytes (distance
                                   // between the start point of two
                                   // consecutive scan lines, in bytes)
      1,                           // Number of video memory planes
      16,                           // Number of bits per plane
      77,                           // Screen Frequency, in Hertz
      320,                         // Horizontal size of screen in millimeters
      240,                         // Vertical size of screen in millimeters
      5,                           // Number Red pixels in DAC
      6,                           // Number Green pixels in DAC
      5,   
	  0xF800,                  // Mask for Red Pixels in non-palette modes
      0x07E0,                  // Mask for Green Pixels in non-palette modes
      0x001F,                  // Mask for Blue Pixels in non-palette modes                 
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS // Mode description flags.
    }
},  
{
  XGA1_MODE_640x480x8x60Hz,
  XGA2_MODE_640x480x8x60Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      640,
      480,
      640,
      1,
      8,
      60,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  NULL,
  XGA2_MODE_640x480x8x72Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      640,
      480,
      640,
      1,
      8,
      72,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  NULL,
  XGA2_MODE_800x600x8x56Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      800,
      600,
      800,
      1,
      8,
      56,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | 
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  NULL,
  XGA2_MODE_800x600x8x60Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      800,
      600,
      800,
      1,
      8,
      60,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  NULL,
  XGA2_MODE_800x600x8x72Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      800,
      600,
      800,
      1,
      8,
      72,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  XGA1_MODE_800x600x8x70Hz,
  NULL,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      800,
      600,
      800,
      1,
      8,
      70,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE
    }
},
{
  NULL,
  XGA2_MODE_1024x768x8x60Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      1024,
      768,
      1024,
      1,
      8,
      60,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE                        
    }
},
{
  NULL,
  XGA2_MODE_1024x768x8x70Hz,
    {
      sizeof(VIDEO_MODE_INFORMATION),
      0,
      1024,
      768,
      1024,
      1,
      8,
      70,
      320,
      240,
      8,
      8,
      8,
      0x00000000,
      0x00000000,
      0x00000000,
      VIDEO_MODE_COLOR | VIDEO_MODE_GRAPHICS | VIDEO_MODE_PALETTE_DRIVEN |
        VIDEO_MODE_MANAGED_PALETTE                        
    }
},
};

ULONG XgaNumModes = (sizeof(XgaModes) / sizeof (XGA_VIDEO_MODE));

//
// Settings for the default color palette.
//

UCHAR colour_default_palette[] = {
    0x00, 0x00, 0x00,
    0x00, 0x00, 0xa8,
    0x00, 0xa8, 0x00,
    0x00, 0xA8, 0xA8,
    0xA8, 0x00, 0x00,
    0xA8, 0x00, 0xa8,
    0xA8, 0x54, 0x00,
    0xA8, 0xA8, 0xA8,
    0x54, 0x54, 0x54,
    0x54, 0x54, 0xfc,
    0x54, 0xfc, 0x54,
    0x54, 0xFC, 0xFC,
    0xFC, 0x54, 0x54,
    0xFC, 0x54, 0xFC,
    0xFC, 0xFC, 0x54,
    0xFC, 0xFC, 0xFC
};


#if defined(ALLOC_PRAGMA)
#pragma data_seg()
#endif
