
;/***************************************************************************\
;*	 struct mpChanInfo
;*	 -----------------
;* Description:  Module Player channel info structure
;\***************************************************************************/

mpChanInfo STRUCT
	flags		DB	?	; bits 0-4 - UNDEFINED
					; bit 5 - new note and/or instrument
					; bit 6 - new volume (S3M)
					; bit 7 - command
	note		DB	?	; note number
	instrument	DB	?	; instrument number
	volume		DB	?	; playing volume
	command 	DB	?	; command number
	infobyte	DB	?	; command infobyte
	volumebar	DB	?	; "fake" volume bar
	commandname	DD	?	; pointer to command name string,
					; ASCIIZ
mpChanInfo ENDS



;/***************************************************************************\
;*	 struct mpInformation
;*	 --------------------
;* Description:  Module Player information structure
;\***************************************************************************/

mpInformation STRUCT
	numChannels	DW	?	; number of channels. MUST be set by
					; the routine calling
					; MP->GetInformation()
	setFrame	DW	?	; 1 if "set frame", 0 if not
	speed		DW	?	; playing speed
	BPM		DW	?	; playing BPM tempo
	pos		DW	?	; current playing position
	pattern 	DW	?	; current pattern number
	row		DW	?	; current row number
	loopCnt 	DW	?	; song loop counter
	chans		DD	?	; pointer to channel data structures.
					; MUST be allocated by the routine
					; calling MP->GetInformation()
mpInformation ENDS



;/****************************************************************************
;*	 struct mpInstrument
;*	 -------------------
;* Description:  General instrument structure in memory
;\****************************************************************************

mpInstrument STRUCT
	fileName	DB	13 dup (?)
	iname		DB	32 dup (?)
	sample		DD	?
	lengthh		DW	?
	loopStart	DW	?
	loopEnd 	DW	?
	looping 	DB	?
	volume		DB	?
	c2Rate		DD	?
	finetune	DB	?
	sdInstHandle	DW	?
mpInstrument ENDS



;/****************************************************************************
;*	 struct mpPattern
;*	 ----------------
;* Description:  General pattern structure
;\****************************************************************************

mpPattern STRUCT
	lengthh		DW	?
;	LABEL		data	BYTE
mpPattern ENDS



;/****************************************************************************
;*	 struct mpModule
;*	 ---------------
;* Description:  General Module structure. See MPLAYER.TXT for documentation
;\****************************************************************************

mpModule STRUCT
	ID		DD	?
	IDnum		DW	?
	songName	DB	32 dup (?)
	songLength	DW	?
	numInsts	DW	?
	numPatts	DW	?
	numChans	DW	?
	flags		DW	?
	masterVol	DB	?
	speed		DB	?
	tempo		DB	?
	masterMult	DB	?
	stereo		DB	?
	chanSettings	DB	32 dup (?)
	orders		DD	?
	insts		DD	?
	patterns	DD	?
	pattEMS 	DD	?
	instsUsed	DD	?
mpModule ENDS



;/****************************************************************************
;*	 struct ModulePlayer
;*	 -------------------
;* Description:  Module Player structure
;\****************************************************************************

ModulePlayer STRUCT
	status		DW	?	; status (see enum above)
	updRate 	DW	?	; Play() calling rate, in 100*Hz

	Identify	DD	?
	Init		DD	?
	Close		DD	?

	LoadModule	DD	?
	FreeModule	DD	?

	PlayModule	DD	?
	StopModule	DD	?

	SetInterrupt	DD	?
	RemoveInterrupt DD	?

	Play		DD	?

	SetPosition	DD	?
	GetInformation	DD	?
        SetMasterVolume DD      ?
ModulePlayer ENDS
