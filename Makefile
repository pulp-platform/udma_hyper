.DEFAULT_GOAL := help

SHELL=bash

export VSIM_PATH=$(PWD)/sim
export BENDER=1

export MSIM_LIBS_PATH=$(VSIM_PATH)/modelsim_libs

define declareInstallFile

$(VSIM_PATH)/$(1): sim/$(1)
	install -v -D sim/$(1) $$@

INSTALL_HEADERS += $(VSIM_PATH)/$(1)

endef

# make sure the make calls to other makefiles get these flags
export POSTLAYOUT
export POSTSYNTH

$(foreach file, $(INSTALL_FILES), $(eval $(call declareInstallFile,$(file))))

BRANCH ?= master

VLOG_ARGS += -suppress 2583 -suppress 13314
BENDER_SIM_BUILD_DIR = sim

ifdef GF22
export GF22
BENDER_SYNTH_DIR ?= gf22/synopsys/scripts
BENDER_TARGETS += -t gf22_SC8T -t hyper_external
else ifdef TSMC16
export TSMC16
BENDER_SYNTH_DIR ?= tsmc16/synopsys/scripts
BENDER_TARGETS += -t synthesis -t tsmc16 -t tech_cells_tsmc16_pwr_cells_exclude -t hyper_external
else
BENDER_TARGETS += -t tech_cells_tsmc16_pads_include -t hyper_external
endif

scripts-bender-vsim: | Bender.lock
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > $(BENDER_SIM_BUILD_DIR)/compile.tcl
	./bender script vsim \
		--vlog-arg="$(VLOG_ARGS)" --vcom-arg="" \
		-t rtl -t test $(BENDER_TARGETS) \
		| grep -v "set ROOT" >> $(BENDER_SIM_BUILD_DIR)/compile.tcl

scripts-bender-vsim_tech_cells: | Bender.lock
ifdef TSMC16
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > $(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl
	echo 'set SIRACUSA_IPS_PATH ' $(SIRACUSA_IPS_PATH) >> $(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl
	./bender -d ../tech_cell_models script vsim -t test $(CELL_FLAVORS) $(BENDER_TARGETS) \
     | grep -v "set ROOT" >> $(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl
else
	@true
endif

$(BENDER_SIM_BUILD_DIR)/compile.tcl: Bender.lock
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > $(BENDER_SIM_BUILD_DIR)/compile.tcl
	./bender script vsim \
		--vlog-arg="$(VLOG_ARGS)" --vcom-arg="" \
		-t rtl -t test -t tech_cells_tsmc_pads_include $(BENDER_TARGETS) \
		| grep -v "set ROOT" >> $(BENDER_SIM_BUILD_DIR)/compile.tcl

$(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl: | Bender.lock
ifdef TSMC16
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > $(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl
	./bender -d ../tech_cell_models script vsim -t test $(CELL_FLAVORS) $(BENDER_TARGETS) \
	  | grep -v "set ROOT" >> $(BENDER_SIM_BUILD_DIR)/compile_tech_cells.tcl
else
	@true
endif

scripts-bender-synopsys: | Bender.lock
	mkdir -p $(BENDER_SYNTH_DIR)
	./bender script synopsys \
	-t asic $(BENDER_TARGETS) > $(BENDER_SYNTH_DIR)/analyze_auto.tcl

BENDER_LOCAL_FILE = $(shell find -name Bender.local)
Bender.lock: bender Bender.yml $(BENDER_LOCAL_FILE)
	./bender update
	touch Bender.lock

.PHONY: checkout
## Checkout/update dependencies using IPApprox or Bender

checkout: bender
	./bender update
	touch Bender.lock

.PHONY: clean

## generic clean and build targets for the platform
clean:
# 	rm -rf $(VSIM_PATH)
	$(MAKE) -C sim BENDER=$(BENDER) clean

build: $(BENDER_SIM_BUILD_DIR)/compile.tcl
	@test -f Bender.lock || { echo "ERROR: Bender.lock file does not exist. Did you run make checkout in bender mode?"; exit 1; }
	@test -f $(BENDER_SIM_BUILD_DIR)/compile.tcl || { echo "ERROR: sim/compile.tcl file does not exist. Did you run make scripts in bender mode?"; exit 1; }
	cd sim && $(MAKE) BENDER=bender all
	cd sim && vmap -c && vmap work $$(readlink -f work)

sim: build
	cd sim && $(MAKE) BENDER=bender sim

## Download the IP management tool bender binary
bender:
ifeq (,$(wildcard ./bender))
	curl --proto '=https' --tlsv1.2 -sSf https://fabianschuiki.github.io/bender/init \
		| bash -s -- 0.22.0
	touch bender
endif

bender-rm:
	rm -f bender

.PHONY: help
help: Makefile
	@printf "Siracusa SoC\n"
	@printf "Available targets\n\n"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-15s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
