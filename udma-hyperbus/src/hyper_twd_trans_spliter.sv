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

module hyper_twd_trans_spliter
#(
   parameter L2_AWIDTH_NOAL  = 12,
   parameter ID_WIDTH        =  1,
   parameter DELAY_BIT_WIDTH =  3,
   parameter TRANS_SIZE      = 16
)
(
   input  logic                       clk_i,
   input  logic                       rst_ni,

   input  logic                       src_valid_i,
   output logic                       src_ready_o,

   input  logic                       dst_ready_i,
   output logic                       dst_valid_o,

   input  logic [L2_AWIDTH_NOAL-1:0]  rx_start_addr_i,
   input  logic [L2_AWIDTH_NOAL-1:0]  tx_start_addr_i,
   input  logic [TRANS_SIZE-1:0]      rx_size_i,
   input  logic [TRANS_SIZE-1:0]      tx_size_i,

   input  logic [31:0]                hyper_sa_addr_i,
   input  logic [15:0]                hyper_int_reg_i,
   
   input  logic [2:0]                 hyper_page_bound_i,
   input  logic                       rw_hyper_i,
   input  logic                       addr_space_i,
   input  logic                       burst_type_i,
   input  logic [1:0]                 mem_sel_i,
   input  logic [ID_WIDTH-1:0]        trans_id_i,

   input  logic                       twd_trans_ext_act_i,
   input  logic [TRANS_SIZE-1:0]      twd_trans_ext_count_i,
   input  logic [TRANS_SIZE-1:0]      twd_trans_ext_stride_i,

   input  logic                       twd_trans_l2_act_i,
   input  logic [TRANS_SIZE-1:0]      twd_trans_l2_count_i,
   input  logic [TRANS_SIZE-1:0]      twd_trans_l2_stride_i,

   input  logic [4:0]                 cfg_t_latency_access_i,
   input  logic                       cfg_en_latency_additional_i,
   input  logic [31:0]                cfg_t_cs_max_i,
   input  logic [31:0]                cfg_t_read_write_recovery_i,
   input  logic [DELAY_BIT_WIDTH-1:0] cfg_t_rwds_delay_line_i,
   input  logic [3:0]                 cfg_t_variable_latency_check_i,

   output logic [L2_AWIDTH_NOAL-1:0]  rx_start_addr_o,
   output logic [L2_AWIDTH_NOAL-1:0]  tx_start_addr_o,
   output logic [TRANS_SIZE-1:0]      rx_size_o,
   output logic [TRANS_SIZE-1:0]      tx_size_o,

   output logic [31:0]                hyper_sa_addr_o,
   output logic [15:0]                hyper_int_reg_o,

   output logic [2:0]                 hyper_page_bound_o,
   output logic                       rw_hyper_o,
   output logic                       addr_space_o,
   output logic                       burst_type_o,
   output logic [1:0]                 mem_sel_o,
   output logic [ID_WIDTH:0]          trans_id_o,

   output  logic [4:0]                t_latency_access_o,
   output  logic                      en_latency_additional_o,
   output  logic [31:0]               t_cs_max_o,
   output  logic [31:0]               t_read_write_recovery_o,
   output  logic [DELAY_BIT_WIDTH-1:0] t_rwds_delay_line_o,
   output  logic [3:0]                t_variable_latency_check_o
);

   logic [L2_AWIDTH_NOAL -1:0]        r_rx_start_addr;
   logic [L2_AWIDTH_NOAL -1:0]        r_tx_start_addr;
   logic [TRANS_SIZE-1:0]             r_rx_size;
   logic [TRANS_SIZE-1:0]             r_tx_size;


   logic [31:0]                       r_hyper_sa_addr;
   logic [15:0]                       r_hyper_int_reg;
   logic [2:0]                        r_hyper_page_bound;
   logic                              r_rw_hyper;
   logic                              r_addr_space;
   logic                              r_burst_type;
   logic [1:0]                        r_mem_sel;
   logic [ID_WIDTH:0]                 r_trans_id;

   logic                              r_twd_trans_ext_act;
   logic [TRANS_SIZE-1:0]             r_twd_trans_ext_count;
   logic [TRANS_SIZE-1:0]             r_twd_trans_ext_stride;

   logic                              r_twd_trans_l2_act;
   logic [TRANS_SIZE-1:0]             r_twd_trans_l2_count;
   logic [TRANS_SIZE-1:0]             r_twd_trans_l2_stride;

   logic [4:0]                        r_t_latency_access;
   logic                              r_en_latency_additional;
   logic [31:0]                       r_t_cs_max;
   logic [31:0]                       r_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]        r_t_rwds_delay_line;
   logic [3:0]                        r_t_variable_latency_check;


   enum  {STANDBY, SETUP, TRANSACTION, END} control_state;

   logic [L2_AWIDTH_NOAL -1:0]        next_rx_start_addr;
   logic [L2_AWIDTH_NOAL -1:0]        next_tx_start_addr;
   logic [TRANS_SIZE-1:0]             next_rx_size;
   logic [TRANS_SIZE-1:0]             next_tx_size;
   logic [31:0]                       next_hyper_sa_addr;

   logic [TRANS_SIZE-1:0]             cur_length;


