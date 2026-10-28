--
-- Power integration, no interpolation (INTERP_FACTOR = 1)
-- Integrates the power in a 4 sample window, stepping the window by 2 samples,
-- so each clock gives NUM_SAMPLES/2 overlapping windows per beam.
--
-- Input is mapped like Bm11 data (S3, S2, S1, S0) -> Bm0 (S3, S2, S1, S0), at 8-bit samples each
-- Output is mapped like Bm11 data (Avg 1, Avg 0) -> Bm0 data (Avg 1, Avg 0) at 16-bit samples each
--
-- Sample ordering follows the rest of the chain: a higher sample index is an older sample, and
-- sample index NUM_SAMPLES+j is sample j of the previous clock. Window p covers samples
-- 2p, 2p+1, 2p+2, 2p+3, so the last window of each clock reaches back into the previous clock:
--      NUM_SAMPLES = 4:  Avg 0 = S0..S3,   Avg 1 = S2, S3, prev S0, prev S1
--
-- Pipeline: power LUT (1 clk) -> pair sums (1 clk) -> window sums (1 clk) -> divide by 4 with rounding (1 clk)
--
-- Ryan Krebs (claude assisted)

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity power_integration_4 is
    generic(
		SAMPLE_LENGTH   : integer := 8;
		NUM_SAMPLES     : integer := 4;  -- samples per clock, must be even
		NUM_PA_CHANNELS : integer := 4;
		INTERP_FACTOR   : integer := 1;  -- kept so existing instantiations still compile; must be 1
        NUM_POWERS      : integer := 2;  -- must be NUM_SAMPLES/2
        POWER_LENGTH    : integer := 16;
		NUM_BEAMS : integer := 12);
    port(
            rst_i		: in std_logic;
            clk_data_i	: in std_logic; --data clock
            enable_i    : in std_logic;
            beam_data_i : in std_logic_vector(NUM_BEAMS*SAMPLE_LENGTH*NUM_SAMPLES-1 downto 0);
            power_o     : out std_logic_vector(POWER_LENGTH*NUM_POWERS*NUM_BEAMS-1 downto 0)
            );
    end power_integration_4;

