`default_nettype none
module subservient_sim
  #(//Memory parameters
    parameter memsize = 512,
    parameter aw    = $clog2(memsize))
  (input wire  i_clk,
   input wire  i_rst,
   output wire q);

   parameter memfile = "";
   parameter with_csr = 1;

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
   wire [7:0] 	 sram_rdata;

   reg [7:0] 	 mem [0:memsize-1];

   always @(posedge i_clk) begin
      sram_rdata <= mem[sram_raddr];
      if (sram_wen)
	mem[sram_waddr] <= sram_wdata;
   end

   subservient
     #(.memfile  (memfile),
       .memsize  (memsize),
       .with_csr (with_csr))
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
      // External I/O
      .o_gpio (o_gpio));

endmodule