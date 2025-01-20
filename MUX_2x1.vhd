library ieee;
use ieee.std_logic_1164.all;
	
entity mux_2x1 is
	port(input_1, input_2: in std_logic_vector(63 downto 0); 
		selector: in std_logic;
		output: out std_logic_vector(63 downto 0)
		);
		
end mux_2x1;
	
architecture mux_2x1_arch of mux_2x1 is
	begin
		with selector select
			output <=  input_1 when '0',
					   input_2 when OTHERS;
end mux_2x1_arch;
