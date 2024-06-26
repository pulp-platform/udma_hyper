module udma_hyper_wrap
    import udma_pkg::udma_evt_t;
    import hyper_pkg::hyper_to_pad_t;
    import hyper_pkg::pad_to_hyper_t;
(
    input  logic         sys_clk_i,
    input  logic         periph_clk_i,
	input  logic         rstn_i,

	input  logic  [31:0] cfg_data_i,
	input  logic   [4:0] cfg_addr_i,
	input  logic  [1:0]  cfg_valid_i,
	input  logic         cfg_rwn_i,
	output logic  [1:0]  cfg_ready_o,
    output logic  [1:0][31:0] cfg_data_o,

    output udma_evt_t    events_o,
    input  udma_evt_t    events_i,

    // UDMA CHANNEL CONNECTION
    UDMA_LIN_CH.tx_in    tx_ch[ 0:0],
    UDMA_LIN_CH.rx_out   rx_ch[ 0:0],

    // PAD SIGNALS CONNECTION
    output  hyper_to_pad_t hyper_to_pad,
    input   pad_to_hyper_t pad_to_hyper

   );

logic [1:0]  hyper_cs_no;
logic        hyper_ck_o;
logic        hyper_ck_no;
logic [1:0]  hyper_rwds_o;
logic        hyper_rwds_i;
logic [1:0]  hyper_rwds_oe;
logic [15:0] hyper_dq_i;
logic [15:0] hyper_dq_o;
logic [1:0]  hyper_dq_oe;
logic        hyper_reset_no;

logic             evt_eot_hyper_s;

import udma_pkg::TRANS_SIZE;     
import udma_pkg::L2_AWIDTH_NOAL; 



logic is_hyper_read_q;
logic is_hyper_read_d;
  logic s_cfg_ready;

logic[31:0] s_cfg_data_out;

assign cfg_data_o[0] = s_cfg_data_out;
assign cfg_data_o[1] = s_cfg_data_out;

assign cfg_ready_o[0] = s_cfg_ready & cfg_valid_i[0];
assign cfg_ready_o[1] = s_cfg_ready & cfg_valid_i[1];

udma_hyper_top #(
	.L2_AWIDTH_NOAL (L2_AWIDTH_NOAL),
	.TRANS_SIZE     (TRANS_SIZE),
	.DELAY_BIT_WIDTH(5),
	.NB_CH          (1)
) i_udma_hyper_top (
	.sys_clk_i          ( sys_clk_i          ),
	.periph_clk_i       ( periph_clk_i       ),
	.rstn_i             ( rstn_i             ),

	.cfg_data_i         ( cfg_data_i         ),
	.cfg_addr_i         ( {cfg_valid_i[1], cfg_addr_i}),
	.cfg_valid_i        ( |cfg_valid_i       ),
	.cfg_rwn_i          ( cfg_rwn_i          ),
	.cfg_ready_o        ( s_cfg_ready_o      ),
	.cfg_data_o         ( s_cfg_data_out     ),

	.cfg_rx_startaddr_o ( rx_ch[0].startaddr  ),
	.cfg_rx_size_o      ( rx_ch[0].size       ),
  .cfg_rx_dest_o      ( rx_ch[0].destination),
	.cfg_rx_continuous_o( rx_ch[0].continuous ),
	.cfg_rx_en_o        ( rx_ch[0].cen        ),
	.cfg_rx_clr_o       ( rx_ch[0].clr        ),
	.cfg_rx_en_i        ( rx_ch[0].en         ),
	.cfg_rx_pending_i   ( rx_ch[0].pending    ),
	.cfg_rx_curr_addr_i ( rx_ch[0].curr_addr  ),
	.cfg_rx_bytes_left_i( rx_ch[0].bytes_left ),
	.data_rx_datasize_o ( rx_ch[0].datasize   ),
	.data_rx_o          ( rx_ch[0].data       ),
	.data_rx_valid_o    ( rx_ch[0].valid      ),
	.data_rx_ready_i    ( rx_ch[0].ready      ),

	.cfg_tx_startaddr_o ( tx_ch[0].startaddr  ),
	.cfg_tx_size_o      ( tx_ch[0].size       ),
  .cfg_tx_dest_o      ( tx_ch[0].destination),
	.cfg_tx_continuous_o( tx_ch[0].continuous ),
	.cfg_tx_en_o        ( tx_ch[0].cen        ),
	.cfg_tx_clr_o       ( tx_ch[0].clr        ),
	.cfg_tx_en_i        ( tx_ch[0].en         ),
	.cfg_tx_pending_i   ( tx_ch[0].pending    ),
	.cfg_tx_curr_addr_i ( tx_ch[0].curr_addr  ),
	.cfg_tx_bytes_left_i( tx_ch[0].bytes_left ),
	.data_tx_req_o      ( tx_ch[0].req        ),
	.data_tx_gnt_i      ( tx_ch[0].gnt        ),
	.data_tx_datasize_o ( tx_ch[0].datasize   ),
	.data_tx_i          ( tx_ch[0].data       ),
	.data_tx_valid_i    ( tx_ch[0].valid      ),
	.data_tx_ready_o    ( tx_ch[0].ready      ),

	.evt_eot_hyper_o    (evt_eot_hyper_s      ),

	.hyper_cs_no        (hyper_cs_no                     ),
	.hyper_ck_o         (hyper_to_pad.hyper_ck_o         ),
	.hyper_ck_no        (hyper_to_pad.hyper_ck_no        ),

	.hyper_rwds_o       (hyper_rwds_o                    ),
	.hyper_rwds_i       (pad_to_hyper.hyper_rwds_i       ),
	.hyper_rwds_oe_o    (hyper_rwds_oe                   ),

	.hyper_dq_i         (hyper_dq_i                      ),
	.hyper_dq_o         (hyper_dq_o                      ),
	.hyper_dq_oe_o      (hyper_dq_oe                     ),

	.hyper_reset_no     (hyper_to_pad.hyper_reset_no     )
);

