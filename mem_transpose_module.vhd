library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;


entity mem_transpose_module is
  Port (
    clk_i : in STD_LOGIC; 
    rst_i : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 );
    vouta : out STD_LOGIC;
    dbg_qualify_state_i : in STD_LOGIC
  );

end mem_transpose_module;

architecture stub of mem_transpose_module is
--attribute syn_black_box : boolean;
--attribute black_box_pad_pin : string;
--attribute syn_black_box of stub : architecture is true;
--attribute black_box_pad_pin of stub : architecture is "clka,ena,wea[0:0],addra[7:0],dina[79:0],clkb,enb,addrb[7:0],doutb[79:0]";
--attribute x_core_info : string;
--attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";.

-- For verification and synthesis
signal data_out_r                   : std_logic_vector( 79 downto 0);
signal enable_read_rr               : std_logic;


-------------------------------------------------	
-------------------------------------------------
-------------------------------------------------
-- For Verification Only Code below
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

constant MAX_SAMPLES : integer := 2**8;  -- maximum number of samples in a frame
--constant IP_WIDTH    : integer := 34;
constant IP_WIDTH    : integer := 40;
constant MEM_WIDTH   : integer := IP_WIDTH*2 -1;
type     MEM_ARRAY is array(0 to  MAX_SAMPLES-1,0 to MAX_SAMPLES-1) of std_logic_vector(MEM_WIDTH downto  0);
type     bit_addr is array ( 0 to MAX_SAMPLES-1) of integer;
type     result_type is ( '0', '1');
signal   fft_raw_mem : MEM_ARRAY;
file     write_file : text;
signal   dummy  : std_logic := '1';
signal   write_fft_1d_raw_done : result_type;

constant PAD_ZEROS  : std_logic_vector(5 downto 0) := (others=> '0');
	
-- counters

signal state_counter_2_r            : integer;
--signal state_counter_2_rr           : integer;
--signal state_counter_2_rrr          : integer;
signal clear_state_counter_2_d      : std_logic;
signal clear_state_counter_2_r      : std_logic;
signal clear_state_counter_2_rr     : std_logic; 
signal enable_state_counter_2_d     : std_logic;
signal enable_state_counter_2_r     : std_logic;

signal state_counter_1_r            : integer;
signal state_counter_1_rr           : integer;
signal state_counter_1_rrr          : integer;
signal clear_state_counter_1_r      : std_logic; -- no _d because comes from registered last event


