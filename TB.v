`timescale 1ns / 1ps

module tb_usbModule;

    // Testbench signals
    reg CLK_USB;
    reg SYS_RST;
    reg DIR;
    reg NXT;
    reg SYSTEM_READY;
    wire STP;
    wire USB_RST;
    wire [7:0] DATA_OUT;

    // Instantiate the usbModule
    usbModule uut (
        .STP(STP),
        .USB_RST(USB_RST),
        .DATA_OUT(DATA_OUT),
        .CLK_USB(CLK_USB),
        .DIR(DIR),
        .NXT(NXT),
        .SYS_RST(SYS_RST),
        .SYSTEM_READY(SYSTEM_READY)
    );

    // Clock generation
    initial begin
        CLK_USB = 0;
        forever #5 CLK_USB = ~CLK_USB; // 100 MHz clock
    end

    // Stimulus
    initial begin
        // Initialize inputs
        SYS_RST = 1;
        DIR = 0;
        NXT = 0;
        SYSTEM_READY = 0;

        // Apply reset
        #20;
        SYS_RST = 0;

        // Wait for boot up to complete
        #50000;
       
        // Begin sending data
        SYSTEM_READY = 1;

        // Stimulate the state machine for SET_FUNCTION_CONTROL
        #100;
        NXT = 0;
        DIR = 0;
        #10;
       
        // At data counter 2, NXT should be high
       
    end
always@(negedge CLK_USB)
        begin
            if(uut.data_counter == (16'd2 || 16'd3)) NXT<=1'd1;
            ///
            //STP<=0;
            else NXT<=1'd0;
        end
    // Monitor
    initial begin
        $monitor("Time = %0t, SYS_STATE = %d, TX_DATA = %h, STP = %b, USB_RST = %b, DIR = %b, NXT = %b",
                 $time, uut.SYS_STATE, DATA_OUT, STP, USB_RST, DIR, NXT);
    end

endmodule

