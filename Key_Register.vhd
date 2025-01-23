library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Register_File is
    port (
        clk : in std_logic;
        rst : in std_logic;
        write_data : in std_logic_vector (15 downto 0);
        read_addr0, read_addr1 : in std_logic_vector (6 downto 0);
        data_1, data_2 : out std_logic_vector (15 downto 0);
        write_enable : in std_logic
    );
end Register_File;

architecture Behavioral of Register_File is
    type reg_array is array (0 to 65) of std_logic_vector (15 downto 0);
    signal registers: reg_array := (others => (others => '0'));
    signal write_addr: std_logic_vector(6 downto 0) := "0000000";

begin

    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => (others => '0'));
            write_addr <= "0000000";
        elsif clk'event and clk = '1' then
            if write_enable = '1' then
                registers(to_integer(unsigned(write_addr))) <= write_data;
            end if;
            write_addr <= std_logic_vector(unsigned(write_addr) + 1);
        end if;
    end process;
    
    data_1 <= registers(to_integer(unsigned(read_addr0)));
    data_2 <= registers(to_integer(unsigned(read_addr1)));

end Behavioral;
