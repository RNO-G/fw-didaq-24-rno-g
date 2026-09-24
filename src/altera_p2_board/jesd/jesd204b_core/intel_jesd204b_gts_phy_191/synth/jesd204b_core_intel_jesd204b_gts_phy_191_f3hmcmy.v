// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module jesd204b_core_intel_jesd204b_gts_phy_191_f3hmcmy #(
    parameter   L                           = 4,
    parameter   RECONFIG_ADDRESS_WIDTH      = 18, // 18 + $clog2(L)
    parameter   l_quad_num                  = (L == 6 || L == 8) ? 2 : 1,
    parameter   DEVICE_FAMILY               = "Agilex 7",
    parameter   clocking_mode               = "PMA",
    parameter   TX_EFIFO_PIPE_EN            = 0,
    parameter   RX_EFIFO_PIPE_EN            = 0,
    parameter   PCS_CONFIG                  = "JESD_PCS_CFG2",
    parameter   PMA_WIDTH                   = 40,
    parameter   SER_SIZE                    = 4,
    parameter   ALIGNMENT_PATTERN           = 658812
)(
    //-------------------------RX ------------------------------------
    input wire                      jesd204_rx_rst_n,
    input wire                      jesd204_rx_avs_clk,
    input wire                      jesd204_rx_avs_rst_n,
    input wire                      rxlink_clk,
    input wire [L-1:0]              rx_serial_data,
    input wire [L-1:0]              rx_serial_data_n,
    input wire                      rx_csr_bit_reversal,
    input wire                      rx_csr_byte_reversal,
    input wire [L-1:0]              rx_csr_lane_polarity,
    input wire [L-1:0]              rx_csr_lane_powerdown,
    input wire [L-1:0]              patternalign_en,
    
    output wire                     jesd204_rx_rst_ack_n,
    output wire [L-1:0]             xcvr_cdr_locked_avs_sync,
    output wire [L-1:0]             rxphy_clk,
    output wire                     rxlink_rst_n,
    output wire [L*32-1:0]          jesd204_rx_pcs_data, 
    output wire [L*4-1:0]           jesd204_rx_pcs_kchar_data, 
    output wire [L*4-1:0]           jesd204_rx_pcs_errdetect,
    output wire [L*4-1:0]           jesd204_rx_pcs_disperr,  
    output wire [L-1:0]             jesd204_rx_pcs_data_valid,
    output wire                     jesd204_rx_out_of_reset,
    //--------------------------- common ------------------------
    input                                           pll_refclk,
    input  [l_quad_num-1:0]                         pma_cu_clk,
    input  [L-1:0]                                  src_sss_grant,
    output [L-1:0]                                  src_sss_req,
    output wire                                     o_refclk_bus_out
);

    localparam SYSCLK_DIS   = (clocking_mode == "syspll") ? 0 : 1;
    localparam BYPASS_EFIFO = (clocking_mode == "syspll") ? 0 : 1;
    //---------------- rx ---------------------
    wire                            phy_rx_reset_ack;
    wire                            phy_rx_ready;
    wire [L-1:0]                    xcvr_cdr_locked;
    wire                            rx_rst_n;
    wire                            j204b_rx_phy_rst_n;
    wire                            rx_cdr_refclk_p;
    wire                            phy_rx_reset;
    wire [L-1:0]                    phy_rx_coreclkin;
    wire [L-1:0]                    phy_rx_clkout;
