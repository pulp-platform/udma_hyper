# 189MHz for SoC clock and 77MHz for the hyper bus "phy" part, which means 144MHz from phy_clk_i
set period_sys 6000
set period_phy 13000

set_ideal_network rst_ni
set_ideal_network phy_rst_ni
set_max_area 0

create_clock -name sys_clk -period $period_sys [get_ports sys_clk_i]
create_clock -name phy_twotimes -period [expr $period_phy/2] [get_ports phy_clk_i]

set_false_path -from [get_ports rst_ni] -hold
set_false_path -from [get_ports phy_rst_ni] -hold

# The following command corresponds to 
create_generated_clock -name clk_phy -source [get_ports phy_clk_i] -divide_by 2 [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/r_clk0_o_reg/Q]
create_generated_clock -name clk_90 -source [get_ports phy_clk_i] -edges {2 4 6} [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/r_clk90_o_reg/Q] 

create_generated_clock -name hyper_ck_o -source [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/r_clk90_o_reg/Q]  -divide_by 1 [get_ports pad_hyper_ck]
create_generated_clock -name hyper_ckn_o -source [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/r_clk90_o_reg/Q]  -divide_by 1 [get_ports pad_hyper_ckn]

# Note
# A small skew between hyper_ck_o and hyper_ck_no is given for this purpose.
set_clock_uncertainty 5 -rise_from [get_clocks hyper_ck_o] -fall_to [get_clocks hyper_ckn_o]
set_clock_uncertainty 5 -fall_from [get_clocks hyper_ck_o] -rise_to [get_clocks hyper_ckn_o]

set_clock_groups -asynchronous -group {phy_twotimes clk_phy hyper_ck_o}
set_clock_groups -asynchronous -group {sys_clk}
set output_ports {{pad_hyper_dq*} {pad_hyper_rwds*}};

# These are DDR output constraints
#1000ps of hold/setup times are comming from the hyperram data sheet. (100MHz operation)
set_output_delay 1000 -clock hyper_ck_o [get_ports $output_ports] -max
set_output_delay [expr -1*1000] -clock hyper_ck_o [get_ports $output_ports] -min -add_delay
set_output_delay 1000 -clock hyper_ck_o [get_ports $output_ports] -max  -clock_fall -add_delay
set_output_delay [expr -1*1000] -clock hyper_ck_o [get_ports $output_ports] -min -clock_fall -add_delay
set_false_path -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_lower_*__ddr_data_lower/q1_reg/Q] -fall_to [get_clocks hyper_ck_o]
set_false_path -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_lower_*__ddr_data_lower/q0_reg/Q] -rise_to [get_clocks hyper_ck_o] 
# De-comment them for 16 pads version
#set_false_path -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_upper_*__ddr_data_upper/q1_reg/Q] -fall_to [get_clocks hyper_ck_o]
#set_false_path -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_upper_*__ddr_data_upper/q0_reg/Q] -rise_to [get_clocks hyper_ck_o]


#To make sure that the oe signals are outputed to the pads with 5ns of the delay at maximum 
set_max_delay [expr $period_phy/2] -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/hyper_dq_oe_o] -to [get_ports pad_hyper_dq*]
set_max_delay [expr $period_phy/2] -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/hyper_rwds_oe_o] -to [get_ports pad_hyper_rwds*]




#These constraints are for reducing the delay of the gray code encoding
set_max_delay -from [all_fanin -to [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_rptr_gray_q[*]}]] \
              -to [all_fanout -from [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_rptr_gray_q[*]}]] [expr $period_phy/2]
set_max_delay -from [all_fanin -to [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q[*]}]] \
               -to [all_fanout -from [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q[*]}]] [expr $period_phy/2]

set_max_delay -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_rptr_bin_q[*]]] \
               -to [all_fanout -from [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_rptr_gray_q[*]]] [expr $period_phy/2]

set_max_delay -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/read_clk_en]] \
              -to [all_fanout -from [get_nets  i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/read_in_valid]] [expr $period_phy/2]



set_propagated_clock [all_clocks]



set_load 15 [get_ports pad_hyper_dq*]
set_load 15 [get_ports pad_hyper_rwds*]
set_load 15 [get_ports pad_hyper_ck]
set_load 15 [get_ports pad_hyper_ckn]
set_load 15 [get_ports pad_hyper_csn*]

