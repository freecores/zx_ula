`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Dept. Architecture and Computing Technology. University of Seville
// Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
// 
// Create Date:    19:13:39 4-Apr-2012 
// Design Name:    ZX Spectrum
// Module Name:    ram32k
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

module ram32k (
	input [14:0] a,
	input cs_n,
	input oe_n,
	input we_n,
	input [7:0] din,
	output [7:0] dout,
	
	output [17:0] sa,
	inout [15:0] sd,
	output sramce,
	output sramub,
	output sramlb,
	output sramoe,
	output sramwe
	);
	
	assign sa = {3'b000,a};
	assign sramce = cs_n;
	assign sramwe = we_n;
	assign sramoe = oe_n;
	assign sramub = 1;
	assign sramlb = 0;
	
	assign dout = (!cs_n && we_n)? sd : 8'bzzzzzzzz;
	assign sd = (!cs_n && !we_n)? din : 8'bzzzzzzzz;	
endmodule