//    wire [L-1:0]                    phy_rx_clkout2;
    wire [L-1:0]                    phy_rx_is_lockedtodata;
    wire [L*80-1:0]                 phy_rx_parallel_data;
    wire [L*40-1:0]                 rx_parallel_data;
    wire                            rxlink_rst_n_dup;

    wire [L-1:0]                    rx_reset_ack_s;
    wire [L-1:0]                    rx_ready_s;

        jesd204b_core_intel_jesd204b_gts_phy_intel_directphy_gts_191_x7bynya rx_0_phy_inst (
            .i_rx_cdr_refclk_p          (rx_cdr_refclk_p),
            .i_rx_reset                 (phy_rx_reset),
            .o_rx_reset_ack             (rx_reset_ack_s[0]),
            .o_rx_ready                 (rx_ready_s[0]),
            .i_rx_coreclkin             (phy_rx_coreclkin[0]),
            .o_rx_clkout                (phy_rx_clkout[0]),
//            .o_rx_clkout2               (phy_rx_clkout2[0]),
            .i_rx_serial_data           (rx_serial_data[0]),
            .i_rx_serial_data_n         (rx_serial_data_n[0]),
            .o_rx_is_lockedtodata       (phy_rx_is_lockedtodata[0]),
            .o_rx_is_lockedtoref        (),
            .o_rx_parallel_data         (phy_rx_parallel_data[79:0]),
            .o_refclk_bus_out           (o_refclk_bus_out),
            .i_src_rs_grant             (src_sss_grant[0]),
            .o_src_rs_req               (src_sss_req[0]),
            .i_pma_cu_clk               (pma_cu_clk[0])
        );
        jesd204b_core_intel_jesd204b_gts_phy_intel_directphy_gts_191_lvsxkwq rx_1_phy_inst (
            .i_rx_cdr_refclk_p          (rx_cdr_refclk_p),
            .i_rx_reset                 (phy_rx_reset),
            .o_rx_reset_ack             (rx_reset_ack_s[1]),
            .o_rx_ready                 (rx_ready_s[1]),
            .i_rx_coreclkin             (phy_rx_coreclkin[1]),
            .o_rx_clkout                (phy_rx_clkout[1]),
//            .o_rx_clkout2               (phy_rx_clkout2[1]),
            .i_rx_serial_data           (rx_serial_data[1]),
            .i_rx_serial_data_n         (rx_serial_data_n[1]),
            .o_rx_is_lockedtodata       (phy_rx_is_lockedtodata[1]),
            .o_rx_is_lockedtoref        (),
            .o_rx_parallel_data         (phy_rx_parallel_data[159:80]),
            .i_src_rs_grant             (src_sss_grant[1]),
            .o_src_rs_req               (src_sss_req[1]),
            .i_pma_cu_clk               (pma_cu_clk[0])
        );

    j204b_gts_phy_adapter_jesd204b_core_intel_jesd204b_gts_phy_191_f3hmcmy #(
        .L                          (L),
        .RECONFIG_ADDRESS_WIDTH     (RECONFIG_ADDRESS_WIDTH),
        .SYSCLK_DIS                 (SYSCLK_DIS),
        .BYPASS_EFIFO               (BYPASS_EFIFO),
        .l_quad_num                 (l_quad_num)
    ) phy_adapter_inst (
            //------------------------------ rx -----------------------------------------------
            .rx_ready_s                 (rx_ready_s),
            .rx_reset_ack_s             (rx_reset_ack_s),
            .rxlink_clk                 (rxlink_clk),
            .j204b_rx_phy_rst_n         (j204b_rx_phy_rst_n),
            .phy_rx_reset               (phy_rx_reset),
            .phy_rx_reset_ack           (phy_rx_reset_ack),
            .phy_rx_ready               (phy_rx_ready),
            .phy_rx_clkout              (phy_rx_clkout),
            .phy_rx_clkout2             ({L{1'b0}}),
            .phy_rx_coreclkin           (phy_rx_coreclkin),
            .rxphy_clk                  (rxphy_clk),
            .rx_cdr_refclk_p            (rx_cdr_refclk_p),
            .phy_rx_is_lockedtodata     (phy_rx_is_lockedtodata),
            .rx_is_lockedtodata         (xcvr_cdr_locked),
            .phy_rx_parallel_data       (phy_rx_parallel_data),
            .rx_parallel_data           (rx_parallel_data),
            //----------------- common ---------------------------
            .pll_refclk                                         (pll_refclk)
    );



    j204b_gts_sip_rst_seq_rx #(
        .L                              (L),
        .SYSCLK_DIS                     (SYSCLK_DIS)
    ) rst_seq_rx_inst (
        .j204b_rst_n                    (jesd204_rx_rst_n),
        .j204b_avs_clk                  (jesd204_rx_avs_clk),
        .j204b_avs_rst_n                (jesd204_rx_avs_rst_n),
        .j204b_rst_ack_n                (jesd204_rx_rst_ack_n),
        .phy_rx_reset_ack               (phy_rx_reset_ack),
        .phy_rx_ready                   (phy_rx_ready),
        .xcvr_cdr_locked_avs_sync       (xcvr_cdr_locked_avs_sync),
        .xcvr_cdr_locked                (xcvr_cdr_locked),
        .user_rx_rst_n                  (),
        .rx_rst_n                       (rx_rst_n),
        .j204b_rx_phy_rst_n             (j204b_rx_phy_rst_n),
        .ready                          (),
        .j204b_rx_out_of_reset          (jesd204_rx_out_of_reset)
    );

    // reset control synchronize to link_clk
    j204b_gts_rstctrl inst_rx_rstctrl (
        .link_clk   (rxlink_clk),
        .rst_n      (rx_rst_n),
        .link_rst_n (rxlink_rst_n)
    );
    
    j204b_gts_pipeline #(
        .DEPTH_PIPE (3)
    ) inst_rx_pipeline (
        .clk  (rxlink_clk),
        .din  (rxlink_rst_n),
        .dout (rxlink_rst_n_dup)
    );

    j204b_gts_rx_mlpcs #(
        .DEVICE_FAMILY          (DEVICE_FAMILY),
        .L                      (L),
        .PCS_CONFIG               (PCS_CONFIG),
        .PMA_WIDTH                (PMA_WIDTH),
        .SER_SIZE                 (SER_SIZE),
        .ALIGNMENT_PATTERN        (ALIGNMENT_PATTERN)
    ) j204b_gts_rx_mlpcs_inst (
        .rxlink_clk                     (rxlink_clk),
        .rxphy_clk                      (rxphy_clk),
        .rxlink_rst_n                   (rxlink_rst_n_dup),
        .rx_parallel_data               (rx_parallel_data),
        .phy_kchar_data                 ({L{4'b0}}),
        .phy_code_err                   ({L{4'b0}}),
        .phy_rd_err                     ({L{4'b0}}),
        .phy_sync_status                ({L{4'b0}}),
        .csr_lane_polarity              (rx_csr_lane_polarity),
        .csr_bit_reversal               (rx_csr_bit_reversal),
        .csr_byte_reversal              (rx_csr_byte_reversal),
        .patternalign_en                (patternalign_en),
        .csr_lane_powerdown             (rx_csr_lane_powerdown),
        .jesd204_rx_pcs_data            (jesd204_rx_pcs_data),
        .jesd204_rx_pcs_kchar_data      (jesd204_rx_pcs_kchar_data),
        .jesd204_rx_pcs_errdetect       (jesd204_rx_pcs_errdetect),
        .jesd204_rx_pcs_disperr         (jesd204_rx_pcs_disperr),
        .jesd204_rx_pcs_data_valid      (jesd204_rx_pcs_data_valid),
        .phy_lane_polarity              (),
        .phy_bit_reversal               (),
        .phy_byte_reversal              (),
        .phy_patternalign_en            (),
        .csr_pcfifo_full                (),
        .csr_pcfifo_empty               ()
    );

endmodule




