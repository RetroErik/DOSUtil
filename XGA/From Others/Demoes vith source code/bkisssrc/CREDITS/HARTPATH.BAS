DEFINT A-Z

CONST FontHeight = 23
CONST ScreenWidth = 320 / 4

SCREEN 13

'display the bitmap
OPEN "BIGHEART.TGA" FOR BINARY AS #1
SEEK #1, 19
FOR Attr = 0 TO 255
    Value$ = SPACE$(3)
    GET #1, , Value$
    red& = ASC(MID$(Value$, 3))
    green& = ASC(MID$(Value$, 2))
    blue& = ASC(MID$(Value$, 1))
    'PALETTE Attr, 65536 * blue& + 256 * green& + red&
NEXT Attr
SEEK #1, 19 + 768: A$ = " "
FOR Row = 0 TO 199
    FOR Col = 0 TO 319
        GET #1, , A$
        PSET (Col, Row), ASC(A$)
    NEXT Col
NEXT Row
CLOSE #1

'Main entry loop
OPEN "HARTPATH.INC" FOR OUTPUT AS #1
PRINT #1, "LABEL HeartPath WORD"
Row = 100: OutputCount = 0
FOR Col = 0 TO 319
    PointStatus = -1
    DO
        IF PointStatus <> -1 THEN
            PSET (Col, Row), PointStatus
            PointStatus = -1
        ELSE
            PointStatus = POINT(Col, Row)
            PSET (Col, Row), 15
        END IF

        A$ = INKEY$
        SELECT CASE A$
            CASE CHR$(0) + CHR$(72) 'Up arrow
                IF PointStatus <> -1 THEN
                    PSET (Col, Row), PointStatus
                    PointStatus = -1
                END IF
                Row = Row - 1
            CASE CHR$(0) + CHR$(80) 'Down arrow
                IF PointStatus <> -1 THEN
                    PSET (Col, Row), PointStatus
                    PointStatus = -1
                END IF
                Row = Row + 1
            CASE CHR$(13) 'Enter
                IF PointStatus <> -1 THEN
                    PSET (Col, Row), PointStatus
                    PointStatus = -1
                END IF
                EXIT DO
            CASE ELSE
        END SELECT
    LOOP
    IF OutputCount = 0 THEN
        PRINT #1, "DW ";
    ELSE
        PRINT #1, ",";
    END IF
    PRINT #1, RTRIM$(LTRIM$(STR$((Row - FontHeight) * ScreenWidth)));
    OutputCount = OutputCount + 1
    IF OutputCount >= 15 THEN
        PRINT #1, ""
        OutputCount = 0
    END IF
NEXT Col
CLOSE #1

