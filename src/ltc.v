/*
 * Copyright (c) 2025 Thomas Flummer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module ltc (
    input wire clk, 
    input wire reset_n,
    input wire [1:0] framerate,
    output reg timecode
	);

	wire reset = !reset_n;

    reg [3:0] frm_u;
    reg [1:0] frm_d;
	reg [3:0] sec_u;
    reg [2:0] sec_d;
    reg [3:0] min_u;
    reg [2:0] min_d;
    reg [3:0] hrs_u;
    reg [1:0] hrs_d;
    reg [23:0] frm_counter;
    reg [11:0] bit_counter;
    reg [79:0] output_buffer;

	reg bit_clk;

	always @(posedge sys_clk) begin
        if(reset) begin
            frm_u <= 0;
            frm_d <= 0;
            sec_u <= 0;
            sec_d <= 0;
            min_u <= 0;
            min_d <= 0;
            hrs_u <= 1;
            hrs_d <= 0;
            frm_counter <= 0;
            bit_counter <= 0;
            bit_clk <= 1'b0;
            output_buffer <= 0;
            timecode <= 0;
        end else begin
            if(frm_u == 10) begin
                frm_u <= 0;
                frm_d <= frm_d + 1;
            end
            if((framerate == 2'b00 && frm_d == 2 && frm_u == 4) || (framerate == 2'b01 && frm_d == 2 && frm_u == 5) || (framerate == 2'b11 && frm_d == 3 && frm_u == 0)) begin
                frm_u <= 0;
                frm_d <= 0;
                sec_u <= sec_u + 1;
            end
            if(sec_u == 10) begin
                sec_u <= 0;
                sec_d <= sec_d + 1;
            end
            if(sec_d == 6) begin
                sec_d <= 0;
                min_u <= min_u + 1;
            end
            if(min_u == 10) begin
                min_u <= 0;
                min_d <= min_d + 1;
            end
            if(min_d == 6) begin
                min_d <= 0;
                hrs_u <= hrs_u + 1;
            end
            if(hrs_u == 10) begin
                hrs_u <= 0;
                hrs_d <= hrs_d + 1;
            end
            if(hrs_d == 2 && hrs_u == 4) begin
                hrs_u <= 0;
                hrs_d <= 0;
            end

            // frame counter
            // 12MHz: 25 fps: 480000, 24 fps: 500000, 30 fps: 400000
            frm_counter <= frm_counter + 1;
            if((framerate == 2'b00 && frm_counter + 1 == 500_000) || (framerate == 2'b01 && frm_counter + 1 == 480_000) || (framerate == 2'b11 && frm_counter + 1 == 400_000)) begin
                frm_u <= frm_u + 1;
                frm_counter <= 0;
            end

            if(frm_counter == 1) begin
                output_buffer <= {frm_u[0],
                frm_u[1],
                frm_u[2],
                frm_u[3],
                4'b0, // user bits field 1
                frm_d[0],
                frm_d[1],
                1'b0, // drop frame flag, 1 = dropframe, 0 = non drop frame
                1'b0, // color frame flag
                4'b0, // user bits field 2
                sec_u[0],
                sec_u[1],
                sec_u[2],
                sec_u[3],
                4'b0, // user bits field 3
                sec_d[0],
                sec_d[1],
                sec_d[2],
                1'b0, // flag (bit 27)
                4'b0, // user bits field 4
                min_u[0],
                min_u[1],
                min_u[2],
                min_u[3],
                4'b0, // user bits field 5
                min_d[0],
                min_d[1],
                min_d[2],
                1'b0, // flag (bit 43)
                4'b0, // user bits field 6
                hrs_u[0],
                hrs_u[1],
                hrs_u[2],
                hrs_u[3],
                4'b0, // user bits field 7
                hrs_d[0],
                hrs_d[1],
                1'b0, // clock flag
                1'b0, // flag (bit 59)
                4'b0, // user bits field 8
                16'b0011111111111101}; // sync word, fixed pattern
            end

            if(frm_counter == 2) begin
                if(framerate == 2'b00 || framerate == 2'b11) begin // 24 or 30 fps
                    output_buffer[52] <= ~^output_buffer[79:16];
                end
                if(framerate == 2'b01) begin // 25 fps
                    output_buffer[20] <= ~^output_buffer[79:16];
                end
            end

            // 80 bits per frame
            bit_counter <= bit_counter + 1;
            if((framerate == 2'b00 && bit_counter + 1 == 3_125) || (framerate == 2'b01 && bit_counter + 1 == 3_000) || (framerate == 2'b11 && bit_counter + 1 == 2_500)) begin
                bit_clk <= ~bit_clk;
                bit_counter <= 0;
            end

            if(bit_counter == 0) begin
                if(bit_clk) begin
                    timecode <= ~timecode; // every bit needs a transition on the output
                end
                if(~bit_clk) begin
                    if(output_buffer[79] == 1'b1)
                        timecode <= ~timecode; // only bits that are set needs an extra transition
                    output_buffer <= (output_buffer<<1);
                end
            end
        end
    end

	wire sys_clk;
    assign sys_clk = clk;

endmodule

`default_nettype wire