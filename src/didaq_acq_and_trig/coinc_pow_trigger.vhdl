---------------------------------------------------------------------------------
-- Penn State
--    --Dept. of Physics--
--
-- PROJECT:      DiDAQ 24 Channel Board
-- FILE:         coinc_trigger.vhdl
-- AUTHOR:       Ryan Krebs
-- EMAIL         rjk5416@psu.edu
-- DATE:         8/11/2026
--
-- DESCRIPTION:  coincidence-based power integration trigger on 24 maskable channels for two separate triggers (masks).
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pow_lut.all;

entity coinc_triggers_24_ch is
generic(
	NUM_CHANNELS : integer := 24;
	SAMPLE_LENGTH : integer := 8;
	NUM_SAMPLES : integer := 8
);
port(
		rst_i			: in std_logic; --global reset on start up
		clk_i			: in std_logic; -- data clock
		ch_data_i		: in std_logic_vector(NUM_CHANNELS*NUM_SAMPLES*SAMPLE_LENGTH - 1 downto 0); --formated where 4 samples of a channel are continuous
		ch_data_valid_i	: in std_logic_vector(NUM_CHANNELS-1 downto 0);

		trig_0_enable_i		: in std_logic; -- from regs
		trig_0_out_en_i		: in std_logic;
		trig_0_ch_mask_i	: in std_logic_vector(NUM_CHANNELS-1 downto 0); -- from regs

		trig_1_enable_i		: in std_logic; -- from regs
		trig_1_out_en_i		: in std_logic;
		trig_1_ch_mask_i	: in std_logic_vector(NUM_CHANNELS-1 downto 0); -- from regs

		trig_0_coinc_window_i		: in std_logic_vector(4 downto 0); --from regs
		trig_1_coinc_window_i		: in std_logic_vector(4 downto 0); --from regs

		trig_0_num_coinc_i			: in std_logic_vector(4 downto 0); -- from regs
		trig_1_num_coinc_i			: in std_logic_vector(4 downto 0); -- from regs

		trig_0_num_over_t_i : in std_logic_vector(3 downto 0);
		trig_1_num_over_t_i : in std_logic_vector(3 downto 0);

		trig_thresholds_i	: in std_logic_vector(NUM_CHANNELS*16-1 downto 0); -- from regs, common set of thresholds across triggers

		trig_bits_o			: out std_logic_vector(NUM_CHANNELS-1 downto 0) := (others=>'0'); --24 ch trig
		trig_0_o			: out std_logic := '0'; --trigger output
		trig_metadata_o		: out std_logic_vector(NUM_CHANNELS-1 downto 0):= (others=>'0'); --triggering channels causing trig_0_o, same time as trig_0_o
		trig_1_o			: out std_logic := '0' --trigger output
		);
end coinc_triggers_24_ch;

