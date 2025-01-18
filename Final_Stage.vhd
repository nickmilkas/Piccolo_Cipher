library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity final_stage is 
    port(
        modified_X: in std_logic_vector(63 downto 0);
        wk2, wk3: in std_logic_vector(15 downto 0);
        rk_pl, rk_l: in std_logic_vector(15 downto 0);
        Y: out std_logic_vector(63 downto 0)
    );
end final_stage;

architecture final_stage_arch of final_stage is

    component F_Box
        port(
            x: in std_logic_vector(15 downto 0);
            f_out: out std_logic_vector(15 downto 0)
        );
    end component;

    signal internal_1, internal_2, internal_3, internal_4: std_logic_vector(15 downto 0);
    signal f1, f2: std_logic_vector(15 downto 0);

begin
    U1: F_Box port map(x => modified_X(63 downto 48), f_out => f1);
    U2: F_Box port map(x => modified_X(31 downto 16), f_out => f2);

    internal_1 <= std_logic_vector(unsigned(modified_X(63 downto 48)) xor unsigned(wk2));
    internal_2 <= std_logic_vector(unsigned(modified_X(47 downto 32)) xor unsigned(f1) xor unsigned(rk_pl));
    internal_3 <= std_logic_vector(unsigned(modified_X(31 downto 16)) xor unsigned(wk3));
    internal_4 <= std_logic_vector(unsigned(modified_X(15 downto 0)) xor unsigned(f2) xor unsigned(rk_l));

    Y <= internal_1 & internal_2 & internal_3 & internal_4;

end final_stage_arch;
