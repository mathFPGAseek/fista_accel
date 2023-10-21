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
-- filename: fft_engine_module.vhd
-- Initial Date: 10/14/23
-- Descr: FFT engine
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity fft_engine_module is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    master_mode_i                  : in std_logic_vector(4 downto 0);
  	
    -- Input Data to front end module
    init_valid_data_i              : in std_logic;
    init_data_i                    : in std_logic_vector(79 downto 0);    
    stall_warning_o                : out std_logic;
  
    dual_port_wr_o                 : out std_logic;  
    dual_port_addr_o               : out std_logic_vector(16 downto 0);
    dual_port_data_o               : out std_logic_vector(79 downto 0);
    	
    fft_rdy_o                      : out std_logic

    );
    
end fft_engine_module;

architecture struct of fft_engine_module is  
	
-- signals                                         
signal s_axis_config_valid_int  : std_logic;  
signal s_axis_config_trdy_int   : std_logic := '1';  
signal s_axis_config_tdata_int  : std_logic_vector(15 downto 0);                   
signal s_axis_data_tvalid_int   : std_logic; 
signal s_axis_data_trdy_int     : std_logic := '1';  
signal s_axis_data_tlast_int    : std_logic;                   
signal stall_warning_int        : std_logic;

signal dual_port_data_int       : std_logic_vector(79 downto 0);
signal m_axis_data_tvalid_int   : std_logic;
signal m_axis_data_tlast_int    : std_logic;

signal fft_rdy_int              : std_logic;


--constant
--constant IMAG_ZEROS : std_logic_vector(39 downto 0) := (others=> '0');


begin
  
  
    -----------------------------------------.
    -- FFT St mach contoller
    -----------------------------------------	 
    U0 : entity work.fft_inbound_st_machine_controller            
    PORT MAP(                                
    	                                   
    	  clk_i                  => clk_i,        -- : in std_logic; --clk_i,
        rst_i                  => rst_i,        -- : in std_logic; --rst_i,
                             
        master_mode_i          => master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
        valid_i                => init_valid_data_i,  -- : in std_logic; --
                             
        s_axis_config_valid_o  => s_axis_config_valid_int,-- : out std_logic;
        s_axis_config_trdy_i   => s_axis_config_trdy_int,-- : in std_logic;
        s_axis_config_tdata_o  => s_axis_config_tdata_int,-- : out std_logic_vector(15 downto 0);
                            
        s_axis_data_tvalid_o   => s_axis_data_tvalid_int,-- : out std_logic;
        s_axis_data_trdy_i     => s_axis_data_trdy_int,-- : in std_logic;
        s_axis_data_tlast_o    => s_axis_data_tlast_int,-- : out std_logic;
        
        m_axis_data_tlast_i    => m_axis_data_tlast_int,
        
        fft_rdy_o              => fft_rdy_int, 
                            
        stall_warning_o        => stall_warning_int-- : out std_logic;                                   
    );                     

    
    -----------------------------------------
    --  FFT Core
    -----------------------------------------	
    U1 : entity work.xfft_0 
  PORT MAP ( 
    aclk 													=>  clk_i, --: in STD_LOGIC;
    aresetn 											=>  not(rst_i), --: in STD_LOGIC;
    s_axis_config_tdata 					=>  s_axis_config_tdata_int, --: in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_axis_config_tvalid 					=>  s_axis_config_valid_int, --: in STD_LOGIC;
    s_axis_config_tready 					=>  s_axis_config_trdy_int, --: out STD_LOGIC;
    s_axis_data_tdata 						=>  init_data_i, --: in STD_LOGIC_VECTOR ( 79 downto 0 ); ???? Need to delay
    s_axis_data_tvalid 						=>  s_axis_data_tvalid_int, --: in STD_LOGIC;
    s_axis_data_tready 						=>  s_axis_data_trdy_int, --: out STD_LOGIC;
    s_axis_data_tlast 						=>  s_axis_data_tlast_int, --: in STD_LOGIC;
    m_axis_data_tdata 						=>  dual_port_data_int, --: out STD_LOGIC_VECTOR ( 79 downto 0 );
    m_axis_data_tvalid 						=>  m_axis_data_tvalid_int, --: out STD_LOGIC;
    m_axis_data_tready 						=>  '1', --: in STD_LOGIC;
    m_axis_data_tlast 						=>  m_axis_data_tlast_int, --: out STD_LOGIC;
    event_frame_started 					=>  open, --: out STD_LOGIC;
    event_tlast_unexpected 				=>  open, --: out STD_LOGIC;
    event_tlast_missing 					=>  open, --: out STD_LOGIC;
    event_status_channel_halt 		=>  open, --: out STD_LOGIC;
    event_data_in_channel_halt 		=>  open, --: out STD_LOGIC;
    event_data_out_channel_halt 	=>  open --: out STD_LOGIC
  );

    -----------------------------------------
    --  Outbound state machine
    -----------------------------------------	
    
    -----------------------------------------
    --  Assignments
    -----------------------------------------	
    dual_port_wr_o       <=  m_axis_data_tvalid_int;     
    dual_port_addr_o     <=  (others => '0');         
    dual_port_data_o     <=  dual_port_data_int; 
    
    fft_rdy_o            <=  fft_rdy_int;
     
    stall_warning_o      <=  stall_warning_int;         
        
            	
end  architecture struct; 
    