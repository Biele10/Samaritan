#pragma once
#include <cstdint>

constexpr const char* ALSA_INPUT_NAME = "{{ALSA_INPUT_NAME}}";
constexpr const char* VOSK_MODEL_LOCATION = "{{VOSK_MODEL_LOCATION}}";
constexpr const char* WAKE_WORD = "samaritan";
constexpr const uint8_t PARTIAL_FIRST_LETTER_INDEX = 16; // when partial is returned, we get {   "partial" : "x, x is all we are interested in
constexpr const char* END_OF_PARTIAL = '}';
constexpr const uint16_t SPEECH_CHAR_CAP = 65535;

enum class STATE
{
    WAKE_WORD_ACTIVE,
    WAKE_WORD_INACTIVE
};