--*----------------------------------------------------------------------------
--*                                VHDL RTL source file
--*                                 Logic Tectonics Inc
--*                                 All Rights Reserved
--*                                     2011-2024
--*                   Provided modified to end customer non-exclusively
--*               and royalty free, AS IS, with no other representations. 
--*                      This header must be included with
--*                the source code wherever used to be in compliance 
--*                        with the terms of this license.                         
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics Inc. www.logic-tectonics.com        
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This file implements:
--*
--*           1. A SPI slave intrface to allow an external access
--*                to an FPGA resident register file and other peripherals in the
--*                FPGA. 
--*
--*                Operation:
--*
--*                a. SPI packet sizes are 40 or 48 bits dependent on
--*                   the g_spi_frame_len generic setting.
--*                   Fields are sent MSB to LSB
--*                b. The input and output data changes on positive 
--*                   edge of the clock from the external SPI master.
--*                   From the processor perspective this module requires
--*                   SPI setting:    POL = 0
--*                                   PHA = 1
--*                c. This device is a slave only and will not initiate 
--*                   SPI transfers.
--*                4. The module expects an active low chip select (SS)
--*                5. The module can accept bursts (without deasserting
--*                   SS) as long as the each frame has tinghe correct 
--*                   structure. Note the differnces between 40 nd 48 bit frames
--*                   in that the 48 bit frame allows for 15 bits of 32bit register
--*                   decoding address space whereas 40 bit frame setting
--*                   supprts only 7 bit (128 location) adress    
--*                6. Technically the interface can be used to read/write
--*                   up to a 32bit register value each transfer. Addressing
--*                   is on a full reg word basis not byte.
--*                7. During a write the same location can be read 
--*                   but the old data will be output on the SPI data out. 
--*                   This means that the old data from the reg will 
--*                   be presented and not the new data that is being written. 
--*                   Also for locations like FIFOs or other locations
--*                   that inherently get modified on read, they will not 
--*                   trigger the internal read strobes unless an explicit
--*                   read is performed to the location. So not on a write to
--*                   the location.
--*                6. The packet structure is as follows for the 32-bit 
--*                   words:
--*       
--*                   Input (MOSI) bits (MSB is received first)
--*                   
--*                   40 bit frame structure:
--*                   ----------------------------------------
--*                   39     Read/Write bit, '1' = read, '0' = write
--*                   38:32  7bit Register address to be accessed
--*                   31:0   The data to be written. This will end up
--*                          right justified in the register.
--*                     
--*                   Output (MISO) bits (MSB is output first)        
--*                   ----------------------------------------      
--*                   39:32  All low (0s).         
--*                   31:0   The data from the chip.  
--*
--*   
--*                   48 bit frame structure:
--*                   ----------------------------------------
--*                   47     Read/Write bit, '1' = read, '0' = write
--*                   46:32  15bit Register address to be accessed
--*                   31:0   The data to be written. This will end up
--*                          right justified in the register.
--*                     
--*                   Output (MISO) bits (MSB is output first)        
--*                   ----------------------------------------      
--*                   47:32  All low (0s).         
--*                   31:0   The data from the chip.     
--*
--*
--*               The registers are also accessible (if enabled at the top
--*               level) to allow reading through a uart interface.                                 
--*
--*           b. Provides control registers for the various other 
--*              modules in the design. These are accessible through the SPI
--*              interface but also can be accessed through the avalone interface. 
--*
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author            Description
--*   -----------    --------------    -----------
--*   2011XXXX       Logic Tectonics   Initial design.
--*   202501XX       Same              Modifed for use on customer specific project.
--*   
--*   20251112       Same              Added ports added by the customer for the 1st pass board:
--*                                    
--*                                    adc_cal_trig : out std_logic_vector(5 downto 0);
--*                                    adc_cal_stat : in  std_logic_vector(5 downto 0);
--*                                    adc_pll_en   : out std_logic_vector(5 downto 0);
--*                                    Done.
--*   
--*   20251205       Same              Added: 
--*                                       
--*                                    cal_pulse_pwr_en  : out std_logic;                       
--*                                    cal_switch_adc    : out std_logic_vector(1 downto 0); 
--*                                    adc_regulator_en  : out std_logic_vector(1 downto 0); 
--*   
--*                                    Removed:
--*                                    clk_pll_status_0                   : in  std_logic;
--*                                    clk_pll_status_1                   : in  std_logic;
--* 
--*
--*    2026-- 	       EJO/CHICAGO		updates for didaq system
--*    2026.6.30								make sw trigger bit self-clearing     
--*
--*  
--*----------------------------------------------------------------------------
--*   References: None
--*   
--*   Synthesis Considerations: None
--*
--*   Par Considerations: None
--*
--*----------------------------------------------------------------------------

library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.spi_slave_reg_intfc_pkg.all;

entity spi_slave_reg_intfc is
   generic(
      g_arst_pol                   : std_logic := '1';  -- default to '1' sets internal reset polarity
      g_spi_frame_len              : positive  := 48;   -- set to 32 for 7  bit address, 24 bit data
                                                        -- set to 40 for 7  bit address, 32 bit data
                                                        -- set to 48 for 15 bit address, 32 bit data. Us this on artic daq project
                                                        
      g_irq_pol                    : std_logic := '1';  -- '1' means active high for output interrupt line
      g_chip_rev                   : std_logic_vector(31 downto 0);  
      
      g_wdog_enb                   : std_logic := '0';   -- '1' = enable, '0' disabled  
      g_wdog_1st_term_ms           : positive := 2000;   -- In msec. Max time to first wdog punch  2 minimum 
      g_wdog_term_ms               : positive := 100     -- Normal wdog period after the first.                                              
      
   );

   port(
      
      -- Clock and reset
      arst                               : in   std_logic;  -- Module async reset
      clk                                : in   std_logic;  -- 125MHz Module clock, it is assumed that this clock is at least 4x the reg_sclk to make the SPI timing work     
      clk_wide                           : in   std_logic;  -- 250MHz wide data clock if needed; 
      
      -- Interrupt event(s) input active high. Will be positive edge detected in this module.
      -- Can be in any domain since will be resynchronized in this module               
      irq_events_in                      : in   std_logic_vector(3 downto 0);
                                                     
      -- Interrrupt pin after detection of events                                      
      irq_out                            : out  std_logic;  -- Used for interrupt sent to SBC (or Nios). Polarity depends on g_irq_pol.
                                         
      -- Timing out 
      tick_1_usec                        : out  std_logic;
      tick_1_msec                        : out  std_logic;          
      tick_1_sec                         : out  std_logic;
                                                                          
      -- Wdog reset output               
      wdog_sys_srst                      : out std_logic;   -- To top level to force a reset. Will be 8 clocks wide 
      wdog_punch_pls_dbg                 : out std_logic;   -- debug to help debug the watchdog issue SW was seeing                                         
                                         
      -- SPI Slave interface to access registers                  
      reg_sclk                           : in   std_logic;
      reg_ss_n                           : in   std_logic;
      reg_mosi                           : in   std_logic;
      reg_miso                           : out  std_logic;                               
                                                                      
      -- Led Interface                                                                                                   
      led_hb                             : out  std_logic; -- Active high LED driver output. Currently tied to a counter      
      leds                               : out  std_logic_vector(7 downto 0);
      switches                           : in   std_logic_vector(7 downto 0);
                                                
      -- Nios/Avalon slave interface let nios/pd/fabric access all regs
      alv_slv_reg_chipselect             : in   std_logic;  
      alv_slv_reg_waitrequest            : out  std_logic;     
      alv_slv_reg_addr                   : in   std_logic_vector(14 downto 0); -- For this device's definition in the pd, these are configured for 32-bitword addresses from Nios, not byte                   
      alv_slv_reg_rd_req                 : in   std_logic;                    
      alv_slv_reg_rd_data_valid          : out  std_logic;                    
      alv_slv_reg_rd_data                : out  std_logic_vector(31 downto 0);       
      alv_slv_reg_wr_req                 : in   std_logic;                                                                       
      alv_slv_reg_wr_data                : in   std_logic_vector(31 downto 0);
      
      -- Nios/Avalon master interface lest this module (i.e. the SBC) access anything in the pd memory map
      -- including the SPI master and I2C masters. Single 32 bit accesses only
      alv_mst_waitrequest                : in   std_logic;     
      alv_mst_addr                       : out  std_logic_vector(31 downto 0); -- byte address address for this module                    
      alv_mst_rd_req                     : out  std_logic;                    
      alv_mst_rd_data_valid              : in   std_logic;                    
      alv_mst_rd_data                    : in   std_logic_vector(31 downto 0);       
      alv_mst_wr_req                     : out  std_logic;                                                                       
      alv_mst_wr_data                    : out  std_logic_vector(31 downto 0);      
                                                                                    
      board_id                           : in   std_logic_vector(1 downto 0);

      gpio_data_in                       : in  std_logic_vector(31 downto 0);
      gpio_data_out                      : out std_logic_vector(31 downto 0);    
      gpio_data_oe                       : out std_logic_vector(31 downto 0);
      
      -- JESD control
      jesd_if_out_fifo_rst_n             : out std_logic;   -- shared with low and high, this module sync this into the clk_wide.                
                                                                                                    
      jesd_if_low_rx_rst_n               : out std_logic_vector(5 downto 0);                               
      jesd_if_low_rx_rst_ack_n           : in  std_logic_vector(5 downto 0);                               
      jesd_if_low_rx_out_of_reset        : in  std_logic_vector(5 downto 0);                               
                                                                                                           
      jesd_if_high_rx_rst_n              : out std_logic_vector(5 downto 0);                            
      jesd_if_high_rx_rst_ack_n          : in  std_logic_vector(5 downto 0);                                   
      jesd_if_high_rx_out_of_reset       : in  std_logic_vector(5 downto 0);                                   
                                                                                                        
      jesd_if_low_loopback_enb           : out std_logic_vector(5 downto 0);                            
      jesd_if_high_loopback_enb          : out std_logic_vector(5 downto 0);                            
                                                                                                    
      jesd_if_avs_sel                    : out std_logic_vector(2 downto 0); -- shared with low and high
      jesd_if_low_adc_dlckd              : in  std_logic_vector(11 downto 0);  -- todo: Domain?         
      jesd_if_high_adc_dlckd             : in  std_logic_vector(11 downto 0);                                 
                               
      -- Unless noted the outputs below are all in the clk domain.
      -- Unless noted the inputs are assumed to be in a differnt to "clk" domain
      -- and will be synchronized in this module to clk before use. 
      -- 
      adc_pdwn_stby                      : out std_logic_vector(5 downto 0);     
      adc_spi_sel                        : out std_logic_vector(2 downto 0);
      
      adc_cal_trig                       : out std_logic_vector(1 downto 0);  -- Foreground calibration trigger control. This pin is only used if hardware calibration triggering is selected in 
                                                                              -- the ADC CAL_TRIG_EN reg, otherwise software triggering is performed using CAL_SOFT_TRIG. Tie this pin to GND if not       
                                                                              -- used.                                                                                                         
      adc_cal_stat                       : in  std_logic_vector(5 downto 0);  -- Foreground calibration status output or device alarm output. Functionality is programmed through 
                                                                              -- CAL_STATUS_SEL. This pin can be left disconnected if not used.                                                                          
      adc_pll_en                         : out std_logic_vector(1 downto 0);  -- '1' to enable the internal PLL for sampling clock generation if set high or to disable and bypass the 
                                                                              -- PLL if set low. Tie this pin to '0' if PLL is not used.                                                                                    
      
      adc_syncse_n                       : out std_logic_vector(1 downto 0);     
      
      cal_pulse                          : out std_logic;
      cal_pulse_pwr_en                   : out std_logic;                           
      cal_switch_adc                     : out std_logic_vector(1 downto 0);        
      adc_regulator_en                   : out std_logic_vector(1 downto 0);        
      
      
      clk_pll_reset_n                    : out std_logic;
      clk_pll_sync                       : out std_logic;
      clk_pll_clkin_sel                  : out std_logic;
                                                                           
      -- daq control/status/event metadata registers 
      --  
      capture_ctrl           	: out std_logic_vector(31 downto 0);      
      capture_stat           	: in  std_logic_vector(31 downto 0); 
      trigger_ctrl1				: out std_logic_vector(31 downto 0);
		trigger_mask1				: out std_logic_vector(31 downto 0);
		trigger_ctrl2				: out std_logic_vector(31 downto 0);
		trigger_mask2				: out std_logic_vector(31 downto 0);		
		ptrigger_ctrl				: out std_logic_vector(31 downto 0); 
		readout_ctrl				: out std_logic_vector(31 downto 0); 
		posttrig_ctrl				: out std_logic_vector(31 downto 0); 
		coinc_trigger_thresh0 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh1 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh2 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh3 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh4 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh5 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh6 	: out   std_logic_vector(31 downto 0);
		coinc_trigger_thresh7 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh8 	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh9 	: out   std_logic_vector(31 downto 0); 	
		coinc_trigger_thresh10	: out   std_logic_vector(31 downto 0); 
		coinc_trigger_thresh11	: out   std_logic_vector(31 downto 0); 
		beam_trig_thresh0			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh1			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh2			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh3			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh4			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh5			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh6			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh7			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh8			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh9			: out   std_logic_vector(31 downto 0);
		beam_trig_thresh10		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh11		: out   std_logic_vector(31 downto 0);
		last_evt_evt_count		: in  std_logic_vector(31 downto 0);      
		last_evt_trig_count		: in  std_logic_vector(31 downto 0);      
		last_evt_deadtime			: in  std_logic_vector(31 downto 0);     
		last_evt_clkcount			: in  std_logic_vector(31 downto 0);      
		last_evt_ppscount			: in  std_logic_vector(31 downto 0);    
		last_evt_metamisc1		: in  std_logic_vector(31 downto 0);     
		last_evt_metamisc2		: in  std_logic_vector(31 downto 0);      
		last_evt_trig_adr			: in  std_logic_vector(31 downto 0);     
		--scalers (on clk_rd)
		scaler_sel					: out   std_logic_vector(31 downto 0);
		scaler_read					: in	 std_logic_vector(31 downto 0); 
      
      -- The data format is big endian, where the 
      -- earliest octet/sample is placed in bit [31:24] and the latest 
      -- octet/sample is placed in bit [7:0].
      -- Its a look ahead FIFO so the the  _rd_ack pops the data and the fifo advances to the next entry in the fifo. 
      -- All of these inputs are already in the clk domain of this module.
      -- the output rd_ack is in the clk domain and the adc data buffer module assumes that too.                         
      adc_0_fifo_data                    : in  std_logic_vector(31 downto 0);  -- Data from channel 4 8-bit samps packed              
      adc_0_fifo_rd_ack                  : out std_logic;                                                                                                                                                                                                                                                                                                                           
      adc_1_fifo_data                    : in  std_logic_vector(31 downto 0);                                                        
      adc_1_fifo_rd_ack                  : out std_logic;                                                                                                                                   
      adc_2_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_2_fifo_rd_ack                  : out std_logic;                                                                                                                                 
      adc_3_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_3_fifo_rd_ack                  : out std_logic;                                                                                                                                                                        
      adc_4_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_4_fifo_rd_ack                  : out std_logic;                                                                                                                                                                                                                                                            
      adc_5_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_5_fifo_rd_ack                  : out std_logic;                                                                                                                                      
      adc_6_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_6_fifo_rd_ack                  : out std_logic;                                                                                                                                    
      adc_7_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_7_fifo_rd_ack                  : out std_logic;                                                                                                                                                                 
      adc_8_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_8_fifo_rd_ack                  : out std_logic;                                                                                                                                                                                                                                                          
      adc_9_fifo_data                    : in  std_logic_vector(31 downto 0);  
      adc_9_fifo_rd_ack                  : out std_logic;                                                                                  
      adc_10_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_10_fifo_rd_ack                 : out std_logic;                                                                                                                                       
      adc_11_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_11_fifo_rd_ack                 : out std_logic;                                                                                             
      adc_12_fifo_data                   : in  std_logic_vector(31 downto 0);               
      adc_12_fifo_rd_ack                 : out std_logic;                                                                                                                                                                                                                                                                                                                              
      adc_13_fifo_data                   : in  std_logic_vector(31 downto 0);                                                        
      adc_13_fifo_rd_ack                 : out std_logic;                                                                                                                              
      adc_14_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_14_fifo_rd_ack                 : out std_logic;                                                                                                                            
      adc_15_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_15_fifo_rd_ack                 : out std_logic;                                                                                                                                                              
      adc_16_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_16_fifo_rd_ack                 : out std_logic;                                                                                                                                                                                                                                                  
      adc_17_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_17_fifo_rd_ack                 : out std_logic;                                                                                                                          
      adc_18_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_18_fifo_rd_ack                 : out std_logic;                                                                                                                            
      adc_19_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_19_fifo_rd_ack                 : out std_logic;                                                                                                                                                    
      adc_20_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_20_fifo_rd_ack                 : out std_logic;                                                                                                                                                                                                                                                         
      adc_21_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_21_fifo_rd_ack                 : out std_logic;                                                                                                                              
      adc_22_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_22_fifo_rd_ack                 : out std_logic;                                                                                                                                      
      adc_23_fifo_data                   : in  std_logic_vector(31 downto 0);  
      adc_23_fifo_rd_ack                 : out std_logic                                                                                                                                                                                                                                                                                                                                                                                                                                       
   );                                                                                                                         
                                                                                                                         
