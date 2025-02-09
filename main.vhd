library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity main is 
    port(
        clk: in std_logic;
        reset: in std_logic;
        -- Σειριακές εισόδοι
        key_in16: in std_logic_vector(15 downto 0);
        plain_in16: in std_logic_vector(15 downto 0);
        -- 00: Encrypt, key80 | 01: Encrypt, key128 | 10: Decrypt, key80 | 11: Decrypt, key128
        mode: in std_logic_vector(1 downto 0); 
        cipher: out std_logic_vector(63 downto 0)
    );
    end main;

architecture Behavioral of main is 

    component fsm_diagram is
        port(
            clk, reset : in std_logic;
            key_reg,init_fin,iter_fin,last_fin: in std_logic;
            fsm_out: out std_logic_vector(2 downto 0)
        );
    end component;

    component input_controller is 
        port(
            clk: in std_logic;
            reset: in std_logic;
            -- Σειριακές εισόδοι
            key_in16: in std_logic_vector(15 downto 0);
            plain_in16: in std_logic_vector(15 downto 0);
            key_mode: in std_logic; -- 0: key80 | 1: key128
            load_key: in std_logic;
            load_plain: in std_logic;
                -- Παράλληλες εξόδοι
            key_out80: out std_logic_vector(79 downto 0);
            key_out128: out std_logic_vector(127 downto 0);
            plain_out64: out std_logic_vector(63 downto 0);
            key_ready: out std_logic;
            plain_ready: out std_logic
        );
    end component;

    component key_scheduler80 is
        port(
            clk     : in std_logic;
            reset   : in std_logic;
            enable  : in std_logic_vector(2 downto 0);
            key_in  : in std_logic_vector(79 downto 0); 
            keys_out: out std_logic_vector(31 downto 0)
        );
    end component;

    component key_scheduler128 is
        port(
            clk     : in std_logic;
            reset   : in std_logic;
            enable  : in std_logic_vector(2 downto 0);
            key_in  : in std_logic_vector(127 downto 0); 
            keys_out: out std_logic_vector(31 downto 0)
        );
    end component;

    component key_reg is
        port(
            clk, rst      : in  std_logic;
            write_data    : in  std_logic_vector (31 downto 0);
            read_addr0    : in  std_logic_vector (5 downto 0);
            read_addr1    : in  std_logic_vector (5 downto 0);
            write_enable  : in  std_logic;
            read_enable   : in  std_logic;
            data_1, data_2: out std_logic_vector (31 downto 0);
            is_full       : out std_logic
        )
    end component;

    component initial_stage is 
        port(
            plain_text      : in std_logic_vector(63 downto 0);
            wk_row          : in std_logic_vector(31 downto 0);
            rk_row          : in std_logic_vector(31 downto 0);
            activate        : in std_logic_vector(3 downto 0);
            modified_X      : out std_logic_vector(63 downto 0);
            initial_finished: out std_logic
        );
    end component;

    component iterative_stage is
        port(
            clk               : in std_logic;
            reset             : in std_logic;
            modified_X        : in std_logic_vector(63 downto 0);
            rk_row            : in std_logic_vector(31 downto 0);
            activate          : in std_logic_vector(3 downto 0);
            choose            : in std_logic;
            new_modified      : out std_logic_vector(63 downto 0);
            iterative_finished: out std_logic
        );
    end component;

    component final_stage is 
        port(
            modified_X    : in std_logic_vector(63 downto 0);
            wk_row        : in std_logic_vector(31 downto 0);
            rk_row        : in std_logic_vector(31 downto 0);
            activate      : in std_logic_vector(3 downto 0);
            Y             : out std_logic_vector(63 downto 0);
            final_finished: out std_logic
        );
    end component;

    component reg_nbit is
        generic(WIDTH : integer := 16);
        port(
            clk        : in  std_logic;
            rst        : in  std_logic;
            load_en    : in  std_logic;
            input_bits : in  std_logic_vector(WIDTH-1 downto 0);
            output_bits: out std_logic_vector(WIDTH-1 downto 0)
        );
    end reg_nbit;

    type reg_array is array (0 to 32) of std_logic_vector (31 downto 0);
    -- arrays
    signal array_inital: reg_array := (others => (others => '0'));
    signal array_iterative1: reg_array := (others => (others => '0'));
    signal array_iterative2: reg_array := (others => (others => '0'));
    signal array_final: reg_array := (others => (others => '0'));
    -- signals
    signal key_out80: std_logic_vector(79 downto 0);
    signal key_out128: std_logic_vector(127 downto 0);
    signal selected_write_data : std_logic_vector(31 downto 0);
    signal plain_out64: std_logic_vector(63 downto 0);
    signal plain_reg: std_logic_vector(63 downto 0);
    signal keys_reg80: std_logic_vector(31 downto 0);
    signal keys_reg128: std_logic_vector(31 downto 0);
    signal fsm_control: std_logic_vector(2 downto 0);
    signal modified_X, iter_X, final_X: std_logic_vector(63 downto 0);
    signal modified_X_reg, iter_X_reg: std_logic_vector(63 downto 0);
    --signal key_reg_full: std_logic;
    signal key_reg_start ,key_reg_finish: std_logic;


    
    
