ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 1.
Hexadecimal [24-Bits]



                                      1 ;--------------------
                                      2 ; bare metal version 
                                      3 ; on STM8S103f3m 
                                      4 ; 
                                      5 ; last change: 2023-03-24
                                      6 ;--------------------
                                      7 
                                      8     .module METAL_POINTER 
                                      9 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 2.
Hexadecimal [24-Bits]



                                     10     .include "inc/macros.inc" 
                                      1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                      2 ;; Copyright Jacques Deschênes 2019,2020,2021 
                                      3 ;; This file is part of stm32_eforth  
                                      4 ;;
                                      5 ;;     stm8_eforth is free software: you can redistribute it and/or modify
                                      6 ;;     it under the terms of the GNU General Public License as published by
                                      7 ;;     the Free Software Foundation, either version 3 of the License, or
                                      8 ;;     (at your option) any later version.
                                      9 ;;
                                     10 ;;     stm32_eforth is distributed in the hope that it will be useful,
                                     11 ;;     but WITHOUT ANY WARRANTY;; without even the implied warranty of
                                     12 ;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
                                     13 ;;     GNU General Public License for more details.
                                     14 ;;
                                     15 ;;     You should have received a copy of the GNU General Public License
                                     16 ;;     along with stm32_eforth.  If not, see <http:;;www.gnu.org/licenses/>.
                                     17 ;;;;
                                     18 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     19 
                                     20 ;--------------------------------------
                                     21 ;   console Input/Output module
                                     22 ;   DATE: 2019-12-11
                                     23 ;    
                                     24 ;   General usage macros.   
                                     25 ;
                                     26 ;--------------------------------------
                                     27     
                                     28     ; reserve space on rstack
                                     29     ; for local variabls
                                     30     .macro _VARS n 
                                     31     sub sp,#n 
                                     32     .endm 
                                     33     
                                     34     ; discard space reserved 
                                     35     ; for local vars on rstack 
                                     36     .macro _DROP_VARS n 
                                     37     addw sp,#n
                                     38     .endm 
                                     39 
                                     40     ; declare ARG_OFS for arguments 
                                     41     ; displacement on stack. This 
                                     42     ; value depend on local variables 
                                     43     ; size.
                                     44     .macro _argofs n 
                                     45     ARG_OFS=2+n 
                                     46     .endm 
                                     47 
                                     48     ; declare a function argument 
                                     49     ; position relative to stack pointer 
                                     50     ; _argofs must be called before it.
                                     51     .macro _arg name ofs 
                                     52     name=ARG_OFS+ofs 
                                     53     .endm 
                                     54 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 3.
Hexadecimal [24-Bits]



                                     55     ; macro to create dictionary header record
                                     56     .macro _HEADER label,len,name 
                                     57         .word LINK 
                                     58         LINK=.
                                     59         .byte len  
                                     60         .ascii name
                                     61         label:
                                     62     .endm 
                                     63 
                                     64     ; runtime literal 
                                     65     .macro _DOLIT value 
                                     66     CALL DOLIT 
                                     67     .word value 
                                     68     .endm 
                                     69 
                                     70     ; branch if TOS<>0
                                     71     ; TBRANCH 
                                     72     .macro _TBRAN target 
                                     73     CALL TBRAN 
                                     74     .word target 
                                     75     .endm 
                                     76     
                                     77     ; branch if TOS==0 
                                     78     ; 0BRANCH 
                                     79     .macro _QBRAN target 
                                     80     CALL QBRAN
                                     81     .word target
                                     82     .endm 
                                     83 
                                     84     ; uncondittionnal BRANCH 
                                     85     .macro _BRAN target 
                                     86     JRA target  
                                     87     .endm 
                                     88 
                                     89     ; run time NEXT 
                                     90     .macro _DONXT target 
                                     91     CALL DONXT 
                                     92     .word target 
                                     93     .endm 
                                     94 
                                     95     ; drop TOS 
                                     96     .macro _DROP 
                                     97     ADDW X,#CELLL  
                                     98     .endm 
                                     99   
                                    100    ; drop a double 
                                    101    .macro _DDROP 
                                    102    ADDW X,#2*CELLL 
                                    103    .endm 
                                    104 
                                    105     ; drop n CELLS
                                    106     .macro _DROPN n 
                                    107     ADDW X,#n*CELLL 
                                    108     .endm 
                                    109 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 4.
Hexadecimal [24-Bits]



                                    110    ; drop from rstack 
                                    111    .macro _RDROP 
                                    112    ADDW SP,#CELLL
                                    113    .endm 
                                    114 
                                    115    ; drop double from rstack
                                    116    .macro _DRDROP
                                    117    ADDW SP,#2*CELLL 
                                    118    .endm 
                                    119 
                                    120    ; test point, print character 
                                    121    ; and stack contain
                                    122    .macro _TP c 
                                    123    .if DEBUG 
                                    124    LD A,#c 
                                    125    CALL putc
                                    126    CALL DOTS 
                                    127    .endif  
                                    128    .endm 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 5.
Hexadecimal [24-Bits]



                                     11     .include "inc/stm8s103f3.inc"
                                      1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                      2 ;; Copyright Jacques Deschênes 2019,2020,2021 
                                      3 ;; This file is part of stm32_eforth  
                                      4 ;;
                                      5 ;;     stm8_eforth is free software: you can redistribute it and/or modify
                                      6 ;;     it under the terms of the GNU General Public License as published by
                                      7 ;;     the Free Software Foundation, either version 3 of the License, or
                                      8 ;;     (at your option) any later version.
                                      9 ;;
                                     10 ;;     stm32_eforth is distributed in the hope that it will be useful,
                                     11 ;;     but WITHOUT ANY WARRANTY;; without even the implied warranty of
                                     12 ;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
                                     13 ;;     GNU General Public License for more details.
                                     14 ;;
                                     15 ;;     You should have received a copy of the GNU General Public License
                                     16 ;;     along with stm32_eforth.  If not, see <http:;;www.gnu.org/licenses/>.
                                     17 ;;;;
                                     18 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     19 
                                     20 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     21 ; 2019/04/26
                                     22 ; STM8S105x4/6 µC registers map
                                     23 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     24 	.module stm8s105c6
                                     25 	
                                     26 ;;;;;;;;;;
                                     27 ; bit mask
                                     28 ;;;;;;;;;;
                           000000    29  BIT0 = (0)
                           000001    30  BIT1 = (1)
                           000002    31  BIT2 = (2)
                           000003    32  BIT3 = (3)
                           000004    33  BIT4 = (4)
                           000005    34  BIT5 = (5)
                           000006    35  BIT6 = (6)
                           000007    36  BIT7 = (7)
                                     37 
                                     38 ; controller memory regions
                           000400    39 RAM_SIZE = (1024) 
                           000280    40 EEPROM_SIZE = (640) 
                           002000    41 FLASH_SIZE = (8192)
                                     42 
                           000000    43  RAM_BASE = (0)
                           0003FF    44  RAM_END = (RAM_BASE+RAM_SIZE-1)
                           004000    45  EEPROM_BASE = (0x4000)
                           00427F    46  EEPROM_END = (EEPROM_BASE+EEPROM_SIZE-1)
                           005000    47  SFR_BASE = (0x5000)
                           0057FF    48  SFR_END = (0x57FF)
                           008000    49  FLASH_BASE = (0x8000)
                           004800    50  OPTION_BASE = (0x4800)
                           00480A    51  OPTION_END = (0x480A)
                           004865    52  DEVID_BASE = (0x4865)
                           004870    53  DEVID_END = (0x4870)
                           000040    54  BLOCK_SIZE = 64 ; flash|eeprom block size
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 6.
Hexadecimal [24-Bits]



                           004000    55 GPIO_BASE = (0x4000)
                           0057FF    56 GPIO_END = (0x57ff)
                                     57 
                                     58 ; options bytes
                                     59 ; this one can be programmed only from SWIM  (ICP)
                           004800    60  OPT0  = (0x4800)
                                     61 ; these can be programmed at runtime (IAP)
                           004801    62  OPT1  = (0x4801)
                           004802    63  NOPT1  = (0x4802)
                           004803    64  OPT2  = (0x4803)
                           004804    65  NOPT2  = (0x4804)
                           004805    66  OPT3  = (0x4805)
                           004806    67  NOPT3  = (0x4806)
                           004807    68  OPT4  = (0x4807)
                           004808    69  NOPT4  = (0x4808)
                           004809    70  OPT5  = (0x4809)
                           00480A    71  NOPT5  = (0x480A)
                                     72 ; option registers usage
                                     73 ; read out protection, value 0xAA enable ROP
                           004800    74  ROP = OPT0  
                                     75 ; user boot code, {0..0x3e} 512 bytes row
                           004801    76  UBC = OPT1
                           004802    77  NUBC = NOPT1
                                     78 ; alternate function register
                           004803    79  AFR = OPT2
                           004804    80  NAFR = NOPT2
                                     81 ; miscelinous options
                           004805    82  MISCOPT = OPT3
                           004806    83  NMISCOPT = NOPT3
                                     84 ; clock options
                           004807    85  CLKOPT = OPT4
                           004808    86  NCLKOPT = NOPT4
                                     87 ; HSE clock startup delay
                           004809    88  HSECNT = OPT5
                           00480A    89  NHSECNT = NOPT5
                                     90 
                                     91 ; MISCOPT bits
                           000004    92   MISCOPT_HSITRIM =  BIT4
                           000003    93   MISCOPT_LSIEN   =  BIT3
                           000002    94   MISCOPT_IWDG_HW =  BIT2
                           000001    95   MISCOPT_WWDG_HW =  BIT1
                           000000    96   MISCOPT_WWDG_HALT = BIT0
                                     97 ; NMISCOPT bits
                           FFFFFFFB    98   NMISCOPT_NHSITRIM  = ~BIT4
                           FFFFFFFC    99   NMISCOPT_NLSIEN    = ~BIT3
                           FFFFFFFD   100   NMISCOPT_NIWDG_HW  = ~BIT2
                           FFFFFFFE   101   NMISCOPT_NWWDG_HW  = ~BIT1
                           FFFFFFFF   102   NMISCOPT_NWWDG_HALT = ~BIT0
                                    103 ; CLKOPT bits
                           000003   104  CLKOPT_EXT_CLK  = BIT3
                           000002   105  CLKOPT_CKAWUSEL = BIT2
                           000001   106  CLKOPT_PRS_C1   = BIT1
                           000000   107  CLKOPT_PRS_C0   = BIT0
                                    108 
                                    109 ; AFR option, remapable functions
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 7.
Hexadecimal [24-Bits]



                           000007   110  AFR7 = BIT7 ;Port C3 = TIM1_CH1N; port C4 = TIM1_CH2N.
                           000006   111  AFR6 = BIT6 ;reserved  
                           000005   112  AFR5 = BIT5 ;reserved 
                           000004   113  AFR4 = BIT4 ;Port B4 = ADC1_ETR; port B5 =TIM1_BKIN
                           000003   114  AFR3 = BIT3 ;Port C3 = TLI
                           000002   115  AFR2 = BIT2 ;reserved
                           000001   116  AFR1 = BIT1 ;Port A3 = SPI_NSS; port D2 =TIM2_CH3
                           000000   117  AFR0 = BIT0 ;Port C5 = TIM2_CH1; port C6 =TIM1_CH1; port C7 = TIM1_CH2
                                    118 
                                    119 ; device ID = (read only)
                           0048CD   120  DEVID_XL  = (0x48CD)
                           0048CE   121  DEVID_XH  = (0x48CE)
                           0048CF   122  DEVID_YL  = (0x48CF)
                           0048D0   123  DEVID_YH  = (0x48D0)
                           0048D1   124  DEVID_WAF  = (0x48D1)
                           0048D2   125  DEVID_LOT0  = (0x48D2)
                           0048D3   126  DEVID_LOT1  = (0x48D3)
                           0048D4   127  DEVID_LOT2  = (0x48D4)
                           0048D5   128  DEVID_LOT3  = (0x48D5)
                           0048D6   129  DEVID_LOT4  = (0x48D6)
                           0048D7   130  DEVID_LOT5  = (0x48D7)
                           0048D8   131  DEVID_LOT6  = (0x48D8)
                                    132 
                                    133 
                                    134 ; port bit
                           000000   135  PIN0 = (0)
                           000001   136  PIN1 = (1)
                           000002   137  PIN2 = (2)
                           000003   138  PIN3 = (3)
                           000004   139  PIN4 = (4)
                           000005   140  PIN5 = (5)
                           000006   141  PIN6 = (6)
                           000007   142  PIN7 = (7)
                                    143 
                           005000   144 GPIO_BASE = (0x5000)
                           000005   145 GPIO_SIZE = (5)
                                    146 ; PORTS SFR OFFSET
                           000000   147 PA = 0
                           000005   148 PB = 5
                           00000A   149 PC = 10
                           00000F   150 PD = 15
                           000014   151 PE = 20
                           000019   152 PF = 25
                                    153 
                                    154 ; GPIO
                           005000   155  PA_ODR  = (0x5000)
                           005001   156  PA_IDR  = (0x5001)
                           005002   157  PA_DDR  = (0x5002)
                           005003   158  PA_CR1  = (0x5003)
                           005004   159  PA_CR2  = (0x5004)
                                    160 
                           005005   161  PB_ODR  = (0x5005)
                           005006   162  PB_IDR  = (0x5006)
                           005007   163  PB_DDR  = (0x5007)
                           005008   164  PB_CR1  = (0x5008)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 8.
Hexadecimal [24-Bits]



                           005009   165  PB_CR2  = (0x5009)
                                    166 
                           00500A   167  PC_ODR  = (0x500A)
                           00500B   168  PC_IDR  = (0x500B)
                           00500C   169  PC_DDR  = (0x500C)
                           00500D   170  PC_CR1  = (0x500D)
                           00500E   171  PC_CR2  = (0x500E)
                                    172 
                           00500F   173  PD_ODR  = (0x500F)
                           005010   174  PD_IDR  = (0x5010)
                           005011   175  PD_DDR  = (0x5011)
                           005012   176  PD_CR1  = (0x5012)
                           005013   177  PD_CR2  = (0x5013)
                                    178 
                           005014   179  PE_ODR  = (0x5014)
                           005015   180  PE_IDR  = (0x5015)
                           005016   181  PE_DDR  = (0x5016)
                           005017   182  PE_CR1  = (0x5017)
                           005018   183  PE_CR2  = (0x5018)
                                    184 
                           005019   185  PF_ODR  = (0x5019)
                           00501A   186  PF_IDR  = (0x501A)
                           00501B   187  PF_DDR  = (0x501B)
                           00501C   188  PF_CR1  = (0x501C)
                           00501D   189  PF_CR2  = (0x501D)
                                    190 
                                    191  ; input modes CR1
                           000000   192  INPUT_FLOAT = (0)
                           000001   193  INPUT_PULLUP = (1)
                                    194 ; output mode CR1
                           000000   195  OUTPUT_OD = (0)
                           000001   196  OUTPUT_PP = (1)
                                    197 ; input modes CR2
                           000000   198  INPUT_DI = (0)
                           000001   199  INPUT_EI = (1)
                                    200 ; output speed CR2
                           000000   201  OUTPUT_SLOW = (0)
                           000001   202  OUTPUT_FAST = (1)
                                    203 
                                    204 
                                    205 ; Flash
                           00505A   206  FLASH_CR1  = (0x505A)
                           00505B   207  FLASH_CR2  = (0x505B)
                           00505C   208  FLASH_NCR2  = (0x505C)
                           00505D   209  FLASH_FPR  = (0x505D)
                           00505E   210  FLASH_NFPR  = (0x505E)
                           00505F   211  FLASH_IAPSR  = (0x505F)
                           005062   212  FLASH_PUKR  = (0x5062)
                           005064   213  FLASH_DUKR  = (0x5064)
                                    214 ; data memory unlock keys
                           0000AE   215  FLASH_DUKR_KEY1 = (0xae)
                           000056   216  FLASH_DUKR_KEY2 = (0x56)
                                    217 ; flash memory unlock keys
                           000056   218  FLASH_PUKR_KEY1 = (0x56)
                           0000AE   219  FLASH_PUKR_KEY2 = (0xae)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 9.
