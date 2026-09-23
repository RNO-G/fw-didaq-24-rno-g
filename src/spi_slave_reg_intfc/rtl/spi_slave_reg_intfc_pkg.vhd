--*----------------------------------------------------------------------------
--*                          VHDL RTL package file
--*                           Logic Tectonics Inc
--*                        For University of Chicago
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics Inc. www.logic-tectonics.com        
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------                   
--*   References: None                                                                               
--*                                                                                                                     
--*   Synthesis Considerations: None                                                                 
--*                                                                                                  
--*   Par Considerations: None                                                                       
--*   
--*
--*   Date      Author           Comments
--*   ------    ------           --------
--*   2025-Q1   Logic Tectonics  Inital verision
--*   20251112  Same             Added  c_adc_cal_trig_reg_addr
--*                                     c_adc_cal_stat_reg_addr
--*                                     c_adc_pll_en_reg_addr      
--*	202604	  UCHICAGO                                                      
--*----------------------------------------------------------------------------                      
                                                                                                                                                                       
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


package spi_slave_reg_intfc_pkg is

   -- Set this to the last location used below
   constant c_last_reg_location                 : natural  := 16#0064#; -- Set c_last_reg_location to the last/highest register location 

--
-- Constants that define register addresses that are accessible
-- by the external proc through the SPI interface (and debug interface)
--
   constant c_num_of_regs                       : positive := c_last_reg_location+1;      
   constant c_chip_rev_reg_addr                 : natural  := 16#0000#;
   constant c_board_id_reg_addr                 : natural  := 16#0001#; 
   constant c_led_switch_reg_addr               : natural  := 16#0002#;
   constant c_irq_stat_reg_addr                 : natural  := 16#0003#;               
   constant c_irq_enb_reg_addr                  : natural  := 16#0004#;
   constant c_wdog_reg_addr                     : natural  := 16#0005#;
   
   constant c_avl_mst_addr_reg_addr             : natural  := 16#0006#;         
   constant c_avl_mst_wr_data_reg_addr          : natural  := 16#0007#; 
   constant c_avl_mst_rd_data_reg_addr          : natural  := 16#0008#; 
   constant c_avl_mst_ctrl_stat_reg_addr        : natural  := 16#0009#;
                
   -- SBC only registers
   constant c_sbc_scratch_pad_reg_addr          : natural  := 16#000A#;
   
   -- Shared, SBC and Nios/Avalon bus accessible registers                               
   -- When NIOS accesses them it needs to use 4x value shown + reg file sys address offset
   -- to convert to byte addresses
   constant c_rsv1_reg_addr                     : natural  := 16#000B#;
   constant c_adc_pdwn_stby_reg_addr            : natural  := 16#000C#;
   constant c_adc_spi_sel_reg_addr              : natural  := 16#000D#;
   constant c_capture_ctrl_reg_addr             : natural  := 16#000E#;
   constant c_capture_stat_reg_addr             : natural  := 16#000F#;
   constant c_jesd_rst_reg_addr                 : natural  := 16#0010#;
   constant c_jesd_loopback_reg_addr            : natural  := 16#0011#;
   constant c_jesd_avs_sel_reg_addr             : natural  := 16#0012#;
   constant c_jesd_locked_stat_reg_addr         : natural  := 16#0013#;
   
   constant c_adc_0_fifo_data_reg_addr          : natural  := 16#0014#;
   constant c_adc_1_fifo_data_reg_addr          : natural  := 16#0015#;
   constant c_adc_2_fifo_data_reg_addr          : natural  := 16#0016#;
   constant c_adc_3_fifo_data_reg_addr          : natural  := 16#0017#;
   constant c_adc_4_fifo_data_reg_addr          : natural  := 16#0018#;
   constant c_adc_5_fifo_data_reg_addr          : natural  := 16#0019#;
   constant c_adc_6_fifo_data_reg_addr          : natural  := 16#001A#;
   constant c_adc_7_fifo_data_reg_addr          : natural  := 16#001B#;
   constant c_adc_8_fifo_data_reg_addr          : natural  := 16#001C#;
   constant c_adc_9_fifo_data_reg_addr          : natural  := 16#001D#;
   constant c_adc_10_fifo_data_reg_addr         : natural  := 16#001E#;
   constant c_adc_11_fifo_data_reg_addr         : natural  := 16#001F#;
   constant c_adc_12_fifo_data_reg_addr         : natural  := 16#0020#;
   constant c_adc_13_fifo_data_reg_addr         : natural  := 16#0021#;
   constant c_adc_14_fifo_data_reg_addr         : natural  := 16#0022#;
   constant c_adc_15_fifo_data_reg_addr         : natural  := 16#0023#;
   constant c_adc_16_fifo_data_reg_addr         : natural  := 16#0024#;
   constant c_adc_17_fifo_data_reg_addr         : natural  := 16#0025#;
   constant c_adc_18_fifo_data_reg_addr         : natural  := 16#0026#;
   constant c_adc_19_fifo_data_reg_addr         : natural  := 16#0027#;
   constant c_adc_20_fifo_data_reg_addr         : natural  := 16#0028#;
   constant c_adc_21_fifo_data_reg_addr         : natural  := 16#0029#;
   constant c_adc_22_fifo_data_reg_addr         : natural  := 16#002A#;
   constant c_adc_23_fifo_data_reg_addr         : natural  := 16#002B#;
       
   constant c_avl_to_sbc_mailbox_reg_addr       : natural  := 16#002C#;
   constant c_sbc_to_avl_mailbox_reg_addr       : natural  := 16#002D#;
   
                                               
   constant c_gpio_data_reg_addr                : natural  := 16#002E#;
   constant c_gpio_data_oe_reg_addr             : natural  := 16#002F#;
   
   constant c_adc_cal_trig_reg_addr             : natural  := 16#0030#;
   constant c_adc_syncse_n_reg_addr             : natural  := 16#0031#;
   constant c_adc_cal_stat_reg_addr             : natural  := 16#0032#;
   constant c_adc_pll_en_reg_addr               : natural  := 16#0033#;
   constant c_misc_ctrl_reg_addr                : natural  := 16#0034#;        
   constant c_pll_ctrl_stat_reg_addr            : natural  := 16#0035#;
   -- NIOS/Avalon accessible only specific register. 
   -- These are word (32-bit) addresses. 
   -- The address actually sent to the 
   -- register file is a 32bit word address and is 15 bits wide. So the nios
   -- SW needs to use the address shown below x4  + (reg file addr offset)
   -- when accessing the registers. 
   constant c_avl_scratch_pad_reg_addr         : natural  := 16#0036#;
	--------------------------
	--trigger stuff
	constant c_trigger_ctrl_1_addr				: natural	:= 16#0037#;
	constant c_trigger_ctrl_2_addr				: natural	:= 16#0038#;
	constant c_trigger_thresh_00_addr			: natural	:= 16#0039#;
	constant c_trigger_thresh_01_addr			: natural	:= 16#003A#;
	constant c_trigger_thresh_02_addr			: natural	:= 16#003B#;
	constant c_trigger_thresh_03_addr			: natural	:= 16#003C#;
	constant c_trigger_thresh_04_addr			: natural	:= 16#003D#;
	constant c_trigger_thresh_05_addr			: natural	:= 16#003E#;
	constant c_trigger_thresh_06_addr			: natural	:= 16#003F#;
	constant c_trigger_thresh_07_addr			: natural	:= 16#0040#;
	constant c_trigger_thresh_08_addr			: natural	:= 16#0041#;
	constant c_trigger_thresh_09_addr			: natural	:= 16#0042#;
	constant c_trigger_thresh_10_addr			: natural	:= 16#0043#;
	constant c_trigger_thresh_11_addr			: natural	:= 16#0044#;
	constant c_phased_trig_ctrl_addr				: natural	:= 16#0045#;
	constant c_beam_thresh_0_addr					: natural	:= 16#0046#;
	constant c_beam_thresh_1_addr					: natural	:= 16#0047#;
	constant c_beam_thresh_2_addr					: natural	:= 16#0048#;
	constant c_beam_thresh_3_addr					: natural	:= 16#0049#;
	constant c_beam_thresh_4_addr					: natural	:= 16#004A#;
	constant c_beam_thresh_5_addr					: natural	:= 16#004B#;
	constant c_beam_thresh_6_addr					: natural	:= 16#004C#;
 	constant c_beam_thresh_7_addr					: natural	:= 16#004D#;
	constant c_beam_thresh_8_addr					: natural	:= 16#004E#;
	constant c_beam_thresh_9_addr					: natural	:= 16#004F#;
	constant c_beam_thresh_10_addr				: natural	:= 16#0050#;
	constant c_beam_thresh_11_addr				: natural	:= 16#0051#;

  	--event header stuff
	constant c_lastevt_event_counter_addr		: natural	:= 16#0052#;
	constant c_lastevt_trig_counter_addr		: natural	:= 16#0053#;
	constant c_lastevt_deadtime_counter_addr	: natural	:= 16#0054#;
	constant c_lastevt_sincepps_counter_addr	: natural	:= 16#0055#;
	constant c_lastevt_pps_counter_addr			: natural	:= 16#0056#;
	constant c_lastevt_metamisc_1_addr			: natural	:= 16#0057#;
	constant c_lastevt_metamisc_2_addr			: natural	:= 16#0058#;
	constant c_lastevt_trigadr_addr				: natural	:= 16#0059#;
	constant c_post_trigger_length_addr			: natural	:= 16#005A#;
	constant c_readout_ctrl_addr					: natural	:= 16#005B#;
	--scalers
	constant c_scaler_readout_addr				: natural	:= 16#005C#;
	constant c_scaler_select_addr					: natural	:= 16#005D#;
	
	constant c_trigger_mask_1_addr				: natural	:= 16#0062#;
	constant c_trigger_mask_2_addr				: natural	:= 16#0063#;


   
                                                                                                                 
end; -- package                                                                                            
                                                                                                          
                                                                                                         
