library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iter_reg is
    port(
        clk   : in std_logic;
        reset : in std_logic;
        d     : in std_logic_vector(63 downto 0);
        q     : out std_logic_vector(63 downto 0)
    );
end iter_reg;

architecture iter_reg_arch of iter_reg is
    signal reg_data : std_logic_vector(63 downto 0) := (others => '0');
	
	begin
		process(clk, reset)
		begin
			if reset = '1' then
				reg_data <= (others => '0');
			elsif rising_edge(clk) then
				reg_data <= d;
			end if;
		end process;

		q <= reg_data;
	end iter_reg_arch;
