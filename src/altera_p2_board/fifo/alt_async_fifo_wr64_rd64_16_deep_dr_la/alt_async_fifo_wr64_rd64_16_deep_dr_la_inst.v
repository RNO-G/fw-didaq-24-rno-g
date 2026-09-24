	alt_async_fifo_wr64_rd64_16_deep_dr_la u0 (
		.data    (_connected_to_data_),    //   input,  width = 64,  fifo_input.datain
		.wrreq   (_connected_to_wrreq_),   //   input,   width = 1,            .wrreq
		.rdreq   (_connected_to_rdreq_),   //   input,   width = 1,            .rdreq
		.wrclk   (_connected_to_wrclk_),   //   input,   width = 1,            .wrclk
		.rdclk   (_connected_to_rdclk_),   //   input,   width = 1,            .rdclk
		.aclr    (_connected_to_aclr_),    //   input,   width = 1,            .aclr
		.q       (_connected_to_q_),       //  output,  width = 64, fifo_output.dataout
		.rdusedw (_connected_to_rdusedw_), //  output,   width = 4,            .rdusedw
		.wrusedw (_connected_to_wrusedw_), //  output,   width = 4,            .wrusedw
		.rdfull  (_connected_to_rdfull_),  //  output,   width = 1,            .rdfull
		.rdempty (_connected_to_rdempty_), //  output,   width = 1,            .rdempty
		.wrfull  (_connected_to_wrfull_)   //  output,   width = 1,            .wrfull
	);

