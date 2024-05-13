
set step_delay 0.05
set start_delay 0.5
for {set i 0} {$i < 32} {incr i +2} {
     set_max_delay -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/in] -to [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/genblk2_4__genblk1_[expr $i]__genblk1_i_clk_mux/A] [expr $start_delay + $step_delay*($i+1)]
     set_min_delay -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/in] -to [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/genblk2_4__genblk1_[expr $i]__genblk1_i_clk_mux/A] [expr $start_delay + $step_delay*($i)]
     set_max_delay -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/in] -to [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/genblk2_4__genblk1_[expr $i]__genblk1_i_clk_mux/B] [expr $start_delay + $step_delay*($i+2)]
     set_min_delay -from [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/in] -to [get_pins i_udma_hyper_top/udma_hyperbus_i/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/genblk2_4__genblk1_[expr $i]__genblk1_i_clk_mux/B] [expr $start_delay + $step_delay*($i+1)]
}

