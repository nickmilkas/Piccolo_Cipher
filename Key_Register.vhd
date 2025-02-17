library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.key_reg_pkg.all;

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


entity key_reg is
    port (
        clk, rst      : in std_logic;
        write_data    : in std_logic_vector (31 downto 0);
        ---- OLD ENABLES
        ---write_enable  : in std_logic_vector(2 downto 0);
        ---read_enable   : in std_logic_vector(2 downto 0);
        ----
        internal_mode : in std_logic_vector(2 downto 0);
        mode          : in std_logic_vector(1 downto 0);
		---en_enc_decr   : in std_logic;
        write_fin     : out std_logic;
        enc_dec_fin   : out std_logic;
        out_initial   : out reg_array(0 to 1);
        out_iter1  	  : out reg_array(0 to 14);
		out_iter2  	  : out reg_array(0 to 14);
        out_final     : out reg_array(0 to 1)
    );
end key_reg;

architecture key_reg_arch of key_reg is
    signal registers  : reg_array(0 to 32) := (others => (others => '0'));
    signal write_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal iter_counter : integer range 0 to 14 := 0;  
begin
    process(clk,rst)
    begin
        if rising_edge(clk) then
            if internal_mode = "001" then
                if rst = '1' then
                    registers  <= (others => (others => '0'));
                    write_addr <= (others => '0');
                else
                    registers(to_integer(unsigned(write_addr))) <= write_data;
                    if unsigned(write_addr) < 32 then
                        write_addr <= std_logic_vector(unsigned(write_addr) + 1);
                    else
                        write_fin <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
	--- Προσθεσε σημα εξδοδου οτι τελειωσε το write ----
	
	---------Check Decryption Part-------------------
	
	process(clk,rst)
		variable temp: reg_array(0 to 32);
		variable valid_lines : integer;
		variable counter     : integer := 0;
		variable temp_rk: std_logic_vector(31 downto 0);
	begin
		if rising_edge(clk) then
			if internal_mode = "010" and mode(0)='1' then
				if mode(1) = '1' then
					valid_lines := 33;
				else 
					valid_lines := 27;
					
				end if;
				
				temp(0) := registers(valid_lines-1);
				temp(valid_lines-1) := registers(0);
				
				for i in 1 to valid_lines - 2 loop
                    if (i mod 2) = 0 then
                        temp(i) := registers(valid_lines - 2 - counter);
                    else
						temp_rk := registers(valid_lines - 2 - counter)(15 downto 0)&registers(valid_lines - 2 - counter)(31 downto 16);
                        temp(i) := temp_rk;
                    end if;
                    counter := counter + 1;
                end loop;
				registers <= temp;
                enc_dec_fin <= '1';
            else
                enc_dec_fin <= '1';
		    end if;
        
		end if;
	end process;
		
	
	----------End Decryption Part--------------------
    
	process(clk,rst)
        variable valid_lines : integer;
		variable temp_iter2  : reg_array(0 to 13);
    begin
        if rising_edge(clk) then
            if internal_mode > "010" then
                if rst = '1' then
                    out_initial  <= (others => (others => '0'));
                    out_iter1 <= (others => (others => '0'));
                    out_iter2 <= (others => (others => '0'));
                    out_final    <= (others => (others => '0'));
                    iter_counter <= 0;
                else
                    -- Determine the number of valid lines based on mode
                    if mode(1) = '1' then
                        valid_lines := 33;
                    else
                        valid_lines := 27;
                    end if;
                    
					-- The above lines are for the outputs for initial and final stage
                    out_initial <= registers(0 to 1);
                    out_final   <= registers(valid_lines - 2 to valid_lines - 1);

                    -- The above lines are for the outputs for 2 iterative stages
                    out_iter1 <= registers(2 to 16);
					
					temp_iter2 := (others => (others => '0'));
                    temp_iter2(0 to valid_lines - 19) := registers(17 to valid_lines - 3);
                    out_iter2 <= temp_iter2;
                end if;
            end if;
        end if;
    end process;
end key_reg_arch;