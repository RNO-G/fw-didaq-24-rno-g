	component niosv_pd is
		port (
			avalon_spi_slave_address          : out std_logic_vector(14 downto 0);                    -- address
			avalon_spi_slave_chipselect       : out std_logic;                                        -- chipselect
			avalon_spi_slave_waitrequest      : in  std_logic                     := 'X';             -- waitrequest
			avalon_spi_slave_write            : out std_logic;                                        -- write
			avalon_spi_slave_writedata        : out std_logic_vector(31 downto 0);                    -- writedata
			avalon_spi_slave_read             : out std_logic;                                        -- read
			avalon_spi_slave_readdata         : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			avalon_spi_slave_readdatavalid    : in  std_logic                     := 'X';             -- readdatavalid
			avalon_spi_slave_reset_reset      : out std_logic;                                        -- reset
			avalon_spi_slave_irq_irq          : in  std_logic                     := 'X';             -- irq
			i2c_master_0_avl_mm_address       : out std_logic_vector(7 downto 0);                     -- address
			i2c_master_0_avl_mm_chipselect    : out std_logic;                                        -- chipselect
			i2c_master_0_avl_mm_write         : out std_logic;                                        -- write
			i2c_master_0_avl_mm_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			i2c_master_0_avl_mm_writedata     : out std_logic_vector(31 downto 0);                    -- writedata
			i2c_master_0_avl_mm_read          : out std_logic;                                        -- read
			i2c_master_0_avl_mm_readdata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			i2c_master_0_avl_mm_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			i2c_master_0_avl_reset_reset      : out std_logic;                                        -- reset
			avl_mst_sbc_address               : in  std_logic_vector(31 downto 0) := (others => 'X'); -- address
			avl_mst_sbc_waitrequest           : out std_logic;                                        -- waitrequest
			avl_mst_sbc_write                 : in  std_logic                     := 'X';             -- write
			avl_mst_sbc_writedata             : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avl_mst_sbc_read                  : in  std_logic                     := 'X';             -- read
			avl_mst_sbc_readdata              : out std_logic_vector(31 downto 0);                    -- readdata
			avl_mst_sbc_readdatavalid         : out std_logic;                                        -- readdatavalid
			avl_mst_sb_reset_reset            : out std_logic;                                        -- reset
			spi_master_0_avl_mm_address       : out std_logic_vector(7 downto 0);                     -- address
			spi_master_0_avl_mm_chipselect    : out std_logic;                                        -- chipselect
			spi_master_0_avl_mm_write         : out std_logic;                                        -- write
			spi_master_0_avl_mm_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			spi_master_0_avl_mm_writedata     : out std_logic_vector(31 downto 0);                    -- writedata
			spi_master_0_avl_mm_read          : out std_logic;                                        -- read
			spi_master_0_avl_mm_readdata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			spi_master_0_avl_mm_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			spi_master_0_avl_reset_reset      : out std_logic;                                        -- reset
			clk_clk                           : in  std_logic                     := 'X';             -- clk
			jesd_low_slave_address            : out std_logic_vector(9 downto 0);                     -- address
			jesd_low_slave_chipselect         : out std_logic;                                        -- chipselect
			jesd_low_slave_read               : out std_logic;                                        -- read
			jesd_low_slave_readdata           : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			jesd_low_slave_waitrequest        : in  std_logic                     := 'X';             -- waitrequest
			jesd_low_slave_write              : out std_logic;                                        -- write
			jesd_low_slave_writedata          : out std_logic_vector(31 downto 0);                    -- writedata
			jesd_low_slave_reset_reset_n      : out std_logic;                                        -- reset_n
			jesd_high_slave_address           : out std_logic_vector(9 downto 0);                     -- address
			jesd_high_slave_chipselect        : out std_logic;                                        -- chipselect
			jesd_high_slave_read              : out std_logic;                                        -- read
			jesd_high_slave_readdata          : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			jesd_high_slave_waitrequest       : in  std_logic                     := 'X';             -- waitrequest
			jesd_high_slave_write             : out std_logic;                                        -- write
			jesd_high_slave_writedata         : out std_logic_vector(31 downto 0);                    -- writedata
			jesd_high_slave_reset_reset_n     : out std_logic;                                        -- reset_n
			pd_debug_uart_rxd                 : in  std_logic                     := 'X';             -- rxd
			pd_debug_uart_txd                 : out std_logic;                                        -- txd
			reset_reset_n                     : in  std_logic                     := 'X';             -- reset_n
			ser_debug_master_address          : in  std_logic_vector(31 downto 0) := (others => 'X'); -- address
			ser_debug_master_waitrequest      : out std_logic;                                        -- waitrequest
			ser_debug_master_write            : in  std_logic                     := 'X';             -- write
			ser_debug_master_writedata        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			ser_debug_master_read             : in  std_logic                     := 'X';             -- read
			ser_debug_master_readdata         : out std_logic_vector(31 downto 0);                    -- readdata
			ser_debug_master_readdatavalid    : out std_logic;                                        -- readdatavalid
			ser_debug_master_byteenable       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
			ser_debug_master_reset_reset      : out std_logic                                         -- reset
		);
	end component niosv_pd;

	u0 : component niosv_pd
		port map (
			avalon_spi_slave_address          => CONNECTED_TO_avalon_spi_slave_address,          --       avalon_spi_slave.address
			avalon_spi_slave_chipselect       => CONNECTED_TO_avalon_spi_slave_chipselect,       --                       .chipselect
			avalon_spi_slave_waitrequest      => CONNECTED_TO_avalon_spi_slave_waitrequest,      --                       .waitrequest
			avalon_spi_slave_write            => CONNECTED_TO_avalon_spi_slave_write,            --                       .write
			avalon_spi_slave_writedata        => CONNECTED_TO_avalon_spi_slave_writedata,        --                       .writedata
			avalon_spi_slave_read             => CONNECTED_TO_avalon_spi_slave_read,             --                       .read
			avalon_spi_slave_readdata         => CONNECTED_TO_avalon_spi_slave_readdata,         --                       .readdata
			avalon_spi_slave_readdatavalid    => CONNECTED_TO_avalon_spi_slave_readdatavalid,    --                       .readdatavalid
			avalon_spi_slave_reset_reset      => CONNECTED_TO_avalon_spi_slave_reset_reset,      -- avalon_spi_slave_reset.reset
			avalon_spi_slave_irq_irq          => CONNECTED_TO_avalon_spi_slave_irq_irq,          --   avalon_spi_slave_irq.irq
			i2c_master_0_avl_mm_address       => CONNECTED_TO_i2c_master_0_avl_mm_address,       --    i2c_master_0_avl_mm.address
			i2c_master_0_avl_mm_chipselect    => CONNECTED_TO_i2c_master_0_avl_mm_chipselect,    --                       .chipselect
			i2c_master_0_avl_mm_write         => CONNECTED_TO_i2c_master_0_avl_mm_write,         --                       .write
			i2c_master_0_avl_mm_waitrequest   => CONNECTED_TO_i2c_master_0_avl_mm_waitrequest,   --                       .waitrequest
			i2c_master_0_avl_mm_writedata     => CONNECTED_TO_i2c_master_0_avl_mm_writedata,     --                       .writedata
			i2c_master_0_avl_mm_read          => CONNECTED_TO_i2c_master_0_avl_mm_read,          --                       .read
			i2c_master_0_avl_mm_readdata      => CONNECTED_TO_i2c_master_0_avl_mm_readdata,      --                       .readdata
			i2c_master_0_avl_mm_readdatavalid => CONNECTED_TO_i2c_master_0_avl_mm_readdatavalid, --                       .readdatavalid
			i2c_master_0_avl_reset_reset      => CONNECTED_TO_i2c_master_0_avl_reset_reset,      -- i2c_master_0_avl_reset.reset
			avl_mst_sbc_address               => CONNECTED_TO_avl_mst_sbc_address,               --            avl_mst_sbc.address
			avl_mst_sbc_waitrequest           => CONNECTED_TO_avl_mst_sbc_waitrequest,           --                       .waitrequest
			avl_mst_sbc_write                 => CONNECTED_TO_avl_mst_sbc_write,                 --                       .write
			avl_mst_sbc_writedata             => CONNECTED_TO_avl_mst_sbc_writedata,             --                       .writedata
			avl_mst_sbc_read                  => CONNECTED_TO_avl_mst_sbc_read,                  --                       .read
			avl_mst_sbc_readdata              => CONNECTED_TO_avl_mst_sbc_readdata,              --                       .readdata
			avl_mst_sbc_readdatavalid         => CONNECTED_TO_avl_mst_sbc_readdatavalid,         --                       .readdatavalid
			avl_mst_sb_reset_reset            => CONNECTED_TO_avl_mst_sb_reset_reset,            --       avl_mst_sb_reset.reset
			spi_master_0_avl_mm_address       => CONNECTED_TO_spi_master_0_avl_mm_address,       --    spi_master_0_avl_mm.address
			spi_master_0_avl_mm_chipselect    => CONNECTED_TO_spi_master_0_avl_mm_chipselect,    --                       .chipselect
			spi_master_0_avl_mm_write         => CONNECTED_TO_spi_master_0_avl_mm_write,         --                       .write
			spi_master_0_avl_mm_waitrequest   => CONNECTED_TO_spi_master_0_avl_mm_waitrequest,   --                       .waitrequest
			spi_master_0_avl_mm_writedata     => CONNECTED_TO_spi_master_0_avl_mm_writedata,     --                       .writedata
			spi_master_0_avl_mm_read          => CONNECTED_TO_spi_master_0_avl_mm_read,          --                       .read
			spi_master_0_avl_mm_readdata      => CONNECTED_TO_spi_master_0_avl_mm_readdata,      --                       .readdata
			spi_master_0_avl_mm_readdatavalid => CONNECTED_TO_spi_master_0_avl_mm_readdatavalid, --                       .readdatavalid
			spi_master_0_avl_reset_reset      => CONNECTED_TO_spi_master_0_avl_reset_reset,      -- spi_master_0_avl_reset.reset
			clk_clk                           => CONNECTED_TO_clk_clk,                           --                    clk.clk
			jesd_low_slave_address            => CONNECTED_TO_jesd_low_slave_address,            --         jesd_low_slave.address
			jesd_low_slave_chipselect         => CONNECTED_TO_jesd_low_slave_chipselect,         --                       .chipselect
			jesd_low_slave_read               => CONNECTED_TO_jesd_low_slave_read,               --                       .read
			jesd_low_slave_readdata           => CONNECTED_TO_jesd_low_slave_readdata,           --                       .readdata
			jesd_low_slave_waitrequest        => CONNECTED_TO_jesd_low_slave_waitrequest,        --                       .waitrequest
			jesd_low_slave_write              => CONNECTED_TO_jesd_low_slave_write,              --                       .write
			jesd_low_slave_writedata          => CONNECTED_TO_jesd_low_slave_writedata,          --                       .writedata
			jesd_low_slave_reset_reset_n      => CONNECTED_TO_jesd_low_slave_reset_reset_n,      --   jesd_low_slave_reset.reset_n
			jesd_high_slave_address           => CONNECTED_TO_jesd_high_slave_address,           --        jesd_high_slave.address
			jesd_high_slave_chipselect        => CONNECTED_TO_jesd_high_slave_chipselect,        --                       .chipselect
			jesd_high_slave_read              => CONNECTED_TO_jesd_high_slave_read,              --                       .read
			jesd_high_slave_readdata          => CONNECTED_TO_jesd_high_slave_readdata,          --                       .readdata
			jesd_high_slave_waitrequest       => CONNECTED_TO_jesd_high_slave_waitrequest,       --                       .waitrequest
			jesd_high_slave_write             => CONNECTED_TO_jesd_high_slave_write,             --                       .write
			jesd_high_slave_writedata         => CONNECTED_TO_jesd_high_slave_writedata,         --                       .writedata
			jesd_high_slave_reset_reset_n     => CONNECTED_TO_jesd_high_slave_reset_reset_n,     --  jesd_high_slave_reset.reset_n
			pd_debug_uart_rxd                 => CONNECTED_TO_pd_debug_uart_rxd,                 --          pd_debug_uart.rxd
			pd_debug_uart_txd                 => CONNECTED_TO_pd_debug_uart_txd,                 --                       .txd
			reset_reset_n                     => CONNECTED_TO_reset_reset_n,                     --                  reset.reset_n
			ser_debug_master_address          => CONNECTED_TO_ser_debug_master_address,          --       ser_debug_master.address
			ser_debug_master_waitrequest      => CONNECTED_TO_ser_debug_master_waitrequest,      --                       .waitrequest
			ser_debug_master_write            => CONNECTED_TO_ser_debug_master_write,            --                       .write
			ser_debug_master_writedata        => CONNECTED_TO_ser_debug_master_writedata,        --                       .writedata
			ser_debug_master_read             => CONNECTED_TO_ser_debug_master_read,             --                       .read
			ser_debug_master_readdata         => CONNECTED_TO_ser_debug_master_readdata,         --                       .readdata
			ser_debug_master_readdatavalid    => CONNECTED_TO_ser_debug_master_readdatavalid,    --                       .readdatavalid
			ser_debug_master_byteenable       => CONNECTED_TO_ser_debug_master_byteenable,       --                       .byteenable
			ser_debug_master_reset_reset      => CONNECTED_TO_ser_debug_master_reset_reset       -- ser_debug_master_reset.reset
		);

