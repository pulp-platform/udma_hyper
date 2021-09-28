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


module udma_hyperbus_mulid
#(
    parameter L2_AWIDTH_NOAL  = 12,
    parameter TRANS_SIZE      = 16,
    parameter DELAY_BIT_WIDTH = 3,
    parameter NR_CS           =2,
    parameter NB_CH           =8
) 
(
    input  logic                      sys_clk_i,
    input  logic                      clk_phy_i,
    input  logic                      clk_phy_i_90,
    input  logic                      rst_ni,
    input  logic                      phy_rst_ni,

    output logic [31:0]               rx_data_udma_o,
    output logic                      rx_valid_udma_o,
    input logic                       rx_ready_udma_i,

    output logic                       data_tx_req_o,
    input  logic                       data_tx_gnt_i,
    output logic                [1:0]  data_tx_datasize_o,
    input  logic               [31:0]  data_tx_i,
    input  logic                       data_tx_valid_i,
    output logic                       data_tx_ready_o,

    input logic [31:0]                cfg_data_i,
    input logic [4:0]                 cfg_addr_i,
    input logic [NB_CH:0]             cfg_valid_i,
    input logic                       cfg_rwn_i,
    output logic [NB_CH:0] [31:0]     cfg_data_o,
    output logic [NB_CH:0]            cfg_ready_o,

    output logic [L2_AWIDTH_NOAL-1:0] udma_rx_startaddr_o,
    output logic [TRANS_SIZE-1:0]     udma_rx_size_o,
    output logic [1:0]                cfg_rx_datasize_o,
    output logic                      cfg_rx_continuous_o,
    output logic                      udma_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input logic                       cfg_rx_en_i,
    input logic                       cfg_rx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]  cfg_rx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]      cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] udma_tx_startaddr_o,
    output logic [TRANS_SIZE-1:0]     udma_tx_size_o,
    output logic [1:0]                cfg_tx_datasize_o,
    output logic                      cfg_tx_continuous_o,
    output logic                      udma_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input logic                       cfg_tx_en_i,
    input logic                       cfg_tx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]  cfg_tx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]      cfg_tx_bytes_left_i,
    output logic [NB_CH-1:0]          evt_eot_hyper_o,

    // physical interface
    output logic [NR_CS-1:0]          hyper_cs_no,
    output logic                      hyper_ck_o,
    output logic                      hyper_ck_no,
    output logic [1:0]                hyper_rwds_o,
    input  logic                      hyper_rwds_i,
    output logic [1:0]                hyper_rwds_oe_o,
    input  logic [15:0]               hyper_dq_i,
    output logic [15:0]               hyper_dq_o,
    output logic [1:0]                hyper_dq_oe_o,
    output logic                      hyper_reset_no,

    //debug
    output logic [1:0]                debug_hyper_rwds_oe_o,
    output logic [1:0]                debug_hyper_dq_oe_o,
    output logic [3:0]                debug_hyper_phy_state_o
 
);
    // configuration
    logic [31:0]                config_t_latency_access;
    logic [31:0]                config_en_latency_additional;
    logic [31:0]                config_t_cs_max;
    logic [31:0]                config_t_read_write_recovery;
    logic [31:0]                config_t_variable_latency_check;
    logic [DELAY_BIT_WIDTH-1:0] config_t_rwds_delay_line;

    // transactions
    logic                   trans_valid;
    logic                   trans_ready;
    logic [31:0]            trans_address;
    logic [NR_CS-1:0]       trans_cs;        // chipselect
    logic                   trans_write;     // transaction is a write
    logic [TRANS_SIZE-1:0]  trans_burst;
    logic                   trans_burst_type;
    logic                   trans_address_space;

    // transmitting
    logic                   tx_valid;
    logic                   tx_ready;
    logic [31:0]            tx_data;
    logic [1:0]             tx_strb_lower;   // mask data
    logic [1:0]             tx_strb_upper;   // mask data
    // receiving channel
    logic                   rx_valid;
    logic                   rx_ready;
    logic [31:0]            rx_data;
    logic                   rx_error;

    logic                   b_valid;
    logic                   b_last;
    logic                   b_error;
    // spram select
    logic [1:0]             mem_sel; 
   
  udma_hyperbus #(
    .L2_AWIDTH_NOAL  (L2_AWIDTH_NOAL),
    .TRANS_SIZE      (TRANS_SIZE),
    .DELAY_BIT_WIDTH (DELAY_BIT_WIDTH),
    .NR_CS           (NR_CS), // not actually a parameter for now :)
    .NB_CH           (NB_CH)
   ) udma_hyper (    
        .sys_clk_i               ( sys_clk_i                    ),
        .clk_phy_i               ( clk_phy_i                    ),
        .clk_phy_i_90            ( clk_phy_i_90                 ),
        .rst_ni                  ( rst_ni                       ),
        .phy_rst_ni              ( phy_rst_ni                   ),

        .cfg_data_i              ( cfg_data_i                   ),
        .cfg_addr_i              ( cfg_addr_i                   ),
        .cfg_valid_i             ( cfg_valid_i                  ),
        .cfg_rwn_i               ( cfg_rwn_i                    ),
        .cfg_ready_o             ( cfg_ready_o                  ),
        .cfg_data_o              ( cfg_data_o                   ),

        .data_tx_req_o           ( data_tx_req_o                ),
        .data_tx_gnt_i           ( data_tx_gnt_i                ),
        .data_tx_valid_i         ( data_tx_valid_i              ),
        .data_tx_i               ( data_tx_i                    ),
        .data_tx_ready_o         ( data_tx_ready_o              ),

        .rx_data_udma_o          ( rx_data_udma_o               ),
        .rx_valid_udma_o         ( rx_valid_udma_o              ),
        .rx_ready_udma_i         ( rx_ready_udma_i              ),

        .udma_rx_startaddr_o     ( udma_rx_startaddr_o          ),
        .udma_rx_size_o          ( udma_rx_size_o               ),
        .cfg_rx_datasize_o       ( cfg_rx_datasize_o            ),
        .cfg_rx_continuous_o     ( cfg_rx_continuous_o          ),
        .udma_rx_en_o            ( udma_rx_en_o                 ),
        .cfg_rx_clr_o            ( cfg_rx_clr_o                 ),
        .cfg_rx_en_i             ( cfg_rx_en_i                  ),
        .cfg_rx_pending_i        ( cfg_rx_pending_i             ),
        .cfg_rx_curr_addr_i      ( cfg_rx_curr_addr_i           ),
        .cfg_rx_bytes_left_i     ( cfg_rx_bytes_left_i          ),

        .udma_tx_startaddr_o     ( udma_tx_startaddr_o          ),
        .udma_tx_size_o          ( udma_tx_size_o               ),
        .cfg_tx_datasize_o       ( cfg_tx_datasize_o            ),
        .cfg_tx_continuous_o     ( cfg_tx_continuous_o          ),
        .udma_tx_en_o            ( udma_tx_en_o                 ),
        .cfg_tx_clr_o            ( cfg_tx_clr_o                 ),
        .cfg_tx_en_i             ( cfg_tx_en_i                  ),
        .cfg_tx_pending_i        ( cfg_tx_pending_i             ),
        .cfg_tx_curr_addr_i      ( cfg_tx_curr_addr_i           ),
        .cfg_tx_bytes_left_i     ( cfg_tx_bytes_left_i          ),
        .evt_eot_hyper_o         ( evt_eot_hyper_o              ),    
        
        .config_t_latency_access(config_t_latency_access),
        .config_en_latency_additional(config_en_latency_additional),
        .config_t_cs_max(config_t_cs_max),
        .config_t_read_write_recovery(config_t_read_write_recovery),
        .config_t_variable_latency_check(config_t_variable_latency_check),
        .config_t_rwds_delay_line(config_t_rwds_delay_line),
        
        .trans_valid_o(trans_valid),
        .trans_ready_i(trans_ready),
        .trans_address_o(trans_address),
        .trans_cs_o(trans_cs),        // chipselect
        .trans_write_o(trans_write),     // transaction is a write
        .trans_burst_o(trans_burst),
        .trans_burst_type_o(trans_burst_type),
        .trans_address_space_o(trans_address_space),       
        
        .tx_valid_o(tx_valid),
        .tx_ready_i(tx_ready),
        .tx_data_o(tx_data),
        .tx_strb_lower_o(tx_strb_lower),   // mask data
        .tx_strb_upper_o(tx_strb_upper),   // mask data
    
        .rx_valid_i(rx_valid),
        .rx_ready_o(rx_ready),
        .rx_data_i(rx_data),
        .rx_error_i(rx_error),
            
        .mem_sel_o(mem_sel)
        );
   
                 
