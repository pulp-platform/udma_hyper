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
`define REG_RX_SADDR            5'b00000 //BASEADDR+0x00 L2 address for RX
`define REG_RX_SIZE             5'b00001 //BASEADDR+0x04 size of the software buffer in L2
`define REG_UDMA_RXCFG          5'b00010 //BASEADDR+0x08 UDMA configuration setup (RX)
`define REG_TX_SADDR            5'b00011 //BASEADDR+0x0C address of the data being transferred 
`define REG_TX_SIZE             5'b00100 //BASEADDR+0x10 size of the data being transferred
`define REG_UDMA_TXCFG          5'b00101 //BASEADDR+0x14 UDMA configuration setup (TX)
`define HYPER_CA_SETUP          5'b00110 //BASEADDR+0x18 set read/write, address space, and burst type 
`define REG_HYPER_ADDR          5'b00111 //BASEADDR+0x1C set address in a hyper ram.
`define REG_HYPER_CFG           5'b01000 //BASEADDR+0x20 set the configuration data for HyperRAM
`define STATUS                  5'b01001 //BASEADDR+0x24 status register
`define TWD_ACT_EXT             5'b01010 //BASEADDR+0x28 set 2D transfer activation
`define TWD_COUNT_EXT           5'b01011 //BASEADDR+0x2C set 2D transfer count
`define TWD_STRIDE_EXT          5'b01100 //BASEADDR+0x30 set 2D transfer stride
`define TWD_ACT_L2              5'b01101 //BASEADDR+0x28 set 2D transfer activation
`define TWD_COUNT_L2            5'b01110 //BASEADDR+0x2C set 2D transfer count
`define TWD_STRIDE_L2           5'b01111 //BASEADDR+0x30 set 2D transfer stride


