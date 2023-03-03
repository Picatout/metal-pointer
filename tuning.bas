NEW 
1 TUNING
2 ' search for LC resonnace frequency
10 CONST TIM1.ARRH=$5262,TIM1.ARRL=$5263
20 CONST TIM1.CR1=$5250,TIM1.CCR1H=$5265, TIM1.CCR1L=$5266
30 CONST PB.CR1=$5008: BRES PB.CR1,8
40 CONST ADC.TDRL=$5407: BSET ADC.TDRL,8 
50 PWM.EN 1,8 'enable PWM
60 PWM.CH.EN 4,1 ' enable channel 4 
70 LET F=PEEK(TIM1.ARRH)*256+PEEK(TIM1.ARRL)
80 PWM.OUT 4,F/2 
90 ADCON 1,4 : ' enable analog/digital converter
100 GOSUB CLS: ? "calibration"
110 PAUSE 100
120 GOSUB CALIB
130 PWM.EN 0 
140 ADCON 0
150 ? "value of F in metal-detector.bas should be ";N   
160 END  

249 ' clear screen subroutine
250 CLS 
260 ' clear terminal screen 
270 ' send cursor top-left 
280 ? CHAR(27);"[";CHAR(50);CHAR($4A)
290 ? CHAR(27);"[";CHAR($48)
300 RETURN 

399 ' Search frequency at which LC impedance is minimum
400 CALIB
401 LET M=ADCREAD(3)
402 ? " Try to minimize 'R' value, typing 'U','D','Q'uit"
403 DO 
404 GET A: LET A=A AND $DF
406 IF A=ASC(\U) LET D=1 : GOTO 410 
408 IF A=ASC(\D) LET D=-1
410 LET F=F+D 
440 GOSUB PWM.FREQ : PAUSE 100 
450 LET R=ADCREAD(3)
454 IF R<M : LET M=R,N=F : ? "*** smallest R is for F=";F  
460 ? "F=";F;" R=";R    
490 UNTIL A=ASC(\Q) 
500 RETURN 

599 ' adjust PWM frequency to new value 
600 PWM.FREQ 
604 BRES TIM1.CR1,1
610 POKE TIM1.ARRH,F/256
620 POKE TIM1.ARRL,F%256
622 BSET TIM1.CR1,1  
630 PWM.OUT 4,F/2 
640 RETURN 
