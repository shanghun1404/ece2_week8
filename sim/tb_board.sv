`timescale 1us/1ns
module tb_board;
    reg clk = 0, btn_reset = 0;
    always #0.5 clk = ~clk;
    wire [4:0] e, rs, rw;
    wire [7:0] data[0:4], leds[0:4];
    wire [31:0] frames[0:4], shifts[0:4];
    lab8_a_basic a(clk,btn_reset,e[0],rs[0],rw[0],data[0],leds[0]);
    // B is tested with an adjustable external clock in tb_external.
    assign e[1] = 0;
    lab8_c_single c(clk,btn_reset,e[2],rs[2],rw[2],data[2],leds[2]);
    lab8_d_offset d(clk,btn_reset,e[3],rs[3],rw[3],data[3],leds[3]);
    lab8_e_scroll s(clk,btn_reset,e[4],rs[4],rw[4],data[4],leds[4]);
    wire nrst = a.nrst;
    lcd_checker #(.MODE(0)) c0(clk,nrst,e[0],rs[0],rw[0],data[0],frames[0],shifts[0]);
    lcd_checker #(.MODE(1),.ONE_LINE(1)) c2(clk,nrst,e[2],rs[2],rw[2],data[2],frames[2],shifts[2]);
    lcd_checker #(.MODE(2),.COLUMN(3)) c3(clk,nrst,e[3],rs[3],rw[3],data[3],frames[3],shifts[3]);
    lcd_checker #(.MODE(4)) c4(clk,nrst,e[4],rs[4],rw[4],data[4],frames[4],shifts[4]);
    realtime previous_shift = 0;
    integer shift_count = 0;
    always @(negedge e[4]) if (nrst && rs[4] == 0 && data[4] == 8'h18) begin
        if (shift_count > 0 && $realtime-previous_shift != 301000)
            $fatal(1,"FAIL: marquee shift is not 301ms");
        previous_shift = $realtime; shift_count = shift_count+1;
    end
    always @(posedge btn_reset) begin shift_count = 0; previous_shift = 0; end
    initial begin
        #175000;
        if (frames[0] != 1 || frames[2] != 1 || frames[3] != 1 || frames[4] != 1)
            $fatal(1,"FAIL: power-on board frames");
        #925000;
        if (shifts[4] != 3 || frames[4] != 1) $fatal(1,"FAIL: board scroll period");
        @(negedge clk); btn_reset = 1; #0.1;
        if (e !== 0 || nrst !== 0) $fatal(1,"FAIL: SM9 assertion");
        #10; @(negedge clk); btn_reset = 0;
        @(posedge clk); #0.1;
        if (nrst !== 0) $fatal(1,"FAIL: reset release first cycle");
        @(posedge clk); #0.1;
        if (nrst !== 1) $fatal(1,"FAIL: reset release second cycle");
        #175000;
        if (frames[0] != 1 || frames[2] != 1 || frames[3] != 1 || frames[4] != 1)
            $fatal(1,"FAIL: board restart frames");
        $display("BOARD_PASS power-on variants 301ms marquee SM9 synchronized-release restart");
        $finish;
    end
    initial begin #1500000; $fatal(1,"FAIL: board timeout"); end
endmodule
