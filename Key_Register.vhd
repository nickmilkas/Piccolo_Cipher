library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package key_reg_pkg is
    type reg_array is array (natural range <>) of std_logic_vector(31 downto 0);
    function zeros(n : natural) return reg_array;
end package key_reg_pkg;

package body key_reg_pkg is
    function zeros(n : natural) return reg_array is
        variable result : reg_array(0 to n-1);
    begin
        for i in 0 to n-1 loop
            result(i) := (others => '0');
        end loop;
        return result;
    end function zeros;
end package body key_reg_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.key_reg_pkg.all;

entity key_reg is
    port (
        clk, rst      : in std_logic;
        write_data    : in std_logic_vector (31 downto 0);
        write_enable  : in std_logic;
        read_enable   : in std_logic;
        mode          : in std_logic_vector(1 downto 0);
        out_initial   : out reg_array(0 to 1);
        out_iter1  	  : out std_logic_vector(31 downto 0);
        out_iter2  	  : out std_logic_vector(31 downto 0);
        out_final     : out reg_array(0 to 1)
    );
end key_reg;

architecture key_reg_arch of key_reg is
    signal registers  : reg_array(0 to 32) := (others => (others => '0'));
    signal write_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal iter_counter : integer range 0 to 14 := 0;  
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                if rst = '1' then
                    registers  <= (others => (others => '0'));
                    write_addr <= (others => '0');
                else
                    registers(to_integer(unsigned(write_addr))) <= write_data;
                    if unsigned(write_addr) < 32 then
                        write_addr <= std_logic_vector(unsigned(write_addr) + 1);
                    end if;
                end if;
            end if;
        end if;
    end process;
	
	
	----------------------------
	-----  ENC/DECR PART----------
	----------------------------
    process(clk)
        variable valid_lines : integer;
    begin
        if rising_edge(clk) then
            if read_enable = '1' then
                if rst = '1' then
                    out_initial  <= (others => (others => '0'));
                    out_iter1 <= (others => '0');
                    out_iter2 <= (others => '0');
                    out_final    <= (others => (others => '0'));
                    iter_counter <= 0;
                else
                    -- Determine the number of valid lines based on mode
                    if mode(1) = '0' then
                        valid_lines := 33;
                    else
                        valid_lines := 27;
                    end if;
                    
					-- The above lines are for the outputs for initial and final stage
                    out_initial <= registers(0 to 1);
                    out_final   <= registers(valid_lines - 2 to valid_lines - 1);

                    -- The above lines are for the outputs for 2 iterative stages
                    out_iter1 <= registers(2 + iter_counter);
					
                    if (17 + iter_counter) < (valid_lines - 2) then
                        out_iter2 <= registers(17 + iter_counter);
                    else
                        out_iter2 <= (others => '0');
                    end if;

                    if iter_counter = 14 then
                        iter_counter <= 0;
                    else
                        iter_counter <= iter_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end key_reg_arch;
