;--------------------
; bare metal version 
; on STM8S105K6B6
;--------------------

    .module METAL_POINTER 

    .include "inc/macros.inc" 
    .include "inc/stm8s105.inc"

    .page 

; defined for debug.asm 
DEBUG=1 
FMSTR=12000000 ; 


;------------------------------
;  system constants 
;------------------------------
ALARM_LED_BIT = 3 
ALARM_LED_ODR = PC_ODR 
ALRAM_LED_DDR = PC_DDR 
ALARM_LED_CR1 = PC_CR1 
ADC_INPUT = 3

;; detector sensivity
;; increment to reduce false detection 
SENSIVITY = 2

;; period value for TIMER1 frequency 
;; period = 12e6/50329 - 1
TMR1_PERIOD=237 
; duty cycle 
TMR1_DC= TMR1_PERIOD/2 

    .macro _led_on 
    bres ALARM_LED_ODR,#ALARM_LED_BIT 
    .endm 

    .macro _led_off 
    bset ALARM_LED_ODR,#ALARM_LED_BIT 
    .endm 

    .macro _sound_on 
 	bset TIM2_CCER1,#TIM_CCER1_CC1E
	bset TIM2_CR1,#TIM_CR1_CEN
	bset TIM2_EGR,#TIM_EGR_UG
    .endm 

    .macro _sound_off 
	bres TIM2_CCER1,#TIM_CCER1_CC1E
	bres TIM2_CR1,#TIM_CR1_CEN 
    .endm 

;**********************************************************
        .area DATA (ABS)
        .org RAM_BASE 
;**********************************************************
SAMPLES_SUM: .blkw 1   ; sum of ADC reading  
SAMPLES_MEAN: .blkw 1  ; mean of 32 reading  
CNTDWN: .blkw 1 ; count down timer 
PERIOD: .blkw 1 ; PWM period count 


;**********************************************************
        .area SSEG (ABS) ; STACK
        .org 0x1700
        .ds 256 
; space for DATSTK,TIB and STACK         
;**********************************************************

;**********************************************************
        .area HOME ; vectors table
;**********************************************************
	int cold_start	        ; reset
	int NonHandledInterrupt	; trap
	int NonHandledInterrupt	; irq0
	int NonHandledInterrupt	; irq1
	int NonHandledInterrupt	; irq2
	int NonHandledInterrupt	; irq3
	int NonHandledInterrupt	; irq4
	int NonHandledInterrupt	; irq5
	int NonHandledInterrupt	; irq6
	int NonHandledInterrupt	; irq7
	int NonHandledInterrupt	; irq8
	int NonHandledInterrupt	; irq9
	int NonHandledInterrupt	; irq10
	int NonHandledInterrupt	; irq11
	int NonHandledInterrupt	; irq12
	int NonHandledInterrupt	; irq13
	int NonHandledInterrupt	; irq14
	int NonHandledInterrupt	; irq15
	int NonHandledInterrupt	; irq16
	int NonHandledInterrupt	; irq17
	int NonHandledInterrupt	; irq18
	int NonHandledInterrupt	; irq19
	int NonHandledInterrupt	; irq20
	int NonHandledInterrupt	; irq21
	int NonHandledInterrupt	; irq22
	int Timer4Handler	    ; irq23
	int NonHandledInterrupt	; irq24
	int NonHandledInterrupt	; irq25
	int NonHandledInterrupt	; irq26
	int NonHandledInterrupt	; irq27
	int NonHandledInterrupt	; irq28
	int NonHandledInterrupt	; irq29

;**********************************************************
        .area CODE
;**********************************************************

; non handled interrupt reset MCU
NonHandledInterrupt:
        iret 
;        ld a, #0x80
;        ld WWDG_CR,a ; WWDG_CR used to reset mcu

; used for count down timer 
Timer4Handler:
	clr TIM4_SR 
    ldw x,CNTDWN 
    jreq 1$
    decw x 
    ldw CNTDWN,x 
1$:     
    iret 


; entry point at power up 
; or reset 
cold_start: 

; initialize clock to HSE
; no divisor 12 Mhz crystal  
clock_init:
    clr CLK_CKDIVR
    bres CLK_SWCR,#CLK_SWCR_SWIF 
    mov CLK_SWR,#CLK_SWR_HSE ; 12 Mhz crystal
    btjf CLK_SWCR,#CLK_SWCR_SWIF,. 
	bset CLK_SWCR,#CLK_SWCR_SWEN
; initialize stack pointer 
    ldw x,#RAM_SIZE-1 
    ldw sp,x 
; clear all ram 
1$: clr (x)
    decw x 
    jrne 1$        
; disable all unused peripheral clock
    ld a,#0xB0 ; enable all timers 1,2,4 
    ld CLK_PCKENR1,a 
    ld a,#(1<<3) ; ADC 
    ld CLK_PCKENR2,a 
; activate pull up on all inputs 
; to reduce noise 
	ld a,#255 
	ld PA_CR1,a 
	ld PB_CR1,a
    ld PC_CR1,a  
	ld PD_CR1,a 
	ld PE_CR1,a 
	ld PF_CR1,a 
	ld PG_CR1,a 
; set PC4 as output low 
; this is TIM1_CH4 output 
; want it low when PWM is off     
    bset PC_DDR,#4 ; output mode 
    bres PC_ODR,#4 ; low 
; set alarm LED as output 
    bres ALARM_LED_CR1,#ALARM_LED_BIT ; open drain 
    bset ALRAM_LED_DDR,#ALARM_LED_BIT
    _led_off 
