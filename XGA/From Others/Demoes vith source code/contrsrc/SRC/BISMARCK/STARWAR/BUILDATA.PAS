program buildtalbes;
uses crt;
var datafile : text;
    x,y,i,j : word;
    table : array [0..139] of byte;
    pal : array [0..255,0..2] of byte;
    pal2 : array [0..768] of byte;
    depl : array [0..139] of word;
    taille : array [0..139] of word;
    plandep : array [0..139] of byte;
    planfin : array [0..139] of byte;
    rapport : array [0..139] of word;
    prout   : real;
    ch: char;
    r,xx: real;

begin
  assign (datafile,'datafile.inc');
  rewrite(datafile);
  write(datafile,'mul320 ');
  for y:=0 to 19 do
  begin
    write(datafile,'WORD ');
    for x:=0 to 9 do
    begin
      write(datafile,(y*10+x)*320);
      if x<>9 then write(datafile,', ');
    end;
    writeln(datafile);
  end;
  writeln(datafile);
  writeln(datafile);
  clrscr;

  write(datafile,'mul420 ');
  for y:=0 to 4 do
  begin
    write(datafile,'WORD ');
    for x:=0 to 9 do
    begin
      write(datafile,(y*10+x)*420);
      if x<>9 then write(datafile,', ');
    end;
    writeln(datafile);
  end;
  write(datafile,'WORD ',50*420,', ',51*420,', ',52*420);
  writeln(datafile);
  for x:= 0 to 255 do
  begin
    pal[x,0]:=0;
    pal[x,1]:=0;
    pal[x,2]:=0;
  end;
  prout:=1;
  for y:=0 to 18 do
  begin
    pal[y*13+0,2]:=trunc(63*ln(prout)/ln(3.5));
    pal[y*13+1,2]:=trunc(58*ln(prout)/ln(3.5));
    pal[y*13+2,2]:=trunc(52*ln(prout)/ln(3.5));
    pal[y*13+3,2]:=trunc(46*ln(prout)/ln(3.5));
    pal[y*13+4,2]:=trunc(36*ln(prout)/ln(3.5));
    pal[y*13+5,2]:=trunc(30*ln(prout)/ln(3.5));
    pal[y*13+6,2]:=trunc(26*ln(prout)/ln(3.5));
    pal[y*13+7,2]:=trunc(18*ln(prout)/ln(3.5));
    pal[y*13+8,2]:=trunc(10*ln(prout)/ln(3.5));
    pal[y*13+9,2]:=trunc(6*ln(prout)/ln(3.5));
    pal[y*13+10,2]:=trunc(2*ln(prout)/ln(3.5));
    pal[y*13+11,2]:=trunc(0*ln(prout)/ln(3.5));
    pal[y*13+12,2]:=trunc(0*ln(prout)/ln(3.5));
    prout:=prout+(3.5-1)/19;
  end;

  for i:=0 to 255 do for j:=0 to 2 do pal2[i*3+j]:=pal[i,j];

  write(datafile,'pal BYTE ');
  for j:=0 to 8 do write(datafile,pal2[j],', ');
  writeln(datafile,pal2[9]);

  for i:=1 to 75 do
  begin
    write(datafile,'BYTE ');
    for j:=0 to 8 do write(datafile,pal2[i*10+j],', ');
    writeln(datafile,pal2[i*10+9]);
  end;
  write(datafile,'BYTE ');
  for j:=0 to 4 do write(datafile,pal2[760+j],', ');
  write(datafile,pal2[762],', ');
  write(datafile,pal2[763],', ');
  writeln(datafile,pal2[764]);

  close(datafile);
end.
