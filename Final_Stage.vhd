library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.initial_stage_pkg.all;

entity final_stage is 
    port(
        clk         : in std_logic;
        reset       : in std_logic;
        modified_X  : in std_logic_vector(63 downto 0);
        final_keys  : in two_line_array;
        internal_mode : in std_logic_vector(2 downto 0);
        Y           : out std_logic_vector(63 downto 0)
    );
end final_stage;

architecture final_stage_arch of final_stage is

    component F_Box
        port(
            x     : in std_logic_vector(15 downto 0);
            f_out : out std_logic_vector(15 downto 0)
        );
    end component;

    signal internal_1, internal_2, internal_3, internal_4 : std_logic_vector(15 downto 0);
    signal f1, f2                                         : std_logic_vector(15 downto 0);
    signal rk_row, wk_row                                 : std_logic_vector(31 downto 0);

begin

    rk_row <= final_keys(0);
    wk_row <= final_keys(1);

    U1: F_Box port map(x => modified_X(63 downto 48), f_out => f1);
    U2: F_Box port map(x => modified_X(31 downto 16), f_out => f2);

    internal_1 <= std_logic_vector(unsigned(modified_X(63 downto 48)) xor unsigned(wk_row(31 downto 16)));
    internal_2 <= std_logic_vector(unsigned(modified_X(47 downto 32)) xor unsigned(f1) xor unsigned(rk_row(31 downto 16)));
    internal_3 <= std_logic_vector(unsigned(modified_X(31 downto 16)) xor unsigned(wk_row(15 downto 0)));
    internal_4 <= std_logic_vector(unsigned(modified_X(15 downto 0)) xor unsigned(f2) xor unsigned(rk_row(15 downto 0)));

    process(clk, reset)
    begin
        if reset = '1' then
            Y <= (others => 'U');
        elsif rising_edge(clk) then
            if internal_mode = "011" then
                Y <= internal_1 & internal_2 & internal_3 & internal_4;
            end if;
        end if;
    end process;

end final_stage_arch;