Hexadecimal [24-Bits]



                                    220 ; FLASH_CR1 bits
                           000003   221  FLASH_CR1_HALT = BIT3
                           000002   222  FLASH_CR1_AHALT = BIT2
                           000001   223  FLASH_CR1_IE = BIT1
                           000000   224  FLASH_CR1_FIX = BIT0
                                    225 ; FLASH_CR2 bits
                           000007   226  FLASH_CR2_OPT = BIT7
                           000006   227  FLASH_CR2_WPRG = BIT6
                           000005   228  FLASH_CR2_ERASE = BIT5
                           000004   229  FLASH_CR2_FPRG = BIT4
                           000000   230  FLASH_CR2_PRG = BIT0
                                    231 ; FLASH_FPR bits
                           000005   232  FLASH_FPR_WPB5 = BIT5
                           000004   233  FLASH_FPR_WPB4 = BIT4
                           000003   234  FLASH_FPR_WPB3 = BIT3
                           000002   235  FLASH_FPR_WPB2 = BIT2
                           000001   236  FLASH_FPR_WPB1 = BIT1
                           000000   237  FLASH_FPR_WPB0 = BIT0
                                    238 ; FLASH_NFPR bits
                           000005   239  FLASH_NFPR_NWPB5 = BIT5
                           000004   240  FLASH_NFPR_NWPB4 = BIT4
                           000003   241  FLASH_NFPR_NWPB3 = BIT3
                           000002   242  FLASH_NFPR_NWPB2 = BIT2
                           000001   243  FLASH_NFPR_NWPB1 = BIT1
                           000000   244  FLASH_NFPR_NWPB0 = BIT0
                                    245 ; FLASH_IAPSR bits
                           000006   246  FLASH_IAPSR_HVOFF = BIT6
                           000003   247  FLASH_IAPSR_DUL = BIT3
                           000002   248  FLASH_IAPSR_EOP = BIT2
                           000001   249  FLASH_IAPSR_PUL = BIT1
                           000000   250  FLASH_IAPSR_WR_PG_DIS = BIT0
                                    251 
                                    252 ; Interrupt control
                           0050A0   253  EXTI_CR1  = (0x50A0)
                           0050A1   254  EXTI_CR2  = (0x50A1)
                                    255 
                                    256 ; Reset Status
                           0050B3   257  RST_SR  = (0x50B3)
                                    258 
                                    259 ; Clock Registers
                           0050C0   260  CLK_ICKR  = (0x50c0)
                           0050C1   261  CLK_ECKR  = (0x50c1)
                           0050C3   262  CLK_CMSR  = (0x50C3)
                           0050C4   263  CLK_SWR  = (0x50C4)
                           0050C5   264  CLK_SWCR  = (0x50C5)
                           0050C6   265  CLK_CKDIVR  = (0x50C6)
                           0050C7   266  CLK_PCKENR1  = (0x50C7)
                           0050C8   267  CLK_CSSR  = (0x50C8)
                           0050C9   268  CLK_CCOR  = (0x50C9)
                           0050CA   269  CLK_PCKENR2  = (0x50CA)
                           0050CC   270  CLK_HSITRIMR  = (0x50CC)
                           0050CD   271  CLK_SWIMCCR  = (0x50CD)
                                    272 
                                    273 ; Peripherals clock gating
                                    274 ; CLK_PCKENR1 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 10.
Hexadecimal [24-Bits]



                           000007   275  CLK_PCKENR1_TIM1 = (7)
                           000005   276  CLK_PCKENR1_TIM2 = (5)
                           000004   277  CLK_PCKENR1_TIM4 = (4)
                           000003   278  CLK_PCKENR1_UART1 = (3)
                           000001   279  CLK_PCKENR1_SPI = (1)
                           000000   280  CLK_PCKENR1_I2C = (0)
                                    281 ; CLK_PCKENR2
                           000003   282  CLK_PCKENR2_ADC1 = (3)
                           000002   283  CLK_PCKENR2_AWU = (2)
                                    284 
                                    285 ; Clock bits
                           000005   286  CLK_ICKR_REGAH = (5)
                           000004   287  CLK_ICKR_LSIRDY = (4)
                           000003   288  CLK_ICKR_LSIEN = (3)
                           000002   289  CLK_ICKR_FHW = (2)
                           000001   290  CLK_ICKR_HSIRDY = (1)
                           000000   291  CLK_ICKR_HSIEN = (0)
                                    292 
                           000001   293  CLK_ECKR_HSERDY = (1)
                           000000   294  CLK_ECKR_HSEEN = (0)
                                    295 ; clock source
                           0000E1   296  CLK_SWR_HSI = 0xE1
                           0000D2   297  CLK_SWR_LSI = 0xD2
                           0000B4   298  CLK_SWR_HSE = 0xB4
                                    299 
                           000003   300  CLK_SWCR_SWIF = (3)
                           000002   301  CLK_SWCR_SWIEN = (2)
                           000001   302  CLK_SWCR_SWEN = (1)
                           000000   303  CLK_SWCR_SWBSY = (0)
                                    304 
                           000004   305  CLK_CKDIVR_HSIDIV1 = (4)
                           000003   306  CLK_CKDIVR_HSIDIV0 = (3)
                           000002   307  CLK_CKDIVR_CPUDIV2 = (2)
                           000001   308  CLK_CKDIVR_CPUDIV1 = (1)
                           000000   309  CLK_CKDIVR_CPUDIV0 = (0)
                                    310 
                                    311 ; Watchdog
                           0050D1   312  WWDG_CR  = (0x50D1)
                           0050D2   313  WWDG_WR  = (0x50D2)
                           0050E0   314  IWDG_KR  = (0x50E0)
                           0050E1   315  IWDG_PR  = (0x50E1)
                           0050E2   316  IWDG_RLR  = (0x50E2)
                           0050F0   317  AWU_CSR1  = (0x50F0)
                           0050F1   318  AWU_APR  = (0x50F1)
                           0050F2   319  AWU_TBR  = (0x50F2)
                                    320 
                                    321 ; Beep
                           0050F3   322  BEEP_CSR  = (0x50F3)
                                    323 
                                    324 ; SPI
                           005200   325  SPI_CR1  = (0x5200)
                           005201   326  SPI_CR2  = (0x5201)
                           005202   327  SPI_ICR  = (0x5202)
                           005203   328  SPI_SR  = (0x5203)
                           005204   329  SPI_DR  = (0x5204)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 11.
Hexadecimal [24-Bits]



                           005205   330  SPI_CRCPR  = (0x5205)
                           005206   331  SPI_RXCRCR  = (0x5206)
                           005207   332  SPI_TXCRCR  = (0x5207)
                                    333 
                                    334 ; I2C
                           005210   335  I2C_CR1  = (0x5210)
                           005211   336  I2C_CR2  = (0x5211)
                           005212   337  I2C_FREQR  = (0x5212)
                           005213   338  I2C_OARL  = (0x5213)
                           005214   339  I2C_OARH  = (0x5214)
                           005216   340  I2C_DR  = (0x5216)
                           005217   341  I2C_SR1  = (0x5217)
                           005218   342  I2C_SR2  = (0x5218)
                           005219   343  I2C_SR3  = (0x5219)
                           00521A   344  I2C_ITR  = (0x521A)
                           00521B   345  I2C_CCRL  = (0x521B)
                           00521C   346  I2C_CCRH  = (0x521C)
                           00521D   347  I2C_TRISER  = (0x521D)
                           00521E   348  I2C_PECR  = (0x521E)
                                    349 
                           000007   350  I2C_CR1_NOSTRETCH = (7)
                           000006   351  I2C_CR1_ENGC = (6)
                           000000   352  I2C_CR1_PE = (0)
                                    353 
                           000007   354  I2C_CR2_SWRST = (7)
                           000003   355  I2C_CR2_POS = (3)
                           000002   356  I2C_CR2_ACK = (2)
                           000001   357  I2C_CR2_STOP = (1)
                           000000   358  I2C_CR2_START = (0)
                                    359 
                           000000   360  I2C_OARL_ADD0 = (0)
                                    361 
                           000009   362  I2C_OAR_ADDR_7BIT = ((I2C_OARL & 0xFE) >> 1)
                           000813   363  I2C_OAR_ADDR_10BIT = (((I2C_OARH & 0x06) << 9) | (I2C_OARL & 0xFF))
                                    364 
                           000007   365  I2C_OARH_ADDMODE = (7)
                           000006   366  I2C_OARH_ADDCONF = (6)
                           000002   367  I2C_OARH_ADD9 = (2)
                           000001   368  I2C_OARH_ADD8 = (1)
                                    369 
                           000007   370  I2C_SR1_TXE = (7)
                           000006   371  I2C_SR1_RXNE = (6)
                           000004   372  I2C_SR1_STOPF = (4)
                           000003   373  I2C_SR1_ADD10 = (3)
                           000002   374  I2C_SR1_BTF = (2)
                           000001   375  I2C_SR1_ADDR = (1)
                           000000   376  I2C_SR1_SB = (0)
                                    377 
                           000005   378  I2C_SR2_WUFH = (5)
                           000003   379  I2C_SR2_OVR = (3)
                           000002   380  I2C_SR2_AF = (2)
                           000001   381  I2C_SR2_ARLO = (1)
                           000000   382  I2C_SR2_BERR = (0)
                                    383 
                           000007   384  I2C_SR3_DUALF = (7)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 12.
Hexadecimal [24-Bits]



                           000004   385  I2C_SR3_GENCALL = (4)
                           000002   386  I2C_SR3_TRA = (2)
                           000001   387  I2C_SR3_BUSY = (1)
                           000000   388  I2C_SR3_MSL = (0)
                                    389 
                           000002   390  I2C_ITR_ITBUFEN = (2)
                           000001   391  I2C_ITR_ITEVTEN = (1)
                           000000   392  I2C_ITR_ITERREN = (0)
                                    393 
                                    394 ; Precalculated values, all in KHz
                           000080   395  I2C_CCRH_16MHZ_FAST_400 = 0x80
                           00000D   396  I2C_CCRL_16MHZ_FAST_400 = 0x0D
                                    397 ;
                                    398 ; Fast I2C mode max rise time = 300ns
                                    399 ; I2C_FREQR = 16 = (MHz) => tMASTER = 1/16 = 62.5 ns
                                    400 ; TRISER = = (300/62.5) + 1 = floor(4.8) + 1 = 5.
                                    401 
                           000005   402  I2C_TRISER_16MHZ_FAST_400 = 0x05
                                    403 
                           0000C0   404  I2C_CCRH_16MHZ_FAST_320 = 0xC0
                           000002   405  I2C_CCRL_16MHZ_FAST_320 = 0x02
                           000005   406  I2C_TRISER_16MHZ_FAST_320 = 0x05
                                    407 
                           000080   408  I2C_CCRH_16MHZ_FAST_200 = 0x80
                           00001A   409  I2C_CCRL_16MHZ_FAST_200 = 0x1A
                           000005   410  I2C_TRISER_16MHZ_FAST_200 = 0x05
                                    411 
                           000000   412  I2C_CCRH_16MHZ_STD_100 = 0x00
                           000050   413  I2C_CCRL_16MHZ_STD_100 = 0x50
                                    414 ;
                                    415 ; Standard I2C mode max rise time = 1000ns
                                    416 ; I2C_FREQR = 16 = (MHz) => tMASTER = 1/16 = 62.5 ns
                                    417 ; TRISER = = (1000/62.5) + 1 = floor(16) + 1 = 17.
                                    418 
                           000011   419  I2C_TRISER_16MHZ_STD_100 = 0x11
                                    420 
                           000000   421  I2C_CCRH_16MHZ_STD_50 = 0x00
                           0000A0   422  I2C_CCRL_16MHZ_STD_50 = 0xA0
                           000011   423  I2C_TRISER_16MHZ_STD_50 = 0x11
                                    424 
                           000001   425  I2C_CCRH_16MHZ_STD_20 = 0x01
                           000090   426  I2C_CCRL_16MHZ_STD_20 = 0x90
                           000011   427  I2C_TRISER_16MHZ_STD_20 = 0x11;
                                    428 
                           000001   429  I2C_READ = 1
                           000000   430  I2C_WRITE = 0
                                    431 
                                    432 ; baudrate constant for brr_value table access
                           000000   433 B2400=0
                           000001   434 B4800=1
                           000002   435 B9600=2
                           000003   436 B19200=3
                           000004   437 B38400=4
                           000005   438 B57600=5
                           000006   439 B115200=6
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 13.
Hexadecimal [24-Bits]



                           000007   440 B230400=7
                           000008   441 B460800=8
                           000009   442 B921600=9
                                    443 
                                    444 ; UART1
                           005230   445  UART1_SR    = (0x5230)
                           005231   446  UART1_DR    = (0x5231)
                           005232   447  UART1_BRR1  = (0x5232)
                           005233   448  UART1_BRR2  = (0x5233)
                           005234   449  UART1_CR1   = (0x5234)
                           005235   450  UART1_CR2   = (0x5235)
                           005236   451  UART1_CR3   = (0x5236)
                           005237   452  UART1_CR4   = (0x5237)
                           005238   453  UART1_CR5   = (0x5238)
                           005239   454  UART1_GTR   = (0x5239)
                           00523A   455  UART1_PSCR  = (0x523A)
                                    456 
                           000002   457  UART1_TX_PIN = 2 ; PD5
                           000003   458  UART1_RX_PIN = 3 ; PD6 
                           00500F   459  UART1_PORT = GPIO_BASE+PD 
                                    460 
                                    461 ; UART Status Register bits
                           000007   462  UART_SR_TXE = (7)
                           000006   463  UART_SR_TC = (6)
                           000005   464  UART_SR_RXNE = (5)
                           000004   465  UART_SR_IDLE = (4)
                           000003   466  UART_SR_OR = (3)
                           000002   467  UART_SR_NF = (2)
                           000001   468  UART_SR_FE = (1)
                           000000   469  UART_SR_PE = (0)
                                    470 
                                    471 ; Uart Control Register bits
                           000007   472  UART_CR1_R8 = (7)
                           000006   473  UART_CR1_T8 = (6)
                           000005   474  UART_CR1_UARTD = (5)
                           000004   475  UART_CR1_M = (4)
                           000003   476  UART_CR1_WAKE = (3)
                           000002   477  UART_CR1_PCEN = (2)
                           000001   478  UART_CR1_PS = (1)
                           000000   479  UART_CR1_PIEN = (0)
                                    480 
                           000007   481  UART_CR2_TIEN = (7)
                           000006   482  UART_CR2_TCIEN = (6)
                           000005   483  UART_CR2_RIEN = (5)
                           000004   484  UART_CR2_ILIEN = (4)
                           000003   485  UART_CR2_TEN = (3)
                           000002   486  UART_CR2_REN = (2)
                           000001   487  UART_CR2_RWU = (1)
                           000000   488  UART_CR2_SBK = (0)
                                    489 
                           000006   490  UART_CR3_LINEN = (6)
                           000005   491  UART_CR3_STOP1 = (5)
                           000004   492  UART_CR3_STOP0 = (4)
                           000003   493  UART_CR3_CLKEN = (3)
                           000002   494  UART_CR3_CPOL = (2)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 14.
