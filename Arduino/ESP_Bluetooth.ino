#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- SERIAL COMMUNICATION WITH ARDUINO ---
#define ARDUINO_SERIAL Serial2
const int ARDUINO_RX_PIN = 27; // ESP32 RX, connects to Arduino TX (Pin 3)
const int ARDUINO_TX_PIN = 25; // ESP32 TX, connects to Arduino RX (Pin 2)

// --- BLUETOOTH CONFIGURATION ---
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME         "Baraa_ESP32"

// --- STATE MANAGEMENT ---
BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
#define LED_PIN 2

// --- CALLBACK FOR CHARACTERISTIC WRITES ---
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String value = pCharacteristic->getValue();
        if (value.length() > 0) {
            Serial.print("[BLE] Received Value: ");
            Serial.println(value); // Print the Arduino String directly

            // Forward the received value to the Arduino over Serial2
            Serial.println("[SERIAL] Sending to Arduino...");
            ARDUINO_SERIAL.println(value);
        }
    }
};

// --- CALLBACK FOR CONNECTION EVENTS ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("[BLE] Device Connected");
      digitalWrite(LED_PIN, HIGH);
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] Device Disconnected");
      pServer->getAdvertising()->start();
      Serial.println("[BLE] Restarting advertising...");
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println("\n[ESP32] Starting BLE Servo Controller...");

    pinMode(LED_PIN, OUTPUT);

    ARDUINO_SERIAL.begin(9600, SERIAL_8N1, ARDUINO_RX_PIN, ARDUINO_TX_PIN);
    Serial.println("[ESP32] Serial2 for Arduino is ready.");

    // --- INITIALIZE BLE SERVER ---
    BLEDevice::init(DEVICE_NAME); 
    
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
                      );

    pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] Advertising started. Ready to connect.");
}

void loop() {
    if (!deviceConnected) {
        digitalWrite(LED_PIN, HIGH);
        delay(1000);
        digitalWrite(LED_PIN, LOW);
        delay(1000);
    } else {
        delay(1000);
    }
}