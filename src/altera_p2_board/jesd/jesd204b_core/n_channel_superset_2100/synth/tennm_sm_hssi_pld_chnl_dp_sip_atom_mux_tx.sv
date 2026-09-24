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


`resetall
`default_nettype none
`define SIP sip
`define DIRECT direct
`define ONE_HOT_SEL tileip_select_ip_one_hot_port
`define MASTER_CLK_LINE short
`define CLK_USE_ONE(port_name) tileip_mux_write_connected_parameter=`"CONNECTED_``port_name```"

`define PARAM_ATTR(attr_name, param_name) tileip_attr_of_``param_name``=`"``attr_name```"

(*
    mux_sip,
    `PARAM_ATTR(num_ports,              NUM_PORTS),
    `PARAM_ATTR(num_lanes,              NUM_LANES),
    `PARAM_ATTR(src_lane_ndx,           SRC_LANE_INDEX),
    `PARAM_ATTR(clk_master_lane_ndx,    CLK_MASTER_LANE_INDEX),
    `PARAM_ATTR(use_clk_master_lane,    USE_io_hio_user_rx_clk1_clk),
    `PARAM_ATTR(use_clk_master_lane,    USE_io_hio_user_rx_clk2_clk),
    `PARAM_ATTR(use_clk_master_lane,    USE_io_hio_user_tx_clk1_clk),
    `PARAM_ATTR(drive_src_lane,         IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk1_clk),
    `PARAM_ATTR(use_clk_master_lane,    USE_io_hio_user_tx_clk2_clk),
    `PARAM_ATTR(drive_src_lane,         IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk2_clk)
*)
module tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx
#(
// DR Tool needs the default to be a valid configuring, so use this for all Quartus runs, and use extra checks in simulations
`ifdef ALTERA_RESERVED_QIS
    /* num_ports                 */ parameter int                                   NUM_PORTS                                        = 1,
`else
    /* num_ports                 */ parameter int                                   NUM_PORTS                                        = -1,
