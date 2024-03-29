NEW 
1 DETECTOR 
2 ' Pin point metal detector, version 1, revesion 5 
3 TRACE 0
4  CLK_HSE  
6 CONST DEBUG=0 : LET K=0 
10 PMODE 6,POUT ' GREEN LED OUTPUT
20 CONST TIM1.ARRH=$5262,TIM1.ARRL=$5263, SENSIVITY=2
30 CONST TIM1.CR1=$5250
40 CONST PB.CR1=$5008: BRES PB.CR1,3
50 CONST ADC.TDRL=$5407: BSET ADC.TDRL,3 
60 CONST LEN=32
64 PMODE 6,POUT: DWRITE 6,0 
70 PWM.EN 1,8 
80 PWM.CH.EN 4,1 
88 ' set PWM frequency to ~50Khz
89 LET F=161
90 POKE TIM1.ARRH,F/256: POKE TIM1.ARRL,F%256:PWM.OUT 4,F/2
100 ADCON 1,4
110 GOSUB LOW.POWER
120 PAUSE 100 
130 FOR I=1 TO LEN : LET S=S+ADCREAD(3):PAUSE 1:NEXT I 
140 LET A=S/LEN  ' average 32 samples 
150 IF DEBUG : GOSUB CLS : ? "Detector active"
160 DO 
164 GOSUB CLR.C3 
170 LET R=ADCREAD(3) 
174 IF DEBUG : GOSUB CLS:? R ; 
180 LET S=S-A+R, A=S/LEN    
190 IF ABS(A-R)>SENSIVITY : GOSUB ALARM  
194 IF DEBUG : GET K 
200 UNTIL K 
209 ' turn off detector 
210 ADCON 0 : PWM.EN 0 
220 END
249 ' clear screen subroutine
250 CLS 
260 ' clear terminal screen 
270 ' send cursor top-left 
280 ? CHAR(27);"c"
300 RETURN 
399 ' BEEP and LED on for 10msec 
400 ALARM 
410 DWRITE 6,1:TONE 500,10:DWRITE 6,0
420 RETURN 
499 ' disable unsused peripherals clock
500  LOW.POWER 
510  CONST CLK.PCKENR1  = $50C7, CLK.PCKENR2  = $50CA
520  POKE CLK.PCKENR1,$B8: POKE CLK.PCKENR2,8  
530  RETURN

699 ' empty C3
700 CLR.C3  
702 ADCON 0 : PWM.CH.EN 4,0  
704 BSET PORTB+DDR,3
706 BRES PORTB+ODR,3 
708 PAUSE 1 
710 BRES PORTB+DDR,3 
712 PWM.CH.EN 4,1 
714 ADCON 1,4 
716 PAUSE 1
720 RETURN 
