	io_pll_sysref u0 (
		.refclk     (_connected_to_refclk_),     //   input,  width = 1,     refclk.clk
		.locked     (_connected_to_locked_),     //  output,  width = 1,     locked.export
		.rst        (_connected_to_rst_),        //   input,  width = 1,      reset.reset
		.permit_cal (_connected_to_permit_cal_), //   input,  width = 1, permit_cal.export
		.outclk_0   (_connected_to_outclk_0_),   //  output,  width = 1,    outclk0.clk
		.outclk_1   (_connected_to_outclk_1_),   //  output,  width = 1,    outclk1.clk
		.outclk_2   (_connected_to_outclk_2_),   //  output,  width = 1,    outclk2.clk
		.outclk_3   (_connected_to_outclk_3_),   //  output,  width = 1,    outclk3.clk
		.outclk_4   (_connected_to_outclk_4_),   //  output,  width = 1,    outclk4.clk
		.outclk_5   (_connected_to_outclk_5_)    //  output,  width = 1,    outclk5.clk
	);

