extrn   _flopenlib:near, _flcloselib:near, _flopenfile:near, _flreadfile:near

; The last byte of the library file is the number of files present in the
; file. There are that many 2 dword arrays preceeding it. The first dword
; of each array is the space padded token for that file, stored in reverse
; byte order so that say a - mov eax,"Name" - will find the token "Name"
; instead of looking for "emaN"... the second dword is the length of the file
; associated with the token. A space padded token like "Me  " would be stored
; as "  eM". These files immediately preceed the arrays in the same order as
; they appear in the arrays.

