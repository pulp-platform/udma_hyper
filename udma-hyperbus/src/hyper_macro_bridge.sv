module hyper_macro_bridge
    import udma_pkg::*;
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

    // bridge connection towards the macro
    // configuration from udma core to the macro
    output cfg_req_t hyper_cfg_req_o,
    input cfg_rsp_t hyper_cfg_rsp_i,
    // data channels from/to the macro
    output udma_linch_tx_req_t hyper_linch_tx_req_o,
    input udma_linch_tx_rsp_t hyper_linch_tx_rsp_i,
    input udma_linch_rx_req_t hyper_linch_rx_req_i,
    output udma_linch_rx_rsp_t hyper_linch_rx_rsp_o,
    input udma_evt_t hyper_macro_evt_i,
    output udma_evt_t hyper_macro_evt_o
	
);

always_comb begin : proc_events
	events_o = hyper_macro_evt_i;
	hyper_macro_evt_o = events_i;
end

// assign the configuration request
always_comb begin : proc_conf_req
	hyper_cfg_req_o.data = cfg_data_i;
	hyper_cfg_req_o.addr = cfg_addr_i;
	hyper_cfg_req_o.valid = cfg_valid_i;
	hyper_cfg_req_o.rwn = cfg_rwn_i;
end

always_comb begin : proc_conf_rsp
	cfg_ready_o = hyper_cfg_rsp_i.ready;
	cfg_data_o = hyper_cfg_rsp_i.data;
end

always_comb begin : proc_tx_req
	hyper_linch_tx_req_o.bytes_left = tx_ch[0].bytes_left;
	hyper_linch_tx_req_o.curr_addr =tx_ch[0].curr_addr;
	hyper_linch_tx_req_o.data = tx_ch[0].data;
	hyper_linch_tx_req_o.en = tx_ch[0].en;
	hyper_linch_tx_req_o.events = tx_ch[0].events;
	hyper_linch_tx_req_o.pending = tx_ch[0].pending;
	hyper_linch_tx_req_o.gnt = tx_ch[0].gnt;
	hyper_linch_tx_req_o.stream = '0;
	hyper_linch_tx_req_o.stream_id = '0;
	hyper_linch_tx_req_o.valid = tx_ch[0].valid;
end
// assign the tx_response
always_comb begin : proc_tx_rsp
	tx_ch[0].cen = hyper_linch_tx_rsp_i.cen;
	tx_ch[0].clr = hyper_linch_tx_rsp_i.clr;
	tx_ch[0].continuous = hyper_linch_tx_rsp_i.continuous;
	tx_ch[0].datasize = hyper_linch_tx_rsp_i.datasize;
	tx_ch[0].destination = hyper_linch_tx_rsp_i.destination;
	tx_ch[0].ready = hyper_linch_tx_rsp_i.ready;
	tx_ch[0].req = hyper_linch_tx_rsp_i.req;
	tx_ch[0].size = hyper_linch_tx_rsp_i.size;
	tx_ch[0].startaddr = hyper_linch_tx_rsp_i.startaddr;
end

always_comb begin : proc_rx_req
	rx_ch[0].cen = hyper_linch_rx_req_i.cen;
	rx_ch[0].clr = hyper_linch_rx_req_i.clr;
	rx_ch[0].continuous = hyper_linch_rx_req_i.continuous;
	rx_ch[0].data = hyper_linch_rx_req_i.data;
	rx_ch[0].datasize = hyper_linch_rx_req_i.datasize;
	rx_ch[0].destination = hyper_linch_rx_req_i.destination;
	rx_ch[0].req = hyper_linch_rx_req_i.req;
	rx_ch[0].size = hyper_linch_rx_req_i.size;
	rx_ch[0].startaddr = hyper_linch_rx_req_i.startaddr;
	rx_ch[0].stream = hyper_linch_rx_req_i.stream;
	rx_ch[0].stream_id = hyper_linch_rx_req_i.stream_id;
	rx_ch[0].valid = hyper_linch_rx_req_i.valid;
end

always_comb begin : proc_rx_rsp
	hyper_linch_rx_rsp_o.bytes_left = rx_ch[0].bytes_left;
	hyper_linch_rx_rsp_o.curr_addr = rx_ch[0].curr_addr;
	hyper_linch_rx_rsp_o.en = rx_ch[0].en;
	hyper_linch_rx_rsp_o.events = rx_ch[0].events;
	hyper_linch_rx_rsp_o.gnt = rx_ch[0].gnt;
	hyper_linch_rx_rsp_o.pending = rx_ch[0].pending;
	hyper_linch_rx_rsp_o.ready = rx_ch[0].ready;
end

endmodule