assign rx_ch[0].stream = '0;
assign rx_ch[0].stream_id = '0;

assign hyper_to_pad.hyper_rwds_o  = hyper_rwds_o[0];
assign hyper_to_pad.hyper_rwds_oe = hyper_rwds_oe[0];
assign hyper_to_pad.hyper_dq_oe = hyper_dq_oe[0];

assign hyper_to_pad.hyper_cs0_no = hyper_cs_no[0];
assign hyper_to_pad.hyper_cs1_no = hyper_cs_no[1];

assign hyper_to_pad.hyper_dq0_o = hyper_dq_o[0];
assign hyper_to_pad.hyper_dq1_o = hyper_dq_o[1];
assign hyper_to_pad.hyper_dq2_o = hyper_dq_o[2];
assign hyper_to_pad.hyper_dq3_o = hyper_dq_o[3];
assign hyper_to_pad.hyper_dq4_o = hyper_dq_o[4];
assign hyper_to_pad.hyper_dq5_o = hyper_dq_o[5];
assign hyper_to_pad.hyper_dq6_o = hyper_dq_o[6];
assign hyper_to_pad.hyper_dq7_o = hyper_dq_o[7];

assign hyper_dq_i[0] = pad_to_hyper.hyper_dq0_i;
assign hyper_dq_i[1] = pad_to_hyper.hyper_dq1_i;
assign hyper_dq_i[2] = pad_to_hyper.hyper_dq2_i;
assign hyper_dq_i[3] = pad_to_hyper.hyper_dq3_i;
assign hyper_dq_i[4] = pad_to_hyper.hyper_dq4_i;
assign hyper_dq_i[5] = pad_to_hyper.hyper_dq5_i;
assign hyper_dq_i[6] = pad_to_hyper.hyper_dq6_i;
assign hyper_dq_i[7] = pad_to_hyper.hyper_dq7_i;

assign events_o[0] = rx_ch[0].events;
assign events_o[1] = tx_ch[0].events;
assign events_o[2] = |evt_eot_hyper_s & is_hyper_read_d ;
assign events_o[3] = |evt_eot_hyper_s & !is_hyper_read_d;

always @(posedge sys_clk_i, negedge rstn_i) begin
   if(~rstn_i) 
         is_hyper_read_q = 0;
   else
         is_hyper_read_q = is_hyper_read_d;
end 

always_comb begin
       if(is_hyper_read_q) begin
            if ( tx_ch[0].events & !rx_ch[0].events) begin
                  is_hyper_read_d =0;
            end
            else  is_hyper_read_d =1;
       end 
       else if(!is_hyper_read_q) begin
            if ( rx_ch[0].events & !tx_ch[0].events) begin
                  is_hyper_read_d =1;
            end
            else  is_hyper_read_d =0;
       end
end

endmodule
