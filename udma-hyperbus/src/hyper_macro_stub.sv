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



endmodule
