library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity iterative_stage is
    port(
        clk               : in std_logic;
        reset             : in std_logic;
        modified_X        : in std_logic_vector(63 downto 0);
        rk_row            : in std_logic_vector(31 downto 0);
        activate          : in std_logic_vector(3 downto 0);
        choose            : in std_logic;
        new_modified      : out std_logic_vector(63 downto 0);
        iterative_finished: out std_logic
    );
end iterative_stage;

architecture iterative_stage_arch of iterative_stage is
    component F_Box is
        port(
            x      : in std_logic_vector(15 downto 0);
            f_out  : out std_logic_vector(15 downto 0)
        );
    end component;

    component RP_Box is
        port(
            x      : in std_logic_vector(63 downto 0);
            rp_out : out std_logic_vector(63 downto 0)
        );
    end component;

    component mux_2x1 is
        port(
            input_1, input_2 : in std_logic_vector(63 downto 0);
            selector          : in std_logic;
            output            : out std_logic_vector(63 downto 0)
        );
    end component;

    component iter_reg is
        port(
            clk   : in std_logic;
            reset : in std_logic;
            d     : in std_logic_vector(63 downto 0);
            q     : out std_logic_vector(63 downto 0)
        );
    end component;

    signal internal_1, internal_2, internal_3, internal_4 : std_logic_vector(15 downto 0);
    signal before_rp, after_rp, x_temp : std_logic_vector(63 downto 0);
    signal f1, f2 : std_logic_vector(15 downto 0);
    signal reg_q : std_logic_vector(63 downto 0);

begin
    MUX: mux_2x1 port map(input_1 => modified_X, input_2 => reg_q, selector => choose, output => x_temp);

    U1: F_Box port map(x => x_temp(63 downto 48), f_out => f1);
    U2: F_Box port map(x => x_temp(31 downto 16), f_out => f2);

    internal_1 <= std_logic_vector(unsigned(x_temp(63 downto 48)));
    internal_2 <= std_logic_vector(unsigned(x_temp(47 downto 32)) xor unsigned(f1) xor unsigned(rk_row(31 downto 16)));
    internal_3 <= std_logic_vector(unsigned(x_temp(31 downto 16)));
    internal_4 <= std_logic_vector(unsigned(x_temp(15 downto 0)) xor unsigned(f2) xor unsigned(rk_row(15 downto 0)));

    before_rp <= internal_1 & internal_2 & internal_3 & internal_4;

    RP_Part: RP_Box port map(x => before_rp, rp_out => after_rp);

    U3: iter_reg port map(clk => clk, reset => reset, d => after_rp, q => reg_q);

    new_modified <= after_rp when (unsigned(activate) >= 1) else (others => 'X');
    iterative_finished <= '1' when (unsigned(activate) >= 1) else 'X';

end iterative_stage_arch;
