library ieee;
use ieee.std_logic_1164.all;

entity reg_nbit is
    generic(WIDTH : integer := 16);
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        load_en : in  std_logic;
        input_bits       : in  std_logic_vector(WIDTH-1 downto 0);
        output_bits       : out std_logic_vector(WIDTH-1 downto 0)
    );
end reg_nbit;

architecture reg_nbit_arch of reg_nbit is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            output_bits <= (others => 'X');
        elsif rising_edge(clk) then
            if load_en = '1' then
                output_bits <= input_bits;
            end if;
        end if;
    end process;
end reg_nbit_arch;