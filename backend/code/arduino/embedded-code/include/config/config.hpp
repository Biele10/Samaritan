#pragma once
#include <Arduino.h>

// When setting pin numbers for items on the arduino, this is the ideal place to store them

namespace Config
{
    constexpr const uint8_t RED_LED_PIN = 11;

    // 74HC595 chip config values
    constexpr const uint8_t HC_DATA_PIN = 12;
    constexpr const uint8_t HC_CLOCK_PIN = 10;
    constexpr const uint8_t HC_LATCH_PIN = 13;
    constexpr const uint8_t HC_MAX_INDEX = 7;

    constexpr const uint8_t HC_RED_LED_PIN = 0; // anything 'HC' means the pin relative to the 74HC595 chip
    constexpr const uint8_t HC_GREEN_LED_PIN = 1;


    constexpr size_t BASE_ARRAY_SIZE = 10;
    constexpr size_t DEFAULT_ARRAY_ADDITION = 10;       // default amount to increase an array size by
    constexpr size_t BASE_HASH_TABLE_SIZE = 10;
    constexpr size_t APPROX_DOOR_DISTANCE = 240;
    const char PARSER_SEPARATOR = '&';      // symbol that parser looks for when separating values
    const char PARSER_VALUE_ASSIGNATION = '=';    // symbol that parser uses to determine next sequence of chars is the value to assign to previous key
}

#define NO_PIN 255

namespace ErrorCode
{
    enum Code : uint8_t
    {
        NONE = 0,
        INVALID_MODULE = 1,
        MODULE_NOT_EXIST = 2,
        INVALID_COMMAND = 3,
        INVALID_PIN = 4,
        HARDWARE_FAILURE = 5
    };
}