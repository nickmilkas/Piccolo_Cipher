library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity F_Box is
    port(
        x: in std_logic_vector(15 downto 0);
        f_out: out std_logic_vector(15 downto 0)
    );
end F_Box;

architecture Behavioral of F_Box is

    component S_Box is
        port (
            x: in std_logic_vector(3 downto 0);
            s_out: out std_logic_vector(3 downto 0)
        );
    end component;

    signal x0, x1, x2, x3: std_logic_vector(3 downto 0);
    signal s_out, rp_out: std_logic_vector(3 downto 0);