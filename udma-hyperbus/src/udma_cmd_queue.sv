// Copyright 2018-2021 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//// Hayate Okuhara <hayate.okuhara@unibo.it>

// Configuration register for Hyper bus CHANNEl
module udma_cmd_queue #(
                          parameter L2_AWIDTH_NOAL = 12,
                          parameter TRANS_SIZE     = 16,
                          parameter BUFFER_DEPTH   =  8,
                          parameter MAX_NB_TRAN    =  8
                          ) (
	                     input logic                       sys_clk_i,
                             input logic                       phy_clk_i,
	                     input logic                       rst_ni,

	                     input logic [31:0]                cfg_data_i,
	                     input logic [4:0]                 cfg_addr_i,
	                     input logic                       cfg_valid_i,
	                     input logic                       cfg_reg_rwn_i,
                             output logic [31:0]               cfg_data_o,
	                     output logic                      cfg_ready_o,

                             input  logic                      running_trans_phy_i,
                             input  logic                      proc_id_sys_i,
                             input  logic                      proc_id_phy_i,

                             output logic [L2_AWIDTH_NOAL*2+TRANS_SIZE*6+32+16+1+1+1+1+1-1:0] trans_cmd_data_o,
                             output logic                      trans_cmd_valid_o,
                             input  logic                      trans_cmd_ready_i,
                             output logic                      evt_eot_o,
                             output logic                      busy_o
                             );


   

