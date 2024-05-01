require 'ble'
require 'adc'

class Broadcaster < BLE::Broadcaster
  #POLLING_UNIT_MS = 10

  def initialize
    super
    @debug = true
    @adc_holizontal = ADC.new(27)
    @adc_vertical = ADC.new(28)
  end

  def adv_data(send_data)
    BLE::AdvertisingData.build do |adv|
      # BLUETOOTH_DATA_TYPE_FLAGS = 0x01
      adv.add(0x01, 0xFF)
      # bluetooth_data_type_complete_local_name = 0x09
      adv.add(0x09, "PicoRuby")
      # BLUETOOTH_DATA_TYPE_MANUFACTURER_SPECIFIC_DATA = 0xFF
      adv.add(0xFF, send_data)
    end
  end

  def heartbeat_callback
    adc_vertical_result = (@adc_vertical.read * 1000).to_i.to_s(16).upcase
    adc_holizontal_result = (@adc_holizontal.read * 1000).to_i.to_s(16).upcase
    puts @adc_vertical.read
    if adc_vertical_result.length < 4
      adc_vertical_result = ("0" * (4 - adc_vertical_result.length)) + adc_vertical_result
    end
    if adc_holizontal_result.length < 4
      adc_holizontal_result = ("0" * (4 - adc_holizontal_result.length)) + adc_holizontal_result
    end

    data = adc_vertical_result + adc_holizontal_result
    puts "data: " + data
    blink_led
    advertise adv_data('adv')#(adv_data(data))
  end


  def packet_callback(event_packet)
    case event_packet[0]&.ord # event type
    when 0x60 # BTSTACK_EVENT_STATE
      return unless event_packet[2]&.ord ==  BLE::HCI_STATE_WORKING
      puts "Broadcaster is up and running on: `#{Utils.bd_addr_to_str(gap_local_bd_addr)}`"
      @state = :HCI_STATE_WORKING
    end
  end
end

broadcaster = Broadcaster.new
broadcaster.start
