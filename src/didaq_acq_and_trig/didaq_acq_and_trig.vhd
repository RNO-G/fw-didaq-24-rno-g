------
--didaq acq_and_trig module // rev0p1 041726 EJO-UCHICAGO
------
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity didaq_acq_and_trig is
	generic(
		reorder_data_flag				: in	 std_logic := '0'); 	--reorder data to be logically compatible with board RF connector mapping
	port(
		arstn                      : in   std_logic;                      -- Chip async reset active low.

      clk_wr                     : in   std_logic;                      -- The data will be pushed in at this rate which will also be 
      clk_rd                     : in   std_logic;                      -- 125MHz clock for the avalon interface                                                                                                                                               
      clk_trig							: in	 std_logic; 							-- equal to clk_wr/2. Run trigger logic on a slower clock 
      -- Data from the JESD link
      -- All of these re in the clk_wide domain                                                          
      adc_0_wide_data            : in  std_logic_vector(31 downto 0);   -- The data format is big endian, where the              
      adc_data_valid      			: in  std_logic_vector(23 downto 0);   -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                                        -- octet/sample is placed in bit [7:0].                                                                                                                          
      adc_1_wide_data            : in  std_logic_vector(31 downto 0);                                                                                         
      adc_2_wide_data            : in  std_logic_vector(31 downto 0);                                   
      adc_3_wide_data            : in  std_logic_vector(31 downto 0);                                                                           
      adc_4_wide_data            : in  std_logic_vector(31 downto 0);                                                                                      
      adc_5_wide_data            : in  std_logic_vector(31 downto 0);                                   
      adc_6_wide_data            : in  std_logic_vector(31 downto 0);                                   
      adc_7_wide_data            : in  std_logic_vector(31 downto 0);                                                                          
      adc_8_wide_data            : in  std_logic_vector(31 downto 0);                                                                                      
      adc_9_wide_data            : in  std_logic_vector(31 downto 0);                                   
      adc_10_wide_data           : in  std_logic_vector(31 downto 0);                                   
      adc_11_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_12_wide_data           : in  std_logic_vector(31 downto 0);                                                                                                                                                                        
      adc_13_wide_data           : in  std_logic_vector(31 downto 0);                                                                                         
      adc_14_wide_data           : in  std_logic_vector(31 downto 0);                                   
      adc_15_wide_data           : in  std_logic_vector(31 downto 0);                                                                          
      adc_16_wide_data           : in  std_logic_vector(31 downto 0);                                                                                     
      adc_17_wide_data           : in  std_logic_vector(31 downto 0);                                   
      adc_18_wide_data           : in  std_logic_vector(31 downto 0);                                   
      adc_19_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_20_wide_data           : in  std_logic_vector(31 downto 0);                                                                                 
      adc_21_wide_data           : in  std_logic_vector(31 downto 0);                             
      adc_22_wide_data           : in  std_logic_vector(31 downto 0);                                                                                                                      
      adc_23_wide_data           : in  std_logic_vector(31 downto 0);  
		--//read side of ram/fifo:
      adc_0_fifo_data                    : out std_logic_vector(31 downto 0);  -- Data from channel 4 8-bit samps packed              
      adc_fifo_rd_ack                    : in  std_logic_vector(23 downto 0);                                                                                                                                                                                                                                                                                                                                     
      adc_1_fifo_data                    : out std_logic_vector(31 downto 0);                                                                                                 
      adc_2_fifo_data                    : out std_logic_vector(31 downto 0);                                           
      adc_3_fifo_data                    : out std_logic_vector(31 downto 0);                                                                                   
      adc_4_fifo_data                    : out std_logic_vector(31 downto 0);                                                                                              
      adc_5_fifo_data                    : out std_logic_vector(31 downto 0);                                           
      adc_6_fifo_data                    : out std_logic_vector(31 downto 0);                                           
      adc_7_fifo_data                    : out std_logic_vector(31 downto 0);                                                                                  
      adc_8_fifo_data                    : out std_logic_vector(31 downto 0);                                                                                              
      adc_9_fifo_data                    : out std_logic_vector(31 downto 0);                                           
      adc_10_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_11_fifo_data                   : out std_logic_vector(31 downto 0);   
      adc_12_fifo_data                   : out std_logic_vector(31 downto 0);                                                                                                                                                                                                                                                                       
      adc_13_fifo_data                   : out std_logic_vector(31 downto 0);                                                                                                 
      adc_14_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_15_fifo_data                   : out std_logic_vector(31 downto 0);                                                                                  
      adc_16_fifo_data                   : out std_logic_vector(31 downto 0);                                                                                             
      adc_17_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_18_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_19_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_20_fifo_data                   : out std_logic_vector(31 downto 0);                                                                                             
      adc_21_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_22_fifo_data                   : out std_logic_vector(31 downto 0);                                           
      adc_23_fifo_data                   : out std_logic_vector(31 downto 0);  
		
		capture_ctrl_reg_i         : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)  
		capture_stat_reg_o         : out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)      				capture_stat               : out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)      
		trigger_ctrl1_reg_i			: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)  
		trigger_ctrl2_reg_i			: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)  
		ptrigger_ctrl_reg_i			: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed) 
		readout_ctrl_reg_i			: in   std_logic_vector(31 downto 0); -- In clk_avs domain 
		posttrig_ctrl_reg_i			: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh0_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh1_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh2_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh3_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh4_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh5_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh6_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh7_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh8_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh9_reg_i : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)	
		coinc_trigger_thresh10_reg_i: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)
		coinc_trigger_thresh11_reg_i: in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed) 
		beam_trig_thresh0_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh1_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh2_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh3_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh4_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh5_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh6_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh7_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh8_reg_i		: in   std_logic_vector(31 downto 0);
		beam_trig_thresh9_reg_i		: in   std_logic_vector(31 downto 0);
		--event metadata:
		last_evt_evt_count_reg_o	: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_trig_count_reg_o	: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_deadtime_reg_o		: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_clkcount_reg_o		: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_ppscount_reg_o		: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_metamisc1_reg_o	: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_metamisc2_reg_o	: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		last_evt_trig_adr_reg_o		: out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)     
		--scalers (on clk_rd)
		scaler_sel_reg_i				: in   std_logic_vector(31 downto 0);
		scaler_read_reg_o				: out	 std_logic_vector(31 downto 0); 
		
		event_ready_o					: out	 std_logic; -- send to gpio
		pps_i								: in	 std_logic;
		ext_trig_i						: in   std_logic);
		
end entity didaq_acq_and_trig;
---------------------
architecture rtl of didaq_acq_and_trig is
---------------------
component ring_buffer
	port(     
      wrclock    	: in  std_logic;                                                                           
      rdclock    	: in  std_logic;  
      wren			: in	std_logic;
		rden			: in	std_logic;
      rdaddress	: in	std_logic_vector(9 downto 0);
      wraddress	: in	std_logic_vector(9 downto 0);
		data			: in 	std_logic_vector(31 downto 0);
		q				: out	std_logic_vector(31 downto 0));
