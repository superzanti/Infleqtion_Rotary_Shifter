LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rot_shifter IS
    GENERIC (
        -- Setting the pipelining will increase f_max but decrease total execution time
        -- This should be tuned to the frequency of your entire system
        PIPELINE_INPUTS : BOOLEAN := false; -- data input
        PIPELINE_STAGE1 : BOOLEAN := false; -- Coarse shift (0/16/32/48)
        PIPELINE_STAGE2 : BOOLEAN := false; -- Mid shift (0/4/8/12)
        PIPELINE_STAGE3 : BOOLEAN := false; -- Fine shift (0/1/2/3)

        -- For verification (not synthesized)
        REGISTER_RESET : STD_LOGIC := '0' -- This can be set to 0 or 1 for testing
    );
    PORT (
        clk : IN STD_LOGIC;
        rst_n : IN STD_LOGIC;
        data_in : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        valid_in : IN STD_LOGIC;
        shift_amt : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        valid_out : OUT STD_LOGIC
    );
END ENTITY rot_shifter;

ARCHITECTURE rtl OF rot_shifter IS

    -- Internal signal for the actual 6-bit shift amount (ignoring top 2 bits)
    -- Top 2 bits just do 0, 1, 2, and 3 full rotations so they can be ignored
    SIGNAL shift_6bit : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL data_in_int : STD_LOGIC_VECTOR(63 DOWNTO 0);

    -- Intermediate pipeline signals
    SIGNAL coarse_out : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL coarse_pipe : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL mid_out : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL mid_pipe : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL fine_out : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL fine_pipe : STD_LOGIC_VECTOR(63 DOWNTO 0);

    -- Keep track of valid data
    SIGNAL valid_in_int, valid_pipe1, valid_pipe2, valid_pipe3 : STD_LOGIC;

BEGIN

    -- Pipeline initial data
    pipeline_in : IF PIPELINE_INPUTS GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                data_in_int <= (OTHERS => REGISTER_RESET);
                shift_6bit <= (OTHERS => REGISTER_RESET);
            ELSIF rising_edge(clk) THEN
                data_in_int <= data_in;
                valid_in_int <= valid_in;
                -- Extract lower 6 bits
                -- This will result in a warning of bits 6/7 being unused. ignorable.
                shift_6bit <= shift_amt(5 DOWNTO 0);
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        data_in_int <= data_in;
        valid_in_int <= valid_in;
    END GENERATE;

    -- STAGE 1: Coarse rotation (0/16/32/48 bits)
    PROCESS (shift_6bit, data_in_int)
    BEGIN
        CASE shift_6bit(5 DOWNTO 4) IS
            WHEN "00" => coarse_out <= data_in_int;
            WHEN "01" => coarse_out <= data_in_int(63 - 16 DOWNTO 0) & data_in_int(63 DOWNTO 64 - 16);
            WHEN "10" => coarse_out <= data_in_int(63 - 32 DOWNTO 0) & data_in_int(63 DOWNTO 64 - 32);
            WHEN OTHERS => coarse_out <= data_in_int(63 - 48 DOWNTO 0) & data_in_int(63 DOWNTO 64 - 48);
        END CASE;
    END PROCESS;

    -- Pipeline after stage 1
    pipeline1 : IF PIPELINE_STAGE1 GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                coarse_pipe <= (OTHERS => REGISTER_RESET);
                valid_pipe1 <= '0';
            ELSIF rising_edge(clk) THEN
                coarse_pipe <= coarse_out;
                valid_pipe1 <= valid_in_int AND valid_in;
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        coarse_pipe <= coarse_out;
        valid_pipe1 <= valid_in_int AND valid_in;
    END GENERATE;

    -- STAGE 2: Mid rotation (0/4/8/12 bits)
    PROCESS (shift_6bit, coarse_pipe)
    BEGIN
        CASE shift_6bit(3 DOWNTO 2) IS
            WHEN "00" => mid_out <= coarse_pipe;
            WHEN "01" => mid_out <= coarse_pipe(63 - 4 DOWNTO 0) & coarse_pipe(63 DOWNTO 64 - 4);
            WHEN "10" => mid_out <= coarse_pipe(63 - 8 DOWNTO 0) & coarse_pipe(63 DOWNTO 64 - 8);
            WHEN OTHERS => mid_out <= coarse_pipe(63 - 12 DOWNTO 0) & coarse_pipe(63 DOWNTO 64 - 12);
        END CASE;
    END PROCESS;

    -- Pipeline after stage 2
    pipeline2 : IF PIPELINE_STAGE2 GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                mid_pipe <= (OTHERS => REGISTER_RESET);
                valid_pipe2 <= '0';
            ELSIF rising_edge(clk) THEN
                mid_pipe <= mid_out;
                valid_pipe2 <= valid_pipe1 AND valid_in;
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        mid_pipe <= mid_out;
        valid_pipe2 <= valid_pipe1 AND valid_in;
    END GENERATE;

    -- STAGE 3: Fine rotation (0/1/2/3 bits)
    PROCESS (shift_6bit, mid_pipe)
    BEGIN
        CASE shift_6bit(1 DOWNTO 0) IS
            WHEN "00" => fine_out <= mid_pipe;
            WHEN "01" => fine_out <= mid_pipe(63 - 1 DOWNTO 0) & mid_pipe(63 DOWNTO 64 - 1);
            WHEN "10" => fine_out <= mid_pipe(63 - 2 DOWNTO 0) & mid_pipe(63 DOWNTO 64 - 2);
            WHEN OTHERS => fine_out <= mid_pipe(63 - 3 DOWNTO 0) & mid_pipe(63 DOWNTO 64 - 3);
        END CASE;
    END PROCESS;

    -- Pipeline after stage 3
    pipeline3 : IF PIPELINE_STAGE3 GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                fine_pipe <= (OTHERS => REGISTER_RESET);
                valid_pipe3 <= '0';
            ELSIF rising_edge(clk) THEN
                fine_pipe <= fine_out;
                valid_pipe3 <= valid_pipe2 AND valid_in;
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        fine_pipe <= fine_out;
        valid_pipe3 <= valid_pipe2 AND valid_in;
    END GENERATE;

    -- Output final data
    data_out <= fine_pipe;
    valid_out <= valid_pipe3;

END ARCHITECTURE rtl;