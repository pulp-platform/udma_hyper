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
`define REG_PAGE_BOUND          5'b00000 //BASEADDR+0x00 set the page boundary.
`define REG_T_LATENCY_ACCESS    5'b00001 //BASEADDR+0x04 set t_latency_access
`define REG_EN_LATENCY_ADD      5'b00010 //BASEADDR+0x08 set en_latency_additional
`define REG_T_CS_MAX            5'b00011 //BASEADDR+0x0C set t_cs_max
`define REG_T_RW_RECOVERY       5'b00100 //BASEADDR+0x10 set t_read_write_recovery
`define REG_T_RWDS_DELAY_LINE   5'b00101 //BASEADDR+0x14 set t_rwds_delay_line
`define REG_T_VARI_LATENCY      5'b00110 //BASEADDR+0x18 set t_variable_latency_check
`define N_HYPER_DEVICE          5'b00111 //BASEADDR+0x1C set the number of connected devices
`define MEM_SEL                 5'b01000 //BASEADDR+0x20 set Memory select: HyperRAM, Hyperflash, or PSRAM 00:Hyper RAM, 01: Hyper Flash, 10:PSRAM
`define TRANS_ID_ALLOC          5'b01001 //BASEADDR+0x30 set 2D transfer stride

module udma_hyper_reg_if_common #(
                          parameter L2_AWIDTH_NOAL = 12,
                          parameter TRANS_SIZE     = 16,
                          parameter NB_CH          = 1,
                          parameter DELAY_BIT_WIDTH =3,
                          parameter MAX_NB_TRAN     = 8
                          ) (
	                     input logic                        clk_i,
	                     input logic                        rst_ni,

	                     input logic [31:0]                 cfg_data_i,
	                     input logic [4:0]                  cfg_addr_i,
	                     input logic                        cfg_valid_i,
	                     input logic                        cfg_reg_rwn_i,
                             output logic [31:0]                cfg_data_o,
	                     output logic                       cfg_ready_o,

                             output logic [4:0]                 cfg_t_latency_access_o,
                             output logic                       cfg_en_latency_additional_o,
                             output logic [31:0]                cfg_t_cs_max_o,
                             output logic [31:0]                cfg_t_read_write_recovery_o,
                             output logic [DELAY_BIT_WIDTH-1:0] cfg_t_rwds_delay_line_o,
                             output logic [3:0]                 cfg_t_variable_latency_check_o,
                             output logic [2:0 ]                cfg_page_bound_o,
                             output logic [1:0]                 cfg_mem_sel_o,

                             input logic [NB_CH-1:0]            busy_vec_i
                             );


   logic [31:0]                                                r_t_latency_access;
   logic [31:0]                                                r_en_latency_additional;
   logic [31:0]                                                r_t_cs_max;
   logic [31:0]                                                r_t_read_write_recovery;
   logic [31:0]                                                r_t_rwds_delay_line;
   logic [31:0]                                                r_t_variable_latency_check;
   logic [2:0]                                                 r_n_hyperdevice;
   logic [2:0]                                                 r_page_bound;

   logic [4:0]                                                 s_wr_addr;
   logic [4:0]                                                 s_rd_addr;
   logic [1:0]                                                 r_mem_sel;
   logic [$clog2(NB_CH)-1:0]                                   alloc_id;


   //assign reg_space_tran = r_addr_space & (!r_rw);
   assign s_wr_addr = (cfg_valid_i & ~cfg_reg_rwn_i) ? cfg_addr_i : 5'h0;
   assign s_rd_addr = (cfg_valid_i &  cfg_reg_rwn_i) ? cfg_addr_i : 5'h0;

   assign cfg_t_latency_access_o         = r_t_latency_access;
   assign cfg_en_latency_additional_o    = r_en_latency_additional;
   assign cfg_t_cs_max_o                 = r_t_cs_max;
   assign cfg_t_read_write_recovery_o    = r_t_read_write_recovery;
   assign cfg_t_rwds_delay_line_o        = r_t_rwds_delay_line;
   assign cfg_t_variable_latency_check_o = r_t_variable_latency_check;
   assign cfg_n_hyperdevice_o            = r_n_hyperdevice;
   assign cfg_page_bound_o               = r_page_bound;
   assign cfg_mem_sel_o                  = r_mem_sel;


   always_ff @(posedge clk_i, negedge rst_ni) 
     begin
        if(~rst_ni) 
          begin
             
             r_t_latency_access         <= 32'h6;
             r_en_latency_additional    <= 32'b1;
             r_t_cs_max                 <= 32'd665;
             r_t_read_write_recovery    <= 32'h6;
             r_t_rwds_delay_line        <= 32'd2;
             r_t_variable_latency_check <= 32'd3;
             r_n_hyperdevice <= 32'h1;
             r_mem_sel <= 2'b0;
             r_page_bound <= 0;

          end
        else
          begin
             if (cfg_valid_i & ~cfg_reg_rwn_i)
               begin
                  case (s_wr_addr)
                    `REG_PAGE_BOUND:
                      begin
                         r_page_bound <= cfg_data_i[2:0];
                      end
                    `REG_T_LATENCY_ACCESS:
                      begin
                         r_t_latency_access <= cfg_data_i[4:0];
                      end
                    `REG_EN_LATENCY_ADD:
                      begin
                         r_en_latency_additional <= cfg_data_i[0];
                      end
                    `REG_T_CS_MAX:
                      begin
                         r_t_cs_max  <= cfg_data_i;
                      end
                    `REG_T_RW_RECOVERY:
                      begin
                         r_t_read_write_recovery <= cfg_data_i;
                      end
                    `REG_T_RWDS_DELAY_LINE:
                      begin
                         r_t_rwds_delay_line <= cfg_data_i[DELAY_BIT_WIDTH-1:0];
                      end
                    `REG_T_VARI_LATENCY:
                      begin
                         r_t_variable_latency_check <= cfg_data_i[3:0];
                      end
                    `N_HYPER_DEVICE:
                      begin
                         r_n_hyperdevice <= cfg_data_i[2:0];
                      end
                    `MEM_SEL:
                      begin
                         r_mem_sel <= cfg_data_i[1:0];
                      end
                  endcase
               end
          end
     end //always

   always_comb
     begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
          `REG_PAGE_BOUND:
            cfg_data_o = {29'b0, r_page_bound};
          `REG_T_LATENCY_ACCESS:
            cfg_data_o = {28'b0, cfg_t_latency_access_o};
          `REG_EN_LATENCY_ADD:
            cfg_data_o = {31'b0, cfg_en_latency_additional_o};
          `REG_T_CS_MAX:
            cfg_data_o = cfg_t_cs_max_o;
          `REG_T_RW_RECOVERY:
            cfg_data_o = cfg_t_read_write_recovery_o;
          `REG_T_RWDS_DELAY_LINE:
            cfg_data_o = r_t_rwds_delay_line;
          `REG_T_VARI_LATENCY:
            cfg_data_o = {29'b0, cfg_t_variable_latency_check_o};
          `N_HYPER_DEVICE:
            cfg_data_o = {29'h0, cfg_n_hyperdevice_o};
          /*`PSRAM_INST:
            cfg_data_o = {16'h0, cfg_psram_inst_o}; */
          `MEM_SEL:
            cfg_data_o = {{30{1'b0}}, cfg_mem_sel_o};
          `TRANS_ID_ALLOC:
            cfg_data_o = {{(32-$clog2(NB_CH)){1'b0}},alloc_id};
          default:
            cfg_data_o = 'h0;
        endcase
     end

   assign cfg_ready_o  = 1'b1;

   integer i;
   always_comb
     begin
       alloc_id = 0;
       for (i = NB_CH-1 ; i >= 0; i=i-1)
         begin
           if(busy_vec_i[i] == 1'b0)
              alloc_id = i;
         end
     end

endmodule 
