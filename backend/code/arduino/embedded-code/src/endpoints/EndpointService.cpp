#include "endpoints/EndpointService.hpp"
#include "Arduino.h"
#include "config/config.hpp"
#include "hardware-components/Led.hpp"
#include "hardware-components/OnboardLed.hpp"
#include "hardware-components/HC.hpp"

// this is where all endpoints are stored which run necessary logic
// can be moved/expanded in the future

EndpointService::EndpointService(ArduinoController& ac) : _ac(ac) {}; // constructed with ac attached

Result EndpointService::redLedPower(const uint16_t* args, uint8_t count)
{
    Led& redLed = this->_ac.getRedLed();
    bool state = !(redLed.getState()); // get opposite of current state
    if (count > 0 && (args[0] == 1 || args[0] == 0))
    {
        state = args[0];
    }

    redLed.power(state);
    return Result::Success(); // still need to sort out result stuff lol
}

Result EndpointService::onboardLedPower(const uint16_t* args, uint8_t count)
{
    OnboardLed& onboardLed = this->_ac.getOnBoardLed();
    bool state = !(onboardLed.getState());
    if (count > 0 && (args[0] == 1 || args[0] == 0))
    {
        state = args[0];
    }

    onboardLed.power(state);
    return Result::Success();
}

Result EndpointService::yes(const uint16_t* args, uint8_t count)
{
    Led& yesLed = this->_ac.getYesLed();

    if (count > 0 && (args[0] == 1 || args[0] == 0))
    {
        yesLed.power(args[0]);
    }
        
    else
    {
        yesLed.power();
    }
        
    return Result::Success(); // still need to sort out result stuff lol
}

Result EndpointService::no(const uint16_t* args, uint8_t count)
{
    Led& noLed = this->_ac.getNoLed();
    HC& hc = this->_ac.getHC();

    bool state = !(noLed.getState()); // get opposite of current state
    if (count > 0 && (args[0] == 1 || args[0] == 0))
    {
        state = args[0];
    }

    hc.adjustBit(noLed.getHcPin(), state); // flips bit on HC for LED
    return Result::Success(); // still need to sort out result stuff lol
}