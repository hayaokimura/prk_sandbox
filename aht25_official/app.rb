require 'aht25'

i2c = I2C.new(unit: :RP2040_I2C1, frequency: 100 * 1000, sda_pin: 2, scl_pin: 3)

aht25 = AHT25.new(i2c: i2c)
aht25.reset

loop do
  puts aht25.read
end