Hexadecimal [24-Bits]



                           000001   495  UART_CR3_CPHA = (1)
                           000000   496  UART_CR3_LBCL = (0)
                                    497 
                           000006   498  UART_CR4_LBDIEN = (6)
                           000005   499  UART_CR4_LBDL = (5)
                           000004   500  UART_CR4_LBDF = (4)
                           000003   501  UART_CR4_ADD3 = (3)
                           000002   502  UART_CR4_ADD2 = (2)
                           000001   503  UART_CR4_ADD1 = (1)
                           000000   504  UART_CR4_ADD0 = (0)
                                    505 
                           000005   506  UART_CR5_SCEN = (5)
                           000004   507  UART_CR5_NACK = (4)
                           000003   508  UART_CR5_HDSEL = (3)
                           000002   509  UART_CR5_IRLP = (2)
                           000001   510  UART_CR5_IREN = (1)
                                    511 
                                    512 ; TIMERS
                                    513 ; Timer 1 - 16-bit timer with complementary PWM outputs
                           005250   514  TIM1_CR1  = (0x5250)
                           005251   515  TIM1_CR2  = (0x5251)
                           005252   516  TIM1_SMCR  = (0x5252)
                           005253   517  TIM1_ETR  = (0x5253)
                           005254   518  TIM1_IER  = (0x5254)
                           005255   519  TIM1_SR1  = (0x5255)
                           005256   520  TIM1_SR2  = (0x5256)
                           005257   521  TIM1_EGR  = (0x5257)
                           005258   522  TIM1_CCMR1  = (0x5258)
                           005259   523  TIM1_CCMR2  = (0x5259)
                           00525A   524  TIM1_CCMR3  = (0x525A)
                           00525B   525  TIM1_CCMR4  = (0x525B)
                           00525C   526  TIM1_CCER1  = (0x525C)
                           00525D   527  TIM1_CCER2  = (0x525D)
                           00525E   528  TIM1_CNTRH  = (0x525E)
                           00525F   529  TIM1_CNTRL  = (0x525F)
                           005260   530  TIM1_PSCRH  = (0x5260)
                           005261   531  TIM1_PSCRL  = (0x5261)
                           005262   532  TIM1_ARRH  = (0x5262)
                           005263   533  TIM1_ARRL  = (0x5263)
                           005264   534  TIM1_RCR  = (0x5264)
                           005265   535  TIM1_CCR1H  = (0x5265)
                           005266   536  TIM1_CCR1L  = (0x5266)
                           005267   537  TIM1_CCR2H  = (0x5267)
                           005268   538  TIM1_CCR2L  = (0x5268)
                           005269   539  TIM1_CCR3H  = (0x5269)
                           00526A   540  TIM1_CCR3L  = (0x526A)
                           00526B   541  TIM1_CCR4H  = (0x526B)
                           00526C   542  TIM1_CCR4L  = (0x526C)
                           00526D   543  TIM1_BKR  = (0x526D)
                           00526E   544  TIM1_DTR  = (0x526E)
                           00526F   545  TIM1_OISR  = (0x526F)
                                    546 
                                    547 ; Timer Control Register bits
                           000007   548  TIM_CR1_ARPE = (7)
                           000006   549  TIM_CR1_CMSH = (6)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 15.
Hexadecimal [24-Bits]



                           000005   550  TIM_CR1_CMSL = (5)
                           000004   551  TIM_CR1_DIR = (4)
                           000003   552  TIM_CR1_OPM = (3)
                           000002   553  TIM_CR1_URS = (2)
                           000001   554  TIM_CR1_UDIS = (1)
                           000000   555  TIM_CR1_CEN = (0)
                                    556 
                           000006   557  TIM1_CR2_MMS2 = (6)
                           000005   558  TIM1_CR2_MMS1 = (5)
                           000004   559  TIM1_CR2_MMS0 = (4)
                           000002   560  TIM1_CR2_COMS = (2)
                           000000   561  TIM1_CR2_CCPC = (0)
                                    562 
                                    563 ; Timer Slave Mode Control bits
                           000007   564  TIM1_SMCR_MSM = (7)
                           000006   565  TIM1_SMCR_TS2 = (6)
                           000005   566  TIM1_SMCR_TS1 = (5)
                           000004   567  TIM1_SMCR_TS0 = (4)
                           000002   568  TIM1_SMCR_SMS2 = (2)
                           000001   569  TIM1_SMCR_SMS1 = (1)
                           000000   570  TIM1_SMCR_SMS0 = (0)
                                    571 
                                    572 ; Timer External Trigger Enable bits
                           000007   573  TIM1_ETR_ETP = (7)
                           000006   574  TIM1_ETR_ECE = (6)
                           000005   575  TIM1_ETR_ETPS1 = (5)
                           000004   576  TIM1_ETR_ETPS0 = (4)
                           000003   577  TIM1_ETR_ETF3 = (3)
                           000002   578  TIM1_ETR_ETF2 = (2)
                           000001   579  TIM1_ETR_ETF1 = (1)
                           000000   580  TIM1_ETR_ETF0 = (0)
                                    581 
                                    582 ; Timer Interrupt Enable bits
                           000007   583  TIM1_IER_BIE = (7)
                           000006   584  TIM1_IER_TIE = (6)
                           000005   585  TIM1_IER_COMIE = (5)
                           000004   586  TIM1_IER_CC4IE = (4)
                           000003   587  TIM1_IER_CC3IE = (3)
                           000002   588  TIM1_IER_CC2IE = (2)
                           000001   589  TIM1_IER_CC1IE = (1)
                           000000   590  TIM1_IER_UIE = (0)
                                    591 
                                    592 ; Timer Status Register bits
                           000007   593  TIM1_SR1_BIF = (7)
                           000006   594  TIM1_SR1_TIF = (6)
                           000005   595  TIM1_SR1_COMIF = (5)
                           000004   596  TIM1_SR1_CC4IF = (4)
                           000003   597  TIM1_SR1_CC3IF = (3)
                           000002   598  TIM1_SR1_CC2IF = (2)
                           000001   599  TIM1_SR1_CC1IF = (1)
                           000000   600  TIM1_SR1_UIF = (0)
                                    601 
                           000004   602  TIM1_SR2_CC4OF = (4)
                           000003   603  TIM1_SR2_CC3OF = (3)
                           000002   604  TIM1_SR2_CC2OF = (2)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 16.
Hexadecimal [24-Bits]



                           000001   605  TIM1_SR2_CC1OF = (1)
                                    606 
                                    607 ; Timer Event Generation Register bits
                           000007   608  TIM_EGR_BG = (7)
                           000006   609  TIM_EGR_TG = (6)
                           000005   610  TIM_EGR_COMG = (5)
                           000004   611  TIM_EGR_CC4G = (4)
                           000003   612  TIM_EGR_CC3G = (3)
                           000002   613  TIM_EGR_CC2G = (2)
                           000001   614  TIM_EGR_CC1G = (1)
                           000000   615  TIM_EGR_UG = (0)
                                    616 
                                    617 ; timer capture compare enable register 
                                    618 ; bit fields 
                           000000   619 TIM_CCER1_CC1E=0 
                           000001   620 TIM_CCER1_CC1P=1 
                           000002   621 TIM_CCER1_CC1NE=2
                           000003   622 TIM_CCER1_CC2NP=3
                           000004   623 TIM_CCER1_CC2E=4 
                           000005   624 TIM_CCER1_CC2P=5
                           000006   625 TIM_CCER1_CC2NE=6
                           000007   626 TIM_CCER1_CC2NP=7
                           000000   627 TIM_CCER2_CC3E=0 
                           000001   628 TIM_CCER2_CC3P=1 
                           000002   629 TIM_CCER2_CC2NE=2
                           000003   630 TIM_CCER2_CC2NP=3
                           000004   631 TIM_CCER2_CC4E=4
                           000005   632 TIM_CCER2_CC4P=5 
                                    633 
                                    634 
                                    635 ; Capture/Compare Mode Register 1 - channel configured in output
                           000007   636  TIM1_CCMR1_OC1CE = (7)
                           000006   637  TIM1_CCMR1_OC1M2 = (6)
                           000005   638  TIM1_CCMR1_OC1M1 = (5)
                           000004   639  TIM1_CCMR1_OC1M0 = (4)
                           000003   640  TIM1_CCMR1_OC1PE = (3)
                           000002   641  TIM1_CCMR1_OC1FE = (2)
                           000001   642  TIM1_CCMR1_CC1S1 = (1)
                           000000   643  TIM1_CCMR1_CC1S0 = (0)
                                    644 
                                    645 ; Capture/Compare Mode Register 1 - channel configured in input
                           000007   646  TIM1_CCMR1_IC1F3 = (7)
                           000006   647  TIM1_CCMR1_IC1F2 = (6)
                           000005   648  TIM1_CCMR1_IC1F1 = (5)
                           000004   649  TIM1_CCMR1_IC1F0 = (4)
                           000003   650  TIM1_CCMR1_IC1PSC1 = (3)
                           000002   651  TIM1_CCMR1_IC1PSC0 = (2)
                                    652 ;  TIM1_CCMR1_CC1S1 = (1)
                           000000   653  TIM1_CCMR1_CC1S0 = (0)
                                    654 
                                    655 ; Capture/Compare Mode Register 2 - channel configured in output
                           000007   656  TIM1_CCMR2_OC2CE = (7)
                           000006   657  TIM1_CCMR2_OC2M2 = (6)
                           000005   658  TIM1_CCMR2_OC2M1 = (5)
                           000004   659  TIM1_CCMR2_OC2M0 = (4)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 17.
Hexadecimal [24-Bits]



                           000003   660  TIM1_CCMR2_OC2PE = (3)
                           000002   661  TIM1_CCMR2_OC2FE = (2)
                           000001   662  TIM1_CCMR2_CC2S1 = (1)
                           000000   663  TIM1_CCMR2_CC2S0 = (0)
                                    664 
                                    665 ; Capture/Compare Mode Register 2 - channel configured in input
                           000007   666  TIM1_CCMR2_IC2F3 = (7)
                           000006   667  TIM1_CCMR2_IC2F2 = (6)
                           000005   668  TIM1_CCMR2_IC2F1 = (5)
                           000004   669  TIM1_CCMR2_IC2F0 = (4)
                           000003   670  TIM1_CCMR2_IC2PSC1 = (3)
                           000002   671  TIM1_CCMR2_IC2PSC0 = (2)
                                    672 ;  TIM1_CCMR2_CC2S1 = (1)
                           000000   673  TIM1_CCMR2_CC2S0 = (0)
                                    674 
                                    675 ; Capture/Compare Mode Register 3 - channel configured in output
                           000007   676  TIM1_CCMR3_OC3CE = (7)
                           000006   677  TIM1_CCMR3_OC3M2 = (6)
                           000005   678  TIM1_CCMR3_OC3M1 = (5)
                           000004   679  TIM1_CCMR3_OC3M0 = (4)
                           000003   680  TIM1_CCMR3_OC3PE = (3)
                           000002   681  TIM1_CCMR3_OC3FE = (2)
                           000001   682  TIM1_CCMR3_CC3S1 = (1)
                           000000   683  TIM1_CCMR3_CC3S0 = (0)
                                    684 
                                    685 ; Capture/Compare Mode Register 3 - channel configured in input
                           000007   686  TIM1_CCMR3_IC3F3 = (7)
                           000006   687  TIM1_CCMR3_IC3F2 = (6)
                           000005   688  TIM1_CCMR3_IC3F1 = (5)
                           000004   689  TIM1_CCMR3_IC3F0 = (4)
                           000003   690  TIM1_CCMR3_IC3PSC1 = (3)
                           000002   691  TIM1_CCMR3_IC3PSC0 = (2)
                                    692 ;  TIM1_CCMR3_CC3S1 = (1)
                           000000   693  TIM1_CCMR3_CC3S0 = (0)
                                    694 
                                    695 ; Capture/Compare Mode Register 4 - channel configured in output
                           000007   696  TIM1_CCMR4_OC4CE = (7)
                           000006   697  TIM1_CCMR4_OC4M2 = (6)
                           000005   698  TIM1_CCMR4_OC4M1 = (5)
                           000004   699  TIM1_CCMR4_OC4M0 = (4)
                           000003   700  TIM1_CCMR4_OC4PE = (3)
                           000002   701  TIM1_CCMR4_OC4FE = (2)
                           000001   702  TIM1_CCMR4_CC4S1 = (1)
                           000000   703  TIM1_CCMR4_CC4S0 = (0)
                                    704 
                                    705 ; Capture/Compare Mode Register 4 - channel configured in input
                           000007   706  TIM1_CCMR4_IC4F3 = (7)
                           000006   707  TIM1_CCMR4_IC4F2 = (6)
                           000005   708  TIM1_CCMR4_IC4F1 = (5)
                           000004   709  TIM1_CCMR4_IC4F0 = (4)
                           000003   710  TIM1_CCMR4_IC4PSC1 = (3)
                           000002   711  TIM1_CCMR4_IC4PSC0 = (2)
                                    712 ;  TIM1_CCMR4_CC4S1 = (1)
                           000000   713  TIM1_CCMR4_CC4S0 = (0)
                                    714 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 18.
Hexadecimal [24-Bits]



                                    715 ; timer 1 break register bits 
                           000000   716 TIM1_BKR_LOCK=0 ;(0:1) lock configuration
                           000002   717 TIM1_BKR_OSSI=2 ; Off state selection for idle mode
                           000003   718 TIM1_BKR_OSSR=3 ; Off state selection for Run mode
                           000004   719 TIM1_BKR_BKE=4  ; Break enable
                           000005   720 TIM1_BKR_BKP=5  ; Break polarity
                           000006   721 TIM1_BKR_AOE=6  ; Automatic output enable
                           000007   722 TIM1_BKR_MOE=7  ; Main output enable
                                    723 
                                    724 ; timer 1 output idle state register bits 
                           000000   725 TIM1_OISR_OS1=0 
                           000001   726 TIM1_OISR_OSN1=1 
                           000002   727 TIM1_OISR_OS2=2 
                           000003   728 TIM1_OISR_OSN2=3 
                           000004   729 TIM1_OISR_OS3=4 
                           000005   730 TIM1_OISR_OSN3=5
                           000006   731 TIM1_OISR_OS4=6 
                           000007   732 TIM1_OISR_OSN4=7
                                    733 
                                    734 ; Timer 2 - 16-bit timer
                           005300   735  TIM2_CR1  = (0x5300)
                           005303   736  TIM2_IER  = (0x5303)
                           005304   737  TIM2_SR1  = (0x5304)
                           005305   738  TIM2_SR2  = (0x5305)
                           005306   739  TIM2_EGR  = (0x5306)
                           005307   740  TIM2_CCMR1  = (0x5307)
                           005308   741  TIM2_CCMR2  = (0x5308)
                           005309   742  TIM2_CCMR3  = (0x5309)
                           00530A   743  TIM2_CCER1  = (0x530A)
                           00530B   744  TIM2_CCER2  = (0x530B)
                           00530C   745  TIM2_CNTRH  = (0x530C)
                           00530C   746  TIM2_CNTRL  = (0x530C)
                           00530E   747  TIM2_PSCR  = (0x530E)
                           00530F   748  TIM2_ARRH  = (0x530F)
                           005319   749  TIM2_ARRL  = (0x5319)
                           005311   750  TIM2_CCR1H  = (0x5311)
                           005312   751  TIM2_CCR1L  = (0x5312)
                           005313   752  TIM2_CCR2H  = (0x5313)
                           005314   753  TIM2_CCR2L  = (0x5314)
                           005315   754  TIM2_CCR3H  = (0x5315)
                           005316   755  TIM2_CCR3L  = (0x5316)
                                    756 
                                    757 ; Timer 4
                           005340   758  TIM4_CR1  = (0x5340)
                           005343   759  TIM4_IER  = (0x5343)
                           005344   760  TIM4_SR  = (0x5344)
                           005345   761  TIM4_EGR  = (0x5345)
                           005346   762  TIM4_CNTR  = (0x5346)
                           005347   763  TIM4_PSCR  = (0x5347)
                           005348   764  TIM4_ARR  = (0x5348)
                                    765 
                                    766 ; Timer 4 bitmasks
                                    767 
                           000007   768  TIM4_CR1_ARPE = (7)
                           000003   769  TIM4_CR1_OPM = (3)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 19.
