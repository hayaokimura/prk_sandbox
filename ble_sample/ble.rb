require 'ble'
class DemoPeripheral < BLE::Peripheral
  # for advertising
  APP_AD_FLAGS = 0x06
  BLUETOOTH_DATA_TYPE_FLAGS = 0x01
  BLUETOOTH_DATA_TYPE_COMPLETE_LIST_OF_16_BIT_SERVICE_CLASS_UUIDS = 0x03
  BLUETOOTH_DATA_TYPE_COMPLETE_LOCAL_NAME = 0x09
  Utils = BLE::Utils
  READ = BLE::READ
  WRITE = BLE::WRITE
  GATT_PRIMARY_SERVICE_UUID = BLE::GATT_PRIMARY_SERVICE_UUID

  def initialize
    @adv_data = BLE::AdvertisingData.build do |a|
      a.add(BLUETOOTH_DATA_TYPE_FLAGS, APP_AD_FLAGS)
      a.add(BLUETOOTH_DATA_TYPE_COMPLETE_LOCAL_NAME, "PicoRuby BLE")
      a.add(BLUETOOTH_DATA_TYPE_COMPLETE_LIST_OF_16_BIT_SERVICE_CLASS_UUIDS, "\x18\x1A")
    end
    db = BLE::GattDatabase.new do |db|
      db.add_service(GATT_PRIMARY_SERVICE_UUID, BLE::GAP_SERVICE_UUID) do |s|
        s.add_characteristic(READ, BLE::GAP_DEVICE_NAME_UUID, READ, "pico_lock")
      end
    end
  end
end

peri = DemoPeripheral.new
peri.debug = true
peri.start
