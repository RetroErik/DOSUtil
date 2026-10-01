{*******************
!!! Setup Screen !!! : fix the last bug (I hope !!!)
*******************}

program setup ;

{$M 2048,3584,3584}

    uses dos , crt , win ;

    type infowin = record
             x,y,long,haut,coul : integer ;
         end ;

    const titledemo = 'CONTRAST - C''est notre t‚l‚ mais c''est ma commande - DEMO' ;
          titlewincolor = BLEU shl 4 + BLANC ;
          titlewin : infowin = (x:4 ; y:1 ; long:80-4*2 ; haut:3 ; coul:titlewincolor) ;

          soundwincolor = BLEU shl 4 + BLANC ;
          soundwin : infowin = (x:20 ; y:6 ; long:80-20*2 ; haut:12 ; coul:soundwincolor) ;
          soundmaxline = 8 ;
          soundbadline = 7 ;
          soundtext : array [1..soundmaxline] of string = (
          'Select a soundcard',
          'Select mixing frequency',
          'Select dma channel',
          'Select io port',
          'Select irq',
          'Select advanced option',
          '',                { = soundbadline }
          'Save & launch (ESC = quit!)') ;

          screenbackgroundcolor = BLEU shl 4 + BLANC ;
          soundhighlightcolor = BLEU shl 4 + JAUNE ;
          highlightcolor = GRISCLAIR shl 4 + ROUGE ;
          otherwincolor = ROUGE shl 4 + BLANC ;

          cardwincolor = otherwincolor ;
          ioportwincolor = otherwincolor ;
          dmawincolor = otherwincolor ;
          irqwincolor = otherwincolor ;
          mixingwincolor = otherwincolor ;
          advancedwincolor = otherwincolor ;
          advanced2wincolor = otherwincolor ;
          launchwincolor = otherwincolor ;

          midaswincolor = BLEU shl 4 + BLANC ;

          cardmaxline = 5 ;
          cardwin : infowin = (x:28 ; y:9 ; long:80-2*28 ; haut:cardmaxline+2 ; coul:cardwincolor) ;
          cardtype : array [1..cardmaxline] of string = (
          'Gravis Ultrasound',
          'Pro Audio Spectrum',
          'WindoZe Sound System',
          'Sound BaLster',
          '!!! No Sound !!!') ;

          ioportmaxline = 9 ;
          ioportbadline = 8 ;
          ioport : array [1..ioportmaxline] of string = (
          '0x210','0x220','0x230','0x240','0x250','0x260','0x270','','auto') ;
          ioportwin : infowin = (x:35 ; y:7 ; long:9 ; haut:ioportmaxline+2 ; coul:ioportwincolor) ;

          dmamaxline = 9 ;
          dmabadline = 8 ;
          dmawin : infowin = (x:36 ; y:7 ; long:8 ; haut:dmamaxline+2 ; coul:dmawincolor) ;
          dma : array [1..dmamaxline] of string = (
          ' 1',' 2',' 3',' 4',' 5',' 6',' 7','','auto') ;

          irqmaxline = 17 ;
          irqbadline = 16 ;
          irq : array [1..irqmaxline] of string = (
          ' 1',' 2',' 3',' 4',' 5',' 6',' 7',' 8',' 9','10','11','12','13','14','15','','auto') ;
          irqwin : infowin = (x:35 ; y:3 ; long:8 ; haut:irqmaxline+2 ; coul: irqwincolor) ;

          mixingmaxline = 5 ;
          mixingwin : infowin = (x:34 ; y:9 ; long:80-2*34 ; haut:mixingmaxline+2 ; coul:mixingwincolor) ;
          mixingfreq : array [1..mixingmaxline] of string = (
          '11025 Hz','15000 Hz','22050 Hz','33000 Hz','44100 Hz') ;

          advancedmaxline = 7 ;
          advancedwin : infowin = (x:32 ; y:9 ; long:80-2*31-1 ; haut:advancedmaxline+2 ; coul:advancedwincolor) ;
          advanced : array [1..advancedmaxline] of string = (
          '[ ] Use EMS',
          '[ ] BPM Tempo',
          '[ ] Surround',
          '[ ] 16 bit',
          '[ ] Stereo',
          '[ ] VGA Comp.',
          '[ ] Quality') ;

          advanced2maxline = 1 ;
          advanced2win : infowin = (x:32 ; y:11 ; long:80-2*31-1 ; haut:advanced2maxline+2 ; coul:advanced2wincolor) ;
          advanced2 : array [1..advanced2maxline] of string = (
          '[ ] VGA Comp.') ;

          midaswin : infowin = (x:4 ; y:20 ; long: 80-2*4 ; haut: 3 ; coul:midaswincolor) ;
          midastxt = '!!! Our Demo Use Midas Sound System !!!' ;

          launchmaxline = 19 ;
          launchbadline = 18 ;
          launchwin : infowin = (x: 28 ; y: 2 ; long: 80-2*28 ; haut: launchmaxline+2 ; coul: launchwincolor) ;
          launch : array [1..launchmaxline] of string = (
          'Shade lines',
          'Contrast Title',
          'Multifire',
          'Rotative zoomer',
          'Distort',
          'Double Plasma',
          'Unlimited sprites',
          'Elephant Zoomer',
          'Dots morphs',
          'Waves',
          'Wolfenstein',
          'Snul Flash',
          'Single Plasma',
          'Transformation',
          'Eyes', 
          'Snake',
          'Starwars scroller',
          '',
          '!!! All the parts !!!') ;

          qualitytbl : array [1..3] of char = ('h','l','m') ; { :) }

    var usrinput : char ;

        f : text ;

        i , soundactline , cardactline ,usrcard , usrmixing , usrdma : integer ;
        usrirq , usrioport , mixingactline , dmaactline , ioportactline : integer ;
        irqactline , advancedactline , launchactline , usrscreen , quality : integer ;

        funckey , savenow : boolean ;
        advancedopt : array [1..advancedmaxline] of boolean ;

        param , commandpath : string ;
        tmp : string [5] ;

        wordtmp : word ;

