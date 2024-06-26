.PHONY: build lib clean sim simc

mkfile_path := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

VOPT 				?= vopt

VSIM        ?= vsim
VSIM_FLAGS  = -gUSE_SDVT_SPI=0 -gUSE_SDVT_CPI=0 -gBAUDRATE=115200 \
		-gENABLE_DEV_DPI=0 -gLOAD_L2=JTAG -gUSE_SDVT_I2S=0

SVLIB	    =  ../rtl/tb/remote_bitbang/librbs

all: clean lib build opt

sim:
	$(VSIM) -64 -gui vopt_tb \
		-suppress vsim-3009 -suppress vsim-8683 \
		+UVM_NO_RELNOTES -stats -t ps \
		$(VSIM_FLAGS) \
		-do "set StdArithNoWarnings 1; set NumericStdNoWarnings 1;"

simc:
	$(VSIM) -64 -c vopt_tb \
		-suppress vsim-3009 -suppress vsim-8683 \
		+UVM_NO_RELNOTES -stats -t ps \
		$(VSIM_FLAGS) \
		-do "set StdArithNoWarnings 1; set NumericStdNoWarnings 1; run -all" 

opt:
ifdef BENDER
	$(VOPT) +acc=npr -o vopt_tb hyper_macro_tb -floatparameters+hyper_macro_tb -work work
else
	$(mkfile_path)/tcl_files/rtl_vopt.tcl
endif

build:
ifdef BENDER
	$(VSIM) -c -do 'source compile.tcl; quit'
else
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk build
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk build
endif

lib:
ifdef BENDER
	@true
else
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk lib
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk lib
endif

clean: 
ifdef BENDER
	@mkdir -p work
	rm -r work 
else
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk clean
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk clean
endif
	@touch modelsim.ini
	rm modelsim.ini