Hexadecimal [24-Bits]



                           000002   770  TIM4_CR1_URS = (2)
                           000001   771  TIM4_CR1_UDIS = (1)
                           000000   772  TIM4_CR1_CEN = (0)
                                    773 
                           000000   774  TIM4_IER_UIE = (0)
                                    775 
                           000000   776  TIM4_SR_UIF = (0)
                                    777 
                           000000   778  TIM4_EGR_UG = (0)
                                    779 
                           000002   780  TIM4_PSCR_PSC2 = (2)
                           000001   781  TIM4_PSCR_PSC1 = (1)
                           000000   782  TIM4_PSCR_PSC0 = (0)
                                    783 
                           000000   784  TIM4_PSCR_1 = 0
                           000001   785  TIM4_PSCR_2 = 1
                           000002   786  TIM4_PSCR_4 = 2
                           000003   787  TIM4_PSCR_8 = 3
                           000004   788  TIM4_PSCR_16 = 4
                           000005   789  TIM4_PSCR_32 = 5
                           000006   790  TIM4_PSCR_64 = 6
                           000007   791  TIM4_PSCR_128 = 7
                                    792 
                                    793 ; TIMx_CCMRx bit fields 
                           000004   794 TIMx_CCRM1_OC1M=4
                           000003   795 TIMx_CCRM1_OC1PE=3 
                           000000   796 TIMx_CCRM1_CC1S=0 
                                    797 
                                    798 ; ADC1 individual element access
                           0053E0   799  ADC1_DB0RH  = (0x53E0)
                           0053E1   800  ADC1_DB0RL  = (0x53E1)
                           0053E2   801  ADC1_DB1RH  = (0x53E2)
                           0053E3   802  ADC1_DB1RL  = (0x53E3)
                           0053E4   803  ADC1_DB2RH  = (0x53E4)
                           0053E5   804  ADC1_DB2RL  = (0x53E5)
                           0053E6   805  ADC1_DB3RH  = (0x53E6)
                           0053E7   806  ADC1_DB3RL  = (0x53E7)
                           0053E8   807  ADC1_DB4RH  = (0x53E8)
                           0053E9   808  ADC1_DB4RL  = (0x53E9)
                           0053EA   809  ADC1_DB5RH  = (0x53EA)
                           0053EB   810  ADC1_DB5RL  = (0x53EB)
                           0053EC   811  ADC1_DB6RH  = (0x53EC)
                           0053ED   812  ADC1_DB6RL  = (0x53ED)
                           0053EE   813  ADC1_DB7RH  = (0x53EE)
                           0053EF   814  ADC1_DB7RL  = (0x53EF)
                           0053F0   815  ADC1_DB8RH  = (0x53F0)
                           0053F1   816  ADC1_DB8RL  = (0x53F1)
                           0053F2   817  ADC1_DB9RH  = (0x53F2)
                           0053F3   818  ADC1_DB9RL  = (0x53F3)
                                    819 
                           005400   820  ADC1_CSR  = (0x5400)
                           005401   821  ADC1_CR1  = (0x5401)
                           005402   822  ADC1_CR2  = (0x5402)
                           005403   823  ADC1_CR3  = (0x5403)
                           005404   824  ADC1_DRH  = (0x5404)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 20.
Hexadecimal [24-Bits]



                           005405   825  ADC1_DRL  = (0x5405)
                           005406   826  ADC1_TDRH  = (0x5406)
                           005407   827  ADC1_TDRL  = (0x5407)
                           005408   828  ADC1_HTRH  = (0x5408)
                           005409   829  ADC1_HTRL  = (0x5409)
                           00540A   830  ADC1_LTRH  = (0x540A)
                           00540B   831  ADC1_LTRL  = (0x540B)
                           00540C   832  ADC1_AWSRH  = (0x540C)
                           00540D   833  ADC1_AWSRL  = (0x540D)
                           00540E   834  ADC1_AWCRH  = (0x540E)
                           00540F   835  ADC1_AWCRL  = (0x540F)
                                    836 
                                    837 ; ADC1 bitmasks
                                    838 
                           000007   839  ADC1_CSR_EOC = (7)
                           000006   840  ADC1_CSR_AWD = (6)
                           000005   841  ADC1_CSR_EOCIE = (5)
                           000004   842  ADC1_CSR_AWDIE = (4)
                           000003   843  ADC1_CSR_CH3 = (3)
                           000002   844  ADC1_CSR_CH2 = (2)
                           000001   845  ADC1_CSR_CH1 = (1)
                           000000   846  ADC1_CSR_CH0 = (0)
                                    847 
                           000006   848  ADC1_CR1_SPSEL2 = (6)
                           000005   849  ADC1_CR1_SPSEL1 = (5)
                           000004   850  ADC1_CR1_SPSEL0 = (4)
                           000001   851  ADC1_CR1_CONT = (1)
                           000000   852  ADC1_CR1_ADON = (0)
                                    853 
                           000006   854  ADC1_CR2_EXTTRIG = (6)
                           000005   855  ADC1_CR2_EXTSEL1 = (5)
                           000004   856  ADC1_CR2_EXTSEL0 = (4)
                           000003   857  ADC1_CR2_ALIGN = (3)
                           000001   858  ADC1_CR2_SCAN = (1)
                                    859 
                           000007   860  ADC1_CR3_DBUF = (7)
                           000006   861  ADC1_CR3_DRH = (6)
                                    862 
                                    863 ; CPU
                           007F00   864  CPU_A  = (0x7F00)
                           007F01   865  CPU_PCE  = (0x7F01)
                           007F02   866  CPU_PCH  = (0x7F02)
                           007F03   867  CPU_PCL  = (0x7F03)
                           007F04   868  CPU_XH  = (0x7F04)
                           007F05   869  CPU_XL  = (0x7F05)
                           007F06   870  CPU_YH  = (0x7F06)
                           007F07   871  CPU_YL  = (0x7F07)
                           007F08   872  CPU_SPH  = (0x7F08)
                           007F09   873  CPU_SPL   = (0x7F09)
                           007F0A   874  CPU_CCR   = (0x7F0A)
                                    875 
                                    876 ; global configuration register
                           007F60   877  CFG_GCR   = (0x7F60)
                                    878 
                                    879 ; interrupt control registers
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 21.
Hexadecimal [24-Bits]



                           007F70   880  ITC_SPR1   = (0x7F70)
                           007F71   881  ITC_SPR2   = (0x7F71)
                           007F72   882  ITC_SPR3   = (0x7F72)
                           007F73   883  ITC_SPR4   = (0x7F73)
                           007F74   884  ITC_SPR5   = (0x7F74)
                           007F75   885  ITC_SPR6   = (0x7F75)
                           007F76   886  ITC_SPR7   = (0x7F76)
                           007F77   887  ITC_SPR8   = (0x7F77)
                                    888 ; interrupt priority
                           000002   889  IPR0 = 2
                           000001   890  IPR1 = 1
                           000000   891  IPR2 = 0
                           000003   892  IPR3 = 3 
                           000003   893  IPR_MASK = 3
                                    894 
                                    895 ; SWIM, control and status register
                           007F80   896  SWIM_CSR   = (0x7F80)
                                    897 ; debug registers
                           007F90   898  DM_BK1RE   = (0x7F90)
                           007F91   899  DM_BK1RH   = (0x7F91)
                           007F92   900  DM_BK1RL   = (0x7F92)
                           007F93   901  DM_BK2RE   = (0x7F93)
                           007F94   902  DM_BK2RH   = (0x7F94)
                           007F95   903  DM_BK2RL   = (0x7F95)
                           007F96   904  DM_CR1   = (0x7F96)
                           007F97   905  DM_CR2   = (0x7F97)
                           007F98   906  DM_CSR1   = (0x7F98)
                           007F99   907  DM_CSR2   = (0x7F99)
                           007F9A   908  DM_ENFCTR   = (0x7F9A)
                                    909 
                                    910 ; Interrupt Numbers
                           000000   911  INT_TLI = 0
                           000001   912  INT_AWU = 1
                           000002   913  INT_CLK = 2
                           000003   914  INT_EXTI0 = 3
                           000004   915  INT_EXTI1 = 4
                           000005   916  INT_EXTI2 = 5
                           000006   917  INT_EXTI3 = 6
                           000007   918  INT_EXTI4 = 7
                           000008   919  INT_RES1 = 8
                           000009   920  INT_RES2 = 9
                           00000A   921  INT_SPI = 10
                           00000B   922  INT_TIM1_OVF = 11
                           00000C   923  INT_TIM1_CCM = 12
                           00000D   924  INT_TIM2_OVF = 13
                           00000E   925  INT_TIM2_CCM = 14
                           00000F   926  INT_RES3 = 15
                           000010   927  INT_RES4 = 16
                           000011   928  INT_UART1_TXC = 17
                           000012   929  INT_UART1_RX_FULL = 18
                           000013   930  INT_I2C = 19
                           000014   931  INT_RES5 = 20
                           000015   932  INT_RES6 = 21
                           000016   933  INT_ADC1 = 22
                           000017   934  INT_TIM4_OVF = 23
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 22.
Hexadecimal [24-Bits]



                           000018   935  INT_FLASH = 24
                                    936 
                                    937 ; Interrupt Vectors
                           008000   938  INT_VECTOR_RESET = 0x8000
                           008004   939  INT_VECTOR_TRAP = 0x8004
                           008008   940  INT_VECTOR_TLI = 0x8008
                           00800C   941  INT_VECTOR_AWU = 0x800C
                           008010   942  INT_VECTOR_CLK = 0x8010
                           008014   943  INT_VECTOR_EXTI0 = 0x8014
                           008018   944  INT_VECTOR_EXTI1 = 0x8018
                           00801C   945  INT_VECTOR_EXTI2 = 0x801C
                           008020   946  INT_VECTOR_EXTI3 = 0x8020
                           008024   947  INT_VECTOR_EXTI4 = 0x8024
                           008030   948  INT_VECTOR_SPI = 0x8030
                           008034   949  INT_VECTOR_TIM1_OVF = 0x8034
                           008038   950  INT_VECTOR_TIM1_CCM = 0x8038
                           00803C   951  INT_VECTOR_TIM2_OVF = 0x803C
                           008040   952  INT_VECTOR_TIM2_CCM = 0x8040
                           00804C   953  INT_VECTOR_UART1_TX_COMPLETE = 0x804c
                           008050   954  INT_VECTOR_UART1_RX_FULL = 0x8050
                           008054   955  INT_VECTOR_I2C = 0x8054
                           008060   956  INT_VECTOR_ADC1 = 0x8060
                           008064   957  INT_VECTOR_TIM4_OVF = 0x8064
                           008068   958  INT_VECTOR_FLASH = 0x8068
                                    959 
                                    960  
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 23.
Hexadecimal [24-Bits]



                                     12 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 24.
Hexadecimal [24-Bits]



                                     14 
                                     15 ; defined for debug.asm 
                           000000    16 DEBUG=0
                                     17 ; master clock frequency 12Mhz crystal 
                           B71B00    18 FMSTR=12000000 ; 
                                     19 
                                     20 
                                     21 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     22 ; peripherals usage 
                                     23 ;  TIMER4 1 msec timer, use interrupt 
                                     24 ;  TIMER1 CH4  PWM, PC4 pin 14
                                     25 ;  TIMER2 CH1  alarm sound, PD4 pin 1
                                     26 ;  alarm GREEN LED, PC3 pin 13
                                     27 ;  alarm RED LED, PC5 pin 15
                                     28 ;  ADC read AIN3, PD2 pin 19
                                     29 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     30 
                                     31 ;------------------------------
                                     32 ;  system constants 
                                     33 ;------------------------------
                           000005    34 ALARM_RLED_BIT = 5 ; RED LED PC5
                           000003    35 ALARM_GLED_BIT = 3 ; GREEN LED PC3
                           00500A    36 ALARM_LED_ODR = PC_ODR 
                           00500C    37 ALARM_LED_DDR = PC_DDR 
                           00500D    38 ALARM_LED_CR1 = PC_CR1 
                           000004    39 ALARM_SOUND = 4 ; PD4 
                           002EE0    40 ALARM_FREQ_HIGH=FMSTR/1000; 12Mhz/1000 
                           0042F6    41 ALARM_FREQ_LOW=FMSTR/700; 12Mhz/700
                           000003    42 ADC_INPUT = 3
                           00500F    43 ADC_ODR = PD_ODR
                           005011    44 ADC_DDR = PD_DDR 
                           000002    45 ADC_BIT = 2
                                     46 ;; detector sensivity
                                     47 ;; increment to reduce false detection 
                           000002    48 SENSIVITY = 2
                                     49 ; how many samples to skip for average 
                                     50 ; adjustment 
                           000003    51 SKIP_MAX=3
                                     52 
                                     53 ;; period value for TIMER1 frequency 
                                     54 ;; period = 1 msec. 
                           002EE0    55 TMR1_PERIOD= 12000 
                                     56 ; pulse width 12uS 
                           002904    57 TMR1_DC= 12000-1500
                                     58 
                                     59 ;;;;;;;;;;;;;;;;;;;;;;;;
                                     60 ;;  usefull macros 
                                     61 ;;;;;;;;;;;;;;;;;;;;;;;;
                                     62 
                                     63     ; turn on green LED 
                                     64     .macro _gled_on 
                                     65     bres ALARM_LED_ODR,#ALARM_GLED_BIT 
                                     66     .endm 
                                     67 
                                     68     ; turn off green LED 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 25.
Hexadecimal [24-Bits]



                                     69     .macro _gled_off 
                                     70     bset ALARM_LED_ODR,#ALARM_GLED_BIT 
                                     71     .endm 
                                     72 
                                     73     ; turn on red LED 
                                     74     .macro _rled_on 
                                     75     bres ALARM_LED_ODR,#ALARM_RLED_BIT 
                                     76     .endm 
                                     77 
                                     78     ; turn off red LED 
                                     79     .macro _rled_off 
                                     80     bset ALARM_LED_ODR,#ALARM_RLED_BIT 
                                     81     .endm 
                                     82 
                                     83     ; turn on both LED 
                                     84     .macro _leds_on 
                                     85     _gled_on 
                                     86     _rled_on 
                                     87     .endm 
                                     88 
                                     89     ; turn of both LED 
                                     90     .macro _leds_off 
                                     91     _gled_off 
                                     92     _rled_off 
                                     93     .endm 
                                     94 
                                     95     .macro _sound_on     
                                     96  	bset TIM2_CCER1,#TIM_CCER1_CC1E
                                     97 	bset TIM2_CR1,#TIM_CR1_CEN
                                     98 	bset TIM2_EGR,#TIM_EGR_UG
                                     99     .endm 
                                    100 
                                    101     .macro _sound_off 
                                    102 	bres TIM2_CCER1,#TIM_CCER1_CC1E
                                    103 	bres TIM2_CR1,#TIM_CR1_CEN 
                                    104     .endm 
                                    105 
                                    106 ;**********************************************************
                                    107         .area DATA (ABS)
      000000                        108         .org RAM_BASE 
                                    109 ;**********************************************************
      000000                        110 ALARM_DLY: .blkb 1 ; control alarm duration 
      000001                        111 SAMPLES_SUM: .blkw 1   ; sum of ADC reading  
      000003                        112 SAMPLES_AVG: .blkw 1  ; mean of 32 reading  
      000005                        113 CNTDWN: .blkw 1 ; count down timer 
      000007                        114 PERIOD: .blkw 1 ; PWM period count 
      000009                        115 CHANGE: .blkb 1 ; 1=up|-1=down|0=same 
      00000A                        116 COUNT: .blkb 1 ; count changes in same direction 
      00000B                        117 SKIP:  .blkw 1 ; count of sample to skip for average adjust  
      00000D                        118 LAST:  .blkw 1 ; last sample value 
      00000F                        119 SLOPE: .blkw 1 ; inc if DELTA>0 else dec if < 0  
      000011                        120 DELTA: .blkw 1 ; average-last 
                           000000   121 .if DEBUG 
                                    122 RX_CHAR: .blkb 1 ;  keep character received from uart 
                                    123 .endif 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 26.
