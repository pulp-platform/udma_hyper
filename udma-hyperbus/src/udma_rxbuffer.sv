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


// This module modifies the data width from 16bit (PHY) to 32 bit (uDMA).
module udma_rxbuffer
#(
  parameter TRANS_SIZE = 16
)
(
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  logic                  cfg_addr_space_i,


  input  logic                  src_valid_i,
  output logic                  src_ready_o,

  input  logic                  dst_ready_i,
  output logic                  dst_valid_o,

  input  logic [TRANS_SIZE-1:0] cfg_rx_size_i,
  input  logic [TRANS_SIZE-1:0] remained_data_i,
  input  logic                  hyper_odd_saaddr_i,
  input  logic [1:0]            mem_sel_i,

  input  logic [31:0]           data_i,
  output logic [31:0]           data_o
);

  logic  [1:0 ]  sel;
  logic          int_valid;
  logic          int_valid_buff;

// Flag for the last data from phy
  logic          last;
  logic          last_buff;
  logic          last_mux;

// Regs for data store  
  logic  [15:0]  check_reg;
  //logic  [15:0]  data_lower, data_upper;
  logic  [31:0]  data_buff;
  logic  [31:0]  prev_data;
  logic  [31:0]  data_rot;
  logic  [31:0]  data_psram_hyper;

  logic  [TRANS_SIZE-1:0] count_32data;
  logic  [TRANS_SIZE-1:0] nb_32data;

  assign  src_ready_o = dst_ready_i; // ready signal is given by a destination FIFO
  assign  nb_32data = |(cfg_rx_size_i[1:0]) ? (cfg_rx_size_i >> 2)+1 : (cfg_rx_size_i >> 2); 
  assign data_psram_hyper = (mem_sel_i == 2'b11) ? { data_i[15:0], data_i[31:16] } :
                            (mem_sel_i == 2'b10) ? { 16'b0, data_i[7:0], data_i[15:8]} : data_i;

  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           check_reg <= 0;
         end
       else
         begin
           if( src_valid_i & cfg_addr_space_i ) check_reg <= data_i; // Results of the REG_RW transaction are stored.
         end
     end  

////////////////////////////////////////////
///////// 16b/32b flipflop /////////////////
////////////////////////////////////////////


  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
          begin
            data_buff <= 0;
            sel <= 0;
          end
       else
          begin
            if( src_valid_i & src_ready_o ) begin
                if(mem_sel_i == 2'b11) begin
                   data_buff <= data_psram_hyper;
                end else begin
                   if(sel==1) 
                      begin
                        sel <= 0;
                        data_buff[31:16] <= data_psram_hyper[15:0];
                      end
                   else
                      begin
                        data_buff[15:0] <= data_psram_hyper[15:0];
                        sel <= sel + 1;
                      end
                end
            end else begin
                if(remained_data_i == 0) sel <= 0;
            end
          end
     end

// Internal valid generation
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          int_valid <= 1'b0;
        end
      else
        begin
          if( remained_data_i >= 1 )
            begin
              if(src_valid_i & src_ready_o)
                begin
                  if(mem_sel_i == 2'b11) 
                     int_valid <= 1'b1;
                  else
                    if(sel==1)
                      int_valid <= 1'b1;
                    else
                      if((count_32data < nb_32data) & (remained_data_i == 1)) int_valid <=1'b1;
                      else int_valid <= 1'b0;
                end
              else
                begin
                  int_valid <= 1'b0;
                end
            end
          else
            begin
              int_valid <= 1'b0;
            end
        end
    end

// Check whether or not it's the last 16 bit data
  always @(posedge clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          last <= 1'b0;
        end
      else
        begin
          if(remained_data_i == 1) last <= 1'b1;
          else last <= 1'b0;
        end
    end


////////////////////////////////////////////
// Data shift module for odd start address//
////////////////////////////////////////////

  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           prev_data <= 0;
           int_valid_buff <= 1'b0;
           last_buff <= 0;
         end
       else
         begin
           if(count_32data < nb_32data) int_valid_buff <= int_valid;
           else int_valid_buff <= 0;
           if( int_valid &src_ready_o )
             begin
               prev_data <= data_buff;
               last_buff <= last;
             end
         end
     end

  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           count_32data <= 0;
         end
       else
         begin
           if(nb_32data == count_32data)
             count_32data <= 0;
           else
             if( int_valid & dst_ready_i ) count_32data <= count_32data + 1;
         end
     end

   assign data_rot = hyper_odd_saaddr_i  ?  {data_buff[7:0], prev_data[31:8]} : data_buff;
   assign dst_valid_o = hyper_odd_saaddr_i ? int_valid_buff : int_valid;
   assign last_mux = hyper_odd_saaddr_i ? last_buff : last;
   assign data_o = (last_mux) && (cfg_rx_size_i[1:0]==2'b11) ? {{8{1'b0}} , data_rot[23:0]}:
                   (last_mux) && (cfg_rx_size_i[1:0]==2'b10) ? {{16{1'b0}}, data_rot[15:0]}:
                   (last_mux) && (cfg_rx_size_i[1:0]==2'b01) ? {{24{1'b0}}, data_rot[7:0]}: data_rot;

endmodule