architecture rtl of coinc_triggers_24_ch is

	signal internal_trig_en : std_logic := '0'; --enable this trigger block from sw
	signal trig_0_internal_trig_en : std_logic := '0'; --enable this trigger block from sw
	signal trig_1_internal_trig_en : std_logic := '0'; --enable this trigger block from sw

	signal trig_0_coinc_require_int : unsigned(4 downto 0) := "00010"; --num of channels needed in coincidence
	signal trig_1_coinc_require_int : unsigned(4 downto 0) := "00010"; --num of channels needed in coincidence

	signal trig_0_coinc_window_int	: unsigned(4 downto 0) := "01000"; --//num of clk_i periods
	signal trig_1_coinc_window_int	: unsigned(4 downto 0) := "01000"; --//num of clk_i periods


	constant baseline : unsigned(7 downto 0) := x"80";

	signal trig_0_channel_mask : std_logic_vector(NUM_CHANNELS-1 downto 0):=x"00f000";
	signal trig_1_channel_mask : std_logic_vector(NUM_CHANNELS-1 downto 0):=x"0f0000";
	signal global_channel_mask : std_logic_vector(NUM_CHANNELS-1 downto 0):=x"0f0000";

	
	signal trig_0_triggering_channels: std_logic_vector(NUM_CHANNELS-1 downto 0):=x"000000"; --metadata to record which are causing trigger
	signal trig_1_triggering_channels: std_logic_vector(NUM_CHANNELS-1 downto 0):=x"000000"; --metadata to record which are causing trigger
	signal trig_0_triggering_channels_past: std_logic_vector(NUM_CHANNELS-1 downto 0):=x"000000"; --metadata to record which are causing trigger
	signal trig_1_triggering_channels_past: std_logic_vector(NUM_CHANNELS-1 downto 0):=x"000000"; --metadata to record which are causing trigger

	signal triggering_channels_past_past: std_logic_vector(NUM_CHANNELS-1 downto 0):=x"000000"; --metadata to record which are causing trigger


	type threshold_array is array (NUM_CHANNELS-1 downto 0) of unsigned(15 downto 0);
	signal trig_threshold_int	: threshold_array := (others=>(others=>'0'));

	type streaming_data_array is array(NUM_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
	signal streaming_data	:streaming_data_array := (others=>(others=>(others=>'0'))); --pipelined trigger data

	type streaming_sat_array is array(NUM_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(6 downto 0);
	signal streaming_sat	:streaming_sat_array := (others=>(others=>(others=>'0'))); --pipelined trigger data

	type streaming_pow_array is array(NUM_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of unsigned(13 downto 0);
	signal streaming_pow	:streaming_pow_array := (others=>(others=>(others=>'0'))); --pipelined trigger data

	type streaming_sum_array is array(NUM_CHANNELS-1 downto 0, 1 downto 0) of unsigned(15 downto 0);
	signal streaming_sum	:streaming_sum_array := (others=>(others=>(others=>'0'))); --pipelined trigger data

	type streaming_sum_win_array is array(NUM_CHANNELS-1 downto 0) of unsigned(15 downto 0);
	signal streaming_sum_win : streaming_sum_win_array := (others=>(others=>'0'));

	type coincidence_array is array(NUM_CHANNELS-1 downto 0) of std_logic_vector(31 downto 0);
	signal trig_0_channel_trig_reg		: coincidence_array := (others=>(others=>'0')); --for coincidencing
	signal trig_0_channel_trig_win_reg		: coincidence_array := (others=>(others=>'0')); --for clocks over threshold

	signal trig_1_channel_trig_reg		: coincidence_array := (others=>(others=>'0')); --for coincidencing
	signal trig_1_channel_trig_win_reg		: coincidence_array := (others=>(others=>'0')); --for clocks over threshold
	
	signal trig_array_for_scalers : std_logic_vector(NUM_CHANNELS-1 downto 0) := (others=>'0'); -- on clk_data, 1 for total trig, 24 for channel trig, and then servos

	signal trig_0_coincidence_trigger_reg : std_logic_vector(1 downto 0) := (others=>'0');
	signal trig_0_coincidence_trigger : std_logic :='0'; --actual trigger, one clk_i cycle

	signal trig_1_coincidence_trigger_reg : std_logic_vector(1 downto 0) := (others=>'0');
	signal trig_1_coincidence_trigger : std_logic :='0'; --actual trigger, one clk_i cycle

	signal trig_0_comp : std_logic_vector(2**trig_0_num_over_t_i'length downto 0) := (others=>'0');
	signal trig_1_comp : std_logic_vector(2**trig_1_num_over_t_i'length downto 0) := (others=>'0');
	
	signal trig_0_count_ones : unsigned(4 downto 0) := (others=>'0');
	signal trig_1_count_ones : unsigned(4 downto 0) := (others=>'0');

	function count_ones(v : std_logic_vector) return unsigned is
	  variable cnt : unsigned(4 downto 0) := (others=>'0');
		begin
		  for i in v'range loop
			 if v(i) = '1' then
				cnt := cnt + 1;
			 end if;
		  end loop;
		  return cnt;
	end function count_ones;

begin

	proc_enable : process(clk_i)
	begin
		if rst_i = '1' then
			internal_trig_en <= '0';
			global_channel_mask <= (others=>'0');
		elsif rising_edge(clk_i) then
			internal_trig_en <= trig_0_internal_trig_en or trig_1_internal_trig_en;
			global_channel_mask <= trig_0_channel_mask or trig_1_channel_mask;
		end if;
	end process;

	-- does everything from pulling in data, removing, baseline, saturating the bit lengths, getting inst power
	proc_pipeline_data : process(clk_i)
	begin
		if rst_i = '1' or internal_trig_en = '0' then
			streaming_data <= (others=>(others=>(others=>'0')));
			streaming_sat <= (others=>(others=>(others=>'0')));
			streaming_pow <= (others=>(others=>(others=>'0')));

		elsif rising_edge(clk_i) then

			for i in 0 to NUM_CHANNELS-1 loop
				for j in 0 to NUM_SAMPLES-1 loop

					if ch_data_valid_i(i) = '1' and global_channel_mask(i) = '1' then
						streaming_data(i,j) <= signed(unsigned(ch_data_i(i*NUM_SAMPLES*SAMPLE_LENGTH+(j+1)*SAMPLE_LENGTH-1 downto i*NUM_SAMPLES*SAMPLE_LENGTH+j*SAMPLE_LENGTH))-baseline);
						
						if streaming_data(i,j) > 127 then
							streaming_sat(i,j) <= "0111111";
						elsif streaming_data(i,j) < -128 then
							streaming_sat(i,j) <= "1000000";
						else
							streaming_sat(i,j) <= resize(streaming_data(i,j), 7);
						end if;

						streaming_pow(i,j) <= to_unsigned(lut_power(to_integer(streaming_sat(i,j))), 14);

					else

						streaming_data(i,j)<=(others=>'0'); 
						streaming_sat(i,j)<=(others=>'0'); 
						streaming_pow(i,j)<=(others=>'0'); 

					end if;
				end loop;
			end loop;

		end if;
	end process;


	proc_power_sum : process(clk_i, rst_i)
	begin
		if rst_i = '1' or internal_trig_en = '0' then
			streaming_sum <= (others=>(others=>(others=>'0')));
			streaming_sum_win <= (others=>(others=>'0'));
		
		elsif rising_edge(clk_i) then

			for i in 0 to NUM_CHANNELS-1 loop
				if global_channel_mask(i) = '1' then
					streaming_sum(i,0) <= resize(streaming_pow(i,0),16) + streaming_pow(i,1) + streaming_pow(i,2) + streaming_pow(i,3);
					streaming_sum(i,1) <= resize(streaming_pow(i,4),16) + streaming_pow(i,5) + streaming_pow(i,6) + streaming_pow(i,7);
					--streaming_sum_win(i) <= resize(streaming_sum(i,0), 16) + streaming_sum(i,1);
				else
					streaming_sum(i,0) <= (others=>'0');
					streaming_sum(i,1) <= (others=>'0');
					--streaming_sum_win(i) <= (others=>'0');
				end if;
			end loop;

		end if;
	end process;

	-- single channel trigger bits with clocks over threshold and aggregating coincidencing windows
	proc_single_channel : process(clk_i, rst_i)
	begin
		for i in 0 to NUM_CHANNELS-1 loop
			if rst_i = '1' or internal_trig_en = '0' then
				trig_0_channel_trig_reg(i) 	<= (others=>'0');
				trig_0_channel_trig_win_reg(i) 	<= (others=>'0');
				trig_1_channel_trig_reg(i) 	<= (others=>'0');
				trig_1_channel_trig_win_reg(i) 	<= (others=>'0');
				trig_0_comp <= (others=>'0');
				trig_1_comp <= (others=>'0');

			elsif rising_edge(clk_i) then

				case trig_0_num_over_t_i is
					when "0000" => trig_0_comp(0 downto 0) <= "1";
					when "0001" => trig_0_comp(1 downto 0) <= "11";
					when "0010" => trig_0_comp(2 downto 0) <= "111";
					when "0011" => trig_0_comp(3 downto 0) <= "1111";
					when "0100" => trig_0_comp(4 downto 0) <= "11111";
					when "0101" => trig_0_comp(5 downto 0) <= "111111";
					when "0110" => trig_0_comp(6 downto 0) <= "1111111";
					when "0111" => trig_0_comp(7 downto 0) <= "11111111";
					when "1000" => trig_0_comp(8 downto 0) <= "111111111";
					when "1001" => trig_0_comp(9 downto 0) <= "1111111111";
					when others => trig_0_comp(9 downto 0) <= "1111111111";
				end case;
					
				--trig_0_comp <= "0111"; --std_logic_vector(shift_left(to_unsigned(1, trig_0_comp'length),
                           --to_integer(unsigned(trig_0_num_over_t_i))) - 1);

				-- trig 0 stuff
				if streaming_sum(i,0) > trig_threshold_int(i) and trig_0_channel_mask(i) = '1' then
					trig_0_channel_trig_win_reg(i)(0) <= '1';
				else
					trig_0_channel_trig_win_reg(i)(0) <= '0';
				end if;
				
				if streaming_sum(i,1) > trig_threshold_int(i) and trig_0_channel_mask(i) = '1' then
					trig_0_channel_trig_win_reg(i)(1) <= '1';
				else
					trig_0_channel_trig_win_reg(i)(1) <= '0';
				end if;
				
				--if trig_0_channel_trig_win_reg(i)(to_integer(unsigned(trig_0_num_over_t_i)) downto 0) = trig_0_comp then
				if trig_0_channel_trig_win_reg(i)(to_integer(unsigned(trig_0_num_over_t_i)) downto 0) = trig_0_comp(to_integer(unsigned(trig_0_num_over_t_i)) downto 0) then
					trig_0_channel_trig_reg(i)(0) <= '1';
				else
					trig_0_channel_trig_reg(i)(0) <= '0';
				end if;
				
				--if trig_0_channel_trig_win_reg(i)(to_integer(unsigned(trig_0_num_over_t_i))+1 downto 1) = trig_0_comp then
				if trig_0_channel_trig_win_reg(i)(to_integer(unsigned(trig_0_num_over_t_i))+1 downto 1) = trig_0_comp(to_integer(unsigned(trig_0_num_over_t_i)) downto 0) then
					trig_0_channel_trig_reg(i)(1) <= '1';
				else
					trig_0_channel_trig_reg(i)(1) <= '0';
				end if;
					
				trig_0_channel_trig_reg(i)(31 downto 2) <= trig_0_channel_trig_reg(i)(29 downto 0);
				trig_0_channel_trig_win_reg(i)(31 downto 2) <= trig_0_channel_trig_win_reg(i)(29 downto 0);

				-- trig 1 stuff
				case trig_1_num_over_t_i is
					when "0000" => trig_1_comp(0 downto 0) <= "1";
					when "0001" => trig_1_comp(1 downto 0) <= "11";
					when "0010" => trig_1_comp(2 downto 0) <= "111";
					when "0011" => trig_1_comp(3 downto 0) <= "1111";
					when "0100" => trig_1_comp(4 downto 0) <= "11111";
					when "0101" => trig_1_comp(5 downto 0) <= "111111";
					when "0110" => trig_1_comp(6 downto 0) <= "1111111";
					when "0111" => trig_1_comp(7 downto 0) <= "11111111";
					when "1000" => trig_1_comp(8 downto 0) <= "111111111";
					when "1001" => trig_1_comp(9 downto 0) <= "1111111111";
					when others => trig_1_comp(9 downto 0) <= "1111111111";
				end case;
				--trig_1_comp <= "0111"; --std_logic_vector(shift_left(to_unsigned(1, trig_1_comp'length),
                           --to_integer(unsigned(trig_1_num_over_t_i))) - 1);
								  
				if streaming_sum(i,0) > trig_threshold_int(i) and trig_1_channel_mask(i) = '1' then
					trig_1_channel_trig_win_reg(i)(0) <= '1';
				else
					trig_1_channel_trig_win_reg(i)(0) <= '0';
				end if;
				if streaming_sum(i,1) > trig_threshold_int(i) and trig_1_channel_mask(i) = '1' then
					trig_1_channel_trig_win_reg(i)(1) <= '1';
				else
					trig_1_channel_trig_win_reg(i)(1) <= '0';
				end if;

				if trig_1_channel_trig_win_reg(i)(to_integer(unsigned(trig_1_num_over_t_i)) downto 0) = trig_1_comp(to_integer(unsigned(trig_1_num_over_t_i)) downto 0) then
					trig_1_channel_trig_reg(i)(0) <= '1';
				else
					trig_1_channel_trig_reg(i)(0) <= '0';
				end if;
				
				if trig_1_channel_trig_win_reg(i)(to_integer(unsigned(trig_1_num_over_t_i))+1 downto 1) = trig_1_comp(to_integer(unsigned(trig_1_num_over_t_i)) downto 0) then
					trig_1_channel_trig_reg(i)(1) <= '1';
				else
					trig_1_channel_trig_reg(i)(1) <= '0';
				end if;

				trig_1_channel_trig_reg(i)(31 downto 2) <= trig_1_channel_trig_reg(i)(29 downto 0);
				trig_1_channel_trig_win_reg(i)(31 downto 2) <= trig_1_channel_trig_win_reg(i)(29 downto 0);

			end if;
		end loop;
	end process;

	--coinc window
	proc_coinc_trig : process(rst_i, clk_i)
	begin
		if rst_i = '1' or internal_trig_en = '0'then
			trig_0_triggering_channels<=(others=>'0');
			trig_1_triggering_channels<=(others=>'0');
			trig_0_triggering_channels_past<=(others=>'0');
			trig_1_triggering_channels_past<=(others=>'0');

			trig_0_coincidence_trigger_reg <= "00";
			trig_0_coincidence_trigger <= '0'; -- the trigger

			trig_1_coincidence_trigger_reg <= "00";
			trig_1_coincidence_trigger <= '0'; -- the trigger

		elsif rising_edge(clk_i) then
			-- aggregate over-threshold windows for ch coincidencing
			for i in 0 to NUM_CHANNELS-1 loop
				if unsigned(trig_0_channel_trig_reg(i)(to_integer(unsigned(trig_0_coinc_window_int)) downto 0)) > 0 then
					trig_0_triggering_channels(i) <= '1';
				else
					trig_0_triggering_channels(i) <= '0';
				end if;

				if unsigned(trig_1_channel_trig_reg(i)(to_integer(unsigned(trig_1_coinc_window_int)) downto 0)) > 0 then
					trig_1_triggering_channels(i) <= '1';
				else
					trig_1_triggering_channels(i) <= '0';
				end if;

			end loop;

			-- sync trigger_o and triggering_channels meta data
			trig_0_triggering_channels_past <= trig_0_triggering_channels;
			trig_1_triggering_channels_past <= trig_1_triggering_channels;

			--triggering_channels_past_past <= triggering_channels_past;


			-- now find multi-channel coincidence for trig 0
			--if unsigned(trig_0_triggering_channels and trig_0_channel_mask) > trig_0_coinc_require_int and trig_0_internal_trig_en='1' then
			if (count_ones(trig_0_triggering_channels and trig_0_channel_mask) > trig_0_coinc_require_int) and trig_0_internal_trig_en='1' then
				trig_0_coincidence_trigger_reg(0) <= '1';
			else
				trig_0_coincidence_trigger_reg(0) <= '0';
			end if;
			

			-- now find multi-channel coincidence for trig 1
			if (count_ones(trig_1_triggering_channels and trig_1_channel_mask) > trig_1_coinc_require_int)  and trig_1_internal_trig_en='1'  then
				trig_1_coincidence_trigger_reg(0) <= '1';
			else
				trig_1_coincidence_trigger_reg(0) <= '0';
			end if;
			

			-- save last state of the trigger to find 0->1 transition
			-- might be able to just use 'event
			trig_0_coincidence_trigger_reg(1) <= trig_0_coincidence_trigger_reg(0);
			trig_1_coincidence_trigger_reg(1) <= trig_1_coincidence_trigger_reg(0);

			-- if 0->1 transition actually send a trigger so the output trigger signal doesn't get stuck high
			-- trig 0
			if trig_0_coincidence_trigger_reg = "01" and trig_1_coincidence_trigger_reg = "01" then
				trig_0_coincidence_trigger <= '1';
				trig_1_coincidence_trigger <= '1';
				trig_metadata_o <= (trig_0_triggering_channels_past and trig_0_channel_mask) or (trig_1_triggering_channels_past and trig_1_channel_mask);
			elsif trig_0_coincidence_trigger_reg = "01" then
				trig_0_coincidence_trigger <= '1';
				trig_1_coincidence_trigger <= '0';
				trig_metadata_o <= trig_0_triggering_channels_past and trig_0_channel_mask;
			elsif trig_1_coincidence_trigger_reg = "01" then
				trig_0_coincidence_trigger <= '0';
				trig_1_coincidence_trigger <= '1';
				trig_metadata_o <= trig_1_triggering_channels_past and trig_1_channel_mask;
			else
				trig_0_coincidence_trigger <= '0';
				trig_1_coincidence_trigger <= '0';
				trig_metadata_o <= (others=>'0');
			end if;
		end if;
	end process;
	
	trig_0_o <= trig_0_coincidence_trigger;
	trig_1_o <= trig_1_coincidence_trigger;

	trig_array_for_scalers <= (trig_0_triggering_channels(NUM_CHANNELS-1 downto 0) or trig_1_triggering_channels(NUM_CHANNELS-1 downto 0));	 

	trig_bits_o <= trig_array_for_scalers;

	trig_0_internal_trig_en <= trig_0_enable_i;
	trig_1_internal_trig_en <= trig_1_enable_i;

	trig_0_coinc_require_int <= unsigned(trig_0_num_coinc_i);
	trig_1_coinc_require_int <= unsigned(trig_1_num_coinc_i);

	trig_0_coinc_window_int <= unsigned(trig_0_coinc_window_i);
	trig_1_coinc_window_int <= unsigned(trig_1_coinc_window_i);


	trig_0_channel_mask <= trig_0_ch_mask_i;
	trig_1_channel_mask <= trig_1_ch_mask_i;

	syncs : for ch in 0 to NUM_CHANNELS-1 generate
				trig_threshold_int(ch) <= unsigned(trig_thresholds_i(16*(ch+1)-1 downto 16*ch));
	end generate;
	
end rtl;