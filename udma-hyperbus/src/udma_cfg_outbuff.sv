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


module udma_cfg_outbuff 
#(
  parameter L2_AWIDTH_NOAL =12,
  parameter ID_WIDTH =1,
  parameter NB_CH =1,
  parameter TRANS_SIZE = 16
)
(
  input logic                       clk_i,
  input logic                       rst_ni,

  input logic [L2_AWIDTH_NOAL-1:0]  toudma_tx_start_addr_i,
  input logic [TRANS_SIZE-1:0]      toudma_tx_size_i,
  input logic [L2_AWIDTH_NOAL-1:0]  toudma_rx_start_addr_i,
  input logic [TRANS_SIZE-1:0]      toudma_rx_size_i,

  input logic                       toudma_rw_hyper_i,
  input logic                       toudma_trans_valid_i,
  input logic [ID_WIDTH:0]          toudma_trans_id_i,
  input logic [TRANS_SIZE-1:0]      rx_bytes_left_i,
  input logic [TRANS_SIZE-1:0]      tx_bytes_left_i,
  input logic                       udma_tx_en_i,
  input logic                       udma_rx_en_i,


  output logic [L2_AWIDTH_NOAL-1:0] udma_tx_start_addr_o,
  output logic [TRANS_SIZE-1:0]     udma_tx_size_o,
  output logic                      udma_tx_en_o,

  output logic [L2_AWIDTH_NOAL-1:0] udma_rx_start_addr_o,
  output logic [TRANS_SIZE-1:0]     udma_rx_size_o,
  output logic                      udma_rx_en_o,

  output logic [NB_CH-1:0]          proc_id_vec_sys_o
);

  logic [ID_WIDTH:0]              r_trans_id;
  logic                           r_tx_en, r_rx_en;
  logic                           rx_en, tx_en;
  assign tx_en = r_tx_en | udma_tx_en_i;
  assign rx_en = r_rx_en | udma_rx_en_i;

  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          udma_tx_start_addr_o <= 0;
          udma_tx_size_o       <= 0;
          udma_tx_en_o         <= 0;

          udma_rx_start_addr_o <= 0;
          udma_rx_size_o       <= 0;
          udma_rx_en_o         <= 0;
        end
      else
        begin
          if(toudma_trans_valid_i)
            begin
              udma_tx_start_addr_o <= toudma_tx_start_addr_i;
              udma_tx_size_o <= toudma_tx_size_i;
              udma_rx_start_addr_o <= toudma_rx_start_addr_i;
              udma_rx_size_o <= toudma_rx_size_i;
              if(toudma_rw_hyper_i) udma_rx_en_o <= 1'b1;
              else udma_tx_en_o <= 1'b1;
            end
          else
            begin
              udma_tx_en_o <= 1'b0;
              udma_rx_en_o <= 1'b0;
            end
        end
    end

// Generating a vector for which transaction IDs are processed
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          r_trans_id <= 1 << ID_WIDTH;
          r_tx_en <= 1'b0;
          r_rx_en <= 1'b0;
        end
      else
        begin
          r_tx_en <= udma_tx_en_i;
          r_rx_en <= udma_rx_en_i;

          if(toudma_trans_valid_i)
            begin
              r_trans_id <= toudma_trans_id_i;
            end
          else
            begin
              if((tx_en==0)&(rx_en==0)) 
                begin
                  r_trans_id <= 1 << ID_WIDTH;
                end
            end
        end
    end

  genvar i;
  generate
    for(i=0; i<=NB_CH-1; i++)
      begin
        assign proc_id_vec_sys_o[i] = (i==r_trans_id) ? 1'b1 : 1'b0;
      end
  endgenerate



endmodule
