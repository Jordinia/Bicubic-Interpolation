library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- use the package
use work.package_imageArray.all;

entity upscaler is
  generic (
      x_size : natural := 100;
      y_size : natural := 100
  );
  port(
		clk    : in std_logic;
		reset  : in std_logic;
    load   : in std_logic; -- Input to load the next BMP
    done   : in std_logic; -- Done signal

    -- input and output image
    inputImageArray: in image_process(0 to x_size-1, 0 to y_size-1);
    outputImageArray: out image_process(0 to x_size-1, 0 to y_size-1);
    -- outputImageArray: out image_process(0 to (x_size*2)-1, 0 to (y_size*2)-1);

    -- state condition
    state  : out std_logic_vector(1 downto 0);  -- Current state
		ready  : out std_logic -- Ready to process


	);
        
end entity upscaler;

-- architecture declaration, providing the implementation for the FSM
architecture rtl of upscaler is
  -- type for the FSM states
  type fsm_states is (IDLE, ACTIVE, FINISHED);

  -- signal for the current state of the FSM
  signal cur_state : fsm_states;

  signal tempImageArray: image_process(0 to x_size-1, 0 to y_size-1);
begin
  -- always block for the FSM
  upscaler: process(clk, reset)
  begin
    if (reset = '1') then
      -- reset the FSM to the IDLE state
      cur_state <= IDLE;
      -- initialInputImageArray(x_size, y_size, inputImageArray);
    elsif (rising_edge(clk)) then
      -- update the FSM state based on the current state and the inputs
      case cur_state is
        when IDLE =>
          -- initialize the shared variables
          -- initialInputImageArray(x_size, y_size, outputImageArray);
          state <= "00";
          if (load = '1') then
            tempImageArray <= inputImageArray;
            cur_state <= ACTIVE;
          end if;
        when ACTIVE =>
          state <= "01";
          outputImageArray <= tempImageArray;
          cur_state <= IDLE;
        when FINISHED =>
          state <= "10";
          if (done = '1') then
            cur_state <= IDLE;
          end if;
      end case;
    end if;
  end process;
end architecture rtl;