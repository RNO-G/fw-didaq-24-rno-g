-- lowpass filter to reduce bandwidth from 500MHz to ~250MHz
-- some signal names are carried over from the upsampling code
-- should be paramerized for N (4 or 8 here) samples per clock
--
-- Input sample data is structured like Ch3 data (SN, ..., S1, S0) -> Ch0 data (SN, ..., S1, S0) at n-bit samples each
-- Output is similarly structured Ch3 data (SN, ..., S1, S0) -> Ch0 data (SN, ..., S1, S0) at n-bit samples each
--
-- Ryan Krebs

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity lowpass is
    generic(
		SAMPLE_LENGTH   : integer := 8;
		NUM_SAMPLES     : integer := 4;
		NUM_PA_CHANNELS : integer := 4
		);
    port(
            rst_i       : in std_logic;
            clk_data_i  : in std_logic;
            enable_i    : in std_logic;
            ch_data_i   : in std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS -1 downto 0);
            ch_data_o   : out std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS -1 downto 0)
            );
    end lowpass;
    
architecture rtl of lowpass is

    constant lowpass_filter_length: integer:=31;
    type lowpass_coeffs_t is array (lowpass_filter_length-1 downto 0) of integer range -128 to 127;
    constant lowpass_coeffs: lowpass_coeffs_t:= (-1, 0, 1, -0, -2, 0, 3, -0, -4,
													0, 7, -0, -13, 0, 41, 64, 41, 0,
													-13, -0, 7, 0, -4, -0, 3, 0, -2,
													-0, 1, 0, -1);

    --short streaming buffer
    type streaming_data_array is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal streaming_data : streaming_data_array := (others=>(others=>(others=>'0'))); --pipeline data

    --buffer to store the interpolated sample for being pulled when doing the beamforming / summation
    type interpolated_data_array is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal interp_data: interpolated_data_array:= (others=>(others=>(others=>'0')));

    type padded_t is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1+lowpass_filter_length downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal padded_sig: padded_t:=(others=>(others=>(others=>'0')));

    type fir_temp is array(15 downto 0, NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES+lowpass_filter_length-1 downto 0) of signed(2*SAMPLE_LENGTH-1 downto 0);
    signal int_up: fir_temp:=(others=>(others=>(others=>(others=>'0'))));

    type fir_temp_big is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(2*SAMPLE_LENGTH-1 downto 0);
    signal int_up_final: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_first: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_second: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_third: fir_temp_big := (others=>(others=>(others=>'0')));

    -- for generality these are the same sizes, but could be optimized on a per coefficient basis since coefficients are 
    -- either close (near the center coeff so less delay needed when reused) or far (early coeff so need to wait a longer time to be used)
    
    signal int_up_m1: fir_temp_big := (others=>(others=>(others=>'0')));
	signal int_up_1: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_m2: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_3: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_m4: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_7: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_m13: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_41: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_64: fir_temp_big := (others=>(others=>(others=>'0')));

