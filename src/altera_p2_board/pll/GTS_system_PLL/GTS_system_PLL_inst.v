	GTS_system_PLL u0 (
		.o_pll_lock     (_connected_to_o_pll_lock_),     //  output,  width = 1,   o_pll_lock.o_pll_lock
		.o_syspll_c0    (_connected_to_o_syspll_c0_),    //  output,  width = 1,  o_syspll_c0.clk
		.i_refclk       (_connected_to_i_refclk_),       //   input,  width = 1,  refclk_xcvr.clk
		.i_refclk_ready (_connected_to_i_refclk_ready_)  //   input,  width = 1, i_refclk_rdy.data
	);

