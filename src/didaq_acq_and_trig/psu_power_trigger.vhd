---------------------------------------------------------------------------------
-- Penn State  
-- Dept. of Physics
--
-- PROJECT:      RNO-G lowthresh
-- FILE:         phased_trigger.vhd
-- AUTHOR:       Ryan Krebs
-- EMAIL         rjk5416@psu.edu
-- DATE:         7/28/26
--
-- DESCRIPTION:  beamformed power integration trigger
-- stolen from the flower pa trigger, adapted for the didaq, optimized upsampling and power sum
--
--  Code roughly assumes a 2x upsampling, may not work as-is for 1x. 
--  if 4 samples, then num powers should be 2 for a 2 ns window step
--  if 8 samples, num powers should be 4 to return the correct number of windows each clock cycle
--
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity power_trigger is
generic(
        station_number      : std_logic_vector(7 downto 0):=x"0b"; -- choose station delays, geometry + cable delays but should be roughly the same across sts.
        SAMPLE_LENGTH       : integer := 8; -- base data size, hopefully flexible for higher
		NUM_SAMPLES         : integer := 4; -- samples per clock cycle fed into the trigger
		NUM_PA_CHANNELS     : integer := 4; -- num of channels used in phasing, some instances are hard coded
		INTERP_FACTOR       : integer := 2; -- upsampling/interpolation factor
        INT_SAMPLE_LENGTH   : integer := 8; -- length of samples coming out of the beamforming module (for bit saturation for eff. lut)
        NUM_POWERS          : integer := 2; -- number of windows to check average power. if num samples*interp = 16 => 4, if num samples*interp = 8 => 2
        POWER_LENGTH        : integer := 16; -- length of average powers and thresholds
        SWAP_CHANNELS       : std_logic := '0'; -- didaq swap of ch 0 <-> 1 and ch 2 <-> 3 data streams (should be moved to acq and trig upper level module)
        NUM_BEAMS : integer := 12);

port(
        rst_i :	in std_logic;

        -- adc data
        clk_data_i      : in    std_logic; --data clock
        ch0_data_i      : in    std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES-1 downto 0); -- S3, S2, S1, S0 (at sample length bits each)
        ch1_data_i      : in	std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES-1 downto 0);
        ch2_data_i      : in	std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES-1 downto 0);
        ch3_data_i      : in	std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES-1 downto 0);
        data_valid_i    : in    std_logic_vector(NUM_PA_CHANNELS-1 downto 0);

        -- register things. configure these io since they may or may not be on the same clock
        clk_reg_i           : in std_logic; --register clock 
        enable_i            : in std_logic;
        beam_mask_i         : in std_logic_vector(NUM_BEAMS-1 downto 0);
        channel_mask_i      : in std_logic_vector(NUM_PA_CHANNELS-1 downto 0);
        trig_thresholds_i   : in std_logic_vector(NUM_BEAMS*POWER_LENGTH-1 downto 0); -- T11 -> T0 at power length bits each
        servo_thresholds_i  : in std_logic_vector(NUM_BEAMS*POWER_LENGTH-1 downto 0);

        -- output
        trig_bits_o : out	std_logic_vector(2*(NUM_BEAMS+1)-1 downto 0); --for scalers
        trig_o : out	std_logic := '0'; --trigger
        trig_metadata_o : out std_logic_vector(NUM_BEAMS-1 downto 0) := (others=>'0'); --for triggering beams

        -- debug
        power_o: out std_logic_vector(POWER_LENGTH-1 downto 0) --test avg power for debugging located in metadata
        );
end power_trigger;

architecture rtl of power_trigger is

--definitions + constants -- I realize I can now just use 'length too
constant streaming_buffer_length: integer := NUM_SAMPLES;
constant baseline: unsigned(7 downto 0) := x"80";
                                    
--short streaming regs to ease timing (if needed at all)
type streaming_data_array is array(NUM_PA_CHANNELS-1 downto 0, NUM_SAMPLES-1 downto 0) of signed(SAMPLE_LENGTH-1 downto 0);
signal streaming_data : streaming_data_array := (others=>(others=>(others=>'0'))); --pipeline data

