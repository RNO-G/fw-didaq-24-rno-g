module jesd_gts_reset_sequencer (
		output wire [11:0] o_src_rs_grant,               //               o_src_rs_grant.src_rs_grant,               Grant from SRC_Shoreline_Sequencer to SRC_Lane, this will allow SRC_Lane to drive/toggle a reset
		input  wire [11:0] i_src_rs_priority,            //            i_src_rs_priority.src_rs_priority,            Binary Priority Input(0 - Less priority and 1 - high Priority). The user will have to tie this input to '0' unless the request is from an IP which needs fast reconfigurations.
		input  wire [11:0] i_src_rs_req,                 //                 i_src_rs_req.src_rs_req,                 Request from SRC_Lane to the SRC_Shoreline_Sequencer when it wants to toggle a reset
		output wire [2:0]  o_pma_cu_clk,                 //                 o_pma_cu_clk.clk,                        PMA control unit clock output, 1 per quad of a shoreline. For example, SPLL is used for QHIP/s across quads then 1 output port to be connected to each quad input.
		input  wire        i_refclk_bus_out,             //             i_refclk_bus_out.refclk_bus_out,             Refclk fail status from 1 QHIP in this shoreline which says if the clkrx refclk failure has occured
		output wire        o_shoreline_refclk_fail_stat  // o_shoreline_refclk_fail_stat.shoreline_refclk_fail_stat, Refclk fail status to the user design which says if the clkrx refclk failure has occured
	);
endmodule

