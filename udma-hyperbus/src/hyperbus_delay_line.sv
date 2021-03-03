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


/// delay line
`timescale 1 ps/1 ps

module hyperbus_delay_line 
#(
    parameter BIT_WIDTH = 3
)
(
    input        in,
    output       out,
    //input [31:0] delay
    input [BIT_WIDTH-1:0] delay
);

   localparam  N_WIRE =       -1*(1-2**(BIT_WIDTH));
   localparam  N_PATH =        2**(BIT_WIDTH);
   logic      [N_WIRE-1:0]     mux_out;
   logic      [N_PATH-1:0]     first_input;

   assign out = mux_out[0];     
   genvar i;

   // delay_path
   generate 
    `ifndef SYNTHESIS
       for( i = 0; i < N_PATH; i++)
          begin
            assign #(i*0.25ns) first_input[i] = in;
          end
    `else
       for( i = 0; i < N_PATH; i++)
          begin
            assign first_input[i] = in;
          end

    `endif
   endgenerate

   // tree of mux
   genvar j,k;
   generate
     for( j = 0; j < BIT_WIDTH; j++)
        begin
           for( k = 0; k < 2**(j+1); k = k+2)
              begin
                if(j== BIT_WIDTH-1)
                   begin
                     hyperbus_mux_generic i_clk_mux
                     (
                         .A ( first_input[k]          ),
                         .B ( first_input[k+1]        ),
                         .S ( delay[BIT_WIDTH-1-j]    ),
                         .Z ( mux_out[k/2-1*(1-2**j)] )
                     );
                   end
                else
                   begin
                     hyperbus_mux_generic i_clk_mux
                     (
                         .A ( mux_out[k-1*(1-2**(j+1))]   ),
                         .B ( mux_out[k+1-1*(1-2**(j+1))] ),
                         .S ( delay[BIT_WIDTH-1-j]        ),
                         .Z ( mux_out[k/2-1*(1-2**j)]     )
                     );
                   end

              end
        end 
   endgenerate

endmodule
