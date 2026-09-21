#include <iostream>
#include <cstring>
#include <curl/curl.h>
#include <thread>
#include <string>

#include "processTranscription.hpp"

// This file is what handles the message the user is making. This parses the input and sends it off to the server via curl.

/**
 * Sends web request with parsed data.
 */
void sendCommand(char* voiceCommand)
{
    CURL* handle = curl_easy_init();

    if (handle == nullptr)
    {
        delete[] voiceCommand;
        return;
    }

    curl_easy_setopt(handle, CURLOPT_URL, SAMARITAN_API_URL); // points to API endpoint
    curl_easy_setopt(handle, CURLOPT_TIMEOUT_MS, CURL_TIMEOUT);

    // constructing json
    std::string postData = "{\"command\":\"";

    for (size_t i = 0; voiceCommand[i] != '\0'; i++)
    {
        if (voiceCommand[i] == '"' || voiceCommand[i] == '\\')
        {
            postData += '\\';
        }

        postData += voiceCommand[i];
    }

    postData += "\"}";

    struct curl_slist* headers = nullptr;

    headers = curl_slist_append(headers, "Content-Type: application/json");

    curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(handle, CURLOPT_POSTFIELDS, postData.c_str());

    std::cout << "POST DATA: " << postData << std::endl;
    
    CURLcode result = curl_easy_perform(handle); // executes curl request

    if (result != CURLE_OK)
    {
        std::cout << "Failed to send command: " << curl_easy_strerror(result) << std::endl;
    }

    curl_slist_free_all(headers);
    curl_easy_cleanup(handle);

    delete[] voiceCommand; // deletes our copy once the thread has finished using it
}

/**
 * Processes voice command by copying the string and sending it
 * asynchronously (wow big word), allowing the speech service to continue running
 * while the web request is being processed.
 */
void process(const char* voiceCommand)
{
    char* copyVoiceCommand = new char[strlen(voiceCommand) + 1];
    strcpy(copyVoiceCommand, voiceCommand); // creates our copy so we don't lose it

    std::thread(sendCommand, copyVoiceCommand).detach(); // posts the voice command to API asynchronously
}