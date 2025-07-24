// ==========================================================
// === REVISED & FIXED ESP32 CODE (Bluetooth BLE Server)  ===
// ==========================================================

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- SERIAL COMMUNICATION WITH ARDUINO ---
// Using the same configuration as before
#define ARDUINO_SERIAL Serial2
const int ARDUINO_RX_PIN = 27; // ESP32 RX, connects to Arduino TX (Pin 3)
const int ARDUINO_TX_PIN = 25; // ESP32 TX, connects to Arduino RX (Pin 2)

// --- BLUETOOTH CONFIGURATION ---
// These UUIDs must match the ones in your Flutter app
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME         "ESP32_Servo_Control" // The name your phone will see

// --- STATE MANAGEMENT ---
BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
#define LED_PIN 2 // The built-in LED on most ESP32 boards (like WEMOS D1 Mini ESP32)

// --- CALLBACK FOR CHARACTERISTIC WRITES ---
// This function is called when the Flutter app writes data
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        // ** THE FIX IS HERE **
        // Use std::string as the correct return type from getValue()
        std::string value = pCharacteristic->getValue();

        if (value.length() > 0) {
            Serial.print("[BLE] Received Value: ");
            Serial.println(value.c_str()); // .c_str() converts std::string to a char array for printing

            // Forward the received value to the Arduino over Serial2
            Serial.println("[SERIAL] Sending to Arduino...");
            ARDUINO_SERIAL.println(value.c_str());
        }
    }
};

// --- CALLBACK FOR CONNECTION EVENTS ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("[BLE] Device Connected");
      digitalWrite(LED_PIN, HIGH); // Turn LED ON to indicate connection
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] Device Disconnected");
      // Restart advertising to allow a new connection
      pServer->getAdvertising()->start();
      Serial.println("[BLE] Restarting advertising...");
    }
};

void setup() {
    // Start serial for debugging
    Serial.begin(115200);
    Serial.println("\n[ESP32] Starting BLE Servo Controller...");

    // Setup the LED pin
    pinMode(LED_PIN, OUTPUT);

    // Start serial for Arduino communication
    ARDUINO_SERIAL.begin(9600, SERIAL_8N1, ARDUINO_RX_PIN, ARDUINO_TX_PIN);
    Serial.println("[ESP32] Serial2 for Arduino is ready.");

    // --- INITIALIZE BLE SERVER ---
    // Here we set the device name that will be broadcast
    BLEDevice::init(DEVICE_NAME); 
    
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        // Use WRITE property without response for faster throughput
                        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
                      );

    // Assign the callback for when data is written
    pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

    pService->start();

    // Start advertising so the Flutter app can find the ESP32
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] Advertising started. Ready to connect.");
}

void loop() {
    // Use the loop to blink the LED to show the connection status
    if (!deviceConnected) {
        // Fast blink when disconnected / advertising
        digitalWrite(LED_PIN, HIGH);
        delay(150);
        digitalWrite(LED_PIN, LOW);
        delay(150);
    } else {
        // LED is kept solid HIGH by the onConnect callback, so do nothing here.
        delay(1000); // Conserve a little power
    }
}