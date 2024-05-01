require 'ble'

class DemoCentral < BLE::Central
  def initialize
    @led = CYW43::GPIO.new(CYW43::GPIO::LED_PIN)
    @led_on = false
    super
  end

  def heartbeat_callback
    puts "===heartbeat==="
    @led.write((@led_on = !@led_on) ? 1 : 0)
    puts "===heartbeat end==="
  end

  def start(timeout_ms = nil, stop_state = :no_stop)
    if timeout_ms
      debug_puts "Starting for #{timeout_ms} ms"
    else
      debug_puts "Starting with infinite loop. Ctrl-C for stop"
    end
    total_timeout_ms = 0
    hci_power_control(HCI_POWER_ON)
    while true
      break if timeout_ms && timeout_ms <= total_timeout_ms
      if @state == stop_state
        puts "Stopped by state: #{stop_state}"
        break
      end
      sleep_ms POLLING_UNIT_MS
      total_timeout_ms += POLLING_UNIT_MS
    end
    puts "===return total timeout ms ======"
    return total_timeout_ms
  ensure
    hci_power_control(HCI_POWER_OFF)
    @ensure_proc&.call
    debug_puts "Stopped"
  end

  # def connect(adv_report)
  #   puts '==============exec connect============'
  #   puts '==============stop scan============'
  #   stop_scan # Is it necessary?
  #   puts '==============gap connect============'
  #   err_code = gap_connect(adv_report.address, adv_report.address_type_code)
  #   if err_code == 0
  #     puts '============err_code 0======='
  #     @state = :TC_W4_CONNECT
  #     puts '============exec start======='
  #     start(10, :TC_IDLE)
  #     puts '============return true======='
  #     return true
  #   else
  #     puts "Error: #{err_code}"
  #     return false
  #   end
  # end
  
  def advertising_report_callback(advertising_report)
    return unless advertising_report.name_include?("PicoRuby BLE")
    connect(advertising_report)
  end

  def packet_callback(event_packet)
    event_type = event_packet[0]&.ord
    # puts "=== event_packet ====="
    # puts "state:" + @state.to_s
    # puts 'event_type:' + event_type.to_s
    # puts 'event_packet[2]:' + event_packet[2]&.ord.to_s
    # puts "======================="

    # 96 0x60 BTSTACK_EVENT_STATE
    # 218 0xDA GAP_EVENT_ADVERTISING_REPORT
    # 62 0x3E HCI_EVENT_LE_META
    case event_type
    when BTSTACK_EVENT_STATE
      puts "=== BTSTACK_EVENT_STATE ====="
      if event_packet[2]&.ord == HCI_STATE_WORKING
        debug_puts "Central is up and running on: `#{Utils.bd_addr_to_str(gap_local_bd_addr)}`"
        start_scan
        @state = :TC_W4_SCAN_RESULT
      else
        reset_state
      end
    when GAP_EVENT_ADVERTISING_REPORT
      return unless @state == :TC_W4_SCAN_RESULT
      advertising_report = AdvertisingReport.new(event_packet)
      # if advertising_report.name_include?("PicoRuby BLE")
      #   puts "========= advertizing_report ============"
      #   puts advertising_report.format
      #   puts "====================="
      # end
      advertising_report_callback(AdvertisingReport.new(event_packet))
    when HCI_EVENT_LE_META
      return unless @state == :TC_W4_CONNECT
      case event_packet[2]&.ord
      when HCI_SUBEVENT_LE_CONNECTION_COMPLETE # 0x01
        @conn_handle = Utils.little_endian_to_int16(event_packet[4, 2])
        debug_puts "Connected. Handle: `#{sprintf("0x%04X", @conn_handle)}`"
        @state = :TC_W4_SERVICE_RESULT
        @services.clear
        err_code = discover_primary_services(@conn_handle)
        if err_code != 0
          puts "Discover primary services failed. Error code: `#{err_code}`"
          @state = :TC_IDLE
        end
      when HCI_EVENT_DISCONNECTION_COMPLETE
        @conn_handle = HCI_CON_HANDLE_INVALID
      end
    when GATT_EVENT_QUERY_COMPLETE..GATT_EVENT_LONG_CHARACTERISTIC_VALUE_QUERY_RESULT
      puts "=== GATT_EVENT_QUERY_COMPLETE..GATT_EVENT_LONG_CHARACTERISTIC_VALUE_QUERY_RESULT ====="
      # Build @services
      case @state
      when :TC_W4_SERVICE_RESULT
        case event_type
        when GATT_EVENT_SERVICE_QUERY_RESULT
          debug_puts "GATT_EVENT_SERVICE_QUERY_RESULT"
          start_handle = Utils.little_endian_to_int16(event_packet[4])
          end_handle = Utils.little_endian_to_int16(event_packet[6])
          uuid128 = Utils.reverse_128(event_packet[8, 16])
          @services << {
            start_handle: start_handle,
            end_handle: end_handle,
            uuid128: uuid128,
            uuid32: Utils.uuid128_to_uuid32(uuid128),
            characteristics: []
          }
          @characteristic_handle_ranges << { start_handle: start_handle, end_handle: end_handle }
        when GATT_EVENT_QUERY_COMPLETE
          debug_puts "GATT_EVENT_QUERY_COMPLETE for service"
          if characteristic_handle_range = @characteristic_handle_ranges.shift
            discover_characteristics_for_service(
              @conn_handle,
              characteristic_handle_range[:start_handle],
              characteristic_handle_range[:end_handle]
            )
            @state = :TC_W4_CHARACTERISTIC_RESULT
          else
            @state = :TC_IDLE
          end
        end
      when :TC_W4_CHARACTERISTIC_RESULT
        case event_type
        when GATT_EVENT_CHARACTERISTIC_QUERY_RESULT
          debug_puts "GATT_EVENT_CHARACTERISTIC_QUERY_RESULT"
          start_handle = Utils.little_endian_to_int16(event_packet[4])
          value_handle = Utils.little_endian_to_int16(event_packet[6])
          end_handle = Utils.little_endian_to_int16(event_packet[8])
          uuid128 = Utils.reverse_128(event_packet[12, 16])
          # @type var characteristic: characteristic_t
          characteristic = {
            start_handle: start_handle,
            value_handle: value_handle,
            end_handle: end_handle,
            properties: Utils.little_endian_to_int16(event_packet[10]),
            uuid128: uuid128,
            uuid32: Utils.uuid128_to_uuid32(uuid128),
            value: nil,
            descriptors: []
          }
          @services.each do |service|
            if service[:start_handle] < start_handle && end_handle <= service[:end_handle]
              service[:characteristics] << characteristic
              break []
            end
          end
          @value_handles << value_handle
          if value_handle < end_handle
            @descriptor_handle_ranges << { value_handle: value_handle, end_handle: end_handle }
          end
        when GATT_EVENT_QUERY_COMPLETE
          debug_puts "GATT_EVENT_QUERY_COMPLETE for characteristic"
          if characteristic_handle_range = @characteristic_handle_ranges.shift
            discover_characteristics_for_service(
              @conn_handle,
              characteristic_handle_range[:start_handle],
              characteristic_handle_range[:end_handle]
            )
          elsif value_handle = @value_handles.shift
            read_value_of_characteristic_using_value_handle(@conn_handle, value_handle)
            @state = :TC_W4_CHARACTERISTIC_VALUE_RESULT
          end
        end
      when :TC_W4_CHARACTERISTIC_VALUE_RESULT
        case event_type
        when GATT_EVENT_CHARACTERISTIC_VALUE_QUERY_RESULT
          debug_puts "GATT_EVENT_CHARACTERISTIC_VALUE_QUERY_RESULT"
          @services.each do |service|
            service[:characteristics].each do |chara|
              if chara[:value_handle] == Utils.little_endian_to_int16(event_packet[4])
                chara[:value] = event_packet[8, Utils.little_endian_to_int16(event_packet[6])]
                break []
              end
            end
          end
          if value_handle = @value_handles.shift
            read_value_of_characteristic_using_value_handle(@conn_handle, value_handle)
          end
        when GATT_EVENT_QUERY_COMPLETE
          debug_puts "GATT_EVENT_QUERY_COMPLETE for characteristic value"
          if handle_range = @descriptor_handle_ranges.shift
            discover_characteristic_descriptors(@conn_handle, handle_range[:value_handle], handle_range[:end_handle])
            @state = :TC_W4_ALL_CHARACTERISTIC_DESCRIPTORS_RESULT
          else
            @state = :TC_IDLE
          end
        end
      when :TC_W4_ALL_CHARACTERISTIC_DESCRIPTORS_RESULT
        case event_type
        when GATT_EVENT_ALL_CHARACTERISTIC_DESCRIPTORS_QUERY_RESULT
          debug_puts "GATT_EVENT_ALL_CHARACTERISTIC_DESCRIPTORS_QUERY_RESULT"
          handle = Utils.little_endian_to_int16(event_packet[4])
          uuid128 = Utils.reverse_128(event_packet[6, 16])
          @services.each do |service|
            service[:characteristics].each do |chara|
              if chara[:value_handle] < handle && handle <= chara[:end_handle]
                chara[:descriptors] << {
                  handle: handle,
                  uuid128: uuid128,
                  uuid32: Utils.uuid128_to_uuid32(uuid128),
                  value: nil
                }
              end
            end
          end
          @descriptor_handles << handle
        when GATT_EVENT_QUERY_COMPLETE
          debug_puts "GATT_EVENT_QUERY_COMPLETE for characteristic descriptor"
          if handle_range = @descriptor_handle_ranges.shift
            discover_characteristic_descriptors(@conn_handle, handle_range[:value_handle], handle_range[:end_handle])
          elsif descriptor_handle = @descriptor_handles.shift
            # I don't know why, but read_value_of_characteristic_descriptor() doesn't work.
            read_value_of_characteristic_using_value_handle(@conn_handle, descriptor_handle)
            @state = :TC_W4_CHARACTERISTIC_DESCRIPTOR_VALUE_RESULT
          else
            @state = :TC_IDLE
          end
        end
      when :TC_W4_CHARACTERISTIC_DESCRIPTOR_VALUE_RESULT
        case event_type
        when GATT_EVENT_CHARACTERISTIC_VALUE_QUERY_RESULT
          debug_puts "GATT_EVENT_CHARACTERISTIC_DESCRIPTOR_QUERY_RESULT"
          @services.each do |service|
            service[:characteristics].each do |chara|
              chara[:descriptors].each do |descriptor|
                if descriptor[:handle] == Utils.little_endian_to_int16(event_packet[4])
                  descriptor[:value] = event_packet[8, Utils.little_endian_to_int16(event_packet[6])]
                  break []
                end
              end
            end
          end
          if descriptor_handle = @descriptor_handles.shift
            # I don't know why, but read_value_of_characteristic_descriptor() doesn't work.
            read_value_of_characteristic_using_value_handle(@conn_handle, descriptor_handle)
          end
        when GATT_EVENT_QUERY_COMPLETE
          debug_puts "GATT_EVENT_QUERY_COMPLETE for characteristic descriptor value"
          @state = :TC_IDLE
        end
      else
        debug_puts "Not implemented: 0x#{event_type&.to_s(16)} state: #{@state}"
      end
    when GATT_EVENT_NOTIFICATION
      #when :TC_W4_ENABLE_NOTIFICATIONS_COMPLETE
      # TODO
    end
  end
end

central = DemoCentral.new
central.debug = true
puts 'start scan'
central.scan
if central.found_devices.count == 1
  puts "Found device including 'PicoRuby' in name"
  central.connect 0
  puts "Run irb and type '$central'"
else
  puts "No device found"
end