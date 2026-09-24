module niosv_pd (
		output wire [14:0] avalon_spi_slave_address,          //       avalon_spi_slave.address
		output wire        avalon_spi_slave_chipselect,       //                       .chipselect
		input  wire        avalon_spi_slave_waitrequest,      //                       .waitrequest
		output wire        avalon_spi_slave_write,            //                       .write
		output wire [31:0] avalon_spi_slave_writedata,        //                       .writedata
		output wire        avalon_spi_slave_read,             //                       .read
		input  wire [31:0] avalon_spi_slave_readdata,         //                       .readdata
		input  wire        avalon_spi_slave_readdatavalid,    //                       .readdatavalid
		output wire        avalon_spi_slave_reset_reset,      // avalon_spi_slave_reset.reset
		input  wire        avalon_spi_slave_irq_irq,          //   avalon_spi_slave_irq.irq
		output wire [7:0]  i2c_master_0_avl_mm_address,       //    i2c_master_0_avl_mm.address
		output wire        i2c_master_0_avl_mm_chipselect,    //                       .chipselect
		output wire        i2c_master_0_avl_mm_write,         //                       .write
		input  wire        i2c_master_0_avl_mm_waitrequest,   //                       .waitrequest
		output wire [31:0] i2c_master_0_avl_mm_writedata,     //                       .writedata
		output wire        i2c_master_0_avl_mm_read,          //                       .read
		input  wire [31:0] i2c_master_0_avl_mm_readdata,      //                       .readdata
		input  wire        i2c_master_0_avl_mm_readdatavalid, //                       .readdatavalid
		output wire        i2c_master_0_avl_reset_reset,      // i2c_master_0_avl_reset.reset
		input  wire [31:0] avl_mst_sbc_address,               //            avl_mst_sbc.address
		output wire        avl_mst_sbc_waitrequest,           //                       .waitrequest
		input  wire        avl_mst_sbc_write,                 //                       .write
		input  wire [31:0] avl_mst_sbc_writedata,             //                       .writedata
		input  wire        avl_mst_sbc_read,                  //                       .read
		output wire [31:0] avl_mst_sbc_readdata,              //                       .readdata
		output wire        avl_mst_sbc_readdatavalid,         //                       .readdatavalid
		output wire        avl_mst_sb_reset_reset,            //       avl_mst_sb_reset.reset
		output wire [7:0]  spi_master_0_avl_mm_address,       //    spi_master_0_avl_mm.address
		output wire        spi_master_0_avl_mm_chipselect,    //                       .chipselect
		output wire        spi_master_0_avl_mm_write,         //                       .write
		input  wire        spi_master_0_avl_mm_waitrequest,   //                       .waitrequest
		output wire [31:0] spi_master_0_avl_mm_writedata,     //                       .writedata
		output wire        spi_master_0_avl_mm_read,          //                       .read
		input  wire [31:0] spi_master_0_avl_mm_readdata,      //                       .readdata
		input  wire        spi_master_0_avl_mm_readdatavalid, //                       .readdatavalid
		output wire        spi_master_0_avl_reset_reset,      // spi_master_0_avl_reset.reset
		input  wire        clk_clk,                           //                    clk.clk
		output wire [9:0]  jesd_low_slave_address,            //         jesd_low_slave.address
		output wire        jesd_low_slave_chipselect,         //                       .chipselect
		output wire        jesd_low_slave_read,               //                       .read
		input  wire [31:0] jesd_low_slave_readdata,           //                       .readdata
		input  wire        jesd_low_slave_waitrequest,        //                       .waitrequest
		output wire        jesd_low_slave_write,              //                       .write
		output wire [31:0] jesd_low_slave_writedata,          //                       .writedata
		output wire        jesd_low_slave_reset_reset_n,      //   jesd_low_slave_reset.reset_n
		output wire [9:0]  jesd_high_slave_address,           //        jesd_high_slave.address
		output wire        jesd_high_slave_chipselect,        //                       .chipselect
		output wire        jesd_high_slave_read,              //                       .read
		input  wire [31:0] jesd_high_slave_readdata,          //                       .readdata
		input  wire        jesd_high_slave_waitrequest,       //                       .waitrequest
		output wire        jesd_high_slave_write,             //                       .write
		output wire [31:0] jesd_high_slave_writedata,         //                       .writedata
		output wire        jesd_high_slave_reset_reset_n,     //  jesd_high_slave_reset.reset_n
		input  wire        pd_debug_uart_rxd,                 //          pd_debug_uart.rxd
		output wire        pd_debug_uart_txd,                 //                       .txd
		input  wire        reset_reset_n,                     //                  reset.reset_n
		input  wire [31:0] ser_debug_master_address,          //       ser_debug_master.address
		output wire        ser_debug_master_waitrequest,      //                       .waitrequest
		input  wire        ser_debug_master_write,            //                       .write
		input  wire [31:0] ser_debug_master_writedata,        //                       .writedata
		input  wire        ser_debug_master_read,             //                       .read
		output wire [31:0] ser_debug_master_readdata,         //                       .readdata
		output wire        ser_debug_master_readdatavalid,    //                       .readdatavalid
		input  wire [3:0]  ser_debug_master_byteenable,       //                       .byteenable
		output wire        ser_debug_master_reset_reset       // ser_debug_master_reset.reset
	);
endmodule