`endif
    /* num_lanes                 */ parameter int                                   NUM_LANES                                        = -1,
    /* src_lane_ndx              */ parameter int                                   SRC_LANE_INDEX                                   = -1,
    /* clk_master_lane_ndx       */ parameter int                                   CLK_MASTER_LANE_INDEX                            = -1,
    /* use_clk_master_lane       */ parameter int                                   USE_io_hio_user_rx_clk1_clk                      = -1,
    /* use_clk_master_lane       */ parameter int                                   USE_io_hio_user_rx_clk2_clk                      = -1,
    /* use_clk_master_lane       */ parameter int                                   USE_io_hio_user_tx_clk1_clk                      = -1,
    /* drive_src_lane            */ parameter int                                   IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk1_clk     = -1,
    /* use_clk_master_lane       */ parameter int                                   USE_io_hio_user_tx_clk2_clk                      = -1,
    /* drive_src_lane            */ parameter int                                   IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk2_clk     = -1,
                                    parameter bit [NUM_PORTS-1:0]                   CONNECTED_i_hio_det_lat_tx_dl_clk                = '0, // One bit per port set to 1 if connected
                                    parameter bit [NUM_PORTS-1:0]                   CONNECTED_i_hio_det_lat_tx_sclk_gen_clk          = '0  // One bit per port set to 1 if connected
)
(
    (* `SIP,`CLK_USE_ONE(i_hio_det_lat_tx_dl_clk)       *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_tx_dl_clk,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_tx_mux_select,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_tx_sclk_flop,
    (* `SIP,`CLK_USE_ONE(i_hio_det_lat_tx_sclk_gen_clk) *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_tx_sclk_gen_clk,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_tx_trig_flop,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       i_hio_pld_tx_clk_in_row_clk,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][79:0] i_hio_txdata,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][9:0]  i_hio_txdata_direct,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][9:0]  i_hio_txdata_extra,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       i_hio_txdata_fifo_wr_en,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_det_lat_tx_async_dl_sync,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_det_lat_tx_async_pulse,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_det_lat_tx_async_sample_sync,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_det_lat_tx_sclk_sample_sync,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_det_lat_tx_trig_sample_sync,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_rst_ux_octl_pcs_txstatus,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_txdata_fifo_wr_empty,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_txdata_fifo_wr_full,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_txdata_fifo_wr_pempty,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_txdata_fifo_wr_pfull,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_user_tx_clk1_clk,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_user_tx_clk2_clk,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_ux_chnl_refclk_mux,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_ux_tx_ch_ptr_smpl,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       o_hio_xcvrif_tx_latency_pulse,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][79:0] i_hio_uxquad_async_tx,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][79:0] i_hio_uxquad_async_pcie_mux_tx,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0][49:0] o_hio_uxquad_async_tx,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0][99:0] o_hio_rxdata_async_tx,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0][99:0] i_hio_txdata_async_tx,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0][1:0]  tx_lane_current_state,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       tx_alarm,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       sip_am_gen_start,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       sip_eth_unidir_en,
    (* `SIP                                             *) output wire [NUM_PORTS-1:0]       sip_freeze_tx_acknowledge,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       tx_clear_alarm,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       tx_lane_desired_state,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       sip_freeze_tx_SRC_sequence,
    (* `SIP                                             *) input  wire [NUM_PORTS-1:0]       sip_am_gen_2x_ack,
    (* `ONE_HOT_SEL                                     *) input  wire [NUM_PORTS-1:0]       one_hot_sel,
    (* `DIRECT                                          *) output wire                       d_i_hio_det_lat_tx_dl_clk,
    (* `DIRECT                                          *) output wire                       d_i_hio_det_lat_tx_mux_select,
    (* `DIRECT                                          *) output wire                       d_i_hio_det_lat_tx_sclk_flop,
    (* `DIRECT                                          *) output wire                       d_i_hio_det_lat_tx_sclk_gen_clk,
    (* `DIRECT                                          *) output wire                       d_i_hio_det_lat_tx_trig_flop,
    (* `DIRECT                                          *) output wire                       d_i_hio_pld_tx_clk_in_row_clk,
    (* `DIRECT                                          *) output wire [79:0]                d_i_hio_txdata,
    (* `DIRECT                                          *) output wire [9:0]                 d_i_hio_txdata_direct,
    (* `DIRECT                                          *) output wire [9:0]                 d_i_hio_txdata_extra,
    (* `DIRECT                                          *) output wire                       d_i_hio_txdata_fifo_wr_en,
    (* `DIRECT                                          *) input  wire                       d_o_hio_det_lat_tx_async_dl_sync,
    (* `DIRECT                                          *) input  wire                       d_o_hio_det_lat_tx_async_pulse,
    (* `DIRECT                                          *) input  wire                       d_o_hio_det_lat_tx_async_sample_sync,
    (* `DIRECT                                          *) input  wire                       d_o_hio_det_lat_tx_sclk_sample_sync,
    (* `DIRECT                                          *) input  wire                       d_o_hio_det_lat_tx_trig_sample_sync,
    (* `DIRECT                                          *) input  wire                       d_o_hio_rst_ux_octl_pcs_txstatus,
    (* `DIRECT                                          *) input  wire                       d_o_hio_txdata_fifo_wr_empty,
    (* `DIRECT                                          *) input  wire                       d_o_hio_txdata_fifo_wr_full,
    (* `DIRECT                                          *) input  wire                       d_o_hio_txdata_fifo_wr_pempty,
    (* `DIRECT                                          *) input  wire                       d_o_hio_txdata_fifo_wr_pfull,
    (* `DIRECT                                          *) input  wire                       d_o_hio_user_tx_clk1_clk,
    (* `DIRECT                                          *) input  wire                       d_o_hio_user_tx_clk2_clk,
    (* `DIRECT                                          *) input  wire                       d_o_hio_ux_chnl_refclk_mux,
    (* `DIRECT                                          *) input  wire                       d_o_hio_ux_tx_ch_ptr_smpl,
    (* `DIRECT                                          *) input  wire                       d_o_hio_xcvrif_tx_latency_pulse,
    (* `DIRECT                                          *) output wire [79:0]                d_i_hio_uxquad_async_tx,
    (* `DIRECT                                          *) output wire [79:0]                d_i_hio_uxquad_async_pcie_mux_tx,
    (* `DIRECT                                          *) input  wire [49:0]                d_o_hio_uxquad_async_tx,
    (* `DIRECT                                          *) input  wire [99:0]                d_o_hio_rxdata_async_tx,
    (* `DIRECT                                          *) output wire [99:0]                d_i_hio_txdata_async_tx,
    (* `DIRECT                                          *) input  wire [1:0]                 d_tx_lane_current_state,
    (* `DIRECT                                          *) input  wire                       d_tx_alarm,
    (* `DIRECT                                          *) input  wire                       d_sip_am_gen_start,
    (* `DIRECT                                          *) output wire                       d_sip_eth_unidir_en,
    (* `DIRECT                                          *) input  wire                       d_sip_freeze_tx_acknowledge,
    (* `DIRECT                                          *) output wire                       d_tx_clear_alarm,
    (* `DIRECT                                          *) output wire                       d_tx_lane_desired_state,
    (* `DIRECT                                          *) output wire                       d_sip_freeze_tx_SRC_sequence,
    (* `DIRECT                                          *) output wire                       d_sip_am_gen_2x_ack,
    (* `MASTER_CLK_LINE                                 *) inout  wire [NUM_LANES-1:0]       io_hio_user_rx_clk1_clk,
    (* `MASTER_CLK_LINE                                 *) inout  wire [NUM_LANES-1:0]       io_hio_user_rx_clk2_clk,
    (* `MASTER_CLK_LINE                                 *) inout  wire [NUM_LANES-1:0]       io_hio_user_tx_clk1_clk,
    (* `MASTER_CLK_LINE                                 *) inout  wire [NUM_LANES-1:0]       io_hio_user_tx_clk2_clk
);

`ifndef __TILE_IP__

    // -------------------------------------------------------------------------
    // Overview:
    // ---------
    // DR Mux Tx - Implements muxing/demuxing of Tx signals between HIP and SIP.
    // All non-clock signals going from SIPs to HIP are muxed, all non-clock
    // signals from HIP to SIPs are demuxed. These signals are first mapped to
    // packed structs to ease the implementation.
    //
    // Muxing: Will be implemented as an M-bit N:1 mux where N is the number of
    // SIPs, and M is the number of bits from the SIPs to the HIP. Can be
    // implemented directly as a one-hot mux using the selector. This requires a
    // 2N to 1 logic function which is not recognized by Quartus as a mux, and
    // thus wont be restructured. Another option is to encode the one hot
    // selector as binary and then use that as the input to a binary mux, with
    // the last value used to indicate no input selected. This requires a
    // ceil(N+log2(N+1)) to 1 logic function. With fewer inputs this is expected
    // to be the smallest implementation. The select signal does not have timing
    // requirements, so the extra logic on those should not be an issue.
    // Demuxing: For each output one bit in the one hot select signal indicates
    // whether the output is in use and the HIP input signals should be
    // connected to those output SIP signals. This can be implemented as a 2
    // input 1 output logic function.
    //
    // Clocking: No logic can be put on clock signals. For clocks going from the
    // HIP to the SIPs fan out is implemented. The row clock to the HIP needs to
    // come from one of the user clocks from a HIP channel in the bonded group.
    // This is implemented by using the io ports that are connected to all the
    // muxes. When to drive the io pins, and when to use the io pins is
    // controlled by parameters set by the DR tool.
    // -------------------------------------------------------------------------

    // Verify that all parameter values are legal
    if (NUM_PORTS<1) $fatal(1,"Number of ports must be > 0");
    if (NUM_LANES<1) $fatal(1,"Number of lanes must be > 0");
    if ((CLK_MASTER_LANE_INDEX<0)||(CLK_MASTER_LANE_INDEX>=NUM_LANES)) $fatal(1,"Invalid clock master lane index");
    if ((SRC_LANE_INDEX<0)||(SRC_LANE_INDEX>=NUM_LANES)) $fatal(1,"Invalid src lane index");
    if (USE_io_hio_user_rx_clk1_clk                  < 0) $fatal(1,"Illegal value of USE_io_hio_user_rx_clk1_clk");
    if (USE_io_hio_user_rx_clk2_clk                  < 0) $fatal(1,"Illegal value of USE_io_hio_user_rx_clk2_clk");
    if (USE_io_hio_user_tx_clk1_clk                  < 0) $fatal(1,"Illegal value of USE_io_hio_user_tx_clk1_clk");
    if (IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk1_clk < 0) $fatal(1,"Illegal value of IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk1_clk");
    if (USE_io_hio_user_tx_clk2_clk                  < 0) $fatal(1,"Illegal value of USE_io_hio_user_tx_clk2_clk");
    if (IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk2_clk < 0) $fatal(1,"Illegal value of IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk2_clk");
    // Assertions (ports)
    always_comb begin : a_proc
        // Check that mux selector is one hot encoded
        one_hot_sel_a: assert final ($onehot0(one_hot_sel))
            else $error("One hot selector must be one-hot. Multiple bits asserted: '%b'", one_hot_sel);
    end : a_proc

    // No clock muxing can be used, so io pins are implemented, row clock inputs
    // are not needed and left unconnected.
    logic [NUM_PORTS-1:0] i_hio_pld_tx_clk_in_row_clk_nc;
    assign i_hio_pld_tx_clk_in_row_clk_nc = i_hio_pld_tx_clk_in_row_clk;

    typedef struct packed {
        logic        i_hio_det_lat_tx_mux_select;
        logic        i_hio_det_lat_tx_sclk_flop;
        logic        i_hio_det_lat_tx_trig_flop;
        logic [79:0] i_hio_txdata;
        logic [9:0]  i_hio_txdata_direct;
        logic [9:0]  i_hio_txdata_extra;
        logic        i_hio_txdata_fifo_wr_en;
        logic [79:0] i_hio_uxquad_async_tx;
        logic [79:0] i_hio_uxquad_async_pcie_mux_tx;
        logic [99:0] i_hio_txdata_async_tx;
        logic        tx_clear_alarm;
        logic        tx_lane_desired_state_n;
        logic        sip_freeze_tx_SRC_sequence;
        logic        sip_am_gen_2x_ack;
        logic        sip_eth_unidir_en;
    } s2h_s;
    typedef struct packed {
        logic        o_hio_det_lat_tx_async_dl_sync;
        logic        o_hio_det_lat_tx_async_pulse;
        logic        o_hio_det_lat_tx_async_sample_sync;
        logic        o_hio_det_lat_tx_sclk_sample_sync;
        logic        o_hio_det_lat_tx_trig_sample_sync;
        logic        o_hio_rst_ux_octl_pcs_txstatus;
        logic        o_hio_txdata_fifo_wr_empty;
        logic        o_hio_txdata_fifo_wr_full;
        logic        o_hio_txdata_fifo_wr_pempty;
        logic        o_hio_txdata_fifo_wr_pfull;
        logic        o_hio_ux_chnl_refclk_mux;
        logic        o_hio_ux_tx_ch_ptr_smpl;
        logic        o_hio_xcvrif_tx_latency_pulse;
        logic [49:0] o_hio_uxquad_async_tx;
        logic [99:0] o_hio_rxdata_async_tx;
        logic        tx_alarm;
        logic        sip_am_gen_start;
        logic        sip_freeze_tx_acknowledge;
    } h2s_s;

    // Map ports to structs to ease mux implementation -------------------------
    s2h_s sip_s2h[NUM_PORTS];
    h2s_s sip_h2s[NUM_PORTS];
    s2h_s hip_s2h;
    h2s_s hip_h2s;
    for (genvar i=0; i<NUM_PORTS; i++) begin : gen_sip_map
        assign sip_s2h[i] = '{
            i_hio_det_lat_tx_mux_select    : i_hio_det_lat_tx_mux_select[i],
            i_hio_det_lat_tx_sclk_flop     : i_hio_det_lat_tx_sclk_flop[i],
            i_hio_det_lat_tx_trig_flop     : i_hio_det_lat_tx_trig_flop[i],
            i_hio_txdata                   : i_hio_txdata[i],
            i_hio_txdata_direct            : i_hio_txdata_direct[i],
            i_hio_txdata_extra             : i_hio_txdata_extra[i],
            i_hio_txdata_fifo_wr_en        : i_hio_txdata_fifo_wr_en[i],
            i_hio_uxquad_async_tx          : i_hio_uxquad_async_tx[i],
            i_hio_uxquad_async_pcie_mux_tx : i_hio_uxquad_async_pcie_mux_tx[i],
            i_hio_txdata_async_tx          : i_hio_txdata_async_tx[i],
            tx_clear_alarm                 : tx_clear_alarm[i],
            tx_lane_desired_state_n        : ~tx_lane_desired_state[i],
            sip_freeze_tx_SRC_sequence     : sip_freeze_tx_SRC_sequence[i],
            sip_am_gen_2x_ack              : sip_am_gen_2x_ack[i],
            sip_eth_unidir_en              : sip_eth_unidir_en[i]
        };
        assign o_hio_det_lat_tx_async_dl_sync[i]     = sip_h2s[i].o_hio_det_lat_tx_async_dl_sync;
        assign o_hio_det_lat_tx_async_pulse[i]       = sip_h2s[i].o_hio_det_lat_tx_async_pulse;
        assign o_hio_det_lat_tx_async_sample_sync[i] = sip_h2s[i].o_hio_det_lat_tx_async_sample_sync;
        assign o_hio_det_lat_tx_sclk_sample_sync[i]  = sip_h2s[i].o_hio_det_lat_tx_sclk_sample_sync;
        assign o_hio_rst_ux_octl_pcs_txstatus[i]     = sip_h2s[i].o_hio_rst_ux_octl_pcs_txstatus;
        assign o_hio_det_lat_tx_trig_sample_sync[i]  = sip_h2s[i].o_hio_det_lat_tx_trig_sample_sync;
        assign o_hio_txdata_fifo_wr_full[i]          = sip_h2s[i].o_hio_txdata_fifo_wr_full;
        assign o_hio_txdata_fifo_wr_empty[i]         = sip_h2s[i].o_hio_txdata_fifo_wr_empty;
        assign o_hio_txdata_fifo_wr_pempty[i]        = sip_h2s[i].o_hio_txdata_fifo_wr_pempty;
        assign o_hio_txdata_fifo_wr_pfull[i]         = sip_h2s[i].o_hio_txdata_fifo_wr_pfull;
        assign o_hio_ux_chnl_refclk_mux[i]           = sip_h2s[i].o_hio_ux_chnl_refclk_mux;
        assign o_hio_ux_tx_ch_ptr_smpl[i]            = sip_h2s[i].o_hio_ux_tx_ch_ptr_smpl;
        assign o_hio_xcvrif_tx_latency_pulse[i]      = sip_h2s[i].o_hio_xcvrif_tx_latency_pulse;
        assign o_hio_uxquad_async_tx[i]              = sip_h2s[i].o_hio_uxquad_async_tx;
        assign o_hio_rxdata_async_tx[i]              = sip_h2s[i].o_hio_rxdata_async_tx;
        assign tx_lane_current_state[i]              = d_tx_lane_current_state; //always send current state so rst_ack is correct at startup
        assign tx_alarm[i]                           = sip_h2s[i].tx_alarm;
        assign sip_am_gen_start[i]                   = sip_h2s[i].sip_am_gen_start;
        assign sip_freeze_tx_acknowledge[i]          = sip_h2s[i].sip_freeze_tx_acknowledge;
    end : gen_sip_map
    assign d_i_hio_det_lat_tx_mux_select    = hip_s2h.i_hio_det_lat_tx_mux_select;
    assign d_i_hio_det_lat_tx_sclk_flop     = hip_s2h.i_hio_det_lat_tx_sclk_flop;
    assign d_i_hio_det_lat_tx_trig_flop     = hip_s2h.i_hio_det_lat_tx_trig_flop;
    assign d_i_hio_txdata                   = hip_s2h.i_hio_txdata;
    assign d_i_hio_txdata_direct            = hip_s2h.i_hio_txdata_direct;
    assign d_i_hio_txdata_extra             = hip_s2h.i_hio_txdata_extra;
    assign d_i_hio_txdata_fifo_wr_en        = hip_s2h.i_hio_txdata_fifo_wr_en;
    assign d_i_hio_uxquad_async_tx          = hip_s2h.i_hio_uxquad_async_tx;
    assign d_i_hio_uxquad_async_pcie_mux_tx = hip_s2h.i_hio_uxquad_async_pcie_mux_tx;
    assign d_i_hio_txdata_async_tx          = hip_s2h.i_hio_txdata_async_tx;
    assign d_tx_clear_alarm                 = hip_s2h.tx_clear_alarm;
    assign d_tx_lane_desired_state          = ~hip_s2h.tx_lane_desired_state_n;
    assign d_sip_freeze_tx_SRC_sequence     = hip_s2h.sip_freeze_tx_SRC_sequence;
    assign d_sip_am_gen_2x_ack              = hip_s2h.sip_am_gen_2x_ack;
    assign d_sip_eth_unidir_en              = hip_s2h.sip_eth_unidir_en;
    assign hip_h2s = '{
        o_hio_det_lat_tx_async_dl_sync     : d_o_hio_det_lat_tx_async_dl_sync,
        o_hio_det_lat_tx_async_pulse       : d_o_hio_det_lat_tx_async_pulse,
        o_hio_det_lat_tx_async_sample_sync : d_o_hio_det_lat_tx_async_sample_sync,
        o_hio_det_lat_tx_sclk_sample_sync  : d_o_hio_det_lat_tx_sclk_sample_sync,
        o_hio_det_lat_tx_trig_sample_sync  : d_o_hio_det_lat_tx_trig_sample_sync,
        o_hio_rst_ux_octl_pcs_txstatus     : d_o_hio_rst_ux_octl_pcs_txstatus,
        o_hio_txdata_fifo_wr_empty         : d_o_hio_txdata_fifo_wr_empty,
        o_hio_txdata_fifo_wr_full          : d_o_hio_txdata_fifo_wr_full,
        o_hio_txdata_fifo_wr_pempty        : d_o_hio_txdata_fifo_wr_pempty,
        o_hio_txdata_fifo_wr_pfull         : d_o_hio_txdata_fifo_wr_pfull,
        o_hio_ux_chnl_refclk_mux           : d_o_hio_ux_chnl_refclk_mux,
        o_hio_ux_tx_ch_ptr_smpl            : d_o_hio_ux_tx_ch_ptr_smpl,
        o_hio_xcvrif_tx_latency_pulse      : d_o_hio_xcvrif_tx_latency_pulse,
        o_hio_uxquad_async_tx              : d_o_hio_uxquad_async_tx,
        o_hio_rxdata_async_tx              : d_o_hio_rxdata_async_tx,
        tx_alarm                           : d_tx_alarm,
        sip_am_gen_start                   : d_sip_am_gen_start,
        sip_freeze_tx_acknowledge          : d_sip_freeze_tx_acknowledge
    };

    // Mux S2H signals ---------------------------------------------------------
    localparam bit MUX_BIN_SEL = 1'b1;
    if (NUM_PORTS == 1) begin : gen_mux_s2h_1
        assign hip_s2h = (one_hot_sel[0]) ? sip_s2h[0] : '0;
    end else begin : gen_mux_s2h_n
        if (MUX_BIN_SEL) begin : gen_mux_bin_sel
            (* keep *) logic [$clog2($bits(one_hot_sel)+1)-1:0] sel;
            always_comb begin
                s2h_s sip_s2h_full[2**$clog2(NUM_PORTS+1)];
                sel = '1;
                foreach (one_hot_sel[i])
                    if (one_hot_sel[i]) begin
                        sel = $bits(sel)'(i);
                    end
                sip_s2h_full = '{default: '0};
                foreach (sip_s2h[i])
                    sip_s2h_full[i] = sip_s2h[i];
                hip_s2h = sip_s2h_full[sel];
            end
        end else begin : gen_mux_one_hot
            s2h_s sip_s2h_mask[NUM_PORTS];
            for (genvar i=0; i<NUM_PORTS; i++) begin : gen_mux_s2h_mask
                assign sip_s2h_mask[i] = {$bits(sip_s2h[i]){one_hot_sel[i]}} & sip_s2h[i];
            end : gen_mux_s2h_mask
            always_comb begin : s2h_mux_proc
                hip_s2h = '0;
                foreach (sip_s2h_mask[i])
                    hip_s2h |= sip_s2h_mask[i];
            end : s2h_mux_proc
        end : gen_mux_one_hot
    end : gen_mux_s2h_n

    // Demux H2S signals ---------------------------------------------------------
    always_comb foreach (sip_h2s[i]) sip_h2s[i] = (one_hot_sel[i]) ? hip_h2s : '0;

    // Clock fanouts -----------------------------------------------------------
    // Clocks from HIP to SIP cannot have logic on them, so implement fanout
    assign o_hio_user_tx_clk1_clk = '{default: d_o_hio_user_tx_clk1_clk};
    assign o_hio_user_tx_clk2_clk = '{default: d_o_hio_user_tx_clk2_clk};

    // DL Clocks ---------------------------------------------------------------
    // For the deterministic latency clocks, avoid logic on the signal
    // pick one and always use that. Must pick one that is driven by a valid
    // clock, DR Tool indicates which input bits a driven, pick anyone of them
    logic [NUM_PORTS-1:0] i_hio_det_lat_tx_dl_clk_nc;
    logic [NUM_PORTS-1:0] i_hio_det_lat_tx_sclk_gen_clk_nc;
    logic d_i_hio_det_lat_tx_dl_clk_int;
    logic d_i_hio_det_lat_tx_sclk_gen_clk_int;
    always_comb begin : dl_clk_proc
        i_hio_det_lat_tx_dl_clk_nc = i_hio_det_lat_tx_dl_clk;
        d_i_hio_det_lat_tx_dl_clk_int = 1'b0;
        foreach (CONNECTED_i_hio_det_lat_tx_dl_clk[i])
            if (CONNECTED_i_hio_det_lat_tx_dl_clk[i]) begin
                d_i_hio_det_lat_tx_dl_clk_int = i_hio_det_lat_tx_dl_clk[i];
                i_hio_det_lat_tx_dl_clk_nc[i] = 1'b0;
            end
        i_hio_det_lat_tx_sclk_gen_clk_nc = i_hio_det_lat_tx_sclk_gen_clk;
        d_i_hio_det_lat_tx_sclk_gen_clk_int = 1'b0;
        foreach (CONNECTED_i_hio_det_lat_tx_sclk_gen_clk[i])
            if (CONNECTED_i_hio_det_lat_tx_sclk_gen_clk[i]) begin
                d_i_hio_det_lat_tx_sclk_gen_clk_int = i_hio_det_lat_tx_sclk_gen_clk[i];
                i_hio_det_lat_tx_sclk_gen_clk_nc[i] = 1'b0;
            end
    end : dl_clk_proc
    assign d_i_hio_det_lat_tx_dl_clk = d_i_hio_det_lat_tx_dl_clk_int;
    assign d_i_hio_det_lat_tx_sclk_gen_clk = d_i_hio_det_lat_tx_sclk_gen_clk_int;

    // Clocking ----------------------------------------------------------------
    if (CLK_MASTER_LANE_INDEX == SRC_LANE_INDEX) begin : gen_clk_drv
        if (IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk1_clk) begin : gen_clk_drv_tx1
            assign io_hio_user_tx_clk1_clk[SRC_LANE_INDEX] = d_o_hio_user_tx_clk1_clk;
        end : gen_clk_drv_tx1
        if (IS_MASTER_CLK_SOURCE_io_hio_user_tx_clk2_clk) begin : gen_clk_drv_tx2
            assign io_hio_user_tx_clk2_clk[SRC_LANE_INDEX] = d_o_hio_user_tx_clk2_clk;
        end : gen_clk_drv_tx2
    end : gen_clk_drv
    assign d_i_hio_pld_tx_clk_in_row_clk   = i_hio_pld_tx_clk_in_row_clk[0];

