-- dedispersion FIR filter, same structure as the lowpass: coefficient multiplies are done as bit shifts and adds
-- 40 taps, coefficients scaled by 64; the sum is divided by 64 at the end with round-half-to-even, then saturated
-- should be paramerized for N (4 or 8 here) samples per clock
--
-- Input sample data is structured like Ch3 data (SN, ..., S1, S0) -> Ch0 data (SN, ..., S1, S0) at n-bit samples each
-- Output is similarly structured Ch3 data (SN, ..., S1, S0) -> Ch0 data (SN, ..., S1, S0) at n-bit samples each
--
-- Indexing follows the lowpass: padded_sig(ch,sam+k) is the sample k steps older than output sample sam,
-- so tap h[k] multiplies padded_sig(ch,sam+k), i.e. y[n] = sum_k h[k] x[n-k].
-- The filter is not symmetric, so the tap order matters: if the output looks more dispersed instead of less,
-- the coefficient order is reversed relative to the sample-age convention.
--
-- Products are computed once per sample for each distinct coefficient magnitude (int_up) and then delayed
-- through the same shift buffer, so taps that share a magnitude reuse the same product (like the lowpass reuses
-- its symmetric pairs). Signs are applied when the taps are summed.
--
-- Ryan Krebs (claude assisted)

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity dedisperse is
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
    end dedisperse;

architecture rtl of dedisperse is

    constant dedisp_filter_length: integer:=40;
    -- for reference only, the taps below are hard coded as shifts and adds. index k = h[k]
    type dedisp_coeffs_t is array (0 to dedisp_filter_length-1) of integer range -128 to 127;
    constant dedisp_coeffs: dedisp_coeffs_t:= (-2,   0,   0,   2,   0,   2,  -2,   0,  -2,  16,
                                               -24, -14,  36,  -6,  -2, -16,  -6,   4,  10,  14,
                                                6,   4,  -8,  -6, -10,  -2,  -4,   2,   1,   5,
                                                4,   4,   2,   0,   0,  -3,  -1,  -2,   0,  -1);

    -- sum of |h| = 223 < 2^8, so SAMPLE_LENGTH+8 bits holds the full sum without overflow
    constant ACC_LENGTH : integer := SAMPLE_LENGTH+8;
    constant FRAC_BITS  : integer := 6; -- coefficients are x64
    constant OUT_MAX    : integer := 2**(SAMPLE_LENGTH-1)-1;
    constant OUT_MIN    : integer := -2**(SAMPLE_LENGTH-1);

    -- product slots, one per distinct coefficient magnitude
    constant P1  : integer := 0;
    constant P2  : integer := 1;
    constant P3  : integer := 2;
    constant P4  : integer := 3;
    constant P5  : integer := 4;
    constant P6  : integer := 5;
    constant P8  : integer := 6;
    constant P10 : integer := 7;
    constant P14 : integer := 8;
    constant P16 : integer := 9;
    constant P24 : integer := 10;
    constant P36 : integer := 11;
    constant NUM_PRODUCTS : integer := 12;

    --short streaming buffer
    type streaming_data_array is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal streaming_data : streaming_data_array := (others=>(others=>(others=>'0'))); --pipeline data

    --filtered output samples
    type filtered_data_array is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal filt_data: filtered_data_array:= (others=>(others=>(others=>'0')));

    type padded_t is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1+dedisp_filter_length downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
    signal padded_sig: padded_t:=(others=>(others=>(others=>'0')));

    type fir_temp is array(NUM_PRODUCTS-1 downto 0, NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES+dedisp_filter_length-1 downto 0) of signed(ACC_LENGTH-1 downto 0);
    signal int_up: fir_temp:=(others=>(others=>(others=>(others=>'0'))));

    type fir_temp_big is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(ACC_LENGTH-1 downto 0);
    signal int_up_final: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_first: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_second: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_up_third: fir_temp_big := (others=>(others=>(others=>'0')));

    -- per-magnitude tap sums (the x2 group has 10 taps so it is split in two to keep the adders short)
    signal int_grp_1: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_2a: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_2b: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_3: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_4: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_5: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_6: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_8: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_10: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_14: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_16: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_24: fir_temp_big := (others=>(others=>(others=>'0')));
    signal int_grp_36: fir_temp_big := (others=>(others=>(others=>'0')));

