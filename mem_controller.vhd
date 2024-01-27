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
-- filename: mem_controller.vhd
-- Initial Date: 9/23/23
-- Descr: Memory Controller Top Level / Fista Accel.
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity mem_controller is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    master_mode_i                  : in std_logic_vector(4 downto 0);
    
    rdy_fr_init_and_inbound_i      : in std_logic; -- Equiv. to Almost full flag
    wait_fr_init_and_inbound_i     : in std_logic; -- Equiv. to Almost empty flag
    
    --fft signals
    fft_flow_tlast_i               : in std_logic; -- This is a multiple clock pulse when 
                                                   -- done writing to mem buffer by FFT state mach
    
    mem_init_start_o               : out std_logic;
    
    -- input fifo control ??? Move to another state machine controller in mem controller
    --inbound_flow_fifo_wr_en_o      : out std_logic;
    --inbound_flow_fifo_rd_en_o      : out std_logic;
    --inbound_flow_fifo_full_i       : in std_logic;
    --inbound_flow_fifo_empty_i      : in std_logic;
    
    -- rd control to init memory ??? Move to init st and mem module
    ----------inbound_flow_mem_init_ena_o       : out std_logic;
    --inbound_flow_mem_init_wea_o       : out std_logic_vector(0 downto 0);
    ----------inbound_flow_mem_init_addra_o     : out std_logic_vector(15 downto 0);
    --inbound_flow_mem_init_enb_o       : out std_logic;
    --inbound_flow_mem_init_addb_o      : out std_logic_vector(7 downto 0);
    	
    -- rd control to external memory "B"  ??? Move to another state machine controller in mem controller
    ----------inbound_flow_mem_ext_ena_o       : out std_logic;
    --inbound_flow_mem_ext_wea_o       : out std_logic_vector(0 downto 0);
    ----------inbound_flow_mem_ext_addra_o     : out std_logic_vector(7 downto 0);
    --inbound_flow_mem_ext_enb_o       : out std_logic;
    --inbound_flow_mem_ext_addb_o      : out std_logic_vector(7 downto 0);
    
    -- app interface to ddr controller
    app_rdy_i           	: in std_logic;
    app_wdf_rdy_i       	: in std_logic;
    app_rd_data_valid_i   : in std_logic_vector( 0 downto 0);
    --add_rd_data_i         : in std_logic_vector(511 downto 0);
    app_cmd_o             : out std_logic_vector(2 downto 0);
    app_addr_o            : out std_logic_vector(28 downto 0);
    app_en_o              : out std_logic;
    app_wdf_mask_o        : out std_logic_vector(63 downto 0);
    --app_wdf_data_o        : out std_logic_vector(511 downto 0);
    app_wdf_end_o         : out std_logic;
    app_wdf_wren_o        : out std_logic;
    --app_wdf_en_o          : out std_logic;
    --app_wdf_addr_o        : out std_logic_vector(28 downto 0);
    --app_wdf_cmd_o         : out std_logic_vector(2 downto 0);
    	
    -- mux control to ddr memory controller.
    ddr_intf_mux_wr_sel_o     : out std_logic_vector(1 downto 0);
    ddr_intf_demux_rd_sel_o   : out std_logic_vector(2 downto 0);
     
    -- rd,wr control to shared input memory ??? Move to FFT st mach
    --mem_shared_in_ena_o       : out std_logic;
    --mem_shared_in_wea_o       : out std_logic_vector(0 downto 0);
    --mem_shared_in_addra_o     : out std_logic_vector(7 downto 0);
    mem_shared_in_ch_state_i  : in std_logic;
    mem_shared_in_enb_o       : out std_logic;
    mem_shared_in_addb_o      : out std_logic_vector(7 downto 0);
    
    -- mux control to front and Backend modules  
    front_end_demux_fr_fista_o   : out std_logic;
    front_end_mux_to_fft_o       : out std_logic_vector(1 downto 0);
    back_end_demux_fr_fh_mem_o   : out std_logic;
    back_end_demux_fr_fv_mem_o   : out std_logic;
    back_end_mux_to_front_end_o  : out std_logic;
    
    -- rd,wr control to F*(H) F(H) FIFO 
    f_h_fifo_wr_en_o             : out std_logic;
    f_h_fifo_rd_en_o             : out std_logic;
    f_h_fifo_full_i              : in std_logic;
    f_h_fifo_empty_i             : in std_logic;
    
    -- rd,wr control to F(V) FIFO
    f_v_fifo_wr_en_o             : out std_logic;
    f_v_fifo_rd_en_o             : out std_logic;
    f_v_fifo_full_i              : in std_logic;
    f_v_fifo_empty_i             : in std_logic;
    
    --  rd,wr control to Fdbk FIFO
    fdbk_fifo_wr_en_o             : out std_logic;
    fdbk_fifo_rd_en_o             : out std_logic;
    fdbk_fifo_full_i              : in std_logic;
    fdbk_fifo_empty_i             : in std_logic;
    
    ---  rd,wr control to Fista xk FIFO ??? Move to fista st mach
    --fista_fifo_xk_wr_en_o         : out std_logic;
    --fista_fifo_xk_en_o            : out std_logic;
    --fista_fifo_xk_full_i          : in std_logic;
    --fista_fifo_xk_empty_i         : in std_logic;
    
    --  rd,wr control to Fista xk FIFO ??? Move to fista st mach
    --fista_fifo_vk_wr_en_o         : out std_logic;
    --fista_fifo_vk_en_o            : out std_logic;
    --fista_fifo_vk_full_i          : in std_logic;
    --fista_fifo_vk_empty_i         : in std_logic;
     
    -- output control
    fista_accel_valid_rd_o       : out std_logic

    );
    
