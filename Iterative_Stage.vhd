library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity iterative_stage is
    port(
       modified_X: in std_logic_vector(63 downto 0);
	   rk_first,rk_second: in std_logic_vector(15 downto 0);
	   new_modified: out std_logic_vector(63 downto 0)
    );
end iterative_stage;


architecture iterative_stage_arch of iterative_stage is
	component Function_f
	port(   
			x: in std_logic_vector(15 downto 0);
			f_out: out std_logic_vector(15 downto 0)
		);
	end component;
	
	component Function_RP
	port(   
			RP_in: in std_logic_vector(63 downto 0);
			RP_out: in std_logic_vector(63 downto 0)
		);
	end component;
	
	signal internal_1, internal_2, internal_3, internal_4: std_logic_vector(15 downto 0);
	signal before_rp, after_rp: std_logic_vector(63 downto 0);
    signal f1, f2: std_logic_vector(15 downto 0);
	
	begin
	U1: Function_f port map(x => modified_X(63 downto 48), f_out => f1);
    U2: Function_f port map(x => modified_X(31 downto 16), f_out => f2);
	
	internal_1 <= std_logic_vector(unsigned(modified_X(63 downto 48)));
    internal_2 <= std_logic_vector(unsigned(modified_X(47 downto 32)) xor unsigned(f1) xor unsigned(rk_first));
    internal_3 <= std_logic_vector(unsigned(modified_X(31 downto 16)));
    internal_4 <= std_logic_vector(unsigned(modified_X(15 downto 0)) xor unsigned(f2) xor unsigned(rk_second));
	before_rp <= internal_1 & internal_2 & internal_3 & internal_4;
	
	RP_Part: Function_RP port map(RP_in => before_rp, RP_out => after_rp);
	
	new_modified <= after_rp;
	
end iterative_stage_arch;
