library ieee;
use ieee.std_logic_1164.all
use ieee.std_logic_arith.all
use ieee.std_logic_unsigned.all

entity RP is
    port(
        x: in std_logic_vector(63 downto 0);
        rp_out: out std_logic_vector(63 downto 0)
    );
end RP;

architecture Behavioral of RP is
signal x0, x1, x2, x3, x4, x5, x6, x7: std_logic_vector(7 downto 0);
begin
    x0 <= x(63 downto 56);
    x1 <= x(55 downto 48);
    x2 <= x(47 downto 40);
    x3 <= x(39 downto 32);
    x4 <= x(31 downto 24);
    x5 <= x(23 downto 16);
    x6 <= x(15 downto 8);
    x7 <= x(7 downto 0);

    rp_out(63 downto 56) <= x2;
    rp_out(55 downto 48) <= x7;
    rp_out(47 downto 40) <= x4;
    rp_out(39 downto 32) <= x1;
    rp_out(31 downto 24) <= x6;
    rp_out(23 downto 16) <= x3;
    rp_out(15 downto 8) <= x0;
    rp_out(7 downto 0) <= x5;
end Behavioral;


