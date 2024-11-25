require "i2c"

FONTS = "\x00\x3E\x51\x49\x45\x3E" + # 0
        "\x00\x00\x42\x7F\x40\x00" + # 1
        "\x00\x42\x61\x51\x49\x46" + # 2
        "\x00\x21\x41\x45\x4B\x31" + # 3
        "\x00\x18\x14\x12\x7F\x10" + # 4
        "\x00\x27\x45\x45\x45\x39" + # 5
        "\x00\x3C\x4A\x49\x49\x30" + # 6
        "\x00\x01\x71\x09\x05\x03" + # 7
        "\x00\x36\x49\x49\x49\x36" + # 8
        "\x00\x06\x49\x49\x29\x1E"   # 9

class SSD1306
  def initialize(unit_name:, freq:, sda:, scl:)
    @i2c = I2C.new(unit: unit_name, frequency: freq, sda_pin: sda, scl_pin: scl)

    # initialize
    @i2c.write(0x3C, [0b10000000, 0x00])
    @i2c.write(0x3C, [0b00000000, 0xAE])
    set_multiplex_ratio(0x1F)
    @i2c.write(0x3C, [0b10000000, 0x40])
    @i2c.write(0x3C, [0b10000000, 0xA1])
    @i2c.write(0x3C, [0b10000000, 0xC8])
    #@i2c.write(0x3C, [0b00000000, 0xDA, 0x12]) #configure for 128*64
    @i2c.write(0x3C, [0b00000000, 0xDA, 0b00000010]) # configure for 125*32
    @i2c.write(0x3C, [0b00000000, 0x81, 0xFF])
    @i2c.write(0x3C, [0b10000000, 0xA4])
    @i2c.write(0x3C, [0b00000000, 0xA6])
    @i2c.write(0x3C, [0b00000000, 0xD5, 0x80])
    @i2c.write(0x3C, [0b00000000, 0x20, 0x10])
    @i2c.write(0x3C, [0b00000000, 0x21, 0x00, 0x7F])
    @i2c.write(0x3C, [0b00000000, 0x22, 0x00, 0x07])
    @i2c.write(0x3C, [0b00000000, 0x8D, 0x14])
    @i2c.write(0x3C, [0b10000000, 0xAF])
  end

  def all_clear()
    i=0
    while i<8 do
      # 描画ページ指定
      @i2c.write(0x3C, [0b10000000, 0xB0 | i])

      j=0
      while j<128 do
        # column address の指定
        @i2c.write(0x3C, [0x00, 0x21, 0x00 | j, 0x00 | j+1])
        # データ指定
        @i2c.write(0x3C, [0x40, 0x00])
        j=j+1
      end
      i=i+1
    end
  end

  def all_white()
    i=0
    while i<8 do
      @i2c.write(0x3C, [0b10000000, 0xB0 | i])

      j=0
      while j<128 do
        # column address の指定
        @i2c.write(0x3C, [0x00, 0x21, 0x00 | j, 0x00 | j+1])
        # データ指定
        @i2c.write(0x3C, [0x40, 0xFF])
        j=j+1
      end
      i=i+1
    end
  end

  def draw_specific_page_line(page:, line:, data:)
    @i2c.write(0x3C, [0b10000000, 0xB0 | page])
    @i2c.write(0x3C, [0x00, 0x21, 0x00 | line, 0x00 | line+1])
    @i2c.write(0x3C, [0x40, data])
  end

  def draw_num(num, page:, col:)
    font = FONTS[num * 6, 6]
    font.bytes.each_with_index do |data, i|
      draw_specific_page_line(page: page, line: col * 6 + i, data: data)
    end
  end

  # 0x3F 63
  # 0x1F 31
  def set_multiplex_ratio(ratio)
    @i2c.write(0x3C, [0b00000000, 0xA8, ratio])
  end
end
