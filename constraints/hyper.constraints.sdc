set period_sys 5
## 1/period_phy is half of periph_domain_clock from Pulp (--> 180MHz)
set period_phy 11

set_ideal_network rstn_i
set_ideal_network sys_clk_i
set_ideal_network periph_clk_i
set_max_area 0

create_clock -name sys_clk -period $period_sys [get_ports sys_clk_i]
create_clock -name phy_twotimes -period [expr $period_phy/2] [get_ports periph_clk_i]
create_clock -name rwds_clk -period [expr $period_phy] [get_ports pad_hyper_rwds]

create_generated_clock -name clk_phy -source [get_ports periph_clk_i] -divide_by 2 [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/clk0_o]
create_generated_clock -name clk_phy_90 -source [get_ports periph_clk_i] -edges {2 4 6} [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/clk90_o] 
create_generated_clock -name hyper_ck_o -source [get_pins i_udma_hyper_top/udma_hyperbus_i/ddr_clk/clk90_o] -divide_by 1 [get_ports pad_hyper_ck] 

set_clock_groups -asynchronous -group {clk_phy hyper_ck_o}
set_clock_groups -asynchronous -group {phy_twotimes rwds_clk}
set_clock_groups -asynchronous -group {sys_clk}
set output_ports {{pad_hyper_dq*} pad_hyper_rwds*};

#1000ps is comming from the hold and setup time of the hyperram operating at 100MHz (it's the worst case)
set_output_delay 1 -clock hyper_ck_o [get_ports $output_ports] -max
set_output_delay [expr -1*1] -clock hyper_ck_o [get_ports $output_ports] -min -add_delay
set_output_delay 1 -clock hyper_ck_o [get_ports $output_ports] -max  -clock_fall -add_delay
set_output_delay [expr -1*1] -clock hyper_ck_o [get_ports $output_ports] -min -clock_fall -add_delay
set_false_path -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_upper[*].ddr_data_upper/q1]] -rise_to [get_clocks clk_phy_90]
set_false_path -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_lower[*].ddr_data_lower/q1]] -rise_to [get_clocks clk_phy_90]
set_false_path -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_upper[*].ddr_data_upper/q0]] -fall_to [get_clocks clk_phy_90]
set_false_path -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/ddr_out_bus_lower[*].ddr_data_lower/q0]] -fall_to [get_clocks clk_phy_90]

set_max_delay [expr $period_phy/2] -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/hyper_dq_oe_o] -to [get_ports pad_hyper_dq*]
set_max_delay [expr $period_phy/2] -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/hyper_rwds_oe_o] -to [get_ports pad_hyper_rwds*]

set_input_delay -max [expr $period_phy/2] -clock rwds_clk [get_ports pad_hyper_dq*]
set_input_delay -min [expr $period_phy/2] -clock rwds_clk [get_ports pad_hyper_dq*] -add_delay
set_input_delay -max [expr $period_phy/2] -clock rwds_clk [get_ports pad_hyper_dq*] -add_delay -clock_fall
set_input_delay -min [expr $period_phy/2] -clock rwds_clk [get_ports pad_hyper_dq*] -add_delay -clock_fall

set_max_delay -from [all_fanin -to [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_rptr_gray_q[*]}]] -to [all_fanout -from [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_rptr_gray_q[*]}]] [expr $period_phy/2]
set_max_delay -from [all_fanin -to [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q[*]}]] -to [all_fanout -from [get_nets {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q[*]}]] [expr $period_phy/2]

set_max_delay -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_rptr_bin_q[*]]] -to [all_fanout -from [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_rptr_gray_q[*]]] [expr $period_phy/2]

set_max_delay -from [all_fanin -to [get_nets i_udma_hyper_top/udma_hyperbus_i/phy_i/read_clk_en]] -to [all_fanout -from [get_nets  i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/read_in_valid]] [expr $period_phy/2]

#set_propagated_clock {rwds_clk }
set_propagated_clock [all_clocks]


set_dont_touch [get_cells {i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i}]