end entity;                                                                                              
                                                                                                                                                                                                                 
architecture rtl of spi_slave_reg_intfc is                                                                 
--                                                                                                          
-- Components                                                                                                
--
component reference_gen is
   generic(
      g_arst_pol  : std_logic := '1'; -- default to '1' being te polarity of arst input
      
      g_n_main         : positive  := 3277;  -- This is the n factor for to generate the ms and us tick refernce from clk in 
      g_k_main         : positive  := 17;    -- This is the k factor for to generate the ms and us tick refernce from clk in 
                                             -- Make sure to set to create a 1 MHz clock from clk in. fclk *  n/2^k
      
      g_n_misc         : positive  := 755;   -- This is the n factor for to generate misc_tick refernce from clk in
      g_k_misc         : positive  := 13;    -- This is the k factor for to generate misc_tick refernce from clk in
                                             
      g_m_ms           : positive  := 1000;  -- One based these are divisors to create slower ticks from the ms and us ticks, max is 1024
      g_m_us           : positive  := 20     -- These are divisors to create slower ticks from the ms and us ticks. 1000 max
        
      
   );   
      

   port(
      
      arst           : in   std_logic;       --  Async reset, polarity set by arst_pol
      clk            : in   std_logic;       --  Clk. Pos edge active.
                     
      ms_tick        : out  std_logic;       -- millisecond tick pulse (one clk wide)
      us_tick        : out  std_logic;       -- microsecond tick pulse (one clk wide)
      
      ms_tick_div_m  : out  std_logic;
      us_tick_div_m  : out  std_logic;
      
      misc_tick      : out  std_logic                                                            
      
   );
   
end component reference_gen;  
         

component timing_gen is
   generic(
      g_arst_pol  : std_logic := '1'; -- default to '1' being te polarity of arst input
      g_n         : positive  := 10; 
      g_k         : positive  := 13
   );   
      

   port(
      
      arst        : in   std_logic;                          --  Async reset, polarity set by arst_pol
      clk         : in   std_logic;                          --  Clk. Pos edge active.
                  
      tick_pls    : out  std_logic                           -- Async read strobe, active low
   );
   
end component timing_gen;



--
-- Constants
--

-- Types
   type spi_slave_state_type is (s_spi_wait_ss_low_and_clk_ped,
                                 s_spi_wait_rw_bit,
                                 s_spi_wait_addr,
                                 s_spi_wait_data_phase                                  
                                 );                              
                                 
