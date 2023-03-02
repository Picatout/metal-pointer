NEW 
1 ETR.ALT_FUNC 
2 ?"Enable or disable ETR alternate function on NUCLEO_8S207K8 board" 
10 IF PEEK($4803) AND 32 : ? "ETR alternate function is enabled." 
20 INPUT "0 Quit\n1 Enable it\n2 Disable it\n"n 
30 IF N=0 : END 
40 IF N=1 : LET A=PEEK($4803) OR 32:WRITE $4803,A : REBOOT 
50 IF N=2 : LET A=NOT 32 AND PEEK($4803):WRITE $4803,A: REBOOT
