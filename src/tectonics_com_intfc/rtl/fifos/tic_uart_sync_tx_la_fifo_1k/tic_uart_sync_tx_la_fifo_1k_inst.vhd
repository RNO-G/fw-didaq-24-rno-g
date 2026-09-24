	component tic_uart_sync_tx_la_fifo_1k is
		port (
			data  : in  std_logic_vector(7 downto 0) := (others => 'X'); -- datain
			wrreq : in  std_logic                    := 'X';             -- wrreq
			rdreq : in  std_logic                    := 'X';             -- rdreq
			clock : in  std_logic                    := 'X';             -- clk
			aclr  : in  std_logic                    := 'X';             -- aclr
			sclr  : in  std_logic                    := 'X';             -- sclr
			q     : out std_logic_vector(7 downto 0);                    -- dataout
			usedw : out std_logic_vector(9 downto 0);                    -- usedw
			full  : out std_logic;                                       -- full
			empty : out std_logic                                        -- empty
		);
	end component tic_uart_sync_tx_la_fifo_1k;

	u0 : component tic_uart_sync_tx_la_fifo_1k
		port map (
			data  => CONNECTED_TO_data,  --  fifo_input.datain
			wrreq => CONNECTED_TO_wrreq, --            .wrreq
			rdreq => CONNECTED_TO_rdreq, --            .rdreq
			clock => CONNECTED_TO_clock, --            .clk
			aclr  => CONNECTED_TO_aclr,  --            .aclr
			sclr  => CONNECTED_TO_sclr,  --            .sclr
			q     => CONNECTED_TO_q,     -- fifo_output.dataout
			usedw => CONNECTED_TO_usedw, --            .usedw
			full  => CONNECTED_TO_full,  --            .full
			empty => CONNECTED_TO_empty  --            .empty
		);