--big arrays for thresholds/ average power
type power_thresh_array is array (NUM_BEAMS-1 downto 0) of unsigned(POWER_LENGTH-1 downto 0);-- range 0 to 2**num_power_bits-1;--std_logic_vector(num_power_bits-1 downto 0); --log2(6*(16*6)^2) max power possible
signal trig_beam_thresh : power_thresh_array:=(others=>(others=>'0')) ; --trigger thresholds for all beams
signal servo_beam_thresh : power_thresh_array:=(others=>(others=>'0')) ;--(others=>(others=>'0')) --servo thresholds for all beams

type power_array is array(NUM_BEAMS-1 downto 0, NUM_POWERS-1 downto 0) of unsigned(POWER_LENGTH-1 downto 0);
signal avg_power: power_array:=(others=>(others=>(others=>'0'))); --average power (power_sum shifted down by log2(32)=5 bits)
signal latched_power_out: power_array:=(others=>(others=>(others=>'0'))); --average power (power_sum shifted down by log2(32)=5 bits)

--input thresholds, 16 bits from registers
type thresh_input is array (NUM_BEAMS-1 downto 0) of unsigned(POWER_LENGTH-1 downto 0);
signal input_trig_thresh : thresh_input:=(others=>(others=>'0'));
signal input_servo_thresh : thresh_input:=(others=>(others=>'0'));

type beam_power_window_t is array(NUM_BEAMS-1 downto 0) of unsigned(NUM_POWERS-1 downto 0);
signal beam_power_window_trig: beam_power_window_t := (others=>(others=>'0'));
signal beam_power_window_servo: beam_power_window_t := (others=>(others=>'0'));

--mask of which beam triggers/servos to use in the trigger
signal triggering_beam: std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0');
signal servoing_beam: std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0');

--signal bits_for_trigger : std_logic_vector(NUM_BEAMS-1 downto 0);

--actual output from the phased trigger and servo
signal phased_trigger : std_logic:='0';
signal phased_trigger_reg : std_logic_vector(1 downto 0):=(others=>'0');
signal phased_servo : std_logic:='0';
signal phased_servo_reg : std_logic_vector(1 downto 0):=(others=>'0');

--copy of simple trigger channel regs (probably not needed)
type trigger_regs is array(NUM_BEAMS-1 downto 0) of std_logic_vector(1 downto 0);
signal beam_trigger_reg : trigger_regs:= (others=>(others=>'0'));
signal beam_servo_reg : trigger_regs:= (others=>(others=>'0'));

--previous trig beam bits
signal last_trig_bits_latched : std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0');
signal trig_array_for_scalers : std_logic_vector(2*(NUM_BEAMS+1) downto 0):=(others=>'0'); --//on clk_data_i

--enables+input masks
signal internal_phased_trig_en : std_logic := '0'; --enable this trigger block from sw
--signal internal_trigger_channel_mask : std_logic_vector(NUM_PA_CHANNELS-1 downto 0); if masking channel from coh sum (not implemented)
signal internal_trigger_beam_mask : std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0');
signal internal_trigger_channel_mask : std_logic_vector(NUM_PA_CHANNELS-1 downto 0):=(others=>'0');


--full regs for ouput to scalers
signal trig_array_for_scalars : std_logic_vector (2*(NUM_BEAMS+1)-1 downto 0):=(others=>'0');

--output for triggering beams for metadata
signal trig_bits_metadata: std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0');

signal phased_trig_metadata: std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0'); --for triggering beams
signal last_phased_trig_metadata: std_logic_vector(NUM_BEAMS-1 downto 0):=(others=>'0'); --for triggering beams


signal dedispersion_i : std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS -1 downto 0):=(others=>'0');
signal dedispersion_o : std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS -1 downto 0):=(others=>'0');
signal upsampling_i : std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS -1 downto 0):=(others=>'0');
signal upsampling_o : std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS*INTERP_FACTOR -1 downto 0):=(others=>'0');	
signal beaming_i : std_logic_vector(SAMPLE_LENGTH*NUM_SAMPLES*NUM_PA_CHANNELS*INTERP_FACTOR -1 downto 0):=(others=>'0');
signal beaming_o : std_logic_vector(NUM_BEAMS*SAMPLE_LENGTH*NUM_SAMPLES*INTERP_FACTOR-1 downto 0):=(others=>'0');
signal power_integration_i : std_logic_vector(NUM_BEAMS*NUM_SAMPLES*INTERP_FACTOR*SAMPLE_LENGTH-1 downto 0):=(others=>'0');
signal power_integration_o : std_logic_vector(NUM_POWERS*POWER_LENGTH*NUM_BEAMS-1 downto 0):=(others=>'0');