-- Signals
   
   --
   -- Register declarations
   -- Read only registers and write through ports dont need a signal/reg
   --
   signal chip_rev_reg                : std_logic_vector(31 downto 0);          
   signal irq_stat_reg                : std_logic_vector(15 downto 0);
   signal irq_enb_reg                 : std_logic_vector(15 downto 0);                                     
   signal sbc_scratch_pad_reg         : std_logic_vector(31 downto 0);   
   signal avl_scratch_pad_reg         : std_logic_vector(31 downto 0);  
   signal adc_pdwn_stby_reg           : std_logic_vector(5 downto 0);                                                                                                      
   signal adc_cal_trig_reg            : std_logic_vector(1 downto 0);                                                                                                                                         
   signal adc_syncse_n_reg            : std_logic_vector(1 downto 0);                                                                                                                             
   --signal adc_cal_stat_reg            : std_logic_vector(5 downto 0);                                                                 
   signal adc_pll_en_reg              : std_logic_vector(1 downto 0);                                                                                                                                                                                                                                    
   signal adc_spi_sel_reg             : std_logic_vector(2 downto 0); -- only 6 adc + Clock/PLL chip                                                                                                     
   --signal capture_stat_reg            : std_logic_vector(31 downto 0);                               
   
                                                                       -- Bit   Funciion
   signal misc_ctrl_reg               : std_logic_vector(7 downto 0);  -- 0     cal_pulse control out 
                                                                       -- 1     cal_pulse_pwr_en   
                                                                       -- 3:2   cal_switch_adc     
                                                                       -- 5:4   adc_regulator_en   
   
   signal pll_ctrl_stat_reg           : std_logic_vector(7 downto 0);  -- clk_pll_reset_n       0             : out
                                                                       -- clk_pll_sync          1             : out
                                                                       -- clk_pll_clkin_sel     2             : out
                                                                       -- spare                 3
                                                                       -- spare                 4             
                                                                       -- spare                 5             
                                                                       -- spare                 6
                                                                       -- spare                 7
   
   signal led_reg                     : std_logic_vector(7 downto 0);
   
   signal jesd_rst_reg                : std_logic_vector(12 downto 0);
   signal jesd_loopback_reg           : std_logic_vector(11 downto 0);
   signal jesd_avs_sel_reg            : std_logic_vector(2 downto 0); 
   
   
   signal gpio_data_reg               : std_logic_vector(31 downto 0);
   signal gpio_data_oe_reg            : std_logic_vector(31 downto 0);                                                                         
                                                                                                                                                        
   -- Signals related to the sampling of the SPI input clk and ports
   signal reg_sclk_mf                 : std_logic;
   signal reg_sclk_rr                 : std_logic;
   signal reg_sclk_rrr                : std_logic;
                                      
   signal reg_sclk_fed                : std_logic; -- falling edge detect    
   --signal reg_sclk_fed_r            : std_logic; -- falling edge detect delayed
                                      
   signal reg_sclk_ped                : std_logic; -- rising edge detect
                                      
   signal reg_ss_n_mf                 : std_logic;
   signal reg_ss_n_rr                 : std_logic;
                                      
   signal reg_mosi_mf                 : std_logic;
   signal reg_mosi_rr                 : std_logic;
                                      
   -- FSM for the SPI slave           
   signal spi_slave_state             : spi_slave_state_type;
   signal spi_rw_bit                  : std_logic;
   signal rx_spi_bit_cnt              : std_logic_vector(5 downto 0);
   signal rx_spi_data_sr              : std_logic_vector(30 downto 0); -- LSB comes from another flop
   --signal spi_frame_err_pls         : std_logic;
   
   -- Signals related to actual register file decoder for SPI accesses            
   signal spi_wr_addr                 : std_logic_vector(14 downto 0);
   signal spi_rd_addr                 : std_logic_vector(14 downto 0);
   signal spi_wr_strb                 : std_logic;                                    
   signal spi_wr_strb_bus             : std_logic_vector(c_num_of_regs-1 downto 0);
   
   -- Signals related to the write strobe bus for avalon interface accesses
   signal avl_wr_strb                 : std_logic;
   signal avl_wr_strb_bus             : std_logic_vector(c_num_of_regs-1 downto 0);                                                                                                                          
                                      
   -- Read process related            
   signal tx_spi_data_sr              : std_logic_vector(31 downto 0);   
                                      
   signal led_cnt                     : std_logic_vector(10 downto 0);        
                                      
   signal all_zeros                   : std_logic_vector(31 downto 0);
   --signal high                      : std_logic;
   --signal low                       : std_logic;                                    
                                      
                                        
   signal spi_reg_write_data          : std_logic_vector(31 downto 0);
                                      
   signal last_spi_addr_bit_loc       : natural range 0 to 63;
   signal last_spi_data_bit_loc       : natural range 0 to 63; 
                                          
   signal wdog_punch_pls              : std_logic;
    
   signal wdog_short_per              : std_logic;
   signal wdog_msec_cnt               : std_logic_vector(15 downto 0);
   signal wdog_expired_pls            : std_logic := '0';
   signal wdog_expired_pls_r          : std_logic := '0';
   signal wdog_sys_srst_vec           : std_logic_vector(7 downto 0);
          
   signal irq_events_in_mf            : std_logic_vector(3 downto 0);
   signal irq_events_in_r             : std_logic_vector(3 downto 0);
   signal irq_events_in_rr            : std_logic_vector(3 downto 0);
   signal irq_events_in_ped           : std_logic_vector(3 downto 0);
   
   signal avl_to_sbc_mailbox_reg      : std_logic_vector(31 downto 0); 
   signal sbc_to_avl_mailbox_reg      : std_logic_vector(31 downto 0); 
   
   signal tick_ms                     : std_logic;
   signal tick_us                     : std_logic;
                                      
   signal tick_sec                    : std_logic;
   signal tick_100us                  : std_logic;
   signal sbc_adc_fifo_rd_ack         : std_logic_vector(23 downto 0);
   signal avl_adc_fifo_rd_ack         : std_logic_vector(23 downto 0);
   signal adc_fifo_rd_ack             : std_logic_vector(23 downto 0);
   
   signal jesd_if_out_fifo_rst_n_mf   : std_logic;
   
   signal avl_mst_addr_reg            : std_logic_vector(31 downto 0); -- using word addresses, so this maps to 32-bits of byte addresse
   signal avl_mst_wr_data_reg         : std_logic_vector(31 downto 0);
   signal avl_mst_rd_data_reg         : std_logic_vector(31 downto 0);
   signal avl_mst_ctrl_stat_reg       : std_logic_vector(1 downto 0); -- bit 0 = '1' for writes to avl, self clearing
                                                                     -- bit 1 = '1' for reads from avl, self clear when data retruns
   signal capture_ctrl_reg          	: std_logic_vector(31 downto 0);    
   signal trigger_ctrl1_reg				: std_logic_vector(31 downto 0); 
	signal trigger_mask1_reg				: std_logic_vector(31 downto 0);
	signal trigger_ctrl2_reg				: std_logic_vector(31 downto 0); 
	signal trigger_mask2_reg				: std_logic_vector(31 downto 0);	
	signal ptrigger_ctrl_reg				: std_logic_vector(31 downto 0);
	signal readout_ctrl_reg					: std_logic_vector(31 downto 0); 
	signal posttrig_ctrl_reg				: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh0_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh1_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh2_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh3_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh4_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh5_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh6_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh7_reg 	: std_logic_vector(31 downto 0); 
	signal coinc_trigger_thresh8_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh9_reg 	: std_logic_vector(31 downto 0);
	signal coinc_trigger_thresh10_reg	: std_logic_vector(31 downto 0); 
	signal coinc_trigger_thresh11_reg	: std_logic_vector(31 downto 0);
	signal beam_trig_thresh0_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh1_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh2_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh3_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh4_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh5_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh6_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh7_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh8_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh9_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh10_reg			: std_logic_vector(31 downto 0);
	signal beam_trig_thresh11_reg			: std_logic_vector(31 downto 0);
	signal scaler_sel_reg					: std_logic_vector(31 downto 0);
   
   
   
begin

-- Convienent assignment for use in various locations. 
all_zeros <= (others => '0');
--high <= '1';
--low  <= '0';

alv_slv_reg_waitrequest <= '0';

-- Take value right from generic.
chip_rev_reg <= g_chip_rev;

--
-- Setup the refernce generator
--
inst_reference_gen : reference_gen
   generic map(
      g_arst_pol       => g_arst_pol,
      
      g_n_main         => 262, -- Make sure to set to create a 1 MHz clock from clk in. fclk *  n/2^k
      g_k_main         => 15, 
                                             
      
      g_n_misc         => 755,     -- This is the n factor for to generate misc_tick refernce from clk in, not used.
      g_k_misc         => 13,      -- This is the k factor for to generate misc_tick refernce from clk in, not used.
                                           
      g_m_ms           => 1000,    -- One based these are divisors to create slower ticks from the ms and us ticks, max is 1024
      g_m_us           => 100      -- These are divisors to create slower ticks from the ms and us ticks. 1000 max
        
      
   )                                                                
   port map(                                               
                                                              
      arst           => arst,                          
      clk            => clk,                        
                     
      ms_tick        => tick_ms,       -- millisecond tick pulse (one clk wide)
      us_tick        => tick_us,       -- microsecond tick pulse (one clk wide)
      
      ms_tick_div_m  => tick_sec,      -- 1 second tick
      us_tick_div_m  => tick_100us,    -- 100 us tick
      
      misc_tick      => open                                                             
      
   );
           
-- Connect to port pisn for use at higher layers   
tick_1_usec  <= tick_us; 
tick_1_msec  <= tick_ms; 
tick_1_sec   <= tick_sec; 

--------------------------------------------------------
--
--------------------------------------------------------                  
--                                                                        
-- Synchonize some signals to system clk
--
process(clk,arst)
begin
   if arst = g_arst_pol then
           
      irq_events_in_mf             <= (others => '0');
      irq_events_in_r              <= (others => '0');
      irq_events_in_rr             <= (others => '0');   
      
   elsif clk'event and clk = '1' then 
      irq_events_in_mf <= irq_events_in;
      irq_events_in_r  <= irq_events_in_mf; 
      irq_events_in_rr <= irq_events_in_r; 
    
   end if;
end process;

--positive edge detection to create pulse on the ps edge                   
irq_events_in_ped <= not(irq_events_in_rr) and irq_events_in_r; 

--
-- First metastable stage on neg edge. The SPI interface is sampled 
-- in the clk domain. So these signals are used for that purpose.
-- Using neg then pos edge is the fastest resync/capture method.
-- Not that clk must be at least 4x the spi clock for the methods 
-- in this module to operate properly.
--
process(clk,arst)
begin
   if arst = g_arst_pol then
      reg_sclk_mf    <= '0';
      reg_ss_n_mf    <= '1';
      reg_mosi_mf    <= '0';
      
   elsif clk'event and clk = '0' then
      reg_sclk_mf    <= reg_sclk;
      reg_ss_n_mf    <= reg_ss_n;
      reg_mosi_mf    <= reg_mosi; 
      
   end if;
end process;   

--
-- The interface to the SPI port is a sampled interface. This
-- Process will generate the necessary sampled data/strobes
-- Also some other unrelated items are here for convenience.
-- 
process(clk,arst)
begin
   if arst = g_arst_pol then
      
      reg_sclk_rr      <= '0';                      
      reg_ss_n_rr      <= '1';                                             
      reg_mosi_rr      <= '0'; 
      reg_sclk_rrr     <= '0';     
      --reg_sclk_fed_r <= '0';    
    
   elsif clk'event and clk = '1' then
        
      reg_sclk_rr      <= reg_sclk_mf;                              
      reg_ss_n_rr      <= reg_ss_n_mf;                                               
      reg_mosi_rr      <= reg_mosi_mf; 
      
      reg_sclk_rrr     <= reg_sclk_rr;                                                                                        
      --reg_sclk_fed_r <= reg_sclk_fed;
      
   end if;  
end process;

--
-- Some useful strobes
--
reg_sclk_fed <= '1' when reg_sclk_rrr = '1' and reg_sclk_rr =  '0' else '0';
reg_sclk_ped <= '1' when reg_sclk_rrr = '0' and reg_sclk_rr =  '1' else '0';


-- g_spi_frame_len         First bit of frame (0)        address msb     address lsb     Data msb   Data lsb
--              32         R/W                           1               7               8          31
--              40         R/W                           1               7               8          39
--              48         R/W                           1               15              16         47
--
--
--
--
-- These are assuming the first bit R/W is bit 0
-- This signal is used to properly captur the address and data form the SPI frame.
last_spi_addr_bit_loc <= 7  when g_spi_frame_len = 32 or g_spi_frame_len = 40 else 15;
last_spi_data_bit_loc <= 31 when g_spi_frame_len = 32 else
                         39 when g_spi_frame_len = 40 else 47;
--
-- SPI Slave fsm. This could be reduced to 3 state but this makes it explicit so easy expand later.
--
process(clk,arst)
begin
   if arst = g_arst_pol then
      
      spi_rw_bit          <= '1';
      spi_slave_state <= s_spi_wait_ss_low_and_clk_ped;
   
   elsif clk'event and clk = '1' then
      case spi_slave_state is 
      
         when s_spi_wait_ss_low_and_clk_ped =>
            spi_rw_bit           <= '1';
         
            if reg_ss_n_rr = '0' and reg_sclk_ped = '1' then
               spi_slave_state <= s_spi_wait_rw_bit;
            end if; 
      
         when s_spi_wait_rw_bit =>
         
            if reg_ss_n_rr = '1' then             -- If the chip select gets deasserted in this state then there was an issue
               spi_slave_state <= s_spi_wait_ss_low_and_clk_ped;    -- then go wait until the chip select is deasserted
                           
            elsif reg_sclk_fed = '1' then         -- Active SPI frame, chip select is asserted, falling edge on clk
               spi_rw_bit       <= reg_mosi_rr;   -- Capture the read/write bit. '0' = write   
               spi_slave_state  <= s_spi_wait_addr;
                  
            end if;            
         
         when s_spi_wait_addr => 
                                              
            if reg_ss_n_rr = '1' then               -- If thge chip select gets deasserted in this state then there was an issue
               spi_slave_state <= s_spi_wait_ss_low_and_clk_ped;             
            elsif conv_integer('0'&rx_spi_bit_cnt) = last_spi_addr_bit_loc and reg_sclk_fed = '1' then      -- Wait until the end of the address phase
               spi_slave_state  <= s_spi_wait_data_phase;            
            end if;            
           
         when s_spi_wait_data_phase =>         
            
            if reg_ss_n_rr = '1' then               -- If thge chip select gets deasserted in this state then there was an issue
               spi_slave_state <= s_spi_wait_ss_low_and_clk_ped;             
            elsif conv_integer('0'&rx_spi_bit_cnt) = last_spi_data_bit_loc and reg_sclk_fed = '1' then      -- Wait until the end of the data phase
               spi_slave_state <= s_spi_wait_ss_low_and_clk_ped;            
            end if;            
                  
         when others =>
            null;
                  
      end case;                                                                                                  
         
   end if;

end process;

--
-- Combinatorial related to the SPI FSM
--

