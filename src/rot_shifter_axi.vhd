LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rot_shifter_axi IS
    GENERIC (
        PIPELINE_INPUT : BOOLEAN := true; -- Inputs
        PIPELINE_OUTPUT : BOOLEAN := true; -- Outputs

        -- For verification (not synthesized)
        REGISTER_RESET : STD_LOGIC := '0' -- This can be set to 0 or 1 for testing
    );
    PORT (
        -- Global signals
        clk : IN STD_LOGIC;
        rst_n : IN STD_LOGIC; -- Active low synchronous reset (Per AXI standard)

        -- AXI4-Stream slave input
        s_axis_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0); -- Input 64 bits
        s_axis_tuser : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Rotate by this many
        s_axis_tvalid : IN STD_LOGIC;
        s_axis_tready : OUT STD_LOGIC;

        -- AXI4-Stream master output
        m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0); -- Output rotation
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tready : IN STD_LOGIC
    );
END ENTITY rot_shifter_axi;

ARCHITECTURE rtl OF rot_shifter_axi IS

    -- Internal input singals
    -- SIGNAL s_axis_tdata_int : STD_LOGIC_VECTOR(63 DOWNTO 0);
    -- SIGNAL s_axis_tuser_int : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_axis_tvalid_int : STD_LOGIC;
    SIGNAL m_axis_tready_int : STD_LOGIC;

    -- Internal output signals
    -- SIGNAL s_axis_tready_int : STD_LOGIC;
    SIGNAL m_axis_tdata_int : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL m_axis_tvalid_int : STD_LOGIC;

    -- Signals for rot_shifter (These must be buffered by axi standard)
    SIGNAL data_in : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL shift_amt : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL data_out : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL valid_out : STD_LOGIC;

BEGIN

    -- Pipeline inputs
    pipeline_in : IF PIPELINE_INPUT GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                s_axis_tvalid_int <= REGISTER_RESET;
                m_axis_tready_int <= REGISTER_RESET;
            ELSIF rising_edge(clk) THEN
                s_axis_tvalid_int <= s_axis_tvalid;
                m_axis_tready_int <= m_axis_tready;
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        s_axis_tvalid_int <= s_axis_tvalid;
        m_axis_tready_int <= m_axis_tready;
    END GENERATE;

    -- Store inputs when accepted
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst_n = '0' THEN
                data_in <= (OTHERS => '0');
                shift_amt <= (OTHERS => '0');
            -- Accept new transaction
            ELSIF (s_axis_tvalid = '1') THEN
                data_in <= s_axis_tdata;
                shift_amt <= s_axis_tuser;
            END IF;
        END IF;
    END PROCESS;

    -- Map the rot shifter
    rot_inst : ENTITY work.rot_shifter
        GENERIC MAP(
            PIPELINE_INPUTS => true, -- for "logic level 1" restrictions
            PIPELINE_STAGE1 => true, -- for "logic level 1" restrictions
            PIPELINE_STAGE2 => true,
            PIPELINE_STAGE3 => true
        )
        PORT MAP(
            clk => clk,
            -- TODO change core to rst_n
            rst_n => rst_n, -- core expects active-high reset
            data_in => data_in,
            shift_amt => shift_amt,
            valid_in => s_axis_tvalid_int,
            data_out => m_axis_tdata_int,
            valid_out => m_axis_tvalid_int
        );

    -- Pipeline outputs
    pipeline_out : IF PIPELINE_OUTPUT GENERATE
        PROCESS (clk, rst_n)
        BEGIN
            IF rst_n = '0' THEN
                s_axis_tready <= REGISTER_RESET;
                m_axis_tdata <= (OTHERS => REGISTER_RESET);
                m_axis_tvalid <= REGISTER_RESET;
            ELSIF rising_edge(clk) THEN
                s_axis_tready <= m_axis_tvalid_int AND m_axis_tready_int AND s_axis_tvalid;
                m_axis_tdata <= m_axis_tdata_int;
                m_axis_tvalid <= m_axis_tvalid_int AND s_axis_tvalid;
            END IF;
        END PROCESS;
    ELSE
        GENERATE
        s_axis_tready <= m_axis_tvalid_int AND m_axis_tready_int AND s_axis_tvalid;
        m_axis_tdata <= m_axis_tdata_int;
        m_axis_tvalid <= m_axis_tvalid_int AND s_axis_tvalid;
    END GENERATE;

END ARCHITECTURE rtl;