# This script was generated automatically by bender.
set ROOT "/home/adimauro/2021_projects/siracusa/deliverables/siracusa-fe/working_dir/udma_hyper"
set search_path_initial $search_path

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_ASIC \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
        TARGET_TECH_CELLS_TSMC16_PADS_EXCLUDE \
        TARGET_TSMC16 \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-f554d151dffd3242/src/deprecated/cluster_clk_cells.sv" \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-f554d151dffd3242/src/deprecated/pulp_clk_cells.sv" \
        "$ROOT/.bender/git/checkouts/tech_cells_generic-f554d151dffd3242/src/deprecated/pulp_clock_gating_async.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/include"

if {[catch {analyze -format sv \
    -define { \
        TARGET_ASIC \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
        TARGET_TECH_CELLS_TSMC16_PADS_EXCLUDE \
        TARGET_TSMC16 \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/binary_to_gray.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cb_filter_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cdc_2phase.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cf_math_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/clk_div.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/delta_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/ecc_pkg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/edge_propagator_tx.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/exp_backoff.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/fifo_v3.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/gray_to_binary.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/isochronous_spill_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/lfsr.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/lfsr_16bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/lfsr_8bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/mv_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/onehot_to_bin.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/plru_tree.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/popcount.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/rr_arb_tree.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/rstgen_bypass.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/serial_deglitch.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/shift_reg.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/spill_register_flushable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_demux.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_fork.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_intf.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_join.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_mux.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/sub_per_hash.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/sync.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/sync_wedge.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/unread.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/addr_decode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cb_filter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cdc_fifo_2phase.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/ecc_decode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/ecc_encode.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/edge_detect.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/lzc.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/max_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/rstgen.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/spill_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_delay.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_fifo.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_fork_dynamic.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/cdc_fifo_gray.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/fall_through_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/id_queue.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_to_mem.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_arbiter_flushable.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_register.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_xbar.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_arbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/stream_omega_net.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/clock_divider_counter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/find_first_one.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/generic_LFSR_8bit.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/generic_fifo.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/prioarbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/pulp_sync.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/pulp_sync_wedge.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/rrarbiter.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/clock_divider.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/fifo_v2.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/deprecated/fifo_v1.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/edge_propagator.sv" \
        "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/src/edge_propagator_rx.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/include"
lappend search_path "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl"
lappend search_path "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common"

if {[catch {analyze -format sv \
    -define { \
        TARGET_ASIC \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
        TARGET_TECH_CELLS_TSMC16_PADS_EXCLUDE \
        TARGET_TSMC16 \
    } \
    [list \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_pkg.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_interfaces.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_clk_gen.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_event_counter.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_generic_fifo.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_shiftreg.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_apb_if.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_clk_div_cnt.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_ctrl.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_dc_fifo.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_arbiter.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_ch_addrgen.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_tx_fifo.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_tx_fifo_dc.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/io_tx_fifo_mark.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/common/udma_clkgen.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_tx_channels.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_stream_unit.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_rx_channels.sv" \
        "$ROOT/.bender/git/checkouts/udma_core-e07c64982a27cd9e/rtl/core/udma_core.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
lappend search_path "$ROOT/.bender/git/checkouts/common_cells-db45afed768a0883/include"
lappend search_path "$ROOT/udma-hyperbus/src"

if {[catch {analyze -format sv \
    -define { \
        TARGET_ASIC \
        TARGET_SYNOPSYS \
        TARGET_SYNTHESIS \
        TARGET_TECH_CELLS_TSMC16_PADS_EXCLUDE \
        TARGET_TSMC16 \
    } \
    [list \
        "$ROOT/udma-hyperbus/src/hyper_pkg.sv" \
        "$ROOT/udma-hyperbus/src/cdc_fifo_gray_hyper.sv" \
        "$ROOT/udma-hyperbus/src/graycode_hyper.sv" \
        "$ROOT/udma-hyperbus/src/clock_diff_out.sv" \
        "$ROOT/udma-hyperbus/src/clk_gen_hyper.sv" \
        "$ROOT/udma-hyperbus/src/onehot_to_bin_hyper.sv" \
        "$ROOT/udma-hyperbus/src/ddr_out.sv" \
        "$ROOT/udma-hyperbus/src/read_clk_rwds.sv" \
        "$ROOT/udma-hyperbus/src/hyperbus_phy.sv" \
        "$ROOT/udma-hyperbus/src/cmd_addr_gen.sv" \
        "$ROOT/udma-hyperbus/src/ddr_in.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_reg_if_common.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_reg_if_mulid.sv" \
        "$ROOT/udma-hyperbus/src/udma_rxbuffer.sv" \
        "$ROOT/udma-hyperbus/src/udma_txbuffer.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_ctrl.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyperbus_mulid.sv" \
        "$ROOT/udma-hyperbus/src/hyper_unpack.sv" \
        "$ROOT/udma-hyperbus/src/udma_cfg_outbuff.sv" \
        "$ROOT/udma-hyperbus/src/hyperbus_mux_generic.sv" \
        "$ROOT/udma-hyperbus/src/hyper_twd_trans_spliter.sv" \
        "$ROOT/udma-hyperbus/src/hyper_rr_flag_req.sv" \
        "$ROOT/udma-hyperbus/src/hyper_arbiter.sv" \
        "$ROOT/udma-hyperbus/src/hyper_arb_primitive.sv" \
        "$ROOT/udma-hyperbus/src/io_generic_fifo_hyper.sv" \
        "$ROOT/udma-hyperbus/src/udma_dc_fifo_hyper.sv" \
        "$ROOT/udma-hyperbus/src/dc_token_ring_fifo_din_hyper.v" \
        "$ROOT/udma-hyperbus/src/dc_token_ring_fifo_dout_hyper.v" \
        "$ROOT/udma-hyperbus/src/dc_token_ring_hyper.v" \
        "$ROOT/udma-hyperbus/src/dc_data_buffer_hyper.sv" \
        "$ROOT/udma-hyperbus/src/dc_full_detector_hyper.v" \
        "$ROOT/udma-hyperbus/src/dc_synchronizer_hyper.v" \
        "$ROOT/udma-hyperbus/src/udma_cmd_queue.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_busy.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_busy_phy.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_top.sv" \
        "$ROOT/udma-hyperbus/src/udma_hyper_wrap.sv" \
        "$ROOT/udma-hyperbus/src/hyper_macro.sv" \
        "$ROOT/udma-hyperbus/src/hyper_macro_bridge.sv" \
        "$ROOT/udma-hyperbus/src/hyperbus_delay_line.sv" \
    ]
}]} {return 1}

set search_path $search_path_initial