end mem_controller;

architecture struct of mem_controller is  
  -- signals
signal mem_shared_in_enb_int    : std_logic;
signal mem_shared_in_addb_int   : std_logic_vector( 7 downto 0); 
signal mem_shared_out_addb_int  : std_logic_vector( 7 downto 0); 
signal mem_shared_in_enb_int_r  : std_logic;
	
begin
  
  
    -----------------------------------------
    -- Memory State Machine Controller 
    -----------------------------------------	
    
    u0 : entity work.mem_st_machine_controller
    PORT MAP(
    	
    	  clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                      => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => master_mode_i, --: in std_logic_vector(4 downto 0);
                                                
        rdy_fr_init_and_inbound_i                   => rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost full flag
         wait_fr_init_and_inbound_i                 =>  wait_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost empty flag
                                                 
        --fft signals                            
        fft_flow_tlast_i                            => fft_flow_tlast_i,--: in std_logic; -- This is a multiple clock pulse when 
                                                                   -- done writing to mem buffer by FFT state mach
                                                   
        mem_init_start_o                            => mem_init_start_o,--: out std_logic;
                                                       
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
        ddr_intf_mux_wr_sel_o                       => ddr_intf_mux_wr_sel_o, --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o                     => ddr_intf_demux_rd_sel_o, --: out std_logic_vector(2 downto 0);
        
        mem_shared_in_ch_state_i                    => mem_shared_in_ch_state_i,                                          
        mem_shared_in_enb_o                         => mem_shared_in_enb_int, --: out std_logic;
        mem_shared_in_addb_o                        => mem_shared_in_addb_int, --: out std_logic_vector(7 downto 0);
                                               
        -- mux control to front and Backend modules 
        front_end_demux_fr_fista_o                  => front_end_demux_fr_fista_o, --: out std_logic;
        front_end_mux_to_fft_o                      => front_end_mux_to_fft_o, --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o                  => back_end_demux_fr_fh_mem_o , --: out std_logic;
        back_end_demux_fr_fv_mem_o                  => back_end_demux_fr_fv_mem_o, --: out std_logic;
        back_end_mux_to_front_end_o                 => back_end_mux_to_front_end_o, --: out std_logic;
                                                 
        -- rd,wr control to F*(H) F(H) FIFO       
        f_h_fifo_wr_en_o                            => f_h_fifo_wr_en_o, --: out std_logic;
        f_h_fifo_rd_en_o                            => f_h_fifo_rd_en_o, --: out std_logic;
        f_h_fifo_full_i                             => f_h_fifo_full_i, --: in std_logic;
        f_h_fifo_empty_i                            => f_h_fifo_empty_i, --: in std_logic;
                                                   
        -- rd,wr control to F(V) FIFO              
        f_v_fifo_wr_en_o                            => f_v_fifo_wr_en_o, --: out std_logic;
        f_v_fifo_rd_en_o                            => f_v_fifo_rd_en_o, --: out std_logic;
        f_v_fifo_full_i                             => f_v_fifo_full_i, --: in std_logic;
        f_v_fifo_empty_i                            => f_v_fifo_empty_i, --: in std_logic;
                                                 
        --  rd,wr control to Fdbk FIFO           
        fdbk_fifo_wr_en_o                           => fdbk_fifo_wr_en_o, --: out std_logic;
        fdbk_fifo_rd_en_o                           => fdbk_fifo_rd_en_o, --: out std_logic;
        fdbk_fifo_full_i                            => fdbk_fifo_full_i, --: in std_logic;
        fdbk_fifo_empty_i                           => fdbk_fifo_empty_i, --: in std_logic;
                                                
        -- output control                      
        fista_accel_valid_rd_o                      => fista_accel_valid_rd_o--: out std_logic
    	                                              
    );
    
    -----------------------------------------
    -- Address Generation for shared memory : To write to DDR
    -----------------------------------------	
    --U1 : entity work.blk_wr_addr_mem_gen_0 
    --PORT MAP( 
    --clka              =>   clk_i,--: in STD_LOGIC;
    --ena               =>   mem_shared_in_enb_int,--: in STD_LOGIC;
    --addra             =>   mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    --douta             =>   mem_shared_out_addb_int--: out STD_LOGIC_VECTOR ( 7 downto 0 )
    --);
    U1 : entity work.blk_wr_addr_mem_gen_no_reg_0 
    PORT MAP( 
    clka              =>   clk_i,--: in STD_LOGIC;
    ena               =>   mem_shared_in_enb_int,--: in STD_LOGIC;
    addra             =>   mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    douta             =>   mem_shared_out_addb_int--: out STD_LOGIC_VECTOR ( 7 downto 0 )
    );
    
    -----------------------------------------
    -- Address Generation for shared memory : To write to DDR
    -----------------------------------------	 
    --U2: entity work.blk_rd_addr_mem_gen_no_reg_0
    --PORT MAP ( 
    --clka    =>     clk_i, --: in STD_LOGIC;
    --ena     =>            --: in STD_LOGIC;
    --addra   =>            --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    --douta   =>            --: out STD_LOGIC_VECTOR ( 15 downto 0 )
  --);
    -----------------------------------------
    -- Delay Memory Controller enable output
    -----------------------------------------.	
    enable_delay_reg : process(clk_i, rst_i)
    		begin
    			if( rst_i = '1') then
    				mem_shared_in_enb_int_r <= '0';
    				
    			elsif(clk_i'event and clk_i = '1') then
    				mem_shared_in_enb_int_r <= mem_shared_in_enb_int;
    			end if;
    				
    end process enable_delay_reg;	
    -----------------------------------------
    -- FISTA State Machine Controller 
    -----------------------------------------	
   
    -----------------------------------------
    -- Assignments
    -----------------------------------------.	 
    mem_shared_in_enb_o   <= mem_shared_in_enb_int_r;
    mem_shared_in_addb_o  <= mem_shared_out_addb_int;  
            	
end  architecture struct; 
    