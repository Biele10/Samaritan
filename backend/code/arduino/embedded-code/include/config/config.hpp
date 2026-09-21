#pragma once
#include <Arduino.h>

namespace Config
{
    constexpr int RED_LED_PIN = 11;
    constexpr int GREEN_LED_PIN = 3;
    constexpr int US_TRIG_PIN = 9;
    constexpr int US_ECHO_PIN = 10;
    constexpr size_t BASE_ARRAY_SIZE = 10;
    constexpr size_t DEFAULT_ARRAY_ADDITION = 10;       // default amount to increase an array size by
    constexpr size_t BASE_HASH_TABLE_SIZE = 10;
    constexpr size_t APPROX_DOOR_DISTANCE = 240;
    const char PARSER_SEPARATOR = '&';      // symbol that parser looks for when separating values
    const char PARSER_VALUE_ASSIGNATION = '=';    // symbol that parser uses to determine next sequence of chars is the value to assign to previous key
}

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