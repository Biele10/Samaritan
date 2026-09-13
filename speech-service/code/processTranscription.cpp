#include <iostream>
#include <cstring>
#include <stdio.h>
#include <curl/curl.h>

// This file is what handles the message the user is making. This parses the input and sends it off to the server via curl.

/**
 * Sends web request with parsed data.
 */
bool curl()
{

}

void process(char* voiceCommand)
{
    char* copyVoiceCommand = new char[strlen(voiceCommand) + 1];
    strcpy(copyVoiceCommand, voiceCommand); // creates our copy so we don't lose it

    

    delete[] copyVoiceCommand;
}