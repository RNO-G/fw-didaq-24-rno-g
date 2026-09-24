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
`define CLK_USE_ONE(port_name) tileip_mux_write_connected_parameter=`"CONNECTED_``port_name```"

`define PARAM_ATTR(attr_name, param_name) tileip_attr_of_``param_name``=`"``attr_name```"
`define CAVMM(port_name) `SIP, tileip_mux_controller_port=`"``port_name``_ch${tileip_net_dr_lane_index}${port_select[0]}`"

(*
    arbiter_sip,
    `PARAM_ATTR(num_ports, NUM_PORTS)
*)
module tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_arbiter
#(
// DR Tool needs the default to be a valid configuring, so use this for all Quartus runs, and use extra checks in simulations
`ifdef ALTERA_RESERVED_QIS
    /* `ATTR_DS_MERGE__COMPUTE   */ parameter int                                   NUM_PORTS                                        = 2,
`else
    /* `ATTR_DS_MERGE__COMPUTE   */ parameter int                                   NUM_PORTS                                        = -1,
`endif
                                    parameter bit [NUM_PORTS-1:0]                   CONNECTED_i_hio_det_lat_sampling_clk             = '0, // One bit per port set to 1 if connected
                                    parameter bit [NUM_PORTS-1:0]                   RX_ONLY_IP_USAGE                                 = '0,
                                    parameter bit [NUM_PORTS-1:0]                   TX_ONLY_IP_USAGE                                 = '0
)
(
    (* `SIP,`CLK_USE_ONE(i_hio_det_lat_sampling_clk) *) input  wire [NUM_PORTS-1:0]       i_hio_det_lat_sampling_clk,
    // DPHY will drive 'z on all LAVMM ports when not enabled, so use tri0 inputs to workaround this
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0][20:0] i_hio_lavmm_addr,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0][3:0]  i_hio_lavmm_be,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0]       i_hio_lavmm_clk,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0]       i_hio_lavmm_read,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0]       i_hio_lavmm_rstn,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0][31:0] i_hio_lavmm_wdata,
    (* `SIP                                          *) input  tri0 [NUM_PORTS-1:0]       i_hio_lavmm_write,
    (* `SIP                                          *) output wire [NUM_PORTS-1:0][31:0] o_hio_lavmm_rdata,
    (* `SIP                                          *) output wire [NUM_PORTS-1:0]       o_hio_lavmm_rdata_valid,
    (* `SIP                                          *) output wire [NUM_PORTS-1:0]       o_hio_lavmm_waitreq,
    // LAVMM port connected to DR Controller
    (* `CAVMM(i_dr_lavmm_addr)                       *) input  wire [20:0]                i_dr_lavmm_addr,
    (* `CAVMM(i_dr_lavmm_be)                         *) input  wire [3:0]                 i_dr_lavmm_be,
    (* `CAVMM(i_dr_lavmm_clk)                        *) input  wire                       i_dr_lavmm_clk,
    (* `CAVMM(i_dr_lavmm_read)                       *) input  wire                       i_dr_lavmm_read,
    (* `CAVMM(i_dr_lavmm_rstn)                       *) input  wire                       i_dr_lavmm_rstn,
    (* `CAVMM(i_dr_lavmm_wdata)                      *) input  wire [31:0]                i_dr_lavmm_wdata,
    (* `CAVMM(i_dr_lavmm_write)                      *) input  wire                       i_dr_lavmm_write,
    (* `CAVMM(o_dr_lavmm_rdata)                      *) output wire [31:0]                o_dr_lavmm_rdata,
    (* `CAVMM(o_dr_lavmm_rdata_valid)                *) output wire                       o_dr_lavmm_rdata_valid,
    (* `CAVMM(o_dr_lavmm_waitreq)                    *) output wire                       o_dr_lavmm_waitreq,

    (* `ONE_HOT_SEL                                  *) input  wire [NUM_PORTS-1:0]       one_hot_sel,
    (* `DIRECT                                       *) output wire                       d_i_hio_det_lat_sampling_clk,
    (* `DIRECT                                       *) output wire [20:0]                d_i_hio_lavmm_addr,
    (* `DIRECT                                       *) output wire [3:0]                 d_i_hio_lavmm_be,
    (* `DIRECT                                       *) output wire                       d_i_hio_lavmm_clk,
    (* `DIRECT                                       *) output wire                       d_i_hio_lavmm_read,
    (* `DIRECT                                       *) output wire                       d_i_hio_lavmm_rstn,
    (* `DIRECT                                       *) output wire [31:0]                d_i_hio_lavmm_wdata,
    (* `DIRECT                                       *) output wire                       d_i_hio_lavmm_write,
    (* `DIRECT                                       *) input  wire [31:0]                d_o_hio_lavmm_rdata,
    (* `DIRECT                                       *) input  wire                       d_o_hio_lavmm_rdata_valid,
    (* `DIRECT                                       *) input  wire                       d_o_hio_lavmm_waitreq
);

`ifndef __TILE_IP__

    // -------------------------------------------------------------------------
    // Overview:
    // ---------
    // DR Arbiter - Implements the arbitration on LAVMM signals needed for DR
    // and the muxing needed for non-Rx/Tx signals. All LAVMM interfaces must
    // use the same clock to avoid clock domain crossings, an assertion is used
    // to verify that this is satisfied.
    //
    // Only the protocol IP selected by the selector is allowed to perform
    // accesses, and changes from one protocol IP to another is only performed
    // when there are no outstanding transactions. The DR Controller interface
    // will only perform accesses when all interfaces from the protocol IPs are
    // idle and the interface is guaranteed to be all zeros when unused. With
    // these requirements the simplest implementation is to perform
    // an AND with the selector for all signals from the protocol IPs to the
    // HIP, and then OR all the results and then OR them with the input from the
    // DR Controller. In the same way the response signals from the HIP can be
    // connected to the protocol IPs after being ANDed with the selector. In
    // addition to this a bit of extra logic is needed to handle responses to
    // the DR Controller. The most efficient muxing is done by encoding the
    // selector as binary before the muxing, but the same functionality can be
    // achieved using the one hot selector directly.
    //
    // The interface on the arbiter does not include any error indication, so no
    // resources will be used to try to detect errors.
    //
    // The non-LAVMM signals are not present for the DR Controller port.
    // -------------------------------------------------------------------------

    // Verify that all parameter values are legal
    if (NUM_PORTS<1) $fatal(1,"Number of ports must be > 0");
    // Assertions (ports)
    always_comb begin : a_proc
        // Check that mux selector is one hot encoded
        one_hot_sel_a: assert final (($onehot0(one_hot_sel)) || (RX_ONLY_IP_USAGE != '0 && TX_ONLY_IP_USAGE != '0)) else
            $error("One hot selector must be one-hot. Multiple bits asserted: '%b'", one_hot_sel);
        // Check that all LAVMM clocks are identical
        foreach (i_hio_lavmm_clk[i]) begin : gen_same_lavmm_clk
            same_lavmm_clk_a: assert final ((i_hio_lavmm_clk[i] == i_dr_lavmm_clk) || (i_hio_lavmm_clk[i] === 1'b0)) else
                $error("All LAVMM clocks must be identical (%d,%b,%b)", i, i_hio_lavmm_clk,i_dr_lavmm_clk);
        end : gen_same_lavmm_clk
        // All System PLL Lock signals and deterministic latency sampling clocks
        // also has to be identical. Currently this is not checked as these
        // assertions are expensive, but checks for this can be added.
    end : a_proc

    localparam int NUM_PORTS_INT = NUM_PORTS+1;
    typedef struct packed {
        logic [20:0] addr;
        logic [3:0]  be;
        logic        read;
        logic [31:0] wdata;
        logic        write;
    } lavmm_req_s;
    localparam lavmm_req_s LAVMM_REQ_IDLE = '{default: '0};
    typedef struct packed {
        logic [31:0] rdata;
        logic        rdata_valid;
        logic        waitreq;
    } lavmm_rsp_s;
    localparam lavmm_rsp_s LAVMM_RSP_IDLE = '{
        rdata       : '0,
        rdata_valid : '0,
        waitreq     : 1'b1
    };

    // Map ports to structs to ease mux implementation -------------------------
    lavmm_req_s lavmm_reqs[NUM_PORTS+1];
    lavmm_rsp_s lavmm_rsps[NUM_PORTS+1];
    lavmm_req_s lavmm_req;
    lavmm_rsp_s lavmm_rsp;
    for (genvar i=0; i<NUM_PORTS; i++) begin : gen_lavmm_map
        assign lavmm_reqs[i] = '{
            addr  : i_hio_lavmm_addr[i],
            be    : i_hio_lavmm_be[i],
            read  : i_hio_lavmm_read[i],
            wdata : i_hio_lavmm_wdata[i],
            write : i_hio_lavmm_write[i]
        };
        assign o_hio_lavmm_rdata[i]       = lavmm_rsps[i].rdata;
        assign o_hio_lavmm_rdata_valid[i] = lavmm_rsps[i].rdata_valid;
        assign o_hio_lavmm_waitreq[i]     = lavmm_rsps[i].waitreq;
    end : gen_lavmm_map
    assign lavmm_reqs[NUM_PORTS] = '{
        addr  : i_dr_lavmm_addr,
        be    : i_dr_lavmm_be,
        read  : i_dr_lavmm_read,
        wdata : i_dr_lavmm_wdata,
        write : i_dr_lavmm_write
    };
    assign o_dr_lavmm_rdata       = lavmm_rsps[NUM_PORTS].rdata;
    assign o_dr_lavmm_rdata_valid = lavmm_rsps[NUM_PORTS].rdata_valid;
    assign o_dr_lavmm_waitreq     = lavmm_rsps[NUM_PORTS].waitreq;
    assign d_i_hio_lavmm_addr     = lavmm_req.addr;
    assign d_i_hio_lavmm_be       = lavmm_req.be;
    assign d_i_hio_lavmm_read     = lavmm_req.read;
    assign d_i_hio_lavmm_wdata    = lavmm_req.wdata;
    assign d_i_hio_lavmm_write    = lavmm_req.write;
    assign lavmm_rsp = '{
        rdata       : d_o_hio_lavmm_rdata,
        rdata_valid : d_o_hio_lavmm_rdata_valid,
        waitreq     : d_o_hio_lavmm_waitreq
    };

    if (RX_ONLY_IP_USAGE != '0 && TX_ONLY_IP_USAGE != '0) begin : gen_arbitration
        // instantiate arbiter implementation as both RX only and TX only IP 
        // instances use this channel so it is possible for multiple 
        // one_hot_sel[] signals to be enabled at the same time
    if (NUM_PORTS_INT == 1) begin : gen_arb_1
        // One port, no arbitration, pass through
        assign lavmm_req = lavmm_reqs[0];
        assign lavmm_rsps[0] = lavmm_rsp;
    end else begin : gen_arb_n
        // Implement arbitration between LAVMM ports using wait request to stall
        // accesses to avoid any buffering. To ensure fairness use round robin
        // between all ports.
        function automatic logic rr_arb (
            input logic [NUM_PORTS_INT-1:0] reqs,
            input logic [$clog2(NUM_PORTS_INT)-1:0] cur,
            output logic [$clog2(NUM_PORTS_INT)-1:0] nxt
        );
            logic [2*NUM_PORTS_INT-2:0] reqs_int;
            logic [2*NUM_PORTS_INT-2:0] mask;
            reqs_int = {reqs[NUM_PORTS_INT-2:0],reqs};
            mask = '0;
            if (cur == (NUM_PORTS_INT-1))
                mask[NUM_PORTS_INT-1:0] = '1;
            else
                mask[(cur+1'b1)+:NUM_PORTS_INT] = '1;
            reqs_int = reqs_int & mask;
            foreach (reqs_int[i])
                if (reqs_int[i])
                    nxt =($clog2(NUM_PORTS_INT))'((i > (NUM_PORTS_INT-1)) ? (i-NUM_PORTS_INT) : i);
            return (|reqs);
        endfunction
        (* preserve, dont_replicate *) enum logic[1:0] {
            WAITING  = 2'b00,
            REQ      = 2'b01,
            WAIT_RSP = 2'b10,
            RSP      = 2'b11} state;
        logic [$clog2(NUM_PORTS_INT)-1:0] cur;
        logic wait_for_rd_data;
        always_ff @(posedge i_dr_lavmm_clk or negedge i_dr_lavmm_rstn) begin : arb_proc
            automatic logic [$clog2(NUM_PORTS_INT)-1:0] nxt;
            // Use LAVMM reset signal from first requester as async reset as it
            // satisfies the requirements, even though the signal is otherwise
            // only used for clock gating.
            if (!i_dr_lavmm_rstn) begin
                state <= WAITING;
                lavmm_req <= LAVMM_REQ_IDLE;
                lavmm_rsps <= '{default: LAVMM_RSP_IDLE};
                cur <= '0;
                wait_for_rd_data <= '0;
            end else begin
                unique case (state)
                    WAITING:
                        begin
                            lavmm_rsps <= '{default: LAVMM_RSP_IDLE};
                            if (rr_arb(.reqs({i_dr_lavmm_read,i_hio_lavmm_read} | {i_dr_lavmm_write,i_hio_lavmm_write}),.cur(cur),.nxt(nxt))) begin
                                cur <= nxt;
                                state <= REQ;
                            end
                        end
                    REQ:
                        begin
                            lavmm_req <= lavmm_reqs[cur];
                            state <= WAIT_RSP;
                        end
                    WAIT_RSP:
                        begin
                            if (!lavmm_rsp.waitreq) begin
                                lavmm_req <= LAVMM_REQ_IDLE; // Clear request once wait request has been deasserted
                                lavmm_rsps[cur].waitreq    <= 1'b0;
                                if (lavmm_req.read)
                                    wait_for_rd_data <= 1'b1;
                                else
                                    wait_for_rd_data <= 1'b0;
                                state <= RSP;
                            end
                        end
                    RSP:
                        begin
                            if (!wait_for_rd_data) begin
                                state <= WAITING;
                            end else begin
                                if (lavmm_rsp.rdata_valid) begin // Wait until read data valid received
                                    lavmm_rsps[cur].rdata       <= lavmm_rsp.rdata;
                                    lavmm_rsps[cur].rdata_valid <= lavmm_rsp.rdata_valid;
                                    wait_for_rd_data            <= 1'b0;
                                    state                       <= WAITING;
                                end
                            end
                        end
                endcase
            end
        end : arb_proc
    end : gen_arb_n

    end else begin : gen_muxing
    // Mux LAVMM signals -------------------------------------------------------
    // Each of the interfaces from the protocol IPs is gated by the 
    // corresponding bit in the one hot selector. The interface from the DR 
    // Controller is gated inside the controller, and only used when all 
    // selector bits are 0.
    localparam MUX_BIN_SEL = 1'b1;
    if (NUM_PORTS_INT == 1) begin : gen_mux_1
        assign lavmm_req = (one_hot_sel[0]) ? lavmm_reqs[0] : LAVMM_REQ_IDLE;
    end else begin : gen_mux_n
        if (MUX_BIN_SEL) begin : gen_mux_bin_sel
            (* keep *) logic [$clog2($bits(one_hot_sel)+1)-1:0] sel;
            always_comb begin
                lavmm_req_s lavmm_reqs_full[2**$clog2(NUM_PORTS_INT)];
                sel = '1;
                foreach (one_hot_sel[i])
                    if (one_hot_sel[i]) begin
                        sel = $bits(sel)'(i);
                    end
                lavmm_reqs_full = '{default: lavmm_reqs[NUM_PORTS_INT-1]};
                foreach (lavmm_reqs[i])
                    lavmm_reqs_full[i] = lavmm_reqs[i];
                lavmm_req = lavmm_reqs_full[sel];
            end
        end else begin : gen_mux_one_hot
            lavmm_req_s lavmm_reqs_mask[NUM_PORTS_INT];
            for (genvar i=0; i<(NUM_PORTS_INT-1); i++) begin : gen_mux_req_mask
                assign lavmm_reqs_mask[i] = {$bits(lavmm_reqs[i]){one_hot_sel[i]}} & lavmm_reqs[i];
            end : gen_mux_req_mask
            assign lavmm_reqs_mask[NUM_PORTS_INT-1] = lavmm_reqs[NUM_PORTS_INT-1];
            always_comb begin : req_mux_proc
                lavmm_req = '0;
                foreach (lavmm_reqs_mask[i])
                    lavmm_req |= lavmm_reqs_mask[i];
            end : req_mux_proc
        end : gen_mux_one_hot
        (* keep *) logic lavmm_rsp_dr_en;
        assign lavmm_rsp_dr_en = one_hot_sel == '0;
        always_comb begin : rsp_proc
            foreach (one_hot_sel[i])
                lavmm_rsps[i] = (one_hot_sel[i]) ? lavmm_rsp : LAVMM_RSP_IDLE;
            lavmm_rsps[NUM_PORTS_INT-1] = (lavmm_rsp_dr_en) ? lavmm_rsp : LAVMM_RSP_IDLE;
        end : rsp_proc
    end : gen_mux_n
    end : gen_muxing

    // LAVMM Clock & Reset -----------------------------------------------------
    // All LAVMM interfaces must use the same clock to avoid clock domain
    // crossings, so pass one copy to HIP and leave the rest unconnected.
    assign d_i_hio_lavmm_clk = i_dr_lavmm_clk;
    logic [NUM_PORTS-1:0] i_hio_lavmm_clk_nc;
    assign i_hio_lavmm_clk_nc = i_hio_lavmm_clk;
    // The LAVMM Reset input is used for clock gating (not reset) to avoid
    // glitches. Shall be asserted from power on, deasserted after user mode is
    // entered, and not be asserted again. Not affected by DR. Use input from
    // DR Controller to guarantee this, other inputs are not connected.
    assign d_i_hio_lavmm_rstn = i_dr_lavmm_rstn;
    logic [NUM_PORTS-1:0] i_hio_lavmm_rstn_nc;
    assign i_hio_lavmm_rstn_nc = i_hio_lavmm_rstn;

    // DL Clocks ---------------------------------------------------------------
    // For the deterministic latency clocks, avoid logic on the signal
    // pick one and always use that. Must pick one that is driven by a valid
    // clock, DR Tool indicates which input bits a driven, pick anyone of them
    logic [NUM_PORTS-1:0] i_hio_det_lat_sampling_clk_nc;
    logic d_i_hio_det_lat_sampling_clk_int;
    always_comb begin : dl_clk_proc
        i_hio_det_lat_sampling_clk_nc = i_hio_det_lat_sampling_clk;
        d_i_hio_det_lat_sampling_clk_int = 1'b0;
        foreach (CONNECTED_i_hio_det_lat_sampling_clk[i])
            if (CONNECTED_i_hio_det_lat_sampling_clk[i]) begin
                d_i_hio_det_lat_sampling_clk_int = i_hio_det_lat_sampling_clk[i];
                i_hio_det_lat_sampling_clk_nc[i] = 1'b0;
            end
    end : dl_clk_proc
    assign d_i_hio_det_lat_sampling_clk = d_i_hio_det_lat_sampling_clk_int;

    // LAVMM SIP Side asserts --------------------------------------------------
`ifndef ALTERA_RESERVED_QIS
    for (genvar i=0; i<NUM_PORTS; i++) begin : gen_lavmm_a
        logic wr_in_prog = 1'b0;
        logic rd_in_prog = 1'b0;
        logic [NUM_PORTS-1:0] one_hot_sel_full;
        assign one_hot_sel_full = {one_hot_sel == '0,one_hot_sel};
        always @(posedge i_hio_lavmm_clk[i]) begin: lavmm_a_proc
            if (one_hot_sel_full[i]) begin
                urw_a: assert (!($isunknown({i_hio_lavmm_read[i],i_hio_lavmm_write[i]}))) else
                    $warning("Unknown value on LAVMM read/write on port %d.",i);
                rw_a: assert (!(i_hio_lavmm_read[i] && i_hio_lavmm_write[i])) else
                    $warning("Reading and writing in same cycles on LAVMM port %d.",i);
                if (i_hio_lavmm_write[i]) begin
                    wr_in_prog <= o_hio_lavmm_waitreq[i];
                    wu_a: assert (!($isunknown({i_hio_lavmm_addr[i],i_hio_lavmm_be[i],i_hio_lavmm_wdata[i]}))) else
                        $warning("Unknown values on control signals during write on LAVMM port %d.",i);
                    wrp: assert (!rd_in_prog) else
                        $warning("Write initiated while read in progress on LAVMM port %d",i);
                end
                if (i_hio_lavmm_read[i]) begin
                    rd_in_prog <= o_hio_lavmm_waitreq[i];
                    ru_a: assert (!($isunknown({i_hio_lavmm_addr[i],i_hio_lavmm_be[i]}))) else
                        $warning("Unknown values on control signals during read on LAVMM port %d.",i);
                    rwp: assert (!wr_in_prog) else
                        $warning("Read initiated while write in progress on LAVMM port %d.",i);
                end
            end else begin
                // LAVMM input not select not transactions allowed
                pd_a: assert ((!wr_in_prog) && (!rd_in_prog)) else
                    $warning("Port %d disabled while access in progress on LAVMM.",i);
                pdrw_a: assert ((i_hio_lavmm_read[i] === 1'b0) && (i_hio_lavmm_write[i] === 1'b0)) else
                    $warning("LAVMM access from port %d while disabled.",i);
                // Check that signals are stable while port is disabled, unless they are undefined as that causes stable check to fail
                rws_a: assert ($isunknown({i_hio_lavmm_addr[i],i_hio_lavmm_be[i],i_hio_lavmm_wdata[i]}) || $stable({i_hio_lavmm_addr[i],i_hio_lavmm_be[i],i_hio_lavmm_wdata[i]},@(posedge i_hio_lavmm_clk[i]))) else
                    $warning("LAVMM activity on port %d while disabled.",i);
            end
        end : lavmm_a_proc
    end : gen_lavmm_a
`endif // ifndef ALTERA_RESERVED_QIS

`endif // ifndef __TILE_IP__

endmodule : tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_arbiter
`undef CAVMM
`undef PARAM_ATTR
`undef CLK_USE_ONE
`undef ONE_HOT_SEL
`undef DIRECT
`undef SIP
`default_nettype wire
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "CYTUP98cokYF5/KnH5U9wpmsMebvw7PjbSFb6M3lY/qsVIz6jKyEvq+ZpFxx2uhEXGlRc0Zdjj1y1wmOppfPxVoYbzB4MDz5WMEEIHxYqLzLPRix146tWtBVedm6MD12cvLP4zUSq8euGs2Vl4XTnYwLn9yJjVujHm3F6Sq+aoE+e5SR+I7FPSr+JWVgOvlOEHDWwXnTb8RANIhljDHm3WWpU5Wvb9fUSAR0qErfFv8mLQQk0BiVuEy4EKXJqQU/g/16dy55mDraI6FZ3qMc0BaK/w5yp+QYBPZA0dXupGs2jYhvLjF5k1W4m/T2qVaLT+R7MNHKn2IQu08xWlT6EAAag6U6ib7ryYAHSggfBK0uViCU4azQKJyXeR2Mu+JHu2vce5RlpgSCzszeXyeAkwiKJTMBeGri/LD1HyfY6SfrYLt0vKz4ugbY+sUJLcNJ2z+lARgqzgMCnU9bOXDSzoRaeKI08Qt+0dzb896qdHi6BGAForzYP3dnRSuAIJjQyVhLYvfLeZZAJGij92zT6a2nol2xKYT9jHghlANvJP2iSWSeLOAEEZ9FOtmQEnuKXGuOVdJowshf+aZhec4tteS4Ae2e/MoGDMuEYhIIbTvduhu1vaZk8JyQNCiJ7J43jEamBl2S6dDdXPcvuNf0cLxLwOPRd1QM9tMr5usn/AmR4x4GKESDYK8AP7pleU5jAORBgZvYzrw9uaESHvAm4EWFjoPkQYMSbJNkzIYMcXgArgwzBD4SUOBxZ0Zs2toreL0OtYLSOAzMwuQFzJNFnePlfZQikkkj5PWaciVRdcShPdYUFhEc7YdyfgaJ4SjmPmt7INoa9+IDbwJADcF/mE7+MPZjFNvl+Y5RU/CvWJvJBp1rjqubJz8n/hoskhbAaZiAZLeOb9AvYpAC/RoQ3dF4JdZRQn2BGeSTuBL4agt1Q8U34YIi/E1SU4wMpYPeSPzHt1KAh859pz6F4L+w1kHS2jz+Yr9WBjONRp45HLvAL+rOY7l1Bflxcz0XFV3O"
`endif