begin

    --assign inputs
    assign_channels_in: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_samples: for sam in 0 to NUM_SAMPLES-1 generate
            streaming_data(ch,sam)<=signed(ch_data_i(SAMPLE_LENGTH*(sam+1)+ch*NUM_SAMPLES*SAMPLE_LENGTH-1 downto ch*NUM_SAMPLES*SAMPLE_LENGTH+SAMPLE_LENGTH*sam));
        end generate;
    end generate;

    --assign ouputs
    assign_channels_out: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_samples_o: for sam in 0 to NUM_SAMPLES-1 generate
            ch_data_o(SAMPLE_LENGTH*(sam+1)+ch*SAMPLE_LENGTH*NUM_SAMPLES-1
                      downto ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*sam)
                      <= std_logic_vector(filt_data(ch,sam));
        end generate;
    end generate;

    -- do the filtering
    proc_dedisp_by_hand:process(clk_data_i, rst_i, enable_i)
        variable quotient : signed(ACC_LENGTH-FRAC_BITS downto 0); -- one extra bit so the +1 from rounding cannot overflow
    begin

			for ch in 0 to NUM_PA_CHANNELS-1 loop
				for sam in 0 to NUM_SAMPLES-1 loop
					padded_sig(ch,sam) <= streaming_data(ch,sam);
				end loop;
			end loop;

		  if rst_i = '1' or enable_i = '0' then
				int_up <= (others=>(others=>(others=>(others=>'0'))));
				filt_data <= (others=>(others=>(others=>'0')));
				int_up_first <= (others=>(others=>(others=>'0')));
				int_up_second <= (others=>(others=>(others=>'0')));
				int_up_third <= (others=>(others=>(others=>'0')));
				int_up_final <= (others=>(others=>(others=>'0')));
				int_grp_1 <= (others=>(others=>(others=>'0')));
				int_grp_2a <= (others=>(others=>(others=>'0')));
				int_grp_2b <= (others=>(others=>(others=>'0')));
				int_grp_3 <= (others=>(others=>(others=>'0')));
				int_grp_4 <= (others=>(others=>(others=>'0')));
				int_grp_5 <= (others=>(others=>(others=>'0')));
				int_grp_6 <= (others=>(others=>(others=>'0')));
				int_grp_8 <= (others=>(others=>(others=>'0')));
				int_grp_10 <= (others=>(others=>(others=>'0')));
				int_grp_14 <= (others=>(others=>(others=>'0')));
				int_grp_16 <= (others=>(others=>(others=>'0')));
				int_grp_24 <= (others=>(others=>(others=>'0')));
				int_grp_36 <= (others=>(others=>(others=>'0')));


			elsif rising_edge(clk_data_i) then

				for  ch in 0 to NUM_PA_CHANNELS-1 loop
						for sam in 0 to NUM_SAMPLES-1 loop

							--products, bit shifts and adds, one per distinct coefficient magnitude
							int_up(P1,ch,sam) <= resize(padded_sig(ch,sam),ACC_LENGTH); -- x1
							int_up(P2,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-1)&"0"); -- x2
							int_up(P3,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-1)&"0") + resize(padded_sig(ch,sam),ACC_LENGTH); -- x3
							int_up(P4,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-2)&"00"); -- x4
							int_up(P5,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-2)&"00") + resize(padded_sig(ch,sam),ACC_LENGTH); -- x5
							int_up(P6,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-2)&"00") + (resize(padded_sig(ch,sam),ACC_LENGTH-1)&"0"); -- x6
							int_up(P8,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-3)&"000"); -- x8
							int_up(P10,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-3)&"000") + (resize(padded_sig(ch,sam),ACC_LENGTH-1)&"0"); -- x10
							int_up(P14,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-4)&"0000") - (resize(padded_sig(ch,sam),ACC_LENGTH-1)&"0"); -- x14
							int_up(P16,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-4)&"0000"); -- x16
							int_up(P24,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-4)&"0000") + (resize(padded_sig(ch,sam),ACC_LENGTH-3)&"000"); -- x24
							int_up(P36,ch,sam) <= (resize(padded_sig(ch,sam),ACC_LENGTH-5)&"00000") + (resize(padded_sig(ch,sam),ACC_LENGTH-2)&"00"); -- x36

							--taps: each reuses the product computed k samples earlier
							int_grp_1(ch,sam) <= int_up(P1,ch,sam+28) - int_up(P1,ch,sam+36) - int_up(P1,ch,sam+39); -- h[28]=1, h[36]=-1, h[39]=-1
							int_grp_2a(ch,sam) <= -int_up(P2,ch,sam+0) + int_up(P2,ch,sam+3) + int_up(P2,ch,sam+5) - int_up(P2,ch,sam+6) - int_up(P2,ch,sam+8); -- h[0]=-2, h[3]=2, h[5]=2, h[6]=-2, h[8]=-2
							int_grp_2b(ch,sam) <= -int_up(P2,ch,sam+14) - int_up(P2,ch,sam+25) + int_up(P2,ch,sam+27) + int_up(P2,ch,sam+32) - int_up(P2,ch,sam+37); -- h[14]=-2, h[25]=-2, h[27]=2, h[32]=2, h[37]=-2
							int_grp_3(ch,sam) <= -int_up(P3,ch,sam+35); -- h[35]=-3
							int_grp_4(ch,sam) <= int_up(P4,ch,sam+17) + int_up(P4,ch,sam+21) - int_up(P4,ch,sam+26) + int_up(P4,ch,sam+30) + int_up(P4,ch,sam+31); -- h[17]=4, h[21]=4, h[26]=-4, h[30]=4, h[31]=4
							int_grp_5(ch,sam) <= int_up(P5,ch,sam+29); -- h[29]=5
							int_grp_6(ch,sam) <= -int_up(P6,ch,sam+13) - int_up(P6,ch,sam+16) + int_up(P6,ch,sam+20) - int_up(P6,ch,sam+23); -- h[13]=-6, h[16]=-6, h[20]=6, h[23]=-6
							int_grp_8(ch,sam) <= -int_up(P8,ch,sam+22); -- h[22]=-8
							int_grp_10(ch,sam) <= int_up(P10,ch,sam+18) - int_up(P10,ch,sam+24); -- h[18]=10, h[24]=-10
							int_grp_14(ch,sam) <= -int_up(P14,ch,sam+11) + int_up(P14,ch,sam+19); -- h[11]=-14, h[19]=14
							int_grp_16(ch,sam) <= int_up(P16,ch,sam+9) - int_up(P16,ch,sam+15); -- h[9]=16, h[15]=-16
							int_grp_24(ch,sam) <= -int_up(P24,ch,sam+10); -- h[10]=-24
							int_grp_36(ch,sam) <= int_up(P36,ch,sam+12); -- h[12]=36

							--sum parts first stage
							int_up_first(ch,sam) <= int_grp_1(ch,sam) + int_grp_2a(ch,sam) + int_grp_2b(ch,sam) + int_grp_3(ch,sam) + int_grp_4(ch,sam);
							int_up_second(ch,sam) <= int_grp_5(ch,sam) + int_grp_6(ch,sam) + int_grp_8(ch,sam) + int_grp_10(ch,sam) + int_grp_14(ch,sam);
							int_up_third(ch,sam) <= int_grp_16(ch,sam) + int_grp_24(ch,sam) + int_grp_36(ch,sam);

							--sum parts second stage
							int_up_final(ch,sam) <= int_up_first(ch,sam) + int_up_second(ch,sam) + int_up_third(ch,sam);

							--do division by 64 (bit shifting) with round half to even, as in the lowpass
							quotient := resize(int_up_final(ch,sam)(ACC_LENGTH-1 downto FRAC_BITS), ACC_LENGTH-FRAC_BITS+1);
							if unsigned(int_up_final(ch,sam)(FRAC_BITS-1 downto 0)) > to_unsigned(2**(FRAC_BITS-1), FRAC_BITS) then
								quotient := quotient + 1;
							elsif unsigned(int_up_final(ch,sam)(FRAC_BITS-1 downto 0)) = to_unsigned(2**(FRAC_BITS-1), FRAC_BITS) and int_up_final(ch,sam)(FRAC_BITS) = '1' then
								quotient := quotient + 1;
							end if;

							--saturate to the output width (the dedispersed pulse can exceed the input range)
							if quotient > OUT_MAX then
								filt_data(ch,sam) <= to_signed(OUT_MAX, SAMPLE_LENGTH);
							elsif quotient < OUT_MIN then
								filt_data(ch,sam) <= to_signed(OUT_MIN, SAMPLE_LENGTH);
							else
								filt_data(ch,sam) <= resize(quotient, SAMPLE_LENGTH);
							end if;
				end loop;

						--shift padded sig and products for future clock cycles
						for j in NUM_SAMPLES to NUM_SAMPLES+dedisp_filter_length-1 loop
							padded_sig(ch,j)<=padded_sig(ch,j-NUM_SAMPLES);
							for fil in 0 to NUM_PRODUCTS-1 loop
								int_up(fil,ch,j) <= int_up(fil,ch,j-NUM_SAMPLES);
							end loop;
						end loop;
				end loop;

        end if;
    end process;
end rtl;