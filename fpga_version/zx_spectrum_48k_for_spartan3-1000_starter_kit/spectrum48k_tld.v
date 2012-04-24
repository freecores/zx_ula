`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Dept. Architecture and Computing Technology. University of Seville
// Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
// 
// Create Date:    19:13:39 4-Apr-2012 
// Design Name:    ZX Spectrum
// Module Name:    tld_spartan3_sp48k
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 1.00 - File Created
// Additional Comments: GPL License policies apply to the contents of this file.
//
//////////////////////////////////////////////////////////////////////////////////
module tld_spartan3_sp48k (
    input clk50,
	 input reset,
    output r,
    output g,
    output b,
    output i,
    output csync,
	// ULA I/O 
	 input ear,
	 output audio_out,
	 output [7:0] kbd_rows,
	 input [4:0] kbd_columns,
	// diagnostics
	 output [7:0] leds,
	// SRAM memory
  	 output [17:0] sa, 
	 inout [15:0] sd1,
	 output sramce1,
	 output sramub1,
	 output sramlb1,
	 output sramoe,
	 output sramwe	
    );

	// CPU signals
	wire [15:0] a;
	wire [7:0] cpudout;
	wire [7:0] cpudin;
	wire clkcpu;
	wire mreq_n;
	wire iorq_n;
	wire wr_n;
	wire rd_n;
	wire rfsh_n;
	wire int_n;

	// VRAM signals
	wire [13:0] va;
	wire [7:0] vramdin;
	wire [7:0] vramdout;
	wire vramoe;
	wire vramcs;
	wire vramwe;
	
	// I/O
	wire mic;
	wire spk;
	assign audio_out = spk;

	// ULA data bus
	wire [7:0] uladout;
	wire [7:0] uladin;
	
	// SRAM data bus
	wire [7:0] sramdout;
	wire [7:0] sramdin;	
	
	// ROM data bus
	wire [7:0] romdout;

	wire sram_cs = a[15] & !mreq_n;
	wire ula_cs = !a[0] & !iorq_n;
	wire vram_cs = !a[15] & a[14] & !mreq_n;
	wire port255_cs = !iorq_n && a[7:0]==8'hFF && !rd_n;
	wire rom_cs = !a[15] & !a[14] & !mreq_n & !rd_n;

	/////////////////////////////////////
	// Master clock (14MHz) generation
	/////////////////////////////////////
	wire clk28mhz;
   master_clock clock28mhz (
    .CLKIN_IN(clk50), 
    .CLKFX_OUT(clk28mhz), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT()
    );
	reg clk14 = 0;
	always @(posedge clk28mhz) begin
		clk14 = !clk14;
	end
	wire clkula = clk14;
	wire clkmem = clk28mhz;
	
   /////////////////////////////////////
   // ROM
   /////////////////////////////////////	
	rom the_rom (
		.clka(clkmem),
		.ena(rom_cs),
		.addra(a[13:0]),
		.douta(romdout)
	);

   /////////////////////////////////////
   // VRAM (first 16K of RAM)
   /////////////////////////////////////	
	vram lower_ram (
		.clka(clkmem),
		.addra(va),
		.dina(vramdin),
		.douta(vramdout),
		.ena(vramcs),
		.wea(vramwe)
	);

   /////////////////////////////////////
   // SRAM (top 32K of RAM). External SRAM chip
   /////////////////////////////////////	
   ram32k upper_ram (
		.a(a[14:0]),
		.cs_n(!sram_cs),
		.oe_n(rd_n),
		.we_n(wr_n),
		.din(sramdin),
		.dout(sramdout),
		.sa(sa),
		.sd(sd1),
		.sramce(sramce1),
		.sramub(sramub1),
		.sramlb(sramlb1),
		.sramoe(sramoe),
		.sramwe(sramwe)
	);

   /////////////////////////////////////
   // The ULA
   /////////////////////////////////////	
	ula the_ula (
		.clk14(clkula), 
		.a(a), 
		.din(uladin), 
		.dout(uladout), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.rfsh_n(rfsh_n),
		.clkcpu(clkcpu), 
		.msk_int_n(int_n), 
		.va(va), 
		.vramdout(vramdout), 
		.vramdin(vramdin), 
		.vramoe(vramoe), 
		.vramcs(vramcs), 
		.vramwe(vramwe), 
		.ear(ear), 
		.mic(mic), 
		.spk(spk), 
		.kbrows(kbd_rows), 
		.kbcolumns(kbd_columns), 
		.r(r), 
		.g(g), 
		.b(b), 
		.i(i), 
		.csync(csync)
	);

   /////////////////////////////////////
   // The CPU Z80A
   /////////////////////////////////////	
   tv80n cpu (
		// Outputs
		.m1_n(),
		.mreq_n(mreq_n),
		.iorq_n(iorq_n),
		.rd_n(rd_n),
		.wr_n(wr_n),
		.rfsh_n(rfsh_n),
		.halt_n(),
		.busak_n(),
		.A(a),
		.dout(cpudout), 
		// Inputs
		.reset_n(!reset),
		.clk(clkcpu),
		.wait_n(1'b1),
		.int_n(int_n),
		.nmi_n(1'b1),
		.busrq_n(1'b1),
		.di(cpudin)
   );

   /////////////////////////////////////
   // Connecting all togther
   /////////////////////////////////////	
	assign sramdin = cpudout;
	assign uladin = cpudout;
	assign cpudin = (rom_cs)? romdout :
	                (ula_cs | vram_cs | port255_cs)? uladout :
						 (sram_cs)? sramdout :
						            8'b10101010;

   /////////////////////////////////////
   // Diagnostics
   /////////////////////////////////////	
	reg [7:0] rLeds = 8'b10000000;
	assign leds = rLeds;
	reg [2:0] cntleds = 3'b000;
	always @(posedge int_n) begin
		cntleds <= cntleds + 1;
		if (cntleds == 3'b111) begin
			rLeds <= { rLeds[0], rLeds[7:1] };
		end
	end
	
endmodule
