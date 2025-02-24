library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package initial_stage_pkg is
    type two_line_array is array (0 to 1) of std_logic_vector(31 downto 0);
end package initial_stage_pkg;

package body initial_stage_pkg is
end package body initial_stage_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.initial_stage_pkg.all;

entity initial_stage is 
    port(
		clk				: in std_logic;
		reset			: in std_logic;
        plain_text      : in  std_logic_vector(63 downto 0);
        init_keys       : in  two_line_array;
        internal_mode   : in  std_logic_vector(2 downto 0);
        modified_X      : out std_logic_vector(63 downto 0)
    );
end initial_stage;

architecture initial_stage_arch of initial_stage is

    component F_Box
        port(
            x    : in  std_logic_vector(15 downto 0);
            f_out: out std_logic_vector(15 downto 0)
        );
    end component;
    
    component RP_Box is
        port(
            x     : in  std_logic_vector(63 downto 0);
            rp_out: out std_logic_vector(63 downto 0)
        );
    end component;

    signal internal_1, internal_2, internal_3, internal_4: std_logic_vector(15 downto 0);
    signal before_rp, after_rp: std_logic_vector(63 downto 0);
    signal f1, f2: std_logic_vector(15 downto 0);
    signal wk_row, rk_row: std_logic_vector(31 downto 0);

begin
	
    wk_row <= init_keys(0);
    rk_row <= init_keys(1);

    internal_1 <= std_logic_vector(unsigned(plain_text(63 downto 48)) xor unsigned(wk_row(31 downto 16)));
    internal_3 <= std_logic_vector(unsigned(plain_text(31 downto 16)) xor unsigned(wk_row(15 downto 0)));

    U1: F_Box port map(x => internal_1, f_out => f1);
    U2: F_Box port map(x => internal_3, f_out => f2);

    internal_2 <= std_logic_vector(unsigned(plain_text(47 downto 32)) xor unsigned(f1) xor unsigned(rk_row(31 downto 16)));
    internal_4 <= std_logic_vector(unsigned(plain_text(15 downto 0)) xor unsigned(f2) xor unsigned(rk_row(15 downto 0)));

    before_rp <= internal_1 & internal_2 & internal_3 & internal_4;
    RP_Part: RP_Box port map(x => before_rp, rp_out => after_rp);
	
	process(clk,reset)
	begin
		if reset = '1' then
			modified_X <= (others => 'U');
		elsif rising_edge(clk) then
			if internal_mode = "010" or internal_mode = "011" then
				modified_X <= after_rp;
			end if;
		end if;
	end process;
end initial_stage_arch;
