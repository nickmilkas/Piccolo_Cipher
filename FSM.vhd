library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_diagram is
    port   (clk, reset : in std_logic;
           in_ctrl, write_fin, enc_dec_fin, read_enable : in std_logic;
           fsm_out: out std_logic_vector(2 downto 0);
           count_out: out std_logic_vector(4 downto 0);
           shift: out std_logic;
           selector: out std_logic);
end fsm_diagram;

architecture fsm_diagram_arch of fsm_diagram is
    type state_type is (A, B, C, D);
    signal state: state_type;
    signal counter: std_logic_vector(4 downto 0) := (others => '0');
    signal shift_signal: std_logic := '0';
begin
    process(clk, reset) 
    begin
        if reset = '1' then
            state <= A;
            counter <= (others => '0');
            shift_signal <= '0';
        elsif rising_edge(clk) then
            case state is
                when A  =>  
                    if in_ctrl = '1' then
                        state <= B;
                    elsif in_ctrl = '0' then
                        state <= A;
                    end if;

                when B  =>  
                    if write_fin = '1' and enc_dec_fin = '1' then
                        state <= C;
                    elsif write_fin = '0' or enc_dec_fin = '0' then
                        state <= B;
                    end if;

                when C  =>  
                    if read_enable = '1' then
                        if counter < "01110" then
                            counter <= std_logic_vector(unsigned(counter) + 1);
                        else
                            state <= E;
                        end if;
                    end if;

                when D  =>  
                    shift_signal <= '1';
                    counter <= (others => '0');
                    state <= D;
            end case;
        end if;
    end process;

    process(state, counter, shift_signal)
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
        end case;

        count_out <= counter;
        shift <= shift_signal;

        if counter = "00000" then
            selector <= '0';
        else
            selector <= '1';
        end if;
    end process;
end fsm_diagram_arch;
