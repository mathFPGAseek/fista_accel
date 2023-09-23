------------------------------------------------
--        ,....,
--      ,:::::::
--     ,::/^\"``.
--    ,::/, `   e`.    
--   ,::; |        '.
--   ,::|  \___,-.  c)
--   ;::|     \   '-'
--   ;::|      \
--   ;::|   _.=`\     
--   `;:|.=` _.=`\
--     '|_.=`   __\
--     `\_..==`` /
--      .'.___.-'.
--     /          \
--    ('--......--')
--    /'--......--'\
--    `"--......--"`
--
-- Created By: RBD
-- filename: fista_accel_top.vhd
-- Initial Date: 9/23/23
-- Descr: Fista accel top 
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity fista_accel_top is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    dbg_master_mode_i                  : in std_logic_vector(4 downto 0);
  
    dbg_rdy_fr_init_and_inbound_i      : in std_logic; -- Equiv. to Almost full flag
    dbg_wait_fr_init_and_inbound_i     : in std_logic; -- Equiv. to Almost empty flag
  
    --fft signals
    dbg_fft_flow_tlast_i               : in std_logic; -- This is a multiple clock pulse when 
                                                 -- done writing to mem buffer by FFT state mach    
    dbg_mem_init_start_o               : out std_logic;
    
    -- app interface to ddr controller
    app_rdy_i           	: in std_logic;
    app_wdf_rdy_i       	: in std_logic;
    app_rd_data_valid_i   : in std_logic_vector( 0 downto 0);
    add_rd_data_i         : in std_logic_vector(511 downto 0);
    app_cmd_o             : out std_logic_vector(2 downto 0);
    app_addr_o            : out std_logic_vector(28 downto 0);
    app_en_o              : out std_logic;
    app_wdf_mask_o        : out std_logic_vector(63 downto 0);
    app_wdf_data_o        : out std_logic_vector(511 downto 0);
    app_wdf_end_o         : out std_logic;
    app_wdf_wren_o        : out std_logic;
   	
    -- mux control to ddr memory controller.
    dbg_ddr_intf_mux_wr_sel_o     : out std_logic_vector(1 downto 0);
    dbg_ddr_intf_demux_rd_sel_o   : out std_logic_vector(2 downto 0);
    dbg_mem_shared_in_enb_o       : out std_logic;
    dbg_mem_shared_in_addb_o      : out std_logic_vector(7 downto 0);

    -- mux control to front and Backend modules  
    dbg_front_end_demux_fr_fista_o   : out std_logic;
    dbg_front_end_mux_to_fft_o       : out std_logic_vector(1 downto 0);
    dbg_back_end_demux_fr_fh_mem_o   : out std_logic;
    dbg_back_end_demux_fr_fv_mem_o   : out std_logic;
    dbg_back_end_mux_to_front_end_o  : out std_logic;

    -- rd,wr control to F*(H) F(H) FIFO 
    dbg_f_h_fifo_wr_en_o             : out std_logic;
    dbg_f_h_fifo_rd_en_o             : out std_logic;
    dbg_f_h_fifo_full_i              : in std_logic;
    dbg_f_h_fifo_empty_i             : in std_logic;
 
    -- rd,wr control to F(V) FIFO
    dbg_f_h_fifo_wr_en_o             : out std_logic;
    dbg_f_h_fifo_rd_en_o             : out std_logic;
    dbg_f_h_fifo_full_i              : in std_logic;
    dbg_f_h_fifo_empty_i             : in std_logic;
 
    --  rd,wr control to Fdbk FIFO
    dbg_fdbk_fifo_wr_en_o             : out std_logic;
    dbg_fdbk_fifo_rd_en_o             : out std_logic;
    dbg_fdbk_fifo_full_i              : in std_logic;
    dbg_fdbk_fifo_empty_i             : in std_logic;
    
    -- output control
    fista_accel_valid_rd_o       : out std_logic

    );
    
end fista_accel_top;

architecture struct of fista_accel_top is  
  -- signals  
