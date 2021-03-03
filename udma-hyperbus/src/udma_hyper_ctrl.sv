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

module udma_hyper_ctrl
#(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE = 16,
    parameter DELAY_BIT_WIDTH = 3,
    parameter ID_WIDTH =1,
    parameter NR_CS =2
)
(
    input  logic                    clk_i,
    input  logic                    rst_ni,

    output logic                    unpack_trans_ready_o,
    input  logic                    unpack_trans_valid_i,
    output logic                    phy_trans_valid_o,
    input  logic                    phy_trans_ready_i,

    input  logic [TRANS_SIZE-1:0]   rx_size_i,
    input  logic [TRANS_SIZE-1:0]   tx_size_i,
    input  logic                    rw_hyper_i,
    input  logic                    addr_space_i,
    input  logic                    rx_valid_phy_i,
    input  logic                    rx_ready_phy_i,
    input  logic                    tx_valid_phy_i,
    input  logic                    tx_ready_phy_i,
    input  logic                    burst_type_i,

    input  logic [31:0]             hyper_addr_i,
    input  logic [15:0]             hyper_intreg_i,
    input  logic [1:0]              mem_sel_i,
    input  logic [ID_WIDTH:0]       trans_id_i,
    //input  logic [2:0]              n_hyperdevice_i,

    //input  logic [31:0]             cfg_t_read_write_recovery_i,
    input  logic [4:0]              unpack_t_latency_access_i,
    input  logic                    unpack_en_latency_additional_i,
    input  logic [31:0]             unpack_t_cs_max_i,
    input  logic [31:0]             unpack_t_read_write_recovery_i,
    input  logic [DELAY_BIT_WIDTH-1:0] unpack_t_rwds_delay_line_i,
    input  logic [3:0]              unpack_t_variable_latency_check_i,


    output logic [TRANS_SIZE-1:0]   ctrl_rx_size_o,
    output logic [TRANS_SIZE-1:0]   ctrl_tx_size_o,
    output logic                    ctrl_rw_hyper_o,
    output logic                    ctrl_addr_space_o,
    output logic                    ctrl_burst_type_o,
    output logic [31:0]             ctrl_hyper_addr_o,
    output logic [15:0]             ctrl_hyper_intreg_o,
    output logic [1:0]              ctrl_mem_sel_o,
    output logic [ID_WIDTH:0]       ctrl_trans_id_o,

    output logic [1:0]              data_mask_lower_o, // mask for DQ7-0
    output logic [1:0]              data_mask_upper_o, // mask for DQ15-0
    output logic [TRANS_SIZE-1:0]   remained_data_o,
    output logic [NR_CS-1:0]        trans_cs_o,
    output logic                    hyper_odd_saaddr_o,
    output logic [TRANS_SIZE-1:0]   trans_burst_o,

    output  logic [4:0]             ctrl_t_latency_access_o,
    output  logic                   ctrl_en_latency_additional_o,
    output  logic [31:0]            ctrl_t_cs_max_o,
    output  logic [31:0]            ctrl_t_read_write_recovery_o,
    output  logic [DELAY_BIT_WIDTH-1:0] ctrl_t_rwds_delay_line_o,
    output  logic [3:0]             ctrl_t_variable_latency_check_o
);

    enum         {IDLE, SETUP, REG_W, WRITETRANSACTION, READTRANSACTION, END}  control_state;
    logic        [31:0]             cnt_rw_recovery;
    logic        [31:0]             cnt_reg_w;
    localparam   T_REG_W = 4;

    logic        [TRANS_SIZE-1:0]   r_rx_size;
    logic        [TRANS_SIZE-1:0]   r_tx_size;
    logic        [31:0]             r_hyper_addr;
    logic        [15:0]             r_hyper_intreg;
    logic        [1:0]              r_mem_sel;
    logic        [ID_WIDTH:0]       r_trans_id;
    logic                           r_rw_hyper;
    logic                           r_addr_space;
    logic                           r_burst_type;

    logic                           even_end_point_tx;
    logic                           hyper_odd_txsize;
    logic                           additional_data;
    logic        [1:0]              tail;

    logic        [4:0]                 r_t_latency_access;
    logic                              r_en_latency_additional;
    logic        [31:0]                r_t_cs_max;
    logic        [31:0]                r_t_read_write_recovery;
    logic        [DELAY_BIT_WIDTH-1:0] r_t_rwds_delay_line;
    logic        [3:0]                 r_t_variable_latency_check;

