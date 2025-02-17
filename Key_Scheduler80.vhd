library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_scheduler80 is
    port (
        clk      : in std_logic;
        reset    : in std_logic;
        enable   : in std_logic_vector(2 downto 0); -- Enable with State Machine output
        key_in   : in std_logic_vector(79 downto 0); 
        keys_out : out std_logic_vector(31 downto 0) -- 32-bit έξοδος: key1 | key2
    );
end key_scheduler80;

architecture Behavioral of key_scheduler80 is
    -- Internal signals
    signal k0, k1, k2, k3, k4 : std_logic_vector(15 downto 0);  -- 16-bit subkeys
    signal round_counter      : integer range 0 to 27 := 0;    -- Μετρητής για 27 cycles (2 κύκλου whk, 25 κύκλοι για rk)
    signal con80_r            : std_logic_vector(31 downto 0); -- 32-bit constant for the current round
    --signal keys               : std_logic_vector(31 downto 0); -- Temporary output for key1 | key2

    -- Function to generate 32-bit constant values (con(2i) | con(2i+1))
    function generate_con80(i: integer) return std_logic_vector is
        variable c0 : std_logic_vector(4 downto 0) := "00000"; -- 5-bit representation of 0
        variable c_i : std_logic_vector(4 downto 0); -- 5-bit representation of i
        variable c_iplus1 : std_logic_vector(4 downto 0); -- 5-bit representation of i+1
        variable con : std_logic_vector(31 downto 0); -- Final 32-bit constant
    begin
       
        c_i := std_logic_vector(to_unsigned(i, 5));
        c_iplus1 := std_logic_vector(to_unsigned(i+1, 5));

        -- (ci+1 | c0 | ci+1 | c0 | ci+1)
        con := c_iplus1 & c0 & c_iplus1 & "00" & c_iplus1 & c0 & c_iplus1;

        -- XOR με την σταθερή τιμή 0f1e2d3c (32-bit)
        con := con xor std_logic_vector(to_unsigned(16#0f1e2d3c#, 32)); 

        return con;
    end function;

begin
    -- Process για σειριακή έξοδο key_scheduling
    process(clk, reset)
        variable keys : std_logic_vector(31 downto 0); -- Χρήση `variable` για αποφυγή καθυστερήσεων
    begin
        if reset = '1' then
            -- Reset state
            k0 <= key_in(79 downto 64);
            k1 <= key_in(63 downto 48);
            k2 <= key_in(47 downto 32);
            k3 <= key_in(31 downto 16);
            k4 <= key_in(15 downto 0);
            round_counter <= 0;
            con80_r <= (others => '0');
            keys := (others => '0');
        elsif rising_edge(clk) then
            if enable = "000" then
                -- Generate constants for the current round
                con80_r <= generate_con80(round_counter);
                -- Generate keys and output based on round counter
                case round_counter is
                    when 0 =>
                        
                        keys := k0(15 downto 8) & k1(7 downto 0) & k1(15 downto 8) & k0(7 downto 0); -- Whitening keys wk0 | wk1
                    when 26 =>
                        keys := k4(15 downto 8) & k3(7 downto 0) & k3(15 downto 8) & k4(7 downto 0); -- Final whitening keys wk2 | wk3
                    when others =>
                        if round_counter < 26 then

                            -- Compute round keys
                            case (round_counter-1) mod 5 is
                                when 0 | 2 =>
                                    keys := k2 & k3;
                                when 1 | 4 =>
                                    keys := k0 & k1;
                                when 3 =>
                                    keys := k4 & k4;
                                when others => null;
                            end case;

                            -- XOR with round constant
                            keys := keys xor con80_r;
                        end if;
                end case;

                -- Update round counter
                if round_counter < 27 then
                    round_counter <= round_counter + 1;
                else
                    round_counter <= 0; -- Reset after all rounds
                    con80_r <= (others => '0');
                end if;
            end if;
        end if;
        keys_out <= keys;
    end process;

    -- Σύνδεση εξόδου
    --keys_out <= keys;

end Behavioral;