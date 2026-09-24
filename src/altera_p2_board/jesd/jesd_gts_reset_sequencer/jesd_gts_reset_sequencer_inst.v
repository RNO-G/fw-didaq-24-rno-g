	jesd_gts_reset_sequencer u0 (
		.o_src_rs_grant               (_connected_to_o_src_rs_grant_),               //  output,  width = 12,               o_src_rs_grant.src_rs_grant
		.i_src_rs_priority            (_connected_to_i_src_rs_priority_),            //   input,  width = 12,            i_src_rs_priority.src_rs_priority
		.i_src_rs_req                 (_connected_to_i_src_rs_req_),                 //   input,  width = 12,                 i_src_rs_req.src_rs_req
		.o_pma_cu_clk                 (_connected_to_o_pma_cu_clk_),                 //  output,   width = 3,                 o_pma_cu_clk.clk
		.i_refclk_bus_out             (_connected_to_i_refclk_bus_out_),             //   input,   width = 1,             i_refclk_bus_out.refclk_bus_out
		.o_shoreline_refclk_fail_stat (_connected_to_o_shoreline_refclk_fail_stat_)  //  output,   width = 1, o_shoreline_refclk_fail_stat.shoreline_refclk_fail_stat
	);

