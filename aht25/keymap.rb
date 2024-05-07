
require 'i2c'

class AHT25
  ADDRESS = 0x38

  def initialize(unit_name:, freq:, sda:, scl:)
    @i2c = I2C.new(unit: unit_name, frequency: freq, sda_pin: sda, scl_pin: scl)

    sleep 0.1
    if @i2c.read(ADDRESS, 0x01, [0x71]).bytes.first != 0x18
      puts "ATH25 module failed."
    end
  end

  def trigger
    sleep 0.01
    @i2c.write(ADDRESS, [0xAC, 0x33, 0x00])
  end

  def read_data
    sleep 0.08
    @data = @i2c.read(ADDRESS, 0x07).bytes
  end

  # Calculate temperature
  #   return: 100x degrees Celsius
  def calc_temp
    temp_raw = ((@data[3] & 0x0F) << 16) | (@data[4] << 8) | @data[5]
    return ((temp_raw * 625) >> 15) - 5000
  end

  # Calculate humidity
  #   return: 1000x %rH
  def calc_hum
    hum_raw = (@data[1] << 12) | (@data[2] << 4) | ((@data[3] & 0x0F) >> 4)
    return ((hum_raw * 625) >> 15) * 5
  end
end

def adj_digit(num, digit)
  s = num.to_s
  s[-digit,0] = '.'
  return s
end

aht25 = AHT25.new(unit_name: :RP2040_I2C1, freq: 100 * 1000, sda: 6, scl: 7)
loop do
  aht25.trigger
  aht25.read_data
  puts("temp: #{adj_digit(aht25.calc_temp, 2)} C")
  puts("hum: #{adj_digit(aht25.calc_hum, 3)} %")
end
