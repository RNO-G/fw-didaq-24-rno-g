module io_pll_sysref (
		input  wire  refclk,     //     refclk.clk,    The reference clock source that drives the I/O PLL.
		output wire  locked,     //     locked.export, The IOPLL IP core drives this port high when the PLL acquires lock. The port remains high as long as the I/O PLL is locked. The I/O PLL asserts the locked port when the phases and frequencies of the reference clock and feedback clock are the same or within the lock circuit tolerance. When the difference between the two clock signals exceeds the lock circuit tolerance, the I/O PLL loses lock.
		input  wire  rst,        //      reset.reset,  The asynchronous reset port for the output clocks. Drive this port high to reset all output clocks to the value of 0.
		input  wire  permit_cal, // permit_cal.export, This is an input port for the downstream I/O PLL. Connect this permit_cal port to the locked output port of the upstream I/O PLL. Connecting this permit_cal port ensures that the cascaded I/O PLLs are calibrated in the correct order
		output wire  outclk_0,   //    outclk0.clk,    Output clock Channel 0 from I/O PLL.
		output wire  outclk_1,   //    outclk1.clk,    Output clock Channel 1 from I/O PLL.
		output wire  outclk_2,   //    outclk2.clk,    Output clock Channel 2 from I/O PLL.
		output wire  outclk_3,   //    outclk3.clk,    Output clock Channel 3 from I/O PLL.
		output wire  outclk_4,   //    outclk4.clk,    Output clock Channel 4 from I/O PLL.
		output wire  outclk_5    //    outclk5.clk,    Output clock Channel 5 from I/O PLL.
	);
endmodule

