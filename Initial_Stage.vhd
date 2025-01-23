library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity initial_stage is 
    port(
        plain_text: in std_logic_vector(63 downto 0);
        wk0, wk1: in std_logic_vector(15 downto 0);
        rk0, rk1: in std_logic_vector(15 downto 0);
        modified_X: out std_logic_vector(63 downto 0)
    );
end initial_stage;

architecture initial_stage_arch of initial_stage is

    component F_Box
        port(
            x: in std_logic_vector(15 downto 0);
            f_out: out std_logic_vector(15 downto 0)
        );
    end component;
	
	component RP_Box is
        port(
            x      : in std_logic_vector(63 downto 0);
            rp_out : out std_logic_vector(63 downto 0)
        );
    end component;

    signal internal_1, internal_2, internal_3, internal_4: std_logic_vector(15 downto 0);
	signal before_rp,after_rp: std_logic_vector(63 downto 0);
    signal f1, f2: std_logic_vector(15 downto 0);

	begin
		internal_1 <= std_logic_vector(unsigned(plain_text(63 downto 48)) xor unsigned(wk0));
		internal_3 <= std_logic_vector(unsigned(plain_text(31 downto 16)) xor unsigned(wk1));
		
		U1: F_Box port map(x => internal_1, f_out => f1);
		U2: F_Box port map(x => internal_3, f_out => f2);
		
		internal_2 <= std_logic_vector(unsigned(plain_text(47 downto 32)) xor unsigned(f1) xor unsigned(rk0));
		internal_4 <= std_logic_vector(unsigned(plain_text(15 downto 0)) xor unsigned(f2) xor unsigned(rk1));

		before_rp <= internal_1 & internal_2 & internal_3 & internal_4;
		RP_Part: RP_Box port map(x => before_rp, rp_out => after_rp);
		
		modified_X <= after_rp;

end initial_stage_arch;