--
-- Counters and shift regs related to the FSM operation. Also captures the address.
--                                           
process(clk,arst)           
begin                            
   if arst = g_arst_pol then
       
       rx_spi_data_sr    <= (others => '0');
       rx_spi_bit_cnt    <= (others => '0');
       spi_wr_addr       <= (others => '0');

       
   elsif clk'event and clk = '1' then
      -- Manage the SPI input shift register. Its 32 bits wide, that is the largest need at any particular time
      if reg_sclk_fed = '1' and ((spi_slave_state = s_spi_wait_rw_bit) or (spi_slave_state = s_spi_wait_addr) or (spi_slave_state = s_spi_wait_data_phase)) then  
          rx_spi_data_sr <= rx_spi_data_sr(rx_spi_data_sr'left-1 downto 0)&reg_mosi_rr;
      end if;    
      
      -- Manage the SPI bit counter    
      if spi_slave_state = s_spi_wait_ss_low_and_clk_ped then
         rx_spi_bit_cnt <= (others => '0'); -- preset to 0
      elsif (spi_slave_state /= s_spi_wait_ss_low_and_clk_ped) and reg_sclk_fed = '1' then 
         rx_spi_bit_cnt <= rx_spi_bit_cnt + 1;
      end if;
      
      -- Capture the address
      if conv_integer('0'&rx_spi_bit_cnt) = last_spi_addr_bit_loc and reg_sclk_fed = '1' and (spi_slave_state = s_spi_wait_addr) then
         if g_spi_frame_len = 32 or g_spi_frame_len = 40 then -- only 7 bit address
            spi_wr_addr <= "00000000"&rx_spi_data_sr(5 downto 0)&reg_mosi_rr;
         else -- 14 bit address
            spi_wr_addr <= rx_spi_data_sr(13 downto 0)&reg_mosi_rr;
         end if;   
      end if;                                                                                                                                
                                                                                                                                          
   end if;                                                                                                                                
end process;
       
--
-- Generate the write strobe. It fires when in a write and the last data bit is available
--

spi_wr_strb     <= '1' when spi_slave_state = s_spi_wait_data_phase and (conv_integer('0'&rx_spi_bit_cnt) = last_spi_data_bit_loc) and reg_sclk_fed = '1' and spi_rw_bit = '0' else '0';

--
-- Write bus generation for SPI side accesses. this assumes that the address is setup before the spi_wr_strb occurs. The address is from the SPI bus
-- receive shift register. This was augmented to support write from the dgb serial module also.
--
process(spi_wr_addr, spi_wr_strb)
   variable spi_wr_strb_bus_var : std_logic_vector(spi_wr_strb_bus'range);
begin
   spi_wr_strb_bus_var := (others => '0'); -- preset the variable to all '0's                      
   if spi_wr_strb = '1' then                                           
      for i in 0 to c_num_of_regs-1 loop      
         if conv_integer('0'&spi_wr_addr) = i then
            spi_wr_strb_bus_var(i) := '1';
         end if;                                           
      end loop;
   end if;
   spi_wr_strb_bus <= spi_wr_strb_bus_var; 
end process;

--
-- Write strobe gen for AVL accesses so can be independent or concurrent with SPI
--
avl_wr_strb <= alv_slv_reg_wr_req; -- Strobe comes right from the avalon bus

process(avl_wr_strb, alv_slv_reg_addr,alv_slv_reg_chipselect)
   variable avl_wr_strb_bus_var : std_logic_vector(avl_wr_strb_bus'range);
begin
   avl_wr_strb_bus_var := (others => '0'); -- preset the variable to all '0's                      
   if avl_wr_strb = '1' and alv_slv_reg_chipselect = '1' then                                           
      for i in 0 to c_num_of_regs-1 loop     
         if conv_integer('0'&alv_slv_reg_addr(alv_slv_reg_addr'left downto 0)) = i then
            avl_wr_strb_bus_var(i) := '1';            
         end if;                                               
      end loop;
   end if;
   avl_wr_strb_bus <= avl_wr_strb_bus_var; 
end process;


-------------------------------------------------------------------------------                                                       
-- Write registers process. All writeable registers (from the external CPU and Nios and serial debugger)
-- are handled in this proess.                               
-------------------------------------------------------------------------------

spi_reg_write_data <= (rx_spi_data_sr & reg_mosi_rr);     


                    
process(clk,arst)
begin
   if arst = g_arst_pol then
   
      -- Assign the reset values here (or from a package if desired)
            
      irq_stat_reg                <= (others => '0');       
      irq_enb_reg                 <= (others => '0');  -- '1' Allows driving the interrupt pin if corresponding stat bit is set   
                                                                                                                                                                                                                                                                                     
      sbc_scratch_pad_reg         <= (others => '0');     
      avl_scratch_pad_reg         <= (others => '0');
              
      adc_pdwn_stby_reg           <= (others => '0'); -- default to powerdown
      
      adc_cal_trig_reg            <= (others => '0');
      adc_syncse_n_reg            <= (others => '0');
      adc_pll_en_reg              <= (others => '0');
           
      adc_spi_sel_reg             <= (others => '0');
      
      misc_ctrl_reg               <= (others => '0');
                       
      pll_ctrl_stat_reg           <= (others => '0');
                  
      led_reg                     <= (others => '0');
        
      wdog_punch_pls              <= '0';
           
      gpio_data_reg               <= (others => '0'); 
      gpio_data_oe_reg            <= (others => '0');
      
      avl_to_sbc_mailbox_reg      <= (others => '0'); 
      sbc_to_avl_mailbox_reg      <= (others => '0');
      
      avl_mst_addr_reg            <= (others => '0');
      avl_mst_wr_data_reg         <= (others => '0');
      avl_mst_rd_data_reg         <= (others => '0');
      avl_mst_ctrl_stat_reg       <= (others => '0');    
      
      jesd_rst_reg                <= (others => '0');
      jesd_loopback_reg           <= (others => '0');
      jesd_avs_sel_reg            <= (others => '0');  

		capture_ctrl_reg           <= (others => '0');    
      trigger_ctrl1_reg				<= (others => '0'); 
		trigger_mask1_reg				<= (others => '0'); 
		trigger_ctrl2_reg				<= (others => '0');  
		trigger_mask2_reg				<= (others => '0');
		ptrigger_ctrl_reg				<= (others => '0');
		readout_ctrl_reg				<= (others => '0'); 
		posttrig_ctrl_reg				<= (others => '0');
		coinc_trigger_thresh0_reg 	<= (others => '0'); 
		coinc_trigger_thresh1_reg 	<= (others => '0');
		coinc_trigger_thresh2_reg 	<= (others => '0');
		coinc_trigger_thresh3_reg 	<= (others => '0');
		coinc_trigger_thresh4_reg 	<= (others => '0'); 
		coinc_trigger_thresh5_reg 	<= (others => '0');
		coinc_trigger_thresh6_reg 	<= (others => '0');
		coinc_trigger_thresh7_reg 	<= (others => '0'); 
		coinc_trigger_thresh8_reg 	<= (others => '0'); 
		coinc_trigger_thresh9_reg 	<= (others => '0');	
		coinc_trigger_thresh10_reg	<= (others => '0'); 
		coinc_trigger_thresh11_reg	<= (others => '0'); 
		beam_trig_thresh0_reg		<= (others => '0');
		beam_trig_thresh1_reg		<= (others => '0');
		beam_trig_thresh2_reg		<= (others => '0');
		beam_trig_thresh3_reg		<= (others => '0');
		beam_trig_thresh4_reg		<= (others => '0');
		beam_trig_thresh5_reg		<= (others => '0');
		beam_trig_thresh6_reg		<= (others => '0');
		beam_trig_thresh7_reg		<= (others => '0');
		beam_trig_thresh8_reg		<= (others => '0');
		beam_trig_thresh9_reg		<= (others => '0');
		beam_trig_thresh10_reg		<= (others => '0');
		beam_trig_thresh11_reg		<= (others => '0');
		scaler_sel_reg					<= (others => '0');
      
   elsif clk'event and clk = '1' then  
      
      -------------------------------------
      -- SBC exclusive registers      
      -------------------------------------
      if spi_wr_strb_bus(c_sbc_scratch_pad_reg_addr) = '1' then sbc_scratch_pad_reg <= spi_reg_write_data; end if;
      -------------------------------------
      -- Dual access registers 
      -------------------------------------
      -- Watchdog
      wdog_punch_pls <= '0';   
      if avl_wr_strb_bus(c_wdog_reg_addr) = '1' then 
         if alv_slv_reg_wr_data = X"FFAA5500" then
            wdog_punch_pls <= '1';
         end if;   
      end if;             
           
      -- Manage the iqr status register. These bits get set 
      -- when the source indicates the event occurred but only drive the output 
      -- irq if 
      --  irq_stat_reg()
      --  (0)           Not defined yet 
      --  (1)           Not defined yet
      --  (2)           Not defined yet
      --  (3)           Not defined yet
      for i in 0 to 3 loop
         if irq_events_in_ped(i) = '1'  then -- on pos edge of interrupt line
            irq_stat_reg(i) <= '1';
         elsif (spi_wr_strb_bus(c_irq_stat_reg_addr) = '1' and spi_reg_write_data(i) = '1') or 
               (avl_wr_strb_bus(c_irq_stat_reg_addr) = '1' and alv_slv_reg_wr_data(i) = '1') then -- if writing a '1' to the bit then clear it
             irq_stat_reg(i) <= '0';     
         end if;
      end loop;    
      -- Just keep the other irq status bits cleared for now                         
      irq_stat_reg(15 downto 4) <= (others => '0');   
            
      if spi_wr_strb_bus(c_irq_enb_reg_addr) = '1' then irq_enb_reg <= spi_reg_write_data( irq_enb_reg'left downto 0); end if;      
      if avl_wr_strb_bus(c_irq_enb_reg_addr) = '1' then irq_enb_reg <= alv_slv_reg_wr_data(irq_enb_reg'left downto 0); end if;   
      
      if spi_wr_strb_bus(c_led_switch_reg_addr) = '1' then led_reg <=  spi_reg_write_data( led_reg'left downto 0); end if;
      if avl_wr_strb_bus(c_led_switch_reg_addr) = '1' then led_reg <=  alv_slv_reg_wr_data(led_reg'left downto 0); end if;
      
      if spi_wr_strb_bus(c_adc_pdwn_stby_reg_addr) = '1' then adc_pdwn_stby_reg <= spi_reg_write_data (adc_pdwn_stby_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_adc_pdwn_stby_reg_addr) = '1' then adc_pdwn_stby_reg <= alv_slv_reg_wr_data(adc_pdwn_stby_reg'left downto 0); end if;
               
      if spi_wr_strb_bus(c_adc_cal_trig_reg_addr)  = '1' then  adc_cal_trig_reg <= spi_reg_write_data (adc_cal_trig_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_adc_cal_trig_reg_addr)  = '1' then  adc_cal_trig_reg <= alv_slv_reg_wr_data(adc_cal_trig_reg'left downto 0); end if;
            
      if spi_wr_strb_bus(c_adc_syncse_n_reg_addr)  = '1' then  adc_syncse_n_reg <= spi_reg_write_data (adc_syncse_n_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_adc_syncse_n_reg_addr)  = '1' then  adc_syncse_n_reg <= alv_slv_reg_wr_data(adc_syncse_n_reg'left downto 0); end if;
          
      if spi_wr_strb_bus(c_adc_pll_en_reg_addr  )  = '1' then  adc_pll_en_reg   <= spi_reg_write_data (adc_pll_en_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_adc_pll_en_reg_addr  )  = '1' then  adc_pll_en_reg   <= alv_slv_reg_wr_data(adc_pll_en_reg'left downto 0); end if;
      
      if spi_wr_strb_bus(c_adc_spi_sel_reg_addr) = '1'   then adc_spi_sel_reg <= spi_reg_write_data (adc_spi_sel_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_adc_spi_sel_reg_addr) = '1'   then adc_spi_sel_reg <= alv_slv_reg_wr_data(adc_spi_sel_reg'left downto 0); end if;  
      ----                                               
      if spi_wr_strb_bus(c_misc_ctrl_reg_addr) = '1'     then misc_ctrl_reg <= spi_reg_write_data (misc_ctrl_reg'left downto 0); end if;  
      if avl_wr_strb_bus(c_misc_ctrl_reg_addr) = '1'     then misc_ctrl_reg <= alv_slv_reg_wr_data(misc_ctrl_reg'left downto 0); end if;  
      
      if spi_wr_strb_bus(c_pll_ctrl_stat_reg_addr) = '1' then pll_ctrl_stat_reg <= spi_reg_write_data (pll_ctrl_stat_reg'left downto 0); end if;  
      if avl_wr_strb_bus(c_pll_ctrl_stat_reg_addr) = '1' then pll_ctrl_stat_reg <= alv_slv_reg_wr_data(pll_ctrl_stat_reg'left downto 0); end if;       
      ---
      if spi_wr_strb_bus(c_capture_ctrl_reg_addr) = '1'  then capture_ctrl_reg <= spi_reg_write_data (capture_ctrl_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_capture_ctrl_reg_addr) = '1'  then capture_ctrl_reg <= alv_slv_reg_wr_data(capture_ctrl_reg'left downto 0); end if;       
      
      if spi_wr_strb_bus(c_gpio_data_reg_addr    ) = '1' then gpio_data_reg    <= spi_reg_write_data(gpio_data_reg'left downto 0); end if;
      if avl_wr_strb_bus(c_gpio_data_reg_addr    ) = '1' then gpio_data_reg    <= alv_slv_reg_wr_data(gpio_data_reg'left downto 0); end if;  
      
      if spi_wr_strb_bus(c_gpio_data_oe_reg_addr ) = '1' then gpio_data_oe_reg <= spi_reg_write_data(gpio_data_oe_reg'left downto 0); end if;
      if avl_wr_strb_bus(c_gpio_data_oe_reg_addr ) = '1' then gpio_data_oe_reg <= alv_slv_reg_wr_data(gpio_data_reg'left downto 0); end if;                               

      --if spi_wr_strb_bus(c_avl_to_sbc_mailbox_reg_addr  ) = '1' then avl_to_sbc_mailbox_reg <= spi_reg_write_data(gpio_data_reg'left downto 0); end if;
      if avl_wr_strb_bus(c_avl_to_sbc_mailbox_reg_addr  ) = '1' then avl_to_sbc_mailbox_reg <= alv_slv_reg_wr_data(31 downto 0); end if;               
                                                                                         
      if spi_wr_strb_bus(c_sbc_to_avl_mailbox_reg_addr  ) = '1' then sbc_to_avl_mailbox_reg <= spi_reg_write_data(gpio_data_reg'left downto 0); end if;
      --if avl_wr_strb_bus(c_sbc_to_avl_mailbox_reg_addr  ) = '1' then sbc_to_avl_mailbox_reg <= alv_slv_reg_wr_data(31 downto 0); end if;               
      
           
      if spi_wr_strb_bus(c_jesd_rst_reg_addr     ) = '1' then jesd_rst_reg       <= spi_reg_write_data(jesd_rst_reg'left downto 0); end if;
      if avl_wr_strb_bus(c_jesd_rst_reg_addr     ) = '1' then jesd_rst_reg       <= alv_slv_reg_wr_data(jesd_rst_reg'left downto 0); end if;               
      if spi_wr_strb_bus(c_jesd_loopback_reg_addr) = '1' then jesd_loopback_reg  <= spi_reg_write_data(jesd_loopback_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_jesd_loopback_reg_addr) = '1' then jesd_loopback_reg  <= alv_slv_reg_wr_data(jesd_loopback_reg'left downto 0); end if;
      if spi_wr_strb_bus(c_jesd_avs_sel_reg_addr ) = '1' then jesd_avs_sel_reg   <= spi_reg_write_data(jesd_avs_sel_reg'left downto 0); end if; 
      if avl_wr_strb_bus(c_jesd_avs_sel_reg_addr ) = '1' then jesd_avs_sel_reg   <= alv_slv_reg_wr_data(jesd_avs_sel_reg'left downto 0); end if;
      ---added didaq specific UC:
		if spi_wr_strb_bus(c_trigger_ctrl_1_addr ) = '1' then trigger_ctrl1_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_ctrl_1_addr ) = '1' then trigger_ctrl1_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_mask_1_addr ) = '1' then trigger_mask1_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_mask_1_addr ) = '1' then trigger_mask1_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_trigger_ctrl_2_addr ) = '1' then trigger_ctrl2_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_ctrl_2_addr ) = '1' then trigger_ctrl2_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_mask_2_addr ) = '1' then trigger_mask2_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_mask_2_addr ) = '1' then trigger_mask2_reg <= alv_slv_reg_wr_data(31 downto 0); end if;		
		if spi_wr_strb_bus(c_phased_trig_ctrl_addr ) = '1' then ptrigger_ctrl_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_phased_trig_ctrl_addr ) = '1' then ptrigger_ctrl_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_trigger_thresh_00_addr ) = '1' then coinc_trigger_thresh0_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_00_addr ) = '1' then coinc_trigger_thresh0_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_01_addr ) = '1' then coinc_trigger_thresh1_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_01_addr ) = '1' then coinc_trigger_thresh1_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_02_addr ) = '1' then coinc_trigger_thresh2_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_02_addr ) = '1' then coinc_trigger_thresh2_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_03_addr ) = '1' then coinc_trigger_thresh3_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_03_addr ) = '1' then coinc_trigger_thresh3_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_04_addr ) = '1' then coinc_trigger_thresh4_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_04_addr ) = '1' then coinc_trigger_thresh4_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_05_addr ) = '1' then coinc_trigger_thresh5_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_05_addr ) = '1' then coinc_trigger_thresh5_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_06_addr ) = '1' then coinc_trigger_thresh6_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_06_addr ) = '1' then coinc_trigger_thresh6_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_07_addr ) = '1' then coinc_trigger_thresh7_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_07_addr ) = '1' then coinc_trigger_thresh7_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_08_addr ) = '1' then coinc_trigger_thresh8_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_08_addr ) = '1' then coinc_trigger_thresh8_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_trigger_thresh_09_addr ) = '1' then coinc_trigger_thresh9_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_09_addr ) = '1' then coinc_trigger_thresh9_reg <= alv_slv_reg_wr_data(31 downto 0); end if;		
		if spi_wr_strb_bus(c_trigger_thresh_10_addr ) = '1' then coinc_trigger_thresh10_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_10_addr ) = '1' then coinc_trigger_thresh10_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_trigger_thresh_11_addr ) = '1' then coinc_trigger_thresh11_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_trigger_thresh_11_addr ) = '1' then coinc_trigger_thresh11_reg <= alv_slv_reg_wr_data(31 downto 0); end if;			
		if spi_wr_strb_bus(c_beam_thresh_0_addr ) = '1' then beam_trig_thresh0_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_0_addr ) = '1' then beam_trig_thresh0_reg <= alv_slv_reg_wr_data(31 downto 0); end if;		
		if spi_wr_strb_bus(c_beam_thresh_1_addr ) = '1' then beam_trig_thresh1_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_1_addr ) = '1' then beam_trig_thresh1_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_2_addr ) = '1' then beam_trig_thresh2_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_2_addr ) = '1' then beam_trig_thresh2_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_3_addr ) = '1' then beam_trig_thresh3_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_3_addr ) = '1' then beam_trig_thresh3_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_4_addr ) = '1' then beam_trig_thresh4_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_4_addr ) = '1' then beam_trig_thresh4_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_5_addr ) = '1' then beam_trig_thresh5_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_5_addr ) = '1' then beam_trig_thresh5_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_6_addr ) = '1' then beam_trig_thresh6_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_6_addr ) = '1' then beam_trig_thresh6_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_7_addr ) = '1' then beam_trig_thresh7_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_7_addr ) = '1' then beam_trig_thresh7_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_8_addr ) = '1' then beam_trig_thresh8_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_8_addr ) = '1' then beam_trig_thresh8_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_9_addr ) = '1' then beam_trig_thresh9_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_9_addr ) = '1' then beam_trig_thresh9_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_10_addr ) = '1' then beam_trig_thresh10_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_10_addr ) = '1' then beam_trig_thresh10_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_beam_thresh_11_addr ) = '1' then beam_trig_thresh11_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_beam_thresh_11_addr ) = '1' then beam_trig_thresh11_reg <= alv_slv_reg_wr_data(31 downto 0); end if;	
		if spi_wr_strb_bus(c_scaler_select_addr ) = '1' then scaler_sel_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_scaler_select_addr ) = '1' then scaler_sel_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_readout_ctrl_addr ) = '1' then readout_ctrl_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_readout_ctrl_addr ) = '1' then readout_ctrl_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
		if spi_wr_strb_bus(c_post_trigger_length_addr ) = '1' then posttrig_ctrl_reg <= spi_reg_write_data(31 downto 0); end if;
      if avl_wr_strb_bus(c_post_trigger_length_addr ) = '1' then posttrig_ctrl_reg <= alv_slv_reg_wr_data(31 downto 0); end if;
      -- Only need to allow these to be accessible form the SBC 
      -- SPI slave since the Nios and serial debugger does not need to use this since they already 
      -- have access to the entire register set.
      -- This is strictly to allow the SBC the same access.
      if spi_wr_strb_bus(c_avl_mst_addr_reg_addr     ) = '1' then avl_mst_addr_reg      <= spi_reg_write_data(31 downto 0);   end if;
      if spi_wr_strb_bus(c_avl_mst_wr_data_reg_addr  ) = '1' then avl_mst_wr_data_reg   <= spi_reg_write_data(31 downto 0);   end if;
      -- Register to allow kicking off of a read or write
      if spi_wr_strb_bus(c_avl_mst_ctrl_stat_reg_addr) = '1' then 
         if (spi_reg_write_data(1 downto 0) = "10" or spi_reg_write_data(1 downto 0) = "01") and avl_mst_ctrl_stat_reg = "00" then -- only allow one at a time (read or write) and only after the current is serviced
             avl_mst_ctrl_stat_reg <= spi_reg_write_data(1 downto 0);    
         end if;
      end if;   
      -- Self clear the pending read or write request when the fabric accepts it.
      if alv_mst_waitrequest = '0' and avl_mst_ctrl_stat_reg /= "00" then
         avl_mst_ctrl_stat_reg <= "00";
      end if;  
      -- capture returning data on reads 
      if alv_mst_rd_data_valid = '1' then avl_mst_rd_data_reg <= alv_mst_rd_data; end if;      
      
      -----------------------------------------------------------------------------------------------------
      -- NIOS/AVL exclusive regs
      ----------------------------------------------------------------------------------------------------- 
      -- avl_scratch_pad_reg Writeable from the AVL/NIOS side, exclusively               
      if avl_wr_strb_bus(c_avl_scratch_pad_reg_addr) = '1' then avl_scratch_pad_reg <= alv_slv_reg_wr_data; end if; 
                                                                                      
   end if;                                                                        
