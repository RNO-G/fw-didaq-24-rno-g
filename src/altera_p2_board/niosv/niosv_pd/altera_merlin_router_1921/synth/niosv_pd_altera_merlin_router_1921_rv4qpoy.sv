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



// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/25.1.1/ip/iconnect/merlin/altera_merlin_router/altera_merlin_router.sv.terp#1 $
// $Revision: #1 $
// $Date: 2025/04/24 $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// the address.
//
// Also sets the binary-encoded destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

// ------------------------------------------
// Generation parameters:
//    decoder_type            0 (address decoder)
//    default_channel         9
//    default_destid          8
//    default_rd_channel      -1
//    default_wr_channel      -1
//    has_default_slave       0
//    memory_aliasing_decode  0
//    output_name             niosv_pd_altera_merlin_router_1921_rv4qpoy
//    pkt_addr_h              67
//    pkt_addr_l              36
//    pkt_dest_id_h           94
//    pkt_dest_id_l           91
//    pkt_protection_h        98
//    pkt_protection_l        96
//    pkt_trans_read          71
//    pkt_trans_write         70
//    slaves_info             8:1000000000:0x40000:0x60000:both:1:0:0:1,3:0100000000:0x80000:0xa0000:both:1:0:0:1,9:0010000000:0x1000000:0x1000020:both:1:0:0:1,1:0000010000:0x1010000:0x1010400:both:1:0:0:1,2:0000001000:0x1020000:0x1020400:both:1:0:0:1,0:0000000100:0x1080000:0x10a0000:both:1:0:0:1,5:0000000010:0x10a0000:0x10a1000:both:1:0:0:1,6:0000000001:0x10b0000:0x10b1000:both:1:0:0:1,4:0000100000:0x10c0000:0x10c0040:both:1:0:0:1,7:0001000000:0x10d0000:0x10d0020:both:1:0:0:1
//    st_channel_w            10
//    st_data_w               162
// ------------------------------------------

module niosv_pd_altera_merlin_router_1921_rv4qpoy_default_decode
  #(
     parameter DEFAULT_CHANNEL = 9,
               DEFAULT_WR_CHANNEL = -1,
               DEFAULT_RD_CHANNEL = -1,
               DEFAULT_DESTID = 8 
   )
  (output [94 - 91 : 0] default_destination_id,
   output [10-1 : 0] default_wr_channel,
   output [10-1 : 0] default_rd_channel,
   output [10-1 : 0] default_src_channel
  );

  assign default_destination_id = 
    DEFAULT_DESTID[94 - 91 : 0];

  generate
    if (DEFAULT_CHANNEL == -1) begin : no_default_channel_assignment
      assign default_src_channel = '0;
    end
    else begin : default_channel_assignment
      assign default_src_channel = 10'b1 << DEFAULT_CHANNEL;
    end
  endgenerate

  generate
    if (DEFAULT_RD_CHANNEL == -1) begin : no_default_rw_channel_assignment
      assign default_wr_channel = '0;
      assign default_rd_channel = '0;
    end
    else begin : default_rw_channel_assignment
      assign default_wr_channel = 10'b1 << DEFAULT_WR_CHANNEL;
      assign default_rd_channel = 10'b1 << DEFAULT_RD_CHANNEL;
    end
  endgenerate

endmodule


module niosv_pd_altera_merlin_router_1921_rv4qpoy
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [162-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [162-1    : 0] src_data,
    output reg [10-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 67;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 94;
    localparam PKT_DEST_ID_L = 91;
    localparam PKT_PROTECTION_H = 98;
    localparam PKT_PROTECTION_L = 96;
    localparam ST_DATA_W = 162;
    localparam ST_CHANNEL_W = 10;
    localparam DECODER_TYPE = 0;

    localparam PKT_TRANS_WRITE = 70;
    localparam PKT_TRANS_READ  = 71;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;



    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 64'h10d0020;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;

    localparam REAL_ADDRESS_RANGE = OPTIMIZED_ADDR_H - PKT_ADDR_L;

      reg [PKT_ADDR_W-1 : 0] address;
      always @* begin
        address = {PKT_ADDR_W{1'b0}};
        address [REAL_ADDRESS_RANGE:0] = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];
      end   

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;
    wire [PKT_DEST_ID_W-1:0] default_destid;
    wire [10-1 : 0] default_src_channel;






    niosv_pd_altera_merlin_router_1921_rv4qpoy_default_decode the_default_decode(
      .default_destination_id (default_destid),
      .default_wr_channel   (),
      .default_rd_channel   (),
      .default_src_channel  (default_src_channel)
    );

    always @* begin
        src_data    = sink_data;
        src_channel = default_src_channel;
        src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = default_destid;

        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------

        // slave 0: [0x40000, 0x60000) : sel [24:17]
        if ( {address[24:17],{17 {1'b0}}} == 25'h40000   ) begin
            src_channel = 10'b1000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
        end

        // slave 1: [0x80000, 0xa0000) : sel [24:17]
        if ( {address[24:17],{17 {1'b0}}} == 25'h80000   ) begin
            src_channel = 10'b0100000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
        end

        // slave 2: [0x1000000, 0x1000020) : sel [24:5]
        if ( {address[24:5],{5 {1'b0}}} == 25'h1000000   ) begin
            src_channel = 10'b0010000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 9;
        end

        // slave 3: [0x1010000, 0x1010400) : sel [24:10]
        if ( {address[24:10],{10 {1'b0}}} == 25'h1010000   ) begin
            src_channel = 10'b0000010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
        end

        // slave 4: [0x1020000, 0x1020400) : sel [24:10]
        if ( {address[24:10],{10 {1'b0}}} == 25'h1020000   ) begin
            src_channel = 10'b0000001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
        end

        // slave 5: [0x1080000, 0x10a0000) : sel [24:17]
        if ( {address[24:17],{17 {1'b0}}} == 25'h1080000   ) begin
            src_channel = 10'b0000000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 0;
        end

        // slave 6: [0x10a0000, 0x10a1000) : sel [24:12]
        if ( {address[24:12],{12 {1'b0}}} == 25'h10a0000   ) begin
            src_channel = 10'b0000000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
        end

        // slave 7: [0x10b0000, 0x10b1000) : sel [24:12]
        if ( {address[24:12],{12 {1'b0}}} == 25'h10b0000   ) begin
            src_channel = 10'b0000000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
        end

        // slave 8: [0x10c0000, 0x10c0040) : sel [24:6]
        if ( {address[24:6],{6 {1'b0}}} == 25'h10c0000   ) begin
            src_channel = 10'b0000100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
        end

        // slave 9: [0x10d0000, 0x10d0020) : sel [24:5]
        if ( {address[24:5],{5 {1'b0}}} == 25'h10d0000   ) begin
            src_channel = 10'b0001000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
        end
    end


    // --------------------------------------------------
    // Ceil(log2()) function
    // It's the 21st century. Consider using $clog2().
    // --------------------------------------------------
    function integer log2ceil;
        input reg[65:0] val;
        reg [65:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule


