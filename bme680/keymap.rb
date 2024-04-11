require 'i2c'

class BME680
  ID = 0x77
  CHIP_ID = 0x61

  REG_CHIP_ID       = 0xD0
  REG_RESET         = 0xE0

  REG_COEFF1        = 0x8A
  REG_COEFF2        = 0xE1

  REG_FIELD0        = 0x1D

  LEN_COEFF1    = 23
  LEN_COEFF2    = 14
  LEN_FIELD = 17

  def initialize(unit_name:, freq:, sda:, scl:)
    @i2c = I2C.new(unit: unit_name, frequency: freq, sda_pin: sda, scl_pin: scl)

    # リセット処理
    @i2c.write(ID, [REG_RESET, 0xB6])
    if @i2c.read(ID, 0x01, [REG_CHIP_ID]).bytes.first != CHIP_ID then
      puts "BME680 module is not found."
    end

    # get calibration data
    calib_datas = @i2c.read(ID, LEN_COEFF1, [REG_COEFF1]) + @i2c.read(ID, LEN_COEFF2, [REG_COEFF2])
    calib_datas = calib_datas.bytes

    @par_t1 = u16(calib_datas[32], calib_datas[31])
    @par_t2 = s16(calib_datas[1], calib_datas[0])
    @par_t3 = s8(calib_datas[2])

    @par_p1 = u16(calib_datas[5], calib_datas[4])
    @par_p2 = s16(calib_datas[7], calib_datas[6])
    @par_p3 = s8(calib_datas[8])
    @par_p4 = s16(calib_datas[11], calib_datas[10])
    @par_p5 = s16(calib_datas[13], calib_datas[12])
    @par_p6 = s8(calib_datas[15])
    @par_p7 = s8(calib_datas[14])
    @par_p8 = s16(calib_datas[19], calib_datas[18])
    @par_p9 = s16(calib_datas[21], calib_datas[20])
    @par_p10 = u8(calib_datas[22])

    @par_h1 = (calib_datas[25] << 4) + (calib_datas[24] & 0x0F)
    @par_h2 = (calib_datas[23] << 4) + ((calib_datas[24] >> 4) & 0x0F)
    @par_h3 = s8(calib_datas[26])
    @par_h4 = s8(calib_datas[27])
    @par_h5 = s8(calib_datas[28])
    @par_h6 = u8(calib_datas[29])
    @par_h7 = s8(calib_datas[30])

    @par_g1 = s8(calib_datas[35])
    @par_g2 = s16(calib_datas[34], calib_datas[33])
    @par_g3 = s8(calib_datas[36])
  end

  def set_op_mode(mode)
    current_mode = 0
    loop do
      current_mode = @i2c.read(ID, 0x01, [0x74]).bytes.first
      break if (current_mode & 0b00000011) == 0
      sleep 1
    end
    if mode != 0
      @i2c.write(ID, [0x74, (current_mode & 0b11111100) | mode])
    end
  end

  def set_conf(osrs_t, osrs_p, osrs_h, filter)
    set_op_mode(0)

    ctrl_meas = @i2c.read(ID, 0x01, [0x74]).bytes.first
    @i2c.write(ID, [0x74, (ctrl_meas & 0b00000011) | ((osrs_t & 0b00000111) << 5) | ((osrs_p  & 0b00000111)<< 2)])

    ctrl_hum = @i2c.read(ID, 0x01, [0x72]).bytes.first
    @i2c.write(ID, [0x72, (ctrl_hum & 0b11111000) | (osrs_h & 0b00000111)])

    config = @i2c.read(ID, 0x01, [0x75]).bytes.first
    @i2c.write(ID, [0x75, (config & 0b11100011) | (filter & 0b00000111 << 2)])
  end

  def read_field_data
    data = @i2c.read(ID, LEN_FIELD, [REG_FIELD0]).bytes
    @adc_pres = (data[2] << 12) | (data[3] << 4) | (data[4] >> 4)
    @adc_temp = (data[5] << 12) | (data[6] << 4) | (data[7] >> 4)
    @adc_hum = (data[8] << 8) | data[9]
  end

  def calc_temp
    var1 = (@adc_temp >> 3) - (@par_t1 << 1)
    var2 = (var1 * @par_t2) >> 11
    var3 = ((((var1 >> 1) * (var1 >> 1)) >> 12) * (@par_t3 << 4)) >> 14
    @t_fine = var2 + var3
    @temp_comp = ((@t_fine * 5) + 128) >> 8
    return @temp_comp
  end

  # def calc_pres
  #   var1 = (@t_fine >> 1) - 64000
  #   var2 = ((((var1 >> 2) * (var1 >> 2)) >> 11) * @par_p6) >> 2
  #   var2 = var2 + ((var1 * @par_p5) << 1)
  #   var2 = (var2 >> 2) + (@par_p4 << 16)
  #   var1 = (((((var1 >> 2) * (var1 >> 2)) >> 13) * (@par_p3 << 5)) >> 3) + ((@par_p2 * var1) >> 1)
  #   var1 = var1 >> 18
  #   var1 = ((32768 + var1) * @par_p1) >> 15
  #   press_comp = 1048576 - @adc_pres
  #   press_comp = (press_comp - (var2 >> 12)) * 3125
  #   if press_comp >= (1 << 30) then
  #     press_comp = (press_comp.div(var1)) << 1
  #   else
  #     press_comp = (press_comp << 1).div(var1)
  #   end
  #   var1 = (@par_p9 * (((press_comp >> 3) * (press_comp >> 3)) >> 13)) >> 12
  #   var2 = ((press_comp >> 2) * @par_p8) >> 13
  #   var3 = ((press_comp >> 8) * (press_comp >> 8) * (press_comp >> 8) * @par_p10) >> 17
  #   press_comp = press_comp + ((var1 + var2 + var3 + (@par_p7 << 7)) >> 4)
  #   return press_comp
  # end

  def calc_hum
    temp_scaled = @temp_comp
    var1 = @adc_hum - (@par_h1 << 4) - (((temp_scaled * @par_h3)/100) >> 1)
    var2 = (@par_h2 * (((temp_scaled * @par_h4)/100) + (((temp_scaled * ((temp_scaled * @par_h5)/100)) >> 6)/100) + (1 << 14))) >> 10
    var3 = var1 * var2
    var4 = ((@par_h6 << 7) + ((temp_scaled * @par_h7)/100)) >> 4
    var5 = ((var3 >> 14) * (var3 >> 14)) >> 10
    var6 = (var4 * var5) >> 1
    comp_hum = (((var3 + var6) >> 10) * 1000) >> 12

    # Limit the result between 0 and 100.000.
    comp_hum = [[comp_hum, 100000].min, 0].max
    return comp_hum
  end

  def u16(msb, lsb)
    return (msb << 8) + lsb
  end
  def s16(msb, lsb)
    return (msb << 8) + lsb + ((msb < 0x80) ? 0 : ~0xFFFF)
  end
  def u8(b)
    return b
  end
  def s8(b)
    return b + ((b < 0x80) ? 0 : ~0xFF)
  end

end

bme680 = BME680.new(unit_name: :RP2040_I2C1, freq: 100 * 1000, sda: 6, scl: 7)

def adj_digit(num, digit)
  s = num.to_s
  s[-digit,0] = '.'
  return s
end

# 初期化
bme680.set_conf(5, 5, 5, 3)


loop do
  # 測定開始
  bme680.set_op_mode(1)
  bme680.set_op_mode(0)
  bme680.read_field_data
  puts("temp: #{adj_digit(bme680.calc_temp, 2)} C")
  puts("hum: #{adj_digit(bme680.calc_hum, 3)} %")
end

#
# pres = bme680.calc_pres
# s = adj_digit(pres, 2)
# puts("pres: #{s} hPa")