end process; 

-- Connect regs to outputs of this module   
gpio_data_out     <= gpio_data_reg;   
gpio_data_oe      <= gpio_data_oe_reg;
                  
adc_spi_sel       <= adc_spi_sel_reg;

cal_pulse         <= misc_ctrl_reg(0);

cal_pulse_pwr_en  <= misc_ctrl_reg(1);        
cal_switch_adc    <= misc_ctrl_reg(3 downto 2);      
adc_regulator_en  <= misc_ctrl_reg(5 downto 4);      
clk_pll_reset_n   <= pll_ctrl_stat_reg(0);
clk_pll_sync      <= pll_ctrl_stat_reg(1);
clk_pll_clkin_sel <= pll_ctrl_stat_reg(2);
capture_ctrl           <= capture_ctrl_reg;    
trigger_ctrl1				<= trigger_ctrl1_reg; 
trigger_mask1				<= trigger_mask1_reg; 
trigger_ctrl2				<= trigger_ctrl2_reg; 
trigger_mask2				<= trigger_mask2_reg; 
ptrigger_ctrl				<= ptrigger_ctrl_reg;
readout_ctrl				<= readout_ctrl_reg; 
posttrig_ctrl				<= posttrig_ctrl_reg;
coinc_trigger_thresh0 	<= coinc_trigger_thresh0_reg; 
coinc_trigger_thresh1 	<= coinc_trigger_thresh1_reg;
coinc_trigger_thresh2 	<= coinc_trigger_thresh2_reg;
coinc_trigger_thresh3 	<= coinc_trigger_thresh3_reg;
coinc_trigger_thresh4 	<= coinc_trigger_thresh4_reg;
coinc_trigger_thresh5 	<= coinc_trigger_thresh5_reg;
coinc_trigger_thresh6 	<= coinc_trigger_thresh6_reg;
coinc_trigger_thresh7 	<= coinc_trigger_thresh7_reg; 
coinc_trigger_thresh8 	<= coinc_trigger_thresh8_reg;
coinc_trigger_thresh9 	<= coinc_trigger_thresh9_reg;	
coinc_trigger_thresh10	<= coinc_trigger_thresh10_reg;
coinc_trigger_thresh11	<= coinc_trigger_thresh11_reg; 
beam_trig_thresh0		<= beam_trig_thresh0_reg;
beam_trig_thresh1		<= beam_trig_thresh1_reg;
beam_trig_thresh2		<= beam_trig_thresh2_reg;
beam_trig_thresh3		<= beam_trig_thresh3_reg;
beam_trig_thresh4		<= beam_trig_thresh4_reg;
beam_trig_thresh5		<= beam_trig_thresh5_reg;
beam_trig_thresh6		<= beam_trig_thresh6_reg;
beam_trig_thresh7		<= beam_trig_thresh7_reg;
beam_trig_thresh8		<= beam_trig_thresh8_reg;
beam_trig_thresh9		<= beam_trig_thresh9_reg;
beam_trig_thresh10	<= beam_trig_thresh10_reg;
beam_trig_thresh11	<= beam_trig_thresh11_reg;
scaler_sel				<= scaler_sel_reg;

