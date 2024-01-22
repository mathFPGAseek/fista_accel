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
-- filename: mem_st_machine_controller.vhd
-- Initial Date: 7/8/23
-- Descr: Memory Controller / Fista Accel.
-- Modes:
-- 1. Init
-- 2. Write in B
--
-- 3. Wait for FFT completion 
-- 4. Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
--
-- 5. Read out 1-D FWD AV Col ( Step 1)
-- 6. Wait for FFT completion
-- 7. Write in 2-D FWD AV Col ( Step 2)
--
-- 8.  Read out 2-D FWD AV Row F(Vk)(Step 3)
-- 9.  Read out 2-D FWD AV Row F(H)
-- 10. Wait for FFT completion
-- 11. Write in 1-D INV AV Row ( Step 4)
--
-- 12. Read out 1-D INV AV Col F(Vk)(Step 5)
-- 13. Wait for FFT completion
-- 14. Write in 2-D INV AV Col ( Step 6)
--
-- 15. Read out 2-D INV AV Row F(Vk)(Step 7)
-- 16. Read out 2-D InV AV Row B
-- 17. Wait for FFT completion
-- 18. Write in 1-D FWD AV-B Row ( Step 8) -- Start of A^H Calculation --
--
-- 19. Read out 1-D FWD AV-B Col ( Step 9)
-- 20. Wait for FFT completion
-- 21. Write in 2-D FWD AV-B Col ( Step 10)
--
-- 22. Read out 2-D FWD AV-B Row F(Vk)(Step 11)
-- 23. Read out 2-D FWD AV-B Row F*(H)
-- 24. Wait for FFT completion
-- 25. Write in 1-D INV AV-B Row ( Step 12)
--
-- 26. Read out 1-D INV AV-B Col F(Vk)(Step 13)
-- 27. Wait for FFT completion
-- 28. Write in 2-D INV AV-B Col ( Step 14)
--
-- 29. Read out 2-D INV AV-B Row F(Vk)(Step 15)
-- 30. Wait for FFT completion 
--
-- 31. -- Return to ( Step 0) with Vk+1

-- Stall Modes
-- 4A.  Stall Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
--
-- 5A.  Stall Read out 1-D FWD AV Col ( Step 1)
-- 7A.  Stall Write in 2-D FWD AV Col ( Step 2)
--
-- 8A.  Stall Read out 2-D FWD AV Row F(Vk)(Step 3)
-- 9A.  Stall Read out 2-D FWD AV Row F(H)
-- 11A. Stall Write in 1-D INV AV Row ( Step 4)
--
-- 12A. Stall Read out 1-D INV AV Col F(Vk)(Step 5)
-- 14A. Stall Write in 2-D INV AV Col ( Step 6)
--
-- 15A. Stall Read out 2-D INV AV Row F(Vk)(Step 7)
-- 16A. Stall Read out 2-D InV AV Row B
-- 18A. Stall Write in 1-D FWD AV-B Row ( Step 8) -- Start of A^H Calculation --
--
-- 19A. Stall Read out 1-D FWD AV-B Col ( Step 9)
-- 21A. Stall Write in 2-D FWD AV-B Col ( Step 10)
--
-- 22A. Stall Read out 2-D FWD AV-B Row F(Vk)(Step 11)
-- 23A. Stall Read out 2-D FWD AV-B Row F*(H)
-- 25A. Stall Write in 1-D INV AV-B Row ( Step 12)
--
-- 26A. Stall Read out 1-D INV AV-B Col F(Vk)(Step 13)
-- 28A. Stall Write in 2-D INV AV-B Col ( Step 14)
--
-- 29A. Stall Read out 2-D INV AV-B Row F(Vk)(Step 15)
 
