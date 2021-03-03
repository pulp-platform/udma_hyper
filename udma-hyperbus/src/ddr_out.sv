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


/// A single to double data rate converter.

module ddr_out #(
    parameter logic INIT = 1'b0
)(
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d0_i,
    input  logic d1_i,
    output logic q_o
);
    logic q0;
    logic q1;

    /*pulp_clock_mux2 ddrmux (
        .clk_o     ( q_o   ),
        .clk0_i    ( q1    ),
        .clk1_i    ( q0    ),
        .clk_sel_i ( clk_i )
    );*/


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            //q0 <= INIT;
            q1 <= INIT;
        end else begin
            //q0 <= d0_i;
            q1 <= d1_i;
        end
    end
    always_ff @(negedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            q0 <= INIT;
        end else begin
            q0 <= d0_i;
        end
    end

    always_comb
      begin
        if(clk_i == 1'b0)
           q_o = q1;
        else
           q_o = q0;
      end
endmodule
