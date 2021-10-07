create_clock -name rwds_clk -period [expr $period_phy] [get_ports pad_hyper_rwds0]
set_clock_groups -asynchronous -group {rwds_clk}

#These are DDR inputconstraints
#1000ps of hold/setup times are comming from the hyperram data sheet. (100MHz operation)

for {set i 0} {$i < 8} {incr i} {

   set_input_delay -max [expr $period_phy/2+1000] -clock rwds_clk [get_ports pad_hyper_dq$i]
   set_input_delay -min [expr $period_phy/2-1000] -clock rwds_clk [get_ports pad_hyper_dq$i] -add_delay
   set_input_delay -max [expr $period_phy/2+1000] -clock rwds_clk [get_ports pad_hyper_dq$i] -add_delay -clock_fall
   set_input_delay -min [expr $period_phy/2-1000] -clock rwds_clk [get_ports pad_hyper_dq$i] -add_delay -clock_fall

}


set_propagated_clock [all_clocks]
