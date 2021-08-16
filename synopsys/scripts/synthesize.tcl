# @Author: Alfio Di Mauro
# @Date:   2021-08-16 16:49:29
# @Last Modified by:   Alfio Di Mauro
# @Last Modified time: 2021-08-16 16:50:23

########################
# set up some vars
########################
remove_design -all
exec rm -rf WORK/*

set MACRO_NAME hyper_macro

#source scripts/design_setup.tcl
source scripts/analyze_auto.tcl

set REPORT_DIR reports
set OUTPUT_DIR netlists
exec mkdir -p $REPORT_DIR
exec mkdir -p $OUTPUT_DIR


######################
# elaborate
######################


echo Elaborate toplevel...
elaborate $MACRO_NAME -library WORK > $REPORT_DIR/elaborate.log
set f [open $REPORT_DIR/elaborate.log]
fcopy $f stdout
close $f
#

# ------------------------------------------------------------------------------
#  Define Constraints
#  ------------------------------------------------------------------------------

source scripts/hyper_constraints.sdc
set_dont_touch [get_cells {udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i}]
#############
# Compile
#############
compile_ultra -no_autoungroup
#######################
# Create reports
#######################
check_design -summary > $REPORT_DIR/check_design.log
report_area -hierarchy > $REPORT_DIR/area.log
report_timing -nosplit > $REPORT_DIR/timing.log
report_timing -from [all_inputs] -to [all_outputs] >> $REPORT_DIR/timing.log
report_reference > $REPORT_DIR/references.log

#######################
# Save design
#######################
write_file -hierarchy -output $OUTPUT_DIR/$MACRO_NAME.ddc

# make sure the naming rules are consistent with verilog...
change_names -h -rules verilog
write_file -format verilog -hierarchy -output $OUTPUT_DIR/$MACRO_NAME.v

echo "Done"
