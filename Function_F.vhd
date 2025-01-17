library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity F_Box is
    port(
        x: in std_logic_vector(15 downto 0);
        f_out: out std_logic_vector(15 downto 0)
    );
end F_Box;

architecture Behavioral of F_Box is

    component S_Box is
        port (
            x: in std_logic_vector(3 downto 0);
            s_out: out std_logic_vector(3 downto 0)
        );
    end component;

    -- 1st S-Box outputs
    signal s0, s1, s2, s3 : std_logic_vector(3 downto 0);
    -- Diffusion Matrix outputs
    signal t0, t1, t2, t3 : std_logic_vector(3 downto 0);
    -- 2nd S-Box outputs
    signal f0, f1, f2, f3 : std_logic_vector(3 downto 0);

    -- Multiplication in GF(2^4)
    function GF_Mul(a : std_logic_vector(3 downto 0); b : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable g : std_logic_vector(7 downto 0) := (others => '0'); -- Result
        variable temp_a : std_logic_vector(7 downto 0);
        variable temp_b : std_logic_vector(7 downto 0);
        constant GF_POLY : std_logic_vector(7 downto 0) := "00010011"; -- x^4 + x + 1
        variable high_bit_set : std_logic;

    begin
        temp_a := "0000" & a(3 downto 0);
        temp_b := "0000" & b(3 downto 0);

        -- Perform 4 iterations (as we are in GF(2^4))
        for i in 0 to 3 loop
            -- Check if LSB of b is 1, then XOR temp_a with g
            if temp_b(0) = '1' then
                g := g xor temp_a;
            end if;

            -- Check if the high bit of temp_a is set
            high_bit_set := temp_a(3);

            -- Shift temp_a left by 1
            temp_a := temp_a(6 downto 0) & '0';

            -- If high bit was set, XOR temp_a with the polynomial
            if high_bit_set = '1' then
                temp_a := temp_a xor GF_POLY;
            end if;

            -- Shift temp_b right by 1
            temp_b := '0' & temp_b(7 downto 1);
        end loop;

        return g(3 downto 0); 
    end function;

begin

    -- 1st S-Box 
    U0: S_Box port map(x => x(15 downto 12), s_out => s0);
    U1: S_Box port map(x => x(11 downto 8), s_out => s1);
    U2: S_Box port map(x => x(7 downto 4), s_out => s2);
    U3: S_Box port map(x => x(3 downto 0), s_out => s3);

    -- Apply diffusion matrix multiplication
    t0 <= GF_Mul("0010", s0) xor GF_Mul("0011", s1) xor GF_Mul("0001", s2) xor GF_Mul("0001", s3);
    t1 <= GF_Mul("0001", s0) xor GF_Mul("0010", s1) xor GF_Mul("0011", s2) xor GF_Mul("0001", s3);
    t2 <= GF_Mul("0001", s0) xor GF_Mul("0001", s1) xor GF_Mul("0010", s2) xor GF_Mul("0011", s3);
    t3 <= GF_Mul("0011", s0) xor GF_Mul("0001", s1) xor GF_Mul("0001", s2) xor GF_Mul("0010", s3);

    -- 2nd S-Box 
    U4: S_Box port map(x => t0, s_out => f0);
    U5: S_Box port map(x => t1, s_out => f1);
    U6: S_Box port map(x => t2, s_out => f2);
    U7: S_Box port map(x => t3, s_out => f3);

    f_out <= f0 & f1 & f2 & f3;
end Behavioral;