-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--components, modules, etc


--cdc slow to fast
component signal_sync is
port(
    clkA			: in	std_logic;
    clkB			: in	std_logic;
    SignalIn_clkA	: in	std_logic;
    SignalOut_clkB	: out	std_logic);
end component;

--cdc fast to slow
component flag_sync is
port(
    clkA		: in	std_logic;
    clkB		: in	std_logic;
    in_clkA		: in	std_logic;
    busy_clkA	: out	std_logic;
    out_clkB	: out	std_logic);
end component;
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--begin rtl

begin

    --buffer samples into the phased trigger module
    proc_pipeline_data: process(clk_data_i, internal_phased_trig_en)
    begin
        if rst_i = '1' then
            streaming_data <= (others=>(others=>x"00"));

        elsif rising_edge(clk_data_i) then
            if internal_phased_trig_en then
                --pull new data in, if not in mask send 0's
                for i in 0 to NUM_SAMPLES-1 loop
                    if internal_trigger_channel_mask(0)='1' and data_valid_i(0)='1' then
                        if SWAP_CHANNELS then
                            streaming_data(0,i) <= signed(unsigned(ch1_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        else
                            streaming_data(0,i) <= signed(unsigned(ch0_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        end if;
                    else
                        streaming_data(0,i) <= (others=>'0');
                    end if;

                    if internal_trigger_channel_mask(1)='1' and data_valid_i(1)='1' then
                        if SWAP_CHANNELS then
                            streaming_data(1,i) <= signed(unsigned(ch0_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        else
                            streaming_data(1,i) <= signed(unsigned(ch1_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        end if;
                    else
                        streaming_data(1,i)<=(others=>'0');
                    end if;

                    if internal_trigger_channel_mask(2)='1' and data_valid_i(2)='1' then
                        if SWAP_CHANNELS then
                            streaming_data(2,i) <= signed(unsigned(ch3_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        else
                            streaming_data(2,i)<=signed(unsigned(ch2_data_i(8*(i+1)-1 downto 8*(i)))-baseline);
                        end if;
                    else
                        streaming_data(2,i)<=(others=>'0');
                    end if;
                    
                    if internal_trigger_channel_mask(3)='1' and data_valid_i(3)='1' then
                        if SWAP_CHANNELS then
                            streaming_data(3,i) <= signed(unsigned(ch2_data_i(SAMPLE_LENGTH*(i+1)-1 downto SAMPLE_LENGTH*(i)))-baseline);
                        else
                            streaming_data(3,i) <= signed(unsigned(ch3_data_i(NUM_SAMPLES*(i+1)-1 downto NUM_SAMPLES*(i)))-baseline);
                        end if;
                    else
                        streaming_data(3,i) <= (others=>'0');
                    end if;
                end loop;
				else
					streaming_data <= (others=>(others=>x"00"));
            end if;
        end if;
    end process;



    --uncomment for dedisperion
    /*
    -- connect streaming data to dedispersion
    assign_upsampling_io: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_sams_i: for i in 0 to NUM_PA_CHANNELS-1 generate
            dedispersion_i(ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*(i+1)-1 downto ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*i)
                <= std_logic_vector(streaming_data(ch,i));
        end generate;
    end generate;
    --
    xDedispersion : entity work.dedispersion
    port map (
        rst_i       => rst_i,
        clk_data_i  => clk_data_i,
        enable      => internal_phased_trig_en,
        ch_data_i   => dedispersion_i,
        ch_data_o   => dedispersion_o
    );
    --connect dedispersion output to upsampling input
    upsampling_i<=dedispersion_o;
    */

    --xUpsampling : entity work.upsampling
    --generic map(
    --  SAMPLE_LENGTH   => SAMPLE_LENGTH,
   --	NUM_SAMPLES     => NUM_SAMPLES,
	--	NUM_PA_CHANNELS => NUM_PA_CHANNELS,
	 --INTERP_FACTOR   => INTERP_FACTOR
    --)
    --port map (
    --    rst_i       => rst_i,
    --    clk_data_i  => clk_data_i,
    --    enable_i    => internal_phased_trig_en,
    --    ch_data_i   => upsampling_i,
    --    ch_data_o   => upsampling_o
    --);

    --comment these generates if using dedispersion
    --assign_upsampling_io: for ch in 0 to NUM_PA_CHANNELS-1 generate
    --    assign_sams_i: for i in 0 to NUM_SAMPLES-1 generate
    --        upsampling_i(ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*(i+1)-1 downto ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*i)
    --            <= std_logic_vector(streaming_data(ch,i));
    --    end generate;
    --end generate;

    --connect upsampling to beamforming
    --beaming_i<=upsampling_o;
	 
	 assign_beamforming_io: for ch in 0 to NUM_PA_CHANNELS-1 generate
        assign_sams_i: for i in 0 to NUM_SAMPLES-1 generate
            beaming_i(ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*(i+1)-1 downto ch*SAMPLE_LENGTH*NUM_SAMPLES+SAMPLE_LENGTH*i)
                <= std_logic_vector(streaming_data(ch,i));
        end generate;
    end generate;

    xBeamforming: entity work.beamforming
    generic map (
        station_number_i => station_number,
        SAMPLE_LENGTH   => SAMPLE_LENGTH,
		NUM_SAMPLES     => NUM_SAMPLES,
		NUM_PA_CHANNELS => NUM_PA_CHANNELS,
		INTERP_FACTOR   => INTERP_FACTOR
        )
    port map (
        rst_i       => rst_i,
        clk_data_i  => clk_data_i,
        enable_i    => internal_phased_trig_en,
        ch_data_i   => beaming_i,
        beam_data_o => beaming_o
    );

    --connect beamforming output to power integration
    power_integration_i<=beaming_o;

    xPower: entity work.power_integration
    generic map(
        SAMPLE_LENGTH   => SAMPLE_LENGTH,
		NUM_SAMPLES     => NUM_SAMPLES,
		NUM_PA_CHANNELS => NUM_PA_CHANNELS,
		INTERP_FACTOR   => INTERP_FACTOR,
        NUM_POWERS      => NUM_POWERS,
        POWER_LENGTH    => POWER_LENGTH
    )
    port map (
        rst_i       => rst_i,
        clk_data_i  => clk_data_i,
        enable_i    => internal_phased_trig_en,
        beam_data_i => power_integration_i,
        power_o     => power_integration_o
    );

    --connect output of power
    assign_power_o: for bm in 0 to NUM_BEAMS-1 generate
        assign_power_windows_o: for s in 0 to NUM_POWERS-1 generate
            avg_power(bm,s) <= unsigned(power_integration_o(NUM_POWERS*POWER_LENGTH*bm+POWER_LENGTH+POWER_LENGTH*s-1 downto NUM_POWERS*POWER_LENGTH*bm+POWER_LENGTH*s));
        --avg_power0(bm)<=unsigned(power_integration_o(NUM_POWERS*POWER_LENGTH*bm+POWER_LENGTH-1 downto NUM_POWERS*POWER_LENGTH*bm));
        --avg_power1(bm)<=unsigned(power_integration_o(NUM_POWERS*POWER_LENGTH*bm+2*POWER_LENGTH-1 downto NUM_POWERS*POWER_LENGTH*bm+POWER_LENGTH));
        end generate;
    end generate;


    --compare calculated powers and compare to masks and thresholds for the actual trigger
    proc_get_triggering_beams : process(clk_data_i,rst_i)
    begin
        if rst_i = '1' then
            phased_trigger_reg <= "00";
            phased_trigger <= '0'; -- the trigger

            phased_servo_reg <= "00";
            phased_servo <= '0';  --the servo trigger

            triggering_beam <= (others=>'0');
            servoing_beam <= (others=>'0');
            last_phased_trig_metadata <= (others=>'0');
            
        elsif rising_edge(clk_data_i) then
            if internal_phased_trig_en then
                --loop over the beams and this is a big mess
                for i in 0 to NUM_BEAMS-1 loop

                    
                    for w in 0 to NUM_POWERS-1 loop
                        if avg_power(i,w) > trig_beam_thresh(i) then
                            beam_power_window_trig(i)(w) <= '1';
                        else
                            beam_power_window_trig(i)(w) <= '0';
                        end if;
                                                
                        if avg_power(i,w) > servo_beam_thresh(i) then
                            beam_power_window_servo(i)(w) <= '1';
                        else
                            beam_power_window_servo(i)(w) <= '0';
                        end if;
                    end loop;

                    if to_integer(beam_power_window_trig(i)) > 0 then
                        triggering_beam(i)<='1';
                        beam_trigger_reg(i)(0)<='1';
                    else
                        triggering_beam(i)<='0';
                        beam_trigger_reg(i)(0)<='0';
                    end if;
                    beam_trigger_reg(i)(1)<=beam_trigger_reg(i)(0);

                    if to_integer(beam_power_window_servo(i)) > 0 then
                        servoing_beam(i)<='1';
                        beam_servo_reg(i)(0)<='1';
                    else
                        servoing_beam(i)<='0';
                        beam_servo_reg(i)(0)<='0';
                    end if;
                    beam_servo_reg(i)(1)<=beam_servo_reg(i)(0);

                    /*
                    -- TODO: to make num power variable, add in another stage to aggregate each window, and then check if any 1
                    --calculate if a beam is triggering or seroing
                    if avg_power(i,0)>trig_beam_thresh(i) or avg_power(i,1)>trig_beam_thresh(i) then
                        triggering_beam(i)<='1';
                        beam_trigger_reg(i)(0)<='1';
                        --latched_power_out(i)<=avg_power(i);
                    else
                        triggering_beam(i)<='0';
                        beam_trigger_reg(i)(0)<='0';
                    end if;

                    beam_trigger_reg(i)(1)<=beam_trigger_reg(i)(0);
                    if avg_power(i,0)>servo_beam_thresh(i) or avg_power(i,1)>servo_beam_thresh(i) then
                        servoing_beam(i)<='1';
                        beam_servo_reg(i)(0)<='1';
                    else
                        servoing_beam(i)<='0';
                        beam_servo_reg(i)(0)<='0';
                    end if;
                    beam_servo_reg(i)(1)<=beam_servo_reg(i)(0);
                    */
                end loop;

                last_phased_trig_metadata <= triggering_beam;
                power_o <= std_logic_vector(avg_power(0,0));
                --this is the core of figuring out if a trigger needs to happen
                if (to_integer(unsigned(triggering_beam AND internal_trigger_beam_mask))>0) then
                    phased_trigger_reg(0)<='1';
                    --power_o(num_power_bits-1 downto 0)<=std_logic_vector(latched_power_out(0)(num_power_bits-1 downto 0));
                    phased_trig_metadata <= triggering_beam AND internal_trigger_beam_mask; --latches on a trigger
                else
                    phased_trigger_reg(0)<='0';
                end if;
                if (to_integer(unsigned(servoing_beam AND internal_trigger_beam_mask))>0) then
                    phased_servo_reg(0)<='1';
                else
                    phased_servo_reg(0)<='0';
                end if;

                phased_trigger_reg(1)<=phased_trigger_reg(0);
                phased_servo_reg(1)<=phased_servo_reg(0);

                if phased_trigger_reg="01" then
                    phased_trigger<='1';
                    trig_o <= '1';
                    trig_metadata_o <= last_phased_trig_metadata;
                else
                    phased_trigger<='0';
                    trig_o <= '0';

                end if;
                
                if phased_servo_reg="01" then
                    phased_servo<='1';
                else
                    phased_servo<='0';
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------

    --//sync some software commands from the slow reg clock to the data clock

	 internal_phased_trig_en <= enable_i;
	 
	 xTHRESHOLDS : for bm in 0 to NUM_BEAMS-1 generate
			trig_beam_thresh(bm) <= unsigned(trig_thresholds_i((bm+1)*POWER_LENGTH-1 downto bm*POWER_LENGTH));
			servo_beam_thresh(bm) <= unsigned(servo_thresholds_i((bm+1)*POWER_LENGTH-1 downto bm*POWER_LENGTH));
			internal_trigger_beam_mask(bm) <= beam_mask_i(bm);
	 end generate;
	 
    internal_trigger_channel_mask <= channel_mask_i;

	 trig_bits_o <= servoing_beam & phased_servo_reg(0) & triggering_beam & phased_trigger_reg(0);
	 
	 -- they're all on the same clock so lets just ignore the sync
	 /*
    --enable for the entire trigger block to start running (consuming power)
    xTRIGENABLESYNC : signal_sync --phased trig enable bit
        port map(
        clkA			=> clk_reg_i,
        clkB			=> clk_data_i,
        SignalIn_clkA	=> enable_i, --overall phased trig enable bit
        SignalOut_clkB	=> internal_phased_trig_en);
        
        
    --sync the trigger thresholds to clk_data_i from slow reg clock
    TRIG_THRESHOLDS : for bm in 0 to NUM_BEAMS-1 generate
        INDIV_TRIG_BITS : for i in 0 to POWER_LENGTH-1 generate
            xTRIGTHRESHSYNC : signal_sync
            port map(
            clkA			=> clk_reg_i,
            clkB			=> clk_data_i,
            SignalIn_clkA	=> trig_thresholds_i(bm*POWER_LENGTH+i), --threshold from software
            SignalOut_clkB	=> input_trig_thresh(bm)(i));
        end generate;
    end generate;


    --sync the servo thresholds to clk_data_i from slow reg clock
    SERVO_THRESHOLDS : for bm in 0 to NUM_BEAMS-1 generate
        INDIV_SERVO_BITS : for i in 0 to POWER_LENGTH-1 generate
            xSERVOTHRESHSYNC : signal_sync
            port map(
            clkA			=> clk_reg_i,
            clkB			=> clk_data_i,
            SignalIn_clkA	=> servo_thresholds_i(bm*POWER_LENGTH+i), --threshold from software
            SignalOut_clkB	=> input_servo_thresh(bm)(i));
        end generate;
    end generate;



    -- TODO Remove now that thresholds are 16-bit values
    --process 12 bit input thresholds with some threshold offset (defined in software) if needed (likely not needed)
    -- this can be removed, right now it just moves thresholds into the module variable, can be condensed to just look at the input
    proc_threshold_set:process(clk_data_i)
    begin
    if rising_edge(clk_data_i) then
            for i in 0 to NUM_BEAMS-1 loop
                trig_beam_thresh(i)<=resize(input_trig_thresh(i),POWER_LENGTH);
                servo_beam_thresh(i)<=resize(input_servo_thresh(i),POWER_LENGTH);
            end loop;
        end if;
    end process;

    --sync the trigger beam mask to clk_data_i from slow reg clock
    TRIGBEAMMASK : for bm in 0 to NUM_BEAMS-1 generate --beam masks. 1 == on
        xTRIGBEAMMASKSYNC : signal_sync
        port map(
        clkA	=> clk_reg_i,
        clkB	=> clk_data_i,
        SignalIn_clkA	=> beam_mask_i(bm), --trig channel mask
        SignalOut_clkB	=> internal_trigger_beam_mask(bm));
    end generate;

    --sync the trigger beam mask to clk_data_i from slow reg clock
    TRIGCHANNELMASK : for ch in 0 to NUM_PA_CHANNELS-1 generate --beam masks. 1 == on
        xTRIGBEAMMASKSYNC : signal_sync
        port map(
        clkA	=> clk_reg_i,
        clkB	=> clk_data_i,
        SignalIn_clkA	=> channel_mask_i(ch), --trig channel mask
        SignalOut_clkB	=> internal_trigger_channel_mask(ch));
    end generate;

    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------

    --send/sync things from the fast clk_data_i clock to the slow reg clock



    --phased trigger scaler, can use phased_trigger if we want to check 0->1 trigger
    trigscaler: flag_sync
        port map(
            clkA 		=> clk_data_i,
            clkB		=> clk_reg_i,
            in_clkA		=> phased_trigger_reg(0),
            busy_clkA	=> open,
            out_clkB	=> trig_bits_o(0));

            
    --beam trigger scalers
    TrigToScalers	:	 for bm in 0 to NUM_BEAMS-1 generate 
        xTRIGSYNC : flag_sync
        port map(
            clkA 		=> clk_data_i,
            clkB		=> clk_reg_i,
            in_clkA		=> triggering_beam(bm),-- and internal_trigger_beam_mask(i),
            busy_clkA	=> open,
            out_clkB	=> trig_bits_o(bm+1));
    end generate TrigToScalers;


    --phased servo scaler
    servoscaler: flag_sync
        port map(
            clkA 		=> clk_data_i,
            clkB		=> clk_reg_i,
            in_clkA		=> phased_servo_reg(0),
            busy_clkA	=> open,
            out_clkB	=> trig_bits_o(NUM_BEAMS+1));

            
    --beam servo scalers
    ServoToScalers	:	 for bm in 0 to NUM_BEAMS-1 generate 
        xSERVOSYNC : flag_sync
        port map(
            clkA 		=> clk_data_i,
            clkB		=> clk_reg_i,
            in_clkA		=> servoing_beam(bm),-- and internal_trigger_beam_mask(i),
            busy_clkA	=> open,
            out_clkB	=> trig_bits_o(bm+NUM_BEAMS+2));
    end generate ServoToScalers;

	 */
end rtl;