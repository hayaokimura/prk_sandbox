require 'pwm'
require 'uart'
motorA1 = PWM.new(16, frequency: 100000, duty: 0)
motorA2 = PWM.new(17, frequency: 100000, duty: 0)
motorB1 = PWM.new(18, frequency: 100000, duty: 0)
motorB2 = PWM.new(19, frequency: 100000, duty: 0)
uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
line = ''

MAX_VOLTAGE = 3.3
NORMAL_LOTATION_MIN_VOLTAGE = 1.7
NORMAL_LOTATION_RANGE = MAX_VOLTAGE - NORMAL_LOTATION_MIN_VOLTAGE
REVERSAL_LOTATION_MAX_VOLTAGE = 1.5
REVERSAL_LOTATION_RANGE = REVERSAL_LOTATION_MAX_VOLTAGE

loop do
  if c = uart.read(1)
    if c == "\x0a"
      next unless line
      line = line.chomp!
      line = line[1,line.length -1]
      unless line.length == 14 || line[0,4].to_i(16) == 1
        line = '' 
        next
      end
      puts 'line:' + line
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
      
      motorA1.duty(motorA1_duty)
      motorA2.duty(motorA2_duty)
      motorB1.duty(motorB1_duty)
      motorB2.duty(motorB2_duty)

      line = ''
    else
      line << c
    end
    #puts c
    uart.write c
  end
end