adc_pdwn_stby <= adc_pdwn_stby_reg;
leds          <= led_reg;

jesd_if_low_rx_rst_n      <= jesd_rst_reg(5 downto 0);
jesd_if_high_rx_rst_n     <= jesd_rst_reg(11 downto 6);
jesd_if_low_loopback_enb  <= jesd_loopback_reg(5 downto 0); 
jesd_if_high_loopback_enb <= jesd_loopback_reg(11 downto 6);
jesd_if_avs_sel           <= jesd_avs_sel_reg(2 downto 0);

--
-- Manage the master back to the pd system memory map
--                    
alv_mst_addr                   <= avl_mst_addr_reg;   
alv_mst_rd_req                 <= avl_mst_ctrl_stat_reg(0);                                                
alv_mst_wr_req                 <= avl_mst_ctrl_stat_reg(1);                                                                             
alv_mst_wr_data                <= avl_mst_wr_data_reg;  

-- sync the jesd jesd_if_out_fifo_rst_n to clk_wide.
-- That module's fifo should do that but 
-- done here also.  
process(clk_wide)
begin
  if clk_wide'event and clk_wide = '1' then
     jesd_if_out_fifo_rst_n_mf <= jesd_rst_reg(12);
     jesd_if_out_fifo_rst_n    <= jesd_if_out_fifo_rst_n_mf;
  end if;
end process;

--
-- The SPI accessible read process. Requires loading the read SR with the data from the registers.
-- At the earliest possible point the read address is ready the appropriate register will
-- be read and loaded into the output/tx shift register. Then the shift register continues to
-- shift at each positive edge. The first (MSB) bit loaded is a dummy leading 0 that is flushed on the
-- first positive edge.
--
-- This is just a convientent assignment to be used later. This will continue to shift as data is received over the SPI bus
-- but will be valid when needed.
--

spi_rd_addr <= "00000000"&rx_spi_data_sr(5 downto 0)  & reg_mosi_rr when g_spi_frame_len = 32 or g_spi_frame_len = 40 else -- Case for 7 bit address
                         rx_spi_data_sr(13 downto 0) & reg_mosi_rr;