end component;
---------------------
---------------------
constant invert_mask	: std_logic_vector(23 downto 0) := x"CCCCCC"; --sign invert chs 0,1 on each ADC
constant pre_trig_depth : integer := 192;
---------------------                                   
type wfm_data_type is array (0 to 23) of std_logic_vector(31 downto 0);   
type pre_trig_wfm_data_type is array(0 to 23, 0 to pre_trig_depth-1) of std_logic_vector(31 downto 0);
type trig_data_type is array (0 to 23) of std_logic_vector(63 downto 0);  
type coinc_threshold_type is array(0 to 23) of std_logic_vector(7 downto 0);
type beam_threshold_type is array(0 to 9) of std_logic_vector(15 downto 0);                 
type ram_address_type is array(0 to 23) of std_logic_vector(9 downto 0);                 
               
--
signal internal_ram_wr_en       : std_logic;                              
signal internal_ram_wr_data_0   : wfm_data_type;
signal internal_ram_wr_data_1   : wfm_data_type; --pipeline
signal internal_ram_wr_data_2   : wfm_data_type; --pipeline
signal internal_ram_wr_data_3   : wfm_data_type; --pipeline
signal internal_pretrig_data	  : pre_trig_wfm_data_type;

signal internal_trig_data	  		: trig_data_type; --to trigger
signal internal_trig_data_mf	  	: trig_data_type; --to trigger

signal internal_ram_rd_data	  : wfm_data_type;
signal internal_ram_rd_data_2	  : wfm_data_type;
signal internal_ram_wr_adr		  : std_logic_vector(9 downto 0);
signal internal_ram_connected_out: std_logic := '0';
signal internal_ram_connected_in: std_logic := '0';
signal internal_ram_has_data    : std_logic_vector(1 downto 0); 
signal internal_posttrig_wr_adr : std_logic_vector(9 downto 0); --counter for saving post-trig data to ram
signal internal_ram_rd_adr		  : ram_address_type;
signal internal_ram_rd_adr_counter :  ram_address_type;
signal last_event_trigger_ram_wr_adr : std_logic_vector(9 downto 0);   
signal last_event_trigger_ram_wr_adr_2 : std_logic_vector(9 downto 0); 
signal internal_ram_wr_state	  : std_logic_Vector(1 downto 0); 
signal internal_ram_rd_state	  : std_logic_Vector(1 downto 0); 
signal save_internal_event_metadata_flag : std_logic;                                   
											  
signal out_fifo_wr_en               : std_logic_vector(23 downto 0);                               
--signal out_fifo_wr_data             : fifo_data_type;
signal out_fifo_wr_full             : std_logic_vector(23 downto 0);                                     
                                                                                                      
signal out_fifo_rd_en               : std_logic_vector(23 downto 0);                                     
signal out_fifo_rd_data             : wfm_data_type;   
signal out_fifo_rd_empty            : std_logic_vector(23 downto 0);                                      

signal capture_ctrl_wr_domain_mf		: std_logic_vector(31 downto 0);
signal capture_ctrl_wr_domain			: std_logic_vector(31 downto 0);
signal sw_trig_edge_capture			: std_logic_vector(1 downto 0);
signal capture_ctrl_trig_domain_mf		: std_logic_vector(31 downto 0);
signal capture_ctrl_trig_domain			: std_logic_vector(31 downto 0);
signal trigger_ctrl1_trig_domain_mf 	: std_logic_vector(31 downto 0);
signal trigger_ctrl1_trig_domain    	: std_logic_vector(31 downto 0);
signal trigger_ctrl2_trig_domain_mf 	: std_logic_vector(31 downto 0);
signal trigger_ctrl2_trig_domain    	: std_logic_vector(31 downto 0);
signal ptrigger_ctrl_trig_domain_mf 	: std_logic_vector(31 downto 0);
signal ptrigger_ctrl_trig_domain    	: std_logic_vector(31 downto 0);
signal coinc_trig_threshold_mf		: coinc_threshold_type;
signal coinc_trig_threshold			: coinc_threshold_type;
signal beam_trig_threshold_mf			: beam_threshold_type;
signal beam_trig_threshold				: beam_threshold_type;
signal beam_servo_threshold_mf		: beam_threshold_type;
signal beam_servo_threshold			: beam_threshold_type;

signal posttrig_length_mf				: std_logic_vector(31 downto 0);
signal posttrig_length					: std_logic_vector(31 downto 0);
---internal signals, clk_wr
signal internal_trigger 		: std_logic_vector(7 downto 0); --for different trigger types 
signal internal_trigger_last	: std_logic_vector(7 downto 0); --prev clock period version of above
signal last_event_trigger_type: std_logic_vector(7 downto 0);
signal last_event_trigger_type_2: std_logic_vector(7 downto 0);
signal internal_trigger_or		: std_logic; --or of all triggers 
signal internal_trigger_state : std_logic_vector(1 downto 0);
signal internal_event_busy		: std_logic_vector(1 downto 0);  --event captured, don't accept new triggers until cleared by SBC
signal internal_event_done		: std_logic;  --done signal comes from SBC to clear event_busy
signal internal_event_ready	: std_logic_vector(1 downto 0);  --ready signal after data is in RAM, awaiting SBC read or clear
signal internal_event_switching: std_logic;
signal internal_pps				: std_logic_vector(2 downto 0); --lsb is mf
signal internal_pps_risedge	: std_logic; --rising edge capture
signal internal_pps_trigclk	: std_logic_vector(2 downto 0); --lsb is mf
signal internal_ext_risedge	: std_logic; --rising edge capture 
signal internal_swtrg_riseedge: std_logic; --rising edge capture of sw trig
signal internal_ext				: std_logic_vector(2 downto 0); --lsb is mf
signal internal_coinc_trig		: std_logic_vector(1 downto 0); --left and right coinc. trig options
signal internal_coinc_trig_mf	: std_logic_vector(1 downto 0); --left and right coinc. trig options
signal internal_phased_trig	: std_logic;
signal internal_pps_counter	: std_logic_vector(15 downto 0);
signal internal_clock_counter : std_logic_vector (31 downto 0);
signal internal_clock_per_pps_counter_latched : std_logic_vector(31 downto 0); --//rolling count of wr clk cycles per pps cycle

signal internal_event_counter	: std_logic_vector(31 downto 0);
signal last_internal_event_counter	: std_logic_vector(31 downto 0);
signal last_internal_event_counter_2	: std_logic_vector(31 downto 0);
signal last_event_pps_counter	  : std_logic_vector(15 downto 0);
signal last_event_pps_counter_2	  : std_logic_vector(15 downto 0);
signal last_event_clock_counter : std_logic_vector (31 downto 0);
signal last_event_clock_counter_2 : std_logic_vector (31 downto 0);
signal last_coinc_trig_hit_pattern_trig_clk : std_logic_vector(23 downto 0);
signal last_coinc_trig_hit_pattern_trig_clk_2 : std_logic_vector(23 downto 0);	
signal last_coinc_trig_hit_pattern_wr_clk : std_logic_vector(23 downto 0);		
signal last_coinc_trig_hit_pattern_wr_clk_2 : std_logic_vector(23 downto 0);		

signal internal_last_beam_pattern_trig_clk : std_logic_vector(9 downto 0);
signal internal_last_beam_pattern_trig_clk_2 : std_logic_vector(9 downto 0);
signal internal_last_beam_pattern_wr_clk_latched : std_logic_vector(9 downto 0);
signal internal_last_beam_pattern_wr_clk_latched_2 : std_logic_vector(9 downto 0);
signal beam_trigs_for_scalers : std_logic_vector(9 downto 0); 
signal beam_servos_for_scalers : std_logic_vector(9 downto 0); 

