---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         scalers_top.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         7/2017
--
--	* RK - added scalers for beams 10-11, scaler pps moved to 91
--
-- DESCRIPTION:  manage board scalers and readout of scalers 
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity scalers_top is
	generic(
		scaler_width   : integer := 16);
	port(
		arst_i			:		in		std_logic;
		clk_i				:		in 	std_logic;
		rdclk_i			: 		in 	std_logic;
		gate_i			:		in		std_logic; --pps

		coinc_trig_singles : in   std_logic_vector(23 downto 0);
		coinc_trigs			: in 	std_logic_Vector(1 downto 0);
		beam_trigs  : in std_logic_vector(11 downto 0);
		beam_trig_servos : in std_logic_Vector(11 downto 0);
		total_beam_trig : in std_logic; --phased trig total
		clkcounts_per_pps_i : std_logic_Vector(31 downto 0);
		
		scaler_sel_reg_i	:   in	std_logic_Vector(31 downto 0);
		scaler_to_read_o  :   out	std_logic_vector(31 downto 0));
end scalers_top;

architecture rtl of scalers_top is

constant num_scalers : integer := 92;
type scaler_array_type is array(num_scalers-1 downto 0) of std_logic_vector(scaler_width-1 downto 0);

signal internal_scaler_array : scaler_array_type := (others=>(others=>'0'));
signal internal_scaler_array_rd_clk_mf : scaler_array_type;
signal internal_scaler_array_rd_clk : scaler_array_type;

signal latched_scaler_array : scaler_array_type; --//assigned after refresh pulse
signal latched_pps_cycle_counter : std_logic_vector(47 downto 0);

--//need to create a single pulse every Hz with width of clk_i period
signal refresh_clk_counter_1Hz 	:	std_logic_vector(31 downto 0) := (others=>'0');
signal refresh_clk_counter_100mHz:	std_logic_vector(31 downto 0) := (others=>'0');
signal refresh_clk_1Hz				:	std_logic := '0';
signal refresh_clk_100mHz			:	std_logic := '0';
--//for 125 MHz clk_i
constant REFRESH_CLK_MATCH_1HZ 		: 	std_logic_vector(31 downto 0) 	:= x"07735940";  
constant REFRESH_CLK_MATCH_100mHz 	: 	std_logic_vector(31 downto 0) 	:= x"4A817C80";  	
component scaler
port(
	rst_i 		: in 	std_logic;
	clk_i			: in	std_logic;
	refresh_i	: in	std_logic;
	count_i		: in	std_logic;
	scaler_o		: out std_logic_vector(scaler_width-1 downto 0));
end component;
-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--//scaler 91 is the `scaler pps' -- sanity check that the scalers are updating
proc_scaler_pps : process(clk_i, refresh_clk_1Hz)
begin
	if arst_i = '1' then
		internal_scaler_array(91) <= (others=>'0');
	elsif rising_edge(clk_i) and refresh_clk_1Hz = '1' then
		internal_scaler_array(91) <= internal_scaler_array(91) + 1;
	end if;
end process;
---------------------------------------------
CoincSingles1Hz : for i in 0 to 23 generate
	xCoincSingles1Hz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_1Hz,
		count_i => coinc_trig_singles(i),
		scaler_o => internal_scaler_array(i));
end generate;
--------------------------------------------- 24
CoincTrigScalers1HzGated : for i in 0 to 23 generate
	xCoincTrigScalers1HzGated : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_1Hz,
		count_i => coinc_trig_singles(i) and gate_i,
		scaler_o => internal_scaler_array(i+24));
end generate;
--------------------------------------------- 48
Coinc100mHz : for i in 0 to 1 generate
	xCoinc100mHz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => coinc_trigs(i),
		scaler_o => internal_scaler_array(i+48));
end generate;
--------------------------------------------- 50
Coinc100mHzGated : for i in 0 to 1 generate
	xCoinc100mHzGated : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => coinc_trigs(i) and gate_i,
		scaler_o => internal_scaler_array(i+50));
end generate;
--------------------------------------------- 52
BeamTrig100mHz : for i in 0 to 11 generate
	xBeamTrig100mHz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => beam_trigs(i),
		scaler_o => internal_scaler_array(i+52));
