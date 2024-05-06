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
-- filename: front_end_module.vhd
-- Initial Date: 10/6/23
-- Descr: Select Data for FFT 
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity front_end_module is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	          : in std_logic;
    rst_i               	          : in std_logic;
    
    master_mode_i                   : in std_logic_vector(4 downto 0);
    
    fr_init_data_i                  : in std_logic_vector(79 downto 0);
    fr_back_end_data_i              : in std_logic_vector(79 downto 0);
    fr_back_end_data2_i             : in std_logic_vector(79 downto 0);
    fr_fista_data_i                 : in std_logic_vector(79 downto 0);
    fr_fd_back_fifo_data_i          : in std_logic_vector(79 downto 0);
    
    fr_init_data_valid_i            : in std_logic;	
    fr_back_end_valid_i             : in std_logic;
    fr_back_end_valid2_i            : in std_logic;
    fr_fista_valid_i                : in std_logic;
    fr_fd_back_fifo_valid_i         : in std_logic;
    
  	
    -- Data to front end module
    to_fft_data_o                   : out std_logic_vector(79 downto 0);
    fista_accel_data_o              : out std_logic_vector(79 downto 0);
    	
    to_fft_valid_o                  : out std_logic;
    fista_accel_valid_o             : out std_logic

    );
    
end front_end_module ;

architecture struct of front_end_module  is  
	
-- signals

signal mux_data_select_d          : std_logic_vector(2 downto 0);
signal mux_data_select_r          : std_logic_vector(2 downto 0); 
signal mux_out_to_fft_data_d      : std_logic_vector(79 downto 0);  
signal mux_out_to_fft_data_r      : std_logic_vector(79 downto 0);

	
signal mux_control_select_d       : std_logic_vector(2 downto 0);
signal mux_control_select_r       : std_logic_vector(2 downto 0);   
signal mux_out_to_fft_control_d   : std_logic;	
signal mux_out_to_fft_control_r   : std_logic;

signal fr_init_data_int           : std_logic_vector(79 downto 0);


constant PAD_ZEROS  : std_logic_vector(5 downto 0) := (others=> '0');

   
begin

-- correct alignment from inbound flow

 fr_init_data_int <= PAD_ZEROS & fr_init_data_i(79 downto 46) & PAD_ZEROS & fr_init_data_i(39 downto 6);	
