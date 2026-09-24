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


module GTS_system_PLL_spll_hal_2100_qol5lrq  #(

parameter sys_pll_c0_output_enable_atom         = "SYS_PLL_C0_OUTPUT_ENABLE_ENABLE" ,
parameter sys_pll_c1_output_enable_atom         = "SYS_PLL_C1_OUTPUT_ENABLE_ENABLE" ,
parameter sys_pll_c2_output_enable_atom         = "SYS_PLL_C2_OUTPUT_ENABLE_ENABLE" ,
parameter sys_pll_c3_output_enable_atom         = "SYS_PLL_C3_OUTPUT_ENABLE_ENABLE" ,
parameter sys_pll_f_ref_hz_atom                 = 36'd0 ,                            
parameter sys_pll_f_out_c0_hz_atom              = 36'd0 ,                            
parameter sys_pll_f_out_c1_hz_atom              = 36'd0 ,                            
parameter sys_pll_f_out_c2_hz_atom              = 36'd0 ,                            
parameter sys_pll_f_out_c3_hz_atom              = 36'd0 ,                            
parameter pll_primary_use_atom                  = "PLL_PRIMARY_USE_DISABLED"  ,      
parameter sys_pll_preset_atom                   = "SYS_PLL_PRESET_FREQ_1000"  ,
parameter sys_pll_f_pfd_hz_atom                 = 36'd0 ,                             
parameter sys_pll_f_vco_hz_atom                 = 36'd0 ,   
//parameter syspll_l_sys_pll_f_vco_hz                       = "0" , 
      
parameter sys_pll_n_counter_atom                = 5'd0 ,                              
parameter sys_pll_m_counter_atom                = 10'd0,                              
parameter sys_pll_k_counter_atom                = 24'd0 ,                             
parameter sys_pll_c0_counter_atom               = 11'd0 ,                             
parameter sys_pll_c1_counter_atom               = 11'd0 ,                             
parameter sys_pll_c2_counter_atom               = 11'd0 ,                             
parameter sys_pll_c3_counter_atom               = 11'd0 ,                             
parameter sys_pll_fractional_enable_atom        = "SYS_PLL_FRACTIONAL_ENABLE_ENABLE" ,
parameter pll_always_on_atom                    = "PLL_ALWAYS_ON_ALWAYS_ON_ENABLED"  ,
parameter sup_mode_atom                         = "SUP_MODE_USER_MODE" ,

parameter  silicon_revision						 = "10nm6awhra",
parameter  device_revision						 = "10nm6awhra"

 ) (
		output		o_spll_lock,							 
		input		i_refclk_rdy,
		input		i_refclk,
		output		o_syspll_c0,
		output		o_syspll_c1,
		output		o_syspll_c2
  );


//=================================================================
//							SystemPLL
//=================================================================
localparam SYSTEMPLL_NUM = 1;

wire   [SYSTEMPLL_NUM-1:0]	w_systempll_clk_out;
wire   [SYSTEMPLL_NUM-1:0]	w_systempll_clk_out_1;
wire   [SYSTEMPLL_NUM-1:0]	w_systempll_clk_out_2;
wire   [SYSTEMPLL_NUM-1:0]	w_systempll_synthlock_out;

wire [SYSTEMPLL_NUM-1:0]	w_systempll_status_out;

assign	  o_spll_lock   = w_systempll_synthlock_out;
assign	  o_syspll_c0	= w_systempll_clk_out;
assign	  o_syspll_c1	= w_systempll_clk_out_1;
assign	  o_syspll_c2	= w_systempll_clk_out_2;


// localparam  MAX_CONVERSION_SIZE_ALT_XCVR_NATIVE_S10 = 128;
//    localparam  MAX_STRING_CHARS_ALT_XCVR_NATIVE_S10  = 64;
//    localparam integer MAX_CHARS_ALT_XCVR_NATIVE_S10 = 86; // To accomodate LONG parameter lists.
// 
//    function automatic [MAX_CONVERSION_SIZE_ALT_XCVR_NATIVE_S10-1:0] str_2_bin_alt_xcvr_native_gdr;
//      input [MAX_STRING_CHARS_ALT_XCVR_NATIVE_S10*8-1:0] instring;
// 
//      integer this_char;
//      integer i;
//      begin
//        // Initialize accumulator
//        str_2_bin_alt_xcvr_native_gdr = {MAX_CONVERSION_SIZE_ALT_XCVR_NATIVE_S10{1'b0}};
//        for(i=MAX_STRING_CHARS_ALT_XCVR_NATIVE_S10-1;i>=0;i=i-1) begin
//          this_char = instring[i*8+:8];
//          // Add value of this digit
//          if(this_char >= 48 && this_char <= 57)
//            str_2_bin_alt_xcvr_native_gdr = (str_2_bin_alt_xcvr_native_gdr * 10) + (this_char - 48);
//                   
//end
//      end
//    endfunction    
//
//
//localparam [36:0] f_vco_hz_atom = str_2_bin_alt_xcvr_native_gdr(syspll_l_sys_pll_f_vco_hz);
 
