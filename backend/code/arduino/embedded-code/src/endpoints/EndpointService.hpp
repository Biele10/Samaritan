#pragma once
#include "Arduino.h"
#include "config/config.hpp"
#include "output/Result.hpp"
#include "controller/ArduinoController.hpp"

// where all endpoints that server calls are defined, they MUST have this
// function signature 

// uint16_t* args, uint8_t count

class EndpointService
{
    private:
        ArduinoController& _ac; // IMPORTANT, this allows each endpoint to access each component class
    public:
        EndpointService(ArduinoController& ac);

        Result redLedPower(const uint16_t* args, uint8_t count);
        Result onboardLedPower(const uint16_t* args, uint8_t count);
        Result yes(const uint16_t* args, uint8_t count);
        Result no(const uint16_t* args, uint8_t count);
};