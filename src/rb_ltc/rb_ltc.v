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
	updatetime,
	set_time_cfg,
	cur_time_cfg,
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
	output reg updatetime;
	output reg [31:0] set_time_cfg;
	input wire [31:0] cur_time_cfg;
	inout wire [39:0] ltc_cfg;
	reg [7:0] reg__ltc_cfg__misc;
	reg [7:0] reg__ltc_cfg__user12;
	reg [7:0] reg__ltc_cfg__user34;
	reg [7:0] reg__ltc_cfg__user56;
	reg [7:0] reg__ltc_cfg__user78;

	reg [3:0] update_pulse;

	always @(posedge clk)
		if (resetb == 0) begin
			reg__ltc_cfg__misc <= 8'b00000000;
			reg__ltc_cfg__user12 <= 8'b00000000;
			reg__ltc_cfg__user34 <= 8'b00000000;
			reg__ltc_cfg__user56 <= 8'b00000000;
			reg__ltc_cfg__user78 <= 8'b00000000;
			updatetime <= 1'b0;
		end
		else
			if (write_en)
				case (address)
					0:
						reg__ltc_cfg__misc <= data_write_in[7:0]; // condif
					1: begin
						set_time_cfg[31:24] <= data_write_in[7:0]; // hrs
						updatetime <= 1'b1;
						update_pulse <= 4'b0;
					end
					2: begin
						set_time_cfg[23:16] <= data_write_in[7:0]; // min
						updatetime <= 1'b1;
						update_pulse <= 4'b0;
					end
					3: begin
						set_time_cfg[15:8] <= data_write_in[7:0]; // sec
						updatetime <= 1'b1;
						update_pulse <= 4'b0;
					end
					4: begin
						set_time_cfg[7:0] <= data_write_in[7:0]; // frm
						updatetime <= 1'b1;
						update_pulse <= 4'b0;
					end
					5:
						reg__ltc_cfg__user12 <= data_write_in[7:0];
					6:
						reg__ltc_cfg__user34 <= data_write_in[7:0];
					7:
						reg__ltc_cfg__user56 <= data_write_in[7:0];
					8:
						reg__ltc_cfg__user78 <= data_write_in[7:0];
				endcase
			else begin
				if(updatetime == 1'b1)
					update_pulse <= update_pulse + 1; 
				if(update_pulse[3] == 1'b1)
					updatetime <= 1'b0;
				if(updatetime == 1'b0)
					set_time_cfg <= cur_time_cfg;
			end
	always @(posedge clk)
		if (resetb == 0)
			data_read_out <= 8'b00000000;
		else begin
			data_read_out <= 8'b00000000;
			case (address)
				0:
					data_read_out[7:0] <= reg__ltc_cfg__misc;
				1:
					data_read_out[7:0] <= cur_time_cfg[31:24]; // hrs
				2:
					data_read_out[7:0] <= cur_time_cfg[23:16]; // min
				3:
					data_read_out[7:0] <= cur_time_cfg[15:8]; // sec
				4: 
					data_read_out[7:0] <= cur_time_cfg[7:0]; // frm
				5:
					data_read_out[7:0] <= reg__ltc_cfg__user12;
				6:
					data_read_out[7:0] <= reg__ltc_cfg__user34;
				7:
					data_read_out[7:0] <= reg__ltc_cfg__user56;
				8:
					data_read_out[7:0] <= reg__ltc_cfg__user78;
				default:
					data_read_out <= 8'b00000000;
			endcase
		end

	assign ltc_cfg[7-:8] = reg__ltc_cfg__misc;
	assign ltc_cfg[15-:8] = reg__ltc_cfg__user12;
	assign ltc_cfg[23-:8] = reg__ltc_cfg__user34;
	assign ltc_cfg[31-:8] = reg__ltc_cfg__user56;
	assign ltc_cfg[39-:8] = reg__ltc_cfg__user78;
endmodule
