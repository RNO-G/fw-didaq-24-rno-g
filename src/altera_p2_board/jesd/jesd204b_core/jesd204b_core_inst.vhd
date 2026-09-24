	component jesd204b_core is
		port (
			pma_cu_clk                     : in  std_logic                     := 'X';             -- clk
			pll_refclk                     : in  std_logic                     := 'X';             -- clk
			src_sss_grant                  : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- src_rs_grant
			src_sss_req                    : out std_logic_vector(1 downto 0);                     -- src_rs_req
			o_refclk_bus_out               : out std_logic;                                        -- refclk_bus_out
			jesd204_rx_rst_n               : in  std_logic                     := 'X';             -- reset_n
			rx_serial_data                 : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			rx_serial_data_n               : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			rxphy_clk                      : out std_logic_vector(1 downto 0);                     -- export
			jesd204_rx_rst_ack_n           : out std_logic;                                        -- export
			rx_locked_to_data              : out std_logic_vector(1 downto 0);                     -- export
			jesd204_rx_out_of_reset        : out std_logic;                                        -- export
			jesd204_rx_avs_chipselect      : in  std_logic                     := 'X';             -- chipselect
			jesd204_rx_avs_address         : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- address
			jesd204_rx_avs_read            : in  std_logic                     := 'X';             -- read
			jesd204_rx_avs_readdata        : out std_logic_vector(31 downto 0);                    -- readdata
			jesd204_rx_avs_waitrequest     : out std_logic;                                        -- waitrequest
			jesd204_rx_avs_write           : in  std_logic                     := 'X';             -- write
			jesd204_rx_avs_writedata       : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			jesd204_rx_int                 : out std_logic;                                        -- irq
			jesd204_rx_link_data           : out std_logic_vector(63 downto 0);                    -- data
			jesd204_rx_link_valid          : out std_logic;                                        -- valid
			jesd204_rx_link_ready          : in  std_logic                     := 'X';             -- ready
			jesd204_rx_dev_sync_n          : out std_logic;                                        -- export
			jesd204_rx_sysref              : in  std_logic                     := 'X';             -- export
			jesd204_rx_somf                : out std_logic_vector(3 downto 0);                     -- export
			jesd204_rx_csr_hd              : out std_logic;                                        -- export
			jesd204_rx_csr_cs              : out std_logic_vector(1 downto 0);                     -- export
			jesd204_rx_csr_l               : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_k               : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_n               : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_np              : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_s               : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_cf              : out std_logic_vector(4 downto 0);                     -- export
			jesd204_rx_csr_f               : out std_logic_vector(7 downto 0);                     -- export
			jesd204_rx_csr_m               : out std_logic_vector(7 downto 0);                     -- export
			jesd204_rx_alldev_lane_aligned : in  std_logic                     := 'X';             -- export
			jesd204_rx_dev_lane_aligned    : out std_logic;                                        -- export
			jesd204_rx_sof                 : out std_logic_vector(3 downto 0);                     -- export
			jesd204_rx_frame_error         : in  std_logic                     := 'X';             -- export
			csr_rx_testmode                : out std_logic_vector(3 downto 0);                     -- export
			jesd204_rx_dlb_data            : in  std_logic_vector(63 downto 0) := (others => 'X'); -- export
			jesd204_rx_dlb_data_valid      : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			jesd204_rx_dlb_kchar_data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			jesd204_rx_dlb_errdetect       : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			jesd204_rx_dlb_disperr         : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			jesd204_rx_avs_rst_n           : in  std_logic                     := 'X';             -- reset_n
			jesd204_rx_avs_clk             : in  std_logic                     := 'X';             -- clk
			rxlink_clk                     : in  std_logic                     := 'X'              -- clk
		);
	end component jesd204b_core;

	u0 : component jesd204b_core
		port map (
			pma_cu_clk                     => CONNECTED_TO_pma_cu_clk,                     --                     pma_cu_clk.clk
			pll_refclk                     => CONNECTED_TO_pll_refclk,                     --                     pll_refclk.clk
			src_sss_grant                  => CONNECTED_TO_src_sss_grant,                  --                  src_sss_grant.src_rs_grant
			src_sss_req                    => CONNECTED_TO_src_sss_req,                    --                    src_sss_req.src_rs_req
			o_refclk_bus_out               => CONNECTED_TO_o_refclk_bus_out,               --               o_refclk_bus_out.refclk_bus_out
			jesd204_rx_rst_n               => CONNECTED_TO_jesd204_rx_rst_n,               --               jesd204_rx_rst_n.reset_n
			rx_serial_data                 => CONNECTED_TO_rx_serial_data,                 --                 rx_serial_data.export
			rx_serial_data_n               => CONNECTED_TO_rx_serial_data_n,               --               rx_serial_data_n.export
			rxphy_clk                      => CONNECTED_TO_rxphy_clk,                      --                      rxphy_clk.export
			jesd204_rx_rst_ack_n           => CONNECTED_TO_jesd204_rx_rst_ack_n,           --           jesd204_rx_rst_ack_n.export
			rx_locked_to_data              => CONNECTED_TO_rx_locked_to_data,              --              rx_locked_to_data.export
			jesd204_rx_out_of_reset        => CONNECTED_TO_jesd204_rx_out_of_reset,        --        jesd204_rx_out_of_reset.export
			jesd204_rx_avs_chipselect      => CONNECTED_TO_jesd204_rx_avs_chipselect,      --                 jesd204_rx_avs.chipselect
			jesd204_rx_avs_address         => CONNECTED_TO_jesd204_rx_avs_address,         --                               .address
			jesd204_rx_avs_read            => CONNECTED_TO_jesd204_rx_avs_read,            --                               .read
			jesd204_rx_avs_readdata        => CONNECTED_TO_jesd204_rx_avs_readdata,        --                               .readdata
			jesd204_rx_avs_waitrequest     => CONNECTED_TO_jesd204_rx_avs_waitrequest,     --                               .waitrequest
			jesd204_rx_avs_write           => CONNECTED_TO_jesd204_rx_avs_write,           --                               .write
			jesd204_rx_avs_writedata       => CONNECTED_TO_jesd204_rx_avs_writedata,       --                               .writedata
			jesd204_rx_int                 => CONNECTED_TO_jesd204_rx_int,                 --                 jesd204_rx_int.irq
			jesd204_rx_link_data           => CONNECTED_TO_jesd204_rx_link_data,           --                jesd204_rx_link.data
			jesd204_rx_link_valid          => CONNECTED_TO_jesd204_rx_link_valid,          --                               .valid
			jesd204_rx_link_ready          => CONNECTED_TO_jesd204_rx_link_ready,          --                               .ready
			jesd204_rx_dev_sync_n          => CONNECTED_TO_jesd204_rx_dev_sync_n,          --          jesd204_rx_dev_sync_n.export
			jesd204_rx_sysref              => CONNECTED_TO_jesd204_rx_sysref,              --              jesd204_rx_sysref.export
			jesd204_rx_somf                => CONNECTED_TO_jesd204_rx_somf,                --                jesd204_rx_somf.export
			jesd204_rx_csr_hd              => CONNECTED_TO_jesd204_rx_csr_hd,              --              jesd204_rx_csr_hd.export
			jesd204_rx_csr_cs              => CONNECTED_TO_jesd204_rx_csr_cs,              --              jesd204_rx_csr_cs.export
			jesd204_rx_csr_l               => CONNECTED_TO_jesd204_rx_csr_l,               --               jesd204_rx_csr_l.export
			jesd204_rx_csr_k               => CONNECTED_TO_jesd204_rx_csr_k,               --               jesd204_rx_csr_k.export
			jesd204_rx_csr_n               => CONNECTED_TO_jesd204_rx_csr_n,               --               jesd204_rx_csr_n.export
			jesd204_rx_csr_np              => CONNECTED_TO_jesd204_rx_csr_np,              --              jesd204_rx_csr_np.export
			jesd204_rx_csr_s               => CONNECTED_TO_jesd204_rx_csr_s,               --               jesd204_rx_csr_s.export
			jesd204_rx_csr_cf              => CONNECTED_TO_jesd204_rx_csr_cf,              --              jesd204_rx_csr_cf.export
			jesd204_rx_csr_f               => CONNECTED_TO_jesd204_rx_csr_f,               --               jesd204_rx_csr_f.export
			jesd204_rx_csr_m               => CONNECTED_TO_jesd204_rx_csr_m,               --               jesd204_rx_csr_m.export
			jesd204_rx_alldev_lane_aligned => CONNECTED_TO_jesd204_rx_alldev_lane_aligned, -- jesd204_rx_alldev_lane_aligned.export
			jesd204_rx_dev_lane_aligned    => CONNECTED_TO_jesd204_rx_dev_lane_aligned,    --    jesd204_rx_dev_lane_aligned.export
			jesd204_rx_sof                 => CONNECTED_TO_jesd204_rx_sof,                 --                 jesd204_rx_sof.export
			jesd204_rx_frame_error         => CONNECTED_TO_jesd204_rx_frame_error,         --         jesd204_rx_frame_error.export
			csr_rx_testmode                => CONNECTED_TO_csr_rx_testmode,                --                csr_rx_testmode.export
			jesd204_rx_dlb_data            => CONNECTED_TO_jesd204_rx_dlb_data,            --            jesd204_rx_dlb_data.export
			jesd204_rx_dlb_data_valid      => CONNECTED_TO_jesd204_rx_dlb_data_valid,      --      jesd204_rx_dlb_data_valid.export
			jesd204_rx_dlb_kchar_data      => CONNECTED_TO_jesd204_rx_dlb_kchar_data,      --      jesd204_rx_dlb_kchar_data.export
			jesd204_rx_dlb_errdetect       => CONNECTED_TO_jesd204_rx_dlb_errdetect,       --       jesd204_rx_dlb_errdetect.export
			jesd204_rx_dlb_disperr         => CONNECTED_TO_jesd204_rx_dlb_disperr,         --         jesd204_rx_dlb_disperr.export
			jesd204_rx_avs_rst_n           => CONNECTED_TO_jesd204_rx_avs_rst_n,           --           jesd204_rx_avs_rst_n.reset_n
			jesd204_rx_avs_clk             => CONNECTED_TO_jesd204_rx_avs_clk,             --             jesd204_rx_avs_clk.clk
			rxlink_clk                     => CONNECTED_TO_rxlink_clk                      --                     rxlink_clk.clk
		);

