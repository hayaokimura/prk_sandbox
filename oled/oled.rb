require 'ssd1306'

oled = SSD1306.new(unit_name: :RP2040_I2C1, freq: 100 * 1000, sda: 2, scl: 3) # sda, scl is GP2, GP3
oled.all_clear()

i = 0
oled.draw_num( 3, page: 0, col: 1)
oled.draw_num( 1, page: 0, col: 2)
oled.draw_num( 0, page: 0, col: 3)
# loop do
#   string = sprintf("%04d", i)
#   length = string.length
#   length.times do |j|
#     c = string[j]
#     oled.draw_num(c.to_i, page: 0, col: j)
#   end
#   i += 1
#   sleep 1
# end

