library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.key_reg_pkg.all;

entity key_reg is
    port (
        clk, rst      : in std_logic;
        write_data    : in std_logic_vector (31 downto 0);
        internal_mode : in std_logic_vector(2 downto 0);
        mode          : in std_logic_vector(1 downto 0);
        write_fin     : out std_logic;
        enc_dec_fin   : out std_logic;
        registers_out : out reg_array(0 to 32);
        out_initial   : out reg_array(0 to 1);
        out_iter1     : out reg_array(0 to 14);
        out_iter2     : out reg_array(0 to 14);
        out_final     : out reg_array(0 to 1)
    );
end key_reg;

architecture key_reg_arch of key_reg is
    signal registers       : reg_array(0 to 32) := (others => (others => '0'));
    signal write_addr      : std_logic_vector(5 downto 0) := (others => '0');
    signal write_fin_int   : std_logic := '0';
    signal enc_dec_fin_int : std_logic := '0';
begin
    write_fin     <= write_fin_int;
    enc_dec_fin   <= enc_dec_fin_int;
    registers_out <= registers;

    --------------------------------------------------------------------
    -- Process: Data Collection and Encryption/Decryption Operation
    --------------------------------------------------------------------
    process(clk, rst)
        variable temp_reg   : reg_array(0 to 32);
        variable temp       : reg_array(0 to 32);
        variable valid_lines: integer;
        variable counter    : integer;
        variable temp_rk    : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                registers       <= (others => (others => '0'));
                write_addr      <= (others => '0');
                write_fin_int   <= '0';
                enc_dec_fin_int <= '0';
            else
                if internal_mode = "001" then
                    if write_fin_int = '0' then
                        temp_reg := registers;
                        temp_reg(to_integer(unsigned(write_addr))) := write_data;
                        registers <= temp_reg;
                        
                        if mode(0) = '1' then
                            if to_integer(unsigned(write_addr)) < 32 then 
                                write_addr <= std_logic_vector(unsigned(write_addr) + 1);
                            else 
                                write_fin_int <= '1';
                            end if;
                        else 
                            if to_integer(unsigned(write_addr)) < 26 then 
                                write_addr <= std_logic_vector(unsigned(write_addr) + 1);
                            else 
                                write_fin_int <= '1';
                            end if;
                        end if;
                        
                  
                    else 
                        if mode(1) = '0' then
                            
                            enc_dec_fin_int <= '1';
                        else
                            
                            if mode(0) = '1' then
                                valid_lines := 33;
                            else
                                valid_lines := 27;
                            end if;
                            
                            temp(0) := registers(valid_lines - 1);
                            temp(valid_lines - 1) := registers(0);
                            
                            counter := 0;
                            for i in 1 to valid_lines - 2 loop
                                if (i mod 2) = 0 then
                                    temp(i) := registers(valid_lines - 2 - counter);
                                else
                                    temp_rk := registers(valid_lines - 2 - counter)(15 downto 0) &
                                               registers(valid_lines - 2 - counter)(31 downto 16);
                                    temp(i) := temp_rk;
                                end if;
                                counter := counter + 1;
                            end loop;
                            
                            registers <= temp;
                            enc_dec_fin_int <= '1';
                        end if;
                    end if;  
                end if;  
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Process: Output Generation for Iterative Stages and Final Stages
    --------------------------------------------------------------------
    process(clk, rst)
        variable valid_lines_local: integer;
        variable temp_iter2       : reg_array(0 to 14);
    begin
        if rising_edge(clk) then
            if internal_mode >= "010" then
                if rst = '1' then
                    out_initial <= (others => (others => '0'));
                    out_iter1   <= (others => (others => '0'));
                    out_iter2   <= (others => (others => '0'));
                    out_final   <= (others => (others => '0'));
                else
                    if mode(1) = '1' then
                        valid_lines_local := 33;
                    else
                        valid_lines_local := 27;
                    end if;
                    
                 
                    out_initial <= registers(0 to 1);
                    out_final   <= registers(valid_lines_local - 2 to valid_lines_local - 1);
                    
                    out_iter1 <= registers(2 to 16);
                    
                    temp_iter2 := (others => (others => '0'));
                    temp_iter2(0 to valid_lines_local - 20) := registers(17 to valid_lines_local - 3);
                    out_iter2 <= temp_iter2;
                end if;
            end if;
        end if;
    end process;

end key_reg_arch;
