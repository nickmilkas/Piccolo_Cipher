library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_reg is
    port (
        clk, rst      : in  std_logic;
        write_data    : in  std_logic_vector (31 downto 0);
        read_addr0    : in  std_logic_vector (5 downto 0);
        read_addr1    : in  std_logic_vector (5 downto 0);
        write_enable  : in  std_logic;
        read_enable   : in  std_logic;
        data_1, data_2: out std_logic_vector (31 downto 0);
        is_full       : out std_logic
    );
end key_reg;

architecture key_reg_arch of key_reg is
    type reg_array is array (0 to 32) of std_logic_vector (31 downto 0);
    signal registers  : reg_array := (others => (others => '0'));
    signal write_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal full_flag  : std_logic := '0';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            registers   <= (others => (others => '0'));
            write_addr  <= (others => '0');
            full_flag   <= '0';
        elsif rising_edge(clk) then
            if write_enable = '1' then
                registers(to_integer(unsigned(write_addr))) <= write_data;
                if unsigned(write_addr) < 32 then
                    write_addr <= std_logic_vector(unsigned(write_addr) + 1);
                else
                    full_flag <= '1';
                end if;
            end if;
        end if;
    end process;

    is_full <= full_flag;

    process(clk, rst)
    begin
        if read_enable = '1' then
            data_1 <= registers(to_integer(unsigned(read_addr0)));
            data_2 <= registers(to_integer(unsigned(read_addr1)));
        else
            data_1 <= (others => '0');
            data_2 <= (others => '0');
        end if;
    end process;

end key_reg_arch;
