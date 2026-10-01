;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
STRUC ParmBlock
        EnvSgmt     DW  0
        CmdTail     DD  0
        FCB_1       DD  0
        FCB_2       DD  0
        ExecAddr    DD  0
        PgmStack    DD  0
ENDS ParmBlock
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
STRUC FCB
        Filename    DB  11 DUP (' ')
        Reserved    DB  5 DUP (0)
ENDS FCB
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
MyParmBlock ParmBlock <>
CommandTail db 0,0Dh
MyFCB_1     FCB <>
MyFCB_2     FCB <>
StackPTR    dd ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;           DS:DX ==> ASCIIZ filename of program to run
;returns:   CARRY set on error
;           AX = error code (on error)
proc        ExecuteProgram
            push es ds
            mov [word cs:StackPTR+0],sp     ;\ save the stack for later
            mov [word cs:StackPTR+2],ss     ;/
            mov ax,4B00h                    ;load and execute program
            mov bx,seg MyParmBlock          ;\
            mov es,bx                       ; > ES:BX ==> parameter block
            mov bx,offset MyParmBlock       ;/
            mov [word MyParmBlock+offset (ParmBlock).EnvSgmt],0
            mov [word MyParmBlock+0+offset (ParmBlock).CmdTail],offset CommandTail
            mov [word MyParmBlock+2+offset (ParmBlock).CmdTail],seg CommandTail
            mov [word MyParmBlock+0+offset (ParmBlock).FCB_1],offset MyFCB_1
            mov [word MyParmBlock+2+offset (ParmBlock).FCB_1],seg MyFCB_1
            mov [word MyParmBlock+0+offset (ParmBlock).FCB_2],offset MyFCB_2
            mov [word MyParmBlock+2+offset (ParmBlock).FCB_2],seg MyFCB_2
            int 21h                         ;call DOS
            mov sp,[word cs:StackPTR+0]     ;\ recover of our
            mov ss,[word cs:StackPTR+2]     ;/ stack pointer
            pop ds es

            ret
endp        ExecuteProgram
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