module udma_hyper_reg_if_mulid #(
                          parameter L2_AWIDTH_NOAL = 12,
                          parameter TRANS_SIZE     = 16,
                          parameter MAX_NB_TRAN     = 8
                          ) (
	                     input logic                       clk_i,
	                     input logic                       rst_ni,

	                     input logic [31:0]                cfg_data_i,
	                     input logic [4:0]                 cfg_addr_i,
	                     input logic                       cfg_valid_i,
	                     input logic                       cfg_reg_rwn_i,
                             output logic [31:0]               cfg_data_o,
	                     output logic                      cfg_ready_o,

                             output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
                             output logic [TRANS_SIZE-1:0]     cfg_rx_size_o,
                             output logic [1:0]                cfg_rx_datasize_o,
                             output logic                      cfg_rx_continuous_o,
                             output logic                      cfg_rx_en_o,
                             output logic                      cfg_rx_clr_o,
                             input logic                       cfg_rx_en_i,
                             input logic                       cfg_rx_pending_i,

                             output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
                             output logic [TRANS_SIZE-1:0]     cfg_tx_size_o,
                             output logic                      cfg_tx_continuous_o,
                             output logic [1:0]                cfg_tx_datasize_o,
                             output logic                      cfg_tx_en_o,
                             output logic                      cfg_tx_clr_o,
                             input logic                       cfg_tx_en_i,
                             input logic                       cfg_tx_pending_i,


                             output logic [31:0]               cfg_hyper_addr_o,
                             output logic [15:0]               cfg_hyper_intreg_o,
                             output logic                      cfg_rw_hyper_o,
                             output logic                      cfg_addr_space_o,
                             output logic                      cfg_burst_type_o,

                             output logic                      cfg_twd_trans_ext_act_o,
                             output logic [TRANS_SIZE-1:0]     cfg_twd_trans_ext_count_o,
                             output logic [TRANS_SIZE-1:0]     cfg_twd_trans_ext_stride_o,
                             output logic                      cfg_twd_trans_l2_act_o,
                             output logic [TRANS_SIZE-1:0]     cfg_twd_trans_l2_count_o,
                             output logic [TRANS_SIZE-1:0]     cfg_twd_trans_l2_stride_o,


                             input  logic                      trans_ready_i,
                             input  logic [MAX_NB_TRAN:0]      nb_trans_waiting_i,
                             input  logic                      busy_i,
                             output logic                      trans_valid_o
                             );

   logic [L2_AWIDTH_NOAL-1:0]                                  r_rx_startaddr;
   logic [TRANS_SIZE-1 : 0]                                    r_rx_size;
   logic                                                       r_rx_continuous;
   logic                                                       r_rx_en;
   logic                                                       r_rx_clr;

   logic [L2_AWIDTH_NOAL-1:0]                                  r_tx_startaddr;
   logic [TRANS_SIZE-1 : 0]                                    r_tx_size;
   logic                                                       r_tx_continuous;
   logic                                                       r_tx_en;
   logic                                                       r_tx_clr;

   logic [31:0]                                                r_hyper_addr;
   logic                                                       r_rw; // 0:write 1: read
   logic                                                       r_addr_space; // 0:memory space 1:register space
   logic                                                       r_burst_type; // 0:wrapped burst 1: linear burst
   //logic                                                       r_tran_kick;
   logic [15:0]                                                r_hyper_intreg;

   logic [4:0]                                                 s_wr_addr;
   logic [4:0]                                                 s_rd_addr;

   logic                                                       r_twd_trans_ext_act;
   logic [TRANS_SIZE-1:0]                                      r_twd_trans_ext_count;
   logic [TRANS_SIZE-1:0]                                      r_twd_trans_ext_stride;
   logic                                                       r_twd_trans_l2_act;
   logic [TRANS_SIZE-1:0]                                      r_twd_trans_l2_count;
   logic [TRANS_SIZE-1:0]                                      r_twd_trans_l2_stride;


   assign s_wr_addr = (cfg_valid_i & ~cfg_reg_rwn_i) ? cfg_addr_i : 5'h0;
   assign s_rd_addr = (cfg_valid_i &  cfg_reg_rwn_i) ? cfg_addr_i : 5'h0;

   assign cfg_rx_startaddr_o  = r_rx_startaddr;
   assign cfg_rx_size_o       = r_rx_size;
   assign cfg_rx_continuous_o = r_rx_continuous;
   assign cfg_rx_en_o         = r_rx_en;
   assign cfg_rx_clr_o        = r_rx_clr;

   assign cfg_tx_startaddr_o  = r_tx_startaddr;
   assign cfg_tx_size_o       = r_tx_size;
   assign cfg_tx_continuous_o = r_tx_continuous;
   assign cfg_tx_en_o         = r_tx_en;
   assign cfg_tx_clr_o        = r_tx_clr;

   assign cfg_hyper_addr_o    = r_hyper_addr;
   assign cfg_rw_hyper_o      = r_rw;
   assign cfg_addr_space_o    = r_addr_space;
   assign cfg_burst_type_o    = r_burst_type; 
   assign cfg_hyper_intreg_o  = r_hyper_intreg;

   assign cfg_twd_trans_ext_act_o    = r_twd_trans_ext_act;
   assign cfg_twd_trans_ext_count_o  = r_twd_trans_ext_count;
   assign cfg_twd_trans_ext_stride_o = r_twd_trans_ext_stride;
   assign cfg_twd_trans_l2_act_o     = r_twd_trans_l2_act;
   assign cfg_twd_trans_l2_count_o   = r_twd_trans_l2_count;
   assign cfg_twd_trans_l2_stride_o  = r_twd_trans_l2_stride;


