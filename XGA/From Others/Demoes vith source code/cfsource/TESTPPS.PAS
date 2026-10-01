{$M 1024,0,100000}
PROGRAM TestPPS;
USES
    Crt,Dos;

{$L C:\DEMOS\CODE\MODPLAY\MODMAIN }
{$L C:\DEMOS\CODE\MODPLAY\DMASUB }
{$L C:\DEMOS\CODE\MODPLAY\MCLSUB }
{$L C:\DEMOS\CODE\MODPLAY\MODSUB }

PROCEDURE StartPlay; EXTERNAL;
PROCEDURE UpdatePlay; EXTERNAL;
PROCEDURE StopPlay; EXTERNAL;

BEGIN
     StartPlay;
     REPEAT
           UpdatePlay;
           Delay(70);
     UNTIL KeyPressed;
     StopPlay;
     WriteLn('Ende!');
END.