// mask signal for spi16
    logic [1:0] upper_mask_head_spi16;
    logic [1:0] upper_mask_tail_spi16;
    logic [1:0] lower_mask_head_spi16;
    logic [1:0] lower_mask_tail_spi16;

// mask signal for hyperbus 
    logic [1:0] lower_mask_head_hyper;
    logic [1:0] lower_mask_tail_hyper;

// mask signal for spi8
    logic [1:0] lower_mask_head_spi8;
    logic [1:0] lower_mask_tail_spi8;

//////////////////////////////////////
// Registers for unpack transactions//
//////////////////////////////////////
 
    always_ff @(posedge clk_i or negedge rst_ni)
      begin
        if(!rst_ni)
          begin
            r_rx_size <= 0;
            r_tx_size <= 0;
            r_hyper_addr <= 0;
            r_hyper_intreg <= 0;
            r_rw_hyper <= 0;
            r_addr_space <= 0;
            r_burst_type <= 0;
            r_mem_sel    <= 0;
            r_t_latency_access         <= 'h6;
            r_en_latency_additional    <= 'b1;
            r_t_cs_max                 <= 'd665;
            r_t_read_write_recovery    <= 'h6;
            r_t_rwds_delay_line        <= 'd2;
            r_t_variable_latency_check <= 'd3;
          end
        else
          begin
            if(unpack_trans_ready_o & unpack_trans_valid_i)
              begin
                r_tx_size <= tx_size_i;
                r_rx_size <= rx_size_i;
                r_hyper_addr <= hyper_addr_i;
                r_hyper_intreg <= hyper_intreg_i;
                r_rw_hyper <= rw_hyper_i;
                r_addr_space <= addr_space_i;
                r_burst_type <= burst_type_i;
                r_mem_sel <= mem_sel_i;
                r_t_latency_access         <= unpack_t_latency_access_i;
                r_en_latency_additional    <= unpack_en_latency_additional_i;
                r_t_cs_max                 <= unpack_t_cs_max_i;
                r_t_read_write_recovery    <= unpack_t_read_write_recovery_i;
                r_t_rwds_delay_line        <= unpack_t_rwds_delay_line_i;
                r_t_variable_latency_check <= unpack_t_variable_latency_check_i;
               // r_trans_id <= trans_id_i;
              end
          end
      end

///////////////////////////
// Output control signals//
///////////////////////////

    assign ctrl_rx_size_o = r_rx_size;
    assign ctrl_tx_size_o = r_tx_size; 
    assign ctrl_hyper_addr_o = r_hyper_addr;
    assign ctrl_hyper_intreg_o = r_hyper_intreg;
    assign ctrl_rw_hyper_o = r_rw_hyper;
    assign ctrl_addr_space_o = r_addr_space;
    assign ctrl_burst_type_o = r_burst_type;
    assign ctrl_mem_sel_o = r_mem_sel;
    assign ctrl_trans_id_o = r_trans_id;

    assign ctrl_t_latency_access_o = r_t_latency_access;
    assign ctrl_en_latency_additional_o = r_en_latency_additional;
    assign ctrl_t_cs_max_o = r_t_cs_max;
    assign ctrl_t_read_write_recovery_o = r_t_read_write_recovery;
    assign ctrl_t_rwds_delay_line_o = r_t_rwds_delay_line;
    assign ctrl_t_variable_latency_check_o = r_t_variable_latency_check;

