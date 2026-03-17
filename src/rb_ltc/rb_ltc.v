/*
 * Copyright (c) 2024 Thomas Flummer
 * SPDX-License-Identifier: Apache-2.0
 */

module rb_ltc (
	clk,
	resetb,
	address,
	data_write_in,
	data_read_out,
	reg_en,
	write_en,
	time_cfg,
	ltc_cfg
);
	parameter ADR_BITS = 8;
	input wire clk;
	input wire resetb;
	input wire [ADR_BITS - 1:0] address;
	input wire [7:0] data_write_in;
	output reg [7:0] data_read_out;
	input wire reg_en;
	input wire write_en;
	inout wire [23:0] time_cfg;
	inout wire [39:0] ltc_cfg;
	reg [7:0] reg__ltc_cfg__misc;
	reg [4:0] reg__time_cfg__sec_u;
	reg [4:0] reg__time_cfg__sec_d;
	reg [4:0] reg__time_cfg__min_u;
	reg [4:0] reg__time_cfg__min_d;
	reg [4:0] reg__time_cfg__hrs_u;
	reg [4:0] reg__time_cfg__hrs_d;
	reg [7:0] reg__ltc_cfg__user21;
	reg [7:0] reg__ltc_cfg__user43;
	reg [7:0] reg__ltc_cfg__user65;
	reg [7:0] reg__ltc_cfg__user87;
	always @(posedge clk)
		if (resetb == 0) begin
			reg__ltc_cfg__misc <= 8'b00000000;
			reg__time_cfg__sec_u <= 4'b0000;
			reg__time_cfg__sec_d <= 4'b0000;
			reg__time_cfg__min_u <= 4'b0000;
			reg__time_cfg__min_d <= 4'b0000;
			reg__time_cfg__hrs_u <= 4'b0001;
			reg__time_cfg__hrs_d <= 4'b0000;
			reg__ltc_cfg__user21 <= 8'b00000000;
			reg__ltc_cfg__user43 <= 8'b00000000;
			reg__ltc_cfg__user65 <= 8'b00000000;
			reg__ltc_cfg__user87 <= 8'b00000000;
		end
		else
			if (write_en)
				case (address)
					0:
						reg__ltc_cfg__misc <= data_write_in[7:0];
					1: begin
						reg__time_cfg__sec_u <= data_write_in[3:0];
						reg__time_cfg__sec_d <= data_write_in[7:4];
					end
					2: begin
						reg__time_cfg__min_u <= data_write_in[3:0];
						reg__time_cfg__min_d <= data_write_in[7:4];
					end
					3: begin
						reg__time_cfg__hrs_u <= data_write_in[3:0];
						reg__time_cfg__hrs_d <= data_write_in[7:4];
					end
					4:
						reg__ltc_cfg__user21 <= data_write_in[7:0];
					5:
						reg__ltc_cfg__user43 <= data_write_in[7:0];
					6:
						reg__ltc_cfg__user65 <= data_write_in[7:0];
					7:
						reg__ltc_cfg__user87 <= data_write_in[7:0];
				endcase
	always @(posedge clk)
		if (resetb == 0)
			data_read_out <= 8'b00000000;
		else begin
			data_read_out <= 8'b00000000;
			case (address)
				0:
					data_read_out[7:0] <= reg__ltc_cfg__misc;
				1: begin
					data_read_out[3:0] <= reg__time_cfg__sec_u;
					data_read_out[7:4] <= reg__time_cfg__sec_d;
				end
				2: begin
					data_read_out[3:0] <= reg__time_cfg__min_u;
					data_read_out[7:4] <= reg__time_cfg__min_d;
				end
				3: begin
					data_read_out[3:0] <= reg__time_cfg__hrs_u;
					data_read_out[7:4] <= reg__time_cfg__hrs_d;
				end
				4:
					data_read_out[7:0] <= reg__ltc_cfg__user21;
				5:
					data_read_out[7:0] <= reg__ltc_cfg__user43;
				6:
					data_read_out[7:0] <= reg__ltc_cfg__user65;
				7:
					data_read_out[7:0] <= reg__ltc_cfg__user87;
				default:
					data_read_out <= 8'b00000000;
			endcase
		end
	assign time_cfg[3-:4] = reg__time_cfg__sec_u;
	assign time_cfg[7-:4] = reg__time_cfg__sec_d;
	assign time_cfg[11-:4] = reg__time_cfg__min_u;
	assign time_cfg[15-:4] = reg__time_cfg__min_u;
	assign time_cfg[19-:4] = reg__time_cfg__hrs_u;
	assign time_cfg[23-:4] = reg__time_cfg__hrs_d;

	assign ltc_cfg[7-:8] = reg__ltc_cfg__misc;
	assign ltc_cfg[15-:8] = reg__ltc_cfg__user21;
	assign ltc_cfg[23-:8] = reg__ltc_cfg__user43;
	assign ltc_cfg[31-:8] = reg__ltc_cfg__user65;
	assign ltc_cfg[39-:8] = reg__ltc_cfg__user87;
endmodule
