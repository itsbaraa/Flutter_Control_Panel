#include <WiFi.h>
#include <HTTPClient.h>

// --- WIFI AND SERVER CONFIGURATION ---
const char* ssid = "ssid";
const char* password = "password";
// The ESP32 should poll the text file that is updated by the PHP script.
// Ensure your PHP scripts are in a 'servo_api' folder.
const char* serverUrl = "http://IP_ADDRESS/servo_api/angles.txt";

// --- SERIAL COMMUNICATION WITH ARDUINO ---
// Using Serial2 hardware port, re-mapped to your specified pins.
#define ARDUINO_SERIAL Serial2
const int ARDUINO_RX_PIN = 27; // Connect to Arduino's TX (Pin 3)
const int ARDUINO_TX_PIN = 25; // Connect to Arduino's RX (Pin 2)

// --- POLLING LOGIC ---
unsigned long lastCheckTime = 0;
const long checkInterval = 500; // Check every 500 ms
String lastSentData = "";       // Store the last sent data to avoid spamming

void setup() {
  // Start serial for debugging on the USB port
  Serial.begin(115200);
  delay(1000); // Give serial monitor time to connect
  Serial.println("\n[ESP32] Booting...");

  // Initialize Serial2 on specific pins for Arduino communication
  // Format: begin(baudrate, config, rxPin, txPin)
  ARDUINO_SERIAL.begin(9600, SERIAL_8N1, ARDUINO_RX_PIN, ARDUINO_TX_PIN);
  Serial.println("[ESP32] Serial2 started on Pins RX:27, TX:25");

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("[ESP32] Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[ESP32] WiFi Connected!");
  Serial.print("[ESP32] IP Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  if (millis() - lastCheckTime > checkInterval) {
    lastCheckTime = millis();
    
    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      
      Serial.print("[HTTP] Making GET request to: ");
      Serial.println(serverUrl);

      http.begin(serverUrl);
      int httpCode = http.GET();

      if (httpCode == HTTP_CODE_OK) {
        String payload = http.getString();
        payload.trim(); // Clean up whitespace
        Serial.print("[HTTP] Received payload: '");
        Serial.print(payload);
        Serial.println("'");

        // Only send to Arduino if the data is valid and has changed
        if (payload.length() > 0 && payload != lastSentData) {
          Serial.println("[SERIAL] New data detected. Sending to Arduino...");
          ARDUINO_SERIAL.println(payload);
          lastSentData = payload;
        } else if (payload == lastSentData) {
          Serial.println("[SERIAL] Data has not changed. Not sending.");
        } else {
           Serial.println("[HTTP] Received empty payload. Not sending.");
        }
        
      } else {
        Serial.printf("[HTTP] GET request failed, error: %s\n", http.errorToString(httpCode).c_str());
      }
      http.end();
    } else {
      Serial.println("[ESP32] WiFi is disconnected.");
    }
  }
}