architecture rtl of power_integration_4 is

    constant WINDOW_LENGTH : integer := 4; -- samples integrated per window
    constant WINDOW_STEP   : integer := 2; -- samples between window starts
    constant num_div       : integer := 2; -- log2(WINDOW_LENGTH), divide by 4 to get the average
    constant round_val     : unsigned(num_div-1 downto 0) := "10"; -- half an LSB, round half up

    constant phased_sum_power_bits : integer := 16; -- width of the power LUT output
    constant pair_bits   : integer := phased_sum_power_bits+1; -- sum of 2 powers
    constant window_bits : integer := phased_sum_power_bits+2; -- sum of 4 powers

    type phased_arr is array (NUM_BEAMS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal phased_beam_waves: phased_arr:= (others=>(others=>(others=>'0')));

    --instantaneous power
    type square_waveform is array (NUM_BEAMS-1 downto 0, NUM_SAMPLES-1 downto 0) of unsigned(phased_sum_power_bits-1 downto 0);
    signal phased_power : square_waveform:= (others=>(others=>(others=>'0')));

    --power summed over sample pairs (2k, 2k+1). index NUM_POWERS holds pair 0 from the previous clock,
    --which the last window needs
    type pair_array is array (NUM_BEAMS-1 downto 0, NUM_POWERS downto 0) of unsigned(pair_bits-1 downto 0);
    signal pair_sum : pair_array := (others=>(others=>(others=>'0')));

    --power summed over each 4 sample window: window p = pair p + pair p+1
    type window_array is array (NUM_BEAMS-1 downto 0, NUM_POWERS-1 downto 0) of unsigned(window_bits-1 downto 0);
    signal window_sum : window_array := (others=>(others=>(others=>'0')));

    type avg_power_array is array (NUM_BEAMS-1 downto 0, NUM_POWERS-1 downto 0) of unsigned(POWER_LENGTH-1 downto 0);
    signal avg_power: avg_power_array:=(others=>(others=>(others=>'0'))); --average power (window_sum shifted down)

    component power_lut_8 is --8 bit lut for calculating power
    port(
            clk_i   : in std_logic;
            a       : in	std_logic_vector(7 downto 0);
            z       : out	unsigned(15 downto 0));
    end component;
begin

assert INTERP_FACTOR = 1
    report "power_integration: this version only supports INTERP_FACTOR = 1" severity failure;
assert NUM_SAMPLES mod WINDOW_STEP = 0 and NUM_POWERS = NUM_SAMPLES/WINDOW_STEP
    report "power_integration: NUM_SAMPLES must be even and NUM_POWERS must be NUM_SAMPLES/2" severity failure;


assign_beam_i: for bm in 0 to NUM_BEAMS-1 generate
    assign_sams_i: for sam in 0 to NUM_SAMPLES-1 generate
        phased_beam_waves(bm,sam)<= signed(beam_data_i(bm*NUM_SAMPLES*SAMPLE_LENGTH+SAMPLE_LENGTH*(sam+1)-1 downto bm*NUM_SAMPLES*SAMPLE_LENGTH+SAMPLE_LENGTH*sam));
    end generate;
end generate;

assign_power_o: for bm in 0 to NUM_BEAMS-1 generate
    assign_powers_o: for pow in 0 to NUM_POWERS-1 generate
        power_o(POWER_LENGTH*NUM_POWERS*bm+POWER_LENGTH*(pow+1)-1 downto POWER_LENGTH*NUM_POWERS*bm+POWER_LENGTH*pow) <= std_logic_vector(avg_power(bm,pow));
    end generate;
end generate;


--calculate the power
--this just uses a LUT in logic to find the power from a signed value. 8 bits synth as bram, 7 bits as norm luts
DO_POWER_BEAM : for i in 0 to NUM_BEAMS-1 generate
    DO_POWER_SAMPLE : for j in 0 to NUM_SAMPLES-1 generate
        xPOWERLUT : power_lut_8
        port map(
        clk_i => clk_data_i,
        a => std_logic_vector(phased_beam_waves(i,j)),
        z => phased_power(i,j));
    end generate;
end generate;


--block to do the power integration
proc_avg_beam_power : process(rst_i, clk_data_i)
begin

    if rst_i = '1' then
        pair_sum   <= (others=>(others=>(others=>'0')));
        window_sum <= (others=>(others=>(others=>'0')));
        avg_power  <= (others=>(others=>(others=>'0')));

    elsif rising_edge(clk_data_i) then
	     if enable_i = '0' then
            pair_sum   <= (others=>(others=>(others=>'0')));
            window_sum <= (others=>(others=>(others=>'0')));
            avg_power  <= (others=>(others=>(others=>'0')));

		  else
			  for i in 0 to NUM_BEAMS-1 loop

					-- sum the power in each pair of samples, shared by the two windows that overlap it
					for k in 0 to NUM_POWERS-1 loop
						pair_sum(i,k) <= resize(phased_power(i,2*k),pair_bits) + resize(phased_power(i,2*k+1),pair_bits);
					end loop;
					pair_sum(i,NUM_POWERS) <= pair_sum(i,0); -- pair 0 delayed by one clock

					-- 4 sample windows, stepped by 2 samples
					for p in 0 to NUM_POWERS-1 loop
						window_sum(i,p) <= resize(pair_sum(i,p),window_bits) + resize(pair_sum(i,p+1),window_bits);
					end loop;

					-- just resize - 16-bit thresholds more more than enough with the reduced sample bit lengths
					for p in 0 to NUM_POWERS-1 loop
                        avg_power(i,p)<=resize(window_sum(i,p),power_length);
					end loop;

			  end loop;
		  end if;
    end if;
end process;


end rtl;