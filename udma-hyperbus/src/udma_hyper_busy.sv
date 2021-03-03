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


module udma_hyper_busy(
   input    sys_clk_i,
   input    phy_clk_i,
   input    rst_ni,

   input    proc_id_sys_i,
   input    proc_id_phy_i,
   input    running_trans_sys_i,
   input    running_trans_phy_i,

   output   evt_eot_o,
   output   busy_o
);

   enum     {IDLE, ISSUED, BUSY, END}  control_state;
   logic    r_busy;
   logic    r_running_trans_phy, r2nd_running_trans_phy, r3rd_running_trans_phy;
   logic    r_proc_id_phy, r2nd_proc_id_phy, r3rd_proc_id_phy;
   logic    running_trans_phy_id;
   assign   busy_o =  (rst_ni)? r_busy | running_trans_sys_i : 0;
   logic    busy_d;


   always_ff @(posedge phy_clk_i, negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           r_running_trans_phy <= 0;
           r_proc_id_phy <=0;
         end
       else
         begin
           r_running_trans_phy <= running_trans_phy_i;
           r_proc_id_phy <= proc_id_phy_i;
         end
     end

   always_ff @(posedge sys_clk_i, negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           r2nd_running_trans_phy <= 0;
           r3rd_running_trans_phy <= 0;
           r2nd_proc_id_phy <=0;
           r3rd_proc_id_phy <=0;
         end
       else
         begin
           r2nd_running_trans_phy <= r_running_trans_phy; // these flip flops are for avoiding metastable
           r3rd_running_trans_phy <= r2nd_running_trans_phy;
           r2nd_proc_id_phy <= r_proc_id_phy;
           r3rd_proc_id_phy <= r2nd_proc_id_phy;
         end
     end
   assign running_trans_phy_id = r3rd_proc_id_phy & r3rd_running_trans_phy;

   always @(posedge sys_clk_i, negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           control_state <= IDLE;
           r_busy <= 0;
         end
       else
         begin
           case(control_state)
             IDLE: begin
               if(running_trans_sys_i) 
                 begin
                   control_state <= ISSUED; 
                   r_busy <= 1'b1;
                 end
               else
                 begin
                   r_busy <= 1'b0;
                 end
             end
             ISSUED: begin
               if(running_trans_phy_id) control_state <= BUSY;
               r_busy <= 1'b1;
             end
             BUSY: begin
               if((!running_trans_phy_id)&(!proc_id_sys_i))
                 begin
                   if(running_trans_sys_i) control_state <= ISSUED;
                   else control_state <= END;
                 end
               r_busy <= 1'b1;
             end
             END: begin
               control_state <= IDLE;
               r_busy <= 1'b0;
             end
           endcase
         end
     end

   assign evt_eot_o = (~busy_o) & busy_d ? 1'b1 : 1'b0;
   always_ff @(posedge sys_clk_i, negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           busy_d <= 0;
         end
       else
         begin
           busy_d <= busy_o;
         end
     end
 

endmodule
