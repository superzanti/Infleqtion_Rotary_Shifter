`timescale 1ns/1ps

module rot_shifter_axi_tb;

    // Clock and reset
    logic clk;
    logic rst_n;

    // AXI4-Stream interface
    logic [63:0] s_axis_tdata;
    logic [7:0]  s_axis_tuser;
    logic        s_axis_tvalid;
    logic        s_axis_tready;

    logic [63:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready;

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    rot_shifter_axi #(
        .PIPELINE_INPUT(1),
        .PIPELINE_OUTPUT(1),
        .REGISTER_RESET(0)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    // Reset sequence
    initial begin
        rst_n = 0;
        s_axis_tdata = 64'd0;
        s_axis_tuser = 8'd0;
        s_axis_tvalid = 0;
        m_axis_tready = 1;
        #60;
        rst_n = 1;
    end

    // Task to drive one AXI transaction
    task send_axi(input logic [63:0] data, input logic [7:0] shift);
        begin
            s_axis_tdata <= data;
            s_axis_tuser <= shift;
            s_axis_tvalid <= 1;
            m_axis_tready <= 1;
            wait(s_axis_tready);
            @(posedge clk);
            s_axis_tvalid <= 0;
            @(posedge clk);
        end
    endtask

    // Function to perform software rotation
    function automatic logic [63:0] rot64(input logic [63:0] data, input logic [5:0] shift);
        rot64 = (data << shift) | (data >> (64-shift));
    endfunction

    // Self-checking procedure
    initial begin
        logic [63:0] expected;
        logic [63:0] test_data [0:3];
        logic [7:0]  test_shift [0:3];

        // Example deterministic tests from your spec
        test_data[0] = 64'b0000100000000000000000000000000010100000000000000000000000000001;
        test_shift[0] = 8'd0;

        test_data[1] = test_data[0];
        test_shift[1] = 8'd3;

        test_data[2] = test_data[0];
        test_shift[2] = 8'd10;

        test_data[3] = test_data[0];
        test_shift[3] = 8'd63;

        // Wait for reset deassertion
        @(posedge rst_n);
        @(posedge clk);

        // Run deterministic test cases
        for (int i = 0; i < 4; i++) begin
            send_axi(test_data[i], test_shift[i]);
            expected = rot64(test_data[i], test_shift[i][5:0]);

            // Wait until DUT asserts valid
            wait(m_axis_tvalid);
            @(posedge clk);

            if (m_axis_tdata !== expected) begin
                $error("Mismatch! Data: %h, Shift: %0d, Expected: %h, Got: %h",
                        test_data[i], test_shift[i], expected, m_axis_tdata);
                $finish;
            end else begin
                $display("PASS: Data=%h, Shift=%0d, Result=%h", test_data[i], test_shift[i], m_axis_tdata);
            end
        end

        $display("Passed Examples.");

        // Randomized test cases
        for (int i = 0; i < 20; i++) begin
            logic [63:0] rnd_data;
            logic [5:0]  rnd_shift;
            rnd_data = $urandom();
            rnd_shift = $urandom_range(0,63);
            send_axi(rnd_data, rnd_shift);
            expected = rot64(rnd_data, rnd_shift);

            wait(m_axis_tvalid);
            @(posedge clk);

            if (m_axis_tdata !== expected) begin
                $error("Random test mismatch! Data: %h, Shift: %0d, Expected: %h, Got: %h",
                        rnd_data, rnd_shift, expected, m_axis_tdata);
                $finish;
            end else begin
                $display("PASS: Data=%h, Shift=%0d, Result=%h", rnd_data, rnd_shift, m_axis_tdata);
            end
        end

        $display("Passed Random Test Cases.");
        $display("All tests finished successfully.");
        $finish;
    end

endmodule