Hexadecimal [24-Bits]



                                    124 
                                    125 ;**********************************************************
                                    126         .area SSEG (ABS) ; STACK
      001700                        127         .org 0x1700
      001700                        128         .ds 256 
                                    129 ; space for DATSTK,TIB and STACK         
                                    130 ;**********************************************************
                                    131 
                                    132 ;**********************************************************
                                    133         .area HOME ; vectors table
                                    134 ;**********************************************************
      008000 82 00 80 94            135 	int cold_start	        ; reset
      008004 82 00 80 80            136 	int NonHandledInterrupt	; trap
      008008 82 00 80 80            137 	int NonHandledInterrupt	; irq0
      00800C 82 00 80 80            138 	int NonHandledInterrupt	; irq1
      008010 82 00 80 80            139 	int NonHandledInterrupt	; irq2
      008014 82 00 80 80            140 	int NonHandledInterrupt	; irq3
      008018 82 00 80 80            141 	int NonHandledInterrupt	; irq4
      00801C 82 00 80 80            142 	int NonHandledInterrupt	; irq5
      008020 82 00 80 80            143 	int NonHandledInterrupt	; irq6
      008024 82 00 80 80            144 	int NonHandledInterrupt	; irq7
      008028 82 00 80 80            145 	int NonHandledInterrupt	; irq8
      00802C 82 00 80 80            146 	int NonHandledInterrupt	; irq9
      008030 82 00 80 80            147 	int NonHandledInterrupt	; irq10
      008034 82 00 80 80            148 	int NonHandledInterrupt	; irq11
      008038 82 00 80 80            149 	int NonHandledInterrupt	; irq12
      00803C 82 00 80 80            150 	int NonHandledInterrupt	; irq13
      008040 82 00 80 80            151 	int NonHandledInterrupt	; irq14
      008044 82 00 80 80            152 	int NonHandledInterrupt	; irq15
      008048 82 00 80 80            153 	int NonHandledInterrupt	; irq16
      00804C 82 00 80 80            154 	int NonHandledInterrupt	; irq17
                           000000   155 .if DEBUG
                                    156     int uart_rx_handler
                           000001   157 .else 
      008050 82 00 80 80            158 	int NonHandledInterrupt	; irq18
                                    159 .endif 
      008054 82 00 80 80            160 	int NonHandledInterrupt	; irq19
      008058 82 00 80 80            161 	int NonHandledInterrupt	; irq20
      00805C 82 00 80 80            162 	int NonHandledInterrupt	; irq21
      008060 82 00 80 80            163 	int NonHandledInterrupt	; irq22
      008064 82 00 80 86            164 	int Timer4Handler	    ; irq23
      008068 82 00 80 80            165 	int NonHandledInterrupt	; irq24
      00806C 82 00 80 80            166 	int NonHandledInterrupt	; irq25
      008070 82 00 80 80            167 	int NonHandledInterrupt	; irq26
      008074 82 00 80 80            168 	int NonHandledInterrupt	; irq27
      008078 82 00 80 80            169 	int NonHandledInterrupt	; irq28
      00807C 82 00 80 80            170 	int NonHandledInterrupt	; irq29
                                    171 
                                    172 ;**********************************************************
                                    173         .area CODE
                                    174 ;**********************************************************
                                    175 
                                    176 ; non handled interrupt reset MCU
      008080                        177 NonHandledInterrupt:
      008080 80               [11]  178         iret 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 27.
Hexadecimal [24-Bits]



                                    179 
      008081                        180 sofware_reset:
      008081 A6 80            [ 1]  181         ld a, #0x80
      008083 C7 50 D1         [ 1]  182         ld WWDG_CR,a ; WWDG_CR used to reset mcu
                                    183 
                                    184 ; used for count down timer 
      008086                        185 Timer4Handler:
      008086 72 5F 53 44      [ 1]  186 	clr TIM4_SR
      00808A CE 00 05         [ 2]  187     ldw x,CNTDWN 
      00808D 27 04            [ 1]  188     jreq 1$
      00808F 5A               [ 2]  189     decw x 
      008090 CF 00 05         [ 2]  190     ldw CNTDWN,x
      008093                        191 1$:         
      008093 80               [11]  192     iret 
                                    193 
                                    194 
                                    195 ; entry point at power up 
                                    196 ; or reset 
      008094                        197 cold_start: 
                                    198 ; initialize clock to HSE
                                    199 ; no divisor 12 Mhz crystal  
      008094                        200 clock_init:
      008094 9B               [ 1]  201     sim ; disable interrupts 
      008095 72 5F 50 C6      [ 1]  202     clr CLK_CKDIVR
      008099 72 17 50 C5      [ 1]  203     bres CLK_SWCR,#CLK_SWCR_SWIF 
      00809D 35 B4 50 C4      [ 1]  204     mov CLK_SWR,#CLK_SWR_HSE ; 12 Mhz crystal
      0080A1 72 07 50 C5 FB   [ 2]  205     btjf CLK_SWCR,#CLK_SWCR_SWIF,. 
      0080A6 72 12 50 C5      [ 1]  206 	bset CLK_SWCR,#CLK_SWCR_SWEN
                                    207 ; initialize stack pointer 
      0080AA                        208 stack_init: 
      0080AA AE 03 FF         [ 2]  209     ldw x,#RAM_SIZE-1 
      0080AD 94               [ 1]  210     ldw sp,x 
                                    211 ; clear all ram 
      0080AE 7F               [ 1]  212 1$: clr (x)
      0080AF 5A               [ 2]  213     decw x 
      0080B0 26 FC            [ 1]  214     jrne 1$        
                                    215 ; disable all unused peripheral clock
      0080B2 A6 B0            [ 1]  216     ld a,#0xB0 ; enable timers 1,2,4 
      0080B4 C7 50 C7         [ 1]  217     ld CLK_PCKENR1,a 
      0080B7 A6 08            [ 1]  218     ld a,#(1<<3) ; ADC1 
      0080B9 C7 50 CA         [ 1]  219     ld CLK_PCKENR2,a 
                                    220 ; activate pull up on all unused inputs 
                                    221 ; to reduce noise 
      0080BC A6 FF            [ 1]  222 	ld a,#255 
      0080BE C7 50 03         [ 1]  223 	ld PA_CR1,a  
      0080C1 C7 50 08         [ 1]  224  	ld PB_CR1,a
      0080C4 C7 50 17         [ 1]  225 	ld PE_CR1,a 
      0080C7 C7 50 1C         [ 1]  226 	ld PF_CR1,a 
      0080CA A6 C0            [ 1]  227     ld a,#(1<<6)|(1<<7)
      0080CC C7 50 0D         [ 1]  228     ld PC_CR1,a  
      0080CF A6 6A            [ 1]  229     ld a,#(1<<1)|(1<<3)|(1<<5)|(1<<6)
      0080D1 C7 50 12         [ 1]  230 	ld PD_CR1,a    
                                    231 
                                    232 ; set PC4 as output high 
                                    233 ; this is TIM1_CH4 output 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 28.
Hexadecimal [24-Bits]



                                    234 ; want it low when PWM is off     
      0080D4 72 18 50 0C      [ 1]  235     bset PC_DDR,#4 ; output mode 
      0080D8 72 18 50 0A      [ 1]  236     bset PC_ODR,#4 ; high  
                                    237     
                                    238 ; set alarm LED as output 
      0080DC 72 17 50 0D      [ 1]  239     bres ALARM_LED_CR1,#ALARM_GLED_BIT ; open drain 
      0080E0 72 16 50 0C      [ 1]  240     bset ALARM_LED_DDR,#ALARM_GLED_BIT
      0080E4 72 1B 50 0D      [ 1]  241     bres ALARM_LED_CR1,#ALARM_RLED_BIT
      0080E8 72 1A 50 0C      [ 1]  242     bset ALARM_LED_DDR,#ALARM_RLED_BIT  
      00006C                        243     _leds_off     
      00006C                          1     _gled_off 
      0080EC 72 16 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_GLED_BIT 
      000070                          2     _rled_off 
      0080F0 72 1A 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_RLED_BIT 
                                    244 
                           000000   245 .if DEBUG 
                                    246     call uart_init 
                                    247 .endif     
                                    248 ; initialize timer4, used for millisecond interrupt  
      0080F4                        249 timer4_init: 
      0080F4 72 11 53 40      [ 1]  250 	bres TIM4_CR1,#TIM4_CR1_CEN 
      0080F8 35 06 53 47      [ 1]  251 	mov TIM4_PSCR,#6 ; prescale 64  
      0080FC 35 BB 53 48      [ 1]  252 	mov TIM4_ARR,#187 ; for 1msec. 12Mhz/64/1000 
      008100 72 10 53 43      [ 1]  253 	bset TIM4_IER,#TIM4_IER_UIE 
      008104 72 10 53 40      [ 1]  254 	bset TIM4_CR1,#TIM4_CR1_CEN
      008108 72 10 53 45      [ 1]  255     bset TIM4_EGR,#TIM4_EGR_UG 
      00810C 9A               [ 1]  256     rim
                                    257 
                                    258 ; initialize TIMER2 for 1Khz tone generator 
      00810D                        259 timer2_init:
      00810D 72 19 50 12      [ 1]  260     bres PD_CR1,#4 ; open drain output 
      008111 35 60 53 07      [ 1]  261  	mov TIM2_CCMR1,#(6<<TIMx_CCRM1_OC1M) ; PWM mode 1 
      008115 35 00 53 0E      [ 1]  262 	mov TIM2_PSCR,#0 ; 
      008119 35 42 53 0F      [ 1]  263     mov TIM2_ARRH,#ALARM_FREQ_LOW>>8  
      00811D 35 F6 53 19      [ 1]  264     mov TIM2_ARRL,#ALARM_FREQ_LOW&255 
      008121 35 21 53 11      [ 1]  265     mov TIM2_CCR1H,#(ALARM_FREQ_LOW/2)>>8
      008125 35 7B 53 12      [ 1]  266     mov TIM2_CCR1L,#(ALARM_FREQ_LOW/2)&255 
      0000A9                        267     _sound_off
      008129 72 11 53 0A      [ 1]    1 	bres TIM2_CCER1,#TIM_CCER1_CC1E
      00812D 72 11 53 00      [ 1]    2 	bres TIM2_CR1,#TIM_CR1_CEN 
                                    268 
                                    269 ; initialize TIMER1 for PWM generation , one pulse mode 
                                    270 ; period 1 msec, pulse width 10uSec 
      008131 AE 2E E0         [ 2]  271     ldw x,#TMR1_PERIOD 
      008134 CF 00 07         [ 2]  272     ldw PERIOD,x 
      008137 72 5F 52 60      [ 1]  273     clr TIM1_PSCRH
      00813B 72 5F 52 61      [ 1]  274     clr TIM1_PSCRL 
      00813F 35 2E 52 62      [ 1]  275     mov TIM1_ARRH,#TMR1_PERIOD>>8  
      008143 35 E0 52 63      [ 1]  276     mov TIM1_ARRL,#TMR1_PERIOD&0xff 
      008147 35 29 52 6B      [ 1]  277     mov TIM1_CCR4H,#TMR1_DC>>8
      00814B 35 04 52 6C      [ 1]  278     mov TIM1_CCR4L,#TMR1_DC&0xff
      00814F 72 1C 52 6F      [ 1]  279     bset TIM1_OISR,#TIM1_OISR_OS4 
      008153 72 18 52 5D      [ 1]  280     bset TIM1_CCER2,#TIM_CCER2_CC4E
      008157 35 68 52 5B      [ 1]  281     mov TIM1_CCMR4,#(6<<4)|(1<<3) ;OC4M=7|OC4PE=1 ; PWM mode 1 
                                    282 ; one pulse mode  
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 29.
Hexadecimal [24-Bits]



      00815B 72 16 52 50      [ 1]  283     bset TIM1_CR1,#TIM_CR1_OPM 
                                    284 ; enable PWM output 
      00815F 72 1E 52 6D      [ 1]  285 	bset TIM1_BKR,#TIM1_BKR_MOE ; enable PWM output   
                                    286 
                           000000   287 .if 0
                                    288 0$:
                                    289 call send_pulse
                                    290 jra 0$
                                    291 .endif 
                                    292 
                                    293 ; enable ADC 
      008163 72 16 54 07      [ 1]  294     bset ADC1_TDRL,#ADC_INPUT
      008167 35 40 54 01      [ 1]  295     mov ADC1_CR1,#(4<<4) ; ADCclk=Fmaster/8 
      00816B 72 16 54 02      [ 1]  296     bset ADC1_CR2,#ADC1_CR2_ALIGN
      00816F 72 10 54 01      [ 1]  297     bset ADC1_CR1,#0 ; turn on ADC  
                                    298 
                                    299 ; signal power up 
      008173 CD 82 69         [ 4]  300     call power_on 
                                    301 
                                    302 ;-------------------------
                                    303 ; initialize detector 
                                    304 ; by reading 32 samples
                                    305 ; and compute average 
                                    306 ;--------------------------
      008176                        307 init_detector: 
      008176 4B 20            [ 1]  308     push #32
      008178 5F               [ 1]  309     clrw x 
      008179 CF 00 01         [ 2]  310     ldw SAMPLES_SUM,x  
      00817C                        311 2$: 
      00817C CD 82 13         [ 4]  312     call sample
      00817F 72 BB 00 01      [ 2]  313     addw x, SAMPLES_SUM
      008183 CF 00 01         [ 2]  314     ldw SAMPLES_SUM, x
      008186 0A 01            [ 1]  315     dec (1,sp)
      008188 26 F2            [ 1]  316     jrne 2$
      00818A 90 AE 00 20      [ 2]  317     ldw y,#32
      00818E 65               [ 2]  318     divw x,y 
      00818F CF 00 03         [ 2]  319     ldw SAMPLES_AVG,x 
                           000000   320 .if DEBUG 
                                    321     call clear_screen
                                    322     call uart_prt_int
                                    323     ld a,#13
                                    324     call uart_putc
                                    325 .endif 
      008192 84               [ 1]  326     pop a 
                                    327 
                                    328 ;-----------------
                                    329 ; detector loop 
                                    330 ;-----------------
      008193                        331 detector:
      008193 CD 82 13         [ 4]  332     call sample 
      008196 CE 00 03         [ 2]  333     ldw x,SAMPLES_AVG 
      008199 72 B0 00 0D      [ 2]  334     subw x,LAST 
      00819D CF 00 11         [ 2]  335     ldw DELTA,x 
      0081A0 2A 07            [ 1]  336     jrpl 3$
      0081A2 72 5A 00 0F      [ 1]  337     dec SLOPE 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 30.
