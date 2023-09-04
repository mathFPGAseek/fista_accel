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
    
    rdy_fr_init_and_inbound_i      : in std_logic;
    
    --fft signals
    fft_flow_tlast_i               : in std_logic;
    
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
    f_h_fifo_wr_en_o             : out std_logic;
    f_h_fifo_rd_en_o             : out std_logic;
    f_h_fifo_full_i              : in std_logic;
    f_h_fifo_empty_i             : in std_logic;
    
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
  
  -- signals
  

  type st_controller_t is (
  state_init,
  state_wait_fft,
  state_wr_out_fft,
  state_wr_rd_out_fft,
  state_finish_rd_out_fft,
  state_rd_out_ddr_mem
  
  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;
  
  --decoded signals
  -- app interface to ddr controller
  signal app_cmd_d         : std_logic_vector(2 downto 0);
  signal app_en_d          : std_logic;
  signal app_wdf_end_d     : std_logic;
  signal app_wdf_en_d      : std_logic;
  signal app_wdf_wren_d    : std_logic_vector(2 downto 0);
  signal app_cmd_r         : std_logic_vector(2 downto 0);
  signal app_en_r          : std_logic;
  signal app_wdf_end_r     : std_logic;
  signal app_wdf_en_r      : std_logic;
  signal app_wdf_wren_r    : std_logic_vector(2 downto 0);
    	
  -- mux/demux control to ddr memory controller.
  signal ddr_intf_mux_wr_sel_d    : std_logic_vector(1 downto 0);
  signal ddr_intf_demux_rd_sel_d  : std_logic_vector(2 downto 0);
  signal ddr_intf_mux_wr_sel_r    : std_logic_vector(1 downto 0);
  signal ddr_intf_demux_rd_sel_r  : std_logic_vector(2 downto 0);
     
  -- rd control to shared input memory
  signal mem_shared_in_enb_d      : std_logic;
  signal mem_shared_in_enb_r      : std_logic;
    
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
  signal f_h_fifo_wr_en_d            : std_logic;
  signal f_h_fifo_rd_en_d            : std_logic;
  signal f_h_fifo_wr_en_r            : std_logic;
  signal f_h_fifo_rd_en_r            : std_logic;
    
  --  rd,wr control to Fdbk FIFO
  signal fdbk_fifo_wr_en_d           : std_logic;
  signal fdbk_fifo_wr_en_r           : std_logic;
  
  architecture struct of mem_st_machine_controller is
    
  BEGIN
  
  ----------------------------------------
  -- Main State Machine (Comb)
  ----------------------------------------  	
       st_mach_controller : process(
       	  state_counter_1_r,
       	  block_start_i,
       	  ps_controller
       ) begin
       	
         case ps_controller is
       	
            when state_init =>
       	
            when others =>
       	
         end case;
       	 	
       end process st_mach_controller;
       
  -----------------------------------------
  -- Main State Machine (Reg)
  -----------------------------------------

       registers_st_mach_controller : process( clk_i, rst_i )
         begin
            if( rst_i = '1') then

              clear_state_counter_1_r         <= '1';
              
              -- app interface to ddr controller
        			app_cmd_r         <=          '000'; --: out std_logic_vector(2 downto 0);
        			app_en_r          <=          '0';   --: out std_logic;
        			app_wdf_end_r     <=          '0';   --: out std_logic;
        			app_wdf_en_r      <=          '0';   --: out std_logic;
        			app_wdf_wren_r    <=          '0';   --: out std_logic_vector(2 downto 0);
    	
        			-- mux/demux control to ddr memory controller.
        			ddr_intf_mux_wr_sel_r    <=    '00';  --: out std_logic_vector(1 downto 0);
        			ddr_intf_demux_rd_sel_r  <=    '000'; --: out std_logic_vector(2 downto 0);
     
        			-- rd control to shared input memory
        			mem_shared_in_enb_r      <=   '0';    --: out std_logic;
    
        			-- mux/demux control to front and Backend modules  
        			front_end_demux_fr_fista_r  <=  '0'; --: out std_logic;
        			front_end_mux_to_fft_r      <=  '00; --: out std_logic_vector(1 downto 0);
        			back_end_demux_fr_fh_mem_r  <=  '0'; --: out std_logic;
        			back_end_demux_fr_fv_mem_r  <=  '0'; --: out std_logic;
        			back_end_mux_to_front_end_r <=  '0'; --: out std_logic;
    
        			-- rd,wr control to F*(H) F(H) FIFO 
        			f_h_fifo_wr_en_r            <=  '0'; --: out std_logic;
        			f_h_fifo_rd_en_r            <=  '0'; --: out std_logic;
    
        			-- rd,wr control to F(V) FIFO
        			f_h_fifo_wr_en_r            <=  '0'; --: out std_logic;
        			f_h_fifo_rd_en_r            <=  '0'; --: out std_logic;
    
        			--  rd,wr control to Fdbk FIFO
        			fdbk_fifo_wr_en_r           <=  '0'; --: out std_logic;
        			fdbk_fifo_rd_en_r           <=  '0'; --: out std_logic;
        			
            elsif(clk_i'event and clk_i = '1') then
            	
            	-- app interface to ddr controller
        			app_cmd_r         <=          app_cmd_d;        --: out std_logic_vector(2 downto 0);
        			app_en_r          <=          app_en_d;         --: out std_logic;
        			app_wdf_end_r     <=          app_wdf_end_d;    --: out std_logic;
        			app_wdf_en_r      <=          app_wdf_en_d;     --: out std_logic;
        			app_wdf_wren_r    <=          app_wdf_wren_d;   --: out std_logic_vector(2 downto 0);
    	
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
        			f_h_fifo_wr_en_r            <=  f_h_fifo_wr_en_d; --: out std_logic;
        			f_h_fifo_rd_en_r            <=  f_h_fifo_rd_en_d; --: out std_logic;
    
        			--  rd,wr control to Fdbk FIFO
        			fdbk_fifo_wr_en_r           <=  fdbk_fifo_wr_en_d; --: out std_logic;
            	
            	
            end if;
       end process registers_st_mach_controller;
       
  -----------------------------------------
  -- Main State Machine Decoder
  -----------------------------------------
  st_mach_controller_decoder : process( decode_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "000001" => -- INIT state
  			  			
  	  	-- app interface to ddr controller.
        app_cmd_o         <=          '000'; --"Don't Care'--: out std_logic_vector(2 downto 0);
        app_en_o          <=          '0';   -- No wr/rd  --: out std_logic;
        app_wdf_end_o     <=          '0';   -- No wr     --: out std_logic;
        app_wdf_en_o      <=          '0';   -- No wr     --: out std_logic;
        app_wdf_wren_o    <=          '0';   -- No wr     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_o    <=    '00';  --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o  <=    '000'; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_o      <=   '0';    -- No rd --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_o  <=  '0'; --"Don't Care'  --: out std_logic;
        front_end_mux_to_fft_o      <=  '00; --"Don't Care'  --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o  <=  '0'; --"Don't Care'  --: out std_logic;
        back_end_demux_fr_fv_mem_o  <=  '0'; --"Don't Care'  --: out std_logic;
        back_end_mux_to_front_end_o <=  '0'; --"Don't Care'  --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_o           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_o           <=  '0'; -- No rd --: out std_logic;
      
     
      when "000010" => -- Write in B
      	
      	-- app interface to ddr controller
        app_cmd_o         <=          '000'; --Wr B Mem      --: out std_logic_vector(2 downto 0);
        app_en_o          <=          '1';   --Wr B Mem      --: out std_logic;
        app_wdf_end_o     <=          '0';   --Wr B Mem      --: out std_logic;
        app_wdf_en_o      <=          '1';   --Wr B Mem      --: out std_logic;
        app_wdf_wren_o    <=          '1';   --Wr B Mem      --: out std_logic_vector(2 downto 0);
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_o    <=    '00';  -- Wr B mem    --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o  <=    '000'; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_o      <=   '0';    -- No rd  --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_o  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_o      <=  '01; --Select Init  --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_o <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No wr --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No wr --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_o           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_o           <=  '0'; -- No wr --: out std_logic;
                  
      when "000011" => -- Wait for FFT Completion, after write in B
      	               -- Wait for FFT Completion, after Read out 1-D FWD AV Col ( Step 1)
  			
  	  	-- app interface to ddr controller
        app_cmd_o         <=          '000'; --"Don't Care'--: out std_logic_vector(2 downto 0);
        app_en_o          <=          '0';   -- No wr/rd  --: out std_logic;
        app_wdf_end_o     <=          '0';   -- No wr     --: out std_logic;
        app_wdf_en_o      <=          '0';   -- No wr     --: out std_logic;
        app_wdf_wren_o    <=          '0';   -- No wr     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_o    <=    '00';  --"Don't Care' --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o  <=    '000'; --"Don't Care' --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_o      <=   '0';    -- No rd --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_o  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_o      <=  '11; -- Select Fdbk --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_o <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_o           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_o           <=  '0'; -- No rd --: out std_logic;
        
      when "000100" =>  --Write in 1-D FWD AV Row ( Step 0)  -- Start of A Calculation --
      	                --  Write in 2-D FWD AV Col ( Step 2)
      	                   
  			
  	  	-- app interface to ddr controller
        app_cmd_o         <=          '000'; --wr B Mem         --: out std_logic_vector(2 downto 0);
        app_en_o          <=          '1';   --wr B Mem         --: out std_logic;
        app_wdf_end_o     <=          '0';   --wr B Mem         --: out std_logic;
        app_wdf_en_o      <=          '1';   --wr B Mem         --: out std_logic;
        app_wdf_wren_o    <=          '1';   --wr B Mem         --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_o    <=    '01';  --rd 1-D Fwd Av Row --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o  <=    '000'; --"Don't Care'      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_o      <=   '1';   --rd B Mem         --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_o  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_o      <=  '00; --"Don't Care' --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_o <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_o           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_o           <=  '0'; -- No rd --: out std_logic;
      	
      when "000101" => --  Read out 1-D FWD AV Col ( Step 1)
      	  			
  	  	-- app interface to ddr controller
        app_cmd_o         <=          '001'; --rd B Mem         --: out std_logic_vector(2 downto 0);
        app_en_o          <=          '1';   --rd B Mem         --: out std_logic;
        app_wdf_end_o     <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_en_o      <=          '0';   --"Don't Care'     --: out std_logic;
        app_wdf_wren_o    <=          '0';   --"Don't Care'     --: out std_logic;
    	
        -- mux/demux control to ddr memory controller.
        ddr_intf_mux_wr_sel_o    <=    '01';  --"Don't Care'           --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o  <=    '100'; --rd 1-D Fwd Av col      --: out std_logic_vector(2 downto 0);
     
        -- rd control to shared input memory
        mem_shared_in_enb_o      <=   '0';    -- No rd                 --: out std_logic;
    
        -- mux/demux control to front and Backend modules  
        front_end_demux_fr_fista_o  <=  '0'; --"Don't Care' --: out std_logic;
        front_end_mux_to_fft_o      <=  '11; -- Select Fdbk --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_demux_fr_fv_mem_o  <=  '0'; --"Don't Care' --: out std_logic;
        back_end_mux_to_front_end_o <=  '0'; --"Don't Care' --: out std_logic;
    
        -- rd,wr control to F*(H) F(H) FIFO 
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        -- rd,wr control to F(V) FIFO
        f_h_fifo_wr_en_o            <=  '0'; -- No wr --: out std_logic;
        f_h_fifo_rd_en_o            <=  '0'; -- No rd --: out std_logic;
    
        --  rd,wr control to Fdbk FIFO
        fdbk_fifo_wr_en_o           <=  '0'; -- No wr --: out std_logic;
        fdbk_fifo_rd_en_o           <=  '0'; -- No rd --: out std_logic;
      	
      --when "000110" => --  Wait for FFT completion --SAME as "000011"
      --when "000111" => --  Write in 2-D FWD AV Col ( Step 2) -- SAME as "000100"
      	
  
  ----------------------------------------
  -- Counters
  ----------------------------------------

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

    ----------------------------------------
    -- Assignments
    ----------------------------------------
       --bp_d  <= std_logic_vector(to_unsigned(state_counter_1_r,bp_d'length));
       --bit_plane_int <= to_integer(unsigned(bit_planes_d ));


           	
       -- app interface to ddr controller
       app_cmd_o         <=          app_cmd_r;        --: out std_logic_vector(2 downto 0);
       app_en_o          <=          app_en_r;         --: out std_logic;
       app_wdf_end_o     <=          app_wdf_end_r;    --: out std_logic;
       app_wdf_en_o      <=          app_wdf_en_r;     --: out std_logic;
       app_wdf_wren_o    <=          app_wdf_wren_r;   --: out std_logic_vector(2 downto 0);
    	
       -- mux/demux control to ddr memory controller.
       ddr_intf_mux_wr_sel_o    <=    ddr_intf_mux_wr_sel_r;  --: out std_logic_vector(1 downto 0);
       ddr_intf_demux_rd_sel_o  <=    ddr_intf_demux_rd_sel_r; --: out std_logic_vector(2 downto 0);
     
       -- rd control to shared input memory
       mem_shared_in_enb_o      <=   mem_shared_in_enb_r;    --: out std_logic;
    
       -- mux/demux control to front and Backend modules  
       front_end_demux_fr_fista_o  <=  front_end_demux_fr_fista_r; --: out std_logic;
       front_end_mux_to_fft_o      <=  front_end_mux_to_fft_r; --: out std_logic_vector(1 downto 0);
       back_end_demux_fr_fh_mem_o  <=  back_end_demux_fr_fh_mem_r; --: out std_logic;
       back_end_demux_fr_fv_mem_o  <=  back_end_demux_fr_fv_mem_r; --: out std_logic;
       back_end_mux_to_front_end_o <=  back_end_mux_to_front_end_r; --: out std_logic;
    
       -- rd,wr control to F*(H) F(H) FIFO 
       f_h_fifo_wr_en_o            <=  f_h_fifo_wr_en_r; --: out std_logic;
       f_h_fifo_rd_en_o            <=  f_h_fifo_rd_en_r; --: out std_logic;
    
       -- rd,wr control to F(V) FIFO
       f_h_fifo_wr_en_o            <=  f_h_fifo_wr_en_r; --: out std_logic;
       f_h_fifo_rd_en_o            <=  f_h_fifo_rd_en_r; --: out std_logic;
    
       --  rd,wr control to Fdbk FIFO
       fdbk_fifo_wr_en_o           <=  fdbk_fifo_wr_en_r; --: out std_logic;

       	
       	-- FIXED value
        app_wdf_mask_o  <= (others => '0');
       
       
            	
  END architecture struct; 
    