process(clk,arst)
begin
   if arst = g_arst_pol then
      tx_spi_data_sr             <= (others => '0');   
      sbc_adc_fifo_rd_ack        <= (others => '0');                   
      
   elsif clk'event and clk = '1' then
      
      sbc_adc_fifo_rd_ack <= (others => '0'); -- used to zero out to create only a pulse as below 
   
      if conv_integer('0'&rx_spi_bit_cnt) = last_spi_addr_bit_loc and reg_sclk_fed = '1' and spi_slave_state = s_spi_wait_addr then 
         case conv_integer('0'&spi_rd_addr) is
         
            when c_chip_rev_reg_addr           => tx_spi_data_sr <= chip_rev_reg; 
                                               
            when c_board_id_reg_addr           => tx_spi_data_sr(31 downto 0) <= all_zeros(31 downto 2)&board_id;                                                                                                                                                                                                                                      
                                                                                                             
            when c_irq_stat_reg_addr           => tx_spi_data_sr <= all_zeros(31 downto irq_stat_reg'length)&irq_stat_reg;                  
                 
            when c_irq_enb_reg_addr            => tx_spi_data_sr <= all_zeros(31 downto irq_enb_reg'length)&irq_enb_reg;                
            
            when c_led_switch_reg_addr         => tx_spi_data_sr <= all_zeros(31 downto 16) & switches & led_reg;
            
            
            when c_sbc_scratch_pad_reg_addr    => tx_spi_data_sr <= sbc_scratch_pad_reg;
                                               
            when c_gpio_data_reg_addr          => tx_spi_data_sr <= gpio_data_in;
            when c_gpio_data_oe_reg_addr       => tx_spi_data_sr <= gpio_data_oe_reg;            
                                               
            when c_adc_pdwn_stby_reg_addr      => tx_spi_data_sr <= all_zeros(31 downto adc_pdwn_stby_reg'length)&adc_pdwn_stby_reg;
            
            when c_adc_cal_trig_reg_addr       => tx_spi_data_sr <= all_zeros(31 downto adc_cal_trig_reg'length)&adc_cal_trig_reg;         
            when c_adc_syncse_n_reg_addr       => tx_spi_data_sr <= all_zeros(31 downto adc_syncse_n_reg'length)&adc_syncse_n_reg;   
            
            when c_adc_cal_stat_reg_addr       => tx_spi_data_sr <= all_zeros(31 downto adc_cal_stat'length)&adc_cal_stat;
            when c_adc_pll_en_reg_addr         => tx_spi_data_sr <= all_zeros(31 downto adc_pll_en_reg'length)&adc_pll_en_reg;
                                
            when c_adc_spi_sel_reg_addr        => tx_spi_data_sr <= all_zeros(31 downto adc_spi_sel_reg'length)&adc_spi_sel_reg;
            
            when c_misc_ctrl_reg_addr          => tx_spi_data_sr <= all_zeros(31 downto misc_ctrl_reg'length) & misc_ctrl_reg;                       
            when c_pll_ctrl_stat_reg_addr      => tx_spi_data_sr <= all_zeros(31 downto pll_ctrl_stat_reg'length) & "00" &  '0' & '0' & '0' & pll_ctrl_stat_reg(2 downto 0);
            
            when c_capture_ctrl_reg_addr       => tx_spi_data_sr <= capture_ctrl_reg;            
            when c_capture_stat_reg_addr       => tx_spi_data_sr <= capture_stat;
            
            when c_jesd_rst_reg_addr           => tx_spi_data_sr <= all_zeros(31 downto 28) & jesd_if_high_rx_out_of_reset & jesd_if_low_rx_out_of_reset  & all_zeros(15 downto 13) & jesd_rst_reg;           
            when c_jesd_loopback_reg_addr      => tx_spi_data_sr <= all_zeros(31 downto jesd_loopback_reg'length)& jesd_loopback_reg;
            when c_jesd_avs_sel_reg_addr       => tx_spi_data_sr <= all_zeros(31 downto jesd_avs_sel_reg'length) & jesd_avs_sel_reg;
            when c_jesd_locked_stat_reg_addr   => tx_spi_data_sr <= all_zeros(31 downto 24) & jesd_if_high_adc_dlckd & jesd_if_low_adc_dlckd;
          
            when c_adc_0_fifo_data_reg_addr    => tx_spi_data_sr <= adc_0_fifo_data;  sbc_adc_fifo_rd_ack(0) <= '1'; -- will create a pulse since next clock will zero out            
            when c_adc_1_fifo_data_reg_addr    => tx_spi_data_sr <= adc_1_fifo_data;  sbc_adc_fifo_rd_ack(1) <= '1';
            when c_adc_2_fifo_data_reg_addr    => tx_spi_data_sr <= adc_2_fifo_data;  sbc_adc_fifo_rd_ack(2) <= '1';
            when c_adc_3_fifo_data_reg_addr    => tx_spi_data_sr <= adc_3_fifo_data;  sbc_adc_fifo_rd_ack(3) <= '1';
            when c_adc_4_fifo_data_reg_addr    => tx_spi_data_sr <= adc_4_fifo_data;  sbc_adc_fifo_rd_ack(4) <= '1';
            when c_adc_5_fifo_data_reg_addr    => tx_spi_data_sr <= adc_5_fifo_data;  sbc_adc_fifo_rd_ack(5) <= '1';
            when c_adc_6_fifo_data_reg_addr    => tx_spi_data_sr <= adc_6_fifo_data;  sbc_adc_fifo_rd_ack(6) <= '1';
            when c_adc_7_fifo_data_reg_addr    => tx_spi_data_sr <= adc_7_fifo_data;  sbc_adc_fifo_rd_ack(7) <= '1';
            when c_adc_8_fifo_data_reg_addr    => tx_spi_data_sr <= adc_8_fifo_data;  sbc_adc_fifo_rd_ack(8) <= '1';
            when c_adc_9_fifo_data_reg_addr    => tx_spi_data_sr <= adc_9_fifo_data;  sbc_adc_fifo_rd_ack(9) <= '1';
            when c_adc_10_fifo_data_reg_addr   => tx_spi_data_sr <= adc_10_fifo_data; sbc_adc_fifo_rd_ack(10) <= '1';
            when c_adc_11_fifo_data_reg_addr   => tx_spi_data_sr <= adc_11_fifo_data; sbc_adc_fifo_rd_ack(11) <= '1';
            when c_adc_12_fifo_data_reg_addr   => tx_spi_data_sr <= adc_12_fifo_data; sbc_adc_fifo_rd_ack(12) <= '1';
            when c_adc_13_fifo_data_reg_addr   => tx_spi_data_sr <= adc_13_fifo_data; sbc_adc_fifo_rd_ack(13) <= '1';
            when c_adc_14_fifo_data_reg_addr   => tx_spi_data_sr <= adc_14_fifo_data; sbc_adc_fifo_rd_ack(14) <= '1';
            when c_adc_15_fifo_data_reg_addr   => tx_spi_data_sr <= adc_15_fifo_data; sbc_adc_fifo_rd_ack(15) <= '1';
            when c_adc_16_fifo_data_reg_addr   => tx_spi_data_sr <= adc_16_fifo_data; sbc_adc_fifo_rd_ack(16) <= '1';
            when c_adc_17_fifo_data_reg_addr   => tx_spi_data_sr <= adc_17_fifo_data; sbc_adc_fifo_rd_ack(17) <= '1';
            when c_adc_18_fifo_data_reg_addr   => tx_spi_data_sr <= adc_18_fifo_data; sbc_adc_fifo_rd_ack(18) <= '1';
            when c_adc_19_fifo_data_reg_addr   => tx_spi_data_sr <= adc_19_fifo_data; sbc_adc_fifo_rd_ack(19) <= '1';
            when c_adc_20_fifo_data_reg_addr   => tx_spi_data_sr <= adc_20_fifo_data; sbc_adc_fifo_rd_ack(20) <= '1';
            when c_adc_21_fifo_data_reg_addr   => tx_spi_data_sr <= adc_21_fifo_data; sbc_adc_fifo_rd_ack(21) <= '1';
            when c_adc_22_fifo_data_reg_addr   => tx_spi_data_sr <= adc_22_fifo_data; sbc_adc_fifo_rd_ack(22) <= '1';
            when c_adc_23_fifo_data_reg_addr   => tx_spi_data_sr <= adc_23_fifo_data; sbc_adc_fifo_rd_ack(23) <= '1';      
            
				when c_trigger_ctrl_1_addr			=> tx_spi_data_sr <= trigger_ctrl1_reg; 
				when c_trigger_mask_1_addr			=> tx_spi_data_sr <= trigger_mask1_reg; 
				when c_trigger_ctrl_2_addr			=> tx_spi_data_sr <= trigger_ctrl2_reg; 
				when c_trigger_mask_2_addr			=> tx_spi_data_sr <= trigger_mask2_reg; 	
				when c_phased_trig_ctrl_addr		=> tx_spi_data_sr <=	ptrigger_ctrl_reg;
				when c_trigger_thresh_00_addr		=> tx_spi_data_sr <= coinc_trigger_thresh0_reg;
				when c_trigger_thresh_01_addr		=> tx_spi_data_sr <= coinc_trigger_thresh1_reg;
				when c_trigger_thresh_02_addr		=> tx_spi_data_sr <= coinc_trigger_thresh2_reg;
				when c_trigger_thresh_03_addr		=> tx_spi_data_sr <= coinc_trigger_thresh3_reg;
				when c_trigger_thresh_04_addr		=> tx_spi_data_sr <= coinc_trigger_thresh4_reg;
				when c_trigger_thresh_05_addr		=> tx_spi_data_sr <= coinc_trigger_thresh5_reg;
				when c_trigger_thresh_06_addr		=> tx_spi_data_sr <= coinc_trigger_thresh6_reg;
				when c_trigger_thresh_07_addr		=> tx_spi_data_sr <= coinc_trigger_thresh7_reg;
				when c_trigger_thresh_08_addr		=> tx_spi_data_sr <= coinc_trigger_thresh8_reg;
				when c_trigger_thresh_09_addr		=> tx_spi_data_sr <= coinc_trigger_thresh9_reg;
				when c_trigger_thresh_10_addr		=> tx_spi_data_sr <= coinc_trigger_thresh10_reg;
				when c_trigger_thresh_11_addr		=> tx_spi_data_sr <= coinc_trigger_thresh11_reg;
				when c_beam_thresh_0_addr 			=> tx_spi_data_sr <= beam_trig_thresh0_reg;
				when c_beam_thresh_1_addr 			=> tx_spi_data_sr <= beam_trig_thresh1_reg;
				when c_beam_thresh_2_addr 			=> tx_spi_data_sr <= beam_trig_thresh2_reg;
				when c_beam_thresh_3_addr 			=> tx_spi_data_sr <= beam_trig_thresh3_reg;
				when c_beam_thresh_4_addr 			=> tx_spi_data_sr <= beam_trig_thresh4_reg;
				when c_beam_thresh_5_addr 			=> tx_spi_data_sr <= beam_trig_thresh5_reg;
				when c_beam_thresh_6_addr 			=> tx_spi_data_sr <= beam_trig_thresh6_reg;
				when c_beam_thresh_7_addr 			=> tx_spi_data_sr <= beam_trig_thresh7_reg;
				when c_beam_thresh_8_addr 			=> tx_spi_data_sr <= beam_trig_thresh8_reg;
				when c_beam_thresh_9_addr 			=> tx_spi_data_sr <= beam_trig_thresh9_reg;
				when c_beam_thresh_10_addr 		=> tx_spi_data_sr <= beam_trig_thresh10_reg;
				when c_beam_thresh_11_addr 		=> tx_spi_data_sr <= beam_trig_thresh11_reg;
				when c_lastevt_event_counter_addr		=> tx_spi_data_sr <= last_evt_evt_count;		
				when c_lastevt_trig_counter_addr			=> tx_spi_data_sr <= last_evt_trig_count;	
				when c_lastevt_deadtime_counter_addr	=> tx_spi_data_sr <= last_evt_deadtime;	
				when c_lastevt_sincepps_counter_addr	=> tx_spi_data_sr <= last_evt_clkcount;	
				when c_lastevt_pps_counter_addr			=> tx_spi_data_sr <= last_evt_ppscount;	
				when c_lastevt_metamisc_1_addr			=> tx_spi_data_sr <= last_evt_metamisc1;	
				when c_lastevt_metamisc_2_addr			=> tx_spi_data_sr <= last_evt_metamisc2;	
				when c_lastevt_trigadr_addr				=> tx_spi_data_sr <= last_evt_trig_adr;	
				when c_post_trigger_length_addr			=> tx_spi_data_sr <= posttrig_ctrl_reg;	
				when c_readout_ctrl_addr					=> tx_spi_data_sr <= readout_ctrl_reg;					
				when c_scaler_readout_addr			=> tx_spi_data_sr <= scaler_read;			
				when c_scaler_select_addr			=> tx_spi_data_sr <= scaler_sel_reg;							
				
            when c_avl_to_sbc_mailbox_reg_addr => tx_spi_data_sr  <= avl_to_sbc_mailbox_reg;
            when c_sbc_to_avl_mailbox_reg_addr => tx_spi_data_sr  <= sbc_to_avl_mailbox_reg;
            
            when c_avl_mst_addr_reg_addr       =>  tx_spi_data_sr <= avl_mst_addr_reg;
            when c_avl_mst_wr_data_reg_addr    =>  tx_spi_data_sr <= avl_mst_wr_data_reg;
            when c_avl_mst_rd_data_reg_addr    =>  tx_spi_data_sr <= avl_mst_rd_data_reg;
            when c_avl_mst_ctrl_stat_reg_addr  =>  tx_spi_data_sr <= all_zeros(31 downto 2) & avl_mst_ctrl_stat_reg;           
                                                                          
            when others =>
               tx_spi_data_sr <= (others => '0');      
         end case;  
 
      elsif reg_sclk_fed = '1' then -- on neg edge since the the clock neg edge detect rececived here will be delayed by at least 1 clock so will meet hold back the at the processor.
                                    -- Add to this the delay of the clock from the processor to the FPGA and you easily meet the setup time back at the processor of 5 ns.
                                    --       
         tx_spi_data_sr <= tx_spi_data_sr(tx_spi_data_sr'left-1 downto 0)&'0'; 
      end if;   
   end if;   

end process;

--                         
-- Drive the interrupt line. If irq enable = '1' then allow interrupt to set the interrupt pin active
--                         
irq_out   <= g_irq_pol when (irq_stat_reg and irq_enb_reg) /= all_zeros(irq_stat_reg'left downto 0) else not g_irq_pol; 

--
-- Assign outputs to the module ports
--
reg_miso <= tx_spi_data_sr(23) when g_spi_frame_len = 32 else  -- 24 bit data case
            tx_spi_data_sr(tx_spi_data_sr'left); -- 32 bit data case
            
                        
adc_cal_trig  <= adc_cal_trig_reg;                                                                                                                                                                                                                                                            
adc_pll_en    <= adc_pll_en_reg;  

adc_syncse_n  <= adc_syncse_n_reg;

-- LED signals. For now just tie to 2 counter bits of a slow reference so that we know the chip is alive
--
process(clk,arst)
begin
   if arst = g_arst_pol then
      led_cnt <= (others => '0');
      
   elsif clk'event and clk = '1' then
      if tick_ms = '1' then
         led_cnt <= led_cnt + 1;
      end if;
   
   end if;
end process;
-- Connect these to the top level    
led_hb <= led_cnt(led_cnt'left-1); 

--
-- This is the read mux for the avalon. It allows the avalon to 
-- to read the registers indepndent of the processor spi interface to the chip
--                  
process(clk,arst)
begin
   if arst = g_arst_pol then
      alv_slv_reg_rd_data_valid   <= '0';
      alv_slv_reg_rd_data         <= (others => '0');
                 
   elsif clk'event and clk = '1' then
   
      alv_slv_reg_rd_data_valid         <= '0'; -- self clear after a read
      
      avl_adc_fifo_rd_ack <= (others => '0'); -- used to zero out to create only a pulse as below 
      
      if alv_slv_reg_rd_req = '1' and alv_slv_reg_chipselect = '1' then 
      
         alv_slv_reg_rd_data_valid <= '1'; -- one clock latency
         
         case conv_integer('0'&alv_slv_reg_addr) is
         
            when c_chip_rev_reg_addr           => alv_slv_reg_rd_data(31 downto 0) <= g_chip_rev; 
                                               
            when c_board_id_reg_addr           => alv_slv_reg_rd_data(31 downto 0) <= all_zeros(31 downto 2)&board_id;               
             
            when c_irq_stat_reg_addr           => alv_slv_reg_rd_data <= all_zeros(31 downto irq_stat_reg'length)&irq_stat_reg;
  
            when c_irq_enb_reg_addr            => alv_slv_reg_rd_data <= all_zeros(31 downto irq_enb_reg'length)&irq_enb_reg;                
                                                             
            when c_led_switch_reg_addr         => alv_slv_reg_rd_data <= all_zeros(31 downto 16) & switches & led_reg;
            
            when c_avl_scratch_pad_reg_addr    => alv_slv_reg_rd_data(31 downto 0) <= avl_scratch_pad_reg;
                
            when c_gpio_data_reg_addr          => alv_slv_reg_rd_data <= gpio_data_in;
            when c_gpio_data_oe_reg_addr       => alv_slv_reg_rd_data <= gpio_data_oe_reg;
                                               
            when c_adc_pdwn_stby_reg_addr      => alv_slv_reg_rd_data <= all_zeros(31 downto adc_pdwn_stby_reg'length)&adc_pdwn_stby_reg;
                               
            when c_adc_cal_trig_reg_addr       => alv_slv_reg_rd_data <= all_zeros(31 downto adc_cal_trig_reg'length)&adc_cal_trig_reg;
            when c_adc_syncse_n_reg_addr       => alv_slv_reg_rd_data <= all_zeros(31 downto adc_syncse_n_reg'length)&adc_syncse_n_reg;
            
            when c_adc_cal_stat_reg_addr       => alv_slv_reg_rd_data <= all_zeros(31 downto adc_cal_stat'length)&adc_cal_stat;        
            when c_adc_pll_en_reg_addr         => alv_slv_reg_rd_data <= all_zeros(31 downto adc_pll_en_reg'length)&adc_pll_en_reg;    
                            
            when c_adc_spi_sel_reg_addr        => alv_slv_reg_rd_data <= all_zeros(31 downto adc_spi_sel_reg'length)&adc_spi_sel_reg;
            
            when c_misc_ctrl_reg_addr          => alv_slv_reg_rd_data <= all_zeros(31 downto misc_ctrl_reg'length) & misc_ctrl_reg;                                                                        
            when c_pll_ctrl_stat_reg_addr      => alv_slv_reg_rd_data <= all_zeros(31 downto pll_ctrl_stat_reg'length) & "00" & '0' &'0'& '0' & pll_ctrl_stat_reg(2 downto 0);
              
            when c_capture_ctrl_reg_addr       => alv_slv_reg_rd_data <= capture_ctrl_reg;
            when c_capture_stat_reg_addr       => alv_slv_reg_rd_data <= capture_stat;

            when c_jesd_rst_reg_addr           => alv_slv_reg_rd_data <= all_zeros(31 downto 28) & jesd_if_high_rx_out_of_reset & jesd_if_low_rx_out_of_reset  & all_zeros(15 downto 13) & jesd_rst_reg;           
            when c_jesd_loopback_reg_addr      => alv_slv_reg_rd_data <= all_zeros(31 downto jesd_loopback_reg'length)& jesd_loopback_reg;
            when c_jesd_avs_sel_reg_addr       => alv_slv_reg_rd_data <= all_zeros(31 downto jesd_avs_sel_reg'length) & jesd_avs_sel_reg;
            when c_jesd_locked_stat_reg_addr   => alv_slv_reg_rd_data <= all_zeros(31 downto 24) & jesd_if_high_adc_dlckd & jesd_if_low_adc_dlckd;                        
           
            when c_adc_0_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_0_fifo_data;  avl_adc_fifo_rd_ack(0) <= '1'; -- will create a pulse since next clock will zero out            
            when c_adc_1_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_1_fifo_data;  avl_adc_fifo_rd_ack(1) <= '1';
            when c_adc_2_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_2_fifo_data;  avl_adc_fifo_rd_ack(2) <= '1';
            when c_adc_3_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_3_fifo_data;  avl_adc_fifo_rd_ack(3) <= '1';
            when c_adc_4_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_4_fifo_data;  avl_adc_fifo_rd_ack(4) <= '1';
            when c_adc_5_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_5_fifo_data;  avl_adc_fifo_rd_ack(5) <= '1';
            when c_adc_6_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_6_fifo_data;  avl_adc_fifo_rd_ack(6) <= '1';
            when c_adc_7_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_7_fifo_data;  avl_adc_fifo_rd_ack(7) <= '1';
            when c_adc_8_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_8_fifo_data;  avl_adc_fifo_rd_ack(8) <= '1';
            when c_adc_9_fifo_data_reg_addr    => alv_slv_reg_rd_data <= adc_9_fifo_data;  avl_adc_fifo_rd_ack(9) <= '1';
            when c_adc_10_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_10_fifo_data; avl_adc_fifo_rd_ack(10) <= '1';
            when c_adc_11_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_11_fifo_data; avl_adc_fifo_rd_ack(11) <= '1';
            when c_adc_12_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_12_fifo_data; avl_adc_fifo_rd_ack(12) <= '1';
            when c_adc_13_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_13_fifo_data; avl_adc_fifo_rd_ack(13) <= '1';
            when c_adc_14_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_14_fifo_data; avl_adc_fifo_rd_ack(14) <= '1';
            when c_adc_15_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_15_fifo_data; avl_adc_fifo_rd_ack(15) <= '1';
            when c_adc_16_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_16_fifo_data; avl_adc_fifo_rd_ack(16) <= '1';
            when c_adc_17_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_17_fifo_data; avl_adc_fifo_rd_ack(17) <= '1';
            when c_adc_18_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_18_fifo_data; avl_adc_fifo_rd_ack(18) <= '1';
            when c_adc_19_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_19_fifo_data; avl_adc_fifo_rd_ack(19) <= '1';
            when c_adc_20_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_20_fifo_data; avl_adc_fifo_rd_ack(20) <= '1';
            when c_adc_21_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_21_fifo_data; avl_adc_fifo_rd_ack(21) <= '1';
            when c_adc_22_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_22_fifo_data; avl_adc_fifo_rd_ack(22) <= '1';
            when c_adc_23_fifo_data_reg_addr   => alv_slv_reg_rd_data <= adc_23_fifo_data; avl_adc_fifo_rd_ack(23) <= '1';    

				when c_trigger_ctrl_1_addr			=> alv_slv_reg_rd_data <= trigger_ctrl1_reg; 
				when c_trigger_mask_1_addr			=> alv_slv_reg_rd_data <= trigger_mask1_reg; 
				when c_trigger_ctrl_2_addr			=> alv_slv_reg_rd_data <= trigger_ctrl2_reg;
				when c_trigger_mask_2_addr			=> alv_slv_reg_rd_data <= trigger_mask2_reg; 		
				when c_phased_trig_ctrl_addr		=> alv_slv_reg_rd_data <=	ptrigger_ctrl_reg;
				when c_trigger_thresh_00_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh0_reg;
				when c_trigger_thresh_01_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh1_reg;
				when c_trigger_thresh_02_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh2_reg;
				when c_trigger_thresh_03_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh3_reg;
				when c_trigger_thresh_04_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh4_reg;
				when c_trigger_thresh_05_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh5_reg;
				when c_trigger_thresh_06_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh6_reg;
				when c_trigger_thresh_07_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh7_reg;
				when c_trigger_thresh_08_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh8_reg;
				when c_trigger_thresh_09_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh9_reg;
				when c_trigger_thresh_10_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh10_reg;
				when c_trigger_thresh_11_addr		=> alv_slv_reg_rd_data <= coinc_trigger_thresh11_reg;
				when c_beam_thresh_0_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh0_reg;
				when c_beam_thresh_1_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh1_reg;
				when c_beam_thresh_2_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh2_reg;
				when c_beam_thresh_3_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh3_reg;
				when c_beam_thresh_4_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh4_reg;
				when c_beam_thresh_5_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh5_reg;
				when c_beam_thresh_6_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh6_reg;
				when c_beam_thresh_7_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh7_reg;
				when c_beam_thresh_8_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh8_reg;
				when c_beam_thresh_9_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh9_reg;
				when c_beam_thresh_10_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh10_reg;
				when c_beam_thresh_11_addr 			=> alv_slv_reg_rd_data <= beam_trig_thresh11_reg;
				when c_lastevt_event_counter_addr		=> alv_slv_reg_rd_data <= last_evt_evt_count;		
				when c_lastevt_trig_counter_addr			=> alv_slv_reg_rd_data <= last_evt_trig_count;	
				when c_lastevt_deadtime_counter_addr	=> alv_slv_reg_rd_data <= last_evt_deadtime;	
				when c_lastevt_sincepps_counter_addr	=> alv_slv_reg_rd_data <= last_evt_clkcount;	
				when c_lastevt_pps_counter_addr			=> alv_slv_reg_rd_data <= last_evt_ppscount;	
				when c_lastevt_metamisc_1_addr			=> alv_slv_reg_rd_data <= last_evt_metamisc1;	
				when c_lastevt_metamisc_2_addr			=> alv_slv_reg_rd_data <= last_evt_metamisc2;	
				when c_lastevt_trigadr_addr				=> alv_slv_reg_rd_data <= last_evt_trig_adr;	
				when c_post_trigger_length_addr			=> alv_slv_reg_rd_data <= posttrig_ctrl_reg;	
				when c_readout_ctrl_addr					=> alv_slv_reg_rd_data <= readout_ctrl_reg;					
				when c_scaler_readout_addr			=> alv_slv_reg_rd_data <= scaler_read;			
				when c_scaler_select_addr			=> alv_slv_reg_rd_data <= scaler_sel_reg;	
                 
            when c_avl_to_sbc_mailbox_reg_addr => alv_slv_reg_rd_data <= avl_to_sbc_mailbox_reg;                                        
            when c_sbc_to_avl_mailbox_reg_addr => alv_slv_reg_rd_data <= sbc_to_avl_mailbox_reg;
                                                                                                                                                                                                                                                                                         
            when others =>
               
               alv_slv_reg_rd_data <= X"DEADBEEF"; --(others => '-');      
         end case;  

      else 
         alv_slv_reg_rd_data <= (others => '0'); -- Dont care what is output when not reading
      
      end if;   
   end if;   

end process;  

-- Its up to SW to make sure these both are not reading
adc_fifo_rd_ack    <= sbc_adc_fifo_rd_ack or avl_adc_fifo_rd_ack;

adc_0_fifo_rd_ack  <= adc_fifo_rd_ack(0);
adc_1_fifo_rd_ack  <= adc_fifo_rd_ack(1);
adc_2_fifo_rd_ack  <= adc_fifo_rd_ack(2);
adc_3_fifo_rd_ack  <= adc_fifo_rd_ack(3);
adc_4_fifo_rd_ack  <= adc_fifo_rd_ack(4);
adc_5_fifo_rd_ack  <= adc_fifo_rd_ack(5);
adc_6_fifo_rd_ack  <= adc_fifo_rd_ack(6);
adc_7_fifo_rd_ack  <= adc_fifo_rd_ack(7);
adc_8_fifo_rd_ack  <= adc_fifo_rd_ack(8);
adc_9_fifo_rd_ack  <= adc_fifo_rd_ack(9);
adc_10_fifo_rd_ack <= adc_fifo_rd_ack(10);
adc_11_fifo_rd_ack <= adc_fifo_rd_ack(11);
adc_12_fifo_rd_ack <= adc_fifo_rd_ack(12);
adc_13_fifo_rd_ack <= adc_fifo_rd_ack(13);
adc_14_fifo_rd_ack <= adc_fifo_rd_ack(14);
adc_15_fifo_rd_ack <= adc_fifo_rd_ack(15);
adc_16_fifo_rd_ack <= adc_fifo_rd_ack(16);
adc_17_fifo_rd_ack <= adc_fifo_rd_ack(17);
adc_18_fifo_rd_ack <= adc_fifo_rd_ack(18);
adc_19_fifo_rd_ack <= adc_fifo_rd_ack(19);
adc_20_fifo_rd_ack <= adc_fifo_rd_ack(20);
adc_21_fifo_rd_ack <= adc_fifo_rd_ack(21);
adc_22_fifo_rd_ack <= adc_fifo_rd_ack(22);
adc_23_fifo_rd_ack <= adc_fifo_rd_ack(23);

--
-- Watchdog function
--

process(clk,arst)
begin
   if arst = g_arst_pol then
      wdog_expired_pls  <= '0';
      wdog_short_per    <= '0'; -- start off with long period of                   
      wdog_msec_cnt     <= (others => '0');                                        

   elsif clk'event and clk = '1' then
   
      wdog_expired_pls <= '0';
      
      if (wdog_punch_pls = '1') then -- If SW punches the dog
         wdog_short_per <= '1'; -- after first pucnh change to short period
         wdog_msec_cnt  <= (others => '0');
      elsif ( ((wdog_short_per = '0') and (conv_integer('0'&wdog_msec_cnt) >= g_wdog_1st_term_ms)) or
              ((wdog_short_per = '1') and (conv_integer('0'&wdog_msec_cnt) >= g_wdog_term_ms)) ) then -- if the timer expires
         wdog_short_per <= '0'; -- start off with long period of        
         wdog_msec_cnt  <= (others => '0');                             
         wdog_expired_pls <= '1'; -- this will pulse 1 clk wide     
      elsif(tick_ms = '1') then -- no punch, not expired but time to increment       
          wdog_msec_cnt <= wdog_msec_cnt + 1;   
      end if;
       
      -- Neither of these are reset with the arst signal so will continue to work as expected during async reset      
      --if (wdog_expired_pls = '1') then
      --   wdog_sys_srst_vec <= (others => '1');
      --else
      --   wdog_sys_srst_vec <= wdog_sys_srst_vec(wdog_sys_srst_vec'left-1 downto 0)&'0'; -- left shift
      --end if;
       
   end if;
end process;


process(clk)
begin                                  

   if clk'event and clk = '1' then
      wdog_expired_pls_r <= wdog_expired_pls;
      -- Neither of these are reset with the arst signal so will continue to work as expected during async reset 
      if (wdog_expired_pls_r = '1') then                                                               
         wdog_sys_srst_vec <= (others => '1');                                                       
      else                                                                                           
         wdog_sys_srst_vec <= wdog_sys_srst_vec(wdog_sys_srst_vec'left-1 downto 0)&'0'; -- left shift
      end if;                                                                                        
   end if;
end process;   



wdog_punch_pls_dbg <= wdog_punch_pls;

wdog_sys_srst      <= wdog_sys_srst_vec(wdog_sys_srst_vec'left) and g_wdog_enb;

end rtl;



                                  