// Registers for 2d transacitons
   always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           r_rx_start_addr <= 0;
           r_tx_start_addr <= 0;
           r_rx_size <=0;
           r_tx_size <=0;
           r_hyper_sa_addr <=0;
           r_hyper_int_reg <=0;
           r_hyper_page_bound <=0;
           r_rw_hyper <= 0;
           r_addr_space <= 0;
           r_burst_type <=0;
           r_mem_sel <=0;
           r_trans_id <= 1 << ID_WIDTH;
           r_twd_trans_ext_act <= 0;
           r_twd_trans_ext_count <=0;
           r_twd_trans_ext_stride <=0;

           r_twd_trans_l2_act <= 0;
           r_twd_trans_l2_count <=0;
           r_twd_trans_l2_stride <=0;

           r_t_latency_access         <= 'h6;
           r_en_latency_additional    <= 'b1;
           r_t_cs_max                 <= 'd665;
           r_t_read_write_recovery    <= 'h6;
           r_t_rwds_delay_line        <= 'd2;
           r_t_variable_latency_check <= 'd3;


         end
       else
         begin
           if(control_state == STANDBY)
             begin
               if(src_valid_i & src_ready_o)
                 begin
                   r_rx_start_addr <= rx_start_addr_i;
                   r_tx_start_addr <= tx_start_addr_i;
                   r_rx_size <= rx_size_i;
                   r_tx_size <= tx_size_i;
                   r_hyper_sa_addr <= hyper_sa_addr_i;

                   r_hyper_int_reg <= hyper_int_reg_i;
                   r_hyper_page_bound <= hyper_page_bound_i;
                   r_rw_hyper <= rw_hyper_i;
                   r_addr_space <= addr_space_i;
                   r_burst_type <= burst_type_i;
                   r_mem_sel <= mem_sel_i;
                   r_trans_id <= {1'b0, trans_id_i};

                   r_twd_trans_ext_act <= twd_trans_ext_act_i;
                   r_twd_trans_ext_count <= twd_trans_ext_count_i; 
                   r_twd_trans_ext_stride <= twd_trans_ext_stride_i; 

                   r_twd_trans_l2_act <= twd_trans_l2_act_i;
                   r_twd_trans_l2_count <= twd_trans_l2_count_i;
                   r_twd_trans_l2_stride <= twd_trans_l2_stride_i;


                   r_t_latency_access         <= cfg_t_latency_access_i;
                   r_en_latency_additional    <= cfg_en_latency_additional_i;
                   r_t_cs_max                 <= cfg_t_cs_max_i;
                   r_t_read_write_recovery    <= cfg_t_read_write_recovery_i;
                   r_t_rwds_delay_line        <= cfg_t_rwds_delay_line_i;
                   r_t_variable_latency_check <= cfg_t_variable_latency_check_i;

                 end
             end
           else
             begin
               if(control_state == TRANSACTION)
                 begin
                   if(dst_ready_i & dst_valid_o)
                     begin
                       r_hyper_sa_addr <= next_hyper_sa_addr;
                       r_rx_start_addr <= next_rx_start_addr;
                       r_tx_start_addr <= next_tx_start_addr;
                       r_rx_size <= next_rx_size;
                       r_tx_size <= next_tx_size;
                     end
                 end
               else
                 begin
                   if(control_state == END) r_trans_id <= 1 << ID_WIDTH;
                 end
             end
         end
     end

   assign hyper_sa_addr_o = r_hyper_sa_addr; 
   assign rx_start_addr_o = (r_rw_hyper)  ? r_rx_start_addr: 0;
   assign tx_start_addr_o = (!r_rw_hyper) ? r_tx_start_addr: 0;
   assign hyper_int_reg_o = r_hyper_int_reg;
   assign hyper_page_bound_o = r_hyper_page_bound; 
   assign rw_hyper_o = r_rw_hyper;
   assign addr_space_o = r_addr_space;
   assign burst_type_o = r_burst_type;
   assign mem_sel_o = r_mem_sel;
   assign rx_size_o = (r_rw_hyper)  ? cur_length: 0;
   assign tx_size_o = (!r_rw_hyper) ? cur_length: 0;
   assign trans_id_o = r_trans_id;

   assign t_latency_access_o = r_t_latency_access;
   assign en_latency_additional_o = r_en_latency_additional;
   assign t_cs_max_o = r_t_cs_max;
   assign t_read_write_recovery_o = r_t_read_write_recovery;
   assign t_rwds_delay_line_o = r_t_rwds_delay_line;
   assign t_variable_latency_check_o = r_t_variable_latency_check;

// Calculation of each 1d length
   always_comb
     begin
       if(r_rw_hyper)
         begin
           case({r_twd_trans_ext_act,r_twd_trans_l2_act})
             2'b00:
               begin
                 cur_length <= r_rx_size;
               end
             2'b01:
               begin
                 if(r_rx_size <= r_twd_trans_l2_count) cur_length <= r_rx_size;
                 else cur_length <= r_twd_trans_l2_count;
               end
             2'b10:
               begin
                 if(r_rx_size <= r_twd_trans_ext_count) cur_length <= r_rx_size;
                 else cur_length <= r_twd_trans_ext_count;
               end
             2'b11:
               begin
                 if((r_rx_size <= r_twd_trans_l2_count) && (r_rx_size <= r_twd_trans_ext_count)) cur_length <= r_rx_size;
                 else if (r_twd_trans_l2_count <= r_twd_trans_ext_count) cur_length <= r_twd_trans_l2_count;
                      else cur_length <= r_twd_trans_ext_count;
               end
           endcase
         end
       else
         begin
           case({r_twd_trans_ext_act,r_twd_trans_l2_act})
             2'b00:
               begin
                 cur_length <= r_tx_size;
               end
             2'b01:
               begin
                 if(r_tx_size <= r_twd_trans_l2_count) cur_length <= r_tx_size;
                 else cur_length <= r_twd_trans_l2_count;
               end
             2'b10:
               begin
                 if(r_tx_size <= r_twd_trans_ext_count) cur_length <= r_tx_size;
                 else cur_length <= r_twd_trans_ext_count;
               end
             2'b11:
               begin
                 if((r_tx_size <= r_twd_trans_l2_count) && (r_tx_size <= r_twd_trans_ext_count)) cur_length <= r_tx_size;
                 else if (r_twd_trans_l2_count <= r_twd_trans_ext_count) cur_length <= r_twd_trans_l2_count;
                      else cur_length <= r_twd_trans_ext_count;
               end
           endcase

         end
     end


// Calculations of the next size and address
   assign next_rx_size = (r_rw_hyper == 1'b1)  ? r_rx_size - cur_length : 0;
   assign next_tx_size = (r_rw_hyper == 1'b0)  ? r_tx_size - cur_length : 0;

   assign next_rx_start_addr = ((r_rw_hyper == 1'b1) && (r_twd_trans_l2_act == 1'b1))  ? r_rx_start_addr + r_twd_trans_l2_stride : 
                               ((r_rw_hyper == 1'b1) && (r_twd_trans_l2_act == 1'b0))  ? r_rx_start_addr + cur_length : 0;
   assign next_tx_start_addr = ((r_rw_hyper == 1'b0) && (r_twd_trans_l2_act == 1'b1))  ? r_tx_start_addr + r_twd_trans_l2_stride :
                               ((r_rw_hyper == 1'b0) && (r_twd_trans_l2_act == 1'b0))  ? r_tx_start_addr + cur_length : 0;

   assign next_hyper_sa_addr = ( r_twd_trans_ext_act== 1'b1 ) ? r_hyper_sa_addr + r_twd_trans_ext_stride :
                               ( r_twd_trans_ext_act== 1'b0 ) ? r_hyper_sa_addr + cur_length : 0;

// Control state machine
   always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           control_state <= STANDBY;
           src_ready_o <= 1'b1;
           dst_valid_o <= 1'b0;
         end
       else
         begin
           case(control_state)
              STANDBY: begin
                dst_valid_o <= 1'b0;
                if(src_valid_i & src_ready_o) 
                  begin
                    control_state <= SETUP;
                    src_ready_o <= 1'b0;
                  end
                else
                  begin
                    src_ready_o <= 1'b1;
                  end
              end
              SETUP: begin
                src_ready_o <= 1'b0;
                if(dst_ready_i)
                  begin 
                    dst_valid_o <= 1'b1;
                    control_state <= TRANSACTION;
                  end
              end
              TRANSACTION: begin
                if(r_rw_hyper) // checking read or write
                  begin
                    if(dst_valid_o & dst_ready_i)
                      begin
                        dst_valid_o <= 1'b0;
                        if( next_rx_size==0 ) control_state <= END;
                      end
                    else
                      begin
                        dst_valid_o <= 1'b1;
                      end
                  end
                else
                  begin
                    if(dst_valid_o & dst_ready_i)
                      begin
                        dst_valid_o <= 1'b0;
                        if( (next_tx_size==0) | (r_addr_space == 1'b1) ) control_state <= END;
                      end
                    else
                      begin
                        dst_valid_o <= 1'b1;
                      end
                  end
              end
              END: begin
                control_state <= STANDBY;
              end
           endcase
         end
     end

endmodule 