-- master_mode_i:
-- Bit 4: unused
-- Bit 3: A=0/AH=1
-- Bit 2: 1D=0/2D=1
-- Bit 1: FWD=0/INV=1
-- Bit 0: WR=0/RD=1
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY mem_st_machine_controller is
--generic(
--	    generic_i  : in natural);
    PORT (

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
    
  END mem_st_machine_controller;
   architecture struct of mem_st_machine_controller is
  -- signals

  
  --decoded signals
  -- app interface to ddr controller
  signal app_cmd_d         : std_logic_vector(2 downto 0);
  signal app_en_d          : std_logic;
  signal app_wdf_end_d     : std_logic;
  signal app_wdf_en_d      : std_logic;
  signal app_wdf_wren_d    : std_logic;--: std_logic_vector(2 downto 0);
  signal app_cmd_r         : std_logic_vector(2 downto 0);
  signal app_cmd_rr        : std_logic_vector(2 downto 0);
  signal app_cmd_rrr       : std_logic_vector(2 downto 0);
  signal app_en_r          : std_logic;
  signal app_en_rr         : std_logic;
  signal app_en_rrr        : std_logic;
  signal app_wdf_end_r     : std_logic;
  signal app_wdf_end_rr    : std_logic;
  signal app_wdf_end_rrr   : std_logic;
  signal app_wdf_en_r      : std_logic;
  signal app_wdf_wren_r    : std_logic;--: std_logic_vector(2 downto 0);
  signal app_wdf_wren_rr   : std_logic;
  signal app_wdf_wren_rrr  : std_logic;
    	
  -- mux/demux control to ddr memory controller.
  signal ddr_intf_mux_wr_sel_d    : std_logic_vector(1 downto 0);
  signal ddr_intf_demux_rd_sel_d  : std_logic_vector(2 downto 0);
  signal ddr_intf_mux_wr_sel_r    : std_logic_vector(1 downto 0);
  signal ddr_intf_demux_rd_sel_r  : std_logic_vector(2 downto 0);
     
  -- rd control to shared input memory
  signal mem_shared_in_enb_d      : std_logic;
  signal mem_shared_in_enb_r      : std_logic;
  signal delay_mvalid_i           : std_logic;
  signal falling_mvalid_event_d   : std_logic;
  signal falling_mvalid_event_r   : std_logic;
    
  -- mux/demux control to front and Backend modules
  signal front_end_demux_fr_fista_d  : std_logic;
  signal front_end_mux_to_fft_d      : std_logic_vector(1 downto 0);
  signal back_end_demux_fr_fh_mem_d  : std_logic;
  signal back_end_demux_fr_fv_mem_d  : std_logic;
  signal back_end_mux_to_front_end_d : std_logic;  
  signal front_end_demux_fr_fista_r  : std_logic;
  signal front_end_mux_to_fft_r      : std_logic_vector(1 downto 0);
  signal back_end_demux_fr_fh_mem_r  : std_logic;
  signal back_end_demux_fr_fv_mem_r  : std_logic;
  signal back_end_mux_to_front_end_r : std_logic;
    
  -- rd,wr control to F*(H) F(H) FIFO 
  signal f_h_fifo_wr_en_d            : std_logic;
  signal f_h_fifo_rd_en_d            : std_logic;
  signal f_h_fifo_wr_en_r            : std_logic;
  signal f_h_fifo_rd_en_r            : std_logic;
    
  -- rd,wr control to F(V) FIFO
  signal f_v_fifo_wr_en_d            : std_logic;
  signal f_v_fifo_rd_en_d            : std_logic;
  signal f_v_fifo_wr_en_r            : std_logic;
  signal f_v_fifo_rd_en_r            : std_logic;
    
  --  rd,wr control to Fdbk FIFO
  signal fdbk_fifo_wr_en_d           : std_logic;
  signal fdbk_fifo_wr_en_r           : std_logic;
  
  signal fdbk_fifo_rd_en_d           : std_logic;
  signal fdbk_fifo_rd_en_r           : std_logic;
  
  signal decoder_st_d                : std_logic_vector(5 downto 0);
  signal decoder_st_r                : std_logic_vector(5 downto 0);
  signal decoder_st_rr               : std_logic_vector(5 downto 0);
  	
  signal pulse_d                     : std_logic;
  signal pulse_r                     : std_logic;
  
  signal mem_init_start_d            : std_logic;
  signal mem_init_start_r            : std_logic;
  
  -- decoder: Address
  signal bank_addr_d                 : std_logic_vector(3 downto 0);
  signal pipe1_addr_d                : std_logic_vector(15 downto 0);  
  signal pipe2_addr_d                : std_logic_vector(15 downto 0);
  signal app_addr_d                  : std_logic_vector(19 downto 0); 
  	
  signal bank_addr_r                 : std_logic_vector(3 downto 0);
  signal pipe1_addr_r                : std_logic_vector(15 downto 0);  
  signal pipe2_addr_r                : std_logic_vector(15 downto 0);
  signal app_addr_r                  : std_logic_vector(19 downto 0); 
  	
  --extend FFt wait  
  signal extend_fft_flow_tlast_d     : std_logic;
  signal extend_fft_flow_tlast_r     : std_logic;
  
  -- counters
  signal state_counter_1_r           : integer;
  signal state_counter_2_r           : integer;
  signal state_counter_3_r           : integer;
  signal state_counter_4_r           : integer;
  signal state_counter_5_r           : integer;
  signal state_counter_6_r           : integer;
  signal state_counter_7_r           : integer;
  signal state_counter_8_r           : integer;
  
  signal clear_state_counter_1_d     : std_logic; 
  signal clear_state_counter_1_r     : std_logic;
  signal clear_state_counter_2_d     : std_logic; 
  signal clear_state_counter_2_r     : std_logic;
  signal clear_state_counter_3_d     : std_logic; 
  signal clear_state_counter_3_r     : std_logic;
  signal clear_state_counter_4_d     : std_logic; 
  signal clear_state_counter_4_r     : std_logic;
  signal clear_state_counter_5_d     : std_logic; 
  signal clear_state_counter_5_r     : std_logic;
  signal clear_state_counter_6_d     : std_logic; 
  signal clear_state_counter_6_r     : std_logic;
  signal clear_state_counter_7_d     : std_logic; 
  signal clear_state_counter_7_r     : std_logic;
  signal clear_state_counter_8_d     : std_logic;
  signal clear_state_counter_8_r     : std_logic;
  
  signal enable_state_counter_1_d     : std_logic; 
  signal enable_state_counter_1_r     : std_logic;
  signal enable_state_counter_2_d     : std_logic; 
  signal enable_state_counter_2_r     : std_logic;
  signal enable_state_counter_3_d     : std_logic; 
  signal enable_state_counter_3_r     : std_logic;
  signal enable_state_counter_4_d     : std_logic; 
  signal enable_state_counter_4_r     : std_logic;
  signal enable_state_counter_5_d     : std_logic; 
  signal enable_state_counter_5_r     : std_logic;
  signal enable_state_counter_6_d     : std_logic; 
  signal enable_state_counter_6_r     : std_logic;
  signal enable_state_counter_7_d     : std_logic; 
  signal enable_state_counter_7_r     : std_logic;
  signal enable_state_counter_8_d     : std_logic;
  signal enable_state_counter_8_r     : std_logic;
   
   
  -- States
  
  type st_controller_t is (
    state_init,
    state_write_in_b,
    state_wait_for_fft,
    state_wr_1d_fwd_av_row,
    state_rd_1d_fwd_av_col,
    -- stall states
    state_stall_wr_1d_fwd_av_row,
    state_stall_rd_1d_fwd_av_col,

    -- kludge state to write out last samples of a fft line
    state_extra_write_end_of_line_1,
    state_extra_write_end_of_line_2,
    
    -- debug state
    state_DEBUG_STOP
  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;
  
  --constants
  constant IMAGE256X256    : integer := 65536;
  -- This was bug ??? temporary
  constant COUNT_256       : integer := 256;
  constant COUNT_255       : integer := 255;
  constant COUNT_253       : integer := 253;
  constant COUNT_254       : integer := 254;
  
  constant FFT_IMAGE_SIZE  : integer := 253; -- 256 -3 for timing purposes.
  --constant FFT_IMAGE_SIZE  : integer := 254;
  constant COUNT_4         : integer := 4;
  constant COUNT_8         : integer := 8;
  
  --KLUDGE 
  constant MIN_ADDR        : std_logic_vector(19 downto 0) := "00000000000000000010"; 
  signal app_addr_d_d      : std_logic_vector(19 downto 0);     
  BEGIN
  
  ----------------------------------------
  -- Main State Machine (Comb)
  ----------------------------------------  	
   st_mach_controller : process(
   	      falling_mvalid_event_r,
       	  rdy_fr_init_and_inbound_i,
       	  wait_fr_init_and_inbound_i,
       	  app_rdy_i,
       	  app_wdf_rdy_i,
       	  state_counter_1_r,
       	  state_counter_3_r,
       	  state_counter_4_r,
       	  state_counter_5_r,
       	  state_counter_6_r,
       	  state_counter_7_r,
       	  state_counter_8_r,
       	  ps_controller
       ) begin
       	
         case ps_controller is
       	
            when state_init =>
            	
            	decoder_st_d <= "000001"; --INIT State
            	
            	if ( (rdy_fr_init_and_inbound_i = '1' ) and
            		    (wait_fr_init_and_inbound_i = '0' ) and 
            		   (app_rdy_i = '1' ) and
            		   (app_wdf_rdy_i = '1' ) 
            		 ) then
            		ns_controller        <= state_write_in_b;
            	else
            		ns_controller        <= state_init;
            	end if;
            
            when state_write_in_b =>
            	
            	decoder_st_d <= "000010"; -- Write in B
            	
            	if ( (rdy_fr_init_and_inbound_i = '0' ) or
            		   (wait_fr_init_and_inbound_i = '1' ) or -- to stall; inbound FIFO levels
            		   (app_rdy_i = '0' ) or 
            		   (app_wdf_rdy_i = '0' ) 
            		 ) then
            		ns_controller        <= state_init;
            	elsif(state_counter_1_r >= IMAGE256X256 ) then  -- ??? Is amount right
            		ns_controller        <= state_wait_for_fft; -- Complete B transfer ???
            		
            	else 
            		ns_controller        <= state_write_in_b; 
            	end if;
            	
            	
            when state_wait_for_fft =>
            	
            	decoder_st_d <= "000011"; --  Wait for FFT Completion
            	
            	--if ( (extend_fft_flow_tlast_r = '1' ) and -- fft_flow_tlast_i multi cycle(window)
            		if ( (falling_mvalid_event_r = '1') and
            		   --(app_rdy_i = '1' ) and        -- signal 
            		   --(app_wdf_rdy_i = '1') and
            		   --(app_rdy_i = '1') and
            		   (master_mode_i(0) = '0')           		   	 
            		 ) then
            		--ns_controller        <= state_wr_1d_fwd_av_row;
            		ns_controller <= state_stall_wr_1d_fwd_av_row;
            	--elsif( (extend_fft_flow_tlast_r = '1' ) and -- fft_flow_tlast_i multi cycle(window)
            	  elsif( (falling_mvalid_event_r = '1') and
            		   --(app_rdy_i = '1' ) and        -- signal 
            		   --(app_wdf_rdy_i = '1') and
            		   --(app_rdy_i = '1') and
            		   (master_mode_i(0) = '1')  -- read         		   	 
            		 ) then
            		--ns_controller        <= state_rd_1d_fwd_av_col; -- ??? DO I need to do
            		ns_controller <= state_stall_wr_1d_fwd_av_row;
            	else                                              -- redundant with state below
            		ns_controller        <= state_wait_for_fft; 
            	end if;
            	
            	
            when state_wr_1d_fwd_av_row =>
            	 
            	decoder_st_d <= "000100"; --  -Write in 1-D FWD AV Row.
            	
            	  if ( ((app_rdy_i = '0' ) or (app_wdf_rdy_i = '0')) or
            		     (state_counter_7_r >= COUNT_4 )	  
            		   ) then
            		   ns_controller <= state_stall_wr_1d_fwd_av_row;
                elsif(state_counter_3_r >= FFT_IMAGE_SIZE  ) then -- complete one FFT write
              	   ns_controller <= state_wait_for_fft;
                elsif(state_counter_4_r >= IMAGE256X256 ) then -- complete image
              	  ns_controller <=  state_rd_1d_fwd_av_col;
                else
              	  ns_controller <=  state_wr_1d_fwd_av_row;	
                end if;
            	
            	
            when state_rd_1d_fwd_av_col  => 
            	
            	decoder_st_d <= "000101"; -- Read out 1-D FWD AV Col
        --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      	--??? TEMPORARY_DEBUG
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!        	
        --    	if ( (app_rdy_i = '0' ) or
        --    		   (app_wdf_rdy_i = '0' )  ) then
        --    		 ns_controller <= state_stall_rd_1d_fwd_av_col;
        --      --elsif(state_counter_5_r >= FFT_IMAGE_SIZE ) -- complete one FFT read
        --      --	 ns_controller <= state_wait_for_fft;  -- ??? incorrect
        --      elsif(state_counter_6_r >= IMAGE256X256 ) then -- complete image
        --      	ns_controller <=  state_DEBUG_STOP;
        --      else
        --      	ns_controller <=  state_rd_1d_fwd_av_col;	
        --      end if;
        ns_controller <=  state_rd_1d_fwd_av_col;	
        --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      	--??? TEMPORARY_DEBUG
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!.    
            -- Stall States
            
            when state_stall_wr_1d_fwd_av_row => 
            	
            	decoder_st_d <= "100100"; -- Stall wr 1d fwd av
            	
              if    ( (state_counter_8_r >= COUNT_8 ) and
            		      (state_counter_3_r < COUNT_253  ) ) then
            		 ns_controller <= state_wr_1d_fwd_av_row;           	
            	elsif ( (state_counter_8_r >= COUNT_8 ) and
            		      (state_counter_3_r = COUNT_253  ) ) then
            		 ns_controller <= state_extra_write_end_of_line_2;
              elsif ( (state_counter_8_r >= COUNT_8 ) and
            		      (state_counter_3_r = COUNT_254  ) ) then
            		 ns_controller <= state_extra_write_end_of_line_1;
              elsif ( (state_counter_8_r >= COUNT_8 ) and
            		      (state_counter_3_r = COUNT_255  ) ) then
              	ns_controller <= state_wr_1d_fwd_av_row;
              elsif ( (state_counter_8_r >= COUNT_8 ) and
            		      (state_counter_3_r = COUNT_256  ) ) then
              	ns_controller <= state_wait_for_fft;
              else
              	ns_controller <=  state_stall_wr_1d_fwd_av_row;	
              end if;
            
            -- extra write states
            when state_extra_write_end_of_line_1 =>
            	decoder_st_d <= "100101";
            
            	ns_controller <=  state_wr_1d_fwd_av_row;	
            	
            when state_extra_write_end_of_line_2 =>
            	decoder_st_d <= "100110";
            	
            	ns_controller <=  state_extra_write_end_of_line_1;	
              
            when state_DEBUG_STOP => 
            	
            	decoder_st_d <= "011111";
            	           	 	
       	
            when others =>
            
               decoder_st_d <= "000001";
       	
         end case;
       	 	
       end process st_mach_controller;
   
  -----------------------------------------
  -- Main State Machine Mem & control Signals Decoder
  -----------------------------------------
  st_mach_controller_mem_and_control_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "000001" => -- INIT state
  			  			
  	  	-- app interface to ddr controller.
        app_cmd_d         <=          "000"; --"Don't Care'--: out std_logic_vector(2 downto 0);
        app_en_d          <=          '0';   -- No wr/rd  --: out std_logic;
        app_wdf_end_d     <=          '0';   -- No wr     --: out std_logic;
        app_wdf_en_d      <=          '0';   -- No wr     --: out std_logic;
        app_wdf_wren_d    <=          '0';   -- No wr     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "00";  --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';    -- No rd --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care'  --: out std_logic;
        front_end_mux_to_fft_d      <=  "00"; --"Don't Care'  --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care'  --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care'  --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care'  --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
      
     
      when "000010" => -- Write in B
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      	--??? TEMPORARY_DEBUG
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!.
      	 	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --Wr B Mem      --: out std_logic_vector(2 downto 0);
        --app_en_d          <=          '1';   --Wr B Mem      --: out std_logic;
        app_en_d          <=          '0';   --Wr B Mem      --: out std_logic;
        app_wdf_end_d     <=          '0';   --Wr B Mem      --: out std_logic;
        -- SIGNAL BELOW IS NOT A REAL SIGNAL
        --app_wdf_en_d      <=          '1';   --Wr B Mem      --: out std_logic;
        app_wdf_en_d      <=          '0';   --Wr B Mem      --: out std_logic;
        --app_wdf_wren_d    <=          '1';   --Wr B Mem      --: out std_logic_vector(2 downto 0);
        app_wdf_wren_d    <=          '0';   --Wr B Mem      --: out std_logic_vector(2 downto 0);
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      	--??? TEMPORARY_DEBUG
      	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "00";  -- Wr B mem    --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';    -- No rd  --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "01"; --Select Init  --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No wr --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No wr --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No wr --: out std_logic;
                  
      when "000011" => -- Wait for FFT Completion, after write in B
      	               -- Wait for FFT Completion, after Read out 1-D FWD AV Col ( Step 1)
  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --"Don't Care'--: out std_logic_vector(2 downto 0);
        app_en_d          <=          '0';   -- No wr/rd  --: out std_logic;
        app_wdf_end_d     <=          '0';   -- No wr     --: out std_logic;
        app_wdf_en_d      <=          '0';   -- No wr     --: out std_logic;
        app_wdf_wren_d    <=          '0';   -- No wr     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "00";  --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';    -- No rd --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "11"; -- Select Fdbk --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
        
      when "000100" =>  --Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
      	                --  Write in 2-D FWD AV Col ( Step 2)
      	                   
  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --wr FWD AV Mem         --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_end_d     <=          '0';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_en_d      <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_wren_d    <=          '1';   --wr FWD AV Mem         --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --rd(fr shared) 1-D Fwd Av Row --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care'      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '1';   --rd B Mem         --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "00"; --"Don't Care' --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
      	
      when "000101" => --  Read out 1-D FWD AV Col ( Step 1)
      	  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "001"; --rd B Mem         --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '1';   --rd B Mem         --: out std_logic;
        app_wdf_end_d     <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_en_d      <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_wren_d    <=          '0';   --"Don't Care'     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --"Don't Care'           --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "100"; --rd 1-D Fwd Av col      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';    -- No rd                 --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "11"; -- Select Fdbk --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
      	
      --when "000110" => --  Wait for FFT completion --SAME as "000011"
      --when "000111" => --  Write in 2-D FWD AV Col ( Step 2) -- SAME as "000100"
      
      
      
      -- Stall States
      when "100100" =>  -- Stall  Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
      	                -- Stall  Write in 2-D FWD AV Col ( Step 2)
      	                   
  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --" Don't Care"    --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '0';   --No wr/rd         --: out std_logic;
        app_wdf_end_d     <=          '0';   --No wr            --: out std_logic;
        app_wdf_en_d      <=          '0';   --No wr            --: out std_logic;
        app_wdf_wren_d    <=          '0';   --No wr            --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --rd(fr shared) 1-D Fwd Av Row --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care'      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';   --No rd B Mem         --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "00"; --"Don't Care' --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
        
      when "111001" => -- Stall   Read out 1-D FWD AV Col ( Step 1)
      	  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --" Don't Care"    --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '0';   --No wr/rd         --: out std_logic;
        app_wdf_end_d     <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_en_d      <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_wren_d    <=          '0';   --"Don't Care'     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --"Don't Care'           --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "100"; --rd 1-D Fwd Av col      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '0';    -- No rd                 --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "11"; -- Select Fdbk --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
      	
      --when "000110" => --  Wait for FFT completion --SAME as "000011"
      --when "000111" => --  Write in 2-D FWD AV Col ( Step 2) -- SAME as "000100"
      when "100101" =>  -- extra write state 1
      	                   
  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --wr FWD AV Mem         --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_end_d     <=          '0';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_en_d      <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_wren_d    <=          '1';   --wr FWD AV Mem         --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --rd(fr shared) 1-D Fwd Av Row --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care'      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '1';   --rd B Mem         --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "00"; --"Don't Care' --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
        
        
      when "100110" =>  -- extra write state 2
      	                   
  			
  	  	-- app interface to ddr controller
        app_cmd_d         <=          "000"; --wr FWD AV Mem         --: out std_logic_vector(2 downto 0);
        app_en_d          <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_end_d     <=          '0';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_en_d      <=          '1';   --wr FWD AV Mem         --: out std_logic;
        app_wdf_wren_d    <=          '1';   --wr FWD AV Mem         --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_d    <=    "01";  --rd(fr shared) 1-D Fwd Av Row --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_d  <=    "000"; --"Don't Care'      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_d      <=   '1';   --rd B Mem         --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_d  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_d      <=  "00"; --"Don't Care' --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_d  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_d <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_d            <=  '0'; -- No wr --: out std_logic;
        f_v_fifo_rd_en_d            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_d           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_d           <=  '0'; -- No rd --: out std_logic;
      when others =>
      	 --???? Need to add 
      end case;
      	
    end process st_mach_controller_mem_and_control_decoder;
    
    
          
  -----------------------------------------
  -- Main State Machine (Reg) Mem & Control Signals
  -----------------------------------------.

    st_mach_controller_mem_and_control_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then

              
        -- app interface to ddr controller
        app_cmd_r         <=          "000"; --: out std_logic_vector(2 downto 0);
        app_en_r          <=          '0';   --: out std_logic;
        app_wdf_end_r     <=          '0';   --: out std_logic;
        app_wdf_en_r      <=          '0';   --: out std_logic;
        app_wdf_wren_r    <=          '0';   --: out std_logic_vector(2 downto 0);
        
        app_cmd_rr        <=          "000"; --: out std_logic_vector(2 downto 0);
        app_en_rr         <=          '0';   --: out std_logic;
        app_wdf_end_rr    <=          '0';   --: out std_logic;
        --app_wdf_en_r    <=          '0';   --: out std_logic;
        app_wdf_wren_rr   <=          '0';   --: out std_logic_vector(2 downto 0);
        
        app_cmd_rrr       <=          "000"; --: out std_logic_vector(2 downto 0);
        app_en_rrr        <=          '0';   --: out std_logic;
        app_wdf_end_rrr   <=          '0';   --: out std_logic;
        --app_wdf_en_r    <=          '0';   --: out std_logic;
        app_wdf_wren_rrr  <=          '0';   --: out std_logic_vector(2 downto 0);
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_r    <=    "00";  --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_r  <=    "000"; --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_r      <=   '0';    --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_r  <=  '0'; --: out std_logic;
        front_end_mux_to_fft_r      <=  "00"; --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_r  <=  '0'; --: out std_logic;
        back_end_demux_fr_fv_mem_r  <=  '0'; --: out std_logic;
        back_end_mux_to_front_end_r <=  '0'; --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_r            <=  '0'; --: out std_logic;
        f_h_fifo_rd_en_r            <=  '0'; --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_r            <=  '0'; --: out std_logic;
        f_v_fifo_rd_en_r            <=  '0'; --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_r           <=  '0'; --: out std_logic;
        fdbk_fifo_rd_en_r           <=  '0'; --: out std_logic;
        			
        -- decoder 
        decoder_st_r                <= "000001"; -- init state
        
        ps_controller               <= state_init;
        			
       elsif(clk_i'event and clk_i = '1') then
       	
            	
        -- app interface to ddr controller
        app_cmd_r         <=          app_cmd_d;        --: out std_logic_vector(2 downto 0);
        app_en_r          <=          app_en_d;         --: out std_logic;
        app_wdf_end_r     <=          app_wdf_end_d;    --: out std_logic;
        app_wdf_en_r      <=          app_wdf_en_d;     --: out std_logic;
        app_wdf_wren_r    <=          app_wdf_wren_d;   --: out std_logic_vector(2 downto 0);
        
        app_cmd_rr        <=          app_cmd_r;        --: out std_logic_vector(2 downto 0);
        app_en_rr         <=          app_en_r;         --: out std_logic;
        app_wdf_end_rr    <=          app_wdf_end_r;    --: out std_logic;
        --app_wdf_en_r    <=          app_wdf_en_d;     --: out std_logic;
        app_wdf_wren_rr   <=          app_wdf_wren_r;   --: out std_logic_vector(2 downto 0);
        
        app_cmd_rrr       <=          app_cmd_rr;        --: out std_logic_vector(2 downto 0);
        app_en_rrr        <=          app_en_rr;         --: out std_logic;
        app_wdf_end_rrr   <=          app_wdf_end_rr;    --: out std_logic;
        --app_wdf_en_r    <=          app_wdf_en_d;     --: out std_logic;
        app_wdf_wren_rrr  <=          app_wdf_wren_rr;   --: out std_logic_vector(2 downto 0);
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_r    <=    ddr_intf_mux_wr_sel_d;  --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_r  <=    ddr_intf_demux_rd_sel_d; --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_r      <=   mem_shared_in_enb_d;    --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_r  <=  front_end_demux_fr_fista_d; --: out std_logic;
        front_end_mux_to_fft_r      <=  front_end_mux_to_fft_d; --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_r  <=  back_end_demux_fr_fh_mem_d; --: out std_logic;
        back_end_demux_fr_fv_mem_r  <=  back_end_demux_fr_fv_mem_d; --: out std_logic;
        back_end_mux_to_front_end_r <=  back_end_mux_to_front_end_d; --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_r            <=  f_h_fifo_wr_en_d; --: out std_logic;
        f_h_fifo_rd_en_r            <=  f_h_fifo_rd_en_d; --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_v_fifo_wr_en_r            <=  f_v_fifo_wr_en_d; --: out std_logic;
        f_v_fifo_rd_en_r            <=  f_v_fifo_rd_en_d; --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_r           <=  fdbk_fifo_wr_en_d; --: out std_logic;
        			
        -- decoder
        decoder_st_r                <= decoder_st_d;
        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_mem_and_control_registers; 
   
  -----------------------------------------
  -- Address Decoder KLUDGE logic
  -----------------------------------------.
  address_KLUDGE_adj_addr: process( app_addr_d) 
  	begin
  		if (app_addr_d >= MIN_ADDR ) then
  			app_addr_d_d <= std_logic_vector(unsigned(app_addr_d) - unsigned(MIN_ADDR));
  		else
  			app_addr_d_d <= (others=> '0');
  		end if;
  end process address_KLUDGE_adj_addr;
  -----------------------------------------
  -- Address Decoder
  -----------------------------------------.
  address_decoder: process( decoder_st_r,bank_addr_r,pipe1_addr_r,pipe2_addr_r,state_counter_4_r,
  	                        state_counter_5_r,state_counter_6_r )
  	begin
  		
  		case decoder_st_r is
  			
  	  when "000100" => -- write 1-D FWD AV Row
  		
  		  bank_addr_d(3 downto 0)    <=	   "0000";   --upper Ping memory
  		  pipe1_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_4_r,pipe1_addr_d'length)); --direct row addr; image counter
  		  --pipe2_addr_d(15 downto 0)  <=    (others=>'0');
  		  --app_addr_d(19 downto 0)    <=    bank_addr_r & pipe1_addr_r;
  		  	
  	
  	  when "000011" =>  -- Wait for FFT
  	  	  		
  		  bank_addr_d(3 downto 0)    <=	   "0000";   --upper Ping memory
  		  pipe1_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_4_r,pipe1_addr_d'length)); --direct row addr; image counter
  		  pipe2_addr_d(15 downto 0)  <=    (others=>'0');
  		  app_addr_d(19 downto 0)    <=    bank_addr_r & pipe1_addr_r;
  			
  	  when "000101" => -- read 1-D FWD AV col
  	  	
  	  	bank_addr_d(3 downto 0)  <=    "0000";     --upper Ping memory
  	  	pipe1_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_5_r,pipe1_addr_d'length)); -- fft count
  	  	pipe2_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_6_r,pipe2_addr_d'length)); -- image count
  	  	app_addr_d(19 downto 0)    <=    bank_addr_r & pipe1_addr_r(7 downto 0) & pipe2_addr_r(15 downto 8);   -- bank +
  	  		                                                                                                     -- lower bits of fft
  	
  	 when "100101" => -- write  row Stall
  	 	 	 	  		
  		  bank_addr_d(3 downto 0)    <=	   "0000";   --upper Ping memory
  		  pipe1_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_4_r,pipe1_addr_d'length)); --direct row addr; image counter
  		  pipe2_addr_d(15 downto 0)  <=    (others=>'0');
  		  app_addr_d(19 downto 0)    <=    bank_addr_r & pipe1_addr_r;
  	 	
  	 	  		                                                                                                     -- upper bits of image 		
  		when others =>
  			
  			bank_addr_d(3 downto 0)    <=	   "0000";  
  		  --pipe1_addr_d(15 downto 0)  <=	   (others=>'0');
  		  pipe1_addr_d(15 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_4_r,pipe1_addr_d'length)); --direct row addr; image counter
  		  pipe2_addr_d(15 downto 0)  <=    (others=>'0');
  		  app_addr_d(19 downto 0)    <=    bank_addr_r & pipe1_addr_r;
  		  	
      end case;
  end process address_decoder;
  
  -----------------------------------------
  -- Address decoder (Reg) Signals
  -----------------------------------------

  dec_registers : process( clk_i, rst_i )
  begin
            if( rst_i = '1') then
            	
            	bank_addr_r(3 downto 0)    <=	   "0000";   --upper Ping memory
  		        pipe1_addr_r(15 downto 0)  <=	   (others=> '0');
  		        pipe2_addr_r(15 downto 0)  <=    (others=>'0');
  		        app_addr_r(19 downto 0)    <=    (others=> '0');
                      
      	    elsif(clk_i'event and clk_i = '1') then
      	    	
      	    	bank_addr_r(3 downto 0)    <=	 bank_addr_d;
  		        pipe1_addr_r(15 downto 0)  <=	 pipe1_addr_d;  
  		        pipe2_addr_r(15 downto 0)  <=  pipe2_addr_d;
  		        --app_addr_r(19 downto 0)    <=  app_addr_d;
  		        --app_addr_r(19 downto 0)    <=  app_addr_d_d;   	    	
      	    	app_addr_r(19 downto 0)    <=  "0000" & pipe1_addr_r;
      	    end if;
      	    	
      	   
  end process dec_registers;			
  			

  -----------------------------------------
  -- Main State Machine Counter Signals Decoder
  -----------------------------------------
  st_mach_controller_counters_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "000001" => -- INIT state
  			
  			-- Counter control for completion of B writes state
  			clear_state_counter_1_d   <= '0'; --NOP counter 1
  			enable_state_counter_1_d  <= '0'; 
  			
  		 -- Counter control for completion of 1-D fwd av row writes
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0'; 
  			
  		 -- Counter control for completion of 1-D fwd av image-row writes
  			clear_state_counter_4_d   <= '1';
  			enable_state_counter_4_d  <= '0';	
  			
  		 -- Counter control for completion of 1-D fwd av col reads
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
  			
  		 -- Counter control for completion of 1-D fwd av image-col reads
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  		-- Counter to stay in  write to memory state
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';	
  
      -- Counter to stay in write stall state			
  			clear_state_counter_8_d   <= '1';
  		--	enable_state_counter_8_d  <= '0';	
  		
  			
  			
  	  when "000010" => -- Write in B
  			

  			clear_state_counter_1_d   <= '0';
  			enable_state_counter_1_d  <= '1'; -- enable counter 1
  			
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0'; 
  			
  			clear_state_counter_4_d   <= '1';
  			enable_state_counter_4_d  <= '0';
  			
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';	
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';	
  			
  		
  		when "000011" =>  -- Wait for FFT
  			
  			clear_state_counter_1_d   <= '1'; --clear counter 1
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '1'; --clear counter 3
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '0'; -- NOP counter 4
  			enable_state_counter_4_d  <= '0'; 			
  			  			
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			
  		when "000100" => -- write 1-D FWD AV Row
  			
  			clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '0';
  			enable_state_counter_3_d  <= '1'; --enable counter 3
  			
  			  			
  			clear_state_counter_4_d   <= '0';
  			enable_state_counter_4_d  <= '1'; --enable counter 4
  			
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '0';
  			enable_state_counter_7_d  <= '1';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			
  			
  	  when "000101" => -- read 1-D FWD AV col
  	  	
  	  	clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '1';
  			enable_state_counter_4_d  <= '0';
  			
  			clear_state_counter_5_d   <= '1';  --clear counter 5
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '0';
  			enable_state_counter_6_d  <= '1';	--enable counter 6
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  	  	
  	  	
  	  when "011111" => -- state debug stop
  	  	
  	  	clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '1';
  			enable_state_counter_4_d  <= '0';
  			
  			clear_state_counter_5_d   <= '1'; 
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			
  	  -- Stall States
  	  when "100100" =>  -- Stall  Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
      	                -- Stall  Write in 2-D FWD AV Col ( Step 2)
  	  	
  	  	clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '0'; -- NOP counter 3
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '0'; -- NOP counter 4
  			enable_state_counter_4_d  <= '0';
  			
  			clear_state_counter_5_d   <= '1'; 
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';
  			
  			clear_state_counter_8_d   <= '0';
  			--enable_state_counter_8_d  <= '1';
  			
  		 when "111001" => -- Stall   Read out 1-D FWD AV Col ( Step 1)
  		 	
  		 	clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '1'; 
  			enable_state_counter_4_d  <= '0';
  			
  			clear_state_counter_5_d   <= '1'; 
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '0';  -- NOP counter 6
  			enable_state_counter_6_d  <= '0';
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';	
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			
  		 when "100101" =>  -- extra write state 1
  		 		
  			clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '0';
  			enable_state_counter_3_d  <= '1'; --enable counter 3
  			
  			  			
  			clear_state_counter_4_d   <= '0';
  			enable_state_counter_4_d  <= '1'; --enable counter 4
  			
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '0';
  			enable_state_counter_7_d  <= '1';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			
   		 when "100110" =>  -- extra write state 2
  		 		
  			clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '0';
  			enable_state_counter_3_d  <= '1'; --enable counter 3
  			
  			  			
  			clear_state_counter_4_d   <= '0';
  			enable_state_counter_4_d  <= '1'; --enable counter 4
  			
  			clear_state_counter_5_d   <= '1';
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1';
  			enable_state_counter_6_d  <= '0';	
  			
  			
  			clear_state_counter_7_d   <= '0';
  			enable_state_counter_7_d  <= '1';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0'; 	  
  		
  		when others =>
  			 ---??? Need to add
  			clear_state_counter_1_d   <= '1';
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_3_d   <= '1';
  			enable_state_counter_3_d  <= '0';
  			
  			clear_state_counter_4_d   <= '1';
  			enable_state_counter_4_d  <= '0';
  			 			  			
  			clear_state_counter_5_d   <= '1'; 
  			enable_state_counter_5_d  <= '0'; 
 
  			clear_state_counter_6_d   <= '1'; 
  			enable_state_counter_6_d  <= '0';	
  			
  			clear_state_counter_7_d   <= '1';
  			enable_state_counter_7_d  <= '0';
  			
  			clear_state_counter_8_d   <= '1';
  			--enable_state_counter_8_d  <= '0';
  			 
  	end case;
  end process st_mach_controller_counters_decoder;
  
  
  -----------------------------------------
  -- Main State Machine (Reg) Counter Signals
  -----------------------------------------.

  st_mach_controller_counters_registers : process( clk_i, rst_i )
         begin
            if( rst_i = '1') then

              
              clear_state_counter_1_r         <= '1';
              enable_state_counter_1_r        <= '0';
              
              clear_state_counter_2_r         <= '1';
              enable_state_counter_2_r        <= '0';                     
              
              clear_state_counter_3_r         <= '1';
              enable_state_counter_3_r        <= '0';
              
              clear_state_counter_4_r         <= '1';
              enable_state_counter_4_r        <= '0';            
                            
              clear_state_counter_5_r         <= '1';
              enable_state_counter_5_r        <= '0';
              
              clear_state_counter_6_r         <= '1';
              enable_state_counter_6_r        <= '0';
              
              clear_state_counter_7_r         <= '1';
  			      enable_state_counter_7_r        <= '0';
  			      
  			      clear_state_counter_8_r         <= '1';
  			      enable_state_counter_8_r        <= '0';
              
      	    elsif(clk_i'event and clk_i = '1') then
      	    	
      	    	-- Complete B writes
      	    	clear_state_counter_1_r         <= clear_state_counter_1_d;
              enable_state_counter_1_r        <= enable_state_counter_1_d;
              
              -- Extend fft_flow_tlast_i; To allow trans. st. wait_fft to st. write
              clear_state_counter_2_r         <= clear_state_counter_2_d;
              enable_state_counter_2_r        <= enable_state_counter_2_d;
              
              -- Counter control for completion of 1-D fwd av row writes
              clear_state_counter_3_r         <= clear_state_counter_3_d;
              enable_state_counter_3_r        <= enable_state_counter_3_d;
              
              -- Counter control for completion of 1-D fwd av image-row writes
              clear_state_counter_4_r         <= clear_state_counter_4_d;
              enable_state_counter_4_r        <= enable_state_counter_4_d;
              
              -- Counter control for completion of 1-D fwd av col reads
              clear_state_counter_5_r         <= clear_state_counter_5_d;
              enable_state_counter_5_r        <= enable_state_counter_5_d;
              
              -- Counter control for completion of 1-D fwd av image-col reads
              clear_state_counter_6_r         <= clear_state_counter_6_d;
              enable_state_counter_6_r        <= enable_state_counter_6_d;
              
              --Counter to allow limited burst to wr mem
              clear_state_counter_7_r         <= clear_state_counter_7_d;
              enable_state_counter_7_r        <= enable_state_counter_7_d;
              
              -- Counter to stay in write stall state			
  			      clear_state_counter_8_r   <= clear_state_counter_8_d;
  			      enable_state_counter_8_r  <= enable_state_counter_8_d;	
      	    	
      	    end if;
      	    	
      	   
  end process st_mach_controller_counters_registers; 	
  					
  ----------------------------------------
  -- Counters
  ----------------------------------------
  -- transition Write B to Wait FFT
  state_counter_1 : process( clk_i, rst_i, clear_state_counter_1_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_1_r       <=  0 ;
      elsif( clear_state_counter_1_r = '1') then
              state_counter_1_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_1_r = '1') then
              state_counter_1_r       <=  state_counter_1_r + 1;
         end if;
      end if;
  end process state_counter_1;
  
    -- Make  fft_flow_tlast_i a N pulse width ( Free- running counter)
  state_counter_2 : process( clk_i, rst_i, clear_state_counter_2_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_2_r       <=  0 ;
      elsif( clear_state_counter_2_r = '1') then
              state_counter_2_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
              state_counter_2_r       <=  state_counter_2_r + 1;
      end if;

  end process state_counter_2;
  
  -- Count to complete one FFT write
  state_counter_3 : process( clk_i, rst_i, clear_state_counter_3_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_3_r       <=  0 ;
      elsif( clear_state_counter_3_r = '1') then
              state_counter_3_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_3_r = '1') then
              state_counter_3_r       <=  state_counter_3_r + 1;
         end if;
      end if;
  end process state_counter_3;
  
  -- Count to complete one Image write
  state_counter_4 : process( clk_i, rst_i, clear_state_counter_4_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_4_r       <=  0 ;
      elsif( clear_state_counter_4_r = '1') then
              state_counter_4_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_4_r = '1') then
              state_counter_4_r       <=  state_counter_4_r + 1;
         end if;
      end if;
  end process state_counter_4;
  
  -- Count to complete one FFT read
  state_counter_5 : process( clk_i, rst_i, clear_state_counter_5_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_5_r       <=  0 ;
      elsif( clear_state_counter_5_r = '1') then
              state_counter_5_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_5_r = '1') then
              state_counter_5_r       <=  state_counter_5_r + 1;
         end if;
      end if;
  end process state_counter_5;
  
  -- Count to complete one Image read
  state_counter_6 : process( clk_i, rst_i, clear_state_counter_6_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_6_r       <=  0 ;
      elsif( clear_state_counter_6_r = '1') then
              state_counter_6_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_6_r = '1') then
              state_counter_6_r       <=  state_counter_6_r + 1;
         end if;
      end if;
  end process state_counter_6;
  
    -- Count to limit wr burst
  state_counter_7 : process( clk_i, rst_i, clear_state_counter_7_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_7_r       <=  0 ;
      elsif( clear_state_counter_7_r = '1') then
              state_counter_7_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_7_r = '1') then
              state_counter_7_r       <=  state_counter_7_r + 1;
         end if;
      end if;
  end process state_counter_7;
  
      -- Counter to stay in write stall state		
  state_counter_8 : process( clk_i, rst_i, clear_state_counter_8_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_8_r       <=  0 ;
      elsif( clear_state_counter_8_r = '1') then
              state_counter_8_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_8_r = '1') then
              state_counter_8_r       <=  state_counter_8_r + 1;
         end if;
      end if;
  end process state_counter_8;
  
  ----------------------------------------
  -- Ancillary logic
  ----------------------------------------
  
  -- Signal generation for mem_start_init
  
  decoder_st_r_del : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			decoder_st_rr <= (others => '0');
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	decoder_st_rr <= decoder_st_r;
  	  end if;
  end process decoder_st_r_del;
  
  pulse_d <= not(decoder_st_rr(0)) and decoder_st_r(0); -- detect rising edge.
  	
  pulse_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			pulse_r <= '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	pulse_r <= pulse_d;
  	  end if;
  end process pulse_reg;	
  	
  mem_init_start_d <= pulse_r and not(or decoder_st_r(5 downto 2 )) and decoder_st_r(1); -- state transition:
  	                                                                                  -- fr 
  	                                                                                  -- state_write_in_b
  	                                                                                  -- to
  	                                                                                  -- state_wait_for_fft
  			
  mem_init_start_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			 mem_init_start_r <= '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	mem_init_start_r <= mem_init_start_d;
  	  end if;
  end process  mem_init_start_reg;
  
  -- Extend fft_flow_tlast_i; To allow trans. st. wait_fft to st. write
  
  clear_state_counter_2_d <= fft_flow_tlast_i;
  
  clear_state_counter_2_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			clear_state_counter_2_r <= '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	clear_state_counter_2_r <= clear_state_counter_2_d;
  	  end if;
  end process clear_state_counter_2_reg;	
  
  
  extend_fft_flow_last_proc : process(state_counter_2_r)
    begin
    	if (state_counter_2_r <= 64) then
    		extend_fft_flow_tlast_d <= '1';
    	else
    		extend_fft_flow_tlast_d <= '0';
    	end if;
  end process   extend_fft_flow_last_proc;
  
  
  extend_fft_flow_last_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			extend_fft_flow_tlast_r <= '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	extend_fft_flow_tlast_r <= extend_fft_flow_tlast_d;
  	  end if;
  end process extend_fft_flow_last_reg;	
  
  -- Falling edge of mvalid
  falling_edge_mvalid : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1') then
  			delay_mvalid_i <= '0';
  		elsif(clk_i'event and clk_i = '1') then
  			delay_mvalid_i <= mem_shared_in_ch_state_i;
  		end if;
  end process falling_edge_mvalid;
  
  falling_mvalid_event_d <= not(mem_shared_in_ch_state_i) and delay_mvalid_i;
  
  falling_edge_mvalid_reg : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1')	then
  			falling_mvalid_event_r <= '0';
  	  elsif(clk_i'event and clk_i = '1') then
  	  	falling_mvalid_event_r <= falling_mvalid_event_d;
  	  end if;
  end process falling_edge_mvalid_reg;
  
  -- enable for counter 8 which keeps in stalled state wr to mem
  enable_state_counter_8_d <= app_rdy_i and app_wdf_rdy_i;
  
  
  ----------------------------------------
  -- Assignments
  ----------------------------------------
  --bp_d  <= std_logic_vector(to_unsigned(state_counter_1_r,bp_d'length));
  --bit_plane_int <= to_integer(unsigned(bit_planes_d ));
           	
  -- app interface to ddr controller
  app_addr_o        <=    "000000000" & app_addr_r;
  app_cmd_o         <=          app_cmd_rrr;        --: out std_logic_vector(2 downto 0);
  app_en_o          <=          app_en_rrr;         --: out std_logic;
  app_wdf_end_o     <=          app_wdf_end_rrr;    --: out std_logic;
  --app_wdf_en_o      <=          app_wdf_en_r;     --: out std_logic;
  --app_wdf_wren_o    <=          app_wdf_wren_rrr;   --: out std_logic_vector(2 downto 0);
  app_wdf_wren_o    <=          app_wdf_wren_rr;
    	
  --mux/demux control to ddr memory controller.
  ddr_intf_mux_wr_sel_o    <=    ddr_intf_mux_wr_sel_r;  --: out std_logic_vector(1 downto 0);
  ddr_intf_demux_rd_sel_o  <=    ddr_intf_demux_rd_sel_r; --: out std_logic_vector(2 downto 0);
     
  -- rd control to shared input memory
  mem_shared_in_enb_o      <=   mem_shared_in_enb_r;    --: out std_logic;
  mem_shared_in_addb_o     <=   std_logic_vector(to_unsigned(state_counter_3_r,mem_shared_in_addb_o'length));
    
  -- mux/demux control to front and Backend modules.  
  front_end_demux_fr_fista_o  <=  front_end_demux_fr_fista_r; --: out std_logic;
  front_end_mux_to_fft_o      <=  front_end_mux_to_fft_r; --: out std_logic_vector(1 downto 0);
  back_end_demux_fr_fh_mem_o  <=  back_end_demux_fr_fh_mem_r; --: out std_logic;
  back_end_demux_fr_fv_mem_o  <=  back_end_demux_fr_fv_mem_r; --: out std_logic;
  back_end_mux_to_front_end_o <=  back_end_mux_to_front_end_r; --: out std_logic;
    
  -- rd,wr control to F*(H) F(H) FIFO 
  f_h_fifo_wr_en_o            <=  f_h_fifo_wr_en_r; --: out std_logic;.
  f_h_fifo_rd_en_o            <=  f_h_fifo_rd_en_r; --: out std_logic;
    
  -- rd,wr control to F(V) FIFO
  f_v_fifo_wr_en_o            <=  f_v_fifo_wr_en_r; --: out std_logic;.
  f_v_fifo_rd_en_o            <=  f_v_fifo_rd_en_r; --: out std_logic;
    
  --  rd,wr control to Fdbk FIFO
  fdbk_fifo_wr_en_o           <=  fdbk_fifo_wr_en_r; --: out std_logic;

       	
  -- FIXED value
  app_wdf_mask_o  <= (others => '0');
       
  -- Output for mem_init
  mem_init_start_o <= mem_init_start_r; 
  
      
            	
  END architecture struct; 
    