Hexadecimal [24-Bits]



      0081A6 50               [ 2]  338     negw x
      0081A7 20 04            [ 2]  339     jra 4$  
      0081A9                        340 3$: 
      0081A9 72 5C 00 0F      [ 1]  341     inc SLOPE 
      0081AD                        342 4$:
      0081AD A3 00 02         [ 2]  343     cpw x,#SENSIVITY 
      0081B0 2A 06            [ 1]  344     jrpl 5$
      0081B2 72 5F 00 0F      [ 1]  345     clr SLOPE 
      0081B6 20 DB            [ 2]  346     jra detector 
      0081B8                        347 5$:      
                           000000   348 .if DEBUG 
                                    349 call uart_prt_int
                                    350 .endif 
      0081B8 CD 81 D7         [ 4]  351     call alarm 
      0081BB CD 81 C0         [ 4]  352    call adjust_avg 
      0081BE 20 D3            [ 2]  353     jra detector 
                                    354 
      0081C0                        355 adjust_avg:
                           000000   356 .if 0
                                    357     ld a,#SKIP_MAX 
                                    358     cp a,SKIP 
                                    359     jrpl 9$ 
                                    360     clr SKIP 
                                    361 .endif 
      0081C0 CE 00 01         [ 2]  362     ldw x,SAMPLES_SUM  
      0081C3 72 B0 00 03      [ 2]  363     subw x,SAMPLES_AVG 
      0081C7 72 BB 00 0D      [ 2]  364     addw x,LAST 
      0081CB CF 00 01         [ 2]  365     ldw SAMPLES_SUM,x 
      0081CE 90 AE 00 20      [ 2]  366     ldw y,#32 
      0081D2 65               [ 2]  367     divw x,y 
      0081D3 CF 00 03         [ 2]  368     ldw SAMPLES_AVG,x 
      0081D6 81               [ 4]  369 9$: ret     
                                    370 
                                    371 ;----------------------
                                    372 ; detection alarm 
                                    373 ;----------------------
      0081D7                        374 alarm:
      0081D7 72 5D 00 0F      [ 1]  375     tnz SLOPE 
      0081DB 27 35            [ 1]  376     jreq 9$
      0081DD 2B 06            [ 1]  377     jrmi 1$ 
      00015F                        378     _gled_on
      0081DF 72 17 50 0A      [ 1]    1     bres ALARM_LED_ODR,#ALARM_GLED_BIT 
      0081E3 20 04            [ 2]  379     jra 2$
      000165                        380 1$: _rled_on  
      0081E5 72 1B 50 0A      [ 1]    1     bres ALARM_LED_ODR,#ALARM_RLED_BIT 
      0081E9                        381 2$:
      0081E9 CD 82 94         [ 4]  382     call set_tone_freq 
      00016C                        383     _sound_on 
      0081EC 72 10 53 0A      [ 1]    1  	bset TIM2_CCER1,#TIM_CCER1_CC1E
      0081F0 72 10 53 00      [ 1]    2 	bset TIM2_CR1,#TIM_CR1_CEN
      0081F4 72 10 53 06      [ 1]    3 	bset TIM2_EGR,#TIM_EGR_UG
      0081F8 AE 00 0A         [ 2]  384     ldw x,#10 
      0081FB CD 82 5F         [ 4]  385     call pause 
      00017E                        386     _leds_off 
      00017E                          1     _gled_off 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 31.
Hexadecimal [24-Bits]



      0081FE 72 16 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_GLED_BIT 
      000182                          2     _rled_off 
      008202 72 1A 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_RLED_BIT 
      000186                        387     _sound_off 
      008206 72 11 53 0A      [ 1]    1 	bres TIM2_CCER1,#TIM_CCER1_CC1E
      00820A 72 11 53 00      [ 1]    2 	bres TIM2_CR1,#TIM_CR1_CEN 
      00820E 72 5F 00 0F      [ 1]  388     clr SLOPE 
      008212                        389 9$:
      008212 81               [ 4]  390     ret 
                                    391 
                                    392 ;--------------------
                                    393 ;  sample reader
                                    394 ;--------------------
      008213                        395 sample:
      008213 CD 82 44         [ 4]  396     call flush_cap 
      008216 CD 82 3A         [ 4]  397     call send_pulse 
      008219 CD 82 21         [ 4]  398     call adc_read
      00821C 72 5C 00 0B      [ 1]  399     inc SKIP   
      008220 81               [ 4]  400     ret 
                                    401 
                                    402 
                                    403 ;------------------------
                                    404 ; read ADC sample
                                    405 ; output:
                                    406 ;    X   sample 
                                    407 ;-------------------------
      008221                        408 adc_read:
      008221 35 03 54 00      [ 1]  409     mov ADC1_CSR,#ADC_INPUT 
      008225 72 10 54 01      [ 1]  410     bset ADC1_CR1,#0
      008229 72 0F 54 00 FB   [ 2]  411     btjf ADC1_CSR,#ADC1_CSR_EOC,. 
      00822E C6 54 05         [ 1]  412     ld a,ADC1_DRL 
      008231 97               [ 1]  413     ld xl,a 
      008232 C6 54 04         [ 1]  414     ld a,ADC1_DRH 
      008235 95               [ 1]  415     ld xh,a
      008236 CF 00 0D         [ 2]  416     ldw LAST,x  
      008239 81               [ 4]  417     ret 
                                    418 
                                    419 ;------------------------
                                    420 ; send short pulse 
                                    421 ; to inductor 
                                    422 ;------------------------
      00823A                        423 send_pulse:
                                    424 ;    bset TIM1_CCER2,#TIM_CCER2_CC4E 
      00823A 72 10 52 50      [ 1]  425     bset TIM1_CR1,#TIM_CR1_CEN 
      00823E 72 00 52 50 FB   [ 2]  426     btjt TIM1_CR1,#TIM_CR1_CEN,.
                                    427 ;    bres TIM1_CCER2,#TIM_CCER2_CC4E 
      008243 81               [ 4]  428     ret 
                                    429 
                                    430 ;------------------------
                                    431 ;  flush peak detector 
                                    432 ;  capacitor C19  
                                    433 ;  pin PB3 
                                    434 ;------------------------
      008244                        435 flush_cap: 
      008244 72 11 54 01      [ 1]  436     bres ADC1_CR1,#ADC1_CR1_ADON
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 32.
Hexadecimal [24-Bits]



      008248 72 14 50 11      [ 1]  437     bset ADC_DDR,#ADC_BIT 
      00824C 72 15 50 0F      [ 1]  438     bres ADC_ODR,#ADC_BIT  
      008250 AE 00 01         [ 2]  439     ldw x,#1
      008253 CD 82 5F         [ 4]  440     call pause 
      008256 72 15 50 11      [ 1]  441     bres ADC_DDR,#ADC_BIT  
      00825A 72 10 54 01      [ 1]  442     bset ADC1_CR1,#ADC1_CR1_ADON
      00825E 81               [ 4]  443     ret 
                                    444 
                                    445 ;------------------------
                                    446 ; pause msec 
                                    447 ; input:
                                    448 ;   x    msec 
                                    449 ;------------------------
      00825F                        450 pause:
      00825F CF 00 05         [ 2]  451     ldw CNTDWN,x 
      008262 8F               [10]  452 1$: wfi 
      008263 CE 00 05         [ 2]  453     ldw x,CNTDWN 
      008266 26 FA            [ 1]  454     jrne 1$ 
      008268 81               [ 4]  455     ret 
                                    456 
                                    457 ;--------------------------
                                    458 ; power on signal 
                                    459 ; LEDs and sound on for 
                                    460 ; 200 milliseconds
                                    461 ;--------------------------
      008269                        462 power_on:
      0001E9                        463     _sound_on 
      008269 72 10 53 0A      [ 1]    1  	bset TIM2_CCER1,#TIM_CCER1_CC1E
      00826D 72 10 53 00      [ 1]    2 	bset TIM2_CR1,#TIM_CR1_CEN
      008271 72 10 53 06      [ 1]    3 	bset TIM2_EGR,#TIM_EGR_UG
      0001F5                        464     _leds_on 
      0001F5                          1     _gled_on 
      008275 72 17 50 0A      [ 1]    1     bres ALARM_LED_ODR,#ALARM_GLED_BIT 
      0001F9                          2     _rled_on 
      008279 72 1B 50 0A      [ 1]    1     bres ALARM_LED_ODR,#ALARM_RLED_BIT 
      00827D AE 00 C8         [ 2]  465     ldw x,#200
      008280 CD 82 5F         [ 4]  466     call pause 
      000203                        467     _leds_off 
      000203                          1     _gled_off 
      008283 72 16 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_GLED_BIT 
      000207                          2     _rled_off 
      008287 72 1A 50 0A      [ 1]    1     bset ALARM_LED_ODR,#ALARM_RLED_BIT 
      00020B                        468     _sound_off
      00828B 72 11 53 0A      [ 1]    1 	bres TIM2_CCER1,#TIM_CCER1_CC1E
      00828F 72 11 53 00      [ 1]    2 	bres TIM2_CR1,#TIM_CR1_CEN 
      008293 81               [ 4]  469     ret 
                                    470 
                                    471 ;---------------------
                                    472 ; set tone frequence
                                    473 ; paramters 
                                    474 ;  ALARM_FREQ constant 
                                    475 ;  DELTA variable  
                                    476 ;--------------------
      008294                        477 set_tone_freq:
      008294 AE 2E E0         [ 2]  478     ldw x,#ALARM_FREQ_HIGH 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 33.
Hexadecimal [24-Bits]



      008297 72 5D 00 0F      [ 1]  479     tnz SLOPE 
      00829B 2B 03            [ 1]  480     jrmi 1$ 
      00829D AE 42 F6         [ 2]  481     LDW x,#ALARM_FREQ_LOW 
      0082A0                        482 1$:
      0082A0 9E               [ 1]  483     ld a,xh 
      0082A1 C7 53 0F         [ 1]  484     ld TIM2_ARRH,a 
      0082A4 9F               [ 1]  485     ld a,xl 
      0082A5 C7 53 19         [ 1]  486     ld TIM2_ARRL,a 
      0082A8 54               [ 2]  487     srlw x 
      0082A9 9E               [ 1]  488     ld a,xh 
      0082AA C7 53 11         [ 1]  489     ld TIM2_CCR1H,a 
      0082AD 9F               [ 1]  490     ld a,xl 
      0082AE C7 53 12         [ 1]  491     ld TIM2_CCR1L,a 
      0082B1 72 10 53 06      [ 1]  492     bset TIM2_EGR,#TIM_EGR_UG 
      0082B5 81               [ 4]  493     ret 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 34.
Hexadecimal [24-Bits]



                                      1 ;------------------------
                                      2 ; debug support 
                                      3 ; using UART 
                                      4 ; to use it define:
                                      5 ; DEBUG=1
                                      6 ; FMSTR= frequency in Hertz  
                                      7 ; in main project file
                                      8 ;-----------------------
                                      9 
                                     10     .module UART_DEBUG 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 35.
Hexadecimal [24-Bits]



                                     11     .include "inc/ascii.inc" 
                                      1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                      2 ;; Copyright Jacques Deschênes 2019,2020,2021 
                                      3 ;; This file is part of stm32_eforth  
                                      4 ;;
                                      5 ;;     stm8_eforth is free software: you can redistribute it and/or modify
                                      6 ;;     it under the terms of the GNU General Public License as published by
                                      7 ;;     the Free Software Foundation, either version 3 of the License, or
                                      8 ;;     (at your option) any later version.
                                      9 ;;
                                     10 ;;     stm32_eforth is distributed in the hope that it will be useful,
                                     11 ;;     but WITHOUT ANY WARRANTY;; without even the implied warranty of
                                     12 ;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
                                     13 ;;     GNU General Public License for more details.
                                     14 ;;
                                     15 ;;     You should have received a copy of the GNU General Public License
                                     16 ;;     along with stm32_eforth.  If not, see <http:;;www.gnu.org/licenses/>.
                                     17 ;;;;
                                     18 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                     19 
                                     20 
                                     21 ;-------------------------------------------------------
                                     22 ;     ASCII control  values
                                     23 ;     CTRL_x   are VT100 keyboard values  
                                     24 ;-------------------------------------------------------
                           000001    25 		CTRL_A = 1
                           000002    26 		CTRL_B = 2
                           000003    27 		CTRL_C = 3
                           000004    28 		CTRL_D = 4
                           000005    29 		CTRL_E = 5
                           000006    30 		CTRL_F = 6
                                     31 	
                           000007    32         BELL = 7    ; vt100 terminal generate a sound.
                           000007    33 		CTRL_G = 7
                                     34 
                           000008    35 		BSP = 8     ; back space 
                           000008    36 		CTRL_H = 8  
                                     37 
                           000009    38     	TAB = 9     ; horizontal tabulation
                           000009    39         CTRL_I = 9
                                     40 
                           00000A    41 		NL = 10     ; new line 
                           00000A    42         CTRL_J = 10 
                                     43 
                           00000B    44         VT = 11     ; vertical tabulation 
                           00000B    45 		CTRL_K = 11
                                     46 
                           00000C    47         FF = 12      ; new page
                           00000C    48 		CTRL_L = 12
                                     49 
                           00000D    50 		CR = 13      ; carriage return 
                           00000D    51 		CTRL_M = 13
                                     52 
                           00000E    53 		CTRL_N = 14
                           00000F    54 		CTRL_O = 15
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 36.
Hexadecimal [24-Bits]



                           000010    55 		CTRL_P = 16
                           000011    56 		CTRL_Q = 17
                           000011    57 		XON = CTRL_Q
                           000012    58 		CTRL_R = 18
                           000013    59 		CTRL_S = 19
                           000013    60 		XOFF = CTRL_S 
                           000014    61 		CTRL_T = 20
                           000015    62 		CTRL_U = 21
                           000016    63 		CTRL_V = 22
                           000017    64 		CTRL_W = 23
                           000018    65 		CTRL_X = 24
                           000019    66 		CTRL_Y = 25
                           00001A    67 		CTRL_Z = 26
                           00001B    68 		ESC = 27
                           000020    69 		SPACE = 32
                           00002C    70 		COMMA = 44 
                           000023    71 		SHARP = 35
                           000027    72 		TICK = 39
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 37.
Hexadecimal [24-Bits]



                                     12 
                           000000    13 .if DEBUG 
                                     14 
                                     15 ;-----------------------------
                                     16 ; define these constants 
                                     17 ; according to selected UART 
                                     18 ;-----------------------------
                                     19 STM8S105=0 
                                     20 STM8S103=1
                                     21 
                                     22 .if STM8S105 
                                     23 UART_BRR1=UART2_BRR1 
                                     24 UART_BRR2=UART2_BRR2 
                                     25 UART_DR=UART2_DR 
                                     26 UART_SR=UART2_SR 
                                     27 UART_CR1=UART2_CR1
                                     28 UART_CR2=UART2_CR2 
                                     29 UART_CLK_PCKENR=CLK_PCKENR1 
                                     30 UART_CLK_PCKENR_UART=CLK_PCKENR1_UART2 
                                     31 .else ; STM8S103  
                                     32 UART_BRR1=UART1_BRR1 
                                     33 UART_BRR2=UART1_BRR2 
                                     34 UART_DR=UART1_DR 
                                     35 UART_SR=UART1_SR 
                                     36 UART_CR1=UART1_CR1
                                     37 UART_CR2=UART1_CR2 
                                     38 UART_CLK_PCKENR=CLK_PCKENR1 
                                     39 UART_CLK_PCKENR_UART=CLK_PCKENR1_UART1 
                                     40 .endif 
                                     41 
                                     42 ;----------------------
                                     43 ; UART receive handler 
                                     44 ;----------------------
                                     45 uart_rx_handler:
                                     46     clr RX_CHAR 
                                     47     btjf UART_SR,#UART_SR_RXNE,9$ 
                                     48     ld a,UART_DR
                                     49     ld RX_CHAR, a
                                     50     call uart_putc   
                                     51     cp a,#CTRL_C 
                                     52     jrne 9$ 
                                     53     jp sofware_reset
                                     54 9$:
                                     55     iret 
                                     56 
                                     57 ;------------------
                                     58 ; initialize UART 
                                     59 ; 115200 BAUD 
                                     60 ; 8N1 
                                     61 ;------------------
                                     62 uart_init::
                                     63 ; enable UART clock
                                     64 	bset UART_CLK_PCKENR,#UART_CLK_PCKENR_UART 	
                                     65 uart_set_baud:: 
                                     66 	push a 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 38.
