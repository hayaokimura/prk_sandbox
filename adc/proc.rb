require 'adc'
pin = GPIO.new(25, GPIO::OUT)
pin.write(1)
adc = ADC.new(26)

loop do
  sleep 1
  puts adc.read
  puts adc.read_raw
end
