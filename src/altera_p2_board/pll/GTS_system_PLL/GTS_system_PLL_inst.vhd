	component GTS_system_PLL is
		port (
			o_pll_lock     : out std_logic;        -- o_pll_lock
			o_syspll_c0    : out std_logic;        -- clk
			i_refclk       : in  std_logic := 'X'; -- clk
			i_refclk_ready : in  std_logic := 'X'  -- data
		);
	end component GTS_system_PLL;

	u0 : component GTS_system_PLL
		port map (
			o_pll_lock     => CONNECTED_TO_o_pll_lock,     --   o_pll_lock.o_pll_lock
			o_syspll_c0    => CONNECTED_TO_o_syspll_c0,    --  o_syspll_c0.clk
			i_refclk       => CONNECTED_TO_i_refclk,       --  refclk_xcvr.clk
			i_refclk_ready => CONNECTED_TO_i_refclk_ready  -- i_refclk_rdy.data
		);