////////////////////Hyper Bus PHY /////////////////////////
  udma_hyperbus_phy #(
    .NR_CS(NR_CS),
    .DELAY_BIT_WIDTH(DELAY_BIT_WIDTH),
    .BURST_WIDTH(TRANS_SIZE)
  ) phy_i (
    .clk0                            ( clk_phy_i                    ),
    .clk90                           ( clk_phy_i_90                 ),
    .rst_ni                          ( phy_rst_ni                   ),
    .test_en_ti                      ( 1'b0                         ),
    .clk_test                        (),

    .config_t_latency_access         ( config_t_latency_access         ),
    .config_en_latency_additional    ( config_en_latency_additional    ),
    .config_t_cs_max                 ( config_t_cs_max                 ),
    .config_t_read_write_recovery    ( config_t_read_write_recovery    ),
    .config_t_rwds_delay_line        ( config_t_rwds_delay_line        ),
    .config_t_variable_latency_check ( config_t_variable_latency_check ),

    .trans_valid_i                   ( trans_valid              ),
    .trans_ready_o                   ( trans_ready              ),

    .trans_address_i                 ( trans_address            ),
    .trans_cs_i                      ( trans_cs                 ),
    .trans_write_i                   ( trans_write              ),
    .trans_burst_i                   ( trans_burst              ),
    .trans_burst_type_i              ( trans_burst_type         ),
    .trans_address_space_i           ( trans_address_space      ),
    .tx_valid_i                      ( tx_valid                 ),
    .tx_ready_o                      ( tx_ready                 ),
    .tx_data_i                       ( tx_data                  ),
    .tx_strb_lower_i                 ( tx_strb_lower            ), 
    .tx_strb_upper_i                 ( tx_strb_upper            ), 
    .rx_valid_o                      ( rx_valid                 ),
    .rx_ready_i                      ( rx_ready                 ),
    .rx_data_o                       ( rx_data                  ),
    .rx_last_o                       ( rx_last                  ),
    .mem_sel_i                       ( mem_sel                  ),
           
    .b_valid_o                       (),
    .b_last_o                        (),
    .b_error_o                       (),
    .rx_error_o                      (),

    .hyper_cs_no                     ( hyper_cs_no                  ),
    .hyper_ck_o                      ( hyper_ck_o                   ),
    .hyper_ck_no                     ( hyper_ck_no                  ),
    .hyper_rwds_o                    ( hyper_rwds_o                 ),
    .hyper_rwds_i                    ( hyper_rwds_i                 ),
    .hyper_rwds_oe_o                 ( hyper_rwds_oe_o              ),
    .hyper_dq_i                      ( hyper_dq_i                   ),
    .hyper_dq_o                      ( hyper_dq_o                   ),
    .hyper_dq_oe_o                   ( hyper_dq_oe_o                ),
    .hyper_reset_no                  ( hyper_reset_no               ),

    .debug_hyper_rwds_oe_o           ( debug_hyper_rwds_oe_o        ),
    .debug_hyper_dq_oe_o             ( debug_hyper_dq_oe_o          ),
    .debug_hyper_phy_state_o         ( debug_hyper_phy_state_o      )
  );

endmodule
