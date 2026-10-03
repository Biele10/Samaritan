#include <iostream>
#include <cstdint>
#include <cctype>
#include <cstring>

#include <alsa/asoundlib.h>
#include <vosk_api.h>
#include <curl/curl.h>

#include "config/config.hpp"
#include "processTranscription.hpp"

SpeechState cycleState = SpeechState::WAKE_WORD_INACTIVE; // this is used to determine which transcribed audio needs to be sent to the PHP which will then call Ollama

VoskModel* model;
VoskRecognizer* recognizer;
snd_pcm_t* pcm; // represents handle for our audio stream

void partialToLower(const char* partial, char* loweredPartial)
{
    uint16_t index = PARTIAL_FIRST_LETTER_INDEX;
    uint16_t charIndex = 0;

    while (index < SPEECH_CHAR_CAP && partial[index] != END_OF_PARTIAL)
    {
        loweredPartial[charIndex++] = (char)tolower((unsigned char)partial[index++]);
    }

    loweredPartial[charIndex] = '\0'; // adds null terminator to make into C type string which we can use strstr on
}

bool containsWakeWord(const char* partial)
{
    if (partial == nullptr) return false;
    
    char loweredPartial[SPEECH_CHAR_CAP];
    partialToLower(partial, loweredPartial);

    return strstr(loweredPartial, WAKE_WORD) != nullptr;
}

char* extractText(const char* result)
{
    const char* start = strstr(result, "\"text\"");

    if (start == nullptr)
    {
        return nullptr;
    }

    start = strchr(start, ':');

    if (start == nullptr)
    {
        return nullptr;
    }

    start++;

    while (*start == ' ' || *start == '\t' || *start == '"')
    {
        start++;
    }

    const char* end = strchr(start, '"');

    if (end == nullptr)
    {
        return nullptr;
    }

    size_t length = end - start;
    char* text = new char[length + 1];

    strncpy(text, start, length);
    text[length] = '\0';

    return text;
}

bool setup()
{
    // ALSA stuff

    int result = snd_pcm_open(
        &pcm, // ALSA needs a pointer to point to to open handle, so give address
        ALSA_INPUT_NAME, // name of our audio device that handle will be assigned to
        SND_PCM_STREAM_CAPTURE, // tells handle we want to capture audio
        0 // normal behaviour, no flags needed
    );

    if (result < 0)
    {
        std::cerr << "Failed to open microphone: " << snd_strerror(result) << std::endl;
        return false;
    }

    // 16-bit signed little-endian
    snd_pcm_format_t format = SND_PCM_FORMAT_S16_LE; // VOSK needs 16 bit PCM audio, so this is format was select, 16 bit audio

    // this is configuring settings so we can read audio the way we want
    result = snd_pcm_set_params(
        pcm, // our microphone
        format, // format we decided on
        SND_PCM_ACCESS_RW_INTERLEAVED, // read the sound through normal read operations
        1,          // mono (1 = 1 audio channel)
        16000,      // 16 kHz
        1,          // allow software resampling (if intternal microphone operates at different sample rate, ALSA can convert to one we want)
        500000      // latency in microseconds
    );

    if (result < 0)
    {
        std::cerr << "Failed to configure microphone: " << snd_strerror(result) << std::endl;

        snd_pcm_close(pcm);
        return false;
    }

    std::cout << "Microphone ready." << std::endl;

    // Vosk stuff (by this point our microphone is open, we now want to read data from it and transcribe)
    model = vosk_model_new(VOSK_MODEL_LOCATION); // our model is what stores data for speech-to-text i.e what sound frequencies correspond with which words
    if (model == nullptr)
    {
        std::cerr << "Failed to load Vosk model." << std::endl;

        snd_pcm_close(pcm);
        return false;
    }

    recognizer = vosk_recognizer_new(model, 16000.0f); // telling recognizer that our audio will be 16kHz samples, this is what uses the model to then process sound with data
    if (recognizer == nullptr)
    {
        std::cerr << "Failed to create Vosk recognizer." << std::endl;

        vosk_model_free(model);
        snd_pcm_close(pcm);
        return false;
    }

    curl_global_init(CURL_GLOBAL_ALL); // get curl set up for later requests

    return true;
}

int main()
{
    if (!setup())
    {
        return 1;
    }

    // Audio buffer
    const int frames = 1600;
    int16_t buffer[frames];

    // Streaming (this is now where we combine the two, read data from microphone and transcribe with Vosk model)
    while (true)
    {
        snd_pcm_sframes_t framesRead =
            snd_pcm_readi( // reading audio from PCM device
                pcm, // mic
                buffer, // temporary store of our audio data
                frames // how much to read from data
            );

        if (framesRead < 0)
        {
            framesRead = snd_pcm_recover(pcm, framesRead, 1); // attempts to reestablish microphone connection

            if (framesRead < 0)
            {
                std::cerr << "ALSA read error: " << snd_strerror(framesRead) << std::endl;
                break;
            }

            continue;
        }

        int final =
            vosk_recognizer_accept_waveform(
                recognizer,
                reinterpret_cast<const char*>(buffer),
                framesRead * sizeof(int16_t)
            );

        if (final)
        {
            if (cycleState == SpeechState::WAKE_WORD_ACTIVE) // this sentence was being recorded, we can send this elsewhere to be processed
            {
                const char* result = vosk_recognizer_result(recognizer);
                char* command = extractText(result);

                if (command != nullptr)
                {
                    process(command); // calls the transcription processor
                }

                cycleState = SpeechState::WAKE_WORD_INACTIVE; // cycle state now back in normal inactive state, audio input will not be recorded until wake word is spoken again
            }

            std::cout << vosk_recognizer_result(recognizer) << std::endl;
        }

        else
        {
            const char* partialResult = vosk_recognizer_partial_result(recognizer);
            if (containsWakeWord(partialResult))
            {
                cycleState = SpeechState::WAKE_WORD_ACTIVE; // we heard the wake word, everything in this utterance should be recorded
                std::cout << "Wake word: " << WAKE_WORD << " was called, recording rest of sentence." << std::endl;
            }

            std::cout << partialResult << std::endl;
        }
    }

    // Cleanup
    vosk_recognizer_free(recognizer);
    vosk_model_free(model);
    snd_pcm_close(pcm);
    curl_global_cleanup();

    return 0;
}