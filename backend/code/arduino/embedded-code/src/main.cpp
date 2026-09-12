#include <Arduino.h>
#include "config/config.hpp"
// #include "HCSR04.h"
#include "utilities/parser.hpp"
#include "controller/ArduinoController.hpp"
// #include "hardware-components/UltrasonicSensor.hpp"
#include "output/Result.hpp"
#include "structures/CommandDispatcher.hpp"
#include "packet/Packet.hpp"

// used to read bytes from serial
uint8_t buffer[BUFFER_SIZE];
uint16_t bufferIndex = 0;
bool packetStarted = false;

ArduinoController ac(Config::RED_LED_PIN);
CommandDispatcher dispatcher;

void setup()
{
  ac.setupHardware(); // configures all connected hardware
  dispatcher.setup(ac); // loads all endpoints into dispatch table
  Serial.begin(9600);
}

// Main program loop, packet bytes are read from serial.
void loop()
{
  while (Serial.available() > 0) // listening for server requests
  {
    uint8_t byte = Serial.read();
    if(processByte(byte, buffer, bufferIndex, packetStarted)) // returns true once whole packet is complete
    {
      ParsedPacket* parsedPacket = parsePacket(buffer);
      if (parsedPacket != nullptr)
      {
        Result result = dispatcher.dispatch(parsedPacket);
        cleanUp(parsedPacket); // frees up memory
      }
    }
  }

  ac.process(); // handles code that must run every event loop
}