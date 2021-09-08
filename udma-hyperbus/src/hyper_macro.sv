/* 
 * Alfio Di Mauro <adimauro@iis.ee.ethz.ch>
 *
 * Copyright (C) 2018-2020 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 *
 *                http://solderpad.org/licenses/SHL-0.51. 
 *
 * Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

module hyper_macro 
	import udma_pkg::*;
(
	input logic sys_clk_i,
	input logic periph_clk_i,
	input logic rstn_i,

	// configuration from udma core to the macro
	input cfg_req_t hyper_cfg_req_i,
	output cfg_rsp_t hyper_cfg_rsp_o,
	// data channels from/to the macro
	input udma_linch_tx_req_t hyper_linch_tx_req_i,
	output udma_linch_tx_rsp_t hyper_linch_tx_rsp_o,

	output udma_linch_rx_req_t hyper_linch_rx_req_o,
	input udma_linch_rx_rsp_t hyper_linch_rx_rsp_i,

	output udma_evt_t hyper_macro_evt_o,
	input udma_evt_t hyper_macro_evt_i,

	// pad signals
	inout wire logic pad_hyper_reset_n,
	inout wire logic pad_hyper_ck,
	inout wire logic pad_hyper_ckn,
	inout wire logic pad_hyper_csn0,
    inout wire logic pad_hyper_csn1,
	inout wire logic pad_hyper_rwds,
	inout wire logic pad_hyper_dq0,
	inout wire logic pad_hyper_dq1,
	inout wire logic pad_hyper_dq2,
	inout wire logic pad_hyper_dq3,
	inout wire logic pad_hyper_dq4,
	inout wire logic pad_hyper_dq5,
	inout wire logic pad_hyper_dq6,
	inout wire logic pad_hyper_dq7

);

    logic [1:0] hyper_cs_no;
    logic hyper_ck_o;
    logic hyper_ck_no;
    logic [1:0] hyper_rwds_o;
    logic hyper_rwds_i;
    logic [1:0] hyper_rwds_oe_o;
    logic [15:0] hyper_dq_i;
    logic [15:0] hyper_dq_o;
    logic [1:0] hyper_dq_oe_o;
    logic hyper_reset_no;

    logic evt_eot_hyper_s;

    // TODO: Replace with actual pads!
    pad_functional_pd padinst_hyper_csno0  (.OEN( 1'b0                ), .I ( hyper_cs_no[0]  ), .O (               ), .PEN ( 1'b0 ), .PAD ( pad_hyper_csn0  ));
    pad_functional_pd padinst_hyper_csno1  (.OEN( 1'b0                ), .I ( hyper_cs_no[1]  ), .O (               ), .PEN ( 1'b0 ), .PAD ( pad_hyper_csn1  ));
    pad_functional_pd padinst_hyper_ck     (.OEN( 1'b0                ), .I ( hyper_ck_o      ), .O (               ), .PEN ( 1'b0 ), .PAD ( pad_hyper_ck    ));
    pad_functional_pd padinst_hyper_ckno   (.OEN( 1'b0                ), .I ( hyper_ck_no     ), .O (               ), .PEN ( 1'b0 ), .PAD ( pad_hyper_ckn   ));
    pad_functional_pd padinst_hyper_rwds0  (.OEN( ~hyper_rwds_oe_o[0] ), .I ( hyper_rwds_o[0] ), .O ( hyper_rwds_i  ), .PEN ( 1'b0 ), .PAD ( pad_hyper_rwds  ));
    pad_functional_pd padinst_hyper_resetn (.OEN( 1'b0                ), .I ( hyper_reset_no  ), .O (               ), .PEN ( 1'b0 ), .PAD ( pad_hyper_reset ));
    pad_functional_pd padinst_hyper_dqio0  (.OEN( ~hyper_dq_oe_o[0]   ), .I ( hyper_dq_o[0]   ), .O ( hyper_dq_i[0] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq0   ));
    pad_functional_pd padinst_hyper_dqio1  (.OEN( ~hyper_dq_oe_o[1]   ), .I ( hyper_dq_o[1]   ), .O ( hyper_dq_i[1] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq1   ));
    pad_functional_pd padinst_hyper_dqio2  (.OEN( ~hyper_dq_oe_o[2]   ), .I ( hyper_dq_o[2]   ), .O ( hyper_dq_i[2] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq2   ));
    pad_functional_pd padinst_hyper_dqio3  (.OEN( ~hyper_dq_oe_o[3]   ), .I ( hyper_dq_o[3]   ), .O ( hyper_dq_i[3] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq3   ));
    pad_functional_pd padinst_hyper_dqio4  (.OEN( ~hyper_dq_oe_o[4]   ), .I ( hyper_dq_o[4]   ), .O ( hyper_dq_i[4] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq4   ));
    pad_functional_pd padinst_hyper_dqio5  (.OEN( ~hyper_dq_oe_o[5]   ), .I ( hyper_dq_o[5]   ), .O ( hyper_dq_i[5] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq5   ));
    pad_functional_pd padinst_hyper_dqio6  (.OEN( ~hyper_dq_oe_o[6]   ), .I ( hyper_dq_o[6]   ), .O ( hyper_dq_i[6] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq6   ));
    pad_functional_pd padinst_hyper_dqio7  (.OEN( ~hyper_dq_oe_o[7]   ), .I ( hyper_dq_o[7]   ), .O ( hyper_dq_i[7] ), .PEN ( 1'b0 ), .PAD ( pad_hyper_dq7   ));

    udma_hyper_top #(
    	.L2_AWIDTH_NOAL (L2_AWIDTH_NOAL),
    	.TRANS_SIZE     (TRANS_SIZE),
    	.DELAY_BIT_WIDTH(5),
    	.NB_CH          (1)
    ) i_udma_hyper_top (
    	.sys_clk_i          ( sys_clk_i                       ),
    	.periph_clk_i       ( periph_clk_i                    ),
    	.rstn_i             ( rstn_i                          ),
    	.cfg_data_i         ( hyper_cfg_req_i.data            ),
    	.cfg_addr_i         ( hyper_cfg_req_i.addr[5:0]       ),
    	.cfg_valid_i        ( hyper_cfg_req_i.valid           ),
    	.cfg_rwn_i          ( hyper_cfg_req_i.rwn             ),
    	.cfg_ready_o        ( hyper_cfg_rsp_o.ready           ),
    	.cfg_data_o         ( hyper_cfg_rsp_o.data            ),

    	.cfg_rx_startaddr_o ( hyper_linch_rx_req_o.startaddr  ),
    	.cfg_rx_size_o      ( hyper_linch_rx_req_o.size       ),
      .cfg_rx_dest_o      ( hyper_linch_rx_req_o.destination),
    	.cfg_rx_continuous_o( hyper_linch_rx_req_o.continuous ),
    	.cfg_rx_en_o        ( hyper_linch_rx_req_o.cen        ),
    	.cfg_rx_clr_o       ( hyper_linch_rx_req_o.clr        ),
    	.data_rx_datasize_o ( hyper_linch_rx_req_o.datasize   ),
    	.data_rx_o          ( hyper_linch_rx_req_o.data       ),
    	.data_rx_valid_o    ( hyper_linch_rx_req_o.valid      ),
    	.cfg_rx_en_i        ( hyper_linch_rx_rsp_i.en         ),
    	.cfg_rx_pending_i   ( hyper_linch_rx_rsp_i.pending    ),
    	.cfg_rx_curr_addr_i ( hyper_linch_rx_rsp_i.curr_addr  ),
    	.cfg_rx_bytes_left_i( hyper_linch_rx_rsp_i.bytes_left ),
    	.data_rx_ready_i    ( hyper_linch_rx_rsp_i.ready      ),

    	.cfg_tx_startaddr_o ( hyper_linch_tx_rsp_o.startaddr  ),
    	.cfg_tx_size_o      ( hyper_linch_tx_rsp_o.size       ),
      .cfg_tx_dest_o      ( hyper_linch_tx_rsp_o.destination),
    	.cfg_tx_continuous_o( hyper_linch_tx_rsp_o.continuous ),
    	.cfg_tx_en_o        ( hyper_linch_tx_rsp_o.cen        ),
    	.cfg_tx_clr_o       ( hyper_linch_tx_rsp_o.clr        ),
    	.data_tx_req_o      ( hyper_linch_tx_rsp_o.req        ),
    	.data_tx_datasize_o ( hyper_linch_tx_rsp_o.datasize   ),
    	.data_tx_ready_o    ( hyper_linch_tx_rsp_o.ready      ),
    	.cfg_tx_en_i        ( hyper_linch_tx_req_i.en         ),
    	.cfg_tx_pending_i   ( hyper_linch_tx_req_i.pending    ),
    	.cfg_tx_curr_addr_i ( hyper_linch_tx_req_i.curr_addr  ),
    	.cfg_tx_bytes_left_i( hyper_linch_tx_req_i.bytes_left ),
    	.data_tx_gnt_i      ( hyper_linch_tx_req_i.gnt        ),
    	.data_tx_i          ( hyper_linch_tx_req_i.data       ),
    	.data_tx_valid_i    ( hyper_linch_tx_req_i.valid      ),

    	.evt_eot_hyper_o    ( evt_eot_hyper_s                 ),
    	// pad connections
    	.hyper_cs_no        ( hyper_cs_no                     ),
    	.hyper_ck_o         ( hyper_ck_o                      ),
    	.hyper_ck_no        ( hyper_ck_no                     ),
    	.hyper_rwds_o       ( hyper_rwds_o                    ),
    	.hyper_rwds_i       ( hyper_rwds_i                    ),
    	.hyper_rwds_oe_o    ( hyper_rwds_oe_o                 ),
    	.hyper_dq_i         ( hyper_dq_i                      ),
    	.hyper_dq_o         ( hyper_dq_o                      ),
    	.hyper_dq_oe_o      ( hyper_dq_oe_o                   ),
    	.hyper_reset_no     ( hyper_reset_no                  )
    );

    assign hyper_linch_rx_req_o.stream = '0;
    assign hyper_linch_rx_req_o.stream_id = '0;

    logic is_hyper_read_q;
    logic is_hyper_read_d;

    assign hyper_macro_evt_o[0] = hyper_linch_rx_rsp_i.events;
    assign hyper_macro_evt_o[1] = hyper_linch_tx_req_i.events;
    assign hyper_macro_evt_o[2] = |evt_eot_hyper_s & is_hyper_read_d ;
    assign hyper_macro_evt_o[3] = |evt_eot_hyper_s & !is_hyper_read_d;

    assign hyper_dq_i[15:8] = 8'b00000000;

    always @(posedge sys_clk_i, negedge rstn_i) begin
       if(~rstn_i) 
             is_hyper_read_q = 0;
       else
             is_hyper_read_q = is_hyper_read_d;
    end 

    always_comb begin
           if(is_hyper_read_q) begin
                if ( hyper_linch_tx_req_i.events & !hyper_linch_rx_rsp_i.events) begin
                      is_hyper_read_d =0;
                end
                else  is_hyper_read_d =1;
           end 
           else if(!is_hyper_read_q) begin
                if ( hyper_linch_rx_rsp_i.events & !hyper_linch_tx_req_i.events) begin
                      is_hyper_read_d =1;
                end
                else  is_hyper_read_d =0;
           end
    end

endmodule
