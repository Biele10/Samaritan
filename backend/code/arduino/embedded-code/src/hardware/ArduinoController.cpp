#include <Arduino.h>
#include "hardware-components/UltrasonicSensor.hpp"
#include "config/config.hpp"
#include "structures/HashTable.hpp"
#include "controller/ArduinoController.hpp"
#include "output/Result.hpp"

/**
 * Constructor
 * Initialises all hardware being used and creates an object for each one
 */
ArduinoController::ArduinoController(const uint8_t redLedPin, const uint8_t hcDataPin, const uint8_t hcClockPin, const uint8_t hcLatchPin, 
const uint8_t hcMaxIndex, const uint8_t noLedPin, const uint8_t yesLedPin) : _redLed(redLedPin), _onboardLed(), _hc(hcDataPin, hcClockPin,
hcLatchPin, hcMaxIndex), _yesLed(NO_PIN, yesLedPin), _noLed(NO_PIN, noLedPin)
{
  // adds all hardware to array
  this->_hardwareArray.addByPointer(&this->_redLed);
  this->_hardwareArray.addByPointer(&this->_onboardLed);
  this->_hardwareArray.addByPointer(&this->_hc);
  this->_hardwareArray.addByPointer(&this->_noLed);
  this->_hardwareArray.addByPointer(&this->_yesLed);
}

/**
 * Ran in setup function, sets up
 * all different pieces of hardware.
 */
void ArduinoController::setupHardware()
{
  pinMode(LED_BUILTIN, OUTPUT); //onboard LED
  pinMode(Config::RED_LED_PIN, OUTPUT);
  pinMode(Config::HC_DATA_PIN, OUTPUT);
  pinMode(Config::HC_CLOCK_PIN, OUTPUT);
  pinMode(Config::HC_LATCH_PIN, OUTPUT);
}

/**
 * Runs code for each component that needs running every event cycle.
 */
void ArduinoController::process()
{
  for (Hardware* hardware : this->_hardwareArray)
  {
    hardware->process();
  }
}

/**
 * Runs update loop on all connected hardware.
 * Detects state changes in object classes
 * and updates hardware accordingly.
 */
void ArduinoController::update()
{
  for (Hardware* hardware : this->_hardwareArray)
  {
    if (hardware->getDirty())
    {
      hardware->update();
      hardware->setDirty(false);
    }
  }
}

Led& ArduinoController::getRedLed() { return this->_redLed; }
OnboardLed& ArduinoController::getOnBoardLed() { return this->_onboardLed; }
HC& ArduinoController::getHC() { return this->_hc; }
Led& ArduinoController::getNoLed() { return this->_noLed; }
Led& ArduinoController::getYesLed() { return this->_yesLed; }