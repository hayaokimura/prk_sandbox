require 'adc'
require 'pwm'
pin = GPIO.new(25, GPIO::OUT)
pin.write(1)
adc = ADC.new(26)
pwm = PWM.new(16, frequency: 100000, duty: 100)

loop do
  puts adc.read
  pwm.duty(adc.read * 100 / 3.3)
end
