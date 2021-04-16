`default_nettype none
module subservient_tb;

   parameter memfile = "";
   parameter memsize = 8192;
   parameter with_csr = 0;
   parameter aw    = $clog2(memsize);

   reg clk = 1'b0;
   reg rst = 1'b1;

   wire [aw-1:0] sram_waddr;
   wire [7:0] 	 sram_wdata;
   wire 	 sram_wen;
   wire [aw-1:0] sram_raddr;
   wire [7:0] 	 sram_rdata;
   wire 	 sram_ren;

   //Debug interface
   reg 		 debug_mode;
   reg [31:0] 	 wb_dbg_adr;
   reg [31:0] 	 wb_dbg_dat;
   reg [3:0] 	 wb_dbg_sel;
   reg 		 wb_dbg_we;
   reg 		 wb_dbg_stb = 1'b0;
   wire [31:0] 	 wb_dbg_rdt;
   wire 	 wb_dbg_ack;

   wire q;

   always  #5 clk <= !clk;
   initial #62 rst <= 1'b0;

   vlog_tb_utils vtu();

   integer baudrate = 0;
   initial begin
      if ($value$plusargs("uart_baudrate=%d", baudrate))
	$display("UART decoder using baud rate %d", baudrate);
      else
	forever
	  @(q) $display("%0t output o_gpio is %s", $time, q ? "ON" : "OFF");

   end

   reg [1023:0] firmware_file;
   integer 	idx = 0;
   reg [7:0] 	 mem [0:memsize-1];

   task wb_dbg_write32(input [31:0] adr, input [31:0] dat);
      begin
	 @ (posedge clk) begin
	    wb_dbg_adr <= adr;
	    wb_dbg_dat <= dat;
	    wb_dbg_sel <= 4'b1111;
	    wb_dbg_we  <= 1'b1;
	    wb_dbg_stb <= 1'b1;
	 end
	 while (!wb_dbg_ack)
	   @ (posedge clk);
	 wb_dbg_stb <= 1'b0;
      end
   endtask

   reg [31:0] tmp_dat;
   integer    adr;
   reg [1:0]  bsel;

   initial begin
      if ($value$plusargs("firmware=%s", firmware_file)) begin
	 $display("Writing %0s to SRAM", firmware_file);
	 $readmemh(firmware_file, mem);
      end else
	$display("No application to load. SRAM will be empty");

      $display("Setting debug mode");
      debug_mode <= 1'b1;
      repeat (10) @(posedge clk);

      //Write full 32-bit words
      while ((mem[idx] !== 8'bxxxxxxxx) && (idx < memsize)) begin
	 adr = (idx >> 2)*4;
	 bsel = idx[1:0];
	 tmp_dat[bsel*8+:8] = mem[idx];
	 if (bsel == 2'd3)
	   wb_dbg_write32(adr, tmp_dat);
	 //$display("%02h", mem[idx]);
	 idx = idx + 1;
      end

      //Write final bytes if required
      if (idx[1:0]) begin
	 adr = (idx >> 2)*4;
	 bsel = idx[1:0];
	 tmp_dat = 32'd0;
	 if (bsel >= 1)
	   tmp_dat[7:0] = mem[idx];
	 if (bsel >= 2)
	   tmp_dat[15:8] = mem[idx+1];
	 if (bsel >= 3)
	   tmp_dat[23:16] = mem[idx+2];
	 wb_dbg_write32(adr, tmp_dat);
      end
      repeat (10) @(posedge clk);

      $display("Done writing SRAM. Turning off debug mode");
      debug_mode <= 1'b0;
   end

   uart_decoder #(57600) uart_decoder (q & |baudrate);

   //Adapt the 8-bit SRAM interface from subservient to the 32-bit OpenRAM instance
   reg [1:0] sram_bsel;
   always @(posedge clk) begin
      sram_bsel  <= sram_raddr[1:0];
      //sram_rdata <= dout1[sram_bsel*8+:8]; //Pick the right byte from the read data
   end

   wire [3:0] wmask0 = 4'd1 << sram_waddr[1:0];
   wire [7:0] waddr0 = sram_waddr[9:2]; //256 32-bit words = 1kB
   wire [31:0] din0 = {4{sram_wdata}}; //Mirror write data to all byte lanes

   wire [7:0]  addr1 = sram_raddr[9:2];
   wire [31:0] dout1;
   assign sram_rdata = dout1[sram_bsel*8+:8]; //Pick the right byte from the read data
   
   sky130_sram_1kbyte_1rw1r_32x256_8
     #(// FIXME: This delay is arbitrary.
       .DELAY (3),
       .VERBOSE (0))
   sram
     (
      .clk0   (clk),
      .csb0   (!sram_wen),
      .web0   (!sram_wen),
      .wmask0 (wmask0),
      .addr0  (waddr0),
      .din0   (din0),
      .dout0  (),
      .clk1   (clk),
      .csb1   (!sram_ren),
      .addr1  (addr1),
      .dout1  (dout1));

/*
   reg [7:0] 	 sram [0:memsize-1];

   always @(posedge clk) begin
      sram_rdata <= sram[sram_raddr];
      if (sram_wen)
	sram[sram_waddr] <= sram_wdata;
   end
*/ 

   subservient
     #(.memsize  (memsize),
       .WITH_CSR (with_csr))
   dut
     (// Clock & reset
      .i_clk (clk),
      .i_rst (rst),

      //SRAM interface
      .o_sram_waddr (sram_waddr),
      .o_sram_wdata (sram_wdata),
      .o_sram_wen   (sram_wen),
      .o_sram_raddr (sram_raddr),
      .i_sram_rdata (sram_rdata),
      .o_sram_ren   (sram_ren),

      //Debug interface
      .i_debug_mode (debug_mode),
      .i_wb_dbg_adr (wb_dbg_adr),
      .i_wb_dbg_dat (wb_dbg_dat),
      .i_wb_dbg_sel (wb_dbg_sel),
      .i_wb_dbg_we  (wb_dbg_we ),
      .i_wb_dbg_stb (wb_dbg_stb),
      .o_wb_dbg_rdt (wb_dbg_rdt),
      .o_wb_dbg_ack (wb_dbg_ack),

      // External I/O
      .o_gpio (q));

endmodule
