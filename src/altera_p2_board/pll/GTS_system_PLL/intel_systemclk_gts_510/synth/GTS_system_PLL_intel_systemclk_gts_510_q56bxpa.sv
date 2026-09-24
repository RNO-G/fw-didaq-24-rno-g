// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



`timescale 1 ps / 1 ps


module GTS_system_PLL_intel_systemclk_gts_510_q56bxpa  #(

   parameter  systempll_ethernet_preset_0 = "IE",
   //parameter  ch_pldif_channel_identifier = "IE",
   parameter  systempll_pcie_preset_0 = "IE",
   parameter  systempll_c0_output_enable_0   = "IE",
   parameter  systempll_c1_output_enable_0   = "IE",
   parameter  systempll_c2_output_enable_0   = "IE",
   parameter  systempll_f_out_c0_hz_0        = "IE",
   parameter  systempll_f_out_c1_hz_0        = "IE",
   parameter  systempll_f_out_c2_hz_0        = "IE",
   parameter  systempll_f_ref_hz_0           = "IE",
   parameter  systempll_primary_use_0        = "IE",
   parameter dr_enabled                                         = "DR_ENABLED_DR_DISABLED"       /* Settings: DR_ENABLED_DR_DISABLED, DR_ENABLED_DR_ENABLED */,
   parameter duplex_mode                                        = "DUPLEX_MODE_DUPLEX"           /* Settings: DUPLEX_MODE_DUPLEX, DUPLEX_MODE_TX_ONLY_SIMPLEX, DUPLEX_MODE_RX_ONLY_SIMPLEX, DUPLEX_MODE_DUAL_SIMPLEX, DUPLEX_MODE_DISABLED */,
   parameter pld_channel_identifier                             = "PLD_CHANNEL_IDENTIFIER_PTP"   /* Settings: PLD_CHANNEL_IDENTIFIER_GENERIC, PLD_CHANNEL_IDENTIFIER_PHIP, PLD_CHANNEL_IDENTIFIER_PTP */,
   parameter rx_clkout1_divider                                 = "RX_CLKOUT1_DIVIDER_DIV1"      /* Settings: RX_CLKOUT1_DIVIDER_DIV1, RX_CLKOUT1_DIVIDER_DIV2, RX_CLKOUT1_DIVIDER_DIV4 */,
   parameter rx_clkout2_divider                                 = "RX_CLKOUT2_DIVIDER_DIV1"      /* Settings: RX_CLKOUT2_DIVIDER_DIV1, RX_CLKOUT2_DIVIDER_DIV2, RX_CLKOUT2_DIVIDER_DIV4 */,
   parameter rx_en                                              = "FALSE"                        /* Settings: TRUE, FALSE */,
   parameter rx_fifo_mode                                       = "RX_FIFO_MODE_DISABLED"      /* Settings: RX_FIFO_MODE_ELASTIC, RX_FIFO_MODE_PHASE_COMP, RX_FIFO_MODE_REVERSE_ELASTIC, RX_FIFO_MODE_DISABLED */,
   parameter rx_fifo_width                                      = "RX_FIFO_WIDTH_DOUBLE_WIDTH"   /* Settings: RX_FIFO_WIDTH_DOUBLE_WIDTH, RX_FIFO_WIDTH_SINGLE_WIDTH, RX_FIFO_WIDTH_DOUBLE_DOUBLE_WIDTH, RX_FIFO_WIDTH_DISABLED */,
   parameter rx_fifo_wr_clk_hz                                  = 36'd0                          /* Settings: SIMPLE_DIRECT */,
   parameter rx_user1_clk_dynamic_mux                           = "RX_USER1_CLK_DYNAMIC_MUX_UNUSED" /* Settings: RX_USER1_CLK_DYNAMIC_MUX_UX, RX_USER1_CLK_DYNAMIC_MUX_C0, RX_USER1_CLK_DYNAMIC_MUX_C1, RX_USER1_CLK_DYNAMIC_MUX_C2, RX_USER1_CLK_DYNAMIC_MUX_UNUSED */,
   parameter rx_user2_clk_dynamic_mux                           = "RX_USER2_CLK_DYNAMIC_MUX_UNUSED" /* Settings: RX_USER2_CLK_DYNAMIC_MUX_UX, RX_USER2_CLK_DYNAMIC_MUX_C0, RX_USER2_CLK_DYNAMIC_MUX_C1, RX_USER2_CLK_DYNAMIC_MUX_C2, RX_USER2_CLK_DYNAMIC_MUX_UNUSED */,
   parameter sup_mode                                           = "SUP_MODE_USER_MODE"           /* Settings: SUP_MODE_USER_MODE, SUP_MODE_ADVANCED_USER_MODE, SUP_MODE_ENGINEERING_MODE */,
   parameter tx_clkout1_divider                                 = "TX_CLKOUT1_DIVIDER_DIV1"      /* Settings: TX_CLKOUT1_DIVIDER_DIV1, TX_CLKOUT1_DIVIDER_DIV2, TX_CLKOUT1_DIVIDER_DIV4 */,
   parameter tx_clkout2_divider                                 = "TX_CLKOUT2_DIVIDER_DIV1"      /* Settings: TX_CLKOUT2_DIVIDER_DIV1, TX_CLKOUT2_DIVIDER_DIV2, TX_CLKOUT2_DIVIDER_DIV4 */,
   parameter tx_en                                              = "FALSE"                        /* Settings: TRUE, FALSE */,
   parameter tx_fifo_mode                                       = "TX_FIFO_MODE_DISABLED"      /* Settings: TX_FIFO_MODE_ELASTIC, TX_FIFO_MODE_PHASE_COMP, TX_FIFO_MODE_REVERSE_ELASTIC, TX_FIFO_MODE_DISABLED */,
   parameter tx_fifo_rd_clk_hz                                  = 36'd0                          /* Settings: SIMPLE_DIRECT */,
   parameter tx_fifo_width                                      = "TX_FIFO_WIDTH_DOUBLE_WIDTH"   /* Settings: TX_FIFO_WIDTH_DOUBLE_WIDTH, TX_FIFO_WIDTH_SINGLE_WIDTH, TX_FIFO_WIDTH_DOUBLE_DOUBLE_WIDTH, TX_FIFO_WIDTH_DISABLED */,
   parameter tx_user1_clk_dynamic_mux                           = "TX_USER1_CLK_DYNAMIC_MUX_UNUSED" /* Settings: TX_USER1_CLK_DYNAMIC_MUX_UX, TX_USER1_CLK_DYNAMIC_MUX_C0, TX_USER1_CLK_DYNAMIC_MUX_C1, TX_USER1_CLK_DYNAMIC_MUX_C2, TX_USER1_CLK_DYNAMIC_MUX_UNUSED */,
   parameter tx_user2_clk_dynamic_mux                           = "TX_USER2_CLK_DYNAMIC_MUX_UNUSED" /* Settings: TX_USER2_CLK_DYNAMIC_MUX_UX, TX_USER2_CLK_DYNAMIC_MUX_C0, TX_USER2_CLK_DYNAMIC_MUX_C1, TX_USER2_CLK_DYNAMIC_MUX_C2, TX_USER2_CLK_DYNAMIC_MUX_UNUSED */,
   parameter vc_rx_pldif_wm_en                                  = "VC_RX_PLDIF_WM_EN_DISABLE",     /* Settings: VC_RX_PLDIF_WM_EN_ENABLE, VC_RX_PLDIF_WM_EN_DISABLE */
  
   parameter  silicon_revision        = "10nm6awhra",
   parameter  device_revision         = "10nm6awhra"

 ) (
        output    o_pll_lock,
                           
        input    i_refclk_ready,
        input    i_refclk,
        
        output    o_syspll_c0,
        output    o_syspll_c1,
        output    o_syspll_c2
  );





//=================================================================
//                          SystemPLL
//=================================================================
localparam SYSTEMPLL_NUM = 1;

wire   [SYSTEMPLL_NUM-1:0]  w_systempll_clk_out;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_clk_out_1;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_clk_out_2;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_fabric_clk_out_2;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_fabric_clk_out_1;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_fabric_clk_out;

wire   [SYSTEMPLL_NUM-1:0]  w_systempll_synthlock_out;
wire   [SYSTEMPLL_NUM-1:0]  w_systempll_status_out;




assign   o_syspll_c2 = w_systempll_clk_out_2;
assign   o_syspll_c1 = w_systempll_clk_out_1;
assign   o_syspll_c0 = w_systempll_clk_out;



assign    o_pll_lock   = w_systempll_synthlock_out;
  
 GTS_system_PLL_intel_systemclk_gts_spll_hal_510_4qpunya #(
  
  //.syspll_l_sys_pll_f_ref_hz         ( systempll_f_ref_hz_0 ),
  //.syspll_l_sys_pll_f_out_c0_hz      ( systempll_f_out_c0_hz_0 ),
  //.syspll_l_sys_pll_c0_output_enable ( systempll_c0_output_enable_0 ),
  //.syspll_l_sys_pll_c1_output_enable ( systempll_c1_output_enable_0),
  //.syspll_l_sys_pll_f_out_c1_hz      ( systempll_f_out_c1_hz_0 ),
  //.syspll_l_sys_pll_c2_output_enable     (  systempll_c2_output_enable_0 ),
  //.syspll_l_sys_pll_f_out_c2_hz          (  systempll_f_out_c2_hz_0 )
  ) inst (
     .o_spll_lock              (   w_systempll_synthlock_out  ),
     .o_syspll_c0              (   w_systempll_clk_out        ),
     .o_syspll_c1              (   w_systempll_clk_out_1      ),
     .o_syspll_c2              (   w_systempll_clk_out_2      ),
     .i_refclk_rdy             (   i_refclk_ready              ),
     .i_refclk                 (   i_refclk )
 );

 
 
 assign w_systempll_fabric_clk_out_2  = 0;
 assign w_systempll_fabric_clk_out_1  = 0;
 assign w_systempll_fabric_clk_out    = 0;
 
 
    
endmodule



