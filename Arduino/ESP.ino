#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- MODE MANAGEMENT ---
enum Mode {
  WIFI,
  BLUETOOTH
};
Mode currentMode; // Will be set to WIFI in setup()

// --- SERIAL COMMUNICATION ---
#define ARDUINO_SERIAL Serial2
const int ARDUINO_RX_PIN = 27;
const int ARDUINO_TX_PIN = 25;

// --- WIFI CONFIGURATION ---
const char* ssid = "ssid";
const char* password = "password";
const char* serverUrl = "http://IP_ADDRESS/servo_api/angles.txt";

// --- BLUETOOTH CONFIGURATION ---
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME         "Baraa_ESP32"
const int LED_PIN = 2;

// --- STATE MANAGEMENT ---
BLECharacteristic *pCharacteristic = nullptr;
bool deviceConnected = false;
unsigned long lastCheckTime = 0;
const long checkInterval = 500;
String lastSentData = "";
bool bleInitialized = false; // *** ADDED: Flag to track BLE initialization ***

// --- FORWARD DECLARATIONS ---
void setupWifi();
void loopWifi();
void stopWifi();
void setupBluetooth();
void loopBluetooth();
void stopBluetooth();

// --- BLUETOOTH CALLBACKS ---
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String value = pCharacteristic->getValue();
        if (value.length() > 0) {
            Serial.println("[BLE] Received: " + value + ". Sending to Arduino.");
            ARDUINO_SERIAL.println(value);
        }
    }
};

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      digitalWrite(LED_PIN, HIGH);
      Serial.println("[BLE] Device Connected");
    }
    
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] Device Disconnected.");
      // We must explicitly restart advertising to make the device discoverable again.
      pServer->getAdvertising()->start();
      Serial.println("[BLE] Advertising restarted.");
    }
};

// --- MAIN SETUP ---
void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    ARDUINO_SERIAL.begin(9600, SERIAL_8N1, ARDUINO_RX_PIN, ARDUINO_TX_PIN);
    Serial.println("\n[ESP32] Booting...");
    
    // Start in Wi-Fi mode by default
    setupWifi();
    currentMode = WIFI;
}

// --- MAIN LOOP ---
void loop() {
  // Check for serial commands to switch modes
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command.equalsIgnoreCase("bluetooth") && currentMode != BLUETOOTH) {
      Serial.println("[MODE] Switching to Bluetooth...");
      stopWifi();
      setupBluetooth();
      currentMode = BLUETOOTH;
    } else if (command.equalsIgnoreCase("wifi") && currentMode != WIFI) {
      Serial.println("[MODE] Switching to Wi-Fi...");
      stopBluetooth();
      setupWifi();
      currentMode = WIFI;
    }
  }

  // Execute the loop function for the current mode
  if (currentMode == WIFI) {
    loopWifi();
  } else {
    loopBluetooth();
  }
}

// --- WIFI FUNCTIONS ---
void setupWifi() {
  Serial.println("[WIFI] Initializing Wi-Fi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("[WIFI] Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[WIFI] Connected!");
  Serial.print("[WIFI] IP Address: ");
  Serial.println(WiFi.localIP());
}

void loopWifi() {
  if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[WIFI] Connection lost. Reconnecting...");
      // A simple delay before the main loop's auto-reconnect logic handles it
      delay(1000); 
      return;
  }

  if (millis() - lastCheckTime > checkInterval) {
    lastCheckTime = millis();
    HTTPClient http;
    http.begin(serverUrl);
    int httpCode = http.GET();

    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      payload.trim();
      if (payload.length() > 0 && payload != lastSentData) {
        Serial.println("[HTTP] New data: '" + payload + "'. Sending to Arduino.");
        ARDUINO_SERIAL.println(payload);
        lastSentData = payload;
      }
    } else if(httpCode > 0) {
        Serial.printf("[HTTP] GET failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }
}

void stopWifi() {
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
  Serial.println("[WIFI] Wi-Fi stopped.");
}

// --- BLUETOOTH FUNCTIONS ---

// *** MODIFIED: This function now handles initialization safely ***
void setupBluetooth() {
    // Only initialize the BLE stack once
    if (!bleInitialized) {
        Serial.println("[BLE] Initializing Bluetooth for the first time...");
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
        bleInitialized = true; // Set the flag so this block doesn't run again
    }
    
    // Always start advertising when entering Bluetooth mode
    BLEDevice::getAdvertising()->start();
    Serial.println("[BLE] Advertising started. Ready to connect.");
}

void loopBluetooth() {
    // Blinks the LED slowly when disconnected and waiting for a connection
    if (!deviceConnected) {
        digitalWrite(LED_PIN, HIGH);
        delay(250);
        digitalWrite(LED_PIN, LOW);
        delay(1750);
    } else {
        // Keeps the LED solid when a device is connected
        digitalWrite(LED_PIN, HIGH);
        delay(2000); // Small delay to prevent busy-looping
    }
}

// *** MODIFIED: This function now only stops advertising ***
void stopBluetooth() {
  BLEDevice::getAdvertising()->stop();
  Serial.println("[BLE] Bluetooth advertising stopped.");
}