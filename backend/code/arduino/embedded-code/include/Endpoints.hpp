#pragma once
#include "Arduino.h"
#include "output/Result.hpp"

// This class is where endpoint binary commands are defined, the complete details for how to add an endpoint are in the README.

struct Endpoint
{
    virtual Result invoke(uint16_t* args, uint8_t count) = 0; // way of calling our member function on object
    virtual ~Endpoint() = default;
};

template<typename T>
struct TypedEndpoint : Endpoint
{
    T* object;
    Result (T::*handler)(uint16_t*, uint8_t);

    TypedEndpoint(T* object, Result (T::*handler)(uint16_t*, uint8_t)): object(object), handler(handler)
    {}

    Result invoke(uint16_t* args, uint8_t count) override
    {
        return (object->*handler)(args, count);
    }
};

// Endpoint binary commands

constexpr uint16_t RED_LED_POWER = 0x0003;
constexpr uint16_t ONBOARD_LED_POWER = 0x0004;
constexpr uint16_t RED_LED_FLASH = 0x0005;
constexpr uint16_t GREEN_LED_FLASH = 0x0006;