end generate;
--------------------------------------------- 64
BeamTrig100mHzGated : for i in 0 to 11 generate
	xBeamTrig100mHzGated : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => beam_trigs(i) and gate_i,
		scaler_o => internal_scaler_array(i+64));
end generate;
--------------------------------------------- 76
BeamServo1Hz : for i in 0 to 11 generate
	xBeamServo1Hz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_1Hz,
		count_i => beam_trig_servos(i),
		scaler_o => internal_scaler_array(i+76));
end generate;
--------------------------------------------- 88
TotalBeamTrig100mHz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => total_beam_trig,
		scaler_o => internal_scaler_array(88));
TotalBeamTrig100mHzGated : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_100mHz,
		count_i => total_beam_trig and gate_i,
		scaler_o => internal_scaler_array(89));
TotalBeamTrig1Hz : scaler
	port map(
		rst_i => arst_i,
		clk_i => clk_i,
		refresh_i => refresh_clk_1Hz,
		count_i => total_beam_trig,
		scaler_o => internal_scaler_array(90));

-------------------------------------		
proc_save_scalers : process(arst_i, rdclk_i)
begin
	if arst_i = '1' then
		for i in 0 to num_scalers-1 loop
			latched_scaler_array(i) <= (others=>'0');
		end loop;
		scaler_to_read_o <= (others=>'0');
		internal_scaler_array_rd_clk_mf <= (others=>(others=>'0'));
		internal_scaler_array_rd_clk 	  <= (others=>(others=>'0'));

	elsif rising_edge(rdclk_i) then
		internal_scaler_array_rd_clk		<= internal_scaler_array_rd_clk_mf;
		internal_scaler_array_rd_clk_mf 	<= internal_scaler_array;
		
		if scaler_sel_reg_i(16) = '1' then
			latched_scaler_array <= internal_scaler_array_rd_clk;
		else -- don't read latched scalers while they are updating
			case scaler_sel_reg_i(7 downto 0) is
				when x"00" => scaler_to_read_o <= latched_scaler_array(1) & latched_scaler_array(0);
				when x"01" => scaler_to_read_o <= latched_scaler_array(3) & latched_scaler_array(2);
				when x"02" => scaler_to_read_o <= latched_scaler_array(5) & latched_scaler_array(4);
				when x"03" => scaler_to_read_o <= latched_scaler_array(7) & latched_scaler_array(6);
				when x"04" => scaler_to_read_o <= latched_scaler_array(9) & latched_scaler_array(8);
				when x"05" => scaler_to_read_o <= latched_scaler_array(11) & latched_scaler_array(10);
				when x"06" => scaler_to_read_o <= latched_scaler_array(13) & latched_scaler_array(12);
				when x"07" => scaler_to_read_o <= latched_scaler_array(15) & latched_scaler_array(14);
				when x"08" => scaler_to_read_o <= latched_scaler_array(17) & latched_scaler_array(16);
				when x"09" => scaler_to_read_o <= latched_scaler_array(19) & latched_scaler_array(18);
				when x"0A" => scaler_to_read_o <= latched_scaler_array(21) & latched_scaler_array(20);
				when x"0B" => scaler_to_read_o <= latched_scaler_array(23) & latched_scaler_array(22);
				when x"0C" => scaler_to_read_o <= latched_scaler_array(25) & latched_scaler_array(24);
				when x"0D" => scaler_to_read_o <= latched_scaler_array(27) & latched_scaler_array(26);
				when x"0E" => scaler_to_read_o <= latched_scaler_array(29) & latched_scaler_array(28);
				when x"0F" => scaler_to_read_o <= latched_scaler_array(31) & latched_scaler_array(30);	
				when x"10" => scaler_to_read_o <= latched_scaler_array(33) & latched_scaler_array(32);
				when x"11" => scaler_to_read_o <= latched_scaler_array(35) & latched_scaler_array(34);
				when x"12" => scaler_to_read_o <= latched_scaler_array(37) & latched_scaler_array(36);
				when x"13" => scaler_to_read_o <= latched_scaler_array(39) & latched_scaler_array(38);
				when x"14" => scaler_to_read_o <= latched_scaler_array(41) & latched_scaler_array(40);
				when x"15" => scaler_to_read_o <= latched_scaler_array(43) & latched_scaler_array(42);
				when x"16" => scaler_to_read_o <= latched_scaler_array(45) & latched_scaler_array(44);
				when x"17" => scaler_to_read_o <= latched_scaler_array(47) & latched_scaler_array(46);
				when x"18" => scaler_to_read_o <= latched_scaler_array(49) & latched_scaler_array(48);
				when x"19" => scaler_to_read_o <= latched_scaler_array(51) & latched_scaler_array(50);	
				when x"1A" => scaler_to_read_o <= latched_scaler_array(53) & latched_scaler_array(52);				
				when x"1B" => scaler_to_read_o <= latched_scaler_array(55) & latched_scaler_array(54);				
				when x"1C" => scaler_to_read_o <= latched_scaler_array(57) & latched_scaler_array(56);				
				when x"1D" => scaler_to_read_o <= latched_scaler_array(59) & latched_scaler_array(58);				
				when x"1E" => scaler_to_read_o <= latched_scaler_array(61) & latched_scaler_array(60);				
				when x"1F" => scaler_to_read_o <= latched_scaler_array(63) & latched_scaler_array(62);		
				when x"20" => scaler_to_read_o <= latched_scaler_array(65) & latched_scaler_array(64);		
				when x"21" => scaler_to_read_o <= latched_scaler_array(67) & latched_scaler_array(66);		
				when x"22" => scaler_to_read_o <= latched_scaler_array(69) & latched_scaler_array(68);		
				when x"23" => scaler_to_read_o <= latched_scaler_array(71) & latched_scaler_array(70);		
				when x"24" => scaler_to_read_o <= latched_scaler_array(73) & latched_scaler_array(72);		
				when x"25" => scaler_to_read_o <= latched_scaler_array(75) & latched_scaler_array(74);		
				when x"26" => scaler_to_read_o <= latched_scaler_array(77) & latched_scaler_array(76);		
				when x"27" => scaler_to_read_o <= latched_scaler_array(79) & latched_scaler_array(78);		
				when x"28" => scaler_to_read_o <= latched_scaler_array(81) & latched_scaler_array(80);		
				when x"29" => scaler_to_read_o <= latched_scaler_array(83) & latched_scaler_array(82);	
				when x"2A" => scaler_to_read_o <= latched_scaler_array(85) & latched_scaler_array(84);		
				when x"2B" => scaler_to_read_o <= latched_scaler_array(87) & latched_scaler_array(86);	
				when x"2C" => scaler_to_read_o <= latched_scaler_array(89) & latched_scaler_array(88);
				when x"2D" => scaler_to_read_o <= latched_scaler_array(91) & latched_scaler_array(90);

				when x"2F" => scaler_to_read_o <= clkcounts_per_pps_i;		

				when others =>
					scaler_to_read_o <= x"DEADBEEF";
			end case;
		end if;
	end if;
end process;

-------------------------------------------------------------------
--//make 1 Hz and 100mHz refresh pulses from the clk_i
proc_make_refresh_pulse : process(clk_i)
begin
	if rising_edge(clk_i) then
		
		if refresh_clk_1Hz = '1' then
			refresh_clk_counter_1Hz <= (others=>'0');
		else
			refresh_clk_counter_1Hz <= refresh_clk_counter_1Hz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_1Hz is
			when REFRESH_CLK_MATCH_1HZ =>
				refresh_clk_1Hz <= '1';
			when others =>
				refresh_clk_1Hz <= '0';
		end case;
		
		--//////////////////////////////////////
		
		if refresh_clk_100mHz = '1' then
			refresh_clk_counter_100mHz <= (others=>'0');
		else
			refresh_clk_counter_100mHz <= refresh_clk_counter_100mHz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_100mHz is
			when REFRESH_CLK_MATCH_100mHz =>
				refresh_clk_100mHz <= '1';
			when others =>
				refresh_clk_100mHz <= '0';
		end case;
		
	end if;
end process;
end rtl;