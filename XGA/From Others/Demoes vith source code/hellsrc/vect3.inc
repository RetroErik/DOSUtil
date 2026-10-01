extrn   _v0rot0init:near, _v0rot0a:near, _v0rot0b:near

extrn   _v0r0sincosptr:dword, _v0r0perspective:word
extrn   _v0r0srx0:dword, _v0r0sry0:dword, _v0r0srz0:dword
extrn   _v0r0crx0:dword, _v0r0cry0:dword, _v0r0crz0:dword
extrn   _v0r0srx1:dword, _v0r0sry1:dword, _v0r0srz1:dword
extrn   _v0r0crx1:dword, _v0r0cry1:dword, _v0r0crz1:dword
extrn   _v0r0tx:word, _v0r0ty:word, _v0r0tz:word

; raw point buffer:
; 0 - 1dw - number of points
; 2 - [0]{
;   0 - 3dw - X, Y, Z signed coords
; }
;
; perspective adjusted point buffer:
; 0 - 1dw - number of points
; 2 - [0]{
;   0 - 3dw - X, Y, Z signed coords
;   6 - 2dw - pX and pY, perspective adjusted coords
; }

