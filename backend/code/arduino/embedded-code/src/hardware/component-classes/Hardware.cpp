#include "Arduino.h"
#include "config/config.hpp"
#include "hardware-components/Hardware.hpp"

void Hardware::setState(bool state)
{
    this->_state = state;
}

Hardware::~Hardware() {}

/**
 * Flips state of component.
 */
bool Hardware::power()
{
    return this->power(!this->getState());
}

/**
 * Function that turns a component on or off.
 */
bool Hardware::power(const bool state)
{
    if (state == false)
    {
        digitalWrite(this->getArduinoPin(), HIGH);
    }

    else if (state == true)
    {
        digitalWrite(this->getArduinoPin(), LOW);
    }

    this->setState(state);
    return true;
}

bool Hardware::logicPower()
{
    return this->logicPower(!this->getState());
}

/**
 * If we want to only update hardware at end of event cycle
 * when update() functions are run, we use this to only update
 * the state logically, then when update() runs it will see change has
 * been made and update component accordingly.
 */
bool Hardware::logicPower(const bool state)
{
    this->setState(state);
    this->setDirty(true);
    return true;
}

void Hardware::setDirty(bool state)
{
    this->_isDirty = state;
}

/**
 * Function that gets the pin currently in use,
 * should really only be used in situations where only ONE pin is being used.
 */
uint8_t Hardware::getPin()
{
    uint8_t arduinoPin = this->getArduinoPin();
    uint8_t hcPin = this->getHcPin();
    if (hcPin == NO_PIN && arduinoPin != NO_PIN)
    {
        return arduinoPin;
    }

    if (arduinoPin == NO_PIN && hcPin != NO_PIN)
    {
        return hcPin;
    }

    return static_cast<uint8_t>(NO_PIN);
}

uint8_t Hardware::getArduinoPin() { return this->_arduinoPin; }
uint8_t Hardware::getHcPin() { return this->_hcPin; }
bool Hardware::getDirty() { return this->_isDirty; }
bool Hardware::getState() { return this->_state; }

void Hardware::update() {}
void Hardware::process() {}