--*
--*                          RTL source file 
--*     Designed by Logic Tectonics for The University of Chicago
--*                   Copyright 2024-2025 ALL RIGHTS RESERVED
--*                  
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics          www.logic-tectonics.com 
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: Top level of a data acquisition system
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   202410xx       Logic Tectonics       Started
--*   20251111       Same                  Restarted now that board is available
--*                                        1. The first pass board supports only 12 channels
--*                                           so add generic g_support_24_channels to support
--*                                           the conditional instantiation of the second 12 channel
--*                                           and tying off signals as needed. Done
--*                                        2. Added generic for setting sample width
--*                                           can set to 8 or 9 and will propagate through the
--*                                           hierarchy to select the right files for use. Not done yet
--*                                        3. Need to completely duplicate adc spi busses.
--*                                        4. Need to add:    Done
--*                                              adc_cal_trig(1:0) output  
--*                                              adc_cal_stat(5:0) input
--*                                              adc_pll_en(1:0)   output
--*                                        5. Added the clock synth SPI port
--*                                           and its unique tristate control 
--*                                           for the shared sdio line it uses for bidir SPI data. Done
--*
--*  20251202/3      Same                   Version E2000001 For the 2nd pass board with 24 channels
--*                                        1. Added other ports - many. Done
--*                                        2. Removed obsoleted ports - many. Done
--*                                        3. Changed sysref generation to output to the ADCs. Done
--*                                           a. Use 2 PLL output to drive 3 sysrefs to each side so per side can be adjusted.
--*                                              Use DDRO to put those in DDR flops for control. Done
--*                                           b. Use 2 other PLL outputs from the same PLL to drive left and right xcvr
--*                                              cores independently.   Done.   
--*  
--*  20251204/5      Same                  Version E2000002
--*                                        1. Added missing registers for control of:
--*                                           cal_pulse_pwr_en   
--*                                           cal_switch_adc                                                           
--*                                           adc_regulator_en 
--*    
--*                                        2. Removed/disable aux qspi in PD, 
--*                                        3. Added aux_spi to normal spi controller as bus (6)
--*                                        4. Cleaned up based on new schematic and pinout.
--*
--*
--* 20260307/6      EJO/UCHICAGO       Version E2000003
--*
--*                                    Version E3000028 -- w/ beamform trigger
--*----------------------------------------------------------------------------
--*   
--*   Reference:  
--*
--*   Synthesis Considerations:
--*
--*
--*   Par Considerations:
--*
--*----------------------------------------------------------------------------

library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity artic_daq_fpga_top is
   generic(
      g_chip_rev             : std_logic_vector(31 downto 0) := X"7EA7002F";
      g_sample_width         : natural := 8;  -- Set to 8 or 9
      g_ser_debug_mult_sim   : natural := 1   -- will use faster baud rate by this factor
   );   
      
   port(
      
      pb_arst_n              : in    std_logic;                    -- Active low reset
      -- JESD/ADC Clocks     
      sysref_from_fpga_p     : out   std_logic; -- To external 1:6 buffer to create differential sysrefs one per ADC  
      sysref_from_fpga_n     : out   std_logic; -- generated from the clk_fpga2_100m                       
      
      clk_gts_pll_ref        : in    std_logic_vector(1 downto 0);  -- one on each side                                                                         
      -- FPGA Clocks  
      clk_fpga0_100m         : in    std_logic;   -- schematic clk0p/n differential, persistent 100M, used for main logic 
                                                  -- FPGA core functions that are always operational
      clk_fpga1_100m         : in    std_logic;   -- schematic clk1p/n differential, persistent 100, not used currently 
      clk_fpga2_100m         : in    std_logic;   -- schematic clk2p/n dfrom the ADC clock source for use in adc_sysref gen
                                                        
      clk_in_sel             : out   std_logic;   -- USed to select the source to the TCXO. Might not be implemented in the FPGA, just connect to a register  
	 
	                       
      rx_adc_ser_data_p      : in    std_logic_vector(23 downto 0); -- ADC0 (3:0) map to (3:0)
      rx_adc_ser_data_n      : in    std_logic_vector(23 downto 0); -- ADC1 (3:0) map to (7:4) 
                                                                    -- ...
								                                    -- ADC4 (3:0) map to (19:16)
								                                    -- ADC5 (3:0) map to (23:20)                                 
 
      -- Secondary SPI interface (not the SDM QSPI)
      aux_spi_clk            : out   std_logic;                   
      aux_spi_cs_n           : out   std_logic;                   
      aux_spi_mosi           : out   std_logic;
      aux_spi_miso           : in    std_logic;                                                           
      -- Serial Debugger port UART
      usb_uart_ser_in        : in    std_logic;         -- Note on Schematic this is TX since schem uses FTDI chip perspective
      usb_uart_ser_out       : out   std_logic;         -- Note on Schematic this is RX since schem uses FTDI chip perspective
      usb_uart_rts_n_in      : in    std_logic;         -- 
      usb_uart_cts_n_out     : out   std_logic;         -- Tied low in this module. 
     
      debug_gpio             : out    std_logic_vector(3 downto 0) := (others => '0');                            
      led_green              : out   std_logic_vector(1 downto 0); -- Active high green. LED1:0 in schematic
      led_red                : out   std_logic_vector(1 downto 0); -- Active high red. LED3:2 in schematic
                             
      i2c_data               : inout std_logic;
      i2c_clk                : inout std_logic;
  
      pll_int                : in    std_logic;   -- Interrupt from the board clock gen syth. The synth is accessed via I2C
                                                  -- Interrupt is accessible through the SBC interface
      
      -- SPI interfaces to the ADCs
      adc_spi_master_sclk    : out   std_logic_vector(5 downto 0);  -- not shared on pass 2 board shared each side of chip with 3 ADCs so only 2 needed   
      adc_spi_master_ss_n    : out   std_logic_vector(5 downto 0);  -- not shared  
      adc_spi_master_mosi    : out   std_logic_vector(5 downto 0);  -- on pass 2 board these are not shared .shared each side of chip with 3 ADCs so only 2 needed  
      adc_spi_master_miso    : in    std_logic_vector(5 downto 0);  -- not shared     
      
      -- GPIO interfaces to the ADCs
      adc_pdwn_stby          : out   std_logic_vector(5 downto 0);  
                             
      adc_cal_trig           : out   std_logic_vector(1 downto 0); -- Set to right_side:left_side = (1:0)
      adc_cal_stat           : in    std_logic_vector(5 downto 0);
      adc_pll_en             : out   std_logic_vector(1 downto 0); -- Set to right_side:left_side = (1:0) 
      adc_syncse_n           : out   std_logic_vector(1 downto 0); -- one per side. (0) = ADC(2:0), (1) = ADC(5:3)
         	
      
      cal_pulse_p            : out   std_logic;                    -- Differential
		cal_pulse_n            : out   std_logic;                    -- Differential
      cal_pulse_pwr_en       : out   std_logic;                    -- power toggle for calibration distribution amplifiers (default '0' off)
      cal_switch_adc         : out   std_logic_vector(1 downto 0); -- bit(0) = control direction of RF switches on adc0-2 input
                                                                   -- Bit(1) = control direction of RF switches on adc3-5 input
      adc_regulator_en       : out   std_logic_vector(1 downto 0); -- bit(0) = enable 1.1V and 1.9V regulators for adc0-2
                                                                   -- Bit(1) = enable 1.1V and 1.9V regulators for adc3-5
      							    									     
      fpga_aux_out           : out   std_logic ;                   -- Sent to in board SMA for trigger out.      
      fpga_aux_in            : in    std_logic;                    -- Received from on board SMA for trigger in. 
           
      sbc_one_pps            : in    std_logic;                    -- Schematic name is ext_pps_in                                                   
      sbc_uart_rxd           : in    std_logic;                    -- ext_tx_uart in schematic 
      sbc_uart_txd           : out   std_logic;                    -- ext_rx_uart in schematic                                                                      
      sbc_io_a               : in    std_logic;                    -- GPIO A 
      sbc_io_b_irq           : out   std_logic;                    -- GPIO B                                
      sbc_spi_sclk           : in    std_logic;
      sbc_spi_ss_n           : in    std_logic;
      sbc_spi_mosi           : in    std_logic;
      sbc_spi_miso           : out   std_logic   
 
   );
   
end entity artic_daq_fpga_top;    
  
architecture rtl of artic_daq_fpga_top is     

component tectonics_i2c_master_avl_intfc is
   generic(
      g_arst_pol                     : std_logic := '1';         -- default to '1' sets internal reset polarity            
      g_input_clk_hz                 : integer   := 100_000_000; -- used by the I2C module to set the bit rate                                
      g_i2c_bus_clk_hz               : integer   := 400_000      -- used by the I2C module to set the bit rate
      --g_rd_stp_strt                  : boolean   := false      -- If true then insert real stop start in between 
      --                                                         -- reg address and read data phases versus just a start.
                                                                 -- Some devices require this
      
   );

   port(
      
      -- Clock and reset
      arst                     : in   std_logic;  -- Module async reset
      clk                      : in   std_logic;  -- Module memory bus interface clock
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            : out  std_logic;          
      avl_slave_waitrequest    : out  std_logic;        
      avl_slave_address        : in   std_logic_vector(7 downto 0);  
      avl_slave_chipselect     : in   std_logic;
      avl_slave_write          : in   std_logic;
      avl_slave_writedata      : in   std_logic_vector(31 downto 0);  
      avl_slave_read           : in   std_logic;
      avl_slave_readdata       : out  std_logic_vector(31 downto 0);
      avl_slave_readdatavalid  : out  std_logic;
                                                                            
      
      -- I2C pin interface
      i2c_data_oe              : out  std_logic;
      i2c_clk_oe               : out  std_logic;
                                 
      i2c_data_in              : in   std_logic;
      i2c_clk_in               : in   std_logic      
      
   );

end component tectonics_i2c_master_avl_intfc;

component tectonics_spi_master_avl_intfc is
   generic(
      g_arst_pol                     : std_logic := '1';         -- default to '1' sets internal reset polarity            
      g_delay_miso_samp_val          : natural range 0 to 2 := 0 -- Shift samp MISO point by this many extra clocks, 1 or 2
                                                                 -- For very slow devices.
      
   );

   port(
      
      -- Clock and reset
      arst                     : in   std_logic;  -- Module async reset                                                                             
      clk                      : in   std_logic;  -- Module memory bus interface clock
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            : out  std_logic;  
      avl_slave_waitrequest    : out  std_logic;                
      avl_slave_address        : in   std_logic_vector(7 downto 0); -- 32-bit word address 
      avl_slave_chipselect     : in   std_logic;
      avl_slave_write          : in   std_logic;
      avl_slave_writedata      : in   std_logic_vector(31 downto 0);  
      avl_slave_read           : in   std_logic;
      avl_slave_readdata       : out  std_logic_vector(31 downto 0);
      avl_slave_readdatavalid  : out  std_logic;
                                                                            
      
      -- SPI pin interface
      -- SPI interface
      spi_sclk                 : out std_logic;
      spi_ss_n                 : out std_logic;
      spi_mosi                 : out std_logic;
      spi_miso                 : in  std_logic                 
      
   );

