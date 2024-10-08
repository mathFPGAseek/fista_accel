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
-- filename: h_h_star_mult_eng.vhd
-- Initial Date: 7/4/24
-- Descr: 
-- H,H* mult proc: mult hadmard w/ trans  & write to trans_mem_buffer
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity h_h_star_mult_eng is
--generic(
--	     g_USE_DEBUG_i  : in natural := 1);
    port (
   
    clk_i                             : in std_logic;
		rst_i                             : in std_logic;
		master_mode_i                     : in std_logic_vector(4 downto 0);
		       
		-- FIFO inputs
		fifo_high_ovf_i                   : in std_logic;
		fifo_high_uf_i                    : in std_logic;
		       
		fifo_low_ovf_i                    : in std_logic;
		fifo_low_uf_i                     : in std_logic;	       
		       
		-- port 1 inputs
		       
		port_1_valid_in_i                 : in std_logic;
		port_1_data_in_i                  : in std_logic_vector(79 downto 0);  
		       
		-- port 2 inputs
		       
		port_2_valid_in_i                 : in std_logic;
		port_2_data_in_i                  : in std_logic_vector(79 downto 0); 
		       
		-- FIFO outputs
		fifo_high_rd_en_o                 : out std_logic;
		fifo_low_rd_en_o                  : out std_logic;
		       
		-- Data out
		valid_out_o                       : out std_logic;
		addr_out_o                        : out std_logic_vector(16 downto 0);
		data_out_o                        : out std_logic_vector(79 downto 0);
		       
		-- rdy flag
		rdy_o                             : out std_logic
		      

    );
    
end h_h_star_mult_eng;

architecture struct of h_h_star_mult_eng is




begin
	
    -- FIFO outputs
		fifo_high_rd_en_o     <= '0';
		fifo_low_rd_en_o      <= '0';
		       
		-- Data out
		valid_out_o           <= '0';
		addr_out_o            <= (others => '0');
		data_out_o            <= (others => '0');
		       
		-- rdy flag
		rdy_o                 <= '0';
 
    -----------------------------------------.
    -- H H_star St mach contoller
    -----------------------------------------	 
    --U0 : entity work.h_hstar_inbound_st_machine_controller            
    --PORT MAP(                                
    --	                                   
    --	  clk_i                  => clk_i,        -- : in std_logic; --clk_i,
    --    rst_i                  => rst_i,        -- : in std_logic; --rst_i,
    --                         
    --    master_mode_i          => master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
    --    valid_i                => port_1_valid_in_i,  -- : in std_logic; --
    --                               
    --    s_axis_config_valid_o  => s_axis_config_valid_int,-- : out std_logic;
    --    s_axis_config_trdy_i   => s_axis_config_trdy_int,-- : in std_logic;
    --    s_axis_config_tdata_o  => s_axis_config_tdata_int,-- : out std_logic_vector(15 downto 0);
    --                        
    --    s_axis_data_tvalid_o   => s_axis_data_tvalid_int,-- : out std_logic;
    --    s_axis_data_trdy_i     => s_axis_data_trdy_int,-- : in std_logic;
    --    s_axis_data_tlast_o    => s_axis_data_tlast_int,-- : out std_logic;
    --    
    --    m_axis_data_tlast_i    => m_axis_data_tlast_int,
    --    
    --    h_h_star_rdy_o         => rdy_o, 
    --                        
    --    stall_warning_o        => stall_warning_int-- : out std_logic;                                   
    --);
    	

--U1 : entity work.cmpy_0 
--PORT MAP ( 
--    aclk                  =>    clk_i, --: in STD_LOGIC;
--    aresetn               =>    rst_i, --: in STD_LOGIC;
--    s_axis_a_tvalid       =>    port_1_valid_in_i, --: in STD_LOGIC;
--    s_axis_a_tlast        =>    s_axis_a_tlast_int, --: in STD_LOGIC;
--    s_axis_a_tdata        =>    port_1_data_in_i, --: in STD_LOGIC_VECTOR ( 79 downto 0 );
--    s_axis_b_tvalid       =>    port_2_valid_in_i, --: in STD_LOGIC;
--    s_axis_b_tlast        =>    s_axis_b_tlast_int, --: in STD_LOGIC;
--    s_axis_b_tdata        =>    port_2_data_in_i, --: in STD_LOGIC_VECTOR ( 79 downto 0 );
--    m_axis_dout_tvalid    =>    m_axis_dout_tvalid_int, --: out STD_LOGIC;
--    m_axis_dout_tlast     =>    m_axis_dout_tlast_int, --: out STD_LOGIC;
--    m_axis_dout_tdata     =>    m_axis_dout_tdata_int --: out STD_LOGIC_VECTOR ( 79 downto 0 )
--  );                     
                       
                       
                        
                       
                     
                      
end architecture struct;	