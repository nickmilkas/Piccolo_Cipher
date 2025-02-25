library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iterative_register is
    generic (
        WIDTH : integer := 64
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        input_data  : in std_logic_vector(WIDTH-1 downto 0);
        output_data : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity iterative_register;

architecture behavior of iterative_register is
    signal reg_q : std_logic_vector(WIDTH-1 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            reg_q <= (others => '0');  -- Reset state
        elsif rising_edge(clk) then
            reg_q <= input_data;  -- Always update on every clock cycle
        end if;
    end process;

    -- Immediate propagation
    output_data <= reg_q;
end architecture behavior;
