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

module hyper_unpack
#(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE = 16,
    parameter DELAY_BIT_WIDTH = 3,
    parameter ID_WIDTH =1,
    parameter NR_CS =2

)
(
  input  logic                      clk_i,
  input  logic                      rst_ni,

  input  logic                      pack_trans_valid_i,
  output logic                      pack_trans_ready_o,
  input  logic [TRANS_SIZE-1:0]     pack_rx_size_i,
  input  logic [TRANS_SIZE-1:0]     pack_tx_size_i,
  input  logic [L2_AWIDTH_NOAL-1:0] pack_rx_start_addr_i,
  input  logic [L2_AWIDTH_NOAL-1:0] pack_tx_start_addr_i,

  input  logic                      pack_rw_hyper_i,
  input  logic                      pack_addr_space_i,
  input  logic                      pack_burst_type_i,
  input  logic [1:0]                pack_mem_sel_i,
  input  logic [ID_WIDTH:0]         pack_trans_id_i,
  input  logic [2:0]                pack_page_bound_i,

  input  logic [31:0]               pack_hyper_addr_i,
  input  logic [15:0]               pack_hyper_intreg_i,
  //input  logic [15:0]               pack_psram_inst_i,

  input  logic [4:0]                pack_t_latency_access_i,
  input  logic                      pack_en_latency_additional_i,
  input  logic [31:0]               pack_t_cs_max_i,
  input  logic [31:0]               pack_t_read_write_recovery_i,
  input  logic [DELAY_BIT_WIDTH-1:0] pack_t_rwds_delay_line_i,
  input  logic [3:0]                pack_t_variable_latency_check_i,


  input  logic                      unpack_trans_ready_i,
  output logic                      unpack_trans_valid_o,
  output logic [31:0]               unpack_hyper_addr_o,
  output logic [15:0]               unpack_hyper_intreg_o,
  //output logic [15:0]               unpack_psram_inst_o,
  output logic [L2_AWIDTH_NOAL-1:0] unpack_rx_start_addr_o,
  output logic [L2_AWIDTH_NOAL-1:0] unpack_tx_start_addr_o,
  output logic [TRANS_SIZE-1:0]     unpack_rx_size_o,
  output logic [TRANS_SIZE-1:0]     unpack_tx_size_o,
  output logic                      unpack_rw_hyper_o,
  output logic                      unpack_addr_space_o,
  output logic                      unpack_burst_type_o,
  output logic [1:0]                unpack_mem_sel_o,
  output logic [ID_WIDTH:0]         unpack_trans_id_o,
  output logic                      unpack_rx_en_o,
  output logic                      unpack_tx_en_o,
  output logic [4:0]                unpack_t_latency_access_o,
  output logic                      unpack_en_latency_additional_o,
  output logic [31:0]               unpack_t_cs_max_o,
  output logic [31:0]               unpack_t_read_write_recovery_o,
  output logic [DELAY_BIT_WIDTH-1:0] unpack_t_rwds_delay_line_o,
  output logic [3:0]                unpack_t_variable_latency_check_o

 // output logic [NR_CS-1:0]          unpack_cs_o
  );

  enum         {STANDBY, SETUP, TRANSACTION, END} control_state;

  logic [L2_AWIDTH_NOAL-1:0] r_rx_start_addr;
  logic [L2_AWIDTH_NOAL-1:0] r_tx_start_addr;
  logic [TRANS_SIZE-1:0]     r_rx_rem_size;
  logic [TRANS_SIZE-1:0]     r_tx_rem_size;
  logic [TRANS_SIZE-1:0]     cur_length;

  logic [L2_AWIDTH_NOAL-1:0] next_rx_addr;
  logic [L2_AWIDTH_NOAL-1:0] next_tx_addr;
  logic [TRANS_SIZE-1:0]     next_rx_size;
  logic [TRANS_SIZE-1:0]     next_tx_size;
  logic [31:0]               next_hyper_addr;

  logic                      r_rw_hyper;
  logic                      r_addr_space;
  logic                      r_burst_type;
  logic                      r_tx_en;
  logic                      r_rx_en;
  logic [2:0]                r_page_bound;
  logic [31:0]               r_hyper_addr;
  logic [31:0]               r_hyper_intreg;
  logic [ID_WIDTH:0]         r_trans_id;

  logic                      boundary_crossed;
  logic                      no_bound_limit;
  logic [3:0]                log_page_bound_length;
  logic [TRANS_SIZE-1:0]     page_bound_length;
  logic [TRANS_SIZE-1:0]     in_page_addr;
  logic [TRANS_SIZE-1:0]     nb_cmd;
  logic [TRANS_SIZE-1:0]     nb_cmd_count;
  logic [1:0]                r_mem_sel;
  logic                      last_tran;

  logic [4:0]                 r_t_latency_access;
  logic                       r_en_latency_additional;
  logic [31:0]                r_t_cs_max;
  logic [31:0]                r_t_read_write_recovery;
  logic [DELAY_BIT_WIDTH-1:0] r_t_rwds_delay_line;
  logic [3:0]                 r_t_variable_latency_check;