spll_hal_top #(
	  .pll_always_on_atom(pll_always_on_atom),
	  .pll_primary_use_atom(pll_primary_use_atom),
	  .sup_mode_atom(sup_mode_atom),
	  .sys_pll_c0_counter_atom(sys_pll_c0_counter_atom),
	  .sys_pll_c0_output_enable_atom(sys_pll_c0_output_enable_atom),
	  .sys_pll_c1_counter_atom(sys_pll_c1_counter_atom),
	  .sys_pll_c1_output_enable_atom(sys_pll_c1_output_enable_atom),
	  .sys_pll_c2_counter_atom(sys_pll_c2_counter_atom),
	  .sys_pll_c2_output_enable_atom(sys_pll_c2_output_enable_atom),
	  .sys_pll_c3_counter_atom(sys_pll_c3_counter_atom),
	  .sys_pll_c3_output_enable_atom(sys_pll_c3_output_enable_atom),
	  .sys_pll_f_out_c0_hz_atom(sys_pll_f_out_c0_hz_atom),
	  .sys_pll_f_out_c1_hz_atom(sys_pll_f_out_c1_hz_atom),
	  .sys_pll_f_out_c2_hz_atom(sys_pll_f_out_c2_hz_atom),
	  .sys_pll_f_out_c3_hz_atom(sys_pll_f_out_c3_hz_atom),
	  .sys_pll_f_pfd_hz_atom(sys_pll_f_pfd_hz_atom),
	  .sys_pll_f_ref_hz_atom(sys_pll_f_ref_hz_atom),
	  .sys_pll_f_vco_hz_atom(sys_pll_f_vco_hz_atom),
	  .sys_pll_fractional_enable_atom(sys_pll_fractional_enable_atom),
	  .sys_pll_k_counter_atom(sys_pll_k_counter_atom),
	  .sys_pll_m_counter_atom(sys_pll_m_counter_atom),
	  .sys_pll_n_counter_atom(sys_pll_n_counter_atom),
	  .sys_pll_preset_atom(sys_pll_preset_atom)
	  ) inst (
		  .i_hio_refclk_ready (i_refclk_rdy),
		  .i_refclk(i_refclk),
		  .o_syspll_c0(w_systempll_clk_out	),
		  .o_syspll_c1(w_systempll_clk_out_1),
		  .o_syspll_c2(w_systempll_clk_out_2),
		  .o_syspll_lock(w_systempll_synthlock_out)
	 );





//  tennm_sm_hssi_pll_wrap #(
//	  .pll_always_on(pll_always_on_atom),
//	  .pll_primary_use(pll_primary_use_atom),
//	  .sup_mode(sup_mode_atom),
//	  .sys_pll_c0_counter(sys_pll_c0_counter_atom),
//	  .sys_pll_c0_output_enable(sys_pll_c0_output_enable_atom),
//	  .sys_pll_c1_counter(sys_pll_c1_counter_atom),
//	  .sys_pll_c1_output_enable(sys_pll_c1_output_enable_atom),
//	  .sys_pll_c2_counter(sys_pll_c2_counter_atom),
//	  .sys_pll_c2_output_enable(sys_pll_c2_output_enable_atom),
//	  .sys_pll_c3_counter(sys_pll_c3_counter_atom),
//	  .sys_pll_c3_output_enable(sys_pll_c3_output_enable_atom),
//	  .sys_pll_f_out_c0_hz(sys_pll_f_out_c0_hz_atom),
//	  .sys_pll_f_out_c1_hz(sys_pll_f_out_c1_hz_atom),
//	  .sys_pll_f_out_c2_hz(sys_pll_f_out_c2_hz_atom),
//	  .sys_pll_f_out_c3_hz(sys_pll_f_out_c3_hz_atom),
//	  .sys_pll_f_pfd_hz(sys_pll_f_pfd_hz_atom),
//	  .sys_pll_f_ref_hz(sys_pll_f_ref_hz_atom),
//	  .sys_pll_f_vco_hz(f_vco_hz_atom),
//	  .sys_pll_fractional_enable(sys_pll_fractional_enable_atom),
//	  .sys_pll_k_counter(sys_pll_k_counter_atom),
//	  .sys_pll_m_counter(sys_pll_m_counter_atom),
//	  .sys_pll_n_counter(sys_pll_n_counter_atom),
//	  .sys_pll_preset(sys_pll_preset_atom)
//	  ) inst (
//		  .i_hio_refclk_ready (i_refclk_rdy),
//		  .i_refclk(i_refclk),
//		  .o_syspll_c0(w_systempll_clk_out	),
//		  .o_syspll_c1(w_systempll_clk_out_1),
//		  .o_syspll_c2(w_systempll_clk_out_2),
//		  .o_syspll_lock(w_systempll_synthlock_out)
//	 );
//	

endmodule

