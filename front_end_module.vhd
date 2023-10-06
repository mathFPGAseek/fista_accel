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
    
    fr_back_end_data_i              : in std_logic_vector(79 downto 0);
    fr_back_end_data2_i             : in std_logic_vector(79 downto 0);
    fr_fista_data_i                 : in std_logic_vector(79 downto 0);
    fr_fd_back_fifo_data_i          : in std_logic_vector(79 downto 0);
    	
    fr_back_end_valid_i             : in std_logic;
    fr_back_end_valid2_i            : in std_logic;
    fr_fista_valid_i                : in std_logic;
    fr_fd_back_fifo_valid_i         : in std_logic;
    
  	
    -- Data to front end module
    to_fft_data_o                   : out std_logic_vector(79 downto 0);
    fista_accel_data_o              : out std_logic_vector(79 downto 0);
    	
    to_fft_valid_o                  : out std_logic;
    fista_accel_valid_o             : out std_logic;

    );
    
end front_end_module ;

architecture struct of front_end_module  is  
	
-- signals
signal addr_int    : std_logic_vector ( 16 downto 0 );
signal en_int      : std_logic;

signal re_dout     : std_logic_vector ( 33 downto 0 );   

--constant
constant IMAG_ZEROS : std_logic_vector(39 downto 0) := (others=> '0');


begin
  
  
    -----------------------------------------
    -- Init St mach contoller
    -----------------------------------------	
    
    U0 : entity work.init_st_machine_controller
    PORT MAP(
    	
    	clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                    => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => master_mode_i, --: in std_logic_vector(4 downto 0);                                                                                        
        mem_init_start_i                            => mem_init_start_i ,--: in std_logic;
                                           
        addr_o                                      => addr_int, --: out std_logic;
        en_o                                        => en_int --: out std_logic;
                                             
                                           
    );

    
    -----------------------------------------.
    --  init memory
    -----------------------------------------	
    -- From Python code of diffuser cam we have an init value;
    -- we will start with psf
    
   U1 : entity work.blk_mem_gen_init_0 
   PORT MAP ( 
        clka        =>     clk_i,          --: in STD_LOGIC;
        ena         =>     en_int,         --: in STD_LOGIC;
        addra       =>     addr_int,       --: in STD_LOGIC_VECTOR ( 16 downto 0 );
        douta       =>     re_dout         --: out STD_LOGIC_VECTOR ( 33 downto 0 )
    );


    
    -----------------------------------------
    --  inbound fifo
    -----------------------------------------	
    
    -----------------------------------------
    --  inbound state machine
    -----------------------------------------	
    
    -----------------------------------------
    --  Assignments
    -----------------------------------------	
     init_data_o <= IMAG_ZEROS & "000000" &  re_dout; 
            	
end  architecture struct; 
    