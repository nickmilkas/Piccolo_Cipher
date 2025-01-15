library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity S_Box is
    port (
        x: in std_logic_vector(3 downto 0);
        s_out: out std_logic_vector(3 downto 0)
    );
end entity S_Box;

architecture Behavioral of S_Box is
begin
    process(x)
    begin
        case x is
            when "0000" => s_out <= "1110"; -- 0 -> E
            when "0001" => s_out <= "0100"; -- 1 -> 4
            when "0010" => s_out <= "1011"; -- 2 -> B
            when "0011" => s_out <= "0010"; -- 3 -> 2
            when "0100" => s_out <= "0011"; -- 4 -> 3
            when "0101" => s_out <= "1000"; -- 5 -> 8
            when "0110" => s_out <= "1000"; -- 6 -> 8
            when "0111" => s_out <= "0000"; -- 7 -> 0
            when "1000" => s_out <= "1001"; -- 8 -> 9
            when "1001" => s_out <= "0001"; -- 9 -> 1
            when "1010" => s_out <= "0111"; -- A -> 7
            when "1011" => s_out <= "1111"; -- B -> F
            when "1100" => s_out <= "0110"; -- C -> 6
            when "1101" => s_out <= "1100"; -- D -> C
            when "1110" => s_out <= "0101"; -- E -> 5
            when "1111" => s_out <= "1101"; -- F -> D
            when others => s_out <= "0000"; -- Default case 
        end case;
    end process;
end Behavioral;