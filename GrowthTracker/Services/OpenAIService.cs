using System;
using OpenAI;
using OpenAI.Chat;

namespace GrowtTracker.API.Services;

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
        var chatResponse = await _openAIClient.GetChatClient("gpt-4o-mini")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage("You are a helpful AI assistant that suggests short tasks."),
                    ChatMessage.CreateUserMessage("Suggest one small daily programming task for a full stack developer.")
                },
                options: new ChatCompletionOptions
                {
                    Temperature = 0.7f,
                    MaxOutputTokenCount = 150,
 
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