Hexadecimal [24-Bits]



                                     67 	bres UART_CR1,#UART_CR1_PIEN
                                     68 ; baud rate 115200 : Fmaster/115200
                                     69 	ldw x,#FMSTR/115200
                                     70     ld a,#16 
                                     71     div x,a 
                                     72     ld (1,sp),a 
                                     73     ld a,xh 
                                     74     add a,(1,sp)
                                     75     ld UART_BRR2,a ; must be loaded first
                                     76 	ld a,xl 
                                     77     ld UART_BRR1,a 
                                     78     clr UART_DR
                                     79 	mov UART_CR2,#((1<<UART_CR2_TEN)|(1<<UART_CR2_REN)|(1<<UART_CR2_RIEN))
                                     80 ;	bset UART_CR2,#UART_CR2_SBK
                                     81 ;    btjf UART_SR,#UART_SR_TC,.
                                     82 	pop a 
                                     83 	ret
                                     84 
                                     85 ;--------------------
                                     86 ; send a character 
                                     87 ; input:
                                     88 ;   A   character to send
                                     89 ;---------------------------
                                     90 uart_putc:: 
                                     91     btjf UART_SR,#UART_SR_TXE,.
                                     92     ld UART_DR,a 
                                     93     ret 
                                     94 
                                     95 ;--------------------------
                                     96 ; receive a character 
                                     97 ; output:
                                     98 ;   A    0| char 
                                     99 uart_getc::
                                    100     ld a,RX_CHAR 
                                    101     ret 
                                    102 
                                    103 ;------------------
                                    104 ; wait for a character 
                                    105 ; from UART 
                                    106 ; output:
                                    107 ;    A   char 
                                    108 ;--------------------
                                    109 uart_wait_char:
                                    110     call uart_getc 
                                    111     tnz a 
                                    112     jreq uart_wait_char  
                                    113     ret
                                    114 
                                    115 ;-------------------------
                                    116 ; send ASCIZ string 
                                    117 ; input:
                                    118 ;    X    *string 
                                    119 ;-------------------------
                                    120 uart_puts:: 
                                    121     ld a,(x)
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 39.
Hexadecimal [24-Bits]



                                    122     jreq 9$
                                    123     call uart_putc 
                                    124     incw x 
                                    125     jra uart_puts 
                                    126 9$: btjf UART_SR,#UART_SR_TC,9$    
                                    127     ret 
                                    128 
                                    129 ;---------------
                                    130 ; print integer 
                                    131 ; input:
                                    132 ;   X   integer 
                                    133 ;---------------
                                    134 uart_prt_int:
                                    135     push a
                                    136     pushw y 
                                    137     clrw y 
                                    138 1$:
                                    139     cpw x,#0
                                    140     jreq 4$ 
                                    141     ld a,#10
                                    142     div x,a 
                                    143     add a,#'0 
                                    144     push a 
                                    145     incw y 
                                    146     jra 1$ 
                                    147 4$: tnzw y 
                                    148     jreq 7$
                                    149 6$: pop a 
                                    150     call uart_putc 
                                    151     decw y 
                                    152     jrne 6$
                                    153     jra 8$ 
                                    154 7$: ld a,#'0
                                    155     call uart_putc 
                                    156 8$:
                                    157     ld a,#32 
                                    158     call uart_putc 
                                    159     btjf UART_SR,#UART_SR_TC,.
                                    160     popw y 
                                    161     pop a 
                                    162     ret 
                                    163 
                                    164 ;------------------------
                                    165 ; clear terminal screen 
                                    166 ;-------------------------
                                    167 clear_screen:
                                    168     ld a,#27 
                                    169     call uart_putc 
                                    170     ld a,#'c 
                                    171     call uart_putc 
                                    172     ret 
                                    173     
                                    174 .endif ; DEBUG 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 40.
Hexadecimal [24-Bits]

Symbol Table

    .__.$$$.=  002710 L   |     .__.ABS.=  000000 G   |     .__.CPU.=  000000 L
    .__.H$L.=  000001 L   |     ADC1_AWC=  00540E     |     ADC1_AWC=  00540F 
    ADC1_AWS=  00540C     |     ADC1_AWS=  00540D     |     ADC1_CR1=  005401 
    ADC1_CR1=  000000     |     ADC1_CR1=  000001     |     ADC1_CR1=  000004 
    ADC1_CR1=  000005     |     ADC1_CR1=  000006     |     ADC1_CR2=  005402 
    ADC1_CR2=  000003     |     ADC1_CR2=  000004     |     ADC1_CR2=  000005 
    ADC1_CR2=  000006     |     ADC1_CR2=  000001     |     ADC1_CR3=  005403 
    ADC1_CR3=  000007     |     ADC1_CR3=  000006     |     ADC1_CSR=  005400 
    ADC1_CSR=  000006     |     ADC1_CSR=  000004     |     ADC1_CSR=  000000 
    ADC1_CSR=  000001     |     ADC1_CSR=  000002     |     ADC1_CSR=  000003 
    ADC1_CSR=  000007     |     ADC1_CSR=  000005     |     ADC1_DB0=  0053E0 
    ADC1_DB0=  0053E1     |     ADC1_DB1=  0053E2     |     ADC1_DB1=  0053E3 
    ADC1_DB2=  0053E4     |     ADC1_DB2=  0053E5     |     ADC1_DB3=  0053E6 
    ADC1_DB3=  0053E7     |     ADC1_DB4=  0053E8     |     ADC1_DB4=  0053E9 
    ADC1_DB5=  0053EA     |     ADC1_DB5=  0053EB     |     ADC1_DB6=  0053EC 
    ADC1_DB6=  0053ED     |     ADC1_DB7=  0053EE     |     ADC1_DB7=  0053EF 
    ADC1_DB8=  0053F0     |     ADC1_DB8=  0053F1     |     ADC1_DB9=  0053F2 
    ADC1_DB9=  0053F3     |     ADC1_DRH=  005404     |     ADC1_DRL=  005405 
    ADC1_HTR=  005408     |     ADC1_HTR=  005409     |     ADC1_LTR=  00540A 
    ADC1_LTR=  00540B     |     ADC1_TDR=  005406     |     ADC1_TDR=  005407 
    ADC_BIT =  000002     |     ADC_DDR =  005011     |     ADC_INPU=  000003 
    ADC_ODR =  00500F     |     AFR     =  004803     |     AFR0    =  000000 
    AFR1    =  000001     |     AFR2    =  000002     |     AFR3    =  000003 
    AFR4    =  000004     |     AFR5    =  000005     |     AFR6    =  000006 
    AFR7    =  000007     |   2 ALARM_DL   000000 R   |     ALARM_FR=  002EE0 
    ALARM_FR=  0042F6     |     ALARM_GL=  000003     |     ALARM_LE=  00500D 
    ALARM_LE=  00500C     |     ALARM_LE=  00500A     |     ALARM_RL=  000005 
    ALARM_SO=  000004     |     AWU_APR =  0050F1     |     AWU_CSR1=  0050F0 
    AWU_TBR =  0050F2     |     B115200 =  000006     |     B19200  =  000003 
    B230400 =  000007     |     B2400   =  000000     |     B38400  =  000004 
    B460800 =  000008     |     B4800   =  000001     |     B57600  =  000005 
    B921600 =  000009     |     B9600   =  000002     |     BEEP_CSR=  0050F3 
    BELL    =  000007     |     BIT0    =  000000     |     BIT1    =  000001 
    BIT2    =  000002     |     BIT3    =  000003     |     BIT4    =  000004 
    BIT5    =  000005     |     BIT6    =  000006     |     BIT7    =  000007 
    BLOCK_SI=  000040     |     BSP     =  000008     |     CFG_GCR =  007F60 
  2 CHANGE     000009 R   |     CLKOPT  =  004807     |     CLKOPT_C=  000002 
    CLKOPT_E=  000003     |     CLKOPT_P=  000000     |     CLKOPT_P=  000001 
    CLK_CCOR=  0050C9     |     CLK_CKDI=  0050C6     |     CLK_CKDI=  000000 
    CLK_CKDI=  000001     |     CLK_CKDI=  000002     |     CLK_CKDI=  000003 
    CLK_CKDI=  000004     |     CLK_CMSR=  0050C3     |     CLK_CSSR=  0050C8 
    CLK_ECKR=  0050C1     |     CLK_ECKR=  000000     |     CLK_ECKR=  000001 
    CLK_HSIT=  0050CC     |     CLK_ICKR=  0050C0     |     CLK_ICKR=  000002 
    CLK_ICKR=  000000     |     CLK_ICKR=  000001     |     CLK_ICKR=  000003 
    CLK_ICKR=  000004     |     CLK_ICKR=  000005     |     CLK_PCKE=  0050C7 
    CLK_PCKE=  000000     |     CLK_PCKE=  000001     |     CLK_PCKE=  000007 
    CLK_PCKE=  000005     |     CLK_PCKE=  000004     |     CLK_PCKE=  000003 
    CLK_PCKE=  0050CA     |     CLK_PCKE=  000003     |     CLK_PCKE=  000002 
    CLK_SWCR=  0050C5     |     CLK_SWCR=  000000     |     CLK_SWCR=  000001 
    CLK_SWCR=  000002     |     CLK_SWCR=  000003     |     CLK_SWIM=  0050CD 
    CLK_SWR =  0050C4     |     CLK_SWR_=  0000B4     |     CLK_SWR_=  0000E1 
    CLK_SWR_=  0000D2     |   2 CNTDWN     000005 R   |     COMMA   =  00002C 
  2 COUNT      00000A R   |     CPU_A   =  007F00     |     CPU_CCR =  007F0A 
    CPU_PCE =  007F01     |     CPU_PCH =  007F02     |     CPU_PCL =  007F03 
    CPU_SPH =  007F08     |     CPU_SPL =  007F09     |     CPU_XH  =  007F04 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 41.
Hexadecimal [24-Bits]

Symbol Table

    CPU_XL  =  007F05     |     CPU_YH  =  007F06     |     CPU_YL  =  007F07 
    CR      =  00000D     |     CTRL_A  =  000001     |     CTRL_B  =  000002 
    CTRL_C  =  000003     |     CTRL_D  =  000004     |     CTRL_E  =  000005 
    CTRL_F  =  000006     |     CTRL_G  =  000007     |     CTRL_H  =  000008 
    CTRL_I  =  000009     |     CTRL_J  =  00000A     |     CTRL_K  =  00000B 
    CTRL_L  =  00000C     |     CTRL_M  =  00000D     |     CTRL_N  =  00000E 
    CTRL_O  =  00000F     |     CTRL_P  =  000010     |     CTRL_Q  =  000011 
    CTRL_R  =  000012     |     CTRL_S  =  000013     |     CTRL_T  =  000014 
    CTRL_U  =  000015     |     CTRL_V  =  000016     |     CTRL_W  =  000017 
    CTRL_X  =  000018     |     CTRL_Y  =  000019     |     CTRL_Z  =  00001A 
    DEBUG   =  000000     |   2 DELTA      000011 R   |     DEVID_BA=  004865 
    DEVID_EN=  004870     |     DEVID_LO=  0048D2     |     DEVID_LO=  0048D3 
    DEVID_LO=  0048D4     |     DEVID_LO=  0048D5     |     DEVID_LO=  0048D6 
    DEVID_LO=  0048D7     |     DEVID_LO=  0048D8     |     DEVID_WA=  0048D1 
    DEVID_XH=  0048CE     |     DEVID_XL=  0048CD     |     DEVID_YH=  0048D0 
    DEVID_YL=  0048CF     |     DM_BK1RE=  007F90     |     DM_BK1RH=  007F91 
    DM_BK1RL=  007F92     |     DM_BK2RE=  007F93     |     DM_BK2RH=  007F94 
    DM_BK2RL=  007F95     |     DM_CR1  =  007F96     |     DM_CR2  =  007F97 
    DM_CSR1 =  007F98     |     DM_CSR2 =  007F99     |     DM_ENFCT=  007F9A 
    EEPROM_B=  004000     |     EEPROM_E=  00427F     |     EEPROM_S=  000280 
    ESC     =  00001B     |     EXTI_CR1=  0050A0     |     EXTI_CR2=  0050A1 
    FF      =  00000C     |     FLASH_BA=  008000     |     FLASH_CR=  00505A 
    FLASH_CR=  000002     |     FLASH_CR=  000000     |     FLASH_CR=  000003 
    FLASH_CR=  000001     |     FLASH_CR=  00505B     |     FLASH_CR=  000005 
    FLASH_CR=  000004     |     FLASH_CR=  000007     |     FLASH_CR=  000000 
    FLASH_CR=  000006     |     FLASH_DU=  005064     |     FLASH_DU=  0000AE 
    FLASH_DU=  000056     |     FLASH_FP=  00505D     |     FLASH_FP=  000000 
    FLASH_FP=  000001     |     FLASH_FP=  000002     |     FLASH_FP=  000003 
    FLASH_FP=  000004     |     FLASH_FP=  000005     |     FLASH_IA=  00505F 
    FLASH_IA=  000003     |     FLASH_IA=  000002     |     FLASH_IA=  000006 
    FLASH_IA=  000001     |     FLASH_IA=  000000     |     FLASH_NC=  00505C 
    FLASH_NF=  00505E     |     FLASH_NF=  000000     |     FLASH_NF=  000001 
    FLASH_NF=  000002     |     FLASH_NF=  000003     |     FLASH_NF=  000004 
    FLASH_NF=  000005     |     FLASH_PU=  005062     |     FLASH_PU=  000056 
    FLASH_PU=  0000AE     |     FLASH_SI=  002000     |     FMSTR   =  B71B00 
    GPIO_BAS=  005000     |     GPIO_END=  0057FF     |     GPIO_SIZ=  000005 
    HSECNT  =  004809     |     I2C_CCRH=  00521C     |     I2C_CCRH=  000080 
    I2C_CCRH=  0000C0     |     I2C_CCRH=  000080     |     I2C_CCRH=  000000 
    I2C_CCRH=  000001     |     I2C_CCRH=  000000     |     I2C_CCRL=  00521B 
    I2C_CCRL=  00001A     |     I2C_CCRL=  000002     |     I2C_CCRL=  00000D 
    I2C_CCRL=  000050     |     I2C_CCRL=  000090     |     I2C_CCRL=  0000A0 
    I2C_CR1 =  005210     |     I2C_CR1_=  000006     |     I2C_CR1_=  000007 
    I2C_CR1_=  000000     |     I2C_CR2 =  005211     |     I2C_CR2_=  000002 
    I2C_CR2_=  000003     |     I2C_CR2_=  000000     |     I2C_CR2_=  000001 
    I2C_CR2_=  000007     |     I2C_DR  =  005216     |     I2C_FREQ=  005212 
    I2C_ITR =  00521A     |     I2C_ITR_=  000002     |     I2C_ITR_=  000000 
    I2C_ITR_=  000001     |     I2C_OARH=  005214     |     I2C_OARH=  000001 
    I2C_OARH=  000002     |     I2C_OARH=  000006     |     I2C_OARH=  000007 
    I2C_OARL=  005213     |     I2C_OARL=  000000     |     I2C_OAR_=  000813 
    I2C_OAR_=  000009     |     I2C_PECR=  00521E     |     I2C_READ=  000001 
    I2C_SR1 =  005217     |     I2C_SR1_=  000003     |     I2C_SR1_=  000001 
    I2C_SR1_=  000002     |     I2C_SR1_=  000006     |     I2C_SR1_=  000000 
    I2C_SR1_=  000004     |     I2C_SR1_=  000007     |     I2C_SR2 =  005218 
    I2C_SR2_=  000002     |     I2C_SR2_=  000001     |     I2C_SR2_=  000000 
    I2C_SR2_=  000003     |     I2C_SR2_=  000005     |     I2C_SR3 =  005219 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 42.
Hexadecimal [24-Bits]

