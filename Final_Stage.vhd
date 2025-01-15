library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity final_stage is 
	generic (N: integer := 32);
    port(
       modified_X: in std_logic_vector(63 downto 0);
	   wk2,wk3: in std_logic_vector(15 downto 0);
	   rk_pl,rk_l: in std_logic_vector(15 downto 0);
	   Y:  out std_logic_vector(63 downto 0)
    );
end final_stage;


architecture final_stage_arch of final_stage is

	component Function_f
	port(   
			x: in std_logic_vector(15 downto 0);
			f_out: out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal internal_1, internal_2, internal_3, internal_4: std_logic_vector(15 downto 0);
	signal f1,f2 std_logic_vector(15 downto 0);
	begin
		U1:Function_f port map(modified_X(63 downto 48),f1);
		U2:Function_f port map(modified_X(31 downto 16),f2);
		
		internal_1 <= modified_X(63 downto 48) xor wk2;
		internal_2 <= modified_X(47 downto 32) xor f1 xor rk_pl;
		internal_3 <= modified_X(31 downto 16) xor wk3;
		internal_4 <= modified_X(15 downto 0) xor f2 xor rk_l;
		
		Y <= internal_1 & internal_2 & internal_3 & internal_4;
end final_stage_arch;