`endif // ifndef __TILE_IP__

endmodule : tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx
`undef PARAM_ATTR
`undef CLK_USE_ONE
`undef MASTER_CLK_LINE
`undef DIRECT
`undef ONE_HOT_SEL
`undef SIP
`default_nettype wire
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "CYTUP98cokYF5/KnH5U9wpmsMebvw7PjbSFb6M3lY/qsVIz6jKyEvq+ZpFxx2uhEXGlRc0Zdjj1y1wmOppfPxVoYbzB4MDz5WMEEIHxYqLzLPRix146tWtBVedm6MD12cvLP4zUSq8euGs2Vl4XTnYwLn9yJjVujHm3F6Sq+aoE+e5SR+I7FPSr+JWVgOvlOEHDWwXnTb8RANIhljDHm3WWpU5Wvb9fUSAR0qErfFv8G/7KTuZqoEEisx/AFdMm+B8RebaIz4dNGGwQdgBJ/3PM/V7kLUB3mwwoVEye+SfMg5IBMMRyDBvYC+GtsguUMU35CA0ebyBg/0d1dnw1ediV0Itzc/tIRNzrS5yNqO2QggqJxuQRb386eLQTkDvCvQsz3yaL0CCHufmx1cEizot8n2c5CzmLhFsiZvCTKB9Hq57a464MgD2VuHaPicPznegeb7f6X73OJ686V/7gEttPOrL3eJBbtTfxQafTrf3P90HnVQPJVIIlNt73H7Xf7feseXtwQrpQkK/dNEQdMzXbi6eDxvORBV7Lz4g7dsb0arEe/b25K6vBIrfkiNNlwJhAC3IPawDzbw+Jl11Po16rlvyhvmpbKn41onzxcUzSgOB5LF3exJQeitxfkzJHREbPkq9SrTWt9tdBdbXivWiPsTfvO1UgZKx9eeiELISrEmzODzq7ga/7WMmgb1YOUiO3P+/nLXr1tUp5uNtW9VV69+jJraOL9JmL8i7e0/z4HsAqgH1sbXSPoSs+A5crQPxULkDoMx3QSuWUzVk5qUBvmXycHCV06CvG2cWh+a5dcsMtnHmj9YR+Uf7bAIdcLEIwrYNhZcUhDkkdjTTlPGLJF09XotHMqSrTcDcMynp6lzW/HJ5j8Plk/+tJ/lmLlQSzTzlWDuo36C0oB78suxgyH8IUZJzmUHRWeSVgtF049TwjSLgTFw2XR+w1kBYZk/nypg8ew7GKga1cUcU9QwtHbfuYoDZT9ciVmBEFQB7wI5qWI1v494Xia+mkDuxp4"
`endif