// uDMA transfers data in 32bit width.
   assign cfg_tx_datasize_o = 2'b10;
   assign cfg_rx_datasize_o = 2'b10;


   always_ff @(posedge clk_i, negedge rst_ni) 
     begin
        if(~rst_ni) 
          begin
             
             r_rx_startaddr  <=  'h0;
             r_rx_size       <=  'h0;
             r_rx_continuous <=  'h0;
             r_rx_en          =  'h0;
             r_rx_clr         =  'h0;
             r_tx_startaddr  <=  'h0;
             r_tx_size       <=  'h0;
             r_tx_continuous <=  'h0;
             r_tx_en          =  'h0;
             r_tx_clr         =  'h0;
             r_hyper_addr    <= 32'b0;
             r_rw            <= 1'b1;
             r_addr_space    <= 1'b0;
             r_burst_type    <= 1'b1;
             r_hyper_intreg <= 32'h0;
             r_twd_trans_ext_act <='0;
             r_twd_trans_ext_count <= '0;
             r_twd_trans_ext_stride <= '0;
             r_twd_trans_l2_act <= '0;
             r_twd_trans_l2_count <= '0;
             r_twd_trans_l2_stride <= '0;
          end
        else
          begin
             r_rx_en          =  'h0;
             r_rx_clr         =  'h0;
             r_tx_en          =  'h0;
             r_tx_clr         =  'h0;
             //r_addr_space     =  1'b0;

             if (cfg_valid_i & ~cfg_reg_rwn_i)
               begin
                  case (s_wr_addr)
                    `REG_RX_SADDR:
                      r_rx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                    `REG_RX_SIZE:
                      r_rx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                    `REG_UDMA_RXCFG:
                      begin
                         r_rx_clr          = cfg_data_i[5];
                         r_rx_en           = cfg_data_i[4];
                         r_rx_continuous  <= cfg_data_i[0];
                      end
                    `REG_TX_SADDR:
                      r_tx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                    `REG_TX_SIZE:
                      r_tx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                    `REG_UDMA_TXCFG:
                      begin
                         r_tx_clr          = cfg_data_i[5];
                         r_tx_en           = cfg_data_i[4];
                         r_tx_continuous  <= cfg_data_i[0];
                      end      
                    `HYPER_CA_SETUP:
                      begin
                         r_rw            <= cfg_data_i[2];
                         r_addr_space    <= cfg_data_i[1];
                         r_burst_type    <= cfg_data_i[0];
                      end
                    `REG_HYPER_ADDR:
                      begin
                         r_hyper_addr <= cfg_data_i;
                      end
                    `REG_HYPER_CFG:
                      begin
                         r_hyper_intreg <= cfg_data_i[15:0];
                      end
                    `TWD_ACT_EXT:
                      begin
                         r_twd_trans_ext_act <= cfg_data_i[0];
                      end
                    `TWD_COUNT_EXT:
                      begin
                         r_twd_trans_ext_count <= cfg_data_i[TRANS_SIZE-1:0];
                      end
                    `TWD_STRIDE_EXT:
                      begin
                         r_twd_trans_ext_stride <= cfg_data_i[TRANS_SIZE-1:0];
                      end
                    `TWD_ACT_L2:
                      begin
                         r_twd_trans_l2_act <= cfg_data_i[0];
                      end
                    `TWD_COUNT_L2:
                      begin
                         r_twd_trans_l2_count <= cfg_data_i[TRANS_SIZE-1:0];
                      end
                    `TWD_STRIDE_L2:
                      begin
                         r_twd_trans_l2_stride <= cfg_data_i[TRANS_SIZE-1:0];
                      end

                  endcase
               end
          end
     end //always

   always_comb
     begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
          `REG_RX_SADDR:
            cfg_data_o = r_rx_startaddr;
          `REG_RX_SIZE:
            cfg_data_o = r_rx_size;
          `REG_UDMA_RXCFG:
            cfg_data_o = {26'h0,cfg_rx_pending_i,cfg_rx_en_i,1'b0,2'b10,r_rx_continuous};
          `REG_TX_SADDR:
            cfg_data_o = r_tx_startaddr;
          `REG_TX_SIZE:
            cfg_data_o = r_tx_size;
          `REG_UDMA_TXCFG:
            cfg_data_o = {26'h0,cfg_tx_pending_i,cfg_tx_en_i,1'b0,2'b00,r_tx_continuous};
          `HYPER_CA_SETUP:            
            cfg_data_o = {29'h0, cfg_rw_hyper_o, cfg_addr_space_o, cfg_burst_type_o};
          `REG_HYPER_ADDR:
            cfg_data_o = cfg_hyper_addr_o;
          `REG_HYPER_CFG:
            cfg_data_o = {16'b0, r_hyper_intreg};
          `STATUS:
            cfg_data_o = {nb_trans_waiting_i, busy_i};
          `TWD_ACT_EXT:
            cfg_data_o = {{31{1'b0}}, cfg_twd_trans_ext_act_o};
          `TWD_COUNT_EXT:
            cfg_data_o = cfg_twd_trans_ext_count_o;
          `TWD_STRIDE_EXT:
            cfg_data_o = cfg_twd_trans_ext_stride_o;
          `TWD_ACT_L2:
            cfg_data_o = {{31{1'b0}}, cfg_twd_trans_l2_act_o};
          `TWD_COUNT_L2:
            cfg_data_o = cfg_twd_trans_l2_count_o;
          `TWD_STRIDE_L2:
            cfg_data_o = cfg_twd_trans_l2_stride_o;

          default:
            cfg_data_o = 'h0;
        endcase
     end

   assign cfg_ready_o  = trans_ready_i;

   always_comb
     begin
       if(r_rx_en|r_tx_en) trans_valid_o <= 1'b1;
       else trans_valid_o <= 1'b0;
     end


endmodule 