function getusrinput : char ;
    var dummy : char ;
begin
    dummy := upcase (readkey) ;
    funckey := false ;
    if (dummy = #0) then
    begin
        dummy := upcase (readkey) ;
        funckey := true ;
    end ;
    getusrinput := dummy ;
end ;

procedure centertext (ligne,coul : integer; blabla : string) ; { affiche dans la window courante }
begin
    winprint (((vd (-1) - vg (1) - length (blabla) + 1) div 2)+vg (1),vh (0)+ligne,coul,blabla) ;
end ;

procedure openwin (info : infowin) ;
begin
    if (winopenshadow (info.x,info.y,info.x+info.long-1,info.y+info.haut-1) = winopenerror) then halt (1) ;
    winframe (VG(0), VH(0), VD(0), VB(0), CAD_SIM,info.coul) ;
    winfill (VG(1), VH(1), VD(-1), VB(-1), ' ',info.coul and $f0) ;
end ;

FUNCTION Int2Str(i: LONGINT): STRING;
{ Conversion d'un entier en chaŒne }
VAR
  s: STRING[11];
BEGIN
  Str(i, s);
  Int2Str := s;
END;

begin
    asm mov ax,3 { mode text 80*25*16c }
    int $10 end ;
    winhidecursor ;
    winfill (0,0,79,24,'±',screenbackgroundcolor) ; { fill the screen }

    openwin (titlewin) ;
    centertext (1,titlewincolor,titledemo) ;
    centertext (0,titlewincolor,' TFL & TDV Proudly Present ') ;

    openwin (midaswin) ;
    centertext (1,midaswincolor,midastxt) ;
    centertext (0,midaswincolor,' A Big Thanks ') ;

    openwin (soundwin) ;

    for i := 1 to soundmaxline do
        centertext (i+1,soundwincolor,soundtext [i]) ;

    wincolor (vg (2),vh (2),vd (-2),vh (2),soundhighlightcolor) ;

    usrcard := 1 ; { GUS }
    usrdma := dmamaxline ; { auto }
    usrioport := ioportmaxline ; { auto }
    usrmixing := 5 ; { 44100 }
    usrirq := irqmaxline ; { auto }

    advancedopt [1] := true ; { use EMS }
    advancedopt [2] := true ; { use BPM tempo }
    advancedopt [3] := false ; { Surround }
    advancedopt [4] := true ; { 16 bit }
    advancedopt [5] := true ; { stereo }
    advancedopt [6] := false ; { VGA comp :( }

    cardactline := 1 ;
    mixingactline := 5 ; { 44100 }
    dmaactline := dmamaxline ;
    irqactline := irqmaxline ;
    ioportactline := ioportmaxline ;
    quality := 1 ;

    launchactline := launchmaxline ; { view all the screen }
    usrscreen := launchmaxline ; { all the screen }
    soundactline := 1 ;
    savenow := false ;
    advancedopt [7] := false ; { laisser a faux !!! quality !!! }
    advancedactline := 1 ;

    assign (f,'demo.bat') ;
    {$I-}
    reset (f) ;
    {$I+}
    if ioresult = 0 then
    begin { ecraser les param par defauts }
        read (f,param) ;
        close (f) ;

        if pos ('-s',param) > 0 then {card !!! 1-5 }
        begin
            tmp := copy (param,pos ('-s',param)+2,1) ; { +2 coze 0='-',1='s' !!! }
            val (tmp,usrcard,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            cardactline := usrcard ;
        end ;

        if pos ('-m',param) > 0 then { port 11025-44100 }
        begin
            tmp := copy (param,pos ('-m',param)+2,5) ; { +2 coze 0='-',1='m' !!! }
            val (tmp,wordtmp,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            case wordtmp of
            11025 : mixingactline := 1 ;
            15000 : mixingactline := 2 ;
            22050 : mixingactline := 3 ;
            33000 : mixingactline := 4 ;
            44100 : mixingactline := 5 ;
            end ;
            usrmixing := mixingactline ;
        end ;

        if pos ('-d',param) > 0 then { dma 1-7 }
        begin
            tmp := copy (param,pos ('-d',param)+2,1) ; { +2 coze 0='-',1='d' !!! }
            val (tmp,usrdma,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            dmaactline := usrdma ;
        end ;

        if pos ('-p',param) > 0 then { port 210-270 en hexa ! }
        begin
            tmp := copy (param,pos ('-p',param)+2,3) ; { +2 coze 0='-',1='p' !!! }
            val (tmp,usrioport,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            case usrioport of
            210 : ioportactline := 1 ;
            220 : ioportactline := 2 ;
            230 : ioportactline := 3 ;
            240 : ioportactline := 4 ;
            250 : ioportactline := 5 ;
            260 : ioportactline := 6 ;
            270 : ioportactline := 7 ;
            end ;
            usrioport := ioportactline ;
        end ;

        if pos ('-i',param) > 0 then { irq 1-15 }
        begin
            tmp := copy (param,pos ('-i',param)+2,2) ; { +2 coze 0='-',1='i' !!! }
            if tmp [2] = ' ' then
               tmp [0] := chr (1) ; { forcer !!! }
            val (tmp,usrirq,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            irqactline := usrirq ;
        end ;

        if pos ('-e',param) > 0 then { EMS }
            advancedopt [1] := false ;
         
        if pos ('-t',param) > 0 then { BPM }
            advancedopt [2] := false ;

        if pos ('-u',param) > 0 then { surround }
            advancedopt [3] := true ;

        if pos ('-o1m',param) > 0 then { 16 bit mono ... encore du code inutile !!! } 
        begin
            advancedopt [4] := true ;
            advancedopt [5] := false ;
        end ;

        if pos ('-o1s',param) > 0 then { 16 bit stereo }
        begin
            advancedopt [4] := true ;
            advancedopt [5] := true ;
        end ;

        if pos ('-o8m',param) > 0 then { 8 bit mono }
        begin
            advancedopt [4] := false ;
            advancedopt [5] := false ;
        end ;

        if pos ('-o8s',param) > 0 then { 8 bit stereo }
        begin
            advancedopt [4] := false ;
            advancedopt [5] := true ;
        end ;

        if pos ('-w',param) > 0 then { EMS }
        begin
            tmp := copy (param,pos ('-w',param)+2,1) ; { +2 coze 0='-',1='w' !!! }
            val (tmp,wordtmp,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            if wordtmp = 0 then
                advancedopt [6] := false
            else
                advancedopt [6] := true ;
        end ;

        if pos ('-oh',param) > 0 then { quality high }
            quality := 1 ;

        if pos ('-om',param) > 0 then { quality medium ... beaucoup de code inutile !!! }
            quality := 3 ;
        
        if pos ('-ol',param) > 0 then { quality low }
            quality := 2 ;

        if pos ('-g',param) > 0 then { screen 1-17 }
        begin
            tmp := copy (param,pos ('-g',param)+2,2) ; { +2 coze 0='-',1='g' !!! }
            if tmp [2] = ' ' then
               tmp [0] := chr (1) ; { forcer !!! }
            val (tmp,usrscreen,i) ; { i = erreur }
            if i <> 0 then
            begin
                writeln ('I/O error : demo.bat altered !!!') ;
                halt (2) ;
            end ;
            launchactline := usrscreen ;
        end ;

    end ;

    repeat
        usrinput := getusrinput ;
        if funckey then
        begin
            if usrinput = 'H' then
            begin { fleche haut }
                wincolor (vg (2),vh (1)+soundactline,vd (-2),vh (1)+soundactline,soundwincolor) ;
                dec (soundactline) ;
                if soundactline = soundbadline then
                    dec (soundactline)
                else if soundactline = 0 then
                    soundactline := soundmaxline ;
                wincolor (vg (2),vh (1)+soundactline,vd (-2),vh (1)+soundactline,soundhighlightcolor) ;
            end

            else if usrinput = 'P' then { fleche bas }
            begin
                wincolor (vg (2),vh (1)+soundactline,vd (-2),vh (1)+soundactline,soundwincolor) ;
                inc (soundactline) ;
                if soundactline = soundbadline then
                    inc (soundactline)
                else if soundactline = soundmaxline+1 then
                    soundactline := 1 ;
                wincolor (vg (2),vh (1)+soundactline,vd (-2),vh (1)+soundactline,soundhighlightcolor) ;
            end
        end
        else if usrinput = #13 then { else if not funckey }
        case soundactline of
        1 : begin { cardtype }
                openwin (cardwin) ;
                for i := 1 to cardmaxline do
                    centertext (i,cardwincolor,cardtype [i]) ;
                wincolor (vg (1),vh (0)+cardactline,vd (-1),vh (0)+cardactline,highlightcolor) ;
                repeat
                    usrinput := getusrinput ;
                    if funckey then
                        if usrinput = 'H' then { fleche haut }
                        begin
                            wincolor (vg (1),vh (0)+cardactline,vd (-1),vh (0)+cardactline,cardwincolor) ;
                            dec (cardactline) ;
                            if cardactline = 0 then
                                cardactline := cardmaxline ;
                            wincolor (vg (1),vh (0)+cardactline,vd (-1),vh (0)+cardactline,highlightcolor) ;
                        end
                        else if usrinput = 'P' then { fleche bas }
                        begin
                            wincolor (vg (1),vh (0)+cardactline,vd (-1),vh (0)+cardactline,cardwincolor) ;
                            inc (cardactline) ;
                            if cardactline = cardmaxline+1 then
                                cardactline := 1 ;
                            wincolor (vg (1),vh (0)+cardactline,vd (-1),vh (0)+cardactline,highlightcolor) ;
                        end
                until usrinput = #13 ;
                winclose (true) ;
                usrcard := cardactline ;

            end ;

        2 : if usrcard <> 5 then
            begin { mixing frequency }
                openwin (mixingwin) ;
                for i := 1 to mixingmaxline do
                    centertext (i,mixingwincolor,mixingfreq [i]) ;
                wincolor (vg (1),vh (0)+mixingactline,vd (-1),vh (0)+mixingactline,highlightcolor) ;
                repeat
                    usrinput := getusrinput ;
                    if funckey then
                        if usrinput = 'H' then { fleche haut }
                        begin
                            wincolor (vg (1),vh (0)+mixingactline,vd (-1),vh (0)+mixingactline,mixingwincolor) ;
                            dec (mixingactline) ;
                            if mixingactline = 0 then
                                mixingactline := mixingmaxline ;
                            wincolor (vg (1),vh (0)+mixingactline,vd (-1),vh (0)+mixingactline,highlightcolor) ;
                        end
                        else if usrinput = 'P' then { fleche bas }
                        begin
                            wincolor (vg (1),vh (0)+mixingactline,vd (-1),vh (0)+mixingactline,mixingwincolor) ;
                            inc (mixingactline) ;
                            if mixingactline = mixingmaxline+1 then
                                mixingactline := 1 ;
                            wincolor (vg (1),vh (0)+mixingactline,vd (-1),vh (0)+mixingactline,highlightcolor) ;
                        end
                until usrinput = #13 ;
                winclose (true) ;
                usrmixing := mixingactline ;
            end ;

        3 : if usrcard <> 5 then
            begin { dma channel }
                openwin (dmawin) ;
                for i := 1 to dmamaxline do
                    centertext (i,dmawincolor,dma [i]) ;
                wincolor (vg (1),vh (0)+dmaactline,vd (-1),vh (0)+dmaactline,highlightcolor) ;
                repeat
                    usrinput := getusrinput ;
                    if funckey then
                        if usrinput = 'H' then { fleche haut }
                        begin
                            wincolor (vg (1),vh (0)+dmaactline,vd (-1),vh (0)+dmaactline,dmawincolor) ;
                            dec (dmaactline) ;
                            if dmaactline = 0 then
                                dmaactline := dmamaxline
                            else if dmaactline = dmabadline then
                                dec (dmaactline) ;
                            wincolor (vg (1),vh (0)+dmaactline,vd (-1),vh (0)+dmaactline,highlightcolor) ;
                        end
                        else if usrinput = 'P' then { fleche bas }
                        begin
                            wincolor (vg (1),vh (0)+dmaactline,vd (-1),vh (0)+dmaactline,dmawincolor) ;
                            inc (dmaactline) ;
                            if dmaactline = dmamaxline+1 then
                                dmaactline := 1
                            else if dmaactline = dmabadline then
                                inc (dmaactline) ;
                            wincolor (vg (1),vh (0)+dmaactline,vd (-1),vh (0)+dmaactline,highlightcolor) ;
                        end
                until usrinput = #13 ;
                winclose (true) ;
                usrdma := dmaactline ;
            end ;

          4: if usrcard <> 5 then
             begin { io port }
                 openwin (ioportwin) ;
                 for i := 1 to ioportmaxline do
                    centertext (i,ioportwincolor,ioport [i]) ;
                 wincolor (vg (1),vh (0)+ioportactline,vd (-1),vh (0)+ioportactline,highlightcolor) ;
                 repeat
                     usrinput := getusrinput ;
                     if funckey then
                         if usrinput = 'H' then { fleche haut }
                         begin
                             wincolor (vg (1),vh (0)+ioportactline,vd (-1),vh (0)+ioportactline,ioportwincolor) ;
                             dec (ioportactline) ;
                             if ioportactline = 0 then
                                 ioportactline := ioportmaxline
                             else if ioportactline = ioportbadline then
                                 dec (ioportactline) ;
                             wincolor (vg (1),vh (0)+ioportactline,vd (-1),vh (0)+ioportactline,highlightcolor) ;
                         end
                         else if usrinput = 'P' then { fleche bas }
                         begin
                             wincolor (vg (1),vh (0)+ioportactline,vd (-1),vh (0)+ioportactline,ioportwincolor) ;
                             inc (ioportactline) ;
                             if ioportactline = ioportmaxline+1 then
                                 ioportactline := 1
                             else if ioportactline = ioportbadline then
                                 inc (ioportactline) ;
                             wincolor (vg (1),vh (0)+ioportactline,vd (-1),vh (0)+ioportactline,highlightcolor) ;
                         end
                 until usrinput = #13 ;
                 winclose (true) ;
                 usrioport := ioportactline ;
            end ;

        5: if usrcard <> 5 then
           begin { irq }
               openwin (irqwin) ;
               for i := 1 to irqmaxline do
                   centertext (i,irqwincolor,irq [i]) ;
               wincolor (vg (1),vh (0)+irqactline,vd (-1),vh (0)+irqactline,highlightcolor) ;
               repeat
                   usrinput := getusrinput ;
                   if funckey then
                       if usrinput = 'H' then { fleche haut }
                       begin
                           wincolor (vg (1),vh (0)+irqactline,vd (-1),vh (0)+irqactline,irqwincolor) ;
                           dec (irqactline) ;
                           if irqactline = 0 then
                               irqactline := irqmaxline
                           else if irqactline = irqbadline then
                               dec (irqactline) ;
                           wincolor (vg (1),vh (0)+irqactline,vd (-1),vh (0)+irqactline,highlightcolor) ;
                       end
                       else if usrinput = 'P' then { fleche bas }
                       begin
                           wincolor (vg (1),vh (0)+irqactline,vd (-1),vh (0)+irqactline,irqwincolor) ;
                           inc (irqactline) ;
                           if irqactline = irqmaxline+1 then
                               irqactline := 1
                           else if irqactline = irqbadline then
                               inc (irqactline) ;
                           wincolor (vg (1),vh (0)+irqactline,vd (-1),vh (0)+irqactline,highlightcolor) ;
                       end
               until usrinput = #13 ;
               winclose (true) ;
               usrirq := irqactline ;
          end ;

          6: { advanced }
              if usrcard <> 5 then { No sound ? }
              begin
                  openwin (advancedwin) ;

                  for i := 1 to advancedmaxline do
                  begin
                      winprint (vg (2),vh (0)+i,advancedwincolor,advanced [i]) ;
                      if advancedopt [i] then
                          winputchar (vg (3),vh (0)+i,'þ',advancedwincolor) ;
                  end ;

                  winputchar (vg (3),vh (0)+7,qualitytbl [quality],advancedwincolor) ;

                  wincolor (vg (1),vh (0)+advancedactline,vd (-1),vh (0)+advancedactline,highlightcolor) ;
                  repeat
                      usrinput := getusrinput ;
                      if funckey then
                      begin
                          if usrinput = 'H' then { fleche haut }
                          begin
                              wincolor (vg (1),vh (0)+advancedactline,vd (-1),vh (0)+advancedactline,advancedwincolor) ;
                              dec (advancedactline) ;
                              if advancedactline = 0 then
                                  advancedactline := advancedmaxline ;
                              wincolor (vg (1),vh (0)+advancedactline,vd (-1),vh (0)+advancedactline,highlightcolor) ;
                          end
                          else if usrinput = 'P' then { fleche bas }
                          begin
                              wincolor (vg (1),vh (0)+advancedactline,vd (-1),vh (0)+advancedactline,advancedwincolor) ;
                              inc (advancedactline) ;
                              if advancedactline = advancedmaxline+1 then
                                  advancedactline := 1 ;
                              wincolor (vg (1),vh (0)+advancedactline,vd (-1),vh (0)+advancedactline,highlightcolor) ;
                          end
                      end
                      else if usrinput = #32 then { funckey = false }
                      begin
                          if advancedactline = 7 then { Quality }
                          begin
                              inc (quality) ;
                              if quality = 4 then
                                  quality := 1 ;
                              winputchar (vg (3),vh (0)+7,qualitytbl [quality],highlightcolor) ;
                          end
                          else { advancedactline <> 7 }
                          begin
                              if advancedopt [advancedactline] then
                                  winputchar (vg (3),vh (0)+advancedactline,#32,highlightcolor)
                              else
                                  winputchar (vg (3),vh (0)+advancedactline,'þ',highlightcolor) ;
                              advancedopt [advancedactline] := not advancedopt [advancedactline] ;
                          end ;
                      end ;
                  until usrinput = #13 ;
                  winclose (true) ;
              end
              else { no sound !!! }
              begin
                  openwin (advanced2win) ;
                  winprint (vg (1),vh (1),advanced2wincolor,advanced2 [1]) ;
                  if advancedopt [6] then
                      winputchar (vg (2),vh (1),'þ',advanced2wincolor) ;
                  wincolor (vg (1),vh (1),vd (-1),vh (1),highlightcolor) ;
                  repeat
                      usrinput := getusrinput ;
                      if (usrinput = #32) and not funckey then { space }
                      begin 
                          if advancedopt [6] then { VGA Comp. }
                              winputchar (vg (2),vh (1),#32,highlightcolor)
                          else
                              winputchar (vg (2),vh (1),'þ',highlightcolor) ;
                          advancedopt [6] := not advancedopt [6] ;
                      end ;
                  until (usrinput = #13) and not funckey ;
                  winclose (true) ;
              end ;

{          7: begin
             end ; bad line :}

          8 : begin
                  savenow := true ;
                  openwin (launchwin) ;
                  for i := 1 to launchmaxline do
                      centertext (i,launchwincolor,launch [i]) ;
                  wincolor (vg (1),vh (0)+launchactline,vd (-1),vh (0)+launchactline,highlightcolor) ;
                  repeat
                      usrinput := getusrinput ;
                      if funckey then
                          if usrinput = 'H' then { fleche haut }
                          begin
                              wincolor (vg (1),vh (0)+launchactline,vd (-1),vh (0)+launchactline,launchwincolor) ;
                              dec (launchactline) ;
                              if launchactline = 0 then
                                  launchactline := launchmaxline
                              else if launchactline = launchbadline then
                                  dec (launchactline) ;
                              wincolor (vg (1),vh (0)+launchactline,vd (-1),vh (0)+launchactline,highlightcolor) ;
                          end
                          else if usrinput = 'P' then { fleche bas }
                          begin
                              wincolor (vg (1),vh (0)+launchactline,vd (-1),vh (0)+launchactline,launchwincolor) ;
                              inc (launchactline) ;
                              if launchactline = launchmaxline+1 then
                                  launchactline := 1
                              else if launchactline = launchbadline then
                                  inc (launchactline) ;
                              wincolor (vg (1),vh (0)+launchactline,vd (-1),vh (0)+launchactline,highlightcolor) ;
                          end
                   until usrinput = #13 ;
                   winclose (true) ;
                   usrscreen := launchactline ;
              end ;
          end ;

    until ((not funckey) and (usrinput = #27)) or savenow ;

    winclose (true) ; { titre }
    winclose (true) ; { main }
    winclose (true) ; { MIDAS }

    asm mov ax,3 { mode text 80*25*16c }
    int $10 end ;

    if savenow then
    begin
        assign (f,'demo.bat') ;
        rewrite (f) ;

        param := '@contrast.exe -s' ;
        param := param + int2str (usrcard) ;

        if usrcard < 5 then { no sound ??? }
        begin { noooooo i wont sound }

            case usrmixing of
            1 : param := param + ' -m11025 ' ;
            2 : param := param + ' -m15000 ' ;
            3 : param := param + ' -m22050 ' ;
            4 : param := param + ' -m33000 ' ;  
            5 : param := param + ' -m44100 ' ;
            end ;
 
            if usrdma <> dmamaxline then { auto }
                param := param + ' -d' + int2str (usrdma) + ' ' ;

            case usrioport of  
            1 : param := param + '-p210 ' ;
            2 : param := param + '-p220 ' ;
            3 : param := param + '-p230 ' ;
            4 : param := param + '-p240 ' ;
            5 : param := param + '-p250 ' ;
            6 : param := param + '-p260 ' ;
            7 : param := param + '-p270 ' ; 
          { 9 : nothing !!! = auto = portmaxline }
            end ;

            if usrirq <> irqmaxline then
                param := param + ' -i' + int2str (usrirq) ;

            if not advancedopt [2] then
                param := param + ' -t' ; { disable BPM }

            if advancedopt [3] then
                param := param + ' -u' ; { enable surround }

            if advancedopt [4] then
                if advancedopt [5] then
                    param := param + ' -o1s'
                else
                    param := param + ' -o1m'
            else
                if advancedopt [5] then
                    param := param + ' -o8s'
                else
                    param := param + ' -o8m' ; { warning on test la quality medium avec -om !!! }

            param := param + ' -o' + qualitytbl [quality] ;

        end ; { usrcard < 5 }

        if not advancedopt [1] then
            param := param + ' -e' ; { disable EMS }

        if usrscreen <> launchmaxline then { view a specific part }
            param := param + ' -g' + int2str (usrscreen) ;


        if advancedopt [6] then { a laisser en dernier !!!!!!!!!!! }
            param := param + ' -w1'
        else
            param := param + ' -w0' ;

        write (f,param) ;
        close (f) ;

        commandpath := getenv ('COMSPEC') ;
        if commandpath = '' then
        begin
            assign (f,'c:\command.com') ;
            {$I-}
            reset (f) ;
            {$I+}
            if ioresult <> 0 then
            begin
                winprint (0,0,7,'Warning : unable to locate command.com ...') ;
                winprint (0,2,7,'Hey Dude ... type this line at the dos prompt :)') ;
                winprint (0,3,7,'SET COMSPEC=driveletter:\fullpath\command.com') ;
                winsetcursor (0,4) ;
                halt (1) ;
            end ;
            close (f) ;
            readln ;
            commandpath := 'c:\command.com' ;
        end ;

        swapvectors ;
        exec (commandpath,'/c demo.bat') ;
        swapvectors ;

    end ;

end.