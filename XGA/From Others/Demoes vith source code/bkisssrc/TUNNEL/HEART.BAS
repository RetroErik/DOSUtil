DEFSNG A-Z

CONST Range = 256
CONST DuplicateFactor = 50

RANDOMIZE TIMER

TYPE PointType
X AS SINGLE
Y AS SINGLE
END TYPE

'count the number of points in the file
OPEN "HEART.ASC" FOR INPUT AS #1
NumPoints = 0
DO
    LINE INPUT #1, A$
    X = VAL(MID$(A$, INSTR(A$, "X:") + 3))
    Y = VAL(MID$(A$, INSTR(A$, "Y:") + 3))
    Z = VAL(MID$(A$, INSTR(A$, "Z:") + 3))
    NumPoints = NumPoints + 1
LOOP UNTIL EOF(1)

'allocate memory and load in the points
SEEK #1, 1
DIM Points(1 TO NumPoints) AS PointType
FOR Count = 1 TO NumPoints
    LINE INPUT #1, A$
    Points(Count).X = VAL(MID$(A$, INSTR(A$, "X:") + 3))
    Points(Count).Y = VAL(MID$(A$, INSTR(A$, "Z:") + 3))
NEXT Count
CLOSE #1

'determine the range of the points in the figure
MinX = 32767: MaxX = -32767: MinY = 32767: MaxY = -32767
FOR Count = 1 TO NumPoints
    IF Points(Count).X > MaxX THEN MaxX = Points(Count).X
    IF Points(Count).X < MinX THEN MinX = Points(Count).X
    IF Points(Count).Y > MaxY THEN MaxY = Points(Count).Y
    IF Points(Count).Y < MinY THEN MinY = Points(Count).Y
NEXT Count
NumX = MaxX - MinX: NumY = MaxY - MinY

'scale all of the points so that they're in our desired range
SCREEN 12: CLS : WINDOW SCREEN (-Range, -Range)-(Range, Range)
FOR Count = 1 TO NumPoints
    'get the X and Y coordinates in the range of 0.0 to 1.0
    Points(Count).X = (Points(Count).X - MinX) / NumX
    Points(Count).Y = (Points(Count).Y - MinY) / NumY
    IF (Points(Count).X > 1 OR Points(Count).X < 0) THEN STOP
    IF (Points(Count).Y > 1 OR Points(Count).Y < 0) THEN STOP

    'get the X and Y coordinates in the range of -Range to +Range
    Points(Count).X = (Points(Count).X - .5) * 2 * Range
    Points(Count).Y = -(Points(Count).Y - .5) * 2 * Range

    PSET (Points(Count).X, Points(Count).Y), 15
NEXT Count

'randomly shuffle them
PRINT "Shuffling..."
FOR Count = 1 TO NumPoints ^ 2
    SWAP Points(INT(RND * NumPoints + 1)), Points(INT(RND * NumPoints + 1))
NEXT Count

'write out our computed points
OPEN "HEART.INC" FOR OUTPUT AS #1
PRINT #1, "STRUC Point_Type"
PRINT #1, "X DW ?"
PRINT #1, "Y DW ?"
PRINT #1, "ENDS Point_Type"
PRINT #1,
PRINT #1, "NumDefaultPoints ="; NumPoints
PRINT #1, "LABEL DefaultPoints Point_Type"
Count = 0
FOR X = 1 TO NumPoints
    IF Count = 0 THEN
        PRINT #1, "Point_Type ";
    ELSE
        PRINT #1, ",";
    END IF

    PRINT #1, "<"; LTRIM$(RTRIM$(STR$(CINT(Points(X).X)))); ","; LTRIM$(RTRIM$(STR$(CINT(Points(X).Y)))); ">";
    Count = Count + 1
    IF Count > 4 THEN
        PRINT #1,
        Count = 0
    END IF
NEXT X
CLOSE #1