signal coinc_trig0_hit_singles : std_logic_vector(11 downto 0);
signal coinc_trig1_hit_singles : std_logic_vector(11 downto 0);

begin
----------------------------------------------------------------
event_ready_o <= internal_event_ready(0) and internal_event_ready(1);
----------------------------------------------------------------
--clock input stuff into the clk_wr domain
process(clk_wr,arstn)
begin
   if arstn = '0' then
		capture_ctrl_wr_domain_mf		<= (others => '0');
		capture_ctrl_wr_domain			<= (others => '0');
		posttrig_length_mf				<= (others => '0');
		posttrig_length					<= (others => '0');
		internal_pps						<= (others => '0');
		internal_ext						<= (others => '0');
		sw_trig_edge_capture				<= (others => '0');
		internal_pps_risedge				<= '0';
		internal_ext_risedge				<= '0';
		internal_swtrg_riseedge			<= '0';

   elsif clk_wr'event and clk_wr = '1' then
      capture_ctrl_wr_domain_mf	<= capture_ctrl_reg_i;
		capture_ctrl_wr_domain 		<= capture_ctrl_wr_domain_mf;
		sw_trig_edge_capture	 		<= sw_trig_edge_capture(0) & capture_ctrl_wr_domain (0);
		
		posttrig_length_mf			<= posttrig_ctrl_reg_i;
		posttrig_length				<= posttrig_length_mf;	
		
		internal_pps <= internal_pps(1 downto 0) & pps_i; --lsb is mf
		internal_ext <= internal_ext(1 downto 0) & ext_trig_i; --lsb is mf
		----------- rising edge conditions for pps and external trigger options:
		if internal_pps(2 downto 1) = "01" then
			internal_pps_risedge <= '1';
		else
			internal_pps_risedge <= '0';
		end if;
		-----------
		if internal_ext(2 downto 1) = "01" then
			internal_ext_risedge <= '1';
		else
			internal_ext_risedge <= '0';
		end if;
		-----------
		if sw_trig_edge_capture = "01" then
			internal_swtrg_riseedge <= '1';
		else
			internal_swtrg_riseedge <= '0';
		end if;
   end if;
end process;        
----------------------------------------------------------------
--handle triggers
process(clk_wr,arstn)
begin
   if arstn = '0' then
		internal_trigger<= (others=>'0');
		internal_trigger_last <= (others=>'0');
		last_event_trigger_type <= (others=>'0');
		last_event_trigger_type_2 <= (others=>'0');
		internal_trigger_or <= '0';
		internal_trigger_state <= "00";
		internal_coinc_trig <= (others=>'0');
	--//software run reset
	elsif clk_wr'event and clk_wr = '1' and capture_ctrl_wr_domain(16) = '1' then	
		internal_trigger<= (others=>'0');
		internal_trigger_last <= (others=>'0');
		last_event_trigger_type <= (others=>'0');
		last_event_trigger_type_2 <= (others=>'0');
		internal_trigger_or <= '0';
		internal_trigger_state <= "00";
		internal_coinc_trig <= (others=>'0');
		
	elsif clk_wr'event and clk_wr = '1' then	
		
		internal_coinc_trig <= internal_coinc_trig_mf; --//from coinc. trig modules
		
		internal_trigger_last <= internal_trigger;
		internal_trigger <= "00" & (internal_pps_risedge and capture_ctrl_wr_domain(24)) &
											(internal_ext_risedge and capture_ctrl_wr_domain(25)) &
											internal_coinc_trig(0) & internal_coinc_trig(1) & internal_phased_trig &
											internal_swtrg_riseedge; 
		
				case internal_trigger_state is
			when "00" => --accept triggers
										  
				internal_trigger_or <= '0';	
				--last_event_trigger_type <= last_event_trigger_type;
				
				if internal_trigger > 0 and ((internal_event_busy(0) = '0' and internal_ram_connected_in = '0') or (internal_event_busy(1) = '0' and internal_ram_connected_in = '1')) then
					internal_trigger_state <= internal_trigger_state + 1;
				end if;
			
			when "01" =>  --sends event trigger, pulsed for two clock cycles
				internal_trigger_or <= '1'; --trigger event
				if internal_ram_connected_in = '0' then
					last_event_trigger_type <= internal_trigger_last;
				else -- if internal_ram_connected_in = '1' then
					last_event_trigger_type_2 <= internal_trigger_last;
				end if;
				
				internal_trigger_state <= internal_trigger_state + 1;

			when "10" => 	
				internal_trigger_or <= '1'; --trigger event
				--last_event_trigger_type <= last_event_trigger_type;
				internal_trigger_state <= internal_trigger_state + 1;
				
			when "11" => 	--wait until event is cleared by sw
				internal_trigger_or <= '0'; --trigger event
				--last_event_trigger_type <= last_event_trigger_type;

				if ((internal_event_busy(0) = '0' and internal_ram_connected_in = '0') or (internal_event_busy(1) = '0' and internal_ram_connected_in = '1')) then --//if trigger started event capture, wait until event is cleared to re-start
					internal_trigger_state <= internal_trigger_state + 1;	
				end if;
			when others=>
				internal_trigger_state <= "00";
		end case;
	end if;
