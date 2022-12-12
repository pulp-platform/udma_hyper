// Copyright 2018 ETH Zurich and University of Bologna.
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

`timescale 1ps/1ps
// Configuration register for Hyper bus CHANNEl
`define REG_RX_SADDR            5'b00000 //BASEADDR+0x00 L2 address for RX
`define REG_RX_SIZE             5'b00001 //BASEADDR+0x04 size of the software buffer in L2
`define REG_UDMA_RXCFG          5'b00010 //BASEADDR+0x08 UDMA configuration setup (RX)
`define REG_TX_SADDR            5'b00011 //BASEADDR+0x0C address of the data being transferred 
`define REG_TX_SIZE             5'b00100 //BASEADDR+0x10 size of the data being transferred
`define REG_UDMA_TXCFG          5'b00101 //BASEADDR+0x14 UDMA configuration setup (TX)
`define HYPER_CA_SETUP          5'b00110 //BASEADDR+0x18 set read/write, address space, and burst type 
`define REG_HYPER_ADDR          5'b00111 //BASEADDR+0x1C set address in a hyper ram.
`define REG_HYPER_CFG           5'b01000 //BASEADDR+0x20 set the configuration data for HyperRAM
`define STATUS                  5'b01001 //BASEADDR+0x24 status register
`define TWD_ACT_EXT             5'b01010 //BASEADDR+0x28 set 2D transfer activation
`define TWD_COUNT_EXT           5'b01011 //BASEADDR+0x2C set 2D transfer count
`define TWD_STRIDE_EXT          5'b01100 //BASEADDR+0x30 set 2D transfer stride
`define TWD_ACT_L2              5'b01101 //BASEADDR+0x28 set 2D transfer activation
`define TWD_COUNT_L2            5'b01110 //BASEADDR+0x2C set 2D transfer count
`define TWD_STRIDE_L2           5'b01111 //BASEADDR+0x30 set 2D transfer stride

// Configuration register for Hyper bus CHANNEl
`define REG_PAGE_BOUND          5'b00000 //BASEADDR+0x00 set the page boundary.
`define REG_T_LATENCY_ACCESS    5'b00001 //BASEADDR+0x04 set t_latency_access
`define REG_EN_LATENCY_ADD      5'b00010 //BASEADDR+0x08 set en_latency_additional
`define REG_T_CS_MAX            5'b00011 //BASEADDR+0x0C set t_cs_max
`define REG_T_RW_RECOVERY       5'b00100 //BASEADDR+0x10 set t_read_write_recovery
`define REG_T_RWDS_DELAY_LINE   5'b00101 //BASEADDR+0x14 set t_rwds_delay_line
`define REG_T_VARI_LATENCY      5'b00110 //BASEADDR+0x18 set t_variable_latency_check
`define N_HYPER_DEVICE          5'b00111 //BASEADDR+0x1C set the number of connected devices
`define MEM_SEL                 5'b01000 //BASEADDR+0x20 set Memory select: HyperRAM, Hyperflash, or PSRAM 00:Hyper RAM, 01: Hyper Flash, 10:PSRAM
`define TRANS_ID_ALLOC          5'b01001 //BASEADDR+0x30 set 2D transfer stride

module hyper_macro_tb;


  timeunit 1ns;
  import udma_pkg::*;

  localparam TCLK = 7ns;
  //localparam TCLK = 5ns;
  localparam SYSTCLK = 14ns;
  //localparam SYSTCLK = 12.5ns;
  localparam NR_CS = 2;
  localparam L2_AWIDTH_NOAL = 12;
  localparam TRANS_SIZE = 16;
  localparam BYTE_WIDTH = 8;
  localparam MEM_DEPTH = 4096;
  localparam NB_CH=8;
   

  logic                   clk_i;
  logic                   sys_clk_i;
  logic                   phy_clk_i;
  logic                   phy_clk_d;
  logic                   clk0;
  logic                   clk90;
  logic                   rst_ni;
  logic                   phy_rst_ni;

  logic [31:0]            rx_data_udma_o;
  logic                   rx_valid_udma_o;
  logic                   rx_ready_udma_i;

  logic [31:0]            tx_data_udma_i;
  logic                   tx_valid_udma_i;
  logic                   tx_valid_udma_d;
  logic                   tx_valid_udma2_i;
  logic                   tx_ready_udma_o;

  logic [NR_CS-1:0]       hyper_cs_no;
  logic                   hyper_ck_o;
  logic                   hyper_ck_no;
  logic                   hyper_rwds_o;
  logic                   hyper_rwds_i;
  logic                   hyper_rwds_oe_o;
  logic [15:0]            hyper_dq_i;
  logic [15:0]            hyper_dq_o;
  logic                   hyper_dq_oe_o;
  logic                   hyper_reset_no;

  logic [1:0]             debug_hyper_rwds_oe_o;
  logic [1:0]             debug_hyper_dq_oe_o;
  logic [3:0]             debug_hyper_phy_state_o;


  logic [31:0]            cfg_data_i;
  logic [5:0]             cfg_addr_i;
  logic [NB_CH:0]         cfg_valid_i;
  logic                   cfg_rwn_i;
  logic [NB_CH:0][31:0]   cfg_data_o;
  logic [NB_CH:0]         cfg_ready_o;

  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o;
  logic [TRANS_SIZE-1:0]     cfg_rx_size_o;
  logic [1:0]                cfg_rx_datasize_o;
  logic                      cfg_rx_continuous_o;
  logic                      cfg_rx_en_o;
  logic                      cfg_rx_clr_o;
  logic                      cfg_rx_en_i;
  logic                      cfg_rx_pending_i;
  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i;
  logic [TRANS_SIZE-1:0]     cfg_rx_bytes_left_i;

  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o;
  logic [TRANS_SIZE-1:0]     cfg_tx_size_o;
  logic [1:0]                cfg_tx_datasize_o;
  logic                      cfg_tx_continuous_o;
  logic                      cfg_tx_en_o;
  logic                      cfg_tx_clr_o;
  logic                      cfg_tx_en_i;
  logic                      cfg_tx_pending_i;
  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i;
  logic [TRANS_SIZE-1:0]     cfg_tx_bytes_left_i;
  logic [31:0]               count;

  logic [BYTE_WIDTH-1:0]     data_mem [0:MEM_DEPTH-1]; // 4KB data mem
  logic [L2_AWIDTH_NOAL-1:0] data_mem_addr;
  logic [L2_AWIDTH_NOAL-1:0] r_tx_addr;
  logic [31:0]               mem_data_out;
  logic [31:0]               mem_data_out_d;
  logic [31:0]               data_count;
  logic [31:0]               rx_data_count;
  logic [31:0]               tran_size;
  logic [31:0]               tran_size32;
  logic [TRANS_SIZE-1:0]     r_tx_size;
  logic                      r_write_tran_en;
  logic                      r_rx_en;

  cfg_req_t hyper_cfg_req_i;
  cfg_rsp_t hyper_cfg_rsp_o;
  // data channels from/to the macro
  udma_linch_tx_req_t hyper_linch_tx_req_i;
  udma_linch_tx_rsp_t hyper_linch_tx_rsp_o;
  udma_linch_rx_req_t hyper_linch_rx_req_o;
  udma_linch_rx_rsp_t hyper_linch_rx_rsp_i;

  // Data memory for test
   /////////////////////////////////////////////////
   //                    MEMORY                   //
   /////////////////////////////////////////////////
  assign mem_data_out = { data_mem[data_mem_addr+3], data_mem[data_mem_addr+2], data_mem[data_mem_addr+1], data_mem[data_mem_addr]};

  always @(posedge sys_clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          r_write_tran_en <= 0;
          r_tx_size <=0;
        end
      else
        begin
          if( cfg_tx_en_o & (data_count == 0))
            begin
              r_write_tran_en <= cfg_tx_en_o;
              r_tx_size <= cfg_tx_size_o;
            end
          else
            begin
              if(data_count >= r_tx_size) r_write_tran_en <= 0;
            end
        end
    end

   assign cfg_tx_bytes_left_i = (r_write_tran_en)? r_tx_size - data_count: 0;
   always  @(posedge sys_clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
            data_count <=0;
            tx_valid_udma_i <= 1'b0;
         end
       else
         begin
           if(r_write_tran_en)
               if(tx_ready_udma_o)
                 begin
                   if(tx_valid_udma_i == 1'b1 & (data_count < r_tx_size))
                     begin
                      data_count <= data_count +4;
                     end
                   else
                      if((data_count < r_tx_size))tx_valid_udma_i <= 1'b1;
                      else tx_valid_udma_i <= 1'b0;
                 end
               else
                 begin
                   //tx_valid_udma_i <= 1'b0;
                 end
           else
             begin
               data_count <=0;
               tx_valid_udma_i <= 1'b0;
             end
         end
     end

   always @(posedge sys_clk_i or negedge rst_ni)
     begin
       if(!rst_ni)
         begin
           data_mem_addr <= 0;
         end
       else
         begin
           if( cfg_tx_en_o & data_count ==0) 
             begin
                data_mem_addr <= cfg_tx_startaddr_o;
             end 
           else
             begin
               if(r_write_tran_en & tx_ready_udma_o & tx_valid_udma_i)
                  data_mem_addr <= data_mem_addr +4;
             end
         end
     end

  assign cfg_rx_en_i = cfg_rx_en_o | r_rx_en;
  always @(posedge sys_clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          r_rx_en <= 1'b0;
        end
      else
        begin
          if(cfg_rx_en_o & (cfg_rx_size_o!=0)) r_rx_en <= 1'b1;
          else if((r_rx_en==1'b1) & (cfg_rx_bytes_left_i==0)) r_rx_en <=0;
        end
    end

    wire [1:0]   wire_rwds;
    wire [15:0 ] wire_dq_io;
    wire [1:0]  wire_cs_no;
    wire        wire_ck_o;
    wire        wire_ck_no;
    wire        wire_reset_no;

    // binding old testbench signals to the new hyper_macro_boundary
    assign hyper_cfg_req_i.data = cfg_data_i;
    assign hyper_cfg_req_i.addr = cfg_addr_i;
    assign hyper_cfg_req_i.valid = |cfg_valid_i;
    assign hyper_cfg_req_i.rwn = cfg_rwn_i;
    assign cfg_ready_o = hyper_cfg_rsp_o.ready;
    assign cfg_data_o = hyper_cfg_rsp_o.data;

    // tx channel
    assign hyper_linch_tx_req_i.bytes_left = cfg_tx_bytes_left_i;
    assign hyper_linch_tx_req_i.curr_addr = cfg_tx_curr_addr_i;
    assign hyper_linch_tx_req_i.data = mem_data_out_d;
    assign hyper_linch_tx_req_i.en = r_write_tran_en;
    assign hyper_linch_tx_req_i.events = '0;
    assign hyper_linch_tx_req_i.pending = cfg_tx_pending_i;
    assign hyper_linch_tx_req_i.stream = '0;
    assign hyper_linch_tx_req_i.stream_id = '0;
    assign hyper_linch_tx_req_i.valid = tx_valid_udma_d;
    assign hyper_linch_tx_req_i.gnt = '1;
    assign cfg_tx_en_o = hyper_linch_tx_rsp_o.cen;
    assign cfg_tx_clr_o = hyper_linch_tx_rsp_o.clr;
    assign cfg_tx_continuous_o = hyper_linch_tx_rsp_o.continuous;
    assign cfg_tx_datasize_o = hyper_linch_tx_rsp_o.datasize;
    // assign tx_ch[0].destination = hyper_linch_tx_rsp_o.destination;
    assign tx_ready_udma_o = hyper_linch_tx_rsp_o.ready;
    // assign tx_ch[0].req = hyper_linch_tx_rsp_o.req;
    assign cfg_tx_size_o = hyper_linch_tx_rsp_o.size;
    assign cfg_tx_startaddr_o = hyper_linch_tx_rsp_o.startaddr;

    // rx channel
    assign cfg_rx_en_o = hyper_linch_rx_req_o.cen;
    assign cfg_rx_clr_o = hyper_linch_rx_req_o.clr;
    assign cfg_rx_continuous_o = hyper_linch_rx_req_o.continuous;
    assign rx_data_udma_o = hyper_linch_rx_req_o.data;
    assign cfg_rx_datasize_o = hyper_linch_rx_req_o.datasize;
    // assign rx_ch[0].destination = hyper_linch_rx_req_o.destination;
    // assign rx_ch[0].req = hyper_linch_rx_req_o.req;
    assign cfg_rx_size_o = hyper_linch_rx_req_o.size;
    assign cfg_rx_startaddr_o = hyper_linch_rx_req_o.startaddr;
    // assign rx_ch[0].stream = hyper_linch_rx_req_o.stream;
    // assign rx_ch[0].stream_id = hyper_linch_rx_req_o.stream_id;
    assign rx_valid_udma_o = hyper_linch_rx_req_o.valid;

    assign hyper_linch_rx_rsp_i.bytes_left = cfg_rx_bytes_left_i;
    assign hyper_linch_rx_rsp_i.curr_addr = cfg_rx_curr_addr_i;
    assign hyper_linch_rx_rsp_i.en = cfg_rx_en_i;
    assign hyper_linch_rx_rsp_i.events = '0;
    assign hyper_linch_rx_rsp_i.gnt = '1;
    assign hyper_linch_rx_rsp_i.pending = cfg_rx_pending_i;
    assign hyper_linch_rx_rsp_i.ready = '1;

    hyper_macro i_dut (
      .sys_clk_i           (sys_clk_i           ),
      .periph_clk_i        (phy_clk_d           ),
      .rstn_i              (rst_ni              ),
      .hyper_cfg_req_i     (hyper_cfg_req_i     ),
      .hyper_cfg_rsp_o     (hyper_cfg_rsp_o     ),
      .hyper_linch_tx_req_i(hyper_linch_tx_req_i),
      .hyper_linch_tx_rsp_o(hyper_linch_tx_rsp_o),
      .hyper_linch_rx_req_o(hyper_linch_rx_req_o),
      .hyper_linch_rx_rsp_i(hyper_linch_rx_rsp_i),
      .hyper_macro_evt_o   (                    ),
      .hyper_macro_evt_i   ('0                  ),
      .pad_hyper_csn0      (wire_cs_no[1]       ),
      .pad_hyper_reset_n   (wire_reset_no       ),
      .pad_hyper_ck        (wire_ck_o           ),
      .pad_hyper_ckn       (wire_ck_no          ),
      .pad_hyper_dq0       (wire_dq_io[0]       ),
      .pad_hyper_dq1       (wire_dq_io[1]       ),
      .pad_hyper_dq2       (wire_dq_io[2]       ),
      .pad_hyper_dq3       (wire_dq_io[3]       ),
      .pad_hyper_dq4       (wire_dq_io[4]       ),
      .pad_hyper_dq5       (wire_dq_io[5]       ),
      .pad_hyper_dq6       (wire_dq_io[6]       ),
      .pad_hyper_dq7       (wire_dq_io[7]       ),
      .pad_hyper_rwds      (wire_rwds[0]        )
    );

    //simulate pad delays
    //-------------------
    

  // assign wire_reset_no = hyper_reset_no; //if delayed, a hold violation occures 

  s27ks0641 #(.mem_file_name("./test_mem.dat"), .TimingModel("S27KS0641DPBHI020")) hyperram_model
  (
    .DQ7      (wire_dq_io[7]),
    .DQ6      (wire_dq_io[6]),
    .DQ5      (wire_dq_io[5]),
    .DQ4      (wire_dq_io[4]),
    .DQ3      (wire_dq_io[3]),
    .DQ2      (wire_dq_io[2]),
    .DQ1      (wire_dq_io[1]),
    .DQ0      (wire_dq_io[0]),
    .RWDS     (wire_rwds[0]),
    .CSNeg    (wire_cs_no[1]),
    .CK       (wire_ck_o),
    .CKNeg    (wire_ck_no),
    .RESETNeg (wire_reset_no)    
  );
   
  always begin
      phy_clk_i = 1;
      #(TCLK/2);
      phy_clk_i = 0;
      #(TCLK/2);
  end
  assign #(TCLK/6) phy_clk_d =  phy_clk_i;
  assign #(SYSTCLK/6) mem_data_out_d  =  mem_data_out;
  assign #(SYSTCLK/6) tx_valid_udma_d = tx_valid_udma_i;


  always begin
      sys_clk_i = 1;
      #(SYSTCLK/2);
      sys_clk_i = 0;
      #(SYSTCLK/2);
  end

  int errors;

// Data check;
  assign tran_size32 = (tran_size%4==0)? tran_size/4 : tran_size/4+1;
  always @(posedge sys_clk_i or negedge rst_ni)
    begin
      if(!rst_ni)
        begin
          rx_data_count <= 0;
          errors <= 0;
        end
      else
        begin
          if(rx_valid_udma_o)
            begin
              if(rx_data_udma_o != (32'hffff0000+rx_data_count))
                begin
                  errors <= errors + 1;
                  $display("@ %g Error at %d th data=%h",$time, rx_data_count, rx_data_udma_o);
                end
              if(rx_data_count == tran_size32 -1) rx_data_count <=0;
              else rx_data_count <= rx_data_count +1;
            end
        end
    end


  program test_hyper_cfg;

     class SetConfig;
        int cfg_address;
        int cfg_data;
        int cfg_valid = 0;
        int cfg_rwn = 1;

     function new (int cfg_address, int cfg_data);
        this.cfg_address = cfg_address;
        this.cfg_data = cfg_data;
     endfunction

     task write;
        this.cfg_valid = 1;
        this.cfg_rwn = 0;
     endtask : write

     endclass: SetConfig



    // SystemVerilog "clocking block"
    // Clocking outputs are DUT inputs and vice versa
    default clocking cb_udma_hyper @(posedge sys_clk_i);
      default input #1step output #1ns;
      output negedge rst_ni;

       
      output cfg_data_i, cfg_addr_i, cfg_valid_i, cfg_rwn_i,  cfg_rx_pending_i, cfg_rx_curr_addr_i,cfg_tx_en_i, cfg_tx_pending_i, cfg_tx_curr_addr_i, cfg_rx_bytes_left_i;
      output tx_data_udma_i, tx_valid_udma_i;
      input cfg_data_o, cfg_ready_o, cfg_rx_startaddr_o, cfg_rx_size_o, cfg_rx_datasize_o, cfg_rx_continuous_o, cfg_rx_en_o, cfg_rx_clr_o;
      input cfg_tx_startaddr_o, cfg_tx_size_o, cfg_tx_continuous_o, cfg_tx_en_o, cfg_tx_clr_o;

    endclocking

    clocking cb_hyper_phy @(posedge phy_clk_i);
      default input #1step output #1ns;
      output negedge phy_rst_ni;

    endclocking



    SetConfig sconfig;

    // Apply the test stimulus
    initial begin
        // $sdf_annotate("/home/lvalente/Documents/vip/hyperram_model/s27ks0641.sdf", hyperram_model);
        $readmemh("./test_mem.dat",data_mem); 

        // Set all inputs at the beginning    

        // Will be applied on negedge of clock!
        cb_udma_hyper.cfg_addr_i <=0;
        cb_udma_hyper.cfg_valid_i <= '0;
        cb_udma_hyper.cfg_data_i <= 0;
        cb_udma_hyper.rst_ni <= 0;
        cb_hyper_phy.phy_rst_ni <= 0;

        // Will be applied 4ns after the clock!
        ##2 cb_udma_hyper.rst_ni <= 1;
        cb_hyper_phy.phy_rst_ni <= 1;
        cb_udma_hyper.cfg_rwn_i<=0;
        cb_udma_hyper.cfg_valid_i<=0;
        cfg_rx_bytes_left_i <= 0;
        cfg_rx_pending_i<=0;
        cfg_rx_curr_addr_i<=0;
        cfg_tx_pending_i<=0;
        cfg_tx_en_i<=0;
        cfg_tx_curr_addr_i<=0;

        #150us; //Wait for RAM to initalize

        // stimuli.address_space = 1;
        //RegTransaction();
        tran_size <= 'h200;
        LongWriteTransactionTest('h1, 0,'h200,0); // Burst length = multiple of 16bits
        #200ns;
        if (errors == 0) begin
          $info("[TEST PASS]");
        end else begin
          $error("[TEST FAIL]");
        end
    end


    task WriteConfig(SetConfig sconfigi, int id);
        if (id == 8) begin
          cb_udma_hyper.cfg_addr_i <= sconfig.cfg_address | (1'b1 << 5);
        end else begin
          cb_udma_hyper.cfg_addr_i <= sconfig.cfg_address;
        end
        cb_udma_hyper.cfg_data_i <= sconfig.cfg_data;
        cb_udma_hyper.cfg_valid_i[id] <= 1;
        cb_udma_hyper.cfg_rwn_i <= 0;
        #SYSTCLK;
        cb_udma_hyper.cfg_valid_i[id] <= 0;
        #SYSTCLK;
     endtask : WriteConfig


    task LongWriteTransactionTest(int mem_address, int l2_address, int length, int id);
        automatic int count2=0;
        automatic int burst_size_32=0;
        if((length%4)==0) burst_size_32 = length/4;
        else burst_size_32 = length/4 +1;

        sconfig = new(`REG_T_RWDS_DELAY_LINE,32'h00000004);
        WriteConfig(sconfig,8);
        sconfig = new(`REG_EN_LATENCY_ADD,32'h00000001);
        WriteConfig(sconfig,8);
        sconfig = new(`REG_PAGE_BOUND, 32'h00000000);
        WriteConfig(sconfig,8);
        sconfig = new(`TWD_ACT_L2, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_COUNT_L2, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_STRIDE_L2,32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_ACT_EXT, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_COUNT_EXT, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_STRIDE_EXT,32'h000000);
        WriteConfig(sconfig,id);

        sconfig = new(`REG_T_CS_MAX, 32'hffffffff); // un_limit burst length
        WriteConfig(sconfig,8);
        sconfig = new(`REG_TX_SADDR, l2_address); // TX Start address
        WriteConfig(sconfig,id);
        sconfig = new(`REG_TX_SIZE, length); // TX size in byte
        WriteConfig(sconfig,id);
        sconfig = new(`REG_HYPER_ADDR, mem_address); // Mem address
        WriteConfig(sconfig,id);
        sconfig = new(`HYPER_CA_SETUP, 32'h000001); // Write is declared.
        WriteConfig(sconfig,id);
        sconfig = new(`REG_UDMA_TXCFG, 32'h0000014); // Write transaction is kicked 
        WriteConfig(sconfig,id);

        #(SYSTCLK*burst_size_32);
        #(SYSTCLK*burst_size_32);

        sconfig = new(`REG_PAGE_BOUND, 32'h00000004);
        WriteConfig(sconfig,8);
        sconfig = new(`REG_UDMA_TXCFG, 32'h0000000); // Write transaction ends
        WriteConfig(sconfig,id);
        ReadTransaction(mem_address,l2_address,length, id);
        cb_udma_hyper.cfg_rx_bytes_left_i <= length;
        wait(rx_valid_udma_o);
        count2 = 0;
       #(SYSTCLK*burst_size_32*2);

    endtask : LongWriteTransactionTest

    task ReadTransaction(int mem_address, int l2_address, int length, int id);
        sconfig = new(`TWD_ACT_L2, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_COUNT_L2, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_STRIDE_L2,32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_ACT_EXT, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_COUNT_EXT, 32'h000000);
        WriteConfig(sconfig,id);
        sconfig = new(`TWD_STRIDE_EXT,32'h000000);
        WriteConfig(sconfig,id);

        sconfig = new(`REG_RX_SADDR, l2_address); // RX Start address
        WriteConfig(sconfig,id);
        sconfig = new(`REG_RX_SIZE, length); // TX size in byte
        WriteConfig(sconfig,id);
        sconfig = new(`REG_HYPER_ADDR, mem_address); // Mem address
        WriteConfig(sconfig,id);
        sconfig = new(`HYPER_CA_SETUP, 32'h000005); // Read is declared
        WriteConfig(sconfig,id);

        sconfig = new(`REG_UDMA_RXCFG, 32'h000014); // Read transaction is kicked
        WriteConfig(sconfig,id);

    endtask : ReadTransaction

    task RegTransaction();
 
        sconfig = new(`REG_PAGE_BOUND, 32'h00000004);
        WriteConfig(sconfig,8);
        sconfig = new(`REG_HYPER_ADDR, 32'h000000); // ID0 reg
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000006); // Reg read is declared
        WriteConfig(sconfig,8);
        sconfig = new(`REG_RX_SIZE, 2); // Read size in byte
        WriteConfig(sconfig,8);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000014); // Read transaction is kicked
        WriteConfig(sconfig,8);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 2;
        wait(rx_valid_udma_o);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 0;
        #(SYSTCLK*10);
        sconfig = new(`HYPER_CA_SETUP, 32'h000000); // configration is cleared
        WriteConfig(sconfig,8);
  
    
        sconfig = new(`REG_HYPER_ADDR, 32'h000001); // ID1 reg
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000006); // Reg read
        WriteConfig(sconfig,8);
        sconfig = new(`REG_RX_SIZE, 2); // Read size in byte
        WriteConfig(sconfig,8);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000014); // Read transaction is kicked
        WriteConfig(sconfig,8);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 2;
        wait(rx_valid_udma_o);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 0;
        #(SYSTCLK*5);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000000); // Read transaction is finished
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000000); // configration is cleared
        WriteConfig(sconfig,8);



        sconfig = new(`REG_HYPER_ADDR, 32'h000801); // Config1 reg
        WriteConfig(sconfig,0);
        sconfig = new(`HYPER_CA_SETUP, 32'h000006); // Reg read
        WriteConfig(sconfig,0);
        sconfig = new(`REG_RX_SIZE, 2); // Read size in byte
        WriteConfig(sconfig,0);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000014); // Read transaction is kicked
        WriteConfig(sconfig,0);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 2;
        wait(rx_valid_udma_o);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 0;
        #(SYSTCLK*5);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000000); // Read transaction is finished
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000000); // configration is cleared
        WriteConfig(sconfig,8);


        sconfig = new(`REG_HYPER_ADDR, 32'h000800); // Config0 reg
        WriteConfig(sconfig,8);
        sconfig = new(`REG_HYPER_CFG, 16'b1011111100010100); // Write data setup
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000002); // Reg Write is declared
        WriteConfig(sconfig,8);
        sconfig = new(`REG_UDMA_TXCFG, 32'h0000014); // Write transaction is kicked 
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000000); // Reg Write finished
        WriteConfig(sconfig,8);
        #(SYSTCLK*5);

        sconfig = new(`REG_HYPER_ADDR, 32'h000800); // Config0 reg
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000006); // Reg read
        WriteConfig(sconfig,8);
        sconfig = new(`REG_RX_SIZE, 2); // Read size in byte
        WriteConfig(sconfig,8);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000014); // Read transaction is kicked
        WriteConfig(sconfig,8);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 2;
        wait(rx_valid_udma_o);
        cb_udma_hyper.cfg_rx_bytes_left_i <= 0;
        #(SYSTCLK*5);
        sconfig = new(`REG_UDMA_RXCFG, 32'h000000); // Read transaction is finished
        WriteConfig(sconfig,8);
        sconfig = new(`HYPER_CA_SETUP, 32'h000000); // configration is cleared
        WriteConfig(sconfig,8);
        #(SYSTCLK*2000);
    endtask: RegTransaction

  endprogram

endmodule
