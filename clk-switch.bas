NEW 
10 ?"clock swith test"
20 GOSUB CLK.SWITCH 
30 PMODE 6,POUT 
40 DWRITE 6,1 
50 ? "switching done"
100 END 

599 ' switch to HSE clock 12Mhz crystal 
600 CLK.SWITCH
604 CONST CLK.SWR=$50C4,CLK.SWCR=$50C5
608 CONST UART3.BRR1=$5242,UART3.BBR2=$5243
612 CONST UART3.CR1=$5244, PA.CR1=$5003
616 BRES PA.CR1,6 ' disable pull up on PA:1,2
620 POKE CLK.SWR,$B4
624 DO UNTIL BTEST(CLK.SWCR,3) : ' SWIF bit 
628 BSET CLK.SWCR,2 ' switch to HSE
630 ' adjust UART3 BRR 
632 BRES UART3.CR1,1 : ' turn off UART 
636 POKE UART3.BBR2,8:POKE UART3.BRR1,6 : '0x68 
640 BSET UART3.CR1,1 : ' turn on UART
644 RETURN 


