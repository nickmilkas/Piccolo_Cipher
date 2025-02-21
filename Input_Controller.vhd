library ieee;
use ieee.std_logic_1164.all;

entity input_controller is 
    port(
        clk: in std_logic;
        reset: in std_logic;
        -- Σειριακές εισόδοι
        key_in16: in std_logic_vector(15 downto 0);
        plain_in16: in std_logic_vector(15 downto 0);
        key_mode: in std_logic; -- 0: key80 | 1: key128
        load_key: in std_logic;
        load_plain: in std_logic;
         -- Παράλληλες εξόδοι
        key_out80: out std_logic_vector(79 downto 0);
        key_out128: out std_logic_vector(127 downto 0);
        plain_out64: out std_logic_vector(63 downto 0);
        key_ready: out std_logic;
        plain_ready: out std_logic
    );
end input_controller;

architecture Behavioral of input_controller is 
    signal key_reg       : std_logic_vector(127 downto 0) := (others => '0');
    signal plaintext_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal key_counter   : integer range 0 to 7 := 0;   -- Μετρητής για 8 chunks (128-bit)
    signal plain_counter : integer range 0 to 3 := 0;   -- Μετρητής για 4 chunks (64-bit)
    signal max_key_chunks: integer := 0;                -- 5 για 80-bit, 8 για 128-bit
    signal key_rd        : std_logic;            -- Ένδειξη ολοκλήρωσης φόρτωσης κλειδιού
    signal plain_rd     : std_logic;            -- Ένδειξη ολοκλήρωσης φόρτωσης plaintext
begin

max_key_chunks <= 4 when key_mode = '0' else 7;

-- Διαδικασία φόρτωσης κλειδιού 
process(clk, reset)
begin
    if reset = '1' then
        key_reg <= (others => '0');
        key_counter <= 0;
        key_rd <= '0';
        key_ready <= '0';
    elsif rising_edge(clk) then
        -- key_ready <= '0';  -- Προκαθορισμένη τιμή
        if (load_key = '1' and key_rd = '0') then
            -- Σειριακή φόρτωση με shift left και προσθήκη νέου chunk
            key_reg <= key_reg(111 downto 0) & key_in16; 
            if key_counter = max_key_chunks then
                key_counter <= 0;
                key_rd <= '1';
                key_ready   <= '1';  
            else
                key_counter <= key_counter + 1;
            end if;
        end if;
    end if;
end process;

-- Διαδικασία φόρτωσης plaintext (4x16-bit)
process(clk, reset)
begin
    if reset = '1' then
        plaintext_reg <= (others => '0');
        plain_counter <= 0;
        plain_rd <= '0';    
        plain_ready   <= '0';
    elsif rising_edge(clk) then
        -- plain_ready <= '0';  -- Προκαθορισμένη τιμή
        if (load_plain = '1' and plain_rd = '0') then
            -- Σειριακή φόρτωση με shift left και προσθήκη νέου chunk
            plaintext_reg <= plaintext_reg(47 downto 0) & plain_in16; 
            if plain_counter = 3 then
                plain_counter <= 0;
                plain_rd <= '1';
                plain_ready   <= '1';  -- Έτοιμο μετά το 4ο chunk
            else
                plain_counter <= plain_counter + 1;
            end if;
        end if;
    end if;
end process;

-- Συνδέσεις εξόδων 
key_out80 <= key_reg(79 downto 0) when key_mode = '0' else (others => '0');
key_out128 <= key_reg when key_mode = '1' else (others => '0');

plain_out64 <= plaintext_reg;

end Behavioral;