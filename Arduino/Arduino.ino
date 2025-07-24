#include <Servo.h>
#include <SoftwareSerial.h>

// --- SERVO CONFIGURATION ---
const int NUM_SERVOS = 4;
// Pins for the servos as specified
const int servoPins[NUM_SERVOS] = {13, 12, 11, 10}; 
Servo servos[NUM_SERVOS];

// --- SERIAL COMMUNICATION WITH ESP32 ---
// Using SoftwareSerial to receive data from the ESP32
const byte rxPin = 2; // Connects to ESP32's TX pin 25
const byte txPin = 3; // Connects to ESP32's RX pin 27
SoftwareSerial espSerial(rxPin, txPin);

void setup() {
  // Start serial for debugging on the USB port
  Serial.begin(9600);
  Serial.println("[Arduino] Booting up...");

  // Start serial for communication with the ESP32
  espSerial.begin(9600);
  Serial.println("[Arduino] SoftwareSerial started on Pins RX:2, TX:3");

  // Attach servos to their pins
  for (int i = 0; i < NUM_SERVOS; i++) {
    servos[i].attach(servoPins[i]);
    servos[i].write(90); // Set a default starting position
  }
  Serial.println("[Arduino] Servos attached and set to 90 degrees.");
  Serial.println("\n[Arduino] Ready to receive data from ESP32...");
}

void loop() {
  // Check if there's data available from the ESP32 via SoftwareSerial
  if (espSerial.available() > 0) {
    // Read the incoming string until a newline character
    String data = espSerial.readStringUntil('\n');
    data.trim();

    Serial.print("[Arduino] Received raw data string: '");
    Serial.print(data);
    Serial.println("'");
    
    // Parse the string and command the servos
    parseAndSetAngles(data);
  }
}

void parseAndSetAngles(String data) {
  int angles[NUM_SERVOS];
  int lastIndex = -1;

  for (int i = 0; i < NUM_SERVOS; i++) {
    int commaIndex = data.indexOf(',', lastIndex + 1);
    String valStr;

    if (commaIndex == -1 && i < NUM_SERVOS -1) {
        Serial.println("[Parser] Error: Malformed string. Not enough values.");
        return; // Exit if the string is incomplete
    }

    if (commaIndex == -1) { // This is the last value in the string
      valStr = data.substring(lastIndex + 1);
    } else {
      valStr = data.substring(lastIndex + 1, commaIndex);
    }

    angles[i] = valStr.toInt();
    lastIndex = commaIndex;
    
    // Safety check to keep angles within the valid 0-180 range
    if (angles[i] < 0) angles[i] = 0;
    if (angles[i] > 180) angles[i] = 180;
  }
  
  // Write the new, parsed angles to the servos
  Serial.println("--- Setting Servo Angles ---");
  for (int i = 0; i < NUM_SERVOS; i++) {
    servos[i].write(angles[i]);
    Serial.print("  Servo on Pin ");
    Serial.print(servoPins[i]);
    Serial.print(" set to: ");
    Serial.println(angles[i]);
  }
  Serial.println("----------------------------");
}