-----------------------------------------.
-----------------------------------------
-- DATA PATH
-----------------------------------------
-----------------------------------------			
	
	
	  -----------------------------------------
    -- Mux Data decoder
    -----------------------------------------	
    mux_data_select_to_fft : process( master_mode_i )
    	begin
    		
    	case master_mode_i is
    		
    		when "00000" => -- A-1D-FWD-WR
    			
    			mux_data_select_d <= "000";
    		
    	  when "00001" =>
    	  	
    	  	mux_data_select_d <= "100";
    			
    	  when others =>
    	  	
    	  	mux_data_select_d <= "111";
    	  	
    	end case;
    		
    		
    end process mux_data_select_to_fft;
    
    -----------------------------------------
    -- Mux Data decoder registers
    -----------------------------------------	
    mux_data_select_to_fft_registers : process(clk_i, rst_i)
    	
    	begin
    		
    		if( rst_i = '1') then
    			
    		  mux_data_select_r <= "000";
    		  
    		elsif( clk_i'event and clk_i = '1') then
    			
    			mux_data_select_r <= mux_data_select_d;
    			
    		end if;
    			
    end process mux_data_select_to_fft_registers;
  
    -----------------------------------------
    -- Mux output to FFT
    -----------------------------------------.	
    mux_data_to_fft : process (mux_data_select_r,
    	                         fr_init_data_int,
    	                         fr_back_end_data_i,
    	                         fr_back_end_data2_i,
    	                         fr_fista_data_i,
    	                         fr_fd_back_fifo_data_i )
    	begin
    		
    		case mux_data_select_r is
    			
    			
    			when "000" =>
    				
    				--mux_out_to_fft_data_d <=  fr_init_data_i;
    			  mux_out_to_fft_data_d <=  fr_init_data_int;

    				
    			when "001" =>
    				
    				mux_out_to_fft_data_d <=  fr_back_end_data_i;  				
    				
    			when "010" =>
    				
    				mux_out_to_fft_data_d <=  fr_back_end_data2_i;  				
    				
    		  when "011" =>
    		  	
    		    mux_out_to_fft_data_d <=  fr_fista_data_i;
    		  	   		  	
    		  when "100" =>
    		  	
    		  	mux_out_to_fft_data_d <=  fr_fd_back_fifo_data_i;
    		  	   		  	
    		  when others => 
    		  	
    		  	mux_out_to_fft_data_d <=  fr_init_data_int;
    		  	
        end case;
    end process mux_data_to_fft;
   
    -----------------------------------------
    -- Mux output to FFT Registers
    -----------------------------------------	 		  	
    mux_data_to_fft_registers : process(clk_i, rst_i)
    	begin
    		
    		if ( rst_i = '1') then
    			 mux_out_to_fft_data_r <= (others=> '0');
    			 	
    		elsif(clk_i'event and clk_i = '1') then
    			
    			 mux_out_to_fft_data_r <= mux_out_to_fft_data_d;
    			 
    		end if;
    			
    end process mux_data_to_fft_registers;
    
-----------------------------------------
-----------------------------------------
-- CONTROL PATH
-----------------------------------------
-----------------------------------------	

	  -----------------------------------------
    -- Mux Data decoder
    -----------------------------------------	
    mux_control_select_to_fft : process( master_mode_i )
    	begin
    		
    	case master_mode_i is
    		
    		when "00000" => -- A-1D-FWD-WR
    			
    			mux_control_select_d <= "000";
    	
    	 		
    		when "00001" => -- A-1D-FWD-WR
    			
    			mux_control_select_d <= "100";
    			
    			
    	  when others =>
    	  	
    	  	mux_control_select_d <= "111";
    	  	
    	end case;
    		
    		
    end process mux_control_select_to_fft;
    
    -----------------------------------------
    -- Mux Data decoder registers
    -----------------------------------------	
    mux_control_select_to_fft_registers : process(clk_i, rst_i)
    	
    	begin
    		
    		if( rst_i = '1') then
    			
    		  mux_control_select_r <= "000";
    		  
    		elsif( clk_i'event and clk_i = '1') then
    			
    			mux_control_select_r <= mux_control_select_d;
    			
    		end if;
    			
    end process mux_control_select_to_fft_registers;
  
    -----------------------------------------
    -- Mux control output to FFT
    -----------------------------------------..	
    mux_control_to_fft : process(mux_control_select_r,
    														 fr_init_data_valid_i,
    														 fr_back_end_valid_i,
    														 fr_back_end_valid2_i,
    														 fr_fista_valid_i,
    														 fr_fd_back_fifo_valid_i )
    	begin
    		
    		case mux_control_select_r is
    			
    			
    			when "000" =>
    				
    				mux_out_to_fft_control_d <=  fr_init_data_valid_i;
    				
    			when "001" =>
    				
    				mux_out_to_fft_control_d <=  fr_back_end_valid_i; 				
    				
    			when "010" =>
    				
    				mux_out_to_fft_control_d <=  fr_back_end_valid2_i;  				
    				
    		  when "011" =>
    		  	
    		    mux_out_to_fft_control_d <=  fr_fista_valid_i;
    		  	   		  	
    		  when "100" =>
    		  	
    		  	mux_out_to_fft_control_d <=  fr_fd_back_fifo_valid_i;
    		  	   		  	
    		  when others => 
    		  	
    		  	mux_out_to_fft_control_d <=  fr_init_data_valid_i;
    		  	
        end case;
    end process mux_control_to_fft;
   
    -----------------------------------------
    -- Mux  control output to FFT Registers
    -----------------------------------------	 		  	
    mux_control_to_fft_registers : process(clk_i, rst_i)
    	begin
    		
    		if ( rst_i = '1') then
    			 mux_out_to_fft_control_r <= '0';
    			 	
    		elsif(clk_i'event and clk_i = '1') then
    			
    			 mux_out_to_fft_control_r <= mux_out_to_fft_control_d;
    			 
    		end if;
    			
    end process mux_control_to_fft_registers;    
    
    -----------------------------------------.
    --  Assignments
    -----------------------------------------	
     to_fft_data_o         <= mux_out_to_fft_data_r;
     fista_accel_data_o    <= mux_out_to_fft_data_r;
     
     to_fft_valid_o        <= mux_out_to_fft_control_r;
     fista_accel_valid_o  <= mux_out_to_fft_control_r; 
            	
end  architecture struct; 
    