end process;
----------------------------------------------------------------				
----------------------------------------------------------------
--handle ram write addressing, S/H essentially
process(clk_wr,arstn)
begin
   if arstn = '0' then
		internal_ram_wr_adr <= (others=>'0');
		internal_posttrig_wr_adr <= (others=>'0');
		last_event_trigger_ram_wr_adr <= (others=>'0'); --latched address when trigger occurs
		internal_ram_wr_state <= "00";
		internal_ram_wr_en <= '0';
		internal_event_busy <= "00";
		internal_event_done <= '0';
		internal_event_ready <= "00";
		internal_ram_connected_out <= '0';
		internal_ram_connected_in <= '0';
		internal_event_switching <= '0';
		
	elsif clk_wr'event and clk_wr = '1'and capture_ctrl_wr_domain(16) = '1' then	
		internal_ram_wr_adr <= (others=>'0');
		internal_posttrig_wr_adr <= (others=>'0');
		last_event_trigger_ram_wr_adr <= (others=>'0'); --latched address when trigger occurs
		internal_ram_wr_state <= "00";
		internal_ram_wr_en <= '0';
		internal_event_busy <= "00";
		internal_event_done <= '0';
		internal_event_ready <= "00";
		internal_ram_connected_out <= '0';
		internal_ram_connected_in <= '0';
		internal_event_switching <= '0';

		elsif clk_wr'event and clk_wr = '1' then	
		
		internal_event_done <= capture_ctrl_wr_domain(8);
		
			case internal_ram_wr_state is
					
				when "00"=> --//wait for trig
					internal_ram_wr_adr <= (others=>'0');
					internal_posttrig_wr_adr <= (others=>'0');
					--last_event_trigger_ram_wr_adr <= internal_ram_wr_adr; --track address until trigger
					internal_ram_wr_en <= '0';
					if internal_ram_connected_in = '0' then
					  internal_event_busy(0) <= '0';
					  internal_event_ready(0) <= '0';
					else -- if internal_ram_connected_in = '1' then
						internal_event_busy(1) <= '0';
						internal_event_ready(1) <= '0';
					end if;
					if internal_trigger_or = '1' then 
						internal_ram_wr_state <= internal_ram_wr_state + 1;	
						internal_ram_wr_en <= '1';
					end if;
					
				when "01"=> --//write to ram
					internal_ram_wr_adr <= internal_ram_wr_adr + 1;
					internal_posttrig_wr_adr <= internal_posttrig_wr_adr + 1;
					--last_event_trigger_ram_wr_adr <= last_event_trigger_ram_wr_adr; //unchanged
					internal_ram_wr_en <= '1';
					if internal_ram_connected_in = '0' then
					  internal_event_busy(0) <= '1';
					  internal_event_ready(0) <= '0';
					else -- if internal_ram_connected_in = '1' then
						internal_event_busy(1) <= '1';
						internal_event_ready(1) <= '0';
					end if;

					if internal_posttrig_wr_adr = 1023 then --fixed post trigger rn, eventually programmable maybe
						internal_ram_wr_state <= internal_ram_wr_state + 1;	
						internal_ram_wr_en <= '0';
					end if;
					
				when "10"=> --// hold, wait until ready for next event	
					internal_ram_wr_adr <= internal_ram_wr_adr;
					internal_posttrig_wr_adr <= (others=>'0');
					--last_event_trigger_ram_wr_adr <= last_event_trigger_ram_wr_adr; //unchanged
					internal_ram_wr_en <= '0';
					if internal_ram_connected_in = '0' then
					  internal_event_busy(0) <= '1';
					  internal_event_ready(0) <= '1';
					  last_event_trigger_ram_wr_adr <= internal_ram_wr_adr; --track address until trigger
					else -- if internal_ram_connected_in = '1' then
						internal_event_busy(1) <= '1';
						internal_event_ready(1) <= '1';--//ready for SBC
						last_event_trigger_ram_wr_adr_2 <= internal_ram_wr_adr; --track address until trigger
					end if; 
					
					-- switch banks if free
					if internal_ram_connected_in = '0' then
						if internal_event_busy(1) = '0' then --if other bank is free
							internal_ram_connected_in <= '1'; --switch banks
							internal_ram_wr_state <= "00";
						end if;
					else -- if internal_ram_connected_in = '1' then
						if internal_event_busy(0) = '0' then
							internal_ram_connected_in <= '0'; --switch banks
							internal_ram_wr_state <= "00";
						end if;
					end if;
					
					--//original code for 1 ram bank
					--if internal_event_done = '1' then
					--	internal_ram_wr_state <= internal_ram_wr_state + 1;
					--end if;
					
				--when "11"=> --//wait until event_done is cleared to re-start
				--	internal_ram_wr_adr <= (others=>'0');
				--	internal_posttrig_wr_adr <= (others=>'0');
				--	--last_event_trigger_ram_wr_adr <= last_event_trigger_ram_wr_adr; //unchanged
				--	if internal_ram_connected_in = '0' then
				--	  internal_ram_wr_en(0) <= '0'
				--	  internal_event_busy(0) <= '1';
				--	  internal_event_ready(0) <= '0';
				--	else
				--		internal_ram_wr_en(1) <= '0';
				--		internal_event_busy(1) <= '1';
				--		internal_event_ready(1) <= '0';--//ready for SBC
				--	end if;
				--
				--	--wait until event_done is cleared to go back to start
				--	--if internal_event_done = '0' then
				--	--	internal_ram_wr_state <= internal_ram_wr_state + 1;	
				--	--end if;
					
				when others=>
					internal_ram_wr_state  <= "00";
			end case;
			
			--process reads
			if internal_event_done = '1' and internal_event_switching = '0' then
				if internal_ram_connected_out = '0' then
					if internal_event_busy(0) = '1' and internal_event_ready(0) = '1' then
						internal_event_ready(0) <= '0';
						internal_event_busy(0) <= '0';
						internal_ram_connected_out <= '1';
						internal_event_switching <= '1';
					end if;
				else --if internal_ram_connected_out = '1' then
					if internal_event_busy(1) = '1' and internal_event_ready(1) = '1' then
						internal_event_ready(1) <= '0';
						internal_event_busy(1) <= '0';
						internal_ram_connected_out <= '0';
						internal_event_switching <= '1';
					end if;
				end if;
			elsif internal_event_done = '0' and internal_event_switching = '1' then
				internal_event_switching <= '0';
			end if;
			
	end if;
