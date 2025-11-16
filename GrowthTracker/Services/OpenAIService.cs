using System;
using GrowthTracker.API.Entity;
using OpenAI;
using OpenAI.Chat;

namespace GrowthTracker.API.Services;

public class OpenAIService
{
    private readonly OpenAIClient _openAIClient;

    public OpenAIService(IConfiguration configuration)
    {
        var apiKey = configuration["OpenAI:ApiKey"];

        _openAIClient = new OpenAIClient(apiKey);
    }

    public async Task<string> GenerateTaskSuggestionsAsync(User user)
    {
        var systemPrompt = @$"You are a creative AI assistant that suggests personalized programming tasks for developers.
        
        User Profile:
        - Name: {user.Name}
        - Job: {user.Job}
        - Age: {user.Age}
        
        Based on their job role ({user.Job}), suggest a practical, small programming task that:
        - Takes less than one hour to complete
        - Is relevant to their current skill level and job
        - Feels fresh and varied each time
        
        Provide a clear title and brief description.";

        var chatResponse = await _openAIClient.GetChatClient("gpt-4o")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage(systemPrompt),
                    ChatMessage.CreateUserMessage("Suggest one short and realistic backend programming task with a brief description.")
                },
                options: new ChatCompletionOptions
                {
                    Temperature = 0.8f,
                    MaxOutputTokenCount = 250,

                }
            );

        // Response extraction
        if (chatResponse?.Value?.Content != null && chatResponse.Value.Content.Count > 0)
        {
            return chatResponse.Value.Content[0].Text.Trim();
        }

        // Fallback: boş dönerse uyar
        return string.Empty;
    }
}
