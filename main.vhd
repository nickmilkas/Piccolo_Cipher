library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.key_reg_pkg.all;
use work.initial_stage_pkg.all;
use work.iterative_stage_pkg.all;

entity main is 
    port(
        clk: in std_logic;
        reset: in std_logic;
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
                in_ctrl, write_fin, enc_dec_fin: in std_logic;
                fsm_out: out std_logic_vector(2 downto 0);
                count_out: out std_logic_vector(3 downto 0);
                shift: out std_logic;
                selector: out std_logic);
    end component;

    component input_controller is 
        port(
            clk: in std_logic;
            reset: in std_logic;
            key_in16: in std_logic_vector(15 downto 0);
            plain_in16: in std_logic_vector(15 downto 0);
            key_mode: in std_logic; -- 0: key80 | 1: key128
            fsm_control: in std_logic_vector(2 downto 0);
            load_key: in std_logic;
            load_plain: in std_logic;
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
            internal_mode : in std_logic_vector(2 downto 0);
            mode          : in std_logic_vector(1 downto 0);
            write_fin     : out std_logic;
            enc_dec_fin   : out std_logic;
            registers_out : out reg_array;
            out_initial   : out two_line_array;
            out_iter1  	  : out rk_array;
            out_iter2  	  : out rk_array;
            out_final     : out two_line_array
        );
    end component;

    component initial_stage is 
        port(
            clk				: in std_logic;
            reset			: in std_logic;
            plain_text      : in  std_logic_vector(63 downto 0);
            init_keys       : in  two_line_array;
            internal_mode   : in  std_logic_vector(2 downto 0);
            modified_X      : out std_logic_vector(63 downto 0)
        );
    end component;

    component iterative_stage is
        port(
            clk               : in std_logic;
            reset             : in std_logic;
            modified_X        : in std_logic_vector(63 downto 0);
            rk_row            : in rk_array;
            mode              : in std_logic_vector(1 downto 0);
            internal_mode     : in std_logic_vector(2 downto 0);
            selector          : in std_logic;
            counter           : in std_logic_vector(3 downto 0);
            reduced           : in std_logic;
            new_modified      : out std_logic_vector(63 downto 0)
        );
    end component;

    component final_stage is 
        port(
            clk           : in std_logic;
            reset         : in std_logic;
            modified_X    : in std_logic_vector(63 downto 0);
            final_keys    : in two_line_array;
            internal_mode : in std_logic_vector(2 downto 0);
            Y             : out std_logic_vector(63 downto 0)
        );
    end component;

	component reg_nbit is
		generic(WIDTH : integer := 64);
		port(
			clk     : in  std_logic;
			rst     : in  std_logic;
			shift   : in  std_logic;
			input_bits       : in  std_logic_vector(WIDTH-1 downto 0);
			output_bits       : out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
	
    
    signal register_file: reg_array;
    signal array_initial: two_line_array;
    signal array_iterative1: rk_array;
    signal array_iterative2: rk_array;
    signal array_final: two_line_array;
    
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
    
    signal key_ready, plain_ready: std_logic;
    signal write_fin, enc_dec_fin: std_logic;
    signal count_out: std_logic_vector(3 downto 0);
    signal shift, selector: std_logic;


    
begin
    -- Starts FSM for main control and the key genetating.
	
    fsm_ctrl: fsm_diagram port map(
        clk => clk, reset => reset, in_ctrl => key_ready, write_fin => write_fin, enc_dec_fin => enc_dec_fin,
        fsm_out => fsm_control, count_out => count_out, shift => shift, selector => selector
    );

    in_ctrl: input_controller port map(
        clk => clk, reset => reset, key_in16 => key_in16, plain_in16 => plain_in16, key_mode => mode(0),
        fsm_control => fsm_control, load_key => '1', load_plain => '1', key_out80 => key_out80, key_out128 => key_out128,
        plain_out64 => plain_out64, key_ready => key_ready, plain_ready => plain_ready
    );

    key_sched80: key_scheduler80 port map(
        clk => clk, reset => reset, enable => fsm_control, mode => mode(0), key_in => key_out80, keys_out => keys_reg80
    );

    key_sched128: key_scheduler128 port map(
        clk => clk, reset => reset, enable => fsm_control, mode => mode(0), key_in => key_out128, keys_out => keys_reg128
    );

    selected_write_data <= keys_reg80 when (mode(0) = '0') else keys_reg128;
   
    file_key_register: key_reg port map(
        clk => clk, rst => reset, write_data => selected_write_data, internal_mode => fsm_control, mode => mode, 
        write_fin => write_fin, enc_dec_fin => enc_dec_fin, registers_out => register_file, out_initial => array_initial, 
        out_iter1 => array_iterative1, out_iter2 => array_iterative2, out_final => array_final
    );



    -------- G function Data Proccesing Part --------
    register1: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => reset, shift => shift, input_bits => plain_out64, output_bits => plain_reg
    );
	
    init_stage: initial_stage port map(
         clk => clk, reset => reset, plain_text => plain_reg, init_keys => array_initial, internal_mode => fsm_control,
         modified_X => modified_X
     ); 
	

    register2: reg_nbit 
         generic map (WIDTH => 64)
         port map(
         clk => clk, rst => reset, shift => shift, input_bits => modified_X, output_bits => modified_X_reg
     );

    
    iter_stage1: iterative_stage port map(
        clk => clk, reset => reset, modified_X => modified_X_reg, rk_row => array_iterative1, mode => mode, 
        internal_mode => fsm_control, selector => selector, counter => count_out, reduced => '0', new_modified => iter1_X
    ); 

    register3: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => reset, shift => shift, input_bits => iter1_X, output_bits => iter1_X_reg
    ); 
    
    iter_stage2: iterative_stage port map(
        clk => clk, reset => reset, modified_X => iter1_X_reg, rk_row => array_iterative2, mode => mode, 
        internal_mode => fsm_control, selector => selector, counter => count_out, reduced => '1', new_modified => iter2_X
    ); 
    
    register4: reg_nbit 
        generic map (WIDTH => 64)
        port map(
        clk => clk, rst => reset, shift => shift, input_bits => iter2_X, output_bits => iter2_X_reg
    );

    final_st: final_stage port map(
        clk => clk, reset => reset, modified_X => iter2_X_reg, final_keys => array_final, internal_mode => fsm_control,
        Y => output_Y
    ); 
	
	cipher <= output_Y;
    
	-------- END OF G function --------
    

end Piccolo;