begin

    fsm_ctrl: fsm_diagram port map(
        clk => clk, reset => reset, key_reg => key_reg_finish, 
        init_fin => initial_finished, iter_fin => iterative_finished, last_fin => final_finished,
        fsm_out => fsm_control
    );

    in_ctrl: input_controller port map(
        clk => clk, reset => reset, key_in16 => key_in16, plain_in16 => plain_in16, key_mode => mode(0),
        load_key => '1', load_plain => '1', key_out80 => key_out80, key_out128 => key_out128,
        plain_out64 => plain_out64, key_ready => key_ready, plain_ready => plain_ready
    );

    plain_register: reg_nbit 
        generic map (WIDTH => 16)
        port map(
        clk => clk, rst => rst, load_en => plain_ready, input_bits => plain_out64, output_bits => plain_reg
    );


    key_sched80: key_scheduler80 port map(
        clk => clk, reset => reset, enable => fsm_control, key_in => key_out80, keys_out => keys_reg80
    );

    key_sched128: key_scheduler128 port map(
        clk => clk, reset => reset, enable => fsm_control, key_in => key_out128, keys_out => keys_reg128
    );

    
    selected_write_data <= keys_reg80 when (mode(0) = '0') else keys_reg128;
    --fix
    key_reg: key_reg port map(
        clk => clk, rst => reset, write_data => selected_write_data, read_addr0 => 000000, read_addr1 => 000001,
        write_enable => key_ready, read_enable => *___*, data_1 => wk0 | wk1, data_2 => rk0 | rk1 , is_full => 
    );




    -------- G function Data Proccesing Part --------
    init_stage: initial_stage port map(
        plain_text => plain_reg, wk_row => keys_reg80, rk_row => keys_reg80,
        activate => fsm_control(2 downto 0), modified_X => modified_X, initial_finished => initial_finished
    );

    register1: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => rst, load_en => initial_finished, input_bits => modified_X, output_bits => modified_X_reg
    );

    -- fix: must be 2 stages of iterative instead of 1
    iter_stage: iterative_stage port map(
        clk => clk, reset => reset, modified_X => iter_X, rk_row => keys_reg80,
        activate => fsm_control(2 downto 0), choose => '0', new_modified => iter_X, 
        iterative_finished => iterative_finished
    );

    register2: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => rst, load_en => iterative_finished, input_bits => iter_X, output_bits => iter_X_reg
    );

    final_stage: final_stage port map(
        modified_X => final_X, wk_row => keys_reg80, rk_row => keys_reg80,
        activate => fsm_control(2 downto 0), Y => cipher, final_finished => final_finished
    );
    -------- END OF G function --------



end Behavioral;