begin
  
  
    -----------------------------------------
    -- Memory Controller 
    -----------------------------------------	
    
    u0 : entity work.mem_controller
    PORT MAP(
    	
    	  clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                      => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => dbg_master_mode_i, --: in std_logic_vector(4 downto 0);
                                                 
        rdy_fr_init_and_inbound_i                   => dbg_rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost full flag
        rdy_fr_init_and_inbound_i                   => dbg_rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost empty flag
                                                    
        --fft signals                              
        fft_flow_tlast_i                            => dbg_fft_flow_tlast_i,--: in std_logic; -- This is a multiple clock pulse when 
                                                                  -- done writing to mem buffer by FFT state mach
                                                    
        mem_init_start_o                            => dbg_mem_init_start_o,--: out std_logic;
                                                    
        -- app interface to ddr controller             
        app_rdy_i           	                      => app_rdy_i,     --: in std_logic;
        app_wdf_rdy_i       	                      => app_wdf_rdy_i, --: in std_logic;
        app_rd_data_valid_i                         => app_rd_data_valid_i, --: in std_logic_vector( 0 downto 0);
        app_cmd_o                                   => app_cmd_o, --: out std_logic_vector(2 downto 0);
        app_addr_o                                  => app_addr_o, --: out std_logic_vector(28 downto 0);
        app_en_o                                    => app_en_o, --: out std_logic;
        app_wdf_mask_o                              => app_wdf_mask_o, --: out std_logic_vector(63 downto 0);
                                             
        app_wdf_end_o                               => app_wdf_end_o, --: out std_logic;
        app_wdf_wren_o                              => app_wdf_wren_o, --: out std_logic;
                                             
        	                                  
        -- mux control to ddr memory controller.      
        ddr_intf_mux_wr_sel_o                       => dbg_ddr_intf_mux_wr_sel_o, --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o                     => dbg_ddr_intf_demux_rd_sel_o, --: out std_logic_vector(2 downto 0);
                                                 
        mem_shared_in_enb_o                         => dbg_mem_shared_in_enb_o, --: out std_logic;
        mem_shared_in_addb_o                        => dbg_mem_shared_in_addb_o, --: out std_logic_vector(7 downto 0);
                                                  
        -- mux control to front and Backend modules  
        front_end_demux_fr_fista_o                  => dbg_front_end_demux_fr_fista_o, --: out std_logic;
        front_end_mux_to_fft_o                      => dbg_front_end_mux_to_fft_o, --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o                  => dbg_back_end_demux_fr_fh_mem_o , --: out std_logic;
        back_end_demux_fr_fv_mem_o                  => dbg_back_end_demux_fr_fv_mem_o, --: out std_logic;
        back_end_mux_to_front_end_o                 => dbg_back_end_mux_to_front_end_o, --: out std_logic;
                                                    
        -- rd,wr control to F*(H) F(H) FIFO        
        f_h_fifo_wr_en_o                            => dbg_f_h_fifo_wr_en_o, --: out std_logic;
        f_h_fifo_rd_en_o                            => dbg_f_h_fifo_rd_en_o, --: out std_logic;
        f_h_fifo_full_i                             => dbg_f_h_fifo_full_i, --: in std_logic;
        f_h_fifo_empty_i                            => dbg_f_h_fifo_empty_i, --: in std_logic;
                                                 
        -- rd,wr control to F(V) FIFO             
        f_h_fifo_wr_en_o                            => dbg_f_h_fifo_wr_en_o, --: out std_logic;
        f_h_fifo_rd_en_o                            => dbg_f_h_fifo_rd_en_o, --: out std_logic;
        f_h_fifo_full_i                             => dbg_f_h_fifo_full_i, --: in std_logic;
        f_h_fifo_empty_i                            => dbg_f_h_fifo_empty_i, --: in std_logic;
                                                      
        --  rd,wr control to Fdbk FIFO           
        fdbk_fifo_wr_en_o                           => dbg_fdbk_fifo_wr_en_o, --: out std_logic;
        fdbk_fifo_rd_en_o                           => dbg_fdbk_fifo_rd_en_o, --: out std_logic;
        fdbk_fifo_full_i                            => dbg_fdbk_fifo_full_i, --: in std_logic;
        fdbk_fifo_empty_i                           => dbg_fdbk_fifo_empty_i, --: in std_logic;
                                                
        -- output control                      
        fista_accel_valid_rd_o                      => fista_accel_valid_rd_o--: out std_logic
    	                                              
    );
    
    -----------------------------------------
    --  init_and_inbound flow
    -----------------------------------------	
    
    -----------------------------------------
    --  front_end
    -----------------------------------------	
    
    -----------------------------------------
    --  master_controller
    -----------------------------------------	

    -----------------------------------------
    --  fft engine
    -----------------------------------------	
    
    -----------------------------------------
    --  mem_in_buffer
    -----------------------------------------	
    
    -----------------------------------------
    --  mem_intf
    -----------------------------------------	

    -----------------------------------------
    --  back_end
    -----------------------------------------	
    
    -----------------------------------------
    --  b fdbk memory
    -----------------------------------------	
    
    -----------------------------------------
    --  f_h adj memory
    -----------------------------------------	
    
    -----------------------------------------
    --  f_v memory
    -----------------------------------------	
    
    -----------------------------------------
    --  fista processing
    -----------------------------------------
   
            	
end  architecture struct; 
    