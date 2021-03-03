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


module udma_hyper_busy_phy#(
   parameter ID_WIDTH = 1,
   parameter NB_CH = 1
)(
   input logic clk_i,
   input logic rst_ni,

   input logic [ID_WIDTH:0] unpack_trans_id_i,
   input logic [ID_WIDTH:0] ctrl_trans_id_i,

   output logic [NB_CH-1:0] proc_id_vec_o
);

  logic [NB_CH-1:0] one_hot_unpack_id;
  logic [NB_CH-1:0] one_hot_ctrl_id;

  genvar i;

  generate
    for(i=0; i<=NB_CH-1; i++)
      begin
        assign one_hot_unpack_id[i] = (i==unpack_trans_id_i) ? 1'b1 : 1'b0; 
        assign one_hot_ctrl_id[i] = (i==ctrl_trans_id_i) ? 1'b1 : 1'b0;
      end
  endgenerate

  assign proc_id_vec_o = one_hot_unpack_id | one_hot_ctrl_id;
  
endmodule
