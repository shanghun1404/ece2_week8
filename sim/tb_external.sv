`timescale 1us/1ns
module tb_external;
    reg clk = 0, btn_reset = 1;
    realtime half_period = 500;
    always begin #(half_period); clk = ~clk; end
    wire e,rs,rw;
    wire [7:0] data,leds;
    lab8_b_external dut(clk,btn_reset,e,rs,rw,data,leds);
    wire [31:0] frames,shifts;
    lcd_checker #(.MODE(3)) check_lcd(clk,dut.nrst,e,rs,rw,data,frames,shifts);
    realtime last_write = 0;
    integer writes = 0;
    reg check_period = 0;
    realtime expected_period = 1000000;
    always @(negedge e) if (dut.nrst) begin
        writes = writes+1;
        if (check_period && $realtime-last_write != expected_period)
            $fatal(1,"FAIL: external clock did not directly control transfer cadence");
        last_write = $realtime;
    end
    initial begin
        #100; btn_reset = 0;
        // Initialization must advance on the external 1 kHz clock.
        #125000;
        if (frames != 1) $fatal(1,"FAIL: external 1kHz frame did not complete");
        wait (dut.U0.state == 4 && dut.U0.cnt == 1);
        @(negedge clk); half_period = 500000;
        // Ignore the first interval while the generator changes frequency.
        repeat (2) @(negedge e);
        check_period = 1;
        repeat (3) @(negedge e);
        check_period = 0;
        @(negedge clk); half_period = 250000;
        repeat (2) @(negedge e);
        expected_period = 500000; check_period = 1;
        repeat (3) @(negedge e);
        check_period = 0;
        @(negedge clk); btn_reset = 1; #0.1;
        if (e !== 0) $fatal(1,"FAIL: external clock reset");
        $display("EXTERNAL_CLOCK_PASS 1kHz initialization, 1Hz and 2Hz direct transfers, reset");
        $finish;
    end
    initial begin #10000000; $fatal(1,"FAIL: external clock timeout"); end
endmodule
