library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity fsm_diagram is
    port   (clk, reset : in std_logic;
           key_reg,init_fin,iter_fin,last_fin: in std_logic;
           fsm_out: out std_logic_vector(2 downto 0));
end fsm_diagram;

architecture fsm_diagram_arch of fsm_diagram is
	type state_type is (A, B, C, D, E);
	signal state: state_type;
	begin
		process(clk, reset,key_reg,init_fin,iter_fin,last_fin)
		begin
		if reset = '1' then
            state <= A;
		elsif rising_edge(clk) then
			case state is
			when A  =>  if key_reg ='1' then state <= B;
						elsif key_reg ='0' then state <=A;
						end if;
						
			when B  =>  if init_fin = '1' then state <= C;
						end if;
						
			when C  =>  if iter_fin = '1' then state <= D;
						end if;
						
			when D  =>  if last_fin = '1' then state <= E;
						end if;
						
			when E => 	state <= E;
						
					
			end case;
		end if;
		end process;
		
		process (state)
		begin
		case state is
			when A => 
				fsm_out <= "000";
			when B => 
				fsm_out <= "001";
			when C => 
				fsm_out <= "010";
			when D => 
				fsm_out <= "011";
			when E => 
				fsm_out <= "100";
		end case;
		end process;
	
end fsm_diagram_arch;