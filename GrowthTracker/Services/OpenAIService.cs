using System;
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

    public async Task<string> GenerateTaskSuggestionsAsync()
    {
        var chatResponse = await _openAIClient.GetChatClient("gpt-4o")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage(@"You are a creative AI assistant that suggests small, practical, and varied programming challenges for backend developers. 
                    Each task should take less than one hour and cover diverse topics such as APIs, databases, optimization, debugging, testing, 
                    security, or architecture. Avoid repeating similar ideas and ensure the output feels fresh each time."),
                    ChatMessage.CreateUserMessage("Suggest one short and realistic backend programming task with a brief description.")
                },
                options: new ChatCompletionOptions
                {
                    Temperature = 0.8f,
                    MaxOutputTokenCount = 200,

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
