program lissajous3 ;

    uses crt , graph ;

    const maxx = 320-48 ; { les - = taille du sprite }
          maxy = 200-48 ;
          maxcompt = 500 ; { 1000 }
          increment = 0.0174 ; { 0.0174 }

    var pilotegr , modegr: integer ;
        x , y : longint ;
        i : word ;
        incr : real ;
        f : text ;
        dummy : char ;

begin
    assign (f,'lissajo3.dat') ;
    rewrite (f) ;
    pilotegr := CGA ; { hahahahah 320*200 4 couleurs !!! }
    modegr := CGAC1 ;
    initgraph (pilotegr,modegr,'c:\tp') ;
    incr := 0.0 ;
    for i := 0 to maxcompt do
    begin
        x := (maxx div 2) + trunc (cos (5*incr/maxcompt*360)*(maxx div 2))  ;
        y := (maxy div 2) + trunc (sin (4*incr/maxcompt*360)*(maxy div 2))  ;
        putpixel (x,y,i mod 4) ;
        delay (1) ;
        incr := incr + increment ;
        writeln (f,'dw ',((y-1)*320) + (x-1))  ;
    end ;
    directvideo := false ;
    writeln ('Strike ESC key when ready !!!') ;
    dummy := readkey ;
    if dummy = #0 then
         dummy := readkey ;
    close (f) ;
    closegraph ;
end.