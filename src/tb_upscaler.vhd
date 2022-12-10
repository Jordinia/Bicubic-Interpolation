library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.package_imageArray.all;
use std.textio.all;
use std.env.finish;

entity tb_upscaler is
end tb_upscaler;

architecture testbench of tb_upscaler is

  --Menyimpan header file
  type header_type  is array (0 to 53) of character;

  --Menyimpan data pixel
  type pixel_type is record
    red : std_logic_vector(7 downto 0);
    green : std_logic_vector(7 downto 0);
    blue : std_logic_vector(7 downto 0);
  end record;

  --Struktur data untuk menyimpan data pixel
  type row_type is array (integer range <>) of pixel_type;
  type row_pointer is access row_type;
  type image_type is array (integer range <>) of row_pointer;
  type image_pointer is access image_type;

  -- DUT signals
  signal x_size : natural := 1000;
  signal y_size : natural := 1000;
  signal clk    : std_logic;
  constant clk_period : time := 100 ps;
  signal reset  : std_logic;
  signal load   : std_logic; -- Input to load the next BMP
  signal done   : std_logic;  -- Done signal
  -- input and output image
  signal inputImageArray: image_process(0 to x_size-1, 0 to y_size-1);
  signal outputImageArray: image_process(0 to x_size-1, 0 to y_size-1);
  signal state  : std_logic_vector(2 downto 0);  -- Current state of
  signal upscaled  : std_logic;  -- upscaled
  signal ready  : std_logic; -- Ready to process

begin
  upscaler_instance: entity work.upscaler
  generic map (
    x_size => x_size,
    y_size => y_size
  )
  port map (
    clk => clk,
    reset => reset,
    load   => load, -- Input to load the next BMP
    done   => done,  -- Done signal
    inputImageArray => inputImageArray,
    outputImageArray => outputImageArray,
    state  => state,  -- Current state of
    upscaled => upscaled,
		ready  => ready -- Ready to process
  );

  CLOCK: process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process CLOCK;

  readbmp : process
    type char_file is file of character; --Mendefinisikan tipe data yang akan dibaca. Karena file yang dibaca adalah file teks, maka tipe data yang digunakan adalah character
    file bmp_file : char_file open read_mode is "love.bmp"; --Nama file input BMP
    file out_file : char_file open write_mode is "out.bmp";   --Nama file output BMP
    variable header : header_type; --Variabel untuk menyimpan data header
    variable image_width : integer; --Variabel untuk menyimpan lebar gambar
    variable image_height : integer; --Variabel untuk menyimpan tinggi gambar
    variable row : row_pointer; 
    variable image : image_pointer; --Bakal digunakan ketika gambar sudah dibaca
    variable padding : integer; 
    variable char : character;
  begin

    -- Read entire header
    for i in header_type'range loop
      read(bmp_file, header(i));
    end loop;

    -- Check ID field
    assert header(0) = 'B' and header(1) = 'M'
      report "First two bytes are not ""BM"". This is not a BMP file"
      severity failure;

    -- Check that the pixel array offset is as expected
    assert character'pos(header(10)) = 54 and
      character'pos(header(11)) = 0 and
      character'pos(header(12)) = 0 and
      character'pos(header(13)) = 0
      report "Pixel array offset in header is not 54 bytes"
      severity failure;

    -- Check that DIB header size is 40 bytes,
    -- meaning that the BMP is of type BITMAPINFOHEADER
    assert character'pos(header(14)) = 40 and
      character'pos(header(15)) = 0 and
      character'pos(header(16)) = 0 and
      character'pos(header(17)) = 0
      report "DIB headers size is not 40 bytes, is this a Windows BMP?"
      severity failure;

    -- Check that the number of color planes is 1
    assert character'pos(header(26)) = 1 and
      character'pos(header(27)) = 0
      report "Color planes is not 1" severity failure;

    -- Check that the number of bits per pixel is 24
    assert character'pos(header(28)) = 24 and
      character'pos(header(29)) = 0
      report "Bits per pixel is not 24" severity failure;

    -- Read image width
    image_width := character'pos(header(18)) +
      character'pos(header(19)) * 2**8 +
      character'pos(header(20)) * 2**16 +
      character'pos(header(21)) * 2**24;

    -- Read image height
    image_height := character'pos(header(22)) +
      character'pos(header(23)) * 2**8 +
      character'pos(header(24)) * 2**16 +
      character'pos(header(25)) * 2**24;

    report "image_width: " & integer'image(image_width) &
      ", image_height: " & integer'image(image_height);

    -- Number of bytes needed to pad each row to 32 bits
    padding := (4 - x_size*3 mod 4) mod 4;

    -- Reset the module:
		reset <= '1';
		wait for clk_period;
		reset <= '0';
		wait for clk_period;

		-- The module should now be ready for work:
		assert ready = '1' report "Module is not ready after reset!" severity error;	
		wait for clk_period;
    -- STATE
		assert state = "00" report "State is incorrect!" severity error;	
    wait for clk_period;

    for i in 0 to x_size loop
      for j in 0 to y_size loop
          -- Read blue pixel
        read(bmp_file, char);
        inputImageArray(i,j).blue <=
          to_integer(to_unsigned(character'pos(char), 8));

        -- Read green pixel
        read(bmp_file, char);
        inputImageArray(i,j).green <=
          to_integer(to_unsigned(character'pos(char), 8));

        -- Read red pixel
        read(bmp_file, char);
        inputImageArray(i,j).red <=
          to_integer(to_unsigned(character'pos(char), 8));

        wait for clk_period;
        
      end loop;

      -- Read and discard padding
      for i in 1 to padding loop
        read(bmp_file, char);
      end loop;

      wait for clk_period;

    end loop;

    load <= '1';
    wait for clk_period;
    load <= '0';
    wait for clk_period;

    wait until state = "10";
    -- STATE
		assert upscaled = '1' report "Image is not upscaled!" severity error;	
    wait for clk_period;

    -- Write header to output file
    for i in header_type'range loop
      write(out_file, header(i));
    end loop;

    for i in 0 to x_size loop
      for j in 0 to y_size loop

        -- Write blue pixel
        write(out_file,
          character'val(outputImageArray(i,j).blue));

        -- Write green pixel
        write(out_file,
          character'val(outputImageArray(i,j).green));

        -- Write red pixel
        write(out_file,
          character'val(outputImageArray(i,j).red));

      end loop;

      -- Write padding
      for i in 1 to padding loop
        write(out_file, character'val(0));
      end loop;

    end loop;

    file_close(bmp_file);
    file_close(out_file);

    report "testbenchulation done. Check ""out.bmp"" image.";
  end process;

end architecture;