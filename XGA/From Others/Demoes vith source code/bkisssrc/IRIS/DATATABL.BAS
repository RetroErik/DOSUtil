DEFSNG A-Z

OPEN "DATATABL.BIN" FOR BINARY AS #1
FOR Y = 0 TO 255
    FOR X = 0 TO 255
        A = COS(.09 * SQR((X - 128) * (X - 128) + (Y - 128) * (Y - 128)))
        B = COS(X / 21)
        C = COS(Y / 26)
        A$ = CHR$(83 * ABS(A + B + C))
        PUT #1, , A$
    NEXT X
    LOCATE , 1: PRINT Y * 100 \ 255; "percent complete...";
NEXT Y
CLOSE #1
PRINT

SYSTEM

