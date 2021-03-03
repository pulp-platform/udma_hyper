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

`timescale 1ns / 1ps

module clock_diff_out
(
    input  logic in_i,
    input  logic en_i, //high enable
    output logic out_o,
    output logic out_no
);

   `ifdef PULP_FPGA_EMUL

       logic en_sync;
    
       always_latch
       begin
         if (in_i == 1'b0)
           en_sync <= en_i;
       end

       assign out_o = in_i & en_sync;
       assign out_no = ~out_o;

   `else

       pulp_clock_gating hyper_ck_gating (
           .clk_i     ( in_i  ),
           .en_i      ( en_i  ),
           .test_en_i ( 1'b0  ),
           .clk_o     ( out_o )
       );

       pulp_clock_inverter hyper_ck_no_inv (
           .clk_i ( out_o  ),
           .clk_o ( out_no )
       );

   `endif

    
endmodule
