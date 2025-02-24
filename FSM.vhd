library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_diagram is
    port(
        clk, reset                     : in std_logic;
        in_ctrl, write_fin, enc_dec_fin  : in std_logic;
        fsm_out                        : out std_logic_vector(2 downto 0);
        count_out                      : out std_logic_vector(3 downto 0);
        shift                          : out std_logic;
        selector                       : out std_logic
    );
end fsm_diagram;

architecture fsm_diagram_arch of fsm_diagram is
    type state_type is (A, A_wait, B, C, D, E);
    signal state          : state_type;
    signal counter        : std_logic_vector(3 downto 0) := (others => '0');
    signal shift_signal   : std_logic := '0';
    signal c_delay_counter: integer := 0;
    constant C_DELAY      : integer := 5;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state           <= A;
            counter         <= (others => '0');
            shift_signal    <= '0';
            c_delay_counter <= 0;
            selector        <= '0';  -- Initialize selector
        elsif rising_edge(clk) then
            
            shift_signal <= '0';
            selector     <= '0';  -- Default value (overridden in state D)

            case state is
                when A =>
                    if in_ctrl = '1' then
                        state <= A_wait;
                    else
                        state <= A;
                    end if;
                    
                when A_wait =>
                    state <= B;
                    
                when B =>
                    if write_fin = '1' and enc_dec_fin = '1' then
                        state <= C;
                    end if;
                    
                when C =>
                    shift_signal <= '1';
                    if c_delay_counter = C_DELAY - 1 then
                        counter         <= (others => '0');
                        state           <= D;
                        c_delay_counter <= 0;
					
						
                    else
                        c_delay_counter <= c_delay_counter + 1;
                        state           <= C;
						
                    end if;
                    
                when D =>
                    selector <= '1';
					shift_signal <= '0';
                    if unsigned(counter) < 14 then  
                        counter <= std_logic_vector(unsigned(counter) + 1);
                    else
                        state <= E;
						shift_signal <= '1';
						selector <='0';
                    end if;
                    
                when E =>
                    selector <= '1';
					shift_signal <= '0';
                    counter      <= (others => '0');
                    state       <= D; 
            end case;
        end if;
    end process;

    -- Output assignments
    process(state, counter, shift_signal)
    begin
        case state is
            when A      => fsm_out <= "000";
            when A_wait => fsm_out <= "111";
            when B      => fsm_out <= "001";
            when C      => fsm_out <= "010";
            when D      => fsm_out <= "011";
            when E      => fsm_out <= "100";
        end case;
        
        count_out <= counter;
        shift     <= shift_signal;
    end process;
    
end fsm_diagram_arch;