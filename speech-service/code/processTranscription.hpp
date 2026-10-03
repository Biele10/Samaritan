#pragma once

#include <cstdint>

constexpr const char* SAMARITAN_API_URL = "http://localhost/api/ai/voice-command";
constexpr uint16_t CURL_TIMEOUT = 30000;

void sendCommand(char* voiceCommand);
void process(const char* voiceCommand);