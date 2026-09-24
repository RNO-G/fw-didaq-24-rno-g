	component jesd_gts_reset_sequencer is
		port (
			o_src_rs_grant               : out std_logic_vector(11 downto 0);                    -- src_rs_grant
			i_src_rs_priority            : in  std_logic_vector(11 downto 0) := (others => 'X'); -- src_rs_priority
			i_src_rs_req                 : in  std_logic_vector(11 downto 0) := (others => 'X'); -- src_rs_req
			o_pma_cu_clk                 : out std_logic_vector(2 downto 0);                     -- clk
			i_refclk_bus_out             : in  std_logic                     := 'X';             -- refclk_bus_out
			o_shoreline_refclk_fail_stat : out std_logic                                         -- shoreline_refclk_fail_stat
		);
	end component jesd_gts_reset_sequencer;

	u0 : component jesd_gts_reset_sequencer
		port map (
			o_src_rs_grant               => CONNECTED_TO_o_src_rs_grant,               --               o_src_rs_grant.src_rs_grant
			i_src_rs_priority            => CONNECTED_TO_i_src_rs_priority,            --            i_src_rs_priority.src_rs_priority
			i_src_rs_req                 => CONNECTED_TO_i_src_rs_req,                 --                 i_src_rs_req.src_rs_req
			o_pma_cu_clk                 => CONNECTED_TO_o_pma_cu_clk,                 --                 o_pma_cu_clk.clk
			i_refclk_bus_out             => CONNECTED_TO_i_refclk_bus_out,             --             i_refclk_bus_out.refclk_bus_out
			o_shoreline_refclk_fail_stat => CONNECTED_TO_o_shoreline_refclk_fail_stat  -- o_shoreline_refclk_fail_stat.shoreline_refclk_fail_stat
		);

