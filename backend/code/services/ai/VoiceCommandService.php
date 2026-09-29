<?php

namespace Samaritan\services\ai;

class VoiceCommandService extends \Samaritan\services\Service
{
    public function sendVoiceCommand(string $command) : array
    {
        $payload = [
            'model' => 'samaritan',
            'messages' => [
                [
                    'role' => 'user',
                    'content' => $command
                ]
            ],
            'think' => false, // need quick response
            'format' => 'json',
            'stream' => false
        ];

        $ch = curl_init(\defined('OLLAMA_SERVICE_HOST') ? OLLAMA_SERVICE_HOST : 'http://localhost:11434/api/chat'); // ollama service on pi

        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json'
            ],
            CURLOPT_POSTFIELDS => json_encode($payload)
        ]);

        $response = curl_exec($ch);

        if ($response === false)
        {
            $error = curl_error($ch);
            curl_close($ch);

            return [
                'success' => false,
                'data' => [
                    'message' => 'Failed to communicate with Ollama.',
                    'error'   => $error
                ]
            ];
        }

        curl_close($ch);

        if ($response === null)
        {
            return [
                'success' => false,
                'data' => [
                    'message' => 'Invalid response from Ollama.'
                ]
            ];
        }        

        $action = trim($response);
        $availableRoutes = [
            '1' => '/api/hardware/redLed/power',
            '2' => '/api/hardware/yesLed/flash',
            '3' => '/api/hardware/noLed/flash'
        ];

        if (!isset($availableRoutes[$action]))
        {
            return [
                'success' => false,
                'data' => [
                    'message' => 'Invalid command returned by Ollama.'
                ]
            ];
        }

        $request = $availableRoutes[$action];

        $ch = curl_init('http://localhost' . $request);

        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => 'PUT',
            CURLOPT_RETURNTRANSFER => true
        ]);

            $result = curl_exec($ch);
            if ($result === false)
            {
                $error = curl_error($ch);
                curl_close($ch);

                return [
                    'success' => false,
                    'data' => [
                        'message' => 'Failed to execute Samaritan request.',
                        'error' => $error
                    ]
                ];
            }

            curl_close($ch);

            return [
                'success' => true,
                'data' => json_decode($result, true)
            ];
        }
    }
}