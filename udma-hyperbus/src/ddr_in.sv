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

module ddr_in #(
)(
    input logic        clk_i,
    input logic        data_i,
    input logic        rst_ni,
    input logic        enable,
    
    output logic [1:0] data_o
);
    logic ddr_neg;
    logic ddr_pos;

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ddr_pos
        if(~rst_ni) begin
            ddr_pos <= 1'b0;
        end else if (enable) begin
            ddr_pos <= data_i;
        end
    end
    
    always_ff @(negedge clk_i or negedge rst_ni) begin : proc_ddr_neg
        if(~rst_ni) begin
            ddr_neg <= 1'b0;
        end else if (enable) begin
            ddr_neg <= data_i;
        end
    end

    assign data_o[0] = ddr_neg;
    assign data_o[1] = ddr_pos;
endmodule

