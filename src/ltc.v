/*
 * Copyright (c) 2025 Thomas Flummer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module ltc (
    input wire clk, 
    input wire reset_n,
    input wire [1:0] framerate,
    input wire [2:0] bgf,
    input wire dropframe,
    input wire colorframe,
    input wire [31:0] userbits,
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
    reg [13:0] bit_counter;
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
            // frame counter
            // 12MHz: 24 fps: 500000, 25 fps: 480000, 30 fps: 400000
            // 24MHz: 24 fps: 1000000, 25 fps: 960000, 30 fps: 800000
            frm_counter <= frm_counter + 1;
            if((framerate == 2'b00 && frm_counter + 1 == 1_000_000) || (framerate == 2'b01 && frm_counter + 1 == 960_000) || (framerate == 2'b11 && frm_counter + 1 == 800_000)) begin
                frm_u <= frm_u + 1;
                frm_counter <= 0;
            end

            if(frm_counter == 1) begin
                if(frm_u == 10) begin
                    frm_u <= 0;
                    frm_d <= frm_d + 1;
                end
            end

            if(frm_counter == 2) begin
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
            end

            if(frm_counter == 3) begin
                output_buffer <= {frm_u[0],
                frm_u[1],
                frm_u[2],
                frm_u[3],
                userbits[3:0], // user bits field 1
                frm_d[0],
                frm_d[1],
                dropframe, // drop frame flag, 1 = dropframe, 0 = non drop frame
                colorframe, // color frame flag
                userbits[7:4], // user bits field 2
                sec_u[0],
                sec_u[1],
                sec_u[2],
                sec_u[3],
                userbits[11:8], // user bits field 3
                sec_d[0],
                sec_d[1],
                sec_d[2],
                (framerate == 2'b01) ? bgf[0] : 1'b0, // flag (bit 27)
                userbits[15:12], // user bits field 4
                min_u[0],
                min_u[1],
                min_u[2],
                min_u[3],
                userbits[19:16], // user bits field 5
                min_d[0],
                min_d[1],
                min_d[2],
                (framerate == 2'b01) ? bgf[2] : bgf[0], // flag (bit 43)
                userbits[23:20], // user bits field 6
                hrs_u[0],
                hrs_u[1],
                hrs_u[2],
                hrs_u[3],
                userbits[27:24], // user bits field 7
                hrs_d[0],
                hrs_d[1],
                bfg[1], // clock flag
                (framerate == 2'b01) ? 1'b0 : bgf[2], // flag (bit 59)
                userbits[31:28], // user bits field 8
                16'b0011111111111101}; // sync word, fixed pattern
            end

            if(frm_counter == 4) begin
                if(framerate == 2'b00 || framerate == 2'b11) begin // 24 or 30 fps
                    output_buffer[52] <= ~^output_buffer[79:16];
                end
                if(framerate == 2'b01) begin // 25 fps
                    output_buffer[20] <= ~^output_buffer[79:16];
                end
            end

            // 80 bits per frame
            // bit counter
            // 12MHz: 24 fps: 3125, 25 fps: 3000, 30 fps: 2500
            // 24MHz: 24 fps: 6250, 25 fps: 6000, 30 fps: 5000
            bit_counter <= bit_counter + 1;
            if((framerate == 2'b00 && bit_counter + 1 == 6_250) || (framerate == 2'b01 && bit_counter + 1 == 6_000) || (framerate == 2'b11 && bit_counter + 1 == 5_000)) begin
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