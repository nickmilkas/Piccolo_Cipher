library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_scheduler128 is
    Port (
        clk         : in std_logic;
        reset       : in std_logic;
        key_in      : in std_logic_vector(127 downto 0); 
        keys_out    : out std_logic_vector(31 downto 0) -- 32-bit έξοδος: key1 | key2
    );
end key_scheduler128;

architecture Behavioral of key_scheduler128 is
    -- Internal signals
    type subkey_array is array (0 to 7) of std_logic_vector(15 downto 0);
    signal k : subkey_array; -- 16-bit subkeys
    --signal k0, k1, k2, k3, k4, k5, k6, k7 : std_logic_vector(15 downto 0);  -- 16-bit subkeys
    signal round_counter      : integer range 0 to 33 := 0;    -- Μετρητής για 33 cycles (2 κύκλου whk, 31 κύκλοι για rk)
    signal con128_r            : std_logic_vector(31 downto 0); -- 32-bit constant for the current round
    signal keys               : std_logic_vector(31 downto 0); -- Temporary output for key1 | key2

 -- Function to generate 32-bit constant values (con(2i) | con(2i+1))
    function generate_con128(i: integer) return std_logic_vector is
        variable c0 : std_logic_vector(4 downto 0) := "00000"; -- 5-bit representation of 0
        variable c_i : std_logic_vector(4 downto 0); -- 5-bit representation of i
        variable c_iplus1 : std_logic_vector(4 downto 0); -- 5-bit representation of i+1
        variable con : std_logic_vector(31 downto 0); -- Final 32-bit constant
    begin
   
        c_i := std_logic_vector(to_unsigned(i, 5));
        c_iplus1 := std_logic_vector(to_unsigned(i+1, 5));

        -- (ci+1 | c0 | ci+1 | c0 | ci+1)
        con := c_iplus1 & c0 & c_iplus1 & "00" & c_iplus1 & c0 & c_iplus1;

        -- XOR με την σταθερή τιμή 6547a98b (32-bit)
        con := con xor std_logic_vector(to_unsigned(16#6547a98b#, 32)); 

        return con;
end function;

begin
    -- Process για σειριακή έξοδο key_scheduling
    process(clk, reset)
        variable key_index : integer;
    begin
        if reset = '1' then
            -- Reset state
            k(0) <= key_in(127 downto 112);
            k(1) <= key_in(111 downto 96);
            k(2) <= key_in(95 downto 80);
            k(3) <= key_in(79 downto 64);
            k(4) <= key_in(63 downto 48);
            k(5) <= key_in(47 downto 32);
            k(6) <= key_in(31 downto 16);
            k(7) <= key_in(15 downto 0);
            round_counter <= 0;
            con128_r <= (others => '0');
            keys <= (others => '0');
        elsif rising_edge(clk) then
            -- Generate constants for the current round
            con128_r <= generate_con128(round_counter);
            -- Generate keys and output based on round counter
            case round_counter is
                when 0 =>
                    
                    keys <= k(0)(15 downto 8) & k(1)(7 downto 0) & k(1)(15 downto 8) & k(0)(7 downto 0); -- Whitening keys wk0 | wk1
                when 32 =>
                    keys <= k(4)(15 downto 8) & k(7)(7 downto 0) & k(7)(15 downto 8) & k(4)(7 downto 0); -- Final whitening keys wk2 | wk3
                when others =>
                    
                    if round_counter < 32 then
                        -- Compute round keys
                        if ((round_counter-1)+2 mod 8) = 0 then
                            k <= (k(2), k(1), k(6), k(7), k(0), k(3), k(4), k(5)); -- Συνδυασμός 8 subkeys
                        end if;
                        
                        -- XOR with round constant
                        keys(31 downto 16) <= k((round_counter-1+2) mod 8) xor con128_r(31 downto 16);
                        keys(15 downto 0)  <= k((round_counter-1+3) mod 8) xor con128_r(15 downto 0);
                    end if;
            end case;

            -- Update round counter
            if round_counter < 33 then
                round_counter <= round_counter + 1;
            else
                round_counter <= 0; -- Reset after all rounds
                con128_r <= (others => '0');
            end if;
        end if;
    end process;

    -- Σύνδεση εξόδου
    keys_out <= keys;

end Behavioral;