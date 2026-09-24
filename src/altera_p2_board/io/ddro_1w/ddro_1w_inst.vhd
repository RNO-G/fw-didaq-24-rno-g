	component ddro_1w is
		port (
			ck        : in  std_logic                    := 'X';             -- export
			datain_h  : in  std_logic_vector(0 downto 0) := (others => 'X'); -- fragment
			datain_l  : in  std_logic_vector(0 downto 0) := (others => 'X'); -- fragment
			dataout   : out std_logic_vector(0 downto 0);                    -- export
			pad_out_b : out std_logic_vector(0 downto 0)                     -- export
		);
	end component ddro_1w;

	u0 : component ddro_1w
		port map (
			ck        => CONNECTED_TO_ck,        --        ck.export
			datain_h  => CONNECTED_TO_datain_h,  --  datain_h.fragment
			datain_l  => CONNECTED_TO_datain_l,  --  datain_l.fragment
			dataout   => CONNECTED_TO_dataout,   --   pad_out.export
			pad_out_b => CONNECTED_TO_pad_out_b  -- pad_out_b.export
		);