-- misc for verification
signal enable_read                  : std_logic;
signal enable_read_r                : std_logic;
--signal enable_read_rr               : std_logic;
signal delay_ena                    : std_logic;
signal falling_valid_event_d        : std_logic;
signal falling_valid_event_r        : std_logic;
signal falling_valid_event_rr       : std_logic;
signal falling_valid_event_rrr      : std_logic;
signal falling_valid_event_int      : std_logic;
signal qualify_state_r              : std_logic;
signal qualify_state_rr             : std_logic;
signal qualify_state_rrr            : std_logic;
signal qualify_state_rrrr           : std_logic;
signal qualify_state_int            : std_logic;
                  
	
	-------------------------------------------------
	-- Function Write to a file the mem contents to check
	-------------------------------------------------
	--impure function writeToFileMemRawContents(  signal fft_mem   : in MEM_ARRAY;
	--	                                          signal fft_bin_center_addr : in bit_addr) return result_type is
  impure function writeToFileMemRawContents(  signal fft_mem   : in MEM_ARRAY) return result_type is
  
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   --variable k            : integer;
	   --variable fft_spec     : MEM_ARRAY;
	   variable data_write_var : bit_vector(79 downto 0);
	   begin
	   	 	--for i in  0 to MAX_SAMPLES-1 loop
	      --   for j in 0 to MAX_SAMPLES-1 loop
	      --      k := fft_bin_center_addr(j);
	      --      fft_spec(i,k) := (fft_mem(i,j));
	      --   end loop;
	      --end loop;
	     file_open(write_file,"col_rd_mem_raw_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  --data_write_var := to_bitvector(fft_spec(i,j));
	                  data_write_var := to_bitvector(fft_mem(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file,mem_line_var);                  
	                  --report" Start writing to file ";
	              end loop;
	          end loop;
	      done := 1;
	      file_close(write_file);
	      report" Done writing to file ";	  
  	    return result;  	       
  end function  writeToFileMemRawContents;


-------------------------------------------------	
-------------------------------------------------
-------------------------------------------------.
-- For Verification Only Code Above
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

	
	
begin
	
  -----------------------------------------
  -- Transpose mem_intf
  -----------------------------------------	
  	
  u1 : entity work.blk_mem_image_gen_0 
  PORT MAP ( 
  clka  => clk_i,                     --clka : in STD_LOGIC;
  ena   => ena,                       --ena : in STD_LOGIC;
  wea   => wea,                       --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => addra,                     --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => dina,                      --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_out_r                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );


-----------------------------------------------------------------
-----------------------------------------------------------------    
-----------------------------------------------------------------
--Verification             ,....,                    Verification
--Verification           ,:::::::                    Verification
--Verification          ,::/^\"``.                   Verification
--Verification         ,::/, `   e`.                 Verification
--Verification        ,::; |        '.               Verification
--Verification        ,::|  \___,-.  c)              Verification
--Verification        ;::|     \   '-'               Verification
--Verification        ;::|      \                    Verification
--Verification        ;::|   _.=`\                   Verification
--Verification        `;:|.=` _.=`\                  Verification
--Verification          '|_.=`   __\                 Verification
--Verification          `\_..==`` /                  Verification
--Verification           .'.___.-'.                  Verification
--Verification          /          \                 Verification
--Verification         ('--......--')                Verification
--Verification         /'--......--'\                Verification
--Verification         `"--......--"`                Verification
--Verification                                       Verification
--Verification        Do not synthesize the code     Verification
--Verification               below                   Verification
--Verification        Only for verification!         Verification
--Verification                                       Verification
--Verification        Verify Block mem Rd            Verification
--Verification                                       Verification
--Verification       Use in conjuntion with Matlab   Verification
--Verification          folder:                      Verification
--Verification          file: verify_block_mem_rd.m  Verification
-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------
 enable_read <= ena and not(wea(0));
 	
 	
 	delay_enable_read_reg  : process(clk_i, rst_i)
 		begin
 			if( rst_i = '1') then
 				enable_read_r     <= '0';
 				enable_read_rr    <= '0';
 				
 			elsif(clk_i'event and clk_i = '1') then
 				enable_read_r     <= enable_read;
 				enable_read_rr    <= enable_read_r;
 			end if;
 				
  end process delay_enable_read_reg;
  ----------------------------------------
  -- Counters for fast address Verification
  ----------------------------------------
  -- counter for lower index
  state_counter_1 : process( clk_i, rst_i,clear_state_counter_1_r)
    begin
      if  ( rst_i = '1' )   then
          state_counter_1_r       <=  0 ;
          state_counter_1_rr      <=  0 ;
          state_counter_1_rrr     <=  0 ;
      elsif( clear_state_counter_1_r = '1' ) then
          state_counter_1_r       <=  0 ;
          state_counter_1_rr      <=  0 ;
          state_counter_1_rrr     <=  0 ;              
      elsif( clk_i'event and clk_i = '1') then
        if (( enable_read = '1') or (enable_read_r = '1')) then
          state_counter_1_r       <=  state_counter_1_r + 1;
          state_counter_1_rr      <=  state_counter_1_r;
          state_counter_1_rrr     <=  state_counter_1_rr;
        end if;
      end if;
  end process state_counter_1;


 ----------------------------------------
 -- Logic for counter 2( slow addr)
 ----------------------------------------
  
  -- Falling edge of mvalid.
  falling_edge_valid : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1') then
  			delay_ena <= '0';
  		elsif(clk_i'event and clk_i = '1') then
  			delay_ena <= enable_read;
  		end if;
  end process falling_edge_valid;
  
  falling_valid_event_int <= not(enable_read) and delay_ena;
  
  falling_edge_mvalid_reg : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1')	then
  			falling_valid_event_r   <= '0';
  			falling_valid_event_rr  <= '0';
  			falling_valid_event_rrr <= '0';

  	  elsif(clk_i'event and clk_i = '1') then
  	  	falling_valid_event_r   <= falling_valid_event_d;
  	  	falling_valid_event_rr  <= falling_valid_event_r;
  	  	falling_valid_event_rrr <= falling_valid_event_rr;

  	  end if;
  end process falling_edge_mvalid_reg;
  
  -- register signal for: Read state ( filter out all writes)
  
  falling_valid_event_d <= falling_valid_event_int and qualify_state_int; -- special logic to 
                                                                          -- capture read state
  delay_qualify_state_reg : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1') then
  			qualify_state_r    <= '0';
  			qualify_state_rr   <= '0';
  			qualify_state_rrr  <= '0';
  			qualify_state_rrrr <= '0';
  		elsif(clk_i'event and clk_i = '1')then
  			qualify_state_r    <= dbg_qualify_state_i;
  			qualify_state_rr   <= qualify_state_r;
  			qualify_state_rrr  <= qualify_state_rr;
  			qualify_state_rrrr <= qualify_state_rrr; 			
  		end if;
  end process delay_qualify_state_reg;
  
  qualify_state_int <= qualify_state_rrrr;
 ----------------------------------------
 -- Counter for slow address
 ----------------------------------------
  state_counter_2 : process( clk_i, rst_i,clear_state_counter_2_rr)
    begin
      if ( rst_i = '1' ) then
          state_counter_2_r       <=  0;
          --state_counter_2_rr      <=  0;
          --state_counter_2_rrr     <=  0;
      elsif(clear_state_counter_2_rr = '1') then
          state_counter_2_r       <=  0;
          --state_counter_2_rr      <=  0;
          --state_counter_2_rrr     <=  0;
      elsif( clk_i'event and clk_i = '1') then
         if ( falling_valid_event_rrr = '1') then
          state_counter_2_r       <=  state_counter_2_r + 1;
          --state_counter_2_rr      <=  state_counter_2_r;
          --state_counter_2_rrr     <=  state_connter_2_rr;
         end if;
      end if;
  end process state_counter_2;
  
   ----------------------------------------
  -- clear counter fast address
  ----------------------------------------.
    clear_state_counter_1_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			clear_state_counter_1_r  <=  '0';
  	  elsif(clk_i'event and clk_i  = '1') then
        clear_state_counter_1_r   <=  falling_valid_event_r;
  	  end if;
  end process clear_state_counter_1_reg;
  
  
   ----------------------------------------
  -- Decode terminal count
  ----------------------------------------.
  decode_terminal_count : process(state_counter_2_r)
  	begin
  		if (  state_counter_2_r = MAX_SAMPLES ) then
  			clear_state_counter_2_d <= '1';
  	  else
  	  	clear_state_counter_2_d <= '0';
  	  end if;
  end process decode_terminal_count;
  
  
   ----------------------------------------
  -- Delay terminal count
  ----------------------------------------
   delay_terminal_count : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			clear_state_counter_2_r  <=  '0';
  			clear_state_counter_2_rr <=  '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	clear_state_counter_2_r  <=  clear_state_counter_2_d;
  	  	clear_state_counter_2_rr <=  clear_state_counter_2_r; 
  	  end if;
  end process delay_terminal_count;
  
   -----------------------------------------------------------------------
  -- Store read outputs from memory; We are reading an array built by  process record_outputs
  -----------------------------------------------------------------------.
  --RamProcRawData : process(clk_i,rst_i,falling_valid_event_d)
  RamProcRawData : process(clk_i,rst_i)

    begin
  	  if ( rst_i = '1' ) then
         --fft_raw_mem <= (Others => '0');
         dummy <= '1';
      --elsif(falling_valid_event_d = '1') then
      --   --fft_raw_mem <= (Others => '0');
      --   fft_raw_mem(state_counter_1_r,state_counter_2_r) <= data_out_r;
  	  --elsif enable_read = '1' then 		
  	  elsif enable_read_rr = '1' then 		
   		--fft_raw_mem(state_counter_1_r,state_counter_2_r) <= data_out_r;  				  	  
  		--fft_raw_mem(state_counter_1_rrr,state_counter_2_rrr) <= data_out_r;  
  		  fft_raw_mem(state_counter_1_rrr,state_counter_2_r) <= data_out_r;  				  
				  
  		end if;
   end process RamProcRawData;  
    
  -------------------------------------------------
	-- Write to a file the mem contents to check
	-------------------------------------------------  
data_read : process(clear_state_counter_2_rr)

  --report " This is a read of one frame

  begin
   if (clear_state_counter_2_rr  = '1') then -- Have completed MAX_SAMPLE FFT Computations( 1-D)o
        --write_fft_1d_raw_done <= writeToFileMemRawContents(fft_raw_mem,fft_bin_seq_addr);	
          write_fft_1d_raw_done <= writeToFileMemRawContents(fft_raw_mem);	
       report " Done Reads for one frame";
   end if;
end process data_read;

 	 	
  ----------------------------------------
  -- Assignments
  ----------------------------------------.
  
  douta <=  data_out_r;  
  vouta <=  enable_read_rr;
 
  
end architecture stub;