// The transaction data from cfg regs is fetched. And, the address and size are updated.
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          r_rw_hyper <= 1'b0;
          r_addr_space <= 1'b0;
          r_burst_type <= 1'b0;
          r_page_bound <= '0;
          r_hyper_addr <= '0;
          r_hyper_intreg <= '0;
          r_tx_start_addr <= '0;
          r_rx_start_addr <= '0;
          r_rx_rem_size <='0;
          r_tx_rem_size <='0;
          r_rx_en <= 0;
          r_tx_en <= 0;
          r_trans_id <=1 << ID_WIDTH;
          //r_psram_inst <= '0;
          r_mem_sel <= 2'b0;
          
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
              if(pack_trans_valid_i & pack_trans_ready_o)
                begin
                  r_rw_hyper <= pack_rw_hyper_i;
                  r_addr_space <= pack_addr_space_i;
                  r_burst_type <= pack_burst_type_i;
                  r_page_bound <= pack_page_bound_i;
                  r_hyper_addr <= pack_hyper_addr_i;
                  r_hyper_intreg <= pack_hyper_intreg_i;
                  r_tx_start_addr <= pack_tx_start_addr_i;
                  r_rx_start_addr <= pack_rx_start_addr_i;
                  r_rx_rem_size <= pack_rx_size_i;
                  r_tx_rem_size <= pack_tx_size_i;
                  //r_psram_inst <= pack_psram_inst_i;
                  r_mem_sel <= pack_mem_sel_i;
                  r_trans_id <= pack_trans_id_i;
                  r_rx_en <= 0;
                  r_tx_en <= 0;

                  r_t_latency_access         <= pack_t_latency_access_i;
                  r_en_latency_additional    <= pack_en_latency_additional_i;
                  r_t_cs_max                 <= pack_t_cs_max_i;
                  r_t_read_write_recovery    <= pack_t_read_write_recovery_i;
                  r_t_rwds_delay_line        <= pack_t_rwds_delay_line_i;
                  r_t_variable_latency_check <= pack_t_variable_latency_check_i;

                end
            end
          else
            begin
              if(control_state == TRANSACTION)
                begin
                  if(unpack_trans_valid_o & unpack_trans_ready_i & (!last_tran) )
                    begin
                      r_hyper_addr <= next_hyper_addr;
                      r_tx_start_addr <= next_tx_addr;
                      r_rx_start_addr <= next_rx_addr;
                      r_rx_rem_size <= next_rx_size; 
                      r_tx_rem_size <= next_tx_size;
                      if(r_rw_hyper) r_rx_en <= 1'b1;
                      else r_tx_en <= 1'b1; 
                    end
                  else
                    begin
                      r_rx_en <= 1'b0;
                      r_tx_en <= 1'b0;
                    end
                end
               else
                begin
                  if(control_state == END) r_trans_id <= 1 << ID_WIDTH;
                end
            end
        end
    end 

  assign unpack_hyper_addr_o    = r_hyper_addr;
  assign unpack_rx_start_addr_o = r_rx_start_addr;
  assign unpack_tx_start_addr_o = r_tx_start_addr;
  assign unpack_rw_hyper_o      = r_rw_hyper;
  assign unpack_addr_space_o    = r_addr_space;
  assign unpack_burst_type_o    = r_burst_type;
  assign unpack_hyper_intreg_o  = r_hyper_intreg;
  assign unpack_rx_en_o         = r_rx_en;
  assign unpack_tx_en_o         = r_tx_en;
  assign unpack_rx_size_o       = (r_rw_hyper) ? cur_length:0;
  assign unpack_tx_size_o       = ((!r_rw_hyper) & (r_mem_sel != 2'b01))? cur_length:0;
  assign unpack_mem_sel_o       = r_mem_sel;
  assign unpack_trans_id_o      = r_trans_id;

  assign unpack_t_latency_access_o = r_t_latency_access;
  assign unpack_en_latency_additional_o = r_en_latency_additional;
  assign unpack_t_cs_max_o = r_t_cs_max;
  assign unpack_t_read_write_recovery_o = r_t_read_write_recovery;
  assign unpack_t_rwds_delay_line_o = r_t_rwds_delay_line;
  assign unpack_t_variable_latency_check_o = r_t_variable_latency_check;



  assign last_tran              = ((!r_rw_hyper) & ((r_tx_rem_size - cur_length) == 0)) | ((r_addr_space == 1'b1) & (r_mem_sel==2'b00)) |
                                  (  r_rw_hyper  & ((r_rx_rem_size - cur_length) == 0)) | ((r_addr_space == 1'b1) & (r_mem_sel==2'b10)) |
                                  ((r_addr_space == 1'b1) & (r_mem_sel==2'b11)) | (r_mem_sel == 2'b01) ? 1'b1: 1'b0;
 
// checks whether or not the transaction crosses the boundary condition
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          log_page_bound_length <= 0;
        end
      else
        begin
          if(pack_trans_valid_i & pack_trans_ready_o)
           begin
             case (pack_page_bound_i)
               3'b000: log_page_bound_length <= $clog2(128);
               3'b001: log_page_bound_length <= $clog2(256);
               3'b010: log_page_bound_length <= $clog2(512);
               3'b011: log_page_bound_length <= $clog2(1024);
               default: log_page_bound_length <= 0;
             endcase
           end
        end
    end


  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          page_bound_length <= 0;
        end
      else
        begin
          if(pack_trans_valid_i & pack_trans_ready_o)
           begin
             case (pack_page_bound_i)
               3'b000: page_bound_length <= 128;
               3'b001: page_bound_length <= 256;
               3'b010: page_bound_length <= 512;
               3'b011: page_bound_length <= 1024;
               default: page_bound_length <= 0;
             endcase
           end
        end
    end


  assign in_page_addr =          (r_page_bound == 3'b000) ? r_hyper_addr[$clog2(128)-1:0]:
                                 (r_page_bound == 3'b001) ? r_hyper_addr[$clog2(256)-1:0]:
                                 (r_page_bound == 3'b010) ? r_hyper_addr[$clog2(512)-1:0]:
                                 (r_page_bound == 3'b011) ? r_hyper_addr[$clog2(1024)-1:0]: 0;

  assign no_bound_limit = (page_bound_length == 0) ? 1'b1: 1'b0;

  always_comb
    begin
      if(no_bound_limit==1'b0)
        begin
          if(r_rw_hyper)
            begin
              if((r_hyper_addr >> (log_page_bound_length) ) != ((r_hyper_addr + (r_rx_rem_size-1)) >> (log_page_bound_length)))
                boundary_crossed <= 1'b1;
              else
                boundary_crossed <= 1'b0;
            end
          else
            begin
              if((r_hyper_addr >> (log_page_bound_length) ) != ((r_hyper_addr + (r_tx_rem_size-1)) >> (log_page_bound_length)))
                boundary_crossed <= 1'b1;
              else
                boundary_crossed <= 1'b0;
            end
        end
      else
        begin
          boundary_crossed <= 1'b0;
        end
    end
  

// Calculates transaction length
  always_comb
    begin
      if(boundary_crossed == 1'b0) 
        begin
          if(r_rw_hyper) 
             cur_length <= r_rx_rem_size;
          else 
             cur_length <= r_tx_rem_size;
        end
      else
        begin
          cur_length <= page_bound_length - in_page_addr;
        end
    end

// Calculates the next addr 

assign       next_rx_addr = r_rx_start_addr + cur_length;
assign       next_tx_addr = r_tx_start_addr + cur_length;
assign       next_rx_size = r_rx_rem_size - cur_length;
assign       next_tx_size = r_tx_rem_size - cur_length;
assign       next_hyper_addr = r_hyper_addr + cur_length;


// State control
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          control_state <= STANDBY;
          pack_trans_ready_o <= 1'b1;
          unpack_trans_valid_o <= 1'b0;
        end
      else
        begin
          case(control_state)
             STANDBY: begin
               unpack_trans_valid_o <= 1'b0;
               if( pack_trans_ready_o & pack_trans_valid_i )
                 begin
                   control_state <= SETUP;
                   pack_trans_ready_o <= 1'b0;
                 end
               else
                 begin
                   pack_trans_ready_o <= 1'b1;
                 end
             end
             SETUP: begin
               pack_trans_ready_o <= 1'b0;
               if(unpack_trans_ready_i)
                 begin
                   unpack_trans_valid_o <= 1'b1;
                   control_state <= TRANSACTION;
                 end
             end
             TRANSACTION: begin
               if(r_rw_hyper)
                 begin
                   if(unpack_trans_ready_i & unpack_trans_valid_o)
                     begin
                       unpack_trans_valid_o <= 1'b0;
                       if(last_tran) control_state <= END;
                     end
                   else
                     begin
                       unpack_trans_valid_o <= 1'b1;
                     end
                 end
               else
                 begin
                   if(unpack_trans_ready_i & unpack_trans_valid_o)
                     begin
                       unpack_trans_valid_o <= 1'b0;
                       if(last_tran) control_state <= END;
                     end
                   else
                     begin
                       unpack_trans_valid_o <= 1'b1;
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