/////////////////////////Config register/////////////////////////////////

   logic [L2_AWIDTH_NOAL-1:0]     cfg_rx_start_addr;
   logic [L2_AWIDTH_NOAL-1:0]     cfg_tx_start_addr;
   logic [TRANS_SIZE-1:0]         cfg_rx_size;
   logic [TRANS_SIZE-1:0]         cfg_tx_size;
   logic [31:0]                   cfg_hyper_addr;
   logic [15:0]                   cfg_hyper_intreg;
   logic                          cfg_rw_hyper;
   logic                          cfg_addr_space;
   logic                          cfg_rx_en;
   logic                          cfg_tx_en;
   logic                          cfg_burst_type;
   logic                          trans_cfg_valid;
   logic                          trans_cfg_ready;
   logic                          running_trans_sys;
   logic [$clog2(BUFFER_DEPTH):0] nb_trans_waiting;

   logic                          cfg_twd_trans_ext_act;
   logic [TRANS_SIZE-1:0]         cfg_twd_trans_ext_count;
   logic [TRANS_SIZE-1:0]         cfg_twd_trans_ext_stride;
   logic                          cfg_twd_trans_l2_act;
   logic [TRANS_SIZE-1:0]         cfg_twd_trans_l2_count;
   logic [TRANS_SIZE-1:0]         cfg_twd_trans_l2_stride;



   assign running_trans_sys = trans_cfg_valid | trans_cmd_valid_o;

   udma_hyper_reg_if_mulid #(
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .TRANS_SIZE(TRANS_SIZE),
      .MAX_NB_TRAN(MAX_NB_TRAN)
   ) u_reg_if (
      .clk_i                          ( sys_clk_i                    ),
      .rst_ni                         ( rst_ni                       ),

      .cfg_data_i                     ( cfg_data_i                   ),
      .cfg_addr_i                     ( cfg_addr_i                   ),
      .cfg_valid_i                    ( cfg_valid_i                  ),
      .cfg_reg_rwn_i                  ( cfg_reg_rwn_i                ),
      .cfg_ready_o                    ( cfg_ready_o                  ),
      .cfg_data_o                     ( cfg_data_o                   ),

      .cfg_rx_startaddr_o             ( cfg_rx_start_addr            ),
      .cfg_rx_size_o                  ( cfg_rx_size                  ),
      .cfg_rx_en_o                    ( cfg_rx_en                    ),
      .cfg_rx_datasize_o              (),
      .cfg_rx_continuous_o            (),
      .cfg_rx_clr_o                   (),
      .cfg_rx_en_i                    (),
      .cfg_rx_pending_i               (),

      .cfg_tx_startaddr_o             ( cfg_tx_start_addr            ),
      .cfg_tx_size_o                  ( cfg_tx_size                  ),
      .cfg_tx_en_o                    ( cfg_tx_en                    ),
      .cfg_tx_continuous_o            (),
      .cfg_tx_datasize_o              (),
      .cfg_tx_clr_o                   (),
      .cfg_tx_en_i                    (),
      .cfg_tx_pending_i               (),
     
      .cfg_hyper_addr_o               ( cfg_hyper_addr               ),
      .cfg_hyper_intreg_o             ( cfg_hyper_intreg             ),
      .cfg_rw_hyper_o                 ( cfg_rw_hyper                 ),
      .cfg_addr_space_o               ( cfg_addr_space               ),
      .cfg_burst_type_o               ( cfg_burst_type               ),

      .cfg_twd_trans_ext_act_o        ( cfg_twd_trans_ext_act        ),
      .cfg_twd_trans_ext_count_o      ( cfg_twd_trans_ext_count      ),
      .cfg_twd_trans_ext_stride_o     ( cfg_twd_trans_ext_stride     ),
      .cfg_twd_trans_l2_act_o         ( cfg_twd_trans_l2_act         ),
      .cfg_twd_trans_l2_count_o       ( cfg_twd_trans_l2_count       ),
      .cfg_twd_trans_l2_stride_o      ( cfg_twd_trans_l2_stride      ),


      .trans_ready_i                  ( trans_cfg_ready              ),
      .nb_trans_waiting_i             ( nb_trans_waiting             ),
      .busy_i                         ( busy_o                       ),
      .trans_valid_o                  ( trans_cfg_valid              )
   );


   udma_hyper_busy busy_detector(
           .sys_clk_i           ( sys_clk_i             ),
           .phy_clk_i           ( phy_clk_i             ),
           .rst_ni              ( rst_ni                ),

           .running_trans_sys_i ( running_trans_sys     ),
           .running_trans_phy_i ( running_trans_phy_i   ),
           .proc_id_sys_i       ( proc_id_sys_i         ),
           .proc_id_phy_i       ( proc_id_phy_i         ),

           .evt_eot_o           ( evt_eot_o             ),
           .busy_o              ( busy_o                )
);

   io_generic_fifo  #(
      .DATA_WIDTH         ( L2_AWIDTH_NOAL*2+TRANS_SIZE*6+32+16+1+1+1+1+1 ),
      .BUFFER_DEPTH       ( BUFFER_DEPTH                                  ),
      .LOG_BUFFER_DEPTH   ( $clog2(BUFFER_DEPTH)                          )
   ) twd_tran_fifo_i
   (
      .clk_i              ( sys_clk_i                                     ),
      .rstn_i             ( rst_ni                                        ),

      .clr_i              ( 1'b0                                          ),

      .valid_i            ( trans_cfg_valid                               ),
      .ready_o            ( trans_cfg_ready                               ),
      .data_i             ( {cfg_rx_start_addr,         cfg_rx_size,
                             cfg_tx_start_addr,         cfg_tx_size,
                             cfg_hyper_addr,            cfg_hyper_intreg,
                             cfg_rw_hyper,              cfg_addr_space,     
                             cfg_burst_type,            cfg_twd_trans_ext_act, 
                             cfg_twd_trans_ext_count,   cfg_twd_trans_ext_stride, 
                             cfg_twd_trans_l2_act,      cfg_twd_trans_l2_count,   
                             cfg_twd_trans_l2_stride} ),

      .elements_o         ( nb_trans_waiting                              ),

      .valid_o            ( trans_cmd_valid_o                             ),
      .ready_i            ( trans_cmd_ready_i                             ),
      .data_o             ( trans_cmd_data_o                              )
   );



endmodule
