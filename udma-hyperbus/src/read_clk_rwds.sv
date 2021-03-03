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

// Description: Connection between HyperBus and Read CDC FIFO
`timescale 1 ps/1 ps

module read_clk_rwds #(
    parameter  DELAY_BIT_WIDTH = 3
)(
    input logic                    clk0,
    input logic                    rst_ni,   // Asynchronous reset active low

    input  logic                   clk_test,
    input  logic                   test_en_ti,

    input logic [1:0]                 mem_sel_i,
    input logic [DELAY_BIT_WIDTH-1:0] config_t_rwds_delay_line,

    input logic                    hyper_rwds_i,
    input logic [15:0]             hyper_dq_i,
    input logic                    read_clk_en_i,
    input logic                    en_ddr_in_i,
    input logic                    ready_i, //Clock to FIFO

    output logic                   valid_o,
    output logic [31:0]            data_o
);

    logic resetReadModule;
    logic hyper_rwds_i_d;
    logic clk_rwds;
    logic clk_rwds_n;
    logic clk_rwds_orig;
    logic [15:0] data_pedge;
    logic [31:0] data_fifoin;

    logic cdc_input_fifo_ready;
    logic read_in_valid;


    //Delay of rwds for center aligned read
    hyperbus_delay_line #(
        .BIT_WIDTH     ( DELAY_BIT_WIDTH          )
    )hyperbus_delay_line_i(
        .in            ( hyper_rwds_i             ),
        .out           ( hyper_rwds_i_d           ),
        .delay         ( config_t_rwds_delay_line )
    );

    // Clock gate
    assign clk_rwds_orig = hyper_rwds_i_d && read_clk_en_i;

   `ifdef PULP_FPGA_EMUL
    pulp_clock_mux2 ddrmux (
        .clk_o     ( clk_rwds      ),
        .clk0_i    ( clk_rwds_orig ),
        .clk1_i    ( clk_test      ),
        .clk_sel_i ( test_en_ti    )
    );
   `else
    always_comb
      begin
        if (test_en_ti == 1'b0)
          clk_rwds = clk_rwds_orig;
        else
          clk_rwds = clk_test;
      end

   `endif

    assign resetReadModule = ~rst_ni || (~read_clk_en_i && ~test_en_ti);

    always_ff @(posedge clk_rwds or posedge resetReadModule) begin : proc_read_in_valid
        if(resetReadModule) begin
            read_in_valid <= 0;
        end else begin
            read_in_valid <= 1;
        end
    end

    always @(posedge clk_rwds or posedge resetReadModule)
      begin
        if(resetReadModule)
          data_pedge <= 0;
        else
          data_pedge <= hyper_dq_i;
      end

    assign data_fifoin = (mem_sel_i==2'b11) ? {data_pedge, hyper_dq_i} : {16'b0, data_pedge[7:0], hyper_dq_i[7:0]};



    `ifndef SYNTHESIS
    always @(negedge cdc_input_fifo_ready) begin
        assert(cdc_input_fifo_ready) else $error("FIFO i_cdc_fifo_hyper should always be ready");
    end
    `endif

    cdc_fifo_gray_hyper  #(.T(logic[31:0]), .LOG_DEPTH(4)) i_cdc_fifo_hyper ( 
      .src_rst_ni  ( rst_ni               ), 
      .src_clk_i   ( !clk_rwds             ), 
      .src_data_i  ( data_fifoin           ), 
      .src_valid_i ( read_in_valid        ), 
      .src_ready_o ( cdc_input_fifo_ready ), 
 
      .dst_rst_ni  ( rst_ni  ), 
      .dst_clk_i   ( clk0    ), 
      .dst_data_o  ( data_o  ), 
      .dst_valid_o ( valid_o ), 
      .dst_ready_i ( ready_i ) 
    ); 
    

endmodule
