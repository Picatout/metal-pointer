;------------------------
; debug support 
; using UART 
; to use it define:
; DEBUG=1
; FMSTR= frequency in Hertz  
; in main project file
;-----------------------

    .module UART_DEBUG 

.if DEBUG 

;-----------------------------
; define these constants 
; according to selected UART 
;-----------------------------
UART_BRR1=UART2_BRR1 
UART_BRR2=UART2_BRR2 
UART_DR=UART2_DR 
UART_SR=UART2_SR 
UART_CR1=UART2_CR1
UART_CR2=UART2_CR2 
UART_CLK_PCKENR=CLK_PCKENR1 
UART_CLK_PCKENR_UART=CLK_PCKENR1_UART2 


;------------------
; initialize UART 
; 115200 BAUD 
; 8N1 
;------------------
uart_init::
; enable UART clock
	bset UART_CLK_PCKENR,#UART_CLK_PCKENR_UART 	
uart_set_baud:: 
	push a 
	bres UART_CR1,#UART_CR1_PIEN
; baud rate 115200 : Fmaster/115200
	ldw x,#FMSTR/115200
    ld a,#16 
    div x,a 
    ld (1,sp),a 
    ld a,xh 
    add a,(1,sp)
    ld UART_BRR2,a ; must be loaded first
	ld a,xl 
    ld UART_BRR1,a 
    clr UART_DR
	mov UART_CR2,#((1<<UART_CR2_TEN)|(1<<UART_CR2_REN))
	bset UART_CR2,#UART_CR2_SBK
    btjf UART_SR,#UART_SR_TC,.
	pop a 
	ret

;--------------------
; send a character 
; input:
;   A   character to send
;---------------------------
uart_putc:: 
    btjf UART_SR,#UART_SR_TXE,.
    ld UART_DR,a 
    ret 

;--------------------------
; receive a character 
; output:
;   A    0| char 
uart_getc::
    clr a 
    btjf UART_SR,#UART_SR_RXNE,9$
    ld a,UART_DR 
9$:
    ret 

;------------------
; wait for a character 
; from UART 
; output:
;    A   char 
;--------------------
uart_wait_char:
    call uart_getc 
    tnz a 
    jreq uart_wait_char  
    ret

;-------------------------
; send ASCIZ string 
; input:
;    X    *string 
;-------------------------
uart_puts:: 
    ld a,(x)
    jreq 9$
    call uart_putc 
    incw x 
    jra uart_puts 
9$: btjf UART_SR,#UART_SR_TC,9$    
    ret 

;---------------
; print integer 
; input:
;   X   integer 
;---------------
uart_prt_int:
    push a
    pushw y 
    clrw y 
1$:
    cpw x,#0
    jreq 4$ 
    ld a,#10
    div x,a 
    add a,#'0 
    push a 
    incw y 
    jra 1$ 
4$: tnzw y 
    jreq 7$
6$: pop a 
    call uart_putc 
    decw y 
    jrne 6$
    jra 8$ 
7$: ld a,#'0
    call uart_putc 
8$:
    ld a,#32 
    call uart_putc 
    btjf UART_SR,#UART_SR_TC,.
    popw y 
    pop a 
    ret 

;------------------------
; clear terminal screen 
;-------------------------
clear_screen:
    ld a,#27 
    call uart_putc 
    ld a,#'c 
    call uart_putc 
    ret 
    
.endif ; DEBUG 
