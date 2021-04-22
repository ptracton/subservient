`default_nettype none
module subservient_sim
  #(//Memory parameters
    parameter memsize = 512,
    parameter aw    = $clog2(memsize),
    parameter memfile = "",
    parameter with_csr = 1)
   (input wire  i_clk,
    input wire 	i_rst,
    output wire o_gpio);


   reg [1023:0] firmware_file;
   initial
     if ($value$plusargs("firmware=%s", firmware_file)) begin
	$display("Loading RAM from %0s", firmware_file);
	$readmemh(firmware_file, mem);
     end

   wire [aw-1:0] sram_waddr;
   wire [7:0] 	 sram_wdata;
   wire 	 sram_wen;
   wire [aw-1:0] sram_raddr;
   reg [7:0] 	 sram_rdata;
   wire 	 sram_ren;

   reg [7:0] 	 mem [0:memsize-1];

   always @(posedge i_clk) begin
      if (sram_ren)
	sram_rdata <= mem[sram_raddr];
      if (sram_wen)
	mem[sram_waddr] <= sram_wdata;
   end

   subservient
     #(.memsize  (memsize),
       .WITH_CSR (with_csr))
   dut
     (// Clock & reset
      .i_clk (i_clk),
      .i_rst (i_rst),

      //SRAM interface
      .o_sram_waddr (sram_waddr),
      .o_sram_wdata (sram_wdata),
      .o_sram_wen   (sram_wen),
      .o_sram_raddr (sram_raddr),
      .i_sram_rdata (sram_rdata),
      .o_sram_ren   (sram_ren),

      //Debug interface
      .i_debug_mode (1'b0),
      .i_wb_dbg_adr (32'd0),
      .i_wb_dbg_dat (32'd0),
      .i_wb_dbg_sel (4'd0),
      .i_wb_dbg_we  (1'd0),
      .i_wb_dbg_stb (1'd0),
      .o_wb_dbg_rdt (),
      .o_wb_dbg_ack (),

      // External I/O
      .o_gpio (o_gpio));

endmodule
