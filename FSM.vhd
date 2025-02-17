library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity fsm_diagram is
    port   (clk, reset : in std_logic;
           in_ctrl, write_fin, enc_dec_fin, init_fin,iter_fin,last_fin: in std_logic;
           fsm_out: out std_logic_vector(2 downto 0));
end fsm_diagram;

architecture fsm_diagram_arch of fsm_diagram is
	type state_type is (A, B, C, D, E, F);
	signal state: state_type;
	begin
		process(clk, reset, in_ctrl, write_fin, enc_dec_fin, init_fin,iter_fin,last_fin)
		begin
		if reset = '1' then
            state <= A;
		elsif rising_edge(clk) then
			case state is
			
			when A  =>  if in_ctrl ='1' then state <= B;
						elsif in_ctrl ='0' then state <=A; --εδω ισως πρεπει να αυξανεται καποιος counter για τους κυκλους των inputs
						end if;
						
			when B  =>  if write_fin ='1' then state <= C;
						elsif write_fin ='0' then state <=B; --εδω ισως πρεπει να αυξανεται καποιος counter για τους κυκλους των κλειδιων
						end if;

			when C =>	if enc_dec_fin = '1' then state <= D;
						elsif enc_dec_fin = '0' then state <=C; 
						end if;

			------------------εδω πρεπει να προστεθουν τα αλλα states
			when   =>  if init_fin = '1' then state <= ;
						end if;
						
			when D  =>  if iter_fin = '1' then state <= E;
						end if;
						
			when E  =>  if last_fin = '1' then state <= F;
						end if;
						
			when F => 	state <= F;
						
					
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
			when F => 
				fsm_out <= "101";
		end case;
		end process;
	
end fsm_diagram_arch;