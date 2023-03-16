##################################
##  metal-pointer V3
##################################
BOARD=stm8s105k6
PROGRAMMER=stlinkv2
FLASH_SIZE=32768
NAME=metal-pointer
# toolchain
SDAS=sdasstm8
SDCC=sdcc
CFLAGS=-mstm8 
# sources files 
MAIN_FILE=metal-pointer.asm
SRC=$(MAIN_FILE) debug.asm 
INC=inc/
INCLUDES=$(INC)stm8s105.inc $(INC)macros.inc  
BUILD=build/
OBJECTS=$(BUILD)$(SRC:.asm=.rel)
SYMBOLS=$(OBJECTS:.rel=.sym)
LISTS=$(OBJECTS:.rel=.lst)
FLASH=stm8flash

.PHONY:	all

all:	clean asm flash

.PHONY:	clean 

clean: 
	@echo
	@echo "***************"
	@echo "cleaning files"
	@echo "***************"
	-rm -f $(BUILD)*

asm: $(SRC) $(INCLUDE)
	@echo ""
	@echo "**********************************"
	@echo " assemble and link project"
	@echo "**********************************"
	$(SDAS) -g -l -o $(BUILD)$(NAME).rel $(SRC) 
	$(SDCC) $(CFLAGS) -Wl-u -o $(BUILD)$(NAME).ihx $(BUILD)$(NAME).rel  
	objcopy -Iihex -Obinary  $(BUILD)$(NAME).ihx $(BUILD)$(NAME).bin 
	@echo 
	@ls -l  $(BUILD)$(NAME).bin 
	@echo 

flash: 
	@echo ""
	@echo "***************"
	@echo "flash program "
	@echo "***************"
	$(FLASH) -c $(PROGRAMMER) -p $(BOARD) -w $(BUILD)$(NAME).bin 