end process;
----------------------------------------------------------------					
----------------------------------------------------------------					
--handle timers and counters and event metadata
process(clk_wr,arstn)
begin
   if arstn = '0' then
		internal_event_counter 	<= (others=>'0');
		internal_clock_counter 	<= (others=>'0');
		internal_pps_counter		<= (others=>'0');
		last_event_clock_counter<= (others=>'0');
		last_event_clock_counter_2<= (others=>'0');
		last_event_pps_counter	<= (others=>'0');
		last_event_pps_counter_2	<= (others=>'0');
		last_coinc_trig_hit_pattern_wr_clk <= (others=>'0');
		last_coinc_trig_hit_pattern_wr_clk_2 <= (others=>'0');
		internal_clock_per_pps_counter_latched  <= (others=>'0');
		internal_last_beam_pattern_wr_clk_latched <= (others=>'0');
		internal_last_beam_pattern_wr_clk_latched_2 <= (others=>'0');
		
	--//software run reset
	elsif (clk_wr'event and clk_wr = '1') and capture_ctrl_wr_domain(16) = '1' then	
		internal_event_counter 	<= (others=>'0');
		internal_clock_counter 	<= (others=>'0');
		internal_pps_counter		<= (others=>'0');
		last_event_clock_counter<= (others=>'0');
		last_event_pps_counter	<= (others=>'0');
		last_coinc_trig_hit_pattern_wr_clk <= (others=>'0');
		internal_clock_per_pps_counter_latched  <= (others=>'0');
		internal_last_beam_pattern_wr_clk_latched <= (others=>'0');

	elsif clk_wr'event and clk_wr = '1' then
		--increment/reset timing counters on rising edge of pps
		if internal_pps_risedge = '1' then
			internal_pps_counter <= internal_pps_counter + 1; --num of pps since start of run
			internal_clock_per_pps_counter_latched <= internal_clock_counter; --num of clk cycles per pps
			internal_clock_counter <= (others=>'0');     --num of clock cycles since last pps
		else
			internal_pps_counter <= internal_pps_counter;
			internal_clock_per_pps_counter_latched <= internal_clock_per_pps_counter_latched;
			internal_clock_counter <= internal_clock_counter + 1; 
		end if;
		
		--latch meta data on trigger that initiates event
		if internal_trigger_state = "10" then 
		   if internal_ram_connected_in = '0' then
				last_event_clock_counter <= internal_clock_counter;
				last_event_pps_counter <= internal_pps_counter;
				internal_event_counter <= internal_event_counter + 1;
				last_internal_event_counter <= internal_event_counter + 1;
				last_coinc_trig_hit_pattern_wr_clk <= last_coinc_trig_hit_pattern_trig_clk;
				internal_last_beam_pattern_wr_clk_latched <= internal_last_beam_pattern_trig_clk;
			else -- if internal_ram_connected_in = '1'
				last_event_clock_counter_2 <= internal_clock_counter;
				last_event_pps_counter_2 <= internal_pps_counter;
				internal_event_counter <= internal_event_counter + 1;
				last_internal_event_counter_2 <= internal_event_counter + 1;
				last_coinc_trig_hit_pattern_wr_clk_2 <= last_coinc_trig_hit_pattern_trig_clk;
				internal_last_beam_pattern_wr_clk_latched_2 <= internal_last_beam_pattern_trig_clk;
			end if;
		end if;
	end if;
end process;
----------------------------------------------------------------	
--generate ring-buffer ram blocks
gen_ring_buffer_rams : for i in 0 to 23 generate 
inst_ring_buffer : ring_buffer
   port map(
	   wrclock    	=> clk_wr,                                                                           
      rdclock    	=> clk_rd,
      wren			=> internal_ram_wr_en when (internal_ram_connected_in='0') else '0',
		rden			=> '1' when (internal_ram_wr_adr = "0000000001") else adc_fifo_rd_ack(i), -- reread 0 when 1 is written
      rdaddress	=> internal_ram_rd_adr(i),
      wraddress	=> internal_ram_wr_adr,
		data			=> internal_pretrig_data(i,191), --internal_ram_wr_data(i),
		q				=> internal_ram_rd_data(i));
end generate;
gen_ring_buffer_rams_2 : for i in 0 to 23 generate 
inst_ring_buffer_2 : ring_buffer
  port map(
	   wrclock    	=> clk_wr,                                                                           
      rdclock    	=> clk_rd,
      wren			=> internal_ram_wr_en when (internal_ram_connected_in='1') else '0',
		rden			=> '1' when (internal_ram_wr_adr = "0000000001") else adc_fifo_rd_ack(i), -- reread 0 when 1 is written
      rdaddress	=> internal_ram_rd_adr(i),
      wraddress	=> internal_ram_wr_adr,
		data			=> internal_pretrig_data(i,191), --internal_ram_wr_data_2(i),
		q				=> internal_ram_rd_data_2(i));
end generate;
----------------------------------------------------------------
--read ram ctrl
process(clk_rd,arstn)
begin
	for i in 0 to 23 loop
		if arstn = '0' then
			internal_ram_rd_adr(i) 				<= (others=>'0');
			internal_ram_rd_adr_counter(i) 	<= (others=>'0');
		--//reset event after done reading
		elsif clk_rd'event and clk_rd = '1' and capture_ctrl_reg_i(8) = '1' then
			internal_ram_rd_adr(i) 				<= (others=>'0');
			internal_ram_rd_adr_counter(i) 	<= (others=>'0');
		--//increment address each time the fifo_rd_ack is pulsed
		elsif clk_rd'event and clk_rd = '1' and adc_fifo_rd_ack(i) = '1' then
			internal_ram_rd_adr(i)(9 downto 0) 	<= readout_ctrl_reg_i(9 downto 0) + internal_ram_rd_adr_counter(i)(9 downto 0);
			internal_ram_rd_adr_counter(i) 		<= internal_ram_rd_adr_counter(i) + 1; --//increment address
		end if;
	end loop;
end process;
----------------------------------------------------------------
process(clk_rd,arstn) --assign status/meta read-only registers
begin
	if arstn = '0' then
		last_evt_evt_count_reg_o	<= (others=>'0');  
		last_evt_trig_count_reg_o	<= (others=>'0');     
		last_evt_deadtime_reg_o		<= (others=>'0');    
		last_evt_clkcount_reg_o		<= (others=>'0');   
		last_evt_ppscount_reg_o		<= (others=>'0');    
		last_evt_metamisc1_reg_o	<= (others=>'0');     
		last_evt_metamisc2_reg_o	<= (others=>'0');     
		last_evt_trig_adr_reg_o		<= (others=>'0');
		capture_stat_reg_o			<= (others=>'0');
	elsif clk_rd'event and clk_rd = '1' then
		if(internal_ram_connected_out = '0') then
			last_evt_evt_count_reg_o	<= last_internal_event_counter;  
			last_evt_trig_count_reg_o	<= last_internal_event_counter;     
			last_evt_deadtime_reg_o		<= (others=>'0');    
			last_evt_clkcount_reg_o		<= last_event_clock_counter;   
			last_evt_ppscount_reg_o		<= x"0000" & last_event_pps_counter;    
			last_evt_metamisc1_reg_o	<= x"00" & last_coinc_trig_hit_pattern_wr_clk;     
			last_evt_metamisc2_reg_o	<= x"00000" & "00" & internal_last_beam_pattern_wr_clk_latched; --//beam trigger details here eventually
			last_evt_trig_adr_reg_o		<= x"00" & last_event_trigger_type & "000000" & last_event_trigger_ram_wr_adr;
			capture_stat_reg_o			<= x"000000" & "000000" & (internal_event_ready(0) or internal_event_ready(1)) & (internal_event_busy(0) and internal_event_busy(1));
		else -- if(internal_ram_connected_out = '1') then
			last_evt_evt_count_reg_o	<= last_internal_event_counter_2;  
			last_evt_trig_count_reg_o	<= last_internal_event_counter_2;     
			last_evt_deadtime_reg_o		<= (others=>'0');    
			last_evt_clkcount_reg_o		<= last_event_clock_counter_2;   
			last_evt_ppscount_reg_o		<= x"0000" & last_event_pps_counter_2;    
			last_evt_metamisc1_reg_o	<= x"00" & last_coinc_trig_hit_pattern_wr_clk_2;     
			last_evt_metamisc2_reg_o	<= x"00000" & "00" & internal_last_beam_pattern_wr_clk_latched_2; --//beam trigger details here eventually
			last_evt_trig_adr_reg_o		<= x"00" & last_event_trigger_type_2 & "000000" & last_event_trigger_ram_wr_adr_2;
			capture_stat_reg_o			<= x"000000" & "000000" & (internal_event_ready(0) or internal_event_ready(1)) & (internal_event_busy(0) and internal_event_busy(1));	
		end if;
	end if;
end process;
----------------------------------------------------------------
process(clk_rd,internal_ram_connected_out)
begin
	if internal_ram_connected_out = '0' then
		adc_0_fifo_data <= internal_ram_rd_data(0);
		adc_1_fifo_data <= internal_ram_rd_data(1);
		adc_2_fifo_data <= internal_ram_rd_data(2);
		adc_3_fifo_data <= internal_ram_rd_data(3);
		adc_4_fifo_data <= internal_ram_rd_data(4);
		adc_5_fifo_data <= internal_ram_rd_data(5);
		adc_6_fifo_data <= internal_ram_rd_data(6);
		adc_7_fifo_data <= internal_ram_rd_data(7);
		adc_8_fifo_data <= internal_ram_rd_data(8);
		adc_9_fifo_data <= internal_ram_rd_data(9);
		adc_10_fifo_data <= internal_ram_rd_data(10);
		adc_11_fifo_data <= internal_ram_rd_data(11);
		adc_12_fifo_data <= internal_ram_rd_data(12);
		adc_13_fifo_data <= internal_ram_rd_data(13);
		adc_14_fifo_data <= internal_ram_rd_data(14);
		adc_15_fifo_data <= internal_ram_rd_data(15);
		adc_16_fifo_data <= internal_ram_rd_data(16);
		adc_17_fifo_data <= internal_ram_rd_data(17);
		adc_18_fifo_data <= internal_ram_rd_data(18);
		adc_19_fifo_data <= internal_ram_rd_data(19);
		adc_20_fifo_data <= internal_ram_rd_data(20);
		adc_21_fifo_data <= internal_ram_rd_data(21);
		adc_22_fifo_data <= internal_ram_rd_data(22);
		adc_23_fifo_data <= internal_ram_rd_data(23);
	else -- if internal_ram_connected_out = '1' then
		adc_0_fifo_data <= internal_ram_rd_data_2(0);
		adc_1_fifo_data <= internal_ram_rd_data_2(1);
		adc_2_fifo_data <= internal_ram_rd_data_2(2);
		adc_3_fifo_data <= internal_ram_rd_data_2(3);
		adc_4_fifo_data <= internal_ram_rd_data_2(4);
		adc_5_fifo_data <= internal_ram_rd_data_2(5);
		adc_6_fifo_data <= internal_ram_rd_data_2(6);
		adc_7_fifo_data <= internal_ram_rd_data_2(7);
		adc_8_fifo_data <= internal_ram_rd_data_2(8);
		adc_9_fifo_data <= internal_ram_rd_data_2(9);
		adc_10_fifo_data <= internal_ram_rd_data_2(10);
		adc_11_fifo_data <= internal_ram_rd_data_2(11);
		adc_12_fifo_data <= internal_ram_rd_data_2(12);
		adc_13_fifo_data <= internal_ram_rd_data_2(13);
		adc_14_fifo_data <= internal_ram_rd_data_2(14);
		adc_15_fifo_data <= internal_ram_rd_data_2(15);
		adc_16_fifo_data <= internal_ram_rd_data_2(16);
		adc_17_fifo_data <= internal_ram_rd_data_2(17);
		adc_18_fifo_data <= internal_ram_rd_data_2(18);
		adc_19_fifo_data <= internal_ram_rd_data_2(19);
		adc_20_fifo_data <= internal_ram_rd_data_2(20);
		adc_21_fifo_data <= internal_ram_rd_data_2(21);
		adc_22_fifo_data <= internal_ram_rd_data_2(22);
		adc_23_fifo_data <= internal_ram_rd_data_2(23);
	end if;
end process;
----------------------------------------------------------------
process(clk_wr,arstn)
begin
	if arstn = '0' then
		for i in 0 to 23 loop
			internal_ram_wr_data_0(i) <= (others => '0');
			internal_ram_wr_data_1(i) <= (others => '0');
			internal_ram_wr_data_2(i) <= (others => '0');
			internal_ram_wr_data_3(i) <= (others => '0');
			for j in 0 to 127 loop
				internal_pretrig_data(i,j) <= (others => '0');
			end loop;
		end loop;

	elsif clk_wr'event and clk_wr = '1' then
		if reorder_data_flag = '0' then --//this is a compile time flag, could be a real-time mux option..but could lead to confusion
			internal_ram_wr_data_0(0) <= adc_0_wide_data;
			internal_ram_wr_data_0(1) <= adc_1_wide_data;
			internal_ram_wr_data_0(2) <= adc_2_wide_data;
			internal_ram_wr_data_0(3) <= adc_3_wide_data;
			internal_ram_wr_data_0(4) <= adc_4_wide_data;
			internal_ram_wr_data_0(5) <= adc_5_wide_data;
			internal_ram_wr_data_0(6) <= adc_6_wide_data;
			internal_ram_wr_data_0(7) <= adc_7_wide_data;
			internal_ram_wr_data_0(8) <= adc_8_wide_data;
			internal_ram_wr_data_0(9) <= adc_9_wide_data;
			internal_ram_wr_data_0(10) <= adc_10_wide_data;
			internal_ram_wr_data_0(11) <= adc_11_wide_data;
			internal_ram_wr_data_0(12) <= adc_12_wide_data;
			internal_ram_wr_data_0(13) <= adc_13_wide_data;
			internal_ram_wr_data_0(14) <= adc_14_wide_data;
			internal_ram_wr_data_0(15) <= adc_15_wide_data;
			internal_ram_wr_data_0(16) <= adc_16_wide_data;
			internal_ram_wr_data_0(17) <= adc_17_wide_data;
			internal_ram_wr_data_0(18) <= adc_18_wide_data;
			internal_ram_wr_data_0(19) <= adc_19_wide_data;
			internal_ram_wr_data_0(20) <= adc_20_wide_data;
			internal_ram_wr_data_0(21) <= adc_21_wide_data;
			internal_ram_wr_data_0(22) <= adc_22_wide_data;
			internal_ram_wr_data_0(23) <= adc_23_wide_data;			
		else
			internal_ram_wr_data_0(0) <= adc_1_wide_data;
			internal_ram_wr_data_0(1) <= adc_0_wide_data;
			internal_ram_wr_data_0(2) <= adc_3_wide_data;
			internal_ram_wr_data_0(3) <= adc_2_wide_data;
			internal_ram_wr_data_0(4) <= adc_5_wide_data;
			internal_ram_wr_data_0(5) <= adc_4_wide_data;
			internal_ram_wr_data_0(6) <= adc_7_wide_data;
			internal_ram_wr_data_0(7) <= adc_6_wide_data;
			internal_ram_wr_data_0(8) <= adc_9_wide_data;
			internal_ram_wr_data_0(9) <= adc_8_wide_data;
			internal_ram_wr_data_0(10) <= adc_11_wide_data;
			internal_ram_wr_data_0(11) <= adc_10_wide_data;
			internal_ram_wr_data_0(12) <= adc_13_wide_data;
			internal_ram_wr_data_0(13) <= adc_12_wide_data;
			internal_ram_wr_data_0(14) <= adc_15_wide_data;
			internal_ram_wr_data_0(15) <= adc_14_wide_data;
			internal_ram_wr_data_0(16) <= adc_17_wide_data;
			internal_ram_wr_data_0(17) <= adc_16_wide_data;
			internal_ram_wr_data_0(18) <= adc_19_wide_data;
			internal_ram_wr_data_0(19) <= adc_18_wide_data;
			internal_ram_wr_data_0(20) <= adc_21_wide_data;
			internal_ram_wr_data_0(21) <= adc_20_wide_data;
			internal_ram_wr_data_0(22) <= adc_23_wide_data;
			internal_ram_wr_data_0(23) <= adc_22_wide_data;
		end if;
		--------------------------------------------------
		for i in 0 to 23 loop
			for j in 1 to pre_trig_depth-1 loop
				internal_pretrig_data(i,j) <= internal_pretrig_data(i,j-1); --//pre-trigger buffer to RAM
			end loop;
			internal_pretrig_data(i,0) <= internal_ram_wr_data_3(i);
			internal_ram_wr_data_3(i) <= internal_ram_wr_data_2(i); --//used for trigger
			internal_ram_wr_data_2(i) <= internal_ram_wr_data_1(i); --//used for trigger
			--//to handle backwards-balun wiring on some of the channels:
			if invert_mask(i) = '1' then
				internal_ram_wr_data_1(i) <= not internal_ram_wr_data_0(i);
			else
				internal_ram_wr_data_1(i) <= internal_ram_wr_data_0(i);
			end if;
		end loop;
	end if;
end process;
--------------------------------------
----------------------------------------------------------------
process(clk_trig,arstn)
begin
   if arstn = '0' then
		capture_ctrl_trig_domain_mf		<= (others => '0');
		capture_ctrl_trig_domain			<= (others => '0');
		trigger_ctrl1_trig_domain_mf 	<= (others => '0');
		trigger_ctrl1_trig_domain    	<= (others => '0');
		trigger_ctrl2_trig_domain_mf 	<= (others => '0');
		trigger_ctrl2_trig_domain    	<= (others => '0');
		ptrigger_ctrl_trig_domain_mf 	<= (others => '0');
		ptrigger_ctrl_trig_domain    	<= (others => '0');
		internal_pps_trigclk				<= (others => '0');
		
		for i in 0 to 23 loop
			coinc_trig_threshold_mf(i)			<= (others => '0');
			coinc_trig_threshold(i)				<= (others => '0');
			internal_trig_data(i)				<= (others => '0');
			internal_trig_data_mf(i)			<= (others => '0');
		end loop;
		for i in 0 to 9 loop
			beam_trig_threshold_mf(i)			<= (others => '0');
			beam_trig_threshold(i)				<= (others => '0');
			beam_servo_threshold_mf(i)			<= (others => '0');
			beam_servo_threshold(i)				<= (others => '0');
		end loop;
				
   elsif clk_trig'event and clk_trig = '1' then
		internal_pps_trigclk 			<= internal_pps_trigclk(1 downto 0) & pps_i;
      capture_ctrl_trig_domain_mf	<= capture_ctrl_reg_i;
		capture_ctrl_trig_domain 		<= capture_ctrl_trig_domain_mf;
		
		trigger_ctrl1_trig_domain_mf 	<= trigger_ctrl1_reg_i;
		trigger_ctrl1_trig_domain 		<= trigger_ctrl1_trig_domain_mf;
		trigger_ctrl2_trig_domain_mf 	<= trigger_ctrl2_reg_i;
		trigger_ctrl2_trig_domain 		<= trigger_ctrl2_trig_domain_mf;
		ptrigger_ctrl_trig_domain_mf 	<= ptrigger_ctrl_reg_i;
		ptrigger_ctrl_trig_domain 		<= ptrigger_ctrl_trig_domain_mf;
		
		coinc_trig_threshold_mf(0)	<= coinc_trigger_thresh0_reg_i(7 downto 0);
		coinc_trig_threshold_mf(1)	<= coinc_trigger_thresh0_reg_i(23 downto 16);
 		coinc_trig_threshold_mf(2)	<= coinc_trigger_thresh1_reg_i(7 downto 0);
		coinc_trig_threshold_mf(3)	<= coinc_trigger_thresh1_reg_i(23 downto 16);
		coinc_trig_threshold_mf(4)	<= coinc_trigger_thresh2_reg_i(7 downto 0);
		coinc_trig_threshold_mf(5)	<= coinc_trigger_thresh2_reg_i(23 downto 16);
		coinc_trig_threshold_mf(6)	<= coinc_trigger_thresh3_reg_i(7 downto 0);
		coinc_trig_threshold_mf(7)	<= coinc_trigger_thresh3_reg_i(23 downto 16);
		coinc_trig_threshold_mf(8)	<= coinc_trigger_thresh4_reg_i(7 downto 0);
		coinc_trig_threshold_mf(9)	<= coinc_trigger_thresh4_reg_i(23 downto 16);
		coinc_trig_threshold_mf(10)	<= coinc_trigger_thresh5_reg_i(7 downto 0);
		coinc_trig_threshold_mf(11)	<= coinc_trigger_thresh5_reg_i(23 downto 16);
		coinc_trig_threshold_mf(12)	<= coinc_trigger_thresh6_reg_i(7 downto 0);
		coinc_trig_threshold_mf(13)	<= coinc_trigger_thresh6_reg_i(23 downto 16);
		coinc_trig_threshold_mf(14)	<= coinc_trigger_thresh7_reg_i(7 downto 0);
		coinc_trig_threshold_mf(15)	<= coinc_trigger_thresh7_reg_i(23 downto 16);
		coinc_trig_threshold_mf(16)	<= coinc_trigger_thresh8_reg_i(7 downto 0);
		coinc_trig_threshold_mf(17)	<= coinc_trigger_thresh8_reg_i(23 downto 16);
		coinc_trig_threshold_mf(18)	<= coinc_trigger_thresh9_reg_i(7 downto 0);
		coinc_trig_threshold_mf(19)	<= coinc_trigger_thresh9_reg_i(23 downto 16);
		coinc_trig_threshold_mf(20)	<= coinc_trigger_thresh10_reg_i(7 downto 0);
		coinc_trig_threshold_mf(21)	<= coinc_trigger_thresh10_reg_i(23 downto 16);
		coinc_trig_threshold_mf(22)	<= coinc_trigger_thresh11_reg_i(7 downto 0);
		coinc_trig_threshold_mf(23)	<= coinc_trigger_thresh11_reg_i(23 downto 16);
		for i in 0 to 23 loop
			coinc_trig_threshold(i)	<= coinc_trig_threshold_mf(i);
			internal_trig_data(i) <= internal_trig_data_mf(i);
			--//internal_ram_wr_data_1 is most recent ("latest") data, keeping with big-endien format
			internal_trig_data_mf(i) <= internal_ram_wr_data_2(i) & internal_ram_wr_data_1(i);
		end loop;
		
		beam_trig_threshold_mf(0) 		<= beam_trig_thresh0_reg_i(15 downto 0);
		beam_servo_threshold_mf(0) 	<= beam_trig_thresh0_reg_i(31 downto 16);
		beam_trig_threshold_mf(1) 		<= beam_trig_thresh1_reg_i(15 downto 0);
		beam_servo_threshold_mf(1) 	<= beam_trig_thresh1_reg_i(31 downto 16);
		beam_trig_threshold_mf(2) 		<= beam_trig_thresh2_reg_i(15 downto 0);
		beam_servo_threshold_mf(2) 	<= beam_trig_thresh2_reg_i(31 downto 16);
		beam_trig_threshold_mf(3) 		<= beam_trig_thresh3_reg_i(15 downto 0);
		beam_servo_threshold_mf(3) 	<= beam_trig_thresh3_reg_i(31 downto 16);
		beam_trig_threshold_mf(4) 		<= beam_trig_thresh4_reg_i(15 downto 0);
		beam_servo_threshold_mf(4) 	<= beam_trig_thresh4_reg_i(31 downto 16);
		beam_trig_threshold_mf(5) 		<= beam_trig_thresh5_reg_i(15 downto 0);
		beam_servo_threshold_mf(5) 	<= beam_trig_thresh5_reg_i(31 downto 16);	
		beam_trig_threshold_mf(6) 		<= beam_trig_thresh6_reg_i(15 downto 0);
		beam_servo_threshold_mf(6) 	<= beam_trig_thresh6_reg_i(31 downto 16);
		beam_trig_threshold_mf(7) 		<= beam_trig_thresh7_reg_i(15 downto 0);
		beam_servo_threshold_mf(7) 	<= beam_trig_thresh7_reg_i(31 downto 16);	
		beam_trig_threshold_mf(8) 		<= beam_trig_thresh8_reg_i(15 downto 0);
		beam_servo_threshold_mf(8) 	<= beam_trig_thresh8_reg_i(31 downto 16);
		beam_trig_threshold_mf(9) 		<= beam_trig_thresh9_reg_i(15 downto 0);
		beam_servo_threshold_mf(9) 	<= beam_trig_thresh9_reg_i(31 downto 16);
		for i in 0 to 9 loop
			beam_trig_threshold(i)	<= beam_trig_threshold_mf(i);
			beam_servo_threshold(i)	<= beam_servo_threshold_mf(i);
		end loop;
	end if;
end process;
--------------------------------------
inst_coinc_trig0 : entity work.coinc_trig
	port map(
		arstn        => arstn,
      clk			 => clk_trig,
		data0			 => internal_trig_data(0),	--8 samples of 8 bit data
		data1			 => internal_trig_data(1),				
		data2			 => internal_trig_data(2),
		data3			 => internal_trig_data(3),	
		data4			 => internal_trig_data(4),					
		data5			 => internal_trig_data(5),	
		data6			 => internal_trig_data(6),
		data7			 => internal_trig_data(7),					
		data8			 => internal_trig_data(8),
		data9			 => internal_trig_data(9),
		data10		 => internal_trig_data(10),
		data11		 => internal_trig_data(11),	
		trig_en		 => trigger_ctrl1_trig_domain(1 downto 0),
		trig_mode	 => trigger_ctrl1_trig_domain(5),
		trig_mask	 => trigger_ctrl1_trig_domain(27 downto 16),
		trig_hit_rq	 => trigger_ctrl1_trig_domain(4 downto 2),
		trig_window	 => trigger_ctrl1_trig_domain(11 downto 8),
		thresh0	 	 => coinc_trig_threshold(0),
		thresh1	 	 => coinc_trig_threshold(1),
		thresh2	 	 => coinc_trig_threshold(2),
		thresh3	 	 => coinc_trig_threshold(3),
		thresh4	 	 => coinc_trig_threshold(4),
		thresh5	 	 => coinc_trig_threshold(5),
		thresh6	 	 => coinc_trig_threshold(6),
		thresh7	 	 => coinc_trig_threshold(7),
		thresh8	 	 => coinc_trig_threshold(8),
		thresh9	 	 => coinc_trig_threshold(9),
		thresh10	 	 => coinc_trig_threshold(10),
		thresh11	 	 => coinc_trig_threshold(11),
		last_trigger_hit_pattern_o	=> last_coinc_trig_hit_pattern_trig_clk(11 downto 0),
		singles_o	 => coinc_trig0_hit_singles, --//for scalers. Note that singles are still active even if channel masked from trig
		trig_o		 => internal_coinc_trig_mf(0));
--------------------------------------
inst_coinc_trig1 : entity work.coinc_trig
	port map(
		arstn        => arstn,
      clk			 => clk_trig,
		data0			 => internal_trig_data(12),	--8 samples of 8 bit data (64 bits wide)
		data1			 => internal_trig_data(13),				
		data2			 => internal_trig_data(14),
		data3			 => internal_trig_data(15),	
		data4			 => internal_trig_data(16),					
		data5			 => internal_trig_data(17),	
		data6			 => internal_trig_data(18),
		data7			 => internal_trig_data(19),					
		data8			 => internal_trig_data(20),
		data9			 => internal_trig_data(21),
		data10		 => internal_trig_data(22),
		data11		 => internal_trig_data(23),	
		trig_en		 => trigger_ctrl2_trig_domain(1 downto 0),
		trig_mode	 => trigger_ctrl2_trig_domain(5),
		trig_mask	 => trigger_ctrl2_trig_domain(27 downto 16),
		trig_hit_rq	 => trigger_ctrl2_trig_domain(4 downto 2),
		trig_window	 => trigger_ctrl2_trig_domain(11 downto 8),
		thresh0	 	 => coinc_trig_threshold(12),
		thresh1	 	 => coinc_trig_threshold(13),
		thresh2	 	 => coinc_trig_threshold(14),
		thresh3	 	 => coinc_trig_threshold(15),
		thresh4	 	 => coinc_trig_threshold(16),
		thresh5	 	 => coinc_trig_threshold(17),
		thresh6	 	 => coinc_trig_threshold(18),
		thresh7	 	 => coinc_trig_threshold(19),
		thresh8	 	 => coinc_trig_threshold(20),
		thresh9	 	 => coinc_trig_threshold(21),
		thresh10	 	 => coinc_trig_threshold(22),
		thresh11	 	 => coinc_trig_threshold(23),
		last_trigger_hit_pattern_o	=> last_coinc_trig_hit_pattern_trig_clk(23 downto 12),
		singles_o	 => coinc_trig1_hit_singles, --//for scalers. Note that singles are still active even if channel masked from trig
		trig_o		 => internal_coinc_trig_mf(1));
--------------------------------------
inst_beam_trig : entity work.beamforming_trig
	port map(
		arstn        => arstn,
      clk			 => clk_trig,							
		data0			 => internal_trig_data(0),	--8 samples of 8 bit data
		data1			 => internal_trig_data(1),					
		data2			 => internal_trig_data(2),
		data3			 => internal_trig_data(3),	
		beamform_en	 => ptrigger_ctrl_trig_domain(1 downto 0),
		beam_mask	 => ptrigger_ctrl_trig_domain(27 downto 16),
		chan_mask	 => ptrigger_ctrl_trig_domain(15 downto 12),
		gain_ctrl_sel=> ptrigger_ctrl_trig_domain(8),
		pow_width_sel=> ptrigger_ctrl_trig_domain(4),
		thresh0	 	 => beam_servo_threshold(0) & beam_trig_threshold(0),
		thresh1	 	 => beam_servo_threshold(1) & beam_trig_threshold(1),
		thresh2	 	 => beam_servo_threshold(2) & beam_trig_threshold(2),
		thresh3	 	 => beam_servo_threshold(3) & beam_trig_threshold(3),
		thresh4	 	 => beam_servo_threshold(4) & beam_trig_threshold(4),
		thresh5	 	 => beam_servo_threshold(5) & beam_trig_threshold(5),
		thresh6	 	 => beam_servo_threshold(6) & beam_trig_threshold(6),
		thresh7	 	 => beam_servo_threshold(7) & beam_trig_threshold(7),
		thresh8	 	 => beam_servo_threshold(8) & beam_trig_threshold(8),
		thresh9	 	 => beam_servo_threshold(9) & beam_trig_threshold(9),
		last_trigger_beam_power => open,
		last_trigger_hit_pattern_o => internal_last_beam_pattern_trig_clk,
		beamtrigs_o	 => beam_trigs_for_scalers,
		beamservos_o => beam_servos_for_scalers,
		trig_o		 => internal_phased_trig );
--------------------------------------		
inst_scalers : entity work.scalers_top
	port map(
		arst_i					=> not arstn, --//rst is active high on this module
		clk_i						=> clk_trig,
		rdclk_i					=> clk_rd,
		gate_i					=> internal_pps_trigclk(2),
		coinc_trig_singles 	=> coinc_trig1_hit_singles & coinc_trig0_hit_singles,
		coinc_trigs				=> internal_coinc_trig_mf,
		beam_trigs  			=> beam_trigs_for_scalers,
		beam_trig_servos 		=> beam_servos_for_scalers,
		total_beam_trig		=> internal_phased_trig,
		clkcounts_per_pps_i  => internal_clock_per_pps_counter_latched,
		scaler_sel_reg_i		=> scaler_sel_reg_i,
		scaler_to_read_o  	=> scaler_read_reg_o);
--------------------------------------
end rtl;