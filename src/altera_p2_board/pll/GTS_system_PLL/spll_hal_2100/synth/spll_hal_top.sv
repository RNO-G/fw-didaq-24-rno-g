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


 
module spll_hal_top

#(
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
parameter sup_mode_atom                         = "SUP_MODE_USER_MODE" 


) (      	output		o_syspll_lock,							 
		input		i_hio_refclk_ready,
		input		i_refclk,
		output		o_syspll_c0,
		output		o_syspll_c1,
		output		o_syspll_c2

        
);


 

tennm_sm_hssi_pll_wrap #(
	  .pll_always_on(pll_always_on_atom),
	  .pll_primary_use(pll_primary_use_atom),
	  .sup_mode(sup_mode_atom),
	  .sys_pll_c0_counter(sys_pll_c0_counter_atom),
	  .sys_pll_c0_output_enable(sys_pll_c0_output_enable_atom),
	  .sys_pll_c1_counter(sys_pll_c1_counter_atom),
	  .sys_pll_c1_output_enable(sys_pll_c1_output_enable_atom),
	  .sys_pll_c2_counter(sys_pll_c2_counter_atom),
	  .sys_pll_c2_output_enable(sys_pll_c2_output_enable_atom),
	  .sys_pll_c3_counter(sys_pll_c3_counter_atom),
	  .sys_pll_c3_output_enable(sys_pll_c3_output_enable_atom),
	  .sys_pll_f_out_c0_hz(sys_pll_f_out_c0_hz_atom),
	  .sys_pll_f_out_c1_hz(sys_pll_f_out_c1_hz_atom),
	  .sys_pll_f_out_c2_hz(sys_pll_f_out_c2_hz_atom),
	  .sys_pll_f_out_c3_hz(sys_pll_f_out_c3_hz_atom),
	  .sys_pll_f_pfd_hz(sys_pll_f_pfd_hz_atom),
	  .sys_pll_f_ref_hz(sys_pll_f_ref_hz_atom),
	  .sys_pll_f_vco_hz(sys_pll_f_vco_hz_atom),
	  .sys_pll_fractional_enable(sys_pll_fractional_enable_atom),
	  .sys_pll_k_counter(sys_pll_k_counter_atom),
	  .sys_pll_m_counter(sys_pll_m_counter_atom),
	  .sys_pll_n_counter(sys_pll_n_counter_atom),
	  .sys_pll_preset(sys_pll_preset_atom)
	  ) inst (
		  .i_hio_refclk_ready (i_hio_refclk_ready),
		  .i_refclk(i_refclk),
		  .o_syspll_c0(o_syspll_c0	),
		  .o_syspll_c1(o_syspll_c1),
		  .o_syspll_c2(o_syspll_c2),
		  .o_syspll_lock(o_syspll_lock)
		 
	 );



	 
endmodule	 
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "11LIYRQQfbcIILvOzHeNg/vIX40VVp5HrhTQFjXrGHbtsSgtccqpT42TNySh0R8XlU7e0x5cX/J3MeRfGn6+BwXOZvNgE4rIo5IEhMAEj9TCLHfPErPj1cJSfwJZktP6CpsgEN63kZciygkTPajkumFaY8w9H3nkh+RMiA9vav9xORaXLaGd8D+CEwMzFAI+If638zrXOLt8W6Nmjo9ybrBZDERYVgWrzpLwGNO0HdmscvmOe8+bAvGmR3iekm3Ju344SQIjX+OFyTMG/HPJxucn2bVc9RXiNacWJg1Oj+pecXh+npwdreRPCyByBpxmNIUO9fWmZQV2QL8w26HXki7iAF6cUuzm7gqfeKL2wAJMG2aZkoQuvICS4C78WmbxB9BVbmoC5PbP+Qi2tnSDFMYw7W0ZSr1ONHPHB0WiVIIJbvNpMmQPKBP5Qf8IbwySLaJmfct9oSJC4pZq1WlzQ6t6yJ+RO+JSs6VUbzxNreMsKNDo/blDtvs/EDj8RIZQmlgnoiaHyamYAlhdvaK7kwudttEoeZTaY4zIibMa4b4k2jlniljTnwNAWBDylqi3JcV8mEQPoervfeb8wOnrgBDiOprlUmtKu8CPc/xAvLUV+NqsPOycr3H1EvL1XTMSB/A7STUbqEmrxjr0FaDwzV2dgqi7rOhkpSDDIcqanxEyInGW19S1Ta+j/FSc2ugv/ZuKmO17PJmgyaydZVDsH9jXnxtpiI2K/KywHi/vMHCwuOYUJAocxCSrqiYc/JGc9PF4dhjhqiHFV7GDmlolcnynoFhYUDlyi9nx5sqUtx367OHLTMyZCe+Id5qRpiujbEalGbAU6tYA3LOZHlCkkQXBGuRfruFJIHBwQWdUEWbX5eSpeoX/pD1w03o2J4eCkogVUWaRiJv7OO7qGqJ/p2hiiu+Z0s+ogTUi6ysGF9l6jaukfuyBvg/MuadGYrShCFIdGXZBjdwMdaoymzmzvZobNWN4QdAJaW74lIFMPOwjLjh2yroMTkGVtB6/d7ek"
`endif