Symbol Table

    I2C_SR3_=  000001     |     I2C_SR3_=  000007     |     I2C_SR3_=  000004 
    I2C_SR3_=  000000     |     I2C_SR3_=  000002     |     I2C_TRIS=  00521D 
    I2C_TRIS=  000005     |     I2C_TRIS=  000005     |     I2C_TRIS=  000005 
    I2C_TRIS=  000011     |     I2C_TRIS=  000011     |     I2C_TRIS=  000011 
    I2C_WRIT=  000000     |     INPUT_DI=  000000     |     INPUT_EI=  000001 
    INPUT_FL=  000000     |     INPUT_PU=  000001     |     INT_ADC1=  000016 
    INT_AWU =  000001     |     INT_CLK =  000002     |     INT_EXTI=  000003 
    INT_EXTI=  000004     |     INT_EXTI=  000005     |     INT_EXTI=  000006 
    INT_EXTI=  000007     |     INT_FLAS=  000018     |     INT_I2C =  000013 
    INT_RES1=  000008     |     INT_RES2=  000009     |     INT_RES3=  00000F 
    INT_RES4=  000010     |     INT_RES5=  000014     |     INT_RES6=  000015 
    INT_SPI =  00000A     |     INT_TIM1=  00000C     |     INT_TIM1=  00000B 
    INT_TIM2=  00000E     |     INT_TIM2=  00000D     |     INT_TIM4=  000017 
    INT_TLI =  000000     |     INT_UART=  000012     |     INT_UART=  000011 
    INT_VECT=  008060     |     INT_VECT=  00800C     |     INT_VECT=  008010 
    INT_VECT=  008014     |     INT_VECT=  008018     |     INT_VECT=  00801C 
    INT_VECT=  008020     |     INT_VECT=  008024     |     INT_VECT=  008068 
    INT_VECT=  008054     |     INT_VECT=  008000     |     INT_VECT=  008030 
    INT_VECT=  008038     |     INT_VECT=  008034     |     INT_VECT=  008040 
    INT_VECT=  00803C     |     INT_VECT=  008064     |     INT_VECT=  008008 
    INT_VECT=  008004     |     INT_VECT=  008050     |     INT_VECT=  00804C 
    IPR0    =  000002     |     IPR1    =  000001     |     IPR2    =  000000 
    IPR3    =  000003     |     IPR_MASK=  000003     |     ITC_SPR1=  007F70 
    ITC_SPR2=  007F71     |     ITC_SPR3=  007F72     |     ITC_SPR4=  007F73 
    ITC_SPR5=  007F74     |     ITC_SPR6=  007F75     |     ITC_SPR7=  007F76 
    ITC_SPR8=  007F77     |     IWDG_KR =  0050E0     |     IWDG_PR =  0050E1 
    IWDG_RLR=  0050E2     |   2 LAST       00000D R   |     MISCOPT =  004805 
    MISCOPT_=  000004     |     MISCOPT_=  000002     |     MISCOPT_=  000003 
    MISCOPT_=  000000     |     MISCOPT_=  000001     |     NAFR    =  004804 
    NCLKOPT =  004808     |     NHSECNT =  00480A     |     NL      =  00000A 
    NMISCOPT=  004806     |     NMISCOPT=  FFFFFFFB     |     NMISCOPT=  FFFFFFFD 
    NMISCOPT=  FFFFFFFC     |     NMISCOPT=  FFFFFFFF     |     NMISCOPT=  FFFFFFFE 
    NOPT1   =  004802     |     NOPT2   =  004804     |     NOPT3   =  004806 
    NOPT4   =  004808     |     NOPT5   =  00480A     |     NUBC    =  004802 
  6 NonHandl   000000 R   |     OPT0    =  004800     |     OPT1    =  004801 
    OPT2    =  004803     |     OPT3    =  004805     |     OPT4    =  004807 
    OPT5    =  004809     |     OPTION_B=  004800     |     OPTION_E=  00480A 
    OUTPUT_F=  000001     |     OUTPUT_O=  000000     |     OUTPUT_P=  000001 
    OUTPUT_S=  000000     |     PA      =  000000     |     PA_CR1  =  005003 
    PA_CR2  =  005004     |     PA_DDR  =  005002     |     PA_IDR  =  005001 
    PA_ODR  =  005000     |     PB      =  000005     |     PB_CR1  =  005008 
    PB_CR2  =  005009     |     PB_DDR  =  005007     |     PB_IDR  =  005006 
    PB_ODR  =  005005     |     PC      =  00000A     |     PC_CR1  =  00500D 
    PC_CR2  =  00500E     |     PC_DDR  =  00500C     |     PC_IDR  =  00500B 
    PC_ODR  =  00500A     |     PD      =  00000F     |     PD_CR1  =  005012 
    PD_CR2  =  005013     |     PD_DDR  =  005011     |     PD_IDR  =  005010 
    PD_ODR  =  00500F     |     PE      =  000014     |   2 PERIOD     000007 R
    PE_CR1  =  005017     |     PE_CR2  =  005018     |     PE_DDR  =  005016 
    PE_IDR  =  005015     |     PE_ODR  =  005014     |     PF      =  000019 
    PF_CR1  =  00501C     |     PF_CR2  =  00501D     |     PF_DDR  =  00501B 
    PF_IDR  =  00501A     |     PF_ODR  =  005019     |     PIN0    =  000000 
    PIN1    =  000001     |     PIN2    =  000002     |     PIN3    =  000003 
    PIN4    =  000004     |     PIN5    =  000005     |     PIN6    =  000006 
    PIN7    =  000007     |     RAM_BASE=  000000     |     RAM_END =  0003FF 
    RAM_SIZE=  000400     |     ROP     =  004800     |     RST_SR  =  0050B3 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 43.
Hexadecimal [24-Bits]

Symbol Table

  2 SAMPLES_   000003 R   |   2 SAMPLES_   000001 R   |     SENSIVIT=  000002 
    SFR_BASE=  005000     |     SFR_END =  0057FF     |     SHARP   =  000023 
  2 SKIP       00000B R   |     SKIP_MAX=  000003     |   2 SLOPE      00000F R
    SPACE   =  000020     |     SPI_CR1 =  005200     |     SPI_CR2 =  005201 
    SPI_CRCP=  005205     |     SPI_DR  =  005204     |     SPI_ICR =  005202 
    SPI_RXCR=  005206     |     SPI_SR  =  005203     |     SPI_TXCR=  005207 
    SWIM_CSR=  007F80     |     TAB     =  000009     |     TICK    =  000027 
    TIM1_ARR=  005262     |     TIM1_ARR=  005263     |     TIM1_BKR=  00526D 
    TIM1_BKR=  000006     |     TIM1_BKR=  000004     |     TIM1_BKR=  000005 
    TIM1_BKR=  000000     |     TIM1_BKR=  000007     |     TIM1_BKR=  000002 
    TIM1_BKR=  000003     |     TIM1_CCE=  00525C     |     TIM1_CCE=  00525D 
    TIM1_CCM=  005258     |     TIM1_CCM=  000000     |     TIM1_CCM=  000001 
    TIM1_CCM=  000004     |     TIM1_CCM=  000005     |     TIM1_CCM=  000006 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000003 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000004 
    TIM1_CCM=  000005     |     TIM1_CCM=  000006     |     TIM1_CCM=  000003 
    TIM1_CCM=  005259     |     TIM1_CCM=  000000     |     TIM1_CCM=  000001 
    TIM1_CCM=  000004     |     TIM1_CCM=  000005     |     TIM1_CCM=  000006 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000003 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000004 
    TIM1_CCM=  000005     |     TIM1_CCM=  000006     |     TIM1_CCM=  000003 
    TIM1_CCM=  00525A     |     TIM1_CCM=  000000     |     TIM1_CCM=  000001 
    TIM1_CCM=  000004     |     TIM1_CCM=  000005     |     TIM1_CCM=  000006 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000003 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000004 
    TIM1_CCM=  000005     |     TIM1_CCM=  000006     |     TIM1_CCM=  000003 
    TIM1_CCM=  00525B     |     TIM1_CCM=  000000     |     TIM1_CCM=  000001 
    TIM1_CCM=  000004     |     TIM1_CCM=  000005     |     TIM1_CCM=  000006 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000003 
    TIM1_CCM=  000007     |     TIM1_CCM=  000002     |     TIM1_CCM=  000004 
    TIM1_CCM=  000005     |     TIM1_CCM=  000006     |     TIM1_CCM=  000003 
    TIM1_CCR=  005265     |     TIM1_CCR=  005266     |     TIM1_CCR=  005267 
    TIM1_CCR=  005268     |     TIM1_CCR=  005269     |     TIM1_CCR=  00526A 
    TIM1_CCR=  00526B     |     TIM1_CCR=  00526C     |     TIM1_CNT=  00525E 
    TIM1_CNT=  00525F     |     TIM1_CR1=  005250     |     TIM1_CR2=  005251 
    TIM1_CR2=  000000     |     TIM1_CR2=  000002     |     TIM1_CR2=  000004 
    TIM1_CR2=  000005     |     TIM1_CR2=  000006     |     TIM1_DTR=  00526E 
    TIM1_EGR=  005257     |     TIM1_ETR=  005253     |     TIM1_ETR=  000006 
    TIM1_ETR=  000000     |     TIM1_ETR=  000001     |     TIM1_ETR=  000002 
    TIM1_ETR=  000003     |     TIM1_ETR=  000007     |     TIM1_ETR=  000004 
    TIM1_ETR=  000005     |     TIM1_IER=  005254     |     TIM1_IER=  000007 
    TIM1_IER=  000001     |     TIM1_IER=  000002     |     TIM1_IER=  000003 
    TIM1_IER=  000004     |     TIM1_IER=  000005     |     TIM1_IER=  000006 
    TIM1_IER=  000000     |     TIM1_OIS=  00526F     |     TIM1_OIS=  000000 
    TIM1_OIS=  000002     |     TIM1_OIS=  000004     |     TIM1_OIS=  000006 
    TIM1_OIS=  000001     |     TIM1_OIS=  000003     |     TIM1_OIS=  000005 
    TIM1_OIS=  000007     |     TIM1_PSC=  005260     |     TIM1_PSC=  005261 
    TIM1_RCR=  005264     |     TIM1_SMC=  005252     |     TIM1_SMC=  000007 
    TIM1_SMC=  000000     |     TIM1_SMC=  000001     |     TIM1_SMC=  000002 
    TIM1_SMC=  000004     |     TIM1_SMC=  000005     |     TIM1_SMC=  000006 
    TIM1_SR1=  005255     |     TIM1_SR1=  000007     |     TIM1_SR1=  000001 
    TIM1_SR1=  000002     |     TIM1_SR1=  000003     |     TIM1_SR1=  000004 
    TIM1_SR1=  000005     |     TIM1_SR1=  000006     |     TIM1_SR1=  000000 
    TIM1_SR2=  005256     |     TIM1_SR2=  000001     |     TIM1_SR2=  000002 
    TIM1_SR2=  000003     |     TIM1_SR2=  000004     |     TIM2_ARR=  00530F 
ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 44.
Hexadecimal [24-Bits]

Symbol Table

    TIM2_ARR=  005319     |     TIM2_CCE=  00530A     |     TIM2_CCE=  00530B 
    TIM2_CCM=  005307     |     TIM2_CCM=  005308     |     TIM2_CCM=  005309 
    TIM2_CCR=  005311     |     TIM2_CCR=  005312     |     TIM2_CCR=  005313 
    TIM2_CCR=  005314     |     TIM2_CCR=  005315     |     TIM2_CCR=  005316 
    TIM2_CNT=  00530C     |     TIM2_CNT=  00530C     |     TIM2_CR1=  005300 
    TIM2_EGR=  005306     |     TIM2_IER=  005303     |     TIM2_PSC=  00530E 
    TIM2_SR1=  005304     |     TIM2_SR2=  005305     |     TIM4_ARR=  005348 
    TIM4_CNT=  005346     |     TIM4_CR1=  005340     |     TIM4_CR1=  000007 
    TIM4_CR1=  000000     |     TIM4_CR1=  000003     |     TIM4_CR1=  000001 
    TIM4_CR1=  000002     |     TIM4_EGR=  005345     |     TIM4_EGR=  000000 
    TIM4_IER=  005343     |     TIM4_IER=  000000     |     TIM4_PSC=  005347 
    TIM4_PSC=  000000     |     TIM4_PSC=  000007     |     TIM4_PSC=  000004 
    TIM4_PSC=  000001     |     TIM4_PSC=  000005     |     TIM4_PSC=  000002 
    TIM4_PSC=  000006     |     TIM4_PSC=  000003     |     TIM4_PSC=  000000 
    TIM4_PSC=  000001     |     TIM4_PSC=  000002     |     TIM4_SR =  005344 
    TIM4_SR_=  000000     |     TIM_CCER=  000000     |     TIM_CCER=  000002 
    TIM_CCER=  000001     |     TIM_CCER=  000004     |     TIM_CCER=  000006 
    TIM_CCER=  000007     |     TIM_CCER=  000005     |     TIM_CCER=  000002 
    TIM_CCER=  000003     |     TIM_CCER=  000000     |     TIM_CCER=  000001 
    TIM_CCER=  000004     |     TIM_CCER=  000005     |     TIM_CR1_=  000007 
    TIM_CR1_=  000000     |     TIM_CR1_=  000006     |     TIM_CR1_=  000005 
    TIM_CR1_=  000004     |     TIM_CR1_=  000003     |     TIM_CR1_=  000001 
    TIM_CR1_=  000002     |     TIM_EGR_=  000007     |     TIM_EGR_=  000001 
    TIM_EGR_=  000002     |     TIM_EGR_=  000003     |     TIM_EGR_=  000004 
    TIM_EGR_=  000005     |     TIM_EGR_=  000006     |     TIM_EGR_=  000000 
    TIMx_CCR=  000000     |     TIMx_CCR=  000004     |     TIMx_CCR=  000003 
    TMR1_DC =  002904     |     TMR1_PER=  002EE0     |   6 Timer4Ha   000006 R
    UART1_BR=  005232     |     UART1_BR=  005233     |     UART1_CR=  005234 
    UART1_CR=  005235     |     UART1_CR=  005236     |     UART1_CR=  005237 
    UART1_CR=  005238     |     UART1_DR=  005231     |     UART1_GT=  005239 
    UART1_PO=  00500F     |     UART1_PS=  00523A     |     UART1_RX=  000003 
    UART1_SR=  005230     |     UART1_TX=  000002     |     UART_CR1=  000004 
    UART_CR1=  000002     |     UART_CR1=  000000     |     UART_CR1=  000001 
    UART_CR1=  000007     |     UART_CR1=  000006     |     UART_CR1=  000005 
    UART_CR1=  000003     |     UART_CR2=  000004     |     UART_CR2=  000002 
    UART_CR2=  000005     |     UART_CR2=  000001     |     UART_CR2=  000000 
    UART_CR2=  000006     |     UART_CR2=  000003     |     UART_CR2=  000007 
    UART_CR3=  000003     |     UART_CR3=  000001     |     UART_CR3=  000002 
    UART_CR3=  000000     |     UART_CR3=  000006     |     UART_CR3=  000004 
    UART_CR3=  000005     |     UART_CR4=  000000     |     UART_CR4=  000001 
    UART_CR4=  000002     |     UART_CR4=  000003     |     UART_CR4=  000004 
    UART_CR4=  000006     |     UART_CR4=  000005     |     UART_CR5=  000003 
    UART_CR5=  000001     |     UART_CR5=  000002     |     UART_CR5=  000004 
    UART_CR5=  000005     |     UART_SR_=  000001     |     UART_SR_=  000004 
    UART_SR_=  000002     |     UART_SR_=  000003     |     UART_SR_=  000000 
    UART_SR_=  000005     |     UART_SR_=  000006     |     UART_SR_=  000007 
    UBC     =  004801     |     VT      =  00000B     |     WWDG_CR =  0050D1 
    WWDG_WR =  0050D2     |     XOFF    =  000013     |     XON     =  000011 
  6 adc_read   0001A1 R   |   6 adjust_a   000140 R   |   6 alarm      000157 R
  6 clock_in   000014 R   |   6 cold_sta   000014 R   |   6 detector   000113 R
  6 flush_ca   0001C4 R   |   6 init_det   0000F6 R   |   6 pause      0001DF R
  6 power_on   0001E9 R   |   6 sample     000193 R   |   6 send_pul   0001BA R
  6 set_tone   000214 R   |   6 sofware_   000001 R   |   6 stack_in   00002A R
  6 timer2_i   00008D R   |   6 timer4_i   000074 R

ASxxxx Assembler V02.00 + NoICE + SDCC mods  (STMicroelectronics STM8), page 45.
Hexadecimal [24-Bits]

Area Table

   0 _CODE      size      0   flags    0
   1 DATA       size      0   flags    8
   2 DATA0      size     13   flags    8
   3 SSEG       size      0   flags    8
   4 SSEG1      size    100   flags    8
   5 HOME       size     80   flags    0
   6 CODE       size    236   flags    0

