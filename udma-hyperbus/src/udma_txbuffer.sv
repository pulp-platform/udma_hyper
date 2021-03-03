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

// This module modifies the data width from 32bit (uDMA) to 16bit (PHY).
// Also, this module is a mux between the data for the register and memory space.

module udma_txbuffer 
#(
  parameter TRANS_SIZE = 16

)
(
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        src_valid_i,
  output logic        src_ready_o,

  input  logic        dst_ready_i,
  output logic        dst_valid_o,

  input  logic [1:0]  mem_sel_i,
  input  logic        cfg_addr_space_i,
  input  logic        burst_type_i,
  input  logic [15:0] cfg_hyper_intreg_i,
  input  logic [TRANS_SIZE-1:0] remained_data_i,

  input  logic        hyper_odd_saaddr_i,

  input  logic [31:0] data_i,
  output logic [31:0] data_o
);

  logic  [1:0 ]  sel;
  logic          src_valid_d; 
  logic          prev_data_valid;
  logic          valid16;   // valid signal for 16 bit dataout
  logic          valid32;   // valid signal for 32 bit dataout
  logic  [31:0]  data32;
  logic  [15:0]  data16;


  logic  [15:0]  upper_data;   // for 31:16 bits of data_i
  logic  [15:0]  lower_data;   // for 15:0 bits of data_i
  logic  [31:0]  r_in_data;
  logic  [15:0]  tx_data_mux;
  logic  [31:0]  data_rotate;
  logic          last_32data;
  logic          busy;

  logic  [31:0]  r_prev_data;


  
///////////////////////////////////////
//Capturing data from the source FIFO//
///////////////////////////////////////

// data register
  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           r_prev_data <=0;
           r_in_data <= 0;
         end
       else
         begin
           if(dst_ready_i)
             begin
               if( src_valid_i & src_ready_o   )
                 begin
                     r_prev_data <= r_in_data;
                     r_in_data <= data_i;
                 end
             end
           else
             begin
               r_prev_data <=0;
               r_in_data <= 0;
             end
         end
     end

// valid signal for the previous data and ready gen
  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           src_ready_o <=0;
           src_valid_d <= 0;
         end
       else
         begin
           if(dst_ready_i)
             begin
               if( src_valid_i & src_ready_o )  
                 begin
                     if(mem_sel_i != 2'b11) src_ready_o <= 0; // 16 bit data transfer requires 2 cycles
                     else src_ready_o <= 1;
                     src_valid_d <=1;
                 end
               else
                 begin
                     src_valid_d <=0;
                     src_ready_o <=1;
                 end
             end
           else
             begin
               src_valid_d <=0;
               src_ready_o <=0;
             end
         end
     end

///////////////////////////////////
/// Data transmission to the PHY///
///////////////////////////////////

  assign dst_valid_o = (mem_sel_i == 2'b11) ? valid32 : valid16; 
  assign data_o = {mem_sel_i == 2'b11} ? data32 : {16'b0, data16};

  // For 32 bit data transmission
  assign data_rotate = hyper_odd_saaddr_i ? {r_in_data[23:0], r_prev_data[31:24]}: r_in_data;
  assign data32 = data_rotate;
  assign valid32 = src_valid_d;

//  always @(posedge clk_i or negedge rst_ni)
//    begin
//       if(!rst_ni)
//          begin
//            prev_data_valid <= 1'b0;
//          end
//       else
//          begin
//             if( src_valid_d & dst_ready_i )
//                 prev_data_valid <= 1'b1;
//             else
//                 prev_data_valid <= 1'b0;
//          end
//    end

  // For 16 bit data transmission
  assign upper_data = (mem_sel_i == 2'b11) | (mem_sel_i == 2'b10) ? {data_rotate[23:16], data_rotate[31:24]} : data_rotate[31:16];
  assign lower_data = (mem_sel_i == 2'b11) | (mem_sel_i == 2'b10) ? {data_rotate[7:0], data_rotate[15:8]}    : data_rotate[15:0];
  assign data16 = cfg_addr_space_i | ((mem_sel_i == 2'b01) & ( burst_type_i == 1'b0 )) ? cfg_hyper_intreg_i : tx_data_mux;

  always @(posedge clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
          begin
            tx_data_mux <= 0;
            valid16 <= 0;
            sel <= 0;
            busy <=0;
          end
       else
          begin
             // when dst is ready and data is available, or when sending upper 16 bit is not finished
             if( (src_valid_d & dst_ready_i ) | (dst_ready_i & sel == 1) | ( busy==1 & remained_data_i !=0) ) 
               begin
                 busy <= 1'b1;
                 valid16 <= 1'b1;
                 if(sel==1) 
                    begin
                       tx_data_mux <= upper_data;
                       sel <= 0;
                    end
                 else
                    begin
                       tx_data_mux <= lower_data;
                       sel <= sel + 1;
                    end
               end 
            else
              begin
                  busy <= 1'b0;
                  valid16 <= 1'b0;
                  sel <= 0;
               end
          end
     end


endmodule
