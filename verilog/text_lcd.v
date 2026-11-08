module text_lcd #(
    parameter integer CLK_HZ = 1000000,
    parameter integer ONE_LINE = 0,
    parameter integer START_COLUMN = 0,
    parameter integer EXTERNAL_CLOCK = 0,
    parameter integer SCROLL = 0,
    parameter integer HOLD_TICKS = 1000
)(
    input wire clk, nrst,
    output wire LCD_E,
    output reg LCD_RS = 0,
    output wire LCD_RW,
    output reg [7:0] LCD_DATA = 0,
    output reg [7:0] LED_out
);
    localparam [3:0] DELAY = 0, FUNCTION_SET = 1,
        ENTRY_MODE = 2, DISP_ONOFF = 3, LINE1 = 4,
        LINE2 = 5, DELAY_T = 6, CLEAR_DISP = 7,
        SHIFT = 8;
    localparam integer NORMAL_CYCLES = CLK_HZ / 1000;
    localparam [127:0] ROW1 = "HELLO WORLD!    ";
    localparam [127:0] ROW2 = "2025440099 LSH  ";
    reg [3:0] state = DELAY;
    reg [15:0] cnt = 0;
    reg [31:0] phase = 0;
    reg [15:0] last_count;
    reg command_valid, command_rs;
    reg [7:0] command_data;
    reg e_pulse = 0, direct_enable = 0;
    assign LCD_E = nrst && (EXTERNAL_CLOCK ? (clk && direct_enable) : e_pulse);
    assign LCD_RW = 1'b0;
    always @(negedge clk or negedge nrst)
        if (!nrst) direct_enable <= 0;
        else direct_enable <= command_valid;

    always @* begin
        last_count = 4;
        case (state)
            DELAY: last_count = 69;
            LINE1, LINE2: last_count = 16;
            DELAY_T: last_count = HOLD_TICKS - 1;
            SHIFT: last_count = 0;
            default: last_count = 4;
        endcase
        case (state)
            DELAY: LED_out = 8'h80;
            FUNCTION_SET: LED_out = 8'h40;
            DISP_ONOFF: LED_out = 8'h20;
            ENTRY_MODE: LED_out = 8'h10;
            LINE1: LED_out = 8'h08;
            LINE2: LED_out = 8'h04;
            DELAY_T: LED_out = 8'h02;
            CLEAR_DISP: LED_out = 8'h01;
            SHIFT: LED_out = 8'h03;
            default: LED_out = 8'h00;
        endcase
        if (!nrst) LED_out = 8'h80;
    end

    always @* begin
        command_valid = 1'b0;
        command_rs = 1'b0;
        command_data = 8'h00;
        case (state)
            FUNCTION_SET: if (cnt == 0) begin
                command_valid = 1'b1;
                command_data = ONE_LINE ? 8'h30 : 8'h38;
            end
            DISP_ONOFF: if (cnt == 0) begin
                command_valid = 1'b1; command_data = 8'h0c;
            end
            ENTRY_MODE: begin
                // Clear once during initialization, with 2 ms spacing.
                command_valid = (cnt == 0 || cnt == 2);
                command_data = (cnt == 0) ? 8'h06 : 8'h01;
            end
            LINE1: begin
                command_valid = 1'b1;
                command_rs = (cnt != 0);
                if (cnt == 0) command_data = 8'h80 + START_COLUMN;
                else command_data = ROW1[127-(cnt-1)*8 -: 8];
            end
            LINE2: begin
                command_valid = 1'b1;
                command_rs = (cnt != 0);
                if (cnt == 0) command_data = 8'hc0 + START_COLUMN;
                else command_data = ROW2[127-(cnt-1)*8 -: 8];
            end
            CLEAR_DISP: if (cnt == 0) begin
                command_valid = 1'b1; command_data = 8'h01;
            end
            SHIFT: begin
                command_valid = 1'b1; command_data = 8'h18;
            end
            default: command_valid = 1'b0;
        endcase
        if (!nrst) command_valid = 1'b0;
    end

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            state <= DELAY; cnt <= 0; phase <= 0;
            e_pulse <= 0; LCD_RS <= 0; LCD_DATA <= 0;
        end else begin
            // Latch data before E rises; only valid transfers pulse E.
            if (EXTERNAL_CLOCK || phase == 0) begin
                e_pulse <= 0;
                if (command_valid) begin
                    LCD_RS <= command_rs;
                    LCD_DATA <= command_data;
                end
            end
            if (!EXTERNAL_CLOCK && phase == NORMAL_CYCLES / 4)
                e_pulse <= command_valid;
            if (!EXTERNAL_CLOCK && phase == 3 * NORMAL_CYCLES / 4)
                e_pulse <= 0;
            if (EXTERNAL_CLOCK || phase == NORMAL_CYCLES - 1) begin
                phase <= 0;
                if (cnt == last_count) begin
                    cnt <= 0;
                    case (state)
                        DELAY: state <= FUNCTION_SET;
                        FUNCTION_SET: state <= DISP_ONOFF;
                        DISP_ONOFF: state <= ENTRY_MODE;
                        ENTRY_MODE: state <= LINE1;
                        LINE1: state <= LINE2;
                        LINE2: state <= DELAY_T;
                        DELAY_T: state <= SCROLL ? SHIFT : CLEAR_DISP;
                        CLEAR_DISP: state <= LINE1;
                        SHIFT: state <= DELAY_T;
                        default: state <= DELAY;
                    endcase
                end else cnt <= cnt + 1'b1;
            end else phase <= phase + 1'b1;
        end
    end
endmodule