////////////////////////////////////
// State machine of the controller//
////////////////////////////////////


    assign additional_data = ((mem_sel_i==2'b11) & ( (r_tx_size[1:0] > 2'b00) | hyper_odd_saaddr_o)) |
                             ((mem_sel_i==2'b11) & ( (r_rx_size[1:0] > 2'b00) | hyper_odd_saaddr_o)) |
                             ((mem_sel_i!=2'b11) & ( (r_tx_size[0] == 1'b1) | hyper_odd_saaddr_o)) |
                             ((mem_sel_i!=2'b11) & ( (r_rx_size[0] == 1'b1) | hyper_odd_saaddr_o)); 


    always_ff @(posedge clk_i or negedge rst_ni)
      begin
        if(!rst_ni)
          begin
             trans_burst_o <= '0;
             control_state <=IDLE;
             cnt_rw_recovery <= 0;
             cnt_reg_w <= 0;
             unpack_trans_ready_o <= 1'b1;
             phy_trans_valid_o <= 1'b0;
             remained_data_o <= 0;
             r_trans_id   <= 1 << ID_WIDTH;
          end
        else
          begin
            case(control_state)
              IDLE: begin
                 phy_trans_valid_o <= 1'b0;
                 trans_burst_o <= '0;
                 if( unpack_trans_ready_o & unpack_trans_valid_i ) 
                   begin
                      control_state <= SETUP; // udma en kicks transactions
                      unpack_trans_ready_o <= 1'b0;
                      r_trans_id <= trans_id_i;
                   end
                 else
                   begin
                      unpack_trans_ready_o <= 1'b1;
                   end
              end
              SETUP: begin // Transaction setup
                 phy_trans_valid_o <= 1'b1;
                 if( (r_addr_space & (!r_rw_hyper))| ((r_mem_sel == 2'b01) & (!r_rw_hyper) & (!r_burst_type)) ) // transaction for the reg space
                   begin
                     if(phy_trans_valid_o & phy_trans_ready_i) begin
                       cnt_reg_w <= T_REG_W + 1;
                       control_state <= REG_W;
                     end
                   end
                 else
                   begin // transaction for the mem space
                     if(r_rw_hyper) // rw=1: read 0:write
                       begin
                         if(phy_trans_valid_o & phy_trans_ready_i) control_state <= READTRANSACTION;
                         if(additional_data) 
                           begin                             
                             if(r_mem_sel == 2'b11) trans_burst_o <= (r_rx_size >>2)+1; // # of 32 bit data received by phy
                             else trans_burst_o <= (r_rx_size >> 1)+1;  // # of 16 bit data received by phy
                             if(r_mem_sel == 2'b11) remained_data_o <= (r_rx_size >> 2)+1; // # of 32 bit data sent to 16b32b module
                             else remained_data_o <= (r_rx_size >> 1)+1; // # of 16 bit data 
                           end
                         else
                           begin
                             if(r_mem_sel == 2'b11) trans_burst_o <= r_rx_size >>2; // # of 32 bit data received by phy
                             else trans_burst_o <= r_rx_size >> 1;  // # of 16 bit data received by phy
                             if(r_mem_sel == 2'b11) remained_data_o <= r_rx_size >> 2; // # of 32 bit data sent to 16b32b module
                             else remained_data_o <= r_rx_size >> 1; // # of 16 bit data  
                           end
                       end
                     else 
                       begin
                         if(phy_trans_valid_o & phy_trans_ready_i) control_state <= WRITETRANSACTION;
                         if(additional_data) // if the burst length is not a multiple of 16 bits
                           begin
                             if(r_mem_sel == 2'b11) trans_burst_o <= (r_tx_size >> 2)+1 ; // # of 32 bit data at phy
                             else trans_burst_o <= (r_tx_size >> 1)+1 ;
                             if(r_mem_sel == 2'b11) remained_data_o <= (r_tx_size >> 2)+1 ; 
                             else remained_data_o <= (r_tx_size >> 1)+1 ;
                           end
                         else
                           begin 
                             if(r_mem_sel == 2'b11) trans_burst_o <= (r_tx_size >> 2);
                             else trans_burst_o <= (r_tx_size >> 1);
                             if(r_mem_sel == 2'b11) remained_data_o <= (r_tx_size >> 2);
                             else remained_data_o <= (r_tx_size >> 1);
                           end

                       end
                   end
              end
              REG_W: begin
                 if(cnt_reg_w == 0)
                   begin
                     control_state <= END;
                     cnt_rw_recovery <= r_t_read_write_recovery-1;
                   end
                 else
                   begin
                     cnt_reg_w <= cnt_reg_w -1; // Waiting for register rw transaction
                   end
              end
              READTRANSACTION: begin
                 if(remained_data_o!=0)
                   begin
                      if(rx_valid_phy_i&rx_ready_phy_i) remained_data_o <= remained_data_o -1;
                   end
                 else
                   begin
                      control_state <= END;
                      cnt_rw_recovery <= r_t_read_write_recovery-1;
                   end
              end
              WRITETRANSACTION: begin
                 if(remained_data_o != 0)
                   begin
                      if( tx_valid_phy_i&tx_ready_phy_i ) remained_data_o <= remained_data_o -1;
                   end
                 else
                   begin
                      control_state <= END;
                      cnt_rw_recovery <= r_t_read_write_recovery-1;
                   end
              end
              END: begin

                 if(cnt_rw_recovery == 0) control_state <= IDLE;
                 else cnt_rw_recovery <= cnt_rw_recovery -1;
                 phy_trans_valid_o <= 1'b0; 
                 remained_data_o <= 0;
                 trans_burst_o <= 0;
                 r_trans_id   <= 1 << ID_WIDTH;
              end
            endcase
          end
      end

/////////////////////////
// Data mask generation//
/////////////////////////

    assign hyper_odd_saaddr_o = r_hyper_addr[0]==1'b1 ? 1 : 0; // transaction start at the odd address
    assign tail = r_hyper_addr[1:0] + r_tx_size[1:0];

    assign lower_mask_head_hyper =  hyper_odd_saaddr_o ? 2'b01 : 
                                    (r_tx_size == 1)   ? 2'b10 : 2'b00;
    assign lower_mask_head_spi8  =  hyper_odd_saaddr_o ? 2'b10 :
                                    (r_tx_size == 1)   ? 2'b01 : 2'b00;
    assign lower_mask_head_spi16 =  hyper_odd_saaddr_o && (r_tx_size == 1) ? 2'b11 :
                                    hyper_odd_saaddr_o ? 2'b10 :
                                    (!hyper_odd_saaddr_o && (r_tx_size <= 2)) ? 2'b01 :  2'b00;
    assign upper_mask_head_spi16 =  (r_tx_size <= 3) && (tail == 2'b01) ? 2'b11 :
                                    (r_tx_size <= 3) && ((tail == 2'b10)|(tail == 2'b11)) ? 2'b01 : 2'b00;
                                    
    assign lower_mask_tail_hyper = (remained_data_o<=2) && tail[0] ? 2'b10: 2'b00;
    assign lower_mask_tail_spi8  = (remained_data_o<=2) && tail[0] ? 2'b01: 2'b00;
    assign lower_mask_tail_spi16 = (remained_data_o<=2) && ((tail == 2'b01)|(tail == 2'b10)) ? 2'b01 : 2'b00;
    assign upper_mask_tail_spi16 = (remained_data_o<=2) && (tail == 2'b01) ? 2'b11:
                                   (remained_data_o<=2) && ((tail == 2'b10)|(tail == 2'b11)) ? 2'b01 : 2'b00;
   
    always_ff @(posedge clk_i or negedge rst_ni)
      begin
        if(!rst_ni)
          begin
            data_mask_lower_o <= 2'b00;
            data_mask_upper_o <= 2'b00;
          end
        else
          case(control_state)
            IDLE: begin
              data_mask_lower_o <= 2'b00;
              data_mask_upper_o <= 2'b00;
            end
            SETUP: begin
              if(mem_sel_i == 2'b11)
                begin
                  data_mask_lower_o <= lower_mask_head_spi16;
                  data_mask_upper_o <= upper_mask_head_spi16;
                end
              else
                begin
                  data_mask_upper_o <= 2'b00;
                  if(mem_sel_i == 2'b10)
                    data_mask_lower_o <= lower_mask_head_spi8;
                  else
                    data_mask_lower_o <= lower_mask_head_hyper;
                end
            end
            WRITETRANSACTION:begin
              if( tx_valid_phy_i & tx_ready_phy_i )
                begin
                  if(mem_sel_i == 2'b11)
                    begin
                       data_mask_lower_o <= lower_mask_tail_spi16;
                       data_mask_upper_o <= upper_mask_tail_spi16;
                    end
                  else
                    begin
                       data_mask_upper_o <= 2'b00;
                       if(mem_sel_i == 2'b10)
                          data_mask_lower_o <= lower_mask_tail_spi8;
                       else  
                          data_mask_lower_o <= lower_mask_tail_hyper;
                    end
                end
            end
          endcase    
      end

/////////////////////////
// Generate chip select//
///////////////////////// 

    assign trans_cs_o[0] = (r_mem_sel == 2'b01) ? 1'b1 : 1'b0; // Hyper flash
    assign trans_cs_o[1] = (r_mem_sel == 2'b00) | (r_mem_sel == 2'b10) | (r_mem_sel == 2'b11 ) ? 1'b1 : 1'b0; // Hyperram or psram

endmodule