end component tectonics_spi_master_avl_intfc;

component spi_slave_reg_intfc is
   generic(
      g_arst_pol                   : std_logic := '1';  -- default to '1' sets internal reset polarity
      g_spi_frame_len              : positive  := 48;   -- set to 32 for 7  bit address, 24 bit data
                                                        -- set to 40 for 7  bit address, 32 bit data
                                                        -- set to 48 for 15 bit address, 32 bit data 
                                                        
      g_irq_pol                    : std_logic := '1';  -- '1' means active high for interrupt line
      g_chip_rev                   : std_logic_vector(31 downto 0)  
      
   );

   port(
      
      -- Clock and reset
      arst                               : in   std_logic;  -- Module async reset
      clk                                : in   std_logic;  -- 125MHz Module clock, it is assumed that this clock is at least 4x the reg_sclk to make the SPI timing work     
      clk_wide                           : in   std_logic;  -- 250MHz wide data clock if needed.                                   
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
      
      -- Nios/Avalon interface
      alv_slv_reg_chipselect             : in   std_logic;  
      alv_slv_reg_waitrequest            : out  std_logic;     
      alv_slv_reg_addr                   : in   std_logic_vector(14 downto 0); -- 32-bit Word address address for this module                   
      alv_slv_reg_rd_req                 : in   std_logic;                    
      alv_slv_reg_rd_data_valid          : out  std_logic;                    
      alv_slv_reg_rd_data                : out  std_logic_vector(31 downto 0);       
      alv_slv_reg_wr_req                 : in   std_logic;                                                                       
      alv_slv_reg_wr_data                : in   std_logic_vector(31 downto 0);
      
      -- Nios/Avalon master interface lets this module (i.e. ultimately the SBC) 
      -- access anything in the pd memory map
      -- including the SPI master and I2C masters. Single 32 bit accesses only
      alv_mst_waitrequest                : in   std_logic;     
      alv_mst_addr                       : out  std_logic_vector(31 downto 0); -- 32-bit Word address address for this module                    
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
      jesd_if_out_fifo_rst_n             : out std_logic;   -- shared with low and high                 
                                                                                                        
      jesd_if_low_rx_rst_n               : out std_logic_vector(5 downto 0);                            
      jesd_if_low_rx_rst_ack_n           : in  std_logic_vector(5 downto 0);                            
      jesd_if_low_rx_out_of_reset        : in  std_logic_vector(5 downto 0);                            
                                                                                                        
      jesd_if_high_rx_rst_n              : out std_logic_vector(5 downto 0);                            
      jesd_if_high_rx_rst_ack_n          : in  std_logic_vector(5 downto 0);                            
      jesd_if_high_rx_out_of_reset       : in  std_logic_vector(5 downto 0);                            
                                                                                                        
      jesd_if_low_loopback_enb           : out std_logic_vector(5 downto 0);                            
      jesd_if_high_loopback_enb          : out std_logic_vector(5 downto 0);                            
                                                                                                        
      jesd_if_avs_sel                    : out std_logic_vector(2 downto 0);   -- shared with low and high
      jesd_if_low_adc_dlckd              : in  std_logic_vector(11 downto 0);  -- todo: Domain?         
      jesd_if_high_adc_dlckd             : in  std_logic_vector(11 downto 0);  -- todo: Domain?                          
                               
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
                                                                                   
      capture_ctrl           : out std_logic_vector(31 downto 0);      
      capture_stat           : in  std_logic_vector(31 downto 0); 
      trigger_ctrl1				: out std_logic_vector(31 downto 0);  
		trigger_ctrl2				: out std_logic_vector(31 downto 0);   
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
		beam_trig_thresh0		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh1		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh2		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh3		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh4		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh5		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh6		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh7		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh8		: out   std_logic_vector(31 downto 0);
		beam_trig_thresh9		: out   std_logic_vector(31 downto 0);
		last_evt_evt_count		: in  std_logic_vector(31 downto 0);      
		last_evt_trig_count		: in  std_logic_vector(31 downto 0);      
		last_evt_deadtime		: in  std_logic_vector(31 downto 0);     
		last_evt_clkcount		: in  std_logic_vector(31 downto 0);      
		last_evt_ppscount		: in  std_logic_vector(31 downto 0);    
		last_evt_metamisc1		: in  std_logic_vector(31 downto 0);     
		last_evt_metamisc2		: in  std_logic_vector(31 downto 0);      
		last_evt_trig_adr		: in  std_logic_vector(31 downto 0);     
		--scalers (on clk_rd)
		scaler_sel				: out   std_logic_vector(31 downto 0);
		scaler_read				: in	 std_logic_vector(31 downto 0); 
      
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
                                                                                                                         
end component;  


component niosv_pd is
    port (                                                                              
        reset_reset_n                                          : in  std_logic;         
        clk_clk                                                : in  std_logic;         

        pd_debug_uart_txd                                      : out std_logic;                                         
        pd_debug_uart_rxd                                      : in  std_logic;       
        
        --qspi_flash_dclk                                        : out   std_logic;                  
        --qspi_flash_ncs                                         : out   std_logic;                  
        --qspi_flash_data                                        : inout std_logic_vector(3 downto 0);
                      
        i2c_master_0_avl_mm_address                            : out std_logic_vector(7 downto 0);                      
        i2c_master_0_avl_mm_chipselect                         : out std_logic;                                         
        i2c_master_0_avl_mm_write                              : out std_logic;                                         
        i2c_master_0_avl_mm_waitrequest                        : in  std_logic;             
        i2c_master_0_avl_mm_writedata                          : out std_logic_vector(31 downto 0);                     
        i2c_master_0_avl_mm_read                               : out std_logic;                                         
        i2c_master_0_avl_mm_readdata                           : in  std_logic_vector(31 downto 0); 
        i2c_master_0_avl_mm_readdatavalid                      : in  std_logic;             
        i2c_master_0_avl_reset_reset                           : out std_logic;                                         
        
        ser_debug_master_address                               : in  std_logic_vector(31 downto 0);
        ser_debug_master_waitrequest                           : out std_logic;                                       
        ser_debug_master_write                                 : in  std_logic;            
        ser_debug_master_writedata                             : in  std_logic_vector(31 downto 0);
        ser_debug_master_read                                  : in  std_logic;            
        ser_debug_master_readdata                              : out std_logic_vector(31 downto 0);                   
        ser_debug_master_readdatavalid                         : out std_logic;                                       
        ser_debug_master_byteenable                            : in  std_logic_vector(3 downto 0);
        ser_debug_master_reset_reset                           : out std_logic;                                       
                                                                                                                                     
        spi_master_0_avl_mm_address                            : out std_logic_vector(7 downto 0);                  
        spi_master_0_avl_mm_chipselect                         : out std_logic;                                     
        spi_master_0_avl_mm_write                              : out std_logic;                                     
        spi_master_0_avl_mm_waitrequest                        : in  std_logic ;
        spi_master_0_avl_mm_writedata                          : out std_logic_vector(31 downto 0);                 
        spi_master_0_avl_mm_read                               : out std_logic;                                     
        spi_master_0_avl_mm_readdata                           : in  std_logic_vector(31 downto 0);
        spi_master_0_avl_mm_readdatavalid                      : in  std_logic;
        spi_master_0_avl_reset_reset                           : out std_logic;
        
        avalon_spi_slave_address                               : out std_logic_vector(14 downto 0);                    
        avalon_spi_slave_chipselect                            : out std_logic;                                        
        avalon_spi_slave_waitrequest                           : in  std_logic;             
        avalon_spi_slave_write                                 : out std_logic;                                        
        avalon_spi_slave_writedata                             : out std_logic_vector(31 downto 0);                    
        avalon_spi_slave_read                                  : out std_logic;                                        
        avalon_spi_slave_readdata                              : in  std_logic_vector(31 downto 0); 
        avalon_spi_slave_readdatavalid                         : in  std_logic;             
        avalon_spi_slave_reset_reset                           : out std_logic;                                        
        avalon_spi_slave_irq_irq                               : in  std_logic;     
        
        avl_mst_sbc_address                                    : in  std_logic_vector(31 downto 0); 
        avl_mst_sbc_waitrequest                                : out std_logic;                    
        avl_mst_sbc_write                                      : in  std_logic;                     
        avl_mst_sbc_writedata                                  : in  std_logic_vector(31 downto 0); 
        avl_mst_sbc_read                                       : in  std_logic;                     
        avl_mst_sbc_readdata                                   : out std_logic_vector(31 downto 0);
        avl_mst_sbc_readdatavalid                              : out std_logic;                    
        avl_mst_sb_reset_reset                                 : out std_logic;                                    
     
        jesd_low_slave_address                                 : out std_logic_vector(9 downto 0); 
        jesd_low_slave_chipselect                              : out std_logic;                    
        jesd_low_slave_read                                    : out std_logic;                    
        jesd_low_slave_readdata                                : in  std_logic_vector(31 downto 0);
        jesd_low_slave_waitrequest                             : in  std_logic;                    
        jesd_low_slave_write                                   : out std_logic;                    
        jesd_low_slave_writedata                               : out std_logic_vector(31 downto 0);
        jesd_low_slave_reset_reset_n                           : out std_logic;                    
                                                              
        jesd_high_slave_address                                : out std_logic_vector(9 downto 0); 
        jesd_high_slave_chipselect                             : out std_logic;                    
        jesd_high_slave_read                                   : out std_logic;                    
        jesd_high_slave_readdata                               : in  std_logic_vector(31 downto 0); 
        jesd_high_slave_waitrequest                            : in  std_logic;             
        jesd_high_slave_write                                  : out std_logic;                                        
        jesd_high_slave_writedata                              : out std_logic_vector(31 downto 0);                    
        jesd_high_slave_reset_reset_n                          : out std_logic                                        

    );
end component niosv_pd;

component pll_sysref_fabric is
    port (
        refclk   : in  std_logic;  -- 100M
        locked   : out std_logic; 
        rst      : in  std_logic; 
        outclk_0 : out std_logic;  -- 250M [line rate / 40 for jesd204b]
        outclk_1 : out std_logic;  -- sysref
        outclk_2 : out std_logic   -- sysref     
      
    );
end component pll_sysref_fabric;

component main_pll is    
   port (
       refclk   : in  std_logic;   -- 100M
       locked   : out std_logic; 
       rst      : in  std_logic; 
       outclk_0 : out std_logic;   -- 125M
       outclk_1 : out std_logic;  -- dataclk (250MHz at 1GSPS, etc)
		 outclk_2 : out std_logic); -- clock for trigger logic (dataclk/2)
end component main_pll;

component jesd_12_chan_if is

   port(
      
      --arstn                      : in   std_logic;                    -- Chip async reset active low.
      clk_sysref                 : in   std_logic_vector(2 downto 0);   -- 62.5MHz, one per bank, there are two XCVRs per JESD module
                                                                        -- two jesd module per bank      
      clk_gts_pll_ref            : in   std_logic_vector(2 downto 0);   -- 125 MHz reference to the transceiver PLLs, one per bank                   
                                                                        
      clk_link_lane              : in   std_logic;                      -- 250 MHz lane and link clock. Can use the same since the same rate
      clk_avs                    : in   std_logic;                      -- 125MHz clock for the avalon interface
                                                                        
      clk_wide                   : in   std_logic;                      -- The data will be pushed out at this rate which will also be              
                                                                        -- 250MHz but its a common 250M for the downstream buffers                  
                                                                        -- which need to capture data for all 24 ADC not just the 12 in this module  
                                                                        -- its called out seprate in the event a second pll is required for         
                                                                        -- each jesd 12 module.                                                     
      
      out_fifo_rst_n             : in   std_logic;                      -- The FIFO will sychronize this as needed
                                                                        -- so this can be in any domain but use clk_avs 
                                                                        -- preferred and assert for at least 2 clk_avs.
                                                                        -- Assertion will flush the FIFO.
		sync_adc_n						: out	std_logic_vector(2 downto 0);
                                                                                                   
      rx_rst_n                   : in  std_logic_vector(5 downto 0);    -- domain for these?, async reset?                                      
      rx_rst_ack_n               : out std_logic_vector(5 downto 0);    -- domain for these?                                                                                               
      rx_out_of_reset            : out std_logic_vector(5 downto 0);    -- domain for these?                                           
                                                                                                                                     
      rx_adc_ser_data_p          : in  std_logic_vector(11 downto 0);   -- Serial lanes from ADC.                                                             
      rx_adc_ser_data_n          : in  std_logic_vector(11 downto 0);   -- Serial lanes from ADC 
                                                                        -- Expected mapping (for 3 ADC chips each with 4 ADCs):
                                                                        -- (0)  = ADC Chip(N)   channel A
                                                                        -- (1)  = ADC Chip(N)   channel B
                                                                        -- (2)  = ADC Chip(N)   channel C
                                                                        -- (3)  = ADC Chip(N)   channel D
                                                                        --                   ...
                                                                        -- (8)  = ADC Chip(N+2) channel A
                                                                        -- (9)  = ADC Chip(N+2) channel B
                                                                        -- (10) = ADC Chip(N+2) channel C
                                                                        -- (11) = ADC Chip(N+2) channel D                                                                                                                                               
                                                                        
      loopback_enb               : in  std_logic_vector(5 downto 0);    -- possibly hook up
                                                                      
      avs_rst_n                  : in  std_logic; 
      avs_select                 : in  std_logic_vector(2 downto 0);    -- Set to select which core is to be addressed. Set before addressing
      avs_chipselect             : in  std_logic;                     
      avs_address                : in  std_logic_vector(9 downto 0); 
      avs_read                   : in  std_logic;                     
      avs_readdata               : out std_logic_vector(31 downto 0);
      avs_waitrequest            : out std_logic;                    
      avs_write                  : in  std_logic;                     
      avs_writedata              : in  std_logic_vector(31 downto 0); 
       
      dev_lanes_aligned_from_ext : in  std_logic;
      dev_lanes_aligned_to_ext   : out std_logic;
                                                                  
      adc_lane_locked_to_data    : out std_logic_vector(11 downto 0);  -- todo: Domain?     
                                                                
      adc_0_wide_data            : out std_logic_vector(31 downto 0); -- The data format is big endian, where the              
      adc_0_wide_data_valid      : out std_logic;                     -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                                      -- octet/sample is placed in bit [7:0].                                                                                                                          
      adc_1_wide_data            : out std_logic_vector(31 downto 0);                                                        
      adc_1_wide_data_valid      : out std_logic;                                                                                                  
                                 
      adc_2_wide_data            : out std_logic_vector(31 downto 0);  
      adc_2_wide_data_valid      : out std_logic;                                                                                                  
                                 
      adc_3_wide_data            : out std_logic_vector(31 downto 0);  
      adc_3_wide_data_valid      : out std_logic;                                                                                               
                                                                         
      adc_4_wide_data            : out std_logic_vector(31 downto 0);  
      adc_4_wide_data_valid      : out std_logic;                                                                                                                                                                        
                                                                                    
      adc_5_wide_data            : out std_logic_vector(31 downto 0);  
      adc_5_wide_data_valid      : out std_logic;                                                                                                   
                                 
      adc_6_wide_data            : out std_logic_vector(31 downto 0);  
      adc_6_wide_data_valid      : out std_logic;                                                                                                    
                                 
      adc_7_wide_data            : out std_logic_vector(31 downto 0);  
      adc_7_wide_data_valid      : out std_logic;                                                                                          
                                                                        
      adc_8_wide_data            : out std_logic_vector(31 downto 0);  
      adc_8_wide_data_valid      : out std_logic;                                                                                                                                                                    
                                                                                    
      adc_9_wide_data            : out std_logic_vector(31 downto 0);  
      adc_9_wide_data_valid      : out std_logic;                                                                                                
                                 
      adc_10_wide_data           : out std_logic_vector(31 downto 0);  
      adc_10_wide_data_valid     : out std_logic;                                                                                                 
                                 
      adc_11_wide_data           : out std_logic_vector(31 downto 0);  
      adc_11_wide_data_valid     : out std_logic                                                                                             
                   
   );
   
end component jesd_12_chan_if;  

component tectonics_ser_debug is
   generic(
   
      g_arst_pol           : std_logic := '1';                                            -- default to '1' being te polarity of arst input
      g_ser_rate           : std_logic_vector(8 downto 0) := conv_std_logic_vector(2,9);   -- 115.2k, 1 for 230.4k 
      g_ser_debug_mult_sim : natural := 1 -- will use faster baud rate by this factor
   );   
      
   port(
   
      arst                         : in   std_logic;  --  Async reset, polarity set by arst_pol
      clk                          : in   std_logic;  --  Clk. Pos edge active. 
      
      -- Interface to the Avalon fabfic for writing as master device     
                                                            
      avl_mstr_port_waitrequest    : in   std_logic;                    
      avl_mstr_port_byteenable     : out  std_logic_vector(3 downto 0); 
      avl_mstr_port_writedata      : out  std_logic_vector(31 downto 0);
      avl_mstr_port_address        : out  std_logic_vector(31 downto 0); -- This is a byte address
      avl_mstr_port_write          : out  std_logic;                    
      avl_mstr_port_read           : out  std_logic;                    
      avl_mstr_port_readdata       : in   std_logic_vector(31 downto 0);
      avl_mstr_port_readdatavalid  : in   std_logic;                     
                                                                                                                 
      -- The serial interface                                                                                                             
      ser_tx                       : out  std_logic;  -- Serial transmit line used to receive commands from the outside world
      ser_rx                       : in   std_logic   -- Serial receive line used to send responses to the outside world          
                                                           
   );                                                       
end component tectonics_ser_debug;      

component didaq_acq_and_trig is

   port(
      
		arstn                      : in   std_logic;                      -- Chip async reset active low.
      clk_wr                     : in   std_logic;                      -- The data will be pushed in at this rate which will also be 
      clk_rd                     : in   std_logic;                      -- 125MHz clock for the avalon interface                                                                                                                                               
      clk_trig							: in	 std_logic;
      -- Data form the JESD link
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
		event_ready_o					: out	 std_logic;
		pps_i								: in	 std_logic;
		ext_trig_i						: in   std_logic);                                                                                                                                 
end component didaq_acq_and_trig;  

--
-- This compnent is needdinagilex to insure the
-- that the FPGA will exit initialization properly.
--
component reset_release is
 port (
    ninit_done : out std_logic 
 );
end component reset_release;


component ddro_1w is
   port (
   	  ck        : in  std_logic;            
   	  datain_h  : in  std_logic_vector(0 downto 0);
   	  datain_l  : in  std_logic_vector(0 downto 0);
   	  dataout   : out std_logic_vector(0 downto 0);
   	  pad_out_b : out std_logic_vector(0 downto 0)                    
   );
end component ddro_1w;
--------------------------------------------------------------------------------
-- signals
signal all_zeros                        : std_logic_vector(31 downto 0);
                                        
signal tick_us                          : std_logic; 
signal tick_ms                          : std_logic; 
signal tick_sec                         : std_logic; 
                                        
signal clk_125m                         : std_logic;
signal clk_250m                         : std_logic;
signal clk_data                    		: std_logic;
signal clk_trig	                    	: std_logic;

signal ser_debug_master_address         : std_logic_vector(31 downto 0);
signal ser_debug_master_waitrequest     : std_logic;                    
signal ser_debug_master_write           : std_logic;                    
signal ser_debug_master_writedata       : std_logic_vector(31 downto 0);
signal ser_debug_master_read            : std_logic;                    
signal ser_debug_master_readdata        : std_logic_vector(31 downto 0);
signal ser_debug_master_readdatavalid   : std_logic;                    
signal ser_debug_master_byteenable      : std_logic_vector(3 downto 0); 
signal ser_debug_master_reset_reset     : std_logic;                    
                                        
signal i2c_master_avl_reset_reset       : std_logic;    
signal i2c_master_avl_address           : std_logic_vector(7 downto 0);                     
signal i2c_master_avl_chipselect        : std_logic;                                        
signal i2c_master_avl_write             : std_logic;                                        
signal i2c_master_avl_waitrequest       : std_logic;            
signal i2c_master_avl_writedata         : std_logic_vector(31 downto 0);                    
signal i2c_master_avl_read              : std_logic;                                        
signal i2c_master_avl_readdata          : std_logic_vector(31 downto 0);
signal i2c_master_avl_readdatavalid     : std_logic;            
                                        
signal adc_spi_master_avl_reset_reset   : std_logic; 
signal adc_spi_master_avl_address       : std_logic_vector(7 downto 0);                     
signal adc_spi_master_avl_chipselect    : std_logic;                                        
signal adc_spi_master_avl_write         : std_logic;                                        
signal adc_spi_master_avl_waitrequest   : std_logic;            
signal adc_spi_master_avl_writedata     : std_logic_vector(31 downto 0);                    
signal adc_spi_master_avl_read          : std_logic;                                        
signal adc_spi_master_avl_readdata      : std_logic_vector(31 downto 0);
signal adc_spi_master_avl_readdatavalid : std_logic;            
                                        
signal i2c_data_oe                      : std_logic;
signal i2c_clk_oe                       : std_logic;
                                        
signal spi_slave_avl_address            : std_logic_vector(14 downto 0);        
signal spi_slave_avl_chipselect         : std_logic;                            
signal spi_slave_avl_waitrequest        : std_logic; 
signal spi_slave_avl_write              : std_logic;                            
signal spi_slave_avl_writedata          : std_logic_vector(31 downto 0);        
signal spi_slave_avl_read               : std_logic;                            
signal spi_slave_avl_readdata           : std_logic_vector(31 downto 0);
signal spi_slave_avl_readdatavalid      : std_logic; 
signal spi_slave_avl_reset_reset        : std_logic; 

signal sbc_avl_mst_address              : std_logic_vector(31 downto 0); 
signal sbc_avl_mst_waitrequest          : std_logic;                     
signal sbc_avl_mst_write                : std_logic;                     
signal sbc_avl_mst_writedata            : std_logic_vector(31 downto 0); 
signal sbc_avl_mst_read                 : std_logic;                     
signal sbc_avl_mst_readdata             : std_logic_vector(31 downto 0); 
signal sbc_avl_mst_readdatavalid        : std_logic;                     
signal sbc_avl_mst_reset                : std_logic;                     

signal adc_data_buffer_rstn             : std_logic;                                                                   
                                       
signal pll_sysref_fabric_locked         : std_logic; 
--signal io_pll_sysref_reset              : std_logic;

signal main_pll_locked                  : std_logic; 
signal main_pll_reset                   : std_logic; 

signal sys_reset_n_pipe                 : std_logic_vector(31 downto 0);
signal sys_reset_n                      : std_logic;

                                        
signal clk_link_lane_low                : std_logic;
signal clk_link_lane_high               : std_logic;
signal clk_wide                         : std_logic;
signal clk_avl                          : std_logic;

signal jesd_if_low_slave_address        : std_logic_vector(9 downto 0); 
signal jesd_if_low_slave_chipselect     : std_logic;                    
signal jesd_if_low_slave_read           : std_logic;                    
signal jesd_if_low_slave_readdata       : std_logic_vector(31 downto 0);
signal jesd_if_low_slave_waitrequest    : std_logic;                    
signal jesd_if_low_slave_write          : std_logic;                    
signal jesd_if_low_slave_writedata      : std_logic_vector(31 downto 0);
signal jesd_if_low_slave_reset_reset_n  : std_logic;                    
                                        
signal jesd_if_high_slave_address       : std_logic_vector(9 downto 0); 
signal jesd_if_high_slave_chipselect    : std_logic;                    
signal jesd_if_high_slave_read          : std_logic;                    
signal jesd_if_high_slave_readdata      : std_logic_vector(31 downto 0);
signal jesd_if_high_slave_waitrequest   : std_logic;             
signal jesd_if_high_slave_write         : std_logic;                    
signal jesd_if_high_slave_writedata     : std_logic_vector(31 downto 0);
signal jesd_if_high_slave_reset_reset_n : std_logic;                     

                                               
signal jesd_if_low_dev_lanes_aligned    : std_logic;    
signal jesd_if_high_dev_lanes_aligned   : std_logic;    

type adc_wide_data_type                 is array (0 to 23) of std_logic_vector(31 downto 0);
signal adc_wide_data                    : adc_wide_data_type;     
signal adc_wide_data_valid              : std_logic_vector(23 downto 0);

signal adc_fifo_data                   : adc_wide_data_type;
signal adc_fifo_rd_ack                 : std_logic_vector(23 downto 0);

type threshold_array_data_type          is array (0 to 11) of std_logic_vector(31 downto 0);

signal capture_ctrl_reg          : std_logic_vector(31 downto 0);      
signal capture_stat_reg          :  std_logic_vector(31 downto 0); 
signal trigger_ctrl1_reg			:  std_logic_vector(31 downto 0);  
signal trigger_ctrl2_reg			:  std_logic_vector(31 downto 0);   
signal ptrigger_ctrl_reg			:  std_logic_vector(31 downto 0); 
signal readout_ctrl_reg				:  std_logic_vector(31 downto 0); 
signal posttrig_ctrl_reg			:  std_logic_vector(31 downto 0); 
signal coinc_trigger_thresh_regs : threshold_array_data_type; 
signal beam_trig_thresh_regs		: threshold_array_data_type;     
signal last_evt_trig_count_reg	: std_logic_vector(31 downto 0);      
signal last_evt_deadtime_reg		: std_logic_vector(31 downto 0);     
signal last_evt_clkcount_reg		: std_logic_vector(31 downto 0);      
signal last_evt_ppscount_reg		: std_logic_vector(31 downto 0);    
signal last_evt_metamisc1_reg		: std_logic_vector(31 downto 0);     
signal last_evt_metamisc2_reg		: std_logic_vector(31 downto 0);      
signal last_evt_trig_adr_reg		: std_logic_vector(31 downto 0);     
signal scaler_sel_reg				: std_logic_vector(31 downto 0);
signal scaler_read_reg				: std_logic_vector(31 downto 0); 

-- todo: get from register file in spi slave            
--       SPI slave needs to source all registers        
--       runtime registers but nios can overwite as need
signal out_fifo_rst_n                       : std_logic; 
signal jesd_if_out_fifo_rst_n               : std_logic;   -- shared with low and high                         
                                                                                                               
signal jesd_if_low_rx_rst_n                 : std_logic_vector(5 downto 0);
signal jesd_if_low_rx_rst_ack_n             : std_logic_vector(5 downto 0);                                                     
signal jesd_if_low_rx_out_of_reset          : std_logic_vector(5 downto 0);
                                            
signal jesd_if_high_rx_rst_n                : std_logic_vector(5 downto 0); 
signal jesd_if_high_rx_rst_ack_n            : std_logic_vector(5 downto 0); 
signal jesd_if_high_rx_out_of_reset         : std_logic_vector(5 downto 0); 
                                            
signal jesd_if_low_loopback_enb             : std_logic_vector(5 downto 0);
signal jesd_if_high_loopback_enb            : std_logic_vector(5 downto 0);
                                            
signal jesd_if_avs_sel                      : std_logic_vector(2 downto 0);   -- shared with low and high 
signal jesd_if_low_adc_lane_locked_to_data  : std_logic_vector(11 downto 0);  -- todo: Domain? 
signal jesd_if_high_adc_lane_locked_to_data : std_logic_vector(11 downto 0);                                      
                                 
signal leds_from_reg                        : std_logic_vector(7 downto 0);                                                        

  
signal capture_ctrl                         : std_logic_vector(31 downto 0);
signal capture_stat                         : std_logic_vector(31 downto 0);
signal adc_spi_sel                          : std_logic_vector(2 downto 0);
signal sync_adc_low_n							  : std_logic_vector(2 downto 0);
signal sync_adc_high_n							  : std_logic_vector(2 downto 0);

signal adc_spi_master_miso_core             : std_logic;
signal adc_spi_master_ss_n_core             : std_logic;
                                            
signal adc_spi_master_sclk_core             : std_logic; 
signal adc_spi_master_mosi_core             : std_logic; 

signal irq                                  : std_logic;
signal irq_to_nios                          : std_logic; 
signal irq_events                           : std_logic_vector(3 downto 0);
signal ninit_done                           : std_logic;

signal clk_sysref_for_adc                   : std_logic;
signal clk_sysref_for_fabric                : std_logic;
signal clk_gts_sysref                       : std_logic_vector(5 downto 0);

signal ser_tx_core                          : std_logic;
signal ser_rx_core                          : std_logic;

signal clk_100m_init_delay_cnt              : std_logic_vector(7 downto 0);
signal clk_100m_init_delay_cnt_done         : std_logic;

signal clk_100m_cnt                         : std_logic_vector(25 downto 0) := (others => '0'); -- preinit just for sim of free running count
signal clk1_100m_cnt                        : std_logic_vector(25 downto 0) := (others => '0'); -- preinit just for sim of free running count

begin -- rtl

all_zeros <= (others => '0');

usb_uart_cts_n_out <= '0'; -- No need for flow control

fpga_aux_out <= fpga_aux_in; -- for now
 
debug_gpio(0) <=  '0';
debug_gpio(1) <=  main_pll_locked;
debug_gpio(2) <=  '0'; --'1',--usb_uart_ser_out;
debug_gpio(3) <=  pll_sysref_fabric_locked;

adc_syncse_n(0) <= sync_adc_low_n(0) and sync_adc_low_n(1) and sync_adc_low_n(2);
adc_syncse_n(1) <= sync_adc_high_n(0) and sync_adc_high_n(1) and sync_adc_high_n(2);
 
irq_events <= "000"&pll_int; -- for now
--
-- Core PLL currently generates the link clocks
-- Main PLL creates the general clocks
--
inst_reset_release : reset_release
 port map(
    ninit_done => ninit_done -- acts like an active high reset
 );

 
main_pll_reset <= ninit_done;   
    
inst_main_pll_1 : main_pll        
   port map(  
       rst      => main_pll_reset,                                        
       refclk   => clk_fpga0_100m,   -- 100M persistent clock       
       locked   => main_pll_locked,
       
       outclk_0 => clk_125m,   -- 125M
       outclk_1 => clk_data,    -- 250
		 outclk_2 => clk_trig   --clk_data/2
   );
        
clk_avl     <= clk_125m; -- To logic needed to be running independent of the ADC clock tree
clk_wide    <= clk_data; -- To logic needed to be running independent of the ADC clock tree

--
-- Generate a locked clock to send to the sysref clock buffer/replicator 
-- external to the FPGA to create a sysref for each ADC 
-- 
--
inst_pll_sysref_fabric : pll_sysref_fabric 
    port map(
        rst      => ninit_done,
        refclk   => clk_fpga2_100m,            -- 100M ADC reference, not persistent
        locked   => pll_sysref_fabric_locked, 
        outclk_0 => clk_250m,                 -- 250M for link/lane clock in xcvr IP // 
        outclk_1 => clk_sysref_for_adc,       -- 3.125MHz
        outclk_2 => clk_sysref_for_fabric     -- 3.125MHz to secondary pll or diriect to create the adjustable 
                                              -- sysrefs to the xcvr modules. On per ADC 
             
    ); 

--
-- Clock copier DDR FLOP just for allowing for repeatable timing
-- when routed. So timing consistent at output pin
-- relative to clock tree
--    
inst_ddro_1w : ddro_1w
   port map(
   	  ck           => clk_sysref_for_adc,          
   	  datain_h(0)  => '1', --'1',
   	  datain_l(0)  => '0',
   	  dataout(0)   => sysref_from_fpga_p, -- to pins on the chip
   	  pad_out_b(0) => sysref_from_fpga_n  -- to pins on the chip                 
   );
inst_ddro_cal_pulse : ddro_1w
   port map(
   	  ck           => clk_sysref_for_adc,          
   	  datain_h(0)  => '1', --'1',
   	  datain_l(0)  => '0',
   	  dataout(0)   => cal_pulse_p, -- to pins on the chip
   	  pad_out_b(0) => cal_pulse_n  -- to pins on the chip                 
   );
        
-- Solution #3, adjust the phase of the clk_sysref_for_fabric 
clk_gts_sysref(0) <= clk_sysref_for_fabric;
clk_gts_sysref(1) <= clk_sysref_for_fabric;
clk_gts_sysref(2) <= clk_sysref_for_fabric;
clk_gts_sysref(3) <= clk_sysref_for_fabric;
clk_gts_sysref(4) <= clk_sysref_for_fabric;
clk_gts_sysref(5) <= clk_sysref_for_fabric;
--------
clk_link_lane_low  <= clk_250m; 
clk_link_lane_high <= clk_250m;

--
-- Create nice stretched reset with known deassertion
-- that can be initiated with a board reset or PLL loss of lock.
--
process(clk_avl,main_pll_locked, pb_arst_n)
begin
   if main_pll_locked = '0' or pb_arst_n = '0' then 
      sys_reset_n_pipe <= (others => '0');
   elsif clk_avl'event and clk_avl = '1' then
      sys_reset_n_pipe <= sys_reset_n_pipe(sys_reset_n_pipe'left-1 downto 0) & '1';
   end if;
end process;

sys_reset_n <= sys_reset_n_pipe(sys_reset_n_pipe'left);
-- 
-- For heartbeat LED get right from the 100M always present input for pass one boards
-- no reset, jus clocked.
--  
process(clk_fpga0_100m)
begin
   if clk_fpga0_100m'event and clk_fpga0_100m = '1' then
      clk_100m_cnt <= clk_100m_cnt + 1;
   end if;
end process; 
   

led_green(0) <= clk_100m_cnt(clk_100m_cnt'left) and pll_sysref_fabric_locked;
led_green(1) <= clk_100m_cnt(clk_100m_cnt'left-1) and main_pll_locked;  
led_red(0) <= clk_100m_cnt(clk_100m_cnt'left) and main_pll_locked;
led_red(1) <= sbc_one_pps; --leds_from_reg(3); 
 
inst_nios_pd : niosv_pd
    port map(
        reset_reset_n                                          => sys_reset_n,
        clk_clk                                                => clk_avl,
        
        pd_debug_uart_txd                                      => sbc_uart_txd,
        pd_debug_uart_rxd                                      => sbc_uart_rxd, 
        
        --qspi_flash_dclk                                        => aux_qspi_flash_dclk,   
        --qspi_flash_ncs                                         => aux_qspi_flash_ncs, 
        --qspi_flash_data                                        => aux_qspi_flash_data,
               
        ser_debug_master_reset_reset                           => ser_debug_master_reset_reset,
        ser_debug_master_address                               => ser_debug_master_address,      
        ser_debug_master_waitrequest                           => ser_debug_master_waitrequest,  
        ser_debug_master_write                                 => ser_debug_master_write,        
        ser_debug_master_writedata                             => ser_debug_master_writedata,    
        ser_debug_master_read                                  => ser_debug_master_read,         
        ser_debug_master_readdata                              => ser_debug_master_readdata,     
        ser_debug_master_readdatavalid                         => ser_debug_master_readdatavalid,
        ser_debug_master_byteenable                            => ser_debug_master_byteenable,           
        
        i2c_master_0_avl_reset_reset                           => i2c_master_avl_reset_reset,
        i2c_master_0_avl_mm_address                            => i2c_master_avl_address,      
        i2c_master_0_avl_mm_chipselect                         => i2c_master_avl_chipselect,   
        i2c_master_0_avl_mm_write                              => i2c_master_avl_write,        
        i2c_master_0_avl_mm_waitrequest                        => i2c_master_avl_waitrequest,  
        i2c_master_0_avl_mm_writedata                          => i2c_master_avl_writedata,    
        i2c_master_0_avl_mm_read                               => i2c_master_avl_read,         
        i2c_master_0_avl_mm_readdata                           => i2c_master_avl_readdata,     
        i2c_master_0_avl_mm_readdatavalid                      => i2c_master_avl_readdatavalid,             
        
        --main_reg_avl_reset_reset                               => open,            
        --main_reg_avl_mm_address                                => open,          
        --main_reg_avl_mm_chipselect                             => open,       
        --main_reg_avl_mm_write                                  => open,            
        --main_reg_avl_mm_waitrequest                            => '0',      
        --main_reg_avl_mm_writedata                              => open,        
        --main_reg_avl_mm_read                                   => open,             
        --main_reg_avl_mm_readdatavalid                          => '0',    
        --main_reg_avl_mm_readdata                               => (others => '0'),                     
        
        spi_master_0_avl_reset_reset                           => adc_spi_master_avl_reset_reset,                                                                                       
        spi_master_0_avl_mm_address                            => adc_spi_master_avl_address,      
        spi_master_0_avl_mm_chipselect                         => adc_spi_master_avl_chipselect,   
        spi_master_0_avl_mm_write                              => adc_spi_master_avl_write,        
        spi_master_0_avl_mm_waitrequest                        => adc_spi_master_avl_waitrequest,  
        spi_master_0_avl_mm_writedata                          => adc_spi_master_avl_writedata,    
        spi_master_0_avl_mm_read                               => adc_spi_master_avl_read,         
        spi_master_0_avl_mm_readdata                           => adc_spi_master_avl_readdata,     
        spi_master_0_avl_mm_readdatavalid                      => adc_spi_master_avl_readdatavalid,
                   
        avalon_spi_slave_reset_reset                           => spi_slave_avl_reset_reset,  
        avalon_spi_slave_irq_irq                               => irq_to_nios,      
        avalon_spi_slave_address                               => spi_slave_avl_address,      
        avalon_spi_slave_chipselect                            => spi_slave_avl_chipselect,   
        avalon_spi_slave_waitrequest                           => spi_slave_avl_waitrequest,  
        avalon_spi_slave_write                                 => spi_slave_avl_write,        
        avalon_spi_slave_writedata                             => spi_slave_avl_writedata,    
        avalon_spi_slave_read                                  => spi_slave_avl_read,         
        avalon_spi_slave_readdata                              => spi_slave_avl_readdata,     
        avalon_spi_slave_readdatavalid                         => spi_slave_avl_readdatavalid,
        
        avl_mst_sbc_address                                    =>  sbc_avl_mst_address,      
        avl_mst_sbc_waitrequest                                =>  sbc_avl_mst_waitrequest,  
        avl_mst_sbc_write                                      =>  sbc_avl_mst_write,        
        avl_mst_sbc_writedata                                  =>  sbc_avl_mst_writedata,    
        avl_mst_sbc_read                                       =>  sbc_avl_mst_read,         
        avl_mst_sbc_readdata                                   =>  sbc_avl_mst_readdata,     
        avl_mst_sbc_readdatavalid                              =>  sbc_avl_mst_readdatavalid,
        avl_mst_sb_reset_reset                                 =>  sbc_avl_mst_reset,           
        
        jesd_low_slave_address                                 => jesd_if_low_slave_address,       
        jesd_low_slave_chipselect                              => jesd_if_low_slave_chipselect,    
        jesd_low_slave_read                                    => jesd_if_low_slave_read,          
        jesd_low_slave_readdata                                => jesd_if_low_slave_readdata,      
        jesd_low_slave_waitrequest                             => jesd_if_low_slave_waitrequest,   
        jesd_low_slave_write                                   => jesd_if_low_slave_write,         
        jesd_low_slave_writedata                               => jesd_if_low_slave_writedata,     
        jesd_low_slave_reset_reset_n                           => jesd_if_low_slave_reset_reset_n, 
                                                                                                  
        jesd_high_slave_address                                => jesd_if_high_slave_address,      
        jesd_high_slave_chipselect                             => jesd_if_high_slave_chipselect,   
        jesd_high_slave_read                                   => jesd_if_high_slave_read,         
        jesd_high_slave_readdata                               => jesd_if_high_slave_readdata,     
        jesd_high_slave_waitrequest                            => jesd_if_high_slave_waitrequest,  
        jesd_high_slave_write                                  => jesd_if_high_slave_write,        
        jesd_high_slave_writedata                              => jesd_if_high_slave_writedata,    
        jesd_high_slave_reset_reset_n                          => jesd_if_high_slave_reset_reset_n
       
    );

inst_tectonics_i2c_master_avl_intfc : tectonics_i2c_master_avl_intfc
   generic map(
      g_arst_pol                     => '1',         -- default to '1' sets internal reset polarity            
      g_input_clk_hz                 => 125_000_000,  -- used by the I2C module to set the bit rate                                
      g_i2c_bus_clk_hz               => 100_000      -- used by the I2C module to set the bit rate
      
   )
   port map(
      
      -- Clock and reset
      arst                     => i2c_master_avl_reset_reset,
      clk                      => clk_avl,
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            => open,   
            
      avl_slave_waitrequest    => i2c_master_avl_waitrequest,      
      avl_slave_address        => i2c_master_avl_address,  
      avl_slave_chipselect     => i2c_master_avl_chipselect,
      avl_slave_write          => i2c_master_avl_write,
      avl_slave_writedata      => i2c_master_avl_writedata,  
      avl_slave_read           => i2c_master_avl_read,
      avl_slave_readdata       => i2c_master_avl_readdata,
      avl_slave_readdatavalid  => i2c_master_avl_readdatavalid,                                                                           
      
      -- I2C pin interface                                              
      i2c_data_oe              => i2c_data_oe,                       
      i2c_clk_oe               => i2c_clk_oe,                             
                                                                    
      i2c_data_in              => i2c_data,                           
      i2c_clk_in               => i2c_clk                                  
                                                                       
   );                                                             

i2c_data  <= '0' when i2c_data_oe = '1' else 'Z';
i2c_clk   <= '0' when i2c_clk_oe  = '1' else 'Z';


inst_tectonics_adc_spi_master_avl_intfc : tectonics_spi_master_avl_intfc
   generic map(
      g_arst_pol                     => '1',   -- default to '1' sets internal reset polarity            
      g_delay_miso_samp_val          => 0      -- Shift samp MISO point by this many extra clocks, 0, 1 or 2
                                               -- For very slow devices.      
   )
   port map(
      
      -- Clock and reset
      arst                     => adc_spi_master_avl_reset_reset,                                                                        
      clk                      => clk_avl,
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            => open, 
      avl_slave_waitrequest    => adc_spi_master_avl_waitrequest,             
      avl_slave_address        => adc_spi_master_avl_address, 
      avl_slave_chipselect     => adc_spi_master_avl_chipselect,
      avl_slave_write          => adc_spi_master_avl_write,
      avl_slave_writedata      => adc_spi_master_avl_writedata, 
      avl_slave_read           => adc_spi_master_avl_read,
      avl_slave_readdata       => adc_spi_master_avl_readdata,                       
      avl_slave_readdatavalid  => adc_spi_master_avl_readdatavalid,                 
                                                                                    
      -- SPI pin interface                                                          
      -- SPI interface                                                 
      spi_sclk                 => adc_spi_master_sclk_core,                        
      spi_ss_n                 => adc_spi_master_ss_n_core,                            
      spi_mosi                 => adc_spi_master_mosi_core,                        
      spi_miso                 => adc_spi_master_miso_core                        
                                                                          
   );  
   -- Select the MISO source of the external core in case they cannot trisate  
   with conv_integer('0'&adc_spi_sel) select adc_spi_master_miso_core <=
      adc_spi_master_miso(0) when 0,
      adc_spi_master_miso(1) when 1,
      adc_spi_master_miso(2) when 2,
      adc_spi_master_miso(3) when 3,
      adc_spi_master_miso(4) when 4,
      adc_spi_master_miso(5) when 5,
      aux_spi_miso           when 6,
      adc_spi_master_miso(0) when others;

   adc_spi_master_ss_n(0) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 0 else '1';
   adc_spi_master_ss_n(1) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 1 else '1';
   adc_spi_master_ss_n(2) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 2 else '1';
   adc_spi_master_ss_n(3) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 3 else '1';
   adc_spi_master_ss_n(4) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 4 else '1';
   adc_spi_master_ss_n(5) <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 5 else '1';  
   aux_spi_cs_n           <= adc_spi_master_ss_n_core when conv_integer('0'&adc_spi_sel) = 6 else '1'; 
   
   
   -- Connect clocks to the ADCs.
   adc_spi_master_sclk(0) <= adc_spi_master_sclk_core; 
   adc_spi_master_sclk(1) <= adc_spi_master_sclk_core;
   adc_spi_master_sclk(2) <= adc_spi_master_sclk_core;
   adc_spi_master_sclk(3) <= adc_spi_master_sclk_core;
   adc_spi_master_sclk(4) <= adc_spi_master_sclk_core;
   adc_spi_master_sclk(5) <= adc_spi_master_sclk_core;
   aux_spi_clk            <= adc_spi_master_sclk_core;
   
   -- Connect mosi to the ADCs.
   adc_spi_master_mosi(0) <= adc_spi_master_mosi_core;
   adc_spi_master_mosi(1) <= adc_spi_master_mosi_core;
   adc_spi_master_mosi(2) <= adc_spi_master_mosi_core;
   adc_spi_master_mosi(3) <= adc_spi_master_mosi_core;
   adc_spi_master_mosi(4) <= adc_spi_master_mosi_core;
   adc_spi_master_mosi(5) <= adc_spi_master_mosi_core;  
   aux_spi_mosi           <= adc_spi_master_mosi_core;
              
------------------------------------------------------------
--spi device (SBC) interface
inst_spi_slave_reg_intfc : spi_slave_reg_intfc
   generic map(
      g_arst_pol                   => '1',
      g_spi_frame_len              => 48,   
                                                                                                                                               
      g_irq_pol                    => '1',
      g_chip_rev                   => g_chip_rev                                                   
   )

   port map(
      
      -- Clock and reset
      arst                         => spi_slave_avl_reset_reset,
      clk                          => clk_avl,    
      clk_wide                     => clk_wide,             
      -- Interrrupts to NiosV                                
      irq_events_in                => irq_events,
      irq_out                      => irq,
      -- Timing out                          
      tick_1_usec                  => tick_us, 
      tick_1_msec                  => tick_ms,                                          
      tick_1_sec                   => tick_sec,      -- Wdog reset output 
               
      wdog_sys_srst                => open,   -- To top level to force a reset. Will be 8 clocks wide 
      wdog_punch_pls_dbg           => open,   -- debug to help debug the watchdog issue SW was seeing
                                                                           
      -- SPI interface             
      reg_sclk                     => sbc_spi_sclk,
      reg_ss_n                     => sbc_spi_ss_n,
      reg_mosi                     => sbc_spi_mosi,
      reg_miso                     => sbc_spi_miso,                               
                                                                     
      led_hb                       => open,                                  
      leds                         => leds_from_reg,   
      switches                     => X"00", --switches,         
      
      -- Nios side interface, lets the nios also access the registers
      alv_slv_reg_chipselect       => spi_slave_avl_chipselect,
      alv_slv_reg_waitrequest      => spi_slave_avl_waitrequest,
      alv_slv_reg_addr             => spi_slave_avl_address,                  
      alv_slv_reg_rd_req           => spi_slave_avl_read,
      alv_slv_reg_rd_data_valid    => spi_slave_avl_readdatavalid,
      alv_slv_reg_rd_data          => spi_slave_avl_readdata,    
      alv_slv_reg_wr_req           => spi_slave_avl_write,                                                
      alv_slv_reg_wr_data          => spi_slave_avl_writedata,
      
      alv_mst_waitrequest          =>  sbc_avl_mst_waitrequest,      
      alv_mst_addr                 =>  sbc_avl_mst_address,  
      alv_mst_rd_req               =>  sbc_avl_mst_read,        
      alv_mst_rd_data_valid        =>  sbc_avl_mst_readdatavalid ,    
      alv_mst_rd_data              =>  sbc_avl_mst_readdata,         
      alv_mst_wr_req               =>  sbc_avl_mst_write,     
      alv_mst_wr_data              =>  sbc_avl_mst_writedata,   
                                                                                    
      board_id                     => "10", --board_id,

      gpio_data_in                 => all_zeros(31 downto 0), -- for now
      gpio_data_out                => open,                   -- for now
      gpio_data_oe                 => open,                   -- for now

                                           
      jesd_if_out_fifo_rst_n       => out_fifo_rst_n,                 
                                                                       
      jesd_if_low_rx_rst_n         => jesd_if_low_rx_rst_n,                 
      jesd_if_low_rx_rst_ack_n     => jesd_if_low_rx_rst_ack_n,             
      jesd_if_low_rx_out_of_reset  => jesd_if_low_rx_out_of_reset,          
                                                                     
      jesd_if_high_rx_rst_n        => jesd_if_high_rx_rst_n,                
      jesd_if_high_rx_rst_ack_n    => jesd_if_high_rx_rst_ack_n,            
      jesd_if_high_rx_out_of_reset => jesd_if_high_rx_out_of_reset,         
                                                                        
      jesd_if_low_loopback_enb     => jesd_if_low_loopback_enb,             
      jesd_if_high_loopback_enb    => jesd_if_high_loopback_enb,            
                                                                        
      jesd_if_avs_sel              => jesd_if_avs_sel,                      
      jesd_if_low_adc_dlckd        => jesd_if_low_adc_lane_locked_to_data,  
      jesd_if_high_adc_dlckd       => jesd_if_high_adc_lane_locked_to_data,
                 
      -- Interfaces realted to the ADC ICs    
      adc_pdwn_stby                => adc_pdwn_stby,
      adc_spi_sel                  => adc_spi_sel,
      
      adc_cal_trig(0)              => adc_cal_trig(0),
      adc_cal_trig(1)              => adc_cal_trig(1),
                       
      adc_cal_stat                 => adc_cal_stat,
      
      adc_pll_en(0)                => adc_pll_en(0), 
      adc_pll_en(1)                => adc_pll_en(1), 
      
      adc_syncse_n                 => open, --, adc_syncse_n, --drive from the RX core
                                                                  
      cal_pulse                    => open, --cal_pulse, 
      cal_pulse_pwr_en             => cal_pulse_pwr_en,
      cal_switch_adc               => cal_switch_adc,  
      adc_regulator_en             => adc_regulator_en,
      
      clk_pll_reset_n              =>  open, -- remove form design
      clk_pll_sync                 =>  open, -- remove form design
      clk_pll_clkin_sel            =>  clk_in_sel,                          
      
      -- Interface to the RX ADC data buffer module
		capture_ctrl       => capture_ctrl_reg,     
		capture_stat       => capture_stat_reg,        
		trigger_ctrl1		 => trigger_ctrl1_reg,	 
		trigger_ctrl2		 => trigger_ctrl2_reg,		  
		ptrigger_ctrl		 => ptrigger_ctrl_reg,	 
		readout_ctrl		=> readout_ctrl_reg,	
		posttrig_ctrl		=> posttrig_ctrl_reg,
		coinc_trigger_thresh0 => coinc_trigger_thresh_regs(0),
		coinc_trigger_thresh1 => coinc_trigger_thresh_regs(1),
		coinc_trigger_thresh2 => coinc_trigger_thresh_regs(2),
		coinc_trigger_thresh3 => coinc_trigger_thresh_regs(3),
		coinc_trigger_thresh4 => coinc_trigger_thresh_regs(4),
		coinc_trigger_thresh5 => coinc_trigger_thresh_regs(5),
		coinc_trigger_thresh6 => coinc_trigger_thresh_regs(6),
		coinc_trigger_thresh7 => coinc_trigger_thresh_regs(7),
		coinc_trigger_thresh8 => coinc_trigger_thresh_regs(8),
		coinc_trigger_thresh9 	=> coinc_trigger_thresh_regs(9),
		coinc_trigger_thresh10  => coinc_trigger_thresh_regs(10),
		coinc_trigger_thresh11  => coinc_trigger_thresh_regs(11),
		beam_trig_thresh0	  => beam_trig_thresh_regs(0),
		beam_trig_thresh1		=> beam_trig_thresh_regs(1),
		beam_trig_thresh2		=> beam_trig_thresh_regs(2),
		beam_trig_thresh3		=> beam_trig_thresh_regs(3),
		beam_trig_thresh4		=> beam_trig_thresh_regs(4),
		beam_trig_thresh5		=> beam_trig_thresh_regs(5),
		beam_trig_thresh6		=> beam_trig_thresh_regs(6),
		beam_trig_thresh7		=> beam_trig_thresh_regs(7),
		beam_trig_thresh8		=> beam_trig_thresh_regs(8),
		beam_trig_thresh9		=> beam_trig_thresh_regs(9),
		--event metadata:
		last_evt_evt_count	=>   open, 
		last_evt_trig_count	=>   last_evt_trig_count_reg,   
		last_evt_deadtime		=>  last_evt_deadtime_reg,    
		last_evt_clkcount		=>  last_evt_clkcount_reg,     
		last_evt_ppscount		=> last_evt_ppscount_reg,    
		last_evt_metamisc1	=>  last_evt_metamisc1_reg,	    
		last_evt_metamisc2	=>  last_evt_metamisc2_reg,    
		last_evt_trig_adr		=>  last_evt_trig_adr_reg,  
		scaler_sel				=>	 scaler_sel_reg,
		scaler_read			 	=>  scaler_read_reg,	 
      --data
      adc_0_fifo_data           => adc_fifo_data(0),   
      adc_0_fifo_rd_ack         => adc_fifo_rd_ack(0),                                            
      adc_1_fifo_data           => adc_fifo_data(1),   
      adc_1_fifo_rd_ack         => adc_fifo_rd_ack(1),                        
      adc_2_fifo_data           => adc_fifo_data(2),  
      adc_2_fifo_rd_ack         => adc_fifo_rd_ack(2),                         
      adc_3_fifo_data           => adc_fifo_data(3),  
      adc_3_fifo_rd_ack         => adc_fifo_rd_ack(3),                         
      adc_4_fifo_data           => adc_fifo_data(4),  
      adc_4_fifo_rd_ack         => adc_fifo_rd_ack(4),                         
      adc_5_fifo_data           => adc_fifo_data(5),  
      adc_5_fifo_rd_ack         => adc_fifo_rd_ack(5),                         
      adc_6_fifo_data           => adc_fifo_data(6),  
      adc_6_fifo_rd_ack         => adc_fifo_rd_ack(6),                        
      adc_7_fifo_data           => adc_fifo_data(7),  
      adc_7_fifo_rd_ack         => adc_fifo_rd_ack(7),                         
      adc_8_fifo_data           => adc_fifo_data(8),  
      adc_8_fifo_rd_ack         => adc_fifo_rd_ack(8),                       
      adc_9_fifo_data           => adc_fifo_data(9),  
      adc_9_fifo_rd_ack         => adc_fifo_rd_ack(9),                     
      adc_10_fifo_data          => adc_fifo_data(10),  
      adc_10_fifo_rd_ack        => adc_fifo_rd_ack(10),                       
      adc_11_fifo_data          => adc_fifo_data(11),  
      adc_11_fifo_rd_ack        => adc_fifo_rd_ack(11),
      adc_12_fifo_data          => adc_fifo_data(12),  
      adc_12_fifo_rd_ack        => adc_fifo_rd_ack(12),                                               
      adc_13_fifo_data          => adc_fifo_data(13),  
      adc_13_fifo_rd_ack        => adc_fifo_rd_ack(13),                      
      adc_14_fifo_data          => adc_fifo_data(14),  
      adc_14_fifo_rd_ack        => adc_fifo_rd_ack(14),                      
      adc_15_fifo_data          => adc_fifo_data(15),  
      adc_15_fifo_rd_ack        => adc_fifo_rd_ack(15),                      
      adc_16_fifo_data          => adc_fifo_data(16),  
      adc_16_fifo_rd_ack        => adc_fifo_rd_ack(16),                      
      adc_17_fifo_data          => adc_fifo_data(17),  
      adc_17_fifo_rd_ack        => adc_fifo_rd_ack(17),                       
      adc_18_fifo_data          => adc_fifo_data(18),  
      adc_18_fifo_rd_ack        => adc_fifo_rd_ack(18),                       
      adc_19_fifo_data          => adc_fifo_data(19),  
      adc_19_fifo_rd_ack        => adc_fifo_rd_ack(19),                       
      adc_20_fifo_data          => adc_fifo_data(20),  
      adc_20_fifo_rd_ack        => adc_fifo_rd_ack(20),                       
      adc_21_fifo_data          => adc_fifo_data(21),  
      adc_21_fifo_rd_ack        => adc_fifo_rd_ack(21),                       
      adc_22_fifo_data          => adc_fifo_data(22),  
      adc_22_fifo_rd_ack        => adc_fifo_rd_ack(22),                         
      adc_23_fifo_data          => adc_fifo_data(23),  
      adc_23_fifo_rd_ack        => adc_fifo_rd_ack(23)                                
                                                                                                                                                                                                                                                                                            
   );    
   
   --sbc_io_b_irq <= irq;
   irq_to_nios  <= irq;
   
   jesd_if_out_fifo_rst_n <= out_fifo_rst_n and not(spi_slave_avl_reset_reset); 
                                       
                                                 
inst_jesd_12_chan_if_low : jesd_12_chan_if       

   port map(
               
      clk_sysref                 => clk_gts_sysref(2 downto 0),  
                                                              
      clk_gts_pll_ref            => clk_gts_pll_ref(0) & clk_gts_pll_ref(0) & clk_gts_pll_ref(0), --
                                                          
      clk_link_lane              => clk_link_lane_low,                     
      clk_avs                    => clk_avl,                     
                                                                       
      clk_wide                   => clk_wide,                              
                                                                  
      out_fifo_rst_n             => jesd_if_out_fifo_rst_n,                                                                                       
      sync_adc_n						=> sync_adc_low_n,                                                                 
		
      rx_rst_n                   => jesd_if_low_rx_rst_n,                        
      rx_rst_ack_n               => jesd_if_low_rx_rst_ack_n,                                                               
      rx_out_of_reset            => jesd_if_low_rx_out_of_reset,           
                                                                        
      rx_adc_ser_data_p          => rx_adc_ser_data_p(11 downto 0),                            
      rx_adc_ser_data_n          => rx_adc_ser_data_n(11 downto 0),        
                                                                                                                                                                                                             
      loopback_enb               => jesd_if_low_loopback_enb,    
                                                               
      avs_rst_n                  => jesd_if_low_slave_reset_reset_n,
      avs_select                 => jesd_if_avs_sel,                 -- Set to select which core is to be addressed. Set before accessing via the AVL bus.
      avs_chipselect             => jesd_if_low_slave_chipselect,                    
      avs_address                => jesd_if_low_slave_address, 
      avs_read                   => jesd_if_low_slave_read,                     
      avs_readdata               => jesd_if_low_slave_readdata,
      avs_waitrequest            => jesd_if_low_slave_waitrequest,                    
      avs_write                  => jesd_if_low_slave_write,                     
      avs_writedata              => jesd_if_low_slave_writedata,               
                                                                        
      dev_lanes_aligned_from_ext => jesd_if_high_dev_lanes_aligned,  -- make sure to flip on other module
      dev_lanes_aligned_to_ext   => jesd_if_low_dev_lanes_aligned,   -- make sure to flip on other module
                                                                  
      adc_lane_locked_to_data    => jesd_if_low_adc_lane_locked_to_data,
                                                                
      adc_0_wide_data            => adc_wide_data(0),       -- The data format is big endian, where the              
      adc_0_wide_data_valid      => adc_wide_data_valid(0), -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                            -- octet/sample is placed in bit [7:0].                                                                                                                          
      adc_1_wide_data            => adc_wide_data(1),                                                              
      adc_1_wide_data_valid      => adc_wide_data_valid(1),                                                                                                       
      adc_2_wide_data            => adc_wide_data(2),        
      adc_2_wide_data_valid      => adc_wide_data_valid(2),                                                                                                       
      adc_3_wide_data            => adc_wide_data(3),        
      adc_3_wide_data_valid      => adc_wide_data_valid(3),                                                                                                                                               
      adc_4_wide_data            => adc_wide_data(4),        
      adc_4_wide_data_valid      => adc_wide_data_valid(4),                                                                                                                                                                                                                                     
      adc_5_wide_data            => adc_wide_data(5),        
      adc_5_wide_data_valid      => adc_wide_data_valid(5),                                                                                                            
      adc_6_wide_data            => adc_wide_data(6),        
      adc_6_wide_data_valid      => adc_wide_data_valid(6),                                                                                                           
      adc_7_wide_data            => adc_wide_data(7),        
      adc_7_wide_data_valid      => adc_wide_data_valid(7),                                                                                                                                         
      adc_8_wide_data            => adc_wide_data(8),        
      adc_8_wide_data_valid      => adc_wide_data_valid(8),                                                                                                                                                                                                                                 
      adc_9_wide_data            => adc_wide_data(9),        
      adc_9_wide_data_valid      => adc_wide_data_valid(9),                                                                                                      
      adc_10_wide_data           => adc_wide_data(10),        
      adc_10_wide_data_valid     => adc_wide_data_valid(10),                                                                                                            
      adc_11_wide_data           => adc_wide_data(11),        
      adc_11_wide_data_valid     => adc_wide_data_valid(11) );
   
   
   inst_jesd_12_chan_if_high : jesd_12_chan_if      
   
      port map(
                  
         clk_sysref                 => clk_gts_sysref(5 downto 3),  
                                                                 
         clk_gts_pll_ref            => clk_gts_pll_ref(1) & clk_gts_pll_ref(1) & clk_gts_pll_ref(1), 
                                                             
         clk_link_lane              => clk_link_lane_high,                     
         clk_avs                    => clk_avl,                     
                                                                          
         clk_wide                   => clk_wide,                              
                                                                     
         out_fifo_rst_n             => jesd_if_out_fifo_rst_n,   
			sync_adc_n						=> sync_adc_high_n,		
                                                                          
         rx_rst_n                   => jesd_if_high_rx_rst_n,                        
         rx_rst_ack_n               => jesd_if_high_rx_rst_ack_n,                                                               
         rx_out_of_reset            => jesd_if_high_rx_out_of_reset,           
                                                                           
         rx_adc_ser_data_p          => rx_adc_ser_data_p(23 downto 12),                            
         rx_adc_ser_data_n          => rx_adc_ser_data_n(23 downto 12),        
                                                                                                                                                                                                                
         loopback_enb               => jesd_if_high_loopback_enb,    
                                                                  
         avs_rst_n                  => jesd_if_high_slave_reset_reset_n,
         avs_select                 => jesd_if_avs_sel,                 -- Set to select which core is to be addressed. Set before addressing
         avs_chipselect             => jesd_if_high_slave_chipselect,                    
         avs_address                => jesd_if_high_slave_address, 
         avs_read                   => jesd_if_high_slave_read,                     
         avs_readdata               => jesd_if_high_slave_readdata,
         avs_waitrequest            => jesd_if_high_slave_waitrequest,                    
         avs_write                  => jesd_if_high_slave_write,                     
         avs_writedata              => jesd_if_high_slave_writedata,               
                                                                           
         dev_lanes_aligned_from_ext => jesd_if_low_dev_lanes_aligned,    -- make sure to flip on other module
         dev_lanes_aligned_to_ext   => jesd_if_high_dev_lanes_aligned,   -- make sure to flip on other module
                                                                     
         adc_lane_locked_to_data    => jesd_if_high_adc_lane_locked_to_data,
                                                                   
         adc_0_wide_data            => adc_wide_data(12),       -- The data format is big endian, where the              
         adc_0_wide_data_valid      => adc_wide_data_valid(12), -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                                -- octet/sample is placed in bit [7:0].                                                                                                                          
         adc_1_wide_data            => adc_wide_data(13),                                                              
         adc_1_wide_data_valid      => adc_wide_data_valid(13),                                                                                                       
         adc_2_wide_data            => adc_wide_data(14),        
         adc_2_wide_data_valid      => adc_wide_data_valid(14),                                                                                                      
         adc_3_wide_data            => adc_wide_data(15),        
         adc_3_wide_data_valid      => adc_wide_data_valid(15),                                                                                                                                              
         adc_4_wide_data            => adc_wide_data(16),        
         adc_4_wide_data_valid      => adc_wide_data_valid(16),                                                                                                                                                                                                                                  
         adc_5_wide_data            => adc_wide_data(17),        
         adc_5_wide_data_valid      => adc_wide_data_valid(17),                                                                                                          
         adc_6_wide_data            => adc_wide_data(18),        
         adc_6_wide_data_valid      => adc_wide_data_valid(18),                                                                                                          
         adc_7_wide_data            => adc_wide_data(19),        
         adc_7_wide_data_valid      => adc_wide_data_valid(19),                                                                                                                                       
         adc_8_wide_data            => adc_wide_data(20),        
         adc_8_wide_data_valid      => adc_wide_data_valid(20),                                                                                                                                                                                                                              
         adc_9_wide_data            => adc_wide_data(21),        
         adc_9_wide_data_valid      => adc_wide_data_valid(21),                                                                                                      
         adc_10_wide_data           => adc_wide_data(22),        
         adc_10_wide_data_valid     => adc_wide_data_valid(22),                                                                                                       
         adc_11_wide_data           => adc_wide_data(23),        
         adc_11_wide_data_valid     => adc_wide_data_valid(23) );

inst_tectonics_ser_debug : tectonics_ser_debug
   generic map(
   
      g_arst_pol           => '1',
      g_ser_debug_mult_sim => g_ser_debug_mult_sim                            
   )        
   port map(
   
      arst                         => ser_debug_master_reset_reset,                    
      clk                          => clk_avl,                   
      
      -- Interface to the Avalon fabfic for writing as master device                                                     
      avl_mstr_port_waitrequest    => ser_debug_master_waitrequest,   
      avl_mstr_port_byteenable     => ser_debug_master_byteenable,       
      avl_mstr_port_writedata      => ser_debug_master_writedata,   
      avl_mstr_port_address        => ser_debug_master_address,         
      avl_mstr_port_write          => ser_debug_master_write,     
      avl_mstr_port_read           => ser_debug_master_read,          
      avl_mstr_port_readdata       => ser_debug_master_readdata,      
      avl_mstr_port_readdatavalid  => ser_debug_master_readdatavalid, 
                                                                                                                     
      -- The serial interface                                                                                                             
      ser_tx                       =>  usb_uart_ser_out,                     
      ser_rx                       =>  usb_uart_ser_in                     
                                                           
   );                                                       
                                                                                         

-- This should be fine to use this async reset.
adc_data_buffer_rstn <= not spi_slave_avl_reset_reset; 
        
inst_adc_data_and_trig_handler : didaq_acq_and_trig

   port map(
      arstn                      => adc_data_buffer_rstn,
      clk_wr                     => clk_wide, 
      clk_rd                     => clk_avl, 
		clk_trig							=> clk_data,		
      -- Data form the JESD link
      -- All of these re in the clk_wide domain  
      adc_data_valid     	=> adc_wide_data_valid,                                        
      adc_0_wide_data           => adc_wide_data(0),                                                                                                                                             
      adc_1_wide_data           => adc_wide_data(1),                                                                    
      adc_2_wide_data           => adc_wide_data(2),                                                                    
      adc_3_wide_data           => adc_wide_data(3),                                                                    
      adc_4_wide_data           => adc_wide_data(4),                                                                    
      adc_5_wide_data           => adc_wide_data(5),                                                                    
      adc_6_wide_data           => adc_wide_data(6),                                                                    
      adc_7_wide_data           => adc_wide_data(7),                                                                    
      adc_8_wide_data           => adc_wide_data(8),                                                                    
      adc_9_wide_data           => adc_wide_data(9),                                                                    
      adc_10_wide_data          => adc_wide_data(10),                                                                   
      adc_11_wide_data          => adc_wide_data(11),                                        
      adc_12_wide_data          => adc_wide_data(12),                                                                         
      adc_13_wide_data          => adc_wide_data(13),                                                                         
      adc_14_wide_data          => adc_wide_data(14),                                                                         
      adc_15_wide_data          => adc_wide_data(15),                                                                         
      adc_16_wide_data          => adc_wide_data(16),                                                                         
      adc_17_wide_data          => adc_wide_data(17),                                                                         
      adc_18_wide_data          => adc_wide_data(18),                                                                         
      adc_19_wide_data          => adc_wide_data(19),                                                                         
      adc_20_wide_data          => adc_wide_data(20),                                                                         
      adc_21_wide_data          => adc_wide_data(21),                                                                         
      adc_22_wide_data          => adc_wide_data(22),                                                                         
      adc_23_wide_data          => adc_wide_data(23),                          
            
		adc_fifo_rd_ack        	 => adc_fifo_rd_ack,                                                                                                                                                 
      adc_0_fifo_data           => adc_fifo_data(0),    
      adc_1_fifo_data           => adc_fifo_data(1),                                   
      adc_2_fifo_data           => adc_fifo_data(2),                                  
      adc_3_fifo_data           => adc_fifo_data(3),                                  
      adc_4_fifo_data           => adc_fifo_data(4),                                  
      adc_5_fifo_data           => adc_fifo_data(5),                                  
      adc_6_fifo_data           => adc_fifo_data(6),                                  
      adc_7_fifo_data           => adc_fifo_data(7),                                  
      adc_8_fifo_data           => adc_fifo_data(8),                                  
      adc_9_fifo_data           => adc_fifo_data(9),                                  
      adc_10_fifo_data          => adc_fifo_data(10),                                  
      adc_11_fifo_data          => adc_fifo_data(11),   
      adc_12_fifo_data          => adc_fifo_data(12),                                                                                                                                                    
      adc_13_fifo_data          => adc_fifo_data(13),                                   
      adc_14_fifo_data          => adc_fifo_data(14),                                  
      adc_15_fifo_data          => adc_fifo_data(15),                                  
      adc_16_fifo_data          => adc_fifo_data(16),                                  
      adc_17_fifo_data          => adc_fifo_data(17),                                  
      adc_18_fifo_data          => adc_fifo_data(18),                                  
      adc_19_fifo_data          => adc_fifo_data(19),                                  
      adc_20_fifo_data          => adc_fifo_data(20),                                    
      adc_21_fifo_data          => adc_fifo_data(21),                                    
      adc_22_fifo_data          => adc_fifo_data(22),                                    
      adc_23_fifo_data          => adc_fifo_data(23),   

		capture_ctrl_reg_i       => capture_ctrl_reg,     
		capture_stat_reg_o       => capture_stat_reg,        
		trigger_ctrl1_reg_i		 => trigger_ctrl1_reg,	 
		trigger_ctrl2_reg_i		 => trigger_ctrl2_reg,		  
		ptrigger_ctrl_reg_i		 => ptrigger_ctrl_reg,	 
		readout_ctrl_reg_i		=> readout_ctrl_reg,	
		posttrig_ctrl_reg_i		=> posttrig_ctrl_reg,
		coinc_trigger_thresh0_reg_i => coinc_trigger_thresh_regs(0),
		coinc_trigger_thresh1_reg_i => coinc_trigger_thresh_regs(1),
		coinc_trigger_thresh2_reg_i => coinc_trigger_thresh_regs(2),
		coinc_trigger_thresh3_reg_i => coinc_trigger_thresh_regs(3),
		coinc_trigger_thresh4_reg_i => coinc_trigger_thresh_regs(4),
		coinc_trigger_thresh5_reg_i => coinc_trigger_thresh_regs(5),
		coinc_trigger_thresh6_reg_i => coinc_trigger_thresh_regs(6),
		coinc_trigger_thresh7_reg_i => coinc_trigger_thresh_regs(7),
		coinc_trigger_thresh8_reg_i => coinc_trigger_thresh_regs(8),
		coinc_trigger_thresh9_reg_i 	=> coinc_trigger_thresh_regs(9),
		coinc_trigger_thresh10_reg_i  => coinc_trigger_thresh_regs(10),
		coinc_trigger_thresh11_reg_i  => coinc_trigger_thresh_regs(11),
		beam_trig_thresh0_reg_i	  => beam_trig_thresh_regs(0),
		beam_trig_thresh1_reg_i		=> beam_trig_thresh_regs(1),
		beam_trig_thresh2_reg_i		=> beam_trig_thresh_regs(2),
		beam_trig_thresh3_reg_i		=> beam_trig_thresh_regs(3),
		beam_trig_thresh4_reg_i		=> beam_trig_thresh_regs(4),
		beam_trig_thresh5_reg_i		=> beam_trig_thresh_regs(5),
		beam_trig_thresh6_reg_i		=> beam_trig_thresh_regs(6),
		beam_trig_thresh7_reg_i		=> beam_trig_thresh_regs(7),
		beam_trig_thresh8_reg_i		=> beam_trig_thresh_regs(8),
		beam_trig_thresh9_reg_i		=> beam_trig_thresh_regs(9),
		--event metadata:
		last_evt_evt_count_reg_o	=>   open, 
		last_evt_trig_count_reg_o	=>   last_evt_trig_count_reg,   
		last_evt_deadtime_reg_o		=>  last_evt_deadtime_reg,    
		last_evt_clkcount_reg_o		=>  last_evt_clkcount_reg,     
		last_evt_ppscount_reg_o		=> last_evt_ppscount_reg,    
		last_evt_metamisc1_reg_o	=>  last_evt_metamisc1_reg,	    
		last_evt_metamisc2_reg_o	=>  last_evt_metamisc2_reg,    
		last_evt_trig_adr_reg_o		=>  last_evt_trig_adr_reg,    
		--scalers (on clk_rd)
		scaler_sel_reg_i			   => scaler_sel_reg,	
		scaler_read_reg_o				=> scaler_read_reg,
		event_ready_o 		   => sbc_io_b_irq,
		pps_i						=> sbc_one_pps,		
		ext_trig_i				=> fpga_aux_in );
                                                               
end rtl;                                                                                   
                                             
                                             