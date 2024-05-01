require 'pwm'
require 'uart'

class Motor
  def initialize(pin)
    @pwm = PWM.new(pin, frequency: 100000, duty: 0)
  end

  def update_duty(duty)
    @pwm.duty(duty)
  end
end

class Receiver
  def initialize
    @uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
    @line = ''
  end

  def get_message
    c = @uart.read(1)
    return nil unless c
    if c != "\x0a"
      @line << c
      return nil
    end
    return nil unless @line
    line = @line.chomp
    @line = '' 
    line = line[1,line.length -1]
    return nil unless line.length == 14 || line[0,4].to_i(16) == 1

    # puts 'line:' + line
    line
  end
end

class Car
  MAX_VOLTAGE = 3.3
  NORMAL_LOTATION_MIN_VOLTAGE = 1.7
  NORMAL_LOTATION_RANGE = MAX_VOLTAGE - NORMAL_LOTATION_MIN_VOLTAGE
  REVERSAL_LOTATION_MAX_VOLTAGE = 1.5
  REVERSAL_LOTATION_RANGE = REVERSAL_LOTATION_MAX_VOLTAGE

  def initialize
    @motorA1 = Motor.new(5)
    @motorA2 = Motor.new(6)
    @motorB1 = Motor.new(7)
    @motorB2 = Motor.new(8)
    @receiver = Receiver.new
  end

  def run
    loop do
      update
    end
  end

  def update
    line = @receiver.get_message
    next unless line
    vertical_adc_result = line[4,4].to_i(16).to_f / 1000
    holizontal_adc_result = line[8,4].to_i(16).to_f / 1000
    puts "vertical: " + vertical_adc_result.to_s
    puts "holizontal: " + holizontal_adc_result.to_s

    forward_vol = (vertical_adc_result - NORMAL_LOTATION_MIN_VOLTAGE) > 0 ? (vertical_adc_result - NORMAL_LOTATION_MIN_VOLTAGE) * 2 : 0
    reversal_vol = (REVERSAL_LOTATION_MAX_VOLTAGE - vertical_adc_result) > 0 ? (REVERSAL_LOTATION_MAX_VOLTAGE - vertical_adc_result) * 2 : 0
    right_vol = (REVERSAL_LOTATION_MAX_VOLTAGE - holizontal_adc_result) > 0 ? (REVERSAL_LOTATION_MAX_VOLTAGE - holizontal_adc_result) : 0
    left_vol = (holizontal_adc_result - NORMAL_LOTATION_MIN_VOLTAGE) > 0 ? (holizontal_adc_result - NORMAL_LOTATION_MIN_VOLTAGE) : 0
    puts "forward_vol:" + forward_vol.to_s
    puts "reversal_vol:" + reversal_vol.to_s
    puts "right_vol:" + right_vol.to_s
    puts "left_vol:" + left_vol.to_s

    motorA1_duty = ((forward_vol - right_vol) > 0 ? (forward_vol - right_vol) : 0)*101/3.2
    motorA2_duty = ((reversal_vol - right_vol) > 0 ? (reversal_vol - right_vol) : 0)*100/3
    motorB1_duty = ((forward_vol - left_vol) > 0 ? (forward_vol - left_vol) : 0)*100/3.2
    motorB2_duty = ((reversal_vol - left_vol) > 0 ? (reversal_vol - left_vol) : 0)*100/3
    puts "motorA1 duty:" + motorA1_duty.to_s
    puts "motorA2 duty:" + motorA2_duty.to_s
    puts "motorB1 duty:" + motorB1_duty.to_s
    puts "motorBB duty:" + motorB2_duty.to_s
  
    @motorA1.update_duty(motorA1_duty)
    @motorA2.update_duty(motorA2_duty)
    @motorB1.update_duty(motorB1_duty)
    @motorB2.update_duty(motorB2_duty) 
  end
end

car = Car.new

car.run