begin

    --assign inputs
    assign_channels_in: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_samples: for sam in 0 to NUM_SAMPLES-1 generate
            streaming_data(ch,sam)<=signed(ch_data_i(SAMPLE_LENGTH*(sam+1)+ch*NUM_SAMPLES*SAMPLE_LENGTH-1 downto ch*NUM_SAMPLES*SAMPLE_LENGTH+8*sam));
        end generate;
    end generate;

    --assign ouputs
    assign_channels_out: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_samples_o: for sam in 0 to NUM_SAMPLES-1 generate
            ch_data_o(SAMPLE_LENGTH*(sam+1)+ch*SAMPLE_LENGTH*NUM_SAMPLES-1 
                      downto ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*sam)
                      <= std_logic_vector(interp_data(ch,sam));
        end generate;
    end generate;

    -- do the upsampling
    proc_lowpass_by_hand:process(clk_data_i, rst_i, enable_i)
    begin
	   
			for ch in 0 to NUM_PA_CHANNELS-1 loop
				-- assign the real sample values
				for sam in 0 to NUM_SAMPLES-1 loop
					-- real samples are located at multiples of INTERP_FACTOR, others default to 0 and are never assigned
					padded_sig(ch,sam) <= streaming_data(ch,sam);
				end loop;
			end loop;

		  if rst_i = '1' or enable_i = '1' then
				int_up <= (others=>(others=>(others=>(others=>'0'))));
				interp_data <= (others=>(others=>(others=>'0')));
				int_up_first <= (others=>(others=>(others=>'0')));
				int_up_second <= (others=>(others=>(others=>'0')));
				int_up_final <= (others=>(others=>(others=>'0')));
				int_up_m1 <= (others=>(others=>(others=>'0')));
				int_up_1 <= (others=>(others=>(others=>'0')));
				int_up_m2 <= (others=>(others=>(others=>'0')));
				int_up_3 <= (others=>(others=>(others=>'0')));
				int_up_m4 <= (others=>(others=>(others=>'0')));
				int_up_7 <= (others=>(others=>(others=>'0')));
				int_up_m13 <= (others=>(others=>(others=>'0')));
				int_up_41 <= (others=>(others=>(others=>'0')));
				int_up_64 <= (others=>(others=>(others=>'0')));


			elsif rising_edge(clk_data_i) then

				for  ch in 0 to NUM_PA_CHANNELS-1 loop
						for sam in 0 to NUM_SAMPLES-1 loop

							--convolve with filter in parts, bit shifts and adds
							int_up(0,ch,sam) <= -resize(padded_sig(ch,0+sam),2*SAMPLE_LENGTH); -- -1
							int_up(2,ch,sam) <= resize(padded_sig(ch,2+sam),2*SAMPLE_LENGTH); -- 1
							int_up(4,ch,sam) <= -(resize(padded_sig(ch,4+sam),2*SAMPLE_LENGTH-1)&'0'); -- -2
							int_up(6,ch,sam) <= (resize(padded_sig(ch,6+sam),2*SAMPLE_LENGTH-1)&'0') + (resize(padded_sig(ch,6+sam),2*SAMPLE_LENGTH)); -- 3
							int_up(8,ch,sam) <= -(resize(padded_sig(ch,8+sam),2*SAMPLE_LENGTH-2)&"00"); -- -4
							int_up(10,ch,sam) <= (resize(padded_sig(ch,10+sam),2*SAMPLE_LENGTH-3)&"000") - resize(padded_sig(ch,10+sam),2*SAMPLE_LENGTH); -- 7
							int_up(12,ch,sam) <= (resize(padded_sig(ch,12+sam),2*SAMPLE_LENGTH-4)&"0000") - (resize(padded_sig(ch,12+sam),2*SAMPLE_LENGTH-1)&'0') - (resize(padded_sig(ch,12+sam),2*SAMPLE_LENGTH)); -- -13
							int_up(14,ch,sam) <= (resize(padded_sig(ch,14+sam),2*SAMPLE_LENGTH-5)&"00000") + (resize(padded_sig(ch,14+sam),2*SAMPLE_LENGTH-3)&"000") + (resize(padded_sig(ch,14+sam),2*SAMPLE_LENGTH)); -- 41
							int_up(15,ch,sam) <= (resize(padded_sig(ch,15+sam),2*SAMPLE_LENGTH-6)&"000000"); -- 64

							-- polyphase
							int_up_m1(ch,sam) <= int_up(0,ch,sam) + int_up(0,ch,sam+30);
							int_up_1(ch,sam) <= int_up(2,ch,sam) + int_up(2,ch,sam+26);
							int_up_m2(ch,sam) <= int_up(4,ch,sam) + int_up(4,ch,sam+22);
							int_up_3(ch,sam) <= int_up(6,ch,sam) + int_up(6,ch,sam+18);
							int_up_m4(ch,sam) <= int_up(8,ch,sam) + int_up(8,ch,sam+14);
							int_up_7(ch,sam) <= int_up(10,ch,sam) + int_up(10,ch,sam+10);
							int_up_m13(ch,sam) <= int_up(12,ch,sam) + int_up(12,ch,sam+6);
							int_up_41(ch,sam) <= int_up(14,ch,sam) + int_up(14,ch,sam+2);
							int_up_64(ch,sam) <= int_up(15,ch,sam);

							--sum parts first stage
							int_up_first(ch,sam) <= int_up_m1(ch,sam) + int_up_1(ch,sam) + int_up_m2(ch,sam) + int_up_3(ch,sam) + int_up_m4(ch,sam);
							int_up_second(ch,sam) <= int_up_7(ch,sam) + int_up_m13(ch,sam) + int_up_41(ch,sam) + int_up_64(ch,sam);

							--sum parts second stage
							int_up_final(ch,sam)<=int_up_first(ch,sam) + int_up_second(ch,sam);

							--do division (bit shifting) with rounding
							if unsigned(int_up_final(ch,sam)(5 downto 0)) > x"20" then
								interp_data(ch,sam) <= resize( signed(int_up_final(ch,sam)(2*SAMPLE_LENGTH-1 downto 6)) , SAMPLE_LENGTH) + 1;
							elsif unsigned(int_up_final(ch,sam)(5 downto 0)) = x"20" and int_up_final(ch,sam)(6) = '0' then
								interp_data(ch,sam) <= resize( signed(int_up_final(ch,sam)(2*SAMPLE_LENGTH-1 downto 6)) , SAMPLE_LENGTH);
							elsif unsigned(int_up_final(ch,sam)(5 downto 0)) = x"20" and int_up_final(ch,sam)(6) = '1' then
								interp_data(ch,sam) <= resize( signed(int_up_final(ch,sam)(2*SAMPLE_LENGTH-1 downto 6)) , SAMPLE_LENGTH) + 1;
							else --unsigned(int_up(ch,sam)(5 downto 0))<x"20" then
								interp_data(ch,sam) <= resize( signed(int_up_final(ch,sam)(2*SAMPLE_LENGTH-1 downto 6)) , SAMPLE_LENGTH);
							end if;
				end loop;

						--shift padded sig for future clock cycles
						for j in NUM_SAMPLES to NUM_SAMPLES+lowpass_filter_length-1 loop
							padded_sig(ch,j)<=padded_sig(ch,j-NUM_SAMPLES);
							for fil in 0 to 15 loop
								int_up(fil,ch,j) <= int_up(fil,ch,j-NUM_SAMPLES);
							end loop;
						end loop;
				end loop;
	
        end if;
    end process;
end rtl;