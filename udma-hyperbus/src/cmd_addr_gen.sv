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


module cmd_addr_gen #(
)(
	input logic              rw_i,              //1-read, 0-write
	input logic              address_space_i,   //0-memory, 1-register
	input logic              burst_type_i,      //0-wrapped, 1-linear
	input logic  [31:0]      address_i,
        //input logic  [15:0]      psram_inst_i,
        input logic [1:0]         mem_sel_i,        //00-HyperRAM, 01-HyperFlash, 10-PSRAM
	
	output logic [47:0]      cmd_addr_o
);

        logic [47:0]             cmd_hyper_addr;
        logic [31:0]             hyper_addr;
        logic [47:0]             cmd_psram_addr;
        logic                    psram_sync_read;
        logic                    psram_sync_write;
        logic                    psram_linear_read;
        logic                    psram_linear_write;
        logic                    psram_reg_read;
        logic                    psram_reg_write;

// Decode for PSRAM
        assign psram_sync_read    =   rw_i  & (!burst_type_i) & (!address_space_i);
        assign psram_sync_write   = (!rw_i) & (!burst_type_i) & (!address_space_i);
        assign psram_linear_read  =   rw_i  &   burst_type_i  & (!address_space_i);
        assign psram_linear_write = (!rw_i) &   burst_type_i  & (!address_space_i);
        assign psram_reg_read     =   rw_i  &   address_space_i;
        assign psram_reg_write    = (!rw_i) &   address_space_i;

        assign cmd_psram_addr[47:32] = psram_sync_read    ? 16'h0000:
                                       psram_sync_write   ? 16'h8080:
                                       psram_linear_read  ? 16'h2021:
                                       psram_linear_write ? 16'hA0A0:
                                       psram_reg_read     ? 16'h4040:
                                       psram_reg_write    ? 16'hC0C0: 16'h0000;

        //assign cmd_psram_addr[31:0]  = address_i;
        assign cmd_psram_addr[31:0]  = address_space_i  ? address_i : 
                                       mem_sel_i == 2'b11 ? address_i >> 1 : {address_i[31:1],1'b0};


// Decode for Hyper RAM
        assign hyper_addr            = address_space_i  ? address_i : address_i >> 1; // Comming address are converted into word address
	assign cmd_hyper_addr[47]    = rw_i;
	assign cmd_hyper_addr[46]    = address_space_i;
	assign cmd_hyper_addr[45]    = burst_type_i;
	assign cmd_hyper_addr[44:16] = hyper_addr[31:3];
	assign cmd_hyper_addr[15:3]  = '0;
	assign cmd_hyper_addr[2:0]   = hyper_addr[2:0];

// command output  mem_sel==10: PSRAM, mem_sel == 11: PSRAM 16spi mem_sel==0: HyperRAM
        assign cmd_addr_o = (mem_sel_i==2'b10)|(mem_sel_i==2'b11) ? cmd_psram_addr : cmd_hyper_addr;
endmodule
