module jesd204b_core (
		input  wire        pma_cu_clk,                     //                     pma_cu_clk.clk
		input  wire        pll_refclk,                     //                     pll_refclk.clk
		input  wire [1:0]  src_sss_grant,                  //                  src_sss_grant.src_rs_grant
		output wire [1:0]  src_sss_req,                    //                    src_sss_req.src_rs_req
		output wire        o_refclk_bus_out,               //               o_refclk_bus_out.refclk_bus_out
		input  wire        jesd204_rx_rst_n,               //               jesd204_rx_rst_n.reset_n
		input  wire [1:0]  rx_serial_data,                 //                 rx_serial_data.export
		input  wire [1:0]  rx_serial_data_n,               //               rx_serial_data_n.export
		output wire [1:0]  rxphy_clk,                      //                      rxphy_clk.export
		output wire        jesd204_rx_rst_ack_n,           //           jesd204_rx_rst_ack_n.export
		output wire [1:0]  rx_locked_to_data,              //              rx_locked_to_data.export
		output wire        jesd204_rx_out_of_reset,        //        jesd204_rx_out_of_reset.export
		input  wire        jesd204_rx_avs_chipselect,      //                 jesd204_rx_avs.chipselect
		input  wire [9:0]  jesd204_rx_avs_address,         //                               .address
		input  wire        jesd204_rx_avs_read,            //                               .read
		output wire [31:0] jesd204_rx_avs_readdata,        //                               .readdata
		output wire        jesd204_rx_avs_waitrequest,     //                               .waitrequest
		input  wire        jesd204_rx_avs_write,           //                               .write
		input  wire [31:0] jesd204_rx_avs_writedata,       //                               .writedata
		output wire        jesd204_rx_int,                 //                 jesd204_rx_int.irq
		output wire [63:0] jesd204_rx_link_data,           //                jesd204_rx_link.data
		output wire        jesd204_rx_link_valid,          //                               .valid
		input  wire        jesd204_rx_link_ready,          //                               .ready
		output wire        jesd204_rx_dev_sync_n,          //          jesd204_rx_dev_sync_n.export
		input  wire        jesd204_rx_sysref,              //              jesd204_rx_sysref.export
		output wire [3:0]  jesd204_rx_somf,                //                jesd204_rx_somf.export
		output wire        jesd204_rx_csr_hd,              //              jesd204_rx_csr_hd.export
		output wire [1:0]  jesd204_rx_csr_cs,              //              jesd204_rx_csr_cs.export
		output wire [4:0]  jesd204_rx_csr_l,               //               jesd204_rx_csr_l.export
		output wire [4:0]  jesd204_rx_csr_k,               //               jesd204_rx_csr_k.export
		output wire [4:0]  jesd204_rx_csr_n,               //               jesd204_rx_csr_n.export
		output wire [4:0]  jesd204_rx_csr_np,              //              jesd204_rx_csr_np.export
		output wire [4:0]  jesd204_rx_csr_s,               //               jesd204_rx_csr_s.export
		output wire [4:0]  jesd204_rx_csr_cf,              //              jesd204_rx_csr_cf.export
		output wire [7:0]  jesd204_rx_csr_f,               //               jesd204_rx_csr_f.export
		output wire [7:0]  jesd204_rx_csr_m,               //               jesd204_rx_csr_m.export
		input  wire        jesd204_rx_alldev_lane_aligned, // jesd204_rx_alldev_lane_aligned.export
		output wire        jesd204_rx_dev_lane_aligned,    //    jesd204_rx_dev_lane_aligned.export
		output wire [3:0]  jesd204_rx_sof,                 //                 jesd204_rx_sof.export
		input  wire        jesd204_rx_frame_error,         //         jesd204_rx_frame_error.export
		output wire [3:0]  csr_rx_testmode,                //                csr_rx_testmode.export
		input  wire [63:0] jesd204_rx_dlb_data,            //            jesd204_rx_dlb_data.export
		input  wire [1:0]  jesd204_rx_dlb_data_valid,      //      jesd204_rx_dlb_data_valid.export
		input  wire [7:0]  jesd204_rx_dlb_kchar_data,      //      jesd204_rx_dlb_kchar_data.export
		input  wire [7:0]  jesd204_rx_dlb_errdetect,       //       jesd204_rx_dlb_errdetect.export
		input  wire [7:0]  jesd204_rx_dlb_disperr,         //         jesd204_rx_dlb_disperr.export
		input  wire        jesd204_rx_avs_rst_n,           //           jesd204_rx_avs_rst_n.reset_n
		input  wire        jesd204_rx_avs_clk,             //             jesd204_rx_avs_clk.clk
		input  wire        rxlink_clk                      //                     rxlink_clk.clk,           Clock Input
	);
endmodule

