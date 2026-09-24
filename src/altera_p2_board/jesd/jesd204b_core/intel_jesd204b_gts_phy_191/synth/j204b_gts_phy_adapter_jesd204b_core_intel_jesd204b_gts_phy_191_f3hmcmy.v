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



//****************************************
//   Filename       : j204b_gts_phy_adapter.v
//
//   Description    : This module only works as interconnect between jesd204 base core and transceiver
//
//   Limitation     : 
//
//   Note           : Optional 
//***************************************

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

(* tile_ip_sip, component_type="sip" *)
// hw.tcl to replace module name with terp
module j204b_gts_phy_adapter_jesd204b_core_intel_jesd204b_gts_phy_191_f3hmcmy

#(
    parameter L = 1,
    parameter RECONFIG_ADDRESS_WIDTH = 21,
    parameter SYSCLK_DIS = 0,
    parameter l_quad_num = 1,
    parameter BYPASS_EFIFO = 1
)
(

    //--------------------- RX -----------------------------
    input [L-1:0]           rx_ready_s,
    input [L-1:0]           rx_reset_ack_s,
	input 					rxlink_clk,
    input                   j204b_rx_phy_rst_n,
    output wire             phy_rx_reset,
    output wire             phy_rx_reset_ack,

    output wire             phy_rx_ready,

    input [L-1:0]           phy_rx_clkout,      // sysclk/2
    input wire [L-1:0]      phy_rx_clkout2,     // rate div40 clock
    output wire [L-1:0]     phy_rx_coreclkin,
    output wire [L-1:0]     rxphy_clk,

    output wire             rx_cdr_refclk_p,

    input [L-1:0]           phy_rx_is_lockedtodata,
    output wire [L-1:0]     rx_is_lockedtodata,
     
    input [L*80-1:0]        phy_rx_parallel_data,
    output wire [L*40-1:0]  rx_parallel_data,
//------------------ Common -----------------------------
    input                                           pll_refclk
);

    localparam MID_LANE             = L >> 1; // choose mid lane clock
    localparam VALID_BIT            = 38;


    //-------------- rx ----------------------
    assign phy_rx_ready     = &rx_ready_s;
    assign phy_rx_reset_ack = &rx_reset_ack_s;
    assign phy_rx_reset             = ~j204b_rx_phy_rst_n;
    assign rx_cdr_refclk_p          = pll_refclk;

    // rx_parallel_data mapping
    genvar i;
    generate
        for(i=0; i<L; i=i+1) begin: rx_hip_out_data_map
            assign rx_parallel_data[i*40    +: 20] = phy_rx_parallel_data[i*80    +: 20];
            assign rx_parallel_data[i*40+20 +: 20] = phy_rx_parallel_data[i*80+40 +: 20];
        end
    endgenerate

    assign rx_is_lockedtodata   = phy_rx_is_lockedtodata;
    assign phy_rx_coreclkin     = {L{rxlink_clk}};               // user IOPLL feed to coreclkin
    assign rxphy_clk            = phy_rx_clkout2;


endmodule



