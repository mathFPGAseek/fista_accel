

/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : example_top.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR4_SDRAM
// Purpose          :
//                    Top-level  module. This module serves both as an example,
//                    and allows the user to synthesize a self-contained
//                    design, which they can be used to test their hardware.
//                    In addition to the memory controller,
//                    the module instantiates:
//                      1. Synthesizable testbench - used to model
//                      user's backend logic and generate different
//                      traffic patterns
//
// Reference        :
// Revision History :
//*****************************************************************************
//LIBRARY xil_defaultlib;

`ifdef MODEL_TECH
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif INCA
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif VCS
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif XILINX_SIMULATOR
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif _VCP
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`endif
`ifdef MODEL_TECH
    `define SIMULATION_MODE
`elsif INCA
    `define SIMULATION_MODE
`elsif VCS
    `define SIMULATION_MODE
`elsif XILINX_SIMULATOR
    `define SIMULATION_MODE
`elsif _VCP
    `define SIMULATION_MODE
`endif


`timescale 1ps/1ps
module example_top #
  (
    parameter nCK_PER_CLK           = 4,   // This parameter is controllerwise
    parameter         APP_DATA_WIDTH          = 512, // This parameter is controllerwise
    parameter         APP_MASK_WIDTH          = 64,  // This parameter is controllerwise
  `ifdef SIMULATION_MODE
    parameter SIMULATION            = "TRUE" 
  `else
    parameter SIMULATION            = "FALSE"
  `endif

  )
   (
    input                 sys_rst, //Common port for all controllers

    output                  c0_init_calib_complete,
    output                  c0_data_compare_error,
    input                   c0_sys_clk_p,
    input                   c0_sys_clk_n,
    output                  c0_ddr4_act_n,
    output [16:0]            c0_ddr4_adr,
    output [1:0]            c0_ddr4_ba,
    output [1:0]            c0_ddr4_bg,
    output [0:0]            c0_ddr4_cke,
    output [0:0]            c0_ddr4_odt,
    output [0:0]            c0_ddr4_cs_n,
    output [0:0]                 c0_ddr4_ck_t,
    output [0:0]                c0_ddr4_ck_c,
    output                  c0_ddr4_reset_n,
    inout  [7:0]            c0_ddr4_dm_dbi_n,
    inout  [63:0]            c0_ddr4_dq,
    inout  [7:0]            c0_ddr4_dqs_t,
    inout  [7:0]            c0_ddr4_dqs_c,
                
    //**** Signals for FISTA Acceleration*******
    input  [4:0]           dbg_master_mode_i,                      
    input                  dbg_rdy_fr_init_and_inbound_i,          
    input                  dbg_wait_fr_init_and_inbound_i,         
    input                  dbg_fft_flow_tlast_i,                   
    output                 dbg_mem_init_start_o,                   
    output [1:0]           dbg_ddr_intf_mux_wr_sel_o,              
    output [2:0]           dbg_ddr_intf_demux_rd_sel_o,            
    output                 dbg_mem_shared_in_enb_o,                
    output [7:0]           dbg_mem_shared_in_addb_o,                            
    output                 dbg_front_end_demux_fr_fista_o,         
    output [1:0]           dbg_front_end_mux_to_fft_o,             
    output                 dbg_back_end_demux_fr_fh_mem_o,         
    output                 dbg_back_end_demux_fr_fv_mem_o,         
    output                 dbg_back_end_mux_to_front_end_o,                                
    output                 dbg_f_h_fifo_wr_en_o,                   
    output                 dbg_f_h_fifo_rd_en_o,                   
    input                  dbg_f_h_fifo_full_i,                    
    input                  dbg_f_h_fifo_empty_i,                   
    output                 dbg_f_v_fifo_wr_en_o,                   
    output                 dbg_f_v_fifo_rd_en_o,                   
    input                  dbg_f_v_fifo_full_i,                    
    input                  dbg_f_v_fifo_empty_i,                                              
    output                 dbg_fdbk_fifo_wr_en_o,                  
    output                 dbg_fdbk_fifo_rd_en_o,                  
    input                  dbg_fdbk_fifo_full_i,                   
    input                  dbg_fdbk_fifo_empty_i,                                   
    output                 fista_accel_valid_rd_o                 
    );


  localparam  APP_ADDR_WIDTH = 29;
  localparam  MEM_ADDR_ORDER = "ROW_COLUMN_BANK";
  localparam DBG_WR_STS_WIDTH      = 32;
  localparam DBG_RD_STS_WIDTH      = 32;
  localparam ECC                   = "OFF";

wire prbs_mode_done;
`ifdef VIO_ATG_EN

         wire  vio_tg_rst;                      
         wire  vio_tg_start;                     
         wire  vio_tg_err_chk_en;                
         wire  vio_tg_err_clear;                 
         wire [3:0]   vio_tg_instr_addr_mode;           
         wire [3:0]   vio_tg_instr_data_mode;          
         wire [3:0]   vio_tg_instr_rw_mode;             
         wire [1:0]  vio_tg_instr_rw_submode;          
         wire [31:0] vio_tg_instr_num_of_iter;         
         wire [5:0] vio_tg_instr_nxt_instr;           
         wire  vio_tg_restart;                    
         wire  vio_tg_pause;                     
         wire  vio_tg_err_clear_all;             
         wire  vio_tg_err_continue;              
         wire  vio_tg_instr_program_en;          
         wire  vio_tg_direct_instr_en;           
         wire [4:0]  vio_tg_instr_num;                 
         wire [2:0] vio_tg_instr_victim_mode;         
         wire [4:0] vio_tg_instr_victim_aggr_delay;   
         wire [2:0] vio_tg_instr_victim_select;       
         wire [9:0] vio_tg_instr_m_nops_btw_n_burst_m;
         wire [31:0] vio_tg_instr_m_nops_btw_n_burst_n;
         wire  vio_tg_seed_program_en;           
         wire [7:0] vio_tg_seed_num;                  
         wire [22:0] vio_tg_seed_data;                      
         wire [7:0] vio_tg_glb_victim_bit;            
         wire [49:0] vio_tg_glb_start_addr;
         wire [APP_DATA_WIDTH-1:0] acc_bit_err;
         wire [7:0]   acc_dq_err;
         reg [31:0]   tg_rd_valid_cnt = 0;
         reg [31:0]   tg_inst_cnt = 0;
         localparam APP_DATA_WIDTH_BYTES = 8; 
         reg [63:0] app_wdf_data_byte;
         reg [63:0] app_rd_data_byte;     
         reg app_wdf_data_byte_wren;
         reg app_rd_data_byte_rden;      
         reg app_wdf_data_byte_end;
         reg app_rdy;               
         reg app_wdf_rdy;           
         reg [2:0] app_cmd;               
         reg [49:0] app_addr;
         reg app_en;                
         reg [79:0] app_wdf_mask; 
         reg app_rd_data_end;
         reg [3:0]    vio_rbyte_sel;
         reg             tg_rd_data_valid_x1;
         reg [63:0]   acc_bit_err_x1, tg_rd_data_x1, tg_exp_data_x1;
         reg [49:0]   tg_rd_err_addr_x1;
         reg [9:0]    acc_byte_err_x2;
         reg [7:0]    acc_dq_err_x2;
         reg    first_err_bit_valid_x1; 
         reg [63:0]   first_err_bit_x1;       
         reg    err_type_valid_x1;      
         reg    err_type_x1;            
         reg    acc_bit_err_valid_x1;   
         reg    tg_exp_data_valid_x1;   
         reg [31:0] tg_cmp_err_x1_cnt;

        
`endif
      




  wire [APP_ADDR_WIDTH-1:0]            c0_ddr4_app_addr;
  wire [2:0]            c0_ddr4_app_cmd;
  wire                  c0_ddr4_app_en;
  wire [APP_DATA_WIDTH-1:0]            c0_ddr4_app_wdf_data;
  wire                  c0_ddr4_app_wdf_end;
  wire [APP_MASK_WIDTH-1:0]            c0_ddr4_app_wdf_mask;
  wire                  c0_ddr4_app_wdf_wren;
  wire [APP_DATA_WIDTH-1:0]            c0_ddr4_app_rd_data;
  wire                  c0_ddr4_app_rd_data_end;
  wire                  c0_ddr4_app_rd_data_valid;
  wire                  c0_ddr4_app_rdy;
  wire                  c0_ddr4_app_wdf_rdy;
  wire                  c0_ddr4_clk;
  wire                  c0_ddr4_rst;
  wire                  dbg_clk;
  wire                  c0_wr_rd_complete;
  wire                       traffic_start;
  wire                       traffic_rst;
  wire                       traffic_err_chk_en;
  wire [3:0]                 traffic_instr_addr_mode;
  wire [3:0]                 traffic_instr_data_mode;
  wire [3:0]                 traffic_instr_rw_mode;
  wire [1:0]                 traffic_instr_rw_submode;
  wire [31:0]                traffic_instr_num_of_iter;
  wire [5:0]                 traffic_instr_nxt_instr;
  wire [APP_DATA_WIDTH-1:0]  traffic_error_tg;
  wire [APP_DATA_WIDTH-1:0]  traffic_error;
  reg                        tg_reset_x1;

`ifdef MARGIN_CHECK
  wire                       traffic_clr_error;
  wire [31:0]                win_status;
  wire                       win_error ;
  wire                       win_active;
  wire                       win_done  ;
  wire [5:0]                 win_nibble;

  wire                       vio_win_type;
  wire                       vio_win_start;
   
  reg                        vio_win_type_x0 = 0;
  reg [2:0]                  vio_win_start_x = 0;
  reg [3:0]                  win_start = 0;
  reg                        win_done_x1 = 0;
  reg                        win_start_pulse = 0;

  reg [9:0]                  tg_reset_cnt;
  reg                        tg_reset_x0;
  reg                        win_done_pulse;

  assign win_error  = win_status[19];
  assign win_active = win_status[17];
  assign win_done   = win_status[16];
  assign win_nibble = win_status[13:8];

  always @(posedge c0_ddr4_clk) begin
     if (c0_ddr4_rst) begin
        vio_win_type_x0 <= 1'b0;
        vio_win_start_x <= 3'b0;
        win_done_x1     <= 1'b0;
        win_start_pulse <= 1'b0;
     end else begin
        vio_win_type_x0 <= vio_win_type;
        vio_win_start_x <= {vio_win_start_x, vio_win_start};
        win_done_x1     <= win_done;
        win_start_pulse <= !vio_win_start_x[1] && vio_win_start_x[2];
     end
  end
  
  always @(posedge c0_ddr4_clk) begin
     if (c0_ddr4_rst) begin
        win_start       <= 4'b0;
     end else begin
        if (win_start_pulse)
          win_start <= vio_win_type_x0 ? 4'b0010 : 4'b0001;
        else if (win_active)
          win_start <= 4'b0;
     end
  end

  always @(posedge c0_ddr4_clk) begin
     if (c0_ddr4_rst) begin
        tg_reset_cnt    <= 10'b0;
        tg_reset_x0     <= 1'b0;
        tg_reset_x1     <= 1'b0;
        win_done_pulse  <= 1'b0;
     end else begin
       tg_reset_x0     <= (tg_reset_cnt != 0);
       tg_reset_x1     <= tg_reset_x0;
       win_done_pulse  <= win_done && !win_done_x1;
       if ((win_start != 0) || traffic_clr_error) begin
  	     tg_reset_cnt <= 100;
       end else if (win_done_pulse) begin
  	     tg_reset_cnt <= 200;
       end else if (tg_reset_cnt != 0) begin
  	     tg_reset_cnt <= tg_reset_cnt - 1;
       end 
     end
  end
`else
  assign tg_reset_x1 = 1'b0;
`endif

   // debug ports
  wire [63:0]           dbg_rd_data_cmp;
  wire [63:0]           dbg_expected_data;
  wire [2:0]            dbg_cal_seq;
  wire [31:0]           dbg_cal_seq_cnt;
  wire [7:0]            dbg_cal_seq_rd_cnt;
  wire                  dbg_rd_valid;
  wire [5:0]            dbg_cmp_byte;
  wire [63:0]           dbg_rd_data;
  wire [15:0]           dbg_cplx_config;
  wire [1:0]            dbg_cplx_status;
  wire [27:0]           dbg_io_address;
  wire                  dbg_pllGate;
  wire [19:0]           dbg_phy2clb_fixdly_rdy_low;
  wire [19:0]           dbg_phy2clb_fixdly_rdy_upp;
  wire [19:0]           dbg_phy2clb_phy_rdy_low;
  wire [19:0]           dbg_phy2clb_phy_rdy_upp;
  wire [127:0]          cal_r0_status;
  wire [8:0]            cal_post_status;


  //HW TG VIO signals
  wire [3:0]                           vio_tg_status_state;
  wire                                 vio_tg_status_err_bit_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_err_bit;
  wire [31:0]                          vio_tg_status_err_cnt;
  wire [APP_ADDR_WIDTH-1:0]            vio_tg_status_err_addr;
  wire                                 vio_tg_status_exp_bit_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_exp_bit;
  wire                                 vio_tg_status_read_bit_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_read_bit;
  wire                                 vio_tg_status_first_err_bit_valid;

  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_first_err_bit;
  wire [APP_ADDR_WIDTH-1:0]            vio_tg_status_first_err_addr;
  wire                                 vio_tg_status_first_exp_bit_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_first_exp_bit;
  wire                                 vio_tg_status_first_read_bit_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_first_read_bit;
  wire                                 vio_tg_status_err_bit_sticky_valid;
  wire [APP_DATA_WIDTH-1:0]            vio_tg_status_err_bit_sticky;
  wire [31:0]                          vio_tg_status_err_cnt_sticky;
  wire                                 vio_tg_status_err_type_valid;
  wire                                 vio_tg_status_err_type;
  wire                                 vio_tg_status_wr_done;
  wire                                 vio_tg_status_done;
  wire                                 vio_tg_status_watch_dog_hang;
  wire                                 tg_ila_debug;

  // Debug Bus
  wire [511:0]                         dbg_bus;        




// debug port wire declarations
`ifdef SIMULATION
`else
 (*mark_debug  = "TRUE" *) wire dbg_init_calib_complete;
 (*mark_debug  = "TRUE" *) wire dbg_data_compare_error;
`endif
// end of  debug port wire declarations

wire c0_ddr4_reset_n_int;
  assign c0_ddr4_reset_n = c0_ddr4_reset_n_int;

//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************

  // user design top is one instance for all controllers
ddr4_0 u_ddr4_0
  (
   .sys_rst           (sys_rst),

   .c0_sys_clk_p                   (c0_sys_clk_p),
   .c0_sys_clk_n                   (c0_sys_clk_n),
   .c0_init_calib_complete (c0_init_calib_complete),
   .c0_ddr4_act_n          (c0_ddr4_act_n),
   .c0_ddr4_adr            (c0_ddr4_adr),
   .c0_ddr4_ba             (c0_ddr4_ba),
   .c0_ddr4_bg             (c0_ddr4_bg),
   .c0_ddr4_cke            (c0_ddr4_cke),
   .c0_ddr4_odt            (c0_ddr4_odt),
   .c0_ddr4_cs_n           (c0_ddr4_cs_n),
   .c0_ddr4_ck_t           (c0_ddr4_ck_t),
   .c0_ddr4_ck_c           (c0_ddr4_ck_c),
   .c0_ddr4_reset_n        (c0_ddr4_reset_n_int),
   .traffic_wr_done               (vio_tg_status_wr_done),
   .traffic_status_err_bit_valid  (vio_tg_status_err_bit_valid),
   .traffic_status_err_type_valid (vio_tg_status_err_type_valid),
   .traffic_status_err_type       (vio_tg_status_err_type),
   .traffic_status_done           (vio_tg_status_done),
   .traffic_status_watch_dog_hang (vio_tg_status_watch_dog_hang),
   .traffic_error                 (vio_tg_status_err_bit_sticky),



`ifdef MARGIN_CHECK
   .win_start                     (win_start),
   .traffic_clr_error             (traffic_clr_error),
   .win_status                    (win_status),
`else   
   .win_start                     (4'b0),
   .traffic_clr_error             (),
   .win_status                    (),
`endif


`ifdef VIO_ATG_EN

   .traffic_start                 (),
   .traffic_rst                   (),
   .traffic_err_chk_en            (),
   .traffic_instr_addr_mode       (),
   .traffic_instr_data_mode       (),
   .traffic_instr_rw_mode         (),
   .traffic_instr_rw_submode      (),
   .traffic_instr_num_of_iter     (),
   .traffic_instr_nxt_instr       (),

`else
   .traffic_start                 (traffic_start),
   .traffic_rst                   (traffic_rst),
   .traffic_err_chk_en            (traffic_err_chk_en),
   .traffic_instr_addr_mode       (traffic_instr_addr_mode),
   .traffic_instr_data_mode       (traffic_instr_data_mode),
   .traffic_instr_rw_mode         (traffic_instr_rw_mode),
   .traffic_instr_rw_submode      (traffic_instr_rw_submode),
   .traffic_instr_num_of_iter     (traffic_instr_num_of_iter),
   .traffic_instr_nxt_instr       (traffic_instr_nxt_instr),

`endif  





    

   .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
   .c0_ddr4_dq             (c0_ddr4_dq),
   .c0_ddr4_dqs_c          (c0_ddr4_dqs_c),
   .c0_ddr4_dqs_t          (c0_ddr4_dqs_t),

   .c0_ddr4_ui_clk                (c0_ddr4_clk),
   .c0_ddr4_ui_clk_sync_rst       (c0_ddr4_rst),
   .addn_ui_clkout1                            (),
   .dbg_clk                                    (dbg_clk),
   .dbg_rd_data_cmp                            (dbg_rd_data_cmp),
   .dbg_expected_data                          (dbg_expected_data),
   .dbg_cal_seq                                (dbg_cal_seq               ),
   .dbg_cal_seq_cnt                            (dbg_cal_seq_cnt           ),
   .dbg_cal_seq_rd_cnt                         (dbg_cal_seq_rd_cnt        ),
   .dbg_rd_valid                               (dbg_rd_valid              ),
   .dbg_cmp_byte                               (dbg_cmp_byte              ),
   .dbg_rd_data                                (dbg_rd_data               ),
   .dbg_cplx_config                            (dbg_cplx_config           ),
   .dbg_cplx_status                            (dbg_cplx_status           ),
   .dbg_io_address                             (dbg_io_address            ),
   .dbg_pllGate                                (dbg_pllGate               ),
   .dbg_phy2clb_fixdly_rdy_low                 (dbg_phy2clb_fixdly_rdy_low),
   .dbg_phy2clb_fixdly_rdy_upp                 (dbg_phy2clb_fixdly_rdy_upp),
   .dbg_phy2clb_phy_rdy_low                    (dbg_phy2clb_phy_rdy_low   ),
   .dbg_phy2clb_phy_rdy_upp                    (dbg_phy2clb_phy_rdy_upp   ),
   .cal_r0_status                              (cal_r0_status),
   .cal_post_status                            (cal_post_status),

   .c0_ddr4_app_addr              (c0_ddr4_app_addr),
   .c0_ddr4_app_cmd               (c0_ddr4_app_cmd),
   .c0_ddr4_app_en                (c0_ddr4_app_en),
   .c0_ddr4_app_hi_pri            (1'b0),
   .c0_ddr4_app_wdf_data          (c0_ddr4_app_wdf_data),
   .c0_ddr4_app_wdf_end           (c0_ddr4_app_wdf_end),
   .c0_ddr4_app_wdf_mask          (c0_ddr4_app_wdf_mask),
   .c0_ddr4_app_wdf_wren          (c0_ddr4_app_wdf_wren),
   .c0_ddr4_app_rd_data           (c0_ddr4_app_rd_data),
   .c0_ddr4_app_rd_data_end       (c0_ddr4_app_rd_data_end),
   .c0_ddr4_app_rd_data_valid     (c0_ddr4_app_rd_data_valid),
   .c0_ddr4_app_rdy               (c0_ddr4_app_rdy),
   .c0_ddr4_app_wdf_rdy           (c0_ddr4_app_wdf_rdy),
  
  // Debug Port
  .dbg_bus         (dbg_bus)                                             

  );

//***************************************************************************
// The example testbench module instantiated below drives traffic (patterns)
// on the application interface of the memory controller
//***************************************************************************
// In DDR4, there are two test generators (TG) available for user to select:
//  1) Simple Test Generator (STG)
//  2) Advanced Test Generator (ATG)
// 
//`define HW_TG_EN

  `ifndef HW_TG_EN
    example_tb #
      (
       .SIMULATION     (SIMULATION),
       .APP_DATA_WIDTH (APP_DATA_WIDTH),
       .APP_ADDR_WIDTH (APP_ADDR_WIDTH),
       .MEM_ADDR_ORDER (MEM_ADDR_ORDER)
       )
      u_example_tb
        (
         .clk                                     (c0_ddr4_clk),
         .rst                                     (c0_ddr4_rst),
         .app_rdy                                 (c0_ddr4_app_rdy),
         .init_calib_complete                     (c0_init_calib_complete),
         .app_rd_data_valid                       (c0_ddr4_app_rd_data_valid),
         .app_rd_data                             (c0_ddr4_app_rd_data),
         .app_wdf_rdy                             (c0_ddr4_app_wdf_rdy),
         .app_en                                  (c0_ddr4_app_en),
         .app_cmd                                 (c0_ddr4_app_cmd),
         .app_addr                                (c0_ddr4_app_addr),
         .app_wdf_wren                            (c0_ddr4_app_wdf_wren),
         .app_wdf_end                             (c0_ddr4_app_wdf_end),
         .app_wdf_mask                            (c0_ddr4_app_wdf_mask),
         .app_wdf_data                            (c0_ddr4_app_wdf_data),
         .compare_error                           (c0_data_compare_error),
         .wr_rd_complete                          (c0_wr_rd_complete),
        
          //**** Signals for FISTA Acceleration*******
         .dbg_master_mode_i                       (dbg_master_mode_i),
         .dbg_rdy_fr_init_and_inbound_i           (dbg_rdy_fr_init_and_inbound_i),
         .dbg_wait_fr_init_and_inbound_i          (dbg_wait_fr_init_and_inbound_i),
         .dbg_fft_flow_tlast_i                    (dbg_fft_flow_tlast_i),           
         .dbg_mem_init_start_o                    (dbg_mem_init_start_o),     
         .dbg_ddr_intf_mux_wr_sel_o               (dbg_ddr_intf_mux_wr_sel_o),
         .dbg_ddr_intf_demux_rd_sel_o             (dbg_ddr_intf_demux_rd_sel_o),
         .dbg_mem_shared_in_enb_o                 (dbg_mem_shared_in_enb_o), 
         .dbg_mem_shared_in_addb_o                (dbg_mem_shared_in_addb_o),                      
         .dbg_front_end_demux_fr_fista_o          (dbg_front_end_demux_fr_fista_o), 
         .dbg_front_end_mux_to_fft_o              (dbg_front_end_mux_to_fft_o),  
         .dbg_back_end_demux_fr_fh_mem_o          (dbg_back_end_demux_fr_fh_mem_o),  
         .dbg_back_end_demux_fr_fv_mem_o          (dbg_back_end_demux_fr_fv_mem_o),  
         .dbg_back_end_mux_to_front_end_o         (dbg_back_end_mux_to_front_end_o),                          
         .dbg_f_h_fifo_wr_en_o                    (dbg_f_h_fifo_wr_en_o),  
         .dbg_f_h_fifo_rd_en_o                    (dbg_f_h_fifo_rd_en_o),  
         .dbg_f_h_fifo_full_i                     (dbg_f_h_fifo_full_i),   
         .dbg_f_h_fifo_empty_i                    (dbg_f_h_fifo_empty_i),             
         .dbg_f_v_fifo_wr_en_o                    (dbg_f_v_fifo_wr_en_o),  
         .dbg_f_v_fifo_rd_en_o                    (dbg_f_v_fifo_rd_en_o),  
         .dbg_f_v_fifo_full_i                     (dbg_f_v_fifo_full_i), 
         .dbg_f_v_fifo_empty_i                    (dbg_f_v_fifo_empty_i),                                        
         .dbg_fdbk_fifo_wr_en_o                   (dbg_fdbk_fifo_wr_en_o),  
         .dbg_fdbk_fifo_rd_en_o                   (dbg_fdbk_fifo_rd_en_o), 
         .dbg_fdbk_fifo_full_i                    (dbg_fdbk_fifo_full_i), 
         .dbg_fdbk_fifo_empty_i                   (dbg_fdbk_fifo_empty_i),                 
                     
         .fista_accel_valid_rd_o                  (fista_accel_valid_rd_o) 
                                     
      );
   `else
    ddr4_v2_2_17_hw_tg #
      (
       .SIMULATION      (SIMULATION),
       .MEM_TYPE        ("DDR4"),
       .APP_DATA_WIDTH  (APP_DATA_WIDTH),
       .APP_ADDR_WIDTH  (APP_ADDR_WIDTH),
       .NUM_DQ_PINS     (64),
       .ECC             (ECC),
       .DEFAULT_MODE    ("2015_3")
       )
      u_hw_tg
        (
         .clk                  (c0_ddr4_clk),
         .rst                  (c0_ddr4_rst),
         .init_calib_complete  (c0_init_calib_complete),
         .app_rdy              (c0_ddr4_app_rdy),
         .app_wdf_rdy          (c0_ddr4_app_wdf_rdy),
         .app_rd_data_valid    (c0_ddr4_app_rd_data_valid),
         .app_rd_data          (c0_ddr4_app_rd_data),
         .app_cmd              (c0_ddr4_app_cmd),
         .app_addr             (c0_ddr4_app_addr),
         .app_en               (c0_ddr4_app_en),
         .app_wdf_mask         (c0_ddr4_app_wdf_mask),
         .app_wdf_data         (c0_ddr4_app_wdf_data),
         .app_wdf_end          (c0_ddr4_app_wdf_end),
         .app_wdf_wren         (c0_ddr4_app_wdf_wren),
         .app_wdf_en           (), // valid for QDRII+ only
         .app_wdf_addr         (), // valid for QDRII+ only
         .app_wdf_cmd          (), // valid for QDRII+ only
         .compare_error        (c0_data_compare_error),

  `ifdef VIO_ATG_EN

         .vio_tg_rst                           (vio_tg_rst),
      `ifdef SIMULATION_MODE 
         .vio_tg_start                         (1'b1),
      `else
         .vio_tg_start                         (vio_tg_start),
      `endif   
         .vio_tg_err_chk_en                    (vio_tg_err_chk_en),
         .vio_tg_err_clear                     (vio_tg_err_clear),
         .vio_tg_instr_addr_mode               (vio_tg_instr_addr_mode),
         .vio_tg_instr_data_mode               (vio_tg_instr_data_mode),
         .vio_tg_instr_rw_mode                 (vio_tg_instr_rw_mode),
         .vio_tg_instr_rw_submode              (vio_tg_instr_rw_submode),
         .vio_tg_instr_num_of_iter             (vio_tg_instr_num_of_iter),
         .vio_tg_instr_nxt_instr               (vio_tg_instr_nxt_instr),
         .vio_tg_status_first_err_bit          (vio_tg_status_first_err_bit),
         .vio_tg_restart                       (vio_tg_restart),
         .vio_tg_pause                         (vio_tg_pause),
         .vio_tg_err_clear_all                 (vio_tg_err_clear_all),
         .vio_tg_err_continue                  (vio_tg_err_continue),
         .vio_tg_instr_program_en              (vio_tg_instr_program_en),
         .vio_tg_direct_instr_en               (vio_tg_direct_instr_en),
         .vio_tg_instr_num                     (vio_tg_instr_num),
         .vio_tg_instr_victim_mode             (vio_tg_instr_victim_mode),
         .vio_tg_instr_victim_aggr_delay       (vio_tg_instr_victim_aggr_delay),
         .vio_tg_instr_victim_select           (vio_tg_instr_victim_select),
         .vio_tg_instr_m_nops_btw_n_burst_m    (vio_tg_instr_m_nops_btw_n_burst_m),
         .vio_tg_instr_m_nops_btw_n_burst_n    (vio_tg_instr_m_nops_btw_n_burst_n),
         .vio_tg_seed_program_en               (vio_tg_seed_program_en),
         .vio_tg_seed_num                      (vio_tg_seed_num),
         .vio_tg_seed                          (vio_tg_seed_data),
         .vio_tg_glb_victim_bit                (vio_tg_glb_victim_bit),
         .vio_tg_glb_start_addr                (vio_tg_glb_start_addr[APP_ADDR_WIDTH-1:0]),
         .vio_tg_glb_qdriv_rw_submode          (2'b00),

  `else 

         .vio_tg_rst                         (traffic_rst | tg_reset_x1),
         .vio_tg_start                       (traffic_start),
         .vio_tg_err_chk_en                  (traffic_err_chk_en),
         .vio_tg_err_clear                   (1'b0),
         .vio_tg_instr_addr_mode             (traffic_instr_addr_mode),
         .vio_tg_instr_data_mode             (traffic_instr_data_mode),
         .vio_tg_instr_rw_mode               (traffic_instr_rw_mode),
         .vio_tg_instr_rw_submode            (traffic_instr_rw_submode),
         .vio_tg_instr_num_of_iter           (traffic_instr_num_of_iter),
         .vio_tg_instr_nxt_instr             (traffic_instr_nxt_instr),
         .vio_tg_status_first_err_bit        (traffic_error_tg),
         .vio_tg_restart                     (1'b0),
         .vio_tg_pause                       (1'b0),
         .vio_tg_err_clear_all               (1'b0),
         .vio_tg_err_continue                (1'b0),
         .vio_tg_instr_program_en            (1'b0),
         .vio_tg_direct_instr_en             (1'b0),
         .vio_tg_instr_num                   (5'b00000),
         .vio_tg_instr_victim_mode           (3'b000),
         .vio_tg_instr_victim_aggr_delay     (5'b00000),
         .vio_tg_instr_victim_select         (3'b000),
         .vio_tg_instr_m_nops_btw_n_burst_m  (10'd0),
         .vio_tg_instr_m_nops_btw_n_burst_n  (32'd0),
         .vio_tg_seed_program_en             (1'b0),
         .vio_tg_seed_num                    (8'h00),
         .vio_tg_seed                        (23'd0),
         .vio_tg_glb_victim_bit              (8'h00),
         .vio_tg_glb_start_addr              ({APP_ADDR_WIDTH{1'b0}}),
         .vio_tg_glb_qdriv_rw_submode        (2'b00),
 
  `endif

         .vio_tg_status_state                  (vio_tg_status_state),
         .vio_tg_status_err_bit_valid          (vio_tg_status_err_bit_valid),
         .vio_tg_status_err_bit                (vio_tg_status_err_bit),
         .vio_tg_status_err_cnt                (vio_tg_status_err_cnt),
         .vio_tg_status_err_addr               (vio_tg_status_err_addr),
         .vio_tg_status_exp_bit_valid          (vio_tg_status_exp_bit_valid),
         .vio_tg_status_exp_bit                (vio_tg_status_exp_bit),
         .vio_tg_status_read_bit_valid         (vio_tg_status_read_bit_valid),
         .vio_tg_status_read_bit               (vio_tg_status_read_bit),
         .vio_tg_status_first_err_bit_valid    (vio_tg_status_first_err_bit_valid),
         .vio_tg_status_first_err_addr         (vio_tg_status_first_err_addr),
         .vio_tg_status_first_exp_bit_valid    (vio_tg_status_first_exp_bit_valid),
         .vio_tg_status_first_exp_bit          (vio_tg_status_first_exp_bit),
         .vio_tg_status_first_read_bit_valid   (vio_tg_status_first_read_bit_valid),
         .vio_tg_status_first_read_bit         (vio_tg_status_first_read_bit),
         .vio_tg_status_err_bit_sticky_valid   (vio_tg_status_err_bit_sticky_valid),
         .vio_tg_status_err_bit_sticky         (vio_tg_status_err_bit_sticky),
         .vio_tg_status_err_cnt_sticky         (vio_tg_status_err_cnt_sticky),
         .vio_tg_status_err_type_valid         (vio_tg_status_err_type_valid),
         .vio_tg_status_err_type               (vio_tg_status_err_type),
         .vio_tg_status_wr_done                (vio_tg_status_wr_done),
         .vio_tg_status_done                   (vio_tg_status_done),
         .vio_tg_status_watch_dog_hang         (vio_tg_status_watch_dog_hang),
         .tg_ila_debug                         (tg_ila_debug),
         .tg_qdriv_submode11_app_rd            (1'b0)



  );
   assign traffic_error = traffic_error_tg;
  `endif


`ifdef MARGIN_CHECK
  `ifdef SIMULATION
  `else
vio_0 u_vio_margin_check (
  .clk(c0_ddr4_clk),                // input wire clk
  .probe_in0(vio_tg_status_wr_done),    // input wire [0 : 0] probe_in0
  .probe_in1(vio_tg_status_err_bit_valid),    // input wire [0 : 0] probe_in1
  .probe_in2(vio_tg_status_err_type_valid),    // input wire [0 : 0] probe_in2
  .probe_in3(vio_tg_status_err_type),    // input wire [0 : 0] probe_in3
  .probe_in4(vio_tg_status_done),    // input wire [0 : 0] probe_in4
  .probe_in5(vio_tg_status_watch_dog_hang),    // input wire [0 : 0] probe_in5
  .probe_in6(traffic_clr_error),    // input wire [0 : 0] probe_in6
  .probe_in7(traffic_start),    // input wire [0 : 0] probe_in7
  .probe_in8(traffic_rst),    // input wire [0 : 0] probe_in8
  .probe_in9(traffic_err_chk_en),    // input wire [0 : 0] probe_in9
  .probe_in10(traffic_instr_addr_mode),  // input wire [3 : 0] probe_in10
  .probe_in11(traffic_instr_data_mode),  // input wire [3 : 0] probe_in11
  .probe_in12(traffic_instr_rw_mode),  // input wire [3 : 0] probe_in12
  .probe_in13(traffic_instr_rw_submode),  // input wire [1 : 0] probe_in13
  .probe_in14(traffic_instr_num_of_iter),  // input wire [31 : 0] probe_in14
  .probe_in15(traffic_instr_nxt_instr),  // input wire [5 : 0] probe_in15
  .probe_in16(win_error),  // input wire [0 : 0] probe_in16
  .probe_in17(win_active),  // input wire [0 : 0] probe_in17
  .probe_in18(win_done),  // input wire [0 : 0] probe_in18
  .probe_in19(win_nibble),  // input wire [5 : 0] probe_in19
  .probe_out0(vio_win_type),  // output wire [0 : 0] probe_out0
  .probe_out1(vio_win_start)  // output wire [0 : 0] probe_out1
);
  `endif
`endif

`ifdef SIMULATION
`else
 // Debug cores instantiation

   assign dbg_init_calib_complete = c0_init_calib_complete;
   assign dbg_data_compare_error  = c0_data_compare_error;


 ila_ddrx u_ila_ddrx (                              // Refer to PG150 for the usage of the Below probes 

    .clk (c0_ddr4_clk),                           
    .probe0  (dbg_init_calib_complete),             // Signifies the status of calibration
    .probe1  (dbg_data_compare_error),              // Signifies the status of Traffic Error from The TG 
    .probe2  (dbg_expected_data),                   // Displays the expected data during calibration stages that use fabric-based data pattern comparison such as Read per-bit deskew or read DQS centering (complex).
    .probe3  (dbg_rd_data_cmp),                     // Comparison of dbg_rd_data and dbg_expected_data
    .probe4  (dbg_cal_seq),                         // Calibration sequence indicator, when RTL is issuing commands to the DRAM. 
    .probe5  (dbg_cal_seq_cnt),                     // Calibration command sequence count used when RTL is issuing commands to the DRAM.
    .probe6  (dbg_cal_seq_rd_cnt),                  // Calibration read data burst count
    .probe7  (dbg_rd_valid),                        // Read data valid
    .probe8  (dbg_cmp_byte),                        // Calibration byte selection 
    .probe9  (dbg_rd_data),                         // Read data from input FIFOs
    .probe10 (dbg_cplx_config),                     // Complex cal configuration
    .probe11 (dbg_cplx_status),                     // Complex cal status
    .probe12 (dbg_io_address),                      // MicroBlaze I/O address bus 
    .probe13 (dbg_pllGate),                         // PLL lock indicator
    .probe14 (dbg_phy2clb_fixdly_rdy_low),          // Xiphy fixed delay ready signal (lower nibble) 
    .probe15 (dbg_phy2clb_fixdly_rdy_upp),          // Xiphy fixed delay ready signal (upper nibble)
    .probe16 (dbg_phy2clb_phy_rdy_low),             // Xiphy phy ready signal (lower nibble)
    .probe17 (dbg_phy2clb_phy_rdy_upp),             // Xiphy phy ready signal (upper nibble)
    .probe18 (cal_r0_status),                        // Signifies the status of each stage of calibration.
    //.probe18 (win_status),                          // Margin Status 
    .probe19 (cal_post_status)                        // Signifies the status of calibration.                                                                                                                      

    );
`endif

 //End of Debug cores instantiation


`ifdef VIO_ATG_EN

   ATG_VIO u_vio_1 (
        .clk(c0_ddr4_clk),                // input wire clk
        .probe_out0   (vio_tg_rst),                // output wire [0:0]      
        .probe_out1   (vio_tg_start),              // output wire [0:0]       
        .probe_out2   (vio_tg_err_chk_en),         // output wire [0:0]        
        .probe_out3   (vio_tg_err_clear),          // output wire [0:0]        
        .probe_out4   (vio_tg_instr_addr_mode),    // output wire [3:0]       
        .probe_out5   (vio_tg_instr_data_mode),    // output wire [3:0]      
        .probe_out6   (vio_tg_instr_rw_mode),      // output wire [3:0]       
        .probe_out7   (vio_tg_instr_rw_submode),   // output wire [1:0]       
        .probe_out8   (vio_tg_instr_num_of_iter),  // output wire [31:0]      
        .probe_out9   (vio_tg_instr_nxt_instr),    // output wire [5:0]       
        .probe_out10  (vio_tg_restart),           // output wire [0:0]          
        .probe_out11  (vio_tg_pause),             // output wire [0:0]        
        .probe_out12  (vio_tg_err_clear_all),     // output wire [0:0]         
        .probe_out13  (vio_tg_err_continue),      // output wire [0:0]       
        .probe_out14  (vio_tg_instr_program_en),  // output wire [0:0]      
        .probe_out15  (vio_tg_direct_instr_en),    // output wire [0:0]      
        .probe_out16  (vio_tg_instr_num),           // output wire [4:0]     
        .probe_out17  (vio_tg_instr_victim_mode),    // output wire [2:0]    
        .probe_out18  (vio_tg_instr_victim_aggr_delay), // output wire [4:0]    
        .probe_out19  (vio_tg_instr_victim_select),    // output wire [2:0]    
        .probe_out20  (vio_tg_instr_m_nops_btw_n_burst_m),  // output wire [9:0]    
        .probe_out21  (vio_tg_instr_m_nops_btw_n_burst_n),  // output wire [31:0] 
        .probe_out22  (vio_tg_seed_program_en),        // output wire [0:0]    
        .probe_out23  (vio_tg_seed_num),                // output wire [7:0]   
        .probe_out24  (vio_tg_seed_data),                    // output wire [22:0]   
        .probe_out25  (vio_tg_glb_victim_bit),            // output wire [7:0] 
        .probe_out26  (vio_tg_glb_start_addr),             // output wire [APP_ADDR_WIDTH-1:0] 
        .probe_out27  (vio_rbyte_sel),                     // output wire [3:0]         
        .probe_in0    (vio_tg_status_state),                // output wire [3:0]           
        .probe_in1    (vio_tg_status_err_bit_valid),        // output wire [0:0]           
        .probe_in2    (vio_tg_status_first_exp_bit_valid),   // output wire [0:0] 
        .probe_in3    (vio_tg_status_first_read_bit_valid),  // output wire [0:0] 
        .probe_in4    (vio_tg_status_done),   // output wire [0:0] 
        .probe_in5    (vio_tg_status_wr_done), // output wire [0:0] 
        .probe_in6    (vio_tg_status_watch_dog_hang), // output wire [0:0] 
        .probe_in7    (vio_tg_status_err_type_valid), // output wire [0:0]
        .probe_in8    (vio_tg_status_err_type)        // output wire [0:0]
        );

   assign acc_bit_err = vio_tg_status_err_bit_sticky;

  always @(posedge c0_ddr4_clk) begin
       if (c0_ddr4_rst || vio_tg_status_wr_done )
         tg_rd_valid_cnt <= 'h0;
       else if (!c0_data_compare_error)
         tg_rd_valid_cnt <= tg_rd_valid_cnt + vio_tg_status_read_bit_valid;
 
       if ( c0_ddr4_rst)
         tg_inst_cnt <= 0;
       else if (vio_tg_status_wr_done)
        tg_inst_cnt <= tg_inst_cnt + 1;
 
      first_err_bit_valid_x1     <= vio_tg_status_first_err_bit_valid;
      first_err_bit_x1           <= vio_tg_status_first_err_bit >> (64*vio_rbyte_sel);
      err_type_valid_x1          <= vio_tg_status_err_type_valid;
      err_type_x1                <= vio_tg_status_err_type;
      acc_bit_err_x1             <= acc_bit_err >> (64*vio_rbyte_sel);
      acc_bit_err_valid_x1       <= vio_tg_status_err_bit_sticky_valid;
      tg_exp_data_x1             <= vio_tg_status_exp_bit  >> (64*vio_rbyte_sel);
      tg_exp_data_valid_x1       <= vio_tg_status_exp_bit_valid ;
      tg_rd_data_x1              <= vio_tg_status_read_bit >> (64*vio_rbyte_sel);
      tg_rd_data_valid_x1        <= vio_tg_status_read_bit_valid ;
      app_wdf_data_byte      <= c0_ddr4_app_wdf_data >> (64*vio_rbyte_sel); 
      app_rd_data_byte       <= c0_ddr4_app_rd_data >> (64*vio_rbyte_sel);
      app_wdf_data_byte_wren <= c0_ddr4_app_wdf_wren;
      app_rd_data_byte_rden  <= c0_ddr4_app_rd_data_valid;
      app_wdf_data_byte_end  <= c0_ddr4_app_wdf_end ;
      app_rdy                <= c0_ddr4_app_rdy ;
      app_wdf_rdy            <= c0_ddr4_app_wdf_rdy ;
      app_cmd                <= c0_ddr4_app_cmd ;
      app_addr               <= c0_ddr4_app_addr ;
      app_en                 <= c0_ddr4_app_en ;
      app_wdf_mask           <= c0_ddr4_app_wdf_mask ;
      app_rd_data_end        <= c0_ddr4_app_rd_data_end ;
      tg_cmp_err_x1_cnt          <= vio_tg_status_err_cnt;
      tg_rd_err_addr_x1              <= vio_tg_status_err_addr;
   


      acc_dq_err_x2[0] <= acc_bit_err_x1[0] | acc_bit_err_x1[8]  | acc_bit_err_x1[16] | acc_bit_err_x1[24] | acc_bit_err_x1[32] | acc_bit_err_x1[40] | acc_bit_err_x1[48] | acc_bit_err_x1[56];
      acc_dq_err_x2[1] <= acc_bit_err_x1[1] | acc_bit_err_x1[9]  | acc_bit_err_x1[17] | acc_bit_err_x1[25] | acc_bit_err_x1[33] | acc_bit_err_x1[41] | acc_bit_err_x1[49] | acc_bit_err_x1[57];
      acc_dq_err_x2[2] <= acc_bit_err_x1[2] | acc_bit_err_x1[10] | acc_bit_err_x1[18] | acc_bit_err_x1[26] | acc_bit_err_x1[34] | acc_bit_err_x1[42] | acc_bit_err_x1[50] | acc_bit_err_x1[58];
      acc_dq_err_x2[3] <= acc_bit_err_x1[3] | acc_bit_err_x1[11] | acc_bit_err_x1[19] | acc_bit_err_x1[27] | acc_bit_err_x1[35] | acc_bit_err_x1[43] | acc_bit_err_x1[51] | acc_bit_err_x1[59];
      acc_dq_err_x2[4] <= acc_bit_err_x1[4] | acc_bit_err_x1[12] | acc_bit_err_x1[20] | acc_bit_err_x1[28] | acc_bit_err_x1[36] | acc_bit_err_x1[44] | acc_bit_err_x1[52] | acc_bit_err_x1[60];
      acc_dq_err_x2[5] <= acc_bit_err_x1[5] | acc_bit_err_x1[13] | acc_bit_err_x1[21] | acc_bit_err_x1[29] | acc_bit_err_x1[37] | acc_bit_err_x1[45] | acc_bit_err_x1[53] | acc_bit_err_x1[61];
      acc_dq_err_x2[6] <= acc_bit_err_x1[6] | acc_bit_err_x1[14] | acc_bit_err_x1[22] | acc_bit_err_x1[30] | acc_bit_err_x1[38] | acc_bit_err_x1[46] | acc_bit_err_x1[54] | acc_bit_err_x1[62];
      acc_dq_err_x2[7] <= acc_bit_err_x1[7] | acc_bit_err_x1[15] | acc_bit_err_x1[23] | acc_bit_err_x1[31] | acc_bit_err_x1[39] | acc_bit_err_x1[47] | acc_bit_err_x1[55] | acc_bit_err_x1[63];
     
  end

genvar j;
generate
 for (j = 0; j < APP_DATA_WIDTH_BYTES ; j = j + 1) begin 
  always @ (posedge c0_ddr4_clk) begin
        acc_byte_err_x2[j]  <= |acc_bit_err[64*j+63:64*j];
  
 end
end 
endgenerate


ATG_ILA u_atg_ila_1
   (
    .clk      (c0_ddr4_clk),
    .probe0   (c0_init_calib_complete),
    .probe1   (c0_data_compare_error),
    .probe2   (acc_byte_err_x2),
    .probe3   (acc_dq_err_x2),
    .probe4   (tg_exp_data_x1),
    .probe5   (tg_exp_data_valid_x1),
    .probe6   (tg_rd_data_x1),
    .probe7   (tg_rd_data_valid_x1),
    .probe8   (tg_rd_err_addr_x1),
    .probe9   (tg_rd_valid_cnt),
    .probe10  (tg_inst_cnt),
    .probe11  (app_wdf_data_byte),    
    .probe12  (app_rd_data_byte),      
    .probe13  (app_wdf_data_byte_wren),
    .probe14  (app_rd_data_byte_rden),      
    .probe15  (app_wdf_data_byte_end),
    .probe16  (app_rdy),           
    .probe17  (app_wdf_rdy),       
    .probe18  (app_cmd),           
    .probe19  (app_addr),          
    .probe20  (app_en),            
    .probe21  (app_wdf_mask),      
    .probe22  (app_rd_data_end),   
    .probe23  (vio_tg_status_err_bit_valid),
    .probe24  (vio_tg_status_first_exp_bit_valid),
    .probe25  (vio_tg_status_first_read_bit_valid),
    .probe26  (vio_tg_status_done),
    .probe27  (vio_tg_status_wr_done),
    .probe28  (vio_tg_status_watch_dog_hang),
    .probe29  (acc_bit_err_x1),
    .probe30  (acc_bit_err_valid_x1),
    .probe31  (first_err_bit_valid_x1),
    .probe32  (first_err_bit_x1),
    .probe33  (err_type_valid_x1),
    .probe34  (err_type_x1),
    .probe35  (tg_cmp_err_x1_cnt),
    .probe36  (vio_rbyte_sel),
    .probe37  (vio_tg_status_state)    
  );


`endif

endmodule





































