module GTS_system_PLL (
		output wire  o_pll_lock,     //   o_pll_lock.o_pll_lock, Lock signal of PLL
		output wire  o_syspll_c0,    //  o_syspll_c0.clk,        Clock output C0
		input  wire  i_refclk,       //  refclk_xcvr.clk,        Input refclock port
		input  wire  i_refclk_ready  // i_refclk_rdy.data,       Reference clock ready indicator. Value '1' indicated SPLL that reference clock is available and stable
	);
endmodule

