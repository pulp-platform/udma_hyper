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


module udma_hyper_top #(
  parameter L2_AWIDTH_NOAL =12,
  parameter TRANS_SIZE     =16,
  parameter DELAY_BIT_WIDTH = 3,
  parameter NB_CH          =8
 )
 (
     input  logic                      sys_clk_i,
     input  logic                      periph_clk_i,
     input  logic                      rstn_i,

     input  logic [31:0]               cfg_data_i,
     input  logic [4:0]                cfg_addr_i,
     input  logic [NB_CH:0]            cfg_valid_i,
     input  logic                      cfg_rwn_i,
     output logic [NB_CH:0]            cfg_ready_o,
     output logic [NB_CH:0][31:0]      cfg_data_o,

     output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
     output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
     output logic                      cfg_rx_continuous_o,
     output logic                      cfg_rx_en_o,
     output logic                      cfg_rx_clr_o,
     input  logic                      cfg_rx_en_i,
     input  logic                      cfg_rx_pending_i,
     input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
     input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,
 
     output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
     output logic     [TRANS_SIZE-1:0] cfg_tx_size_o,
     output logic                      cfg_tx_continuous_o,
     output logic                      cfg_tx_en_o,
     output logic                      cfg_tx_clr_o,
     input  logic                      cfg_tx_en_i,
     input  logic                      cfg_tx_pending_i,
     input  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i,
     input  logic     [TRANS_SIZE-1:0] cfg_tx_bytes_left_i,
     output logic          [NB_CH-1:0] evt_eot_hyper_o,

    output logic                       data_tx_req_o,
    input  logic                       data_tx_gnt_i,
    output logic                [1:0]  data_tx_datasize_o,
    input  logic               [31:0]  data_tx_i,
    input  logic                       data_tx_valid_i,
    output logic                       data_tx_ready_o,

    output logic                [1:0]  data_rx_datasize_o,
    output logic               [31:0]  data_rx_o,
    output logic                       data_rx_valid_o,
    input  logic                       data_rx_ready_i,

    // physical interface
    output logic [1:0]                 hyper_cs_no,
    output logic                       hyper_ck_o,
    output logic                       hyper_ck_no,
    output logic [1:0]                 hyper_rwds_o,
    input  logic                       hyper_rwds_i,
    output logic [1:0]                 hyper_rwds_oe_o,
    input  logic [15:0]                hyper_dq_i,
    output logic [15:0]                hyper_dq_o,
    output logic [1:0]                 hyper_dq_oe_o,
    output logic                       hyper_reset_no

    //debug
    //output logic                       debug_hyper_rwds_oe_o,
    //output logic                       debug_hyper_dq_oe_o,
    //output logic [3:0]                 debug_hyper_phy_state_o

 );

    logic [31:0] s_data_tx;
    logic         s_data_tx_valid;
    logic         s_data_tx_ready;

     io_tx_fifo #(
      .DATA_WIDTH(32),
      .BUFFER_DEPTH(4)
      ) u_fifo (
        .clk_i   ( sys_clk_i       ),
        .rstn_i  ( rstn_i          ),
        .clr_i   ( 1'b0            ),
        .data_o  ( s_data_tx       ),
        .valid_o ( s_data_tx_valid ),
        .ready_i ( s_data_tx_ready ),
        .req_o   ( data_tx_req_o   ),
        .gnt_i   ( data_tx_gnt_i   ),
        .valid_i ( data_tx_valid_i ),
        .data_i  ( data_tx_i       ),
        .ready_o ( data_tx_ready_o )
    );

    udma_hyperbus_mulid #(
     .L2_AWIDTH_NOAL ( L2_AWIDTH_NOAL ),
     .TRANS_SIZE     ( TRANS_SIZE     ),
     .DELAY_BIT_WIDTH ( DELAY_BIT_WIDTH ),
     .NB_CH          ( NB_CH          )
    ) udma_hyperbus_i
    (
        .sys_clk_i               ( sys_clk_i                    ),
        .phy_clk_i               ( periph_clk_i                 ),
        .rst_ni                  ( rstn_i                       ),
        .phy_rst_ni              ( rstn_i                       ),

        .cfg_data_i              ( cfg_data_i                   ),
        .cfg_addr_i              ( cfg_addr_i                   ),
        .cfg_valid_i             ( cfg_valid_i                  ),
        .cfg_rwn_i               ( cfg_rwn_i                    ),
        .cfg_ready_o             ( cfg_ready_o                  ),
        .cfg_data_o              ( cfg_data_o                   ),

        .tx_data_udma_i          ( s_data_tx                    ),
        .tx_valid_udma_i         ( s_data_tx_valid              ),
        .tx_ready_udma_o         ( s_data_tx_ready              ),

        .rx_data_udma_o          ( data_rx_o                    ),
        .rx_valid_udma_o         ( data_rx_valid_o              ),
        .rx_ready_udma_i         ( data_rx_ready_i              ),

        .udma_rx_startaddr_o     ( cfg_rx_startaddr_o           ),
        .udma_rx_size_o          ( cfg_rx_size_o                ),
        .cfg_rx_datasize_o       ( data_rx_datasize_o           ),
        .cfg_rx_continuous_o     ( cfg_rx_continuous_o          ),
        .udma_rx_en_o            ( cfg_rx_en_o                  ),
        .cfg_rx_clr_o            ( cfg_rx_clr_o                 ),
        .cfg_rx_en_i             ( cfg_rx_en_i                  ),
        .cfg_rx_pending_i        ( cfg_rx_pending_i             ),
        .cfg_rx_curr_addr_i      ( cfg_rx_curr_addr_i           ),
        .cfg_rx_bytes_left_i     ( cfg_rx_bytes_left_i          ),

        .udma_tx_startaddr_o     ( cfg_tx_startaddr_o           ),
        .udma_tx_size_o          ( cfg_tx_size_o                ),
        .cfg_tx_datasize_o       ( data_tx_datasize_o           ),
        .cfg_tx_continuous_o     ( cfg_tx_continuous_o          ),
        .udma_tx_en_o            ( cfg_tx_en_o                  ),
        .cfg_tx_clr_o            ( cfg_tx_clr_o                 ),
        .cfg_tx_en_i             ( cfg_tx_en_i                  ),
        .cfg_tx_pending_i        ( cfg_tx_pending_i             ),
        .cfg_tx_curr_addr_i      ( cfg_tx_curr_addr_i           ),
        .cfg_tx_bytes_left_i     ( cfg_tx_bytes_left_i          ),
        .evt_eot_hyper_o         ( evt_eot_hyper_o              ),

        .hyper_cs_no             ( hyper_cs_no                  ),
        .hyper_ck_o              ( hyper_ck_o                   ),
        .hyper_ck_no             ( hyper_ck_no                  ),
        .hyper_rwds_o            ( hyper_rwds_o                 ),
        .hyper_rwds_i            ( hyper_rwds_i                 ),
        .hyper_rwds_oe_o         ( hyper_rwds_oe_o              ),
        .hyper_dq_i              ( hyper_dq_i                   ),
        .hyper_dq_o              ( hyper_dq_o                   ),
        .hyper_dq_oe_o           ( hyper_dq_oe_o                ),
        .hyper_reset_no          ( hyper_reset_no               ),
        .debug_hyper_rwds_oe_o   ( ),
        .debug_hyper_dq_oe_o     ( ),
        .debug_hyper_phy_state_o ( )
    );
endmodule
