library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.key_reg_pkg.all;
-- use work.initial_stage_pkg.all;
-- use work.iterative_stage_pkg.all;
-- use work.final_stage_pkg.all;

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

architecture Piccolo of main is 

    component fsm_diagram is
        port   (clk, reset : in std_logic;
                in_ctrl, write_fin, enc_dec_fin, read_enable : in std_logic;
                fsm_out: out std_logic_vector(2 downto 0);
                count_out: out std_logic_vector(4 downto 0);
                shift: out std_logic;
                selector: out std_logic);
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
            mode     : in std_logic; 
            key_in  : in std_logic_vector(79 downto 0); 
            keys_out: out std_logic_vector(31 downto 0)
        );
    end component;

    component key_scheduler128 is
        port(
            clk     : in std_logic;
            reset   : in std_logic;
            enable  : in std_logic_vector(2 downto 0);
            mode     : in std_logic; 
            key_in  : in std_logic_vector(127 downto 0); 
            keys_out: out std_logic_vector(31 downto 0)
        );
    end component;

    component key_reg is
        port(
            clk, rst      : in std_logic;
            write_data    : in std_logic_vector (31 downto 0);
            ---- OLD ENABLES
            ---write_enable  : in std_logic_vector(2 downto 0);
            ---read_enable   : in std_logic_vector(2 downto 0);
            ----
            internal_mode : in std_logic_vector(2 downto 0);
            mode          : in std_logic_vector(1 downto 0);
            ---en_enc_decr   : in std_logic;
            write_fin     : out std_logic;
            enc_dec_fin   : out std_logic;
            registers_out : out reg_array(0 to 32);
            out_initial   : out reg_array(0 to 1);
            out_iter1  	  : out reg_array(0 to 14);
            out_iter2  	  : out reg_array(0 to 14);
            out_final     : out reg_array(0 to 1)
        );
    end component;

    component initial_stage is 
        port(
            clk				: in std_logic;
            reset			: in std_logic;
            plain_text      : in  std_logic_vector(63 downto 0);
            --init_keys       : in  two_line_array;
            internal_mode   : in  std_logic_vector(2 downto 0);
            modified_X      : out std_logic_vector(63 downto 0)
        );
    end component;

    component iterative_stage is
        port(
            clk               : in std_logic;
            reset             : in std_logic;
            modified_X        : in std_logic_vector(63 downto 0);
            --rk_row            : in rk_array;
            mode              : in std_logic_vector(1 downto 0);
            internal_mode     : in std_logic_vector(2 downto 0);
            selector          : in std_logic;
            counter           : in std_logic_vector(4 downto 0);
            reduced           : in std_logic;
            new_modified      : out std_logic_vector(63 downto 0)
        );
    end component;

    component final_stage is 
        port(
            clk           : in std_logic;
            reset         : in std_logic;
            modified_X    : in std_logic_vector(63 downto 0);
            --final_keys    : in two_line_array;
            internal_mode : in std_logic_vector(2 downto 0);
            Y             : out std_logic_vector(63 downto 0)
        );
    end component;

    component reg_nbit is
        generic(WIDTH : integer := 16);
        port(
            clk        : in  std_logic;
            rst        : in  std_logic;
            data_proc  : in  std_logic;
            shift      : in  std_logic;
            input_bits : in  std_logic_vector(WIDTH-1 downto 0);
            output_bits: out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    -- type reg_array is array (0 to 32) of std_logic_vector (31 downto 0);
    -- arrays
    signal register_file: reg_array(0 to 32);
    signal array_initial: reg_array(0 to 1);
    signal array_iterative1: reg_array(0 to 14);
    signal array_iterative2: reg_array(0 to 14);
    signal array_final: reg_array(0 to 1);
    -- signals
    signal key_out80: std_logic_vector(79 downto 0);
    signal key_out128: std_logic_vector(127 downto 0);
    signal selected_write_data : std_logic_vector(31 downto 0);
    signal plain_out64: std_logic_vector(63 downto 0);
    signal plain_reg: std_logic_vector(63 downto 0);
    signal keys_reg80: std_logic_vector(31 downto 0);
    signal keys_reg128: std_logic_vector(31 downto 0);
    signal fsm_control: std_logic_vector(2 downto 0);
    signal modified_X, iter1_X, iter2_X, output_Y: std_logic_vector(63 downto 0);
    signal modified_X_reg, iter1_X_reg, iter2_X_reg: std_logic_vector(63 downto 0);
    --signal key_reg_full: std_logic;
    signal key_ready, plain_ready: std_logic;
    signal key_reg_start ,key_reg_finish: std_logic;
    signal write_fin, enc_dec_fin: std_logic;
    signal count_out: std_logic_vector(4 downto 0);
    signal shift, selector: std_logic;
    --signal c_80: integer range 0 to 27;


    
    
begin
    --- να αλλαχθουν τα port map του fsm
    fsm_ctrl: fsm_diagram port map(
        clk => clk, reset => reset, in_ctrl => key_ready, write_fin => write_fin, enc_dec_fin => enc_dec_fin, read_enable => '1',
        fsm_out => fsm_control, count_out => count_out, shift => shift, selector => selector
    );

    in_ctrl: input_controller port map(
        clk => clk, reset => reset, key_in16 => key_in16, plain_in16 => plain_in16, key_mode => mode(0),
        load_key => '1', load_plain => '1', key_out80 => key_out80, key_out128 => key_out128,
        plain_out64 => plain_out64, key_ready => key_ready, plain_ready => plain_ready
    );

    key_sched80: key_scheduler80 port map(
        clk => clk, reset => reset, enable => fsm_control, mode => mode(0), key_in => key_out80, keys_out => keys_reg80
    );

    key_sched128: key_scheduler128 port map(
        clk => clk, reset => reset, enable => fsm_control, mode => mode(0), key_in => key_out128, keys_out => keys_reg128
    );

    selected_write_data <= keys_reg80 when (mode(0) = '0') else keys_reg128; --this to be before the 2 key_schedulers
   
    -- FIX!! enc_dec_fin παντα 1 και write_fin δεν παιρνει τιμη στο test 
    file_key_register: key_reg port map(
        clk => clk, rst => reset, write_data => selected_write_data, internal_mode => fsm_control, mode => mode, 
        write_fin => write_fin, enc_dec_fin => enc_dec_fin, registers_out => register_file, out_initial => array_initial, 
        out_iter1 => array_iterative1, out_iter2 => array_iterative2, out_final => array_final
    );



    ---- FIX ALL
    -------- G function Data Proccesing Part --------
    register1: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => reset, data_proc => '1', shift => shift, input_bits => plain_out64, output_bits => plain_reg
    );
    -- init_stage: initial_stage port map(
    --     clk => clk, reset => reset, plain_text => plain_reg, init_keys => array_initial, internal_mode => fsm_control,
    --     modified_X => modified_X
    -- ); -- init_keys ειναι τυπου two_line_array, array_initial ειναι reg_array(0 to 1)

    -- register2: reg_nbit 
    --     generic map (WIDTH => 64)
    --     port map(
    --     clk => clk, rst => rst, data_proc => '1', shift => shift, input_bits => modified_X, output_bits => modified_X_reg
    -- );

    -- -- fix: must be 2 stages of iterative instead of 1
    -- iter_stage1: iterative_stage port map(
    --     clk => clk, reset => reset, modified_X => modified_X_reg, rk_row => array_iterative1, mode => mode, 
    --     internal_mode => fsm_control, selector => selector, counter => count_out, reduced => '0', new_modified => iter1_X
    -- ); -- rk_row ειναι τυπου rk_array, array_iterative1 ειναι reg_array(0 to 14)

    -- register3: reg_nbit 
    --     generic map (WIDTH => 64)
    --     port map(
    --     clk => clk, rst => rst, data_proc => '1', shift => shift, input_bits => iter1_X, output_bits => iter1_X_reg
    -- ); 
    
    -- iter_stage2: iterative_stage port map(
    --     clk => clk, reset => reset, modified_X => iter1_X_reg, rk_row => array_iterative2, mode => mode, 
    --     internal_mode => fsm_control, selector => selector, counter => count_out, reduced => '1', new_modified => iter2_X
    -- ); -- rk_row ειναι τυπου rk_array, array_iterative2 ειναι reg_array(0 to 14)
    
    -- register4: reg_nbit 
    --     generic map (WIDTH => 64)
    --     port map(
    --     clk => clk, rst => rst, data_proc => '1', shift => shift, input_bits => iter2_X, output_bits => iter2_X_reg
    -- );

    -- final_stage: final_stage port map(
    --     clk => clk, reset => reset, modified_X => iter2_X_reg, final_keys => array_final, internal_mode => fsm_control,
    --     Y => output_Y
    -- ); -- final_keys ειναι τυπου two_line_array, array_final ειναι reg_array(0 to 1)
    -------- END OF G function --------
    
    ---- END FIX


end Piccolo;


