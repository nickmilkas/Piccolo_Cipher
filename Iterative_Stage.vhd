library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package iterative_stage_pkg is
    type rk_array is array (0 to 14) of std_logic_vector(31 downto 0);
end package iterative_stage_pkg;

package body iterative_stage_pkg is
end package body iterative_stage_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.iterative_stage_pkg.all;

entity iterative_stage is
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
end iterative_stage;

architecture iterative_stage_arch of iterative_stage is
    component F_Box is
        port(
            x      : in std_logic_vector(15 downto 0);
            f_out  : out std_logic_vector(15 downto 0)
        );
    end component;

    component RP_Box is
        port(
            x      : in std_logic_vector(63 downto 0);
            rp_out : out std_logic_vector(63 downto 0)
        );
    end component;

    component mux_2x1 is
        port(
            input_1, input_2 : in std_logic_vector(63 downto 0);
            selector          : in std_logic;
            output            : out std_logic_vector(63 downto 0)
        );
    end component;

    component reg_nbit is
		generic(WIDTH : integer := 64);
		port(
			clk     : in  std_logic;
			rst     : in  std_logic;
			data_proc: in  std_logic;
			shift   : in  std_logic;
			input_bits       : in  std_logic_vector(WIDTH-1 downto 0);
			output_bits       : out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
	
	component iterative_register is
    generic (
        WIDTH : integer := 64
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        input_data  : in std_logic_vector(WIDTH-1 downto 0);
        output_data : out std_logic_vector(WIDTH-1 downto 0)
    );
	end component;

    signal internal_1, internal_2, internal_3, internal_4 : std_logic_vector(15 downto 0);
    signal before_rp, after_rp: std_logic_vector(63 downto 0);
	signal x_temp : std_logic_vector(63 downto 0);
    signal f1, f2 : std_logic_vector(15 downto 0);
    signal reg_q : std_logic_vector(63 downto 0);
    signal iteration_count : integer range 0 to 15 := 0;
    signal max_iterations : integer;
    signal last_valid_result : std_logic_vector(63 downto 0);

begin
    MUX: mux_2x1 port map(input_1 => modified_X, input_2 => reg_q, selector => selector, output => x_temp);

    max_iterations <= 15 when reduced = '0' else 
                      8 when reduced = '1' and mode(0) = '0' else
                      14;

    U1: F_Box port map(x => x_temp(63 downto 48), f_out => f1);
    U2: F_Box port map(x => x_temp(31 downto 16), f_out => f2);

    internal_1 <= std_logic_vector(unsigned(x_temp(63 downto 48)));
    internal_2 <= std_logic_vector(unsigned(x_temp(47 downto 32)) xor unsigned(f1) xor unsigned(rk_row(to_integer(unsigned(counter)))(31 downto 16)));
    internal_3 <= std_logic_vector(unsigned(x_temp(31 downto 16)));
    internal_4 <= std_logic_vector(unsigned(x_temp(15 downto 0)) xor unsigned(f2) xor unsigned(rk_row(to_integer(unsigned(counter)))(15 downto 0)));

    before_rp <= internal_1 & internal_2 & internal_3 & internal_4;

    RP_Part: RP_Box port map(x => before_rp, rp_out => after_rp);

	U3: iterative_register port map( clk => clk, rst => reset, input_data => after_rp, output_data => reg_q);
	
	-- Concurrent assignment for iteration count
	iteration_count <= iteration_count + 1 when (internal_mode = "011" and iteration_count < max_iterations) else 0 when reset = '1' else iteration_count;

	-- Concurrent assignment for new_modified
	new_modified <= reg_q when (internal_mode = "011") else (others => 'U');

	
    -- process(clk, reset)
    -- begin
        -- if reset = '1' then
            -- new_modified <= (others => 'U');  
            -- iteration_count <= 0;
        -- elsif rising_edge(clk) then
            -- if internal_mode = "011" then
				-- new_modified <= reg_q;
                -- if iteration_count < max_iterations then
                    -- iteration_count <= iteration_count + 1;
                -- end if;
				
                -- if iteration_count = max_iterations then
                    -- new_modified <= reg_q;
                -- end if;
            -- end if;
        -- end if;
    -- end process;
	
	

end iterative_stage_arch;