.if DEBUG 
    call uart_init 
.endif     
; initialize timer4, used for millisecond interrupt  
timer4_init: 
	bres TIM4_CR1,#TIM4_CR1_CEN 
	mov TIM4_PSCR,#6 ; prescale 64  
	mov TIM4_ARR,#187 ; for 1msec. 12Mhz/64/1000 
	bset TIM4_IER,#TIM4_IER_UIE 
	mov TIM4_CR1,#(1<<TIM4_CR1_CEN);|(1<<TIM4_CR1_URS)
    bset TIM4_EGR,#TIM4_EGR_UG 
    rim
; initialize TIMER2 for 1Khz tone generator 
timer2_init:
    bres PD_CR1,#4 ; open drain output 
 	mov TIM2_CCMR1,#(6<<TIMx_CCRM1_OC1M) ; PWM mode 1 
	mov TIM2_PSCR,#6 ; 12Mhz/64=187500
    clr TIM2_ARRH 
    mov TIM2_ARRL,#187
    clr TIM2_CCR1H
    mov TIM2_CCR1L,#94
; initialize TIMER1 for PWM generation 
; Fpwm= 50329 Hertz 
    ldw x,#TMR1_PERIOD 
    ldw PERIOD,x 
    clr TIM1_PSCRH
    clr TIM1_PSCRL 
    clr TIM1_ARRH 
    mov TIM1_ARRL,#TMR1_PERIOD ; 12Mhz/50329=158.9
    clr TIM1_CCR4H
    mov TIM1_CCR4L,#TMR1_DC 
    bset TIM1_CCER2,#TIM_CCER2_CC4E 
    mov TIM1_CCMR4,#(6<<4)|(1<<3) ;OC4M=6|OC4PE=1 ; PWM mode 1 
; enable counter 
	bset TIM1_CR1,#TIM_CR1_CEN
	bset TIM1_EGR,#0
; enable ADC 
;    bset ADC_TDRL,#ADC_INPUT
    mov ADC_CR1,#(4<<4) ; ADCclk=Fmaster/8 
    bset ADC_CR2,#ADC_CR2_ALIGN
    bset ADC_CR1,#0 ; turn on ADC  

init_detector: 
; initialize detector 
; by reading 32 samples
; and calculate mean 
.if DEBUG 
    ld a,#27
    call uart_putc
    ld a,#'c 
    call uart_putc 
.endif 
    push #32
    clrw x 
    ldw SAMPLES_SUM,x  
2$: 
    call sample 
    addw x, SAMPLES_SUM
    ldw SAMPLES_SUM, x
    dec (1,sp)
    jrne 2$
    ldw y,#32
    divw x,y 
    ldw SAMPLES_MEAN,x 

.if DEBUG 
    call uart_prt_int
    ld a,#13
    call uart_putc
.endif 
    pop a 

; begin detection 
detector:
    call sample 
    pushw x 
    ldw x,SAMPLES_MEAN 
    subw x,(1,sp)
    jrpl 3$ 
    negw x  
3$: cpw x,#SENSIVITY 
    jrmi 4$ 
.if DEBUG 
call uart_prt_int
.endif 
    call alarm 
4$: 
    ; adjust SAMPLES_MEAN 
    ldw x,SAMPLES_SUM  
    subw x,SAMPLES_MEAN 
    addw x,(1,sp)
    ldw SAMPLES_SUM,x 
    ldw y,#32 
    divw x,y 
    ldw SAMPLES_MEAN,x 
    popw x 
    jra detector 

;----------------------
; detection alarm 
;----------------------
alarm:
    _sound_on 
    _led_on 
    ldw x,#10 
    call pause 
    _led_off 
    _sound_off 
    ret 

;--------------------
;  sample detector 
;--------------------
sample:
    call flush_cap 
    call charge_cap 
    call adc_read  
    ret 


;------------------------
; read ADC sample
; output:
;    X   sample 
;-------------------------
adc_read:
    mov ADC_CSR,#ADC_INPUT 
    bset ADC_CR1,#0
    btjf ADC_CSR,#ADC_CSR_EOC,. 
    ld a,ADC_DRL 
    ld xl,a 
    ld a,ADC_DRH 
    ld xh,a 
    ret 

;------------------------
; charge peak detector 
; capacitor 
;------------------------
charge_cap:
	bset TIM1_BKR,#7 ; enable PWM output   
    ldw x,#9
    call pause 
	bres TIM1_BKR,#7 ; disable PWM output       
    ret 

;------------------------
;  flush peak detector 
;  capacitor C19  
;  pin PB3 
;------------------------
flush_cap: 
    bres ADC_CR1,#ADC_CR1_ADON
    bset PB_DDR,#3 
    bres PB_ODR,#3 
    ldw x,#1 
    call pause 
    bres PB_DDR,#3 
    bset ADC_CR1,#ADC_CR1_ADON 
    ret 

;------------------------
; pause msec 
; input:
;   x    msec 
;------------------------
pause:
    ldw CNTDWN,x 
1$: wfi 
    ldw x,CNTDWN 
    jrne 1$ 
    ret 

.if 0
;--------------------------
; power on signal 
; LED and sound on for 
; 200 milliseconds
;--------------------------
power_on:
    _sound_on 
    _led_on 
    ldw x,#200
    call pause 
    _led_off 
    _sound_off
    ret 
.endif 
