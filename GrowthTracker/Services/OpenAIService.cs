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
        var systemPrompt = @$"You are a helpful assistant that suggests one personalized, practical micro‑task to support habit building and personal growth.

        User Profile:
        - Name: {user.Name}
        - Occupation/Role: {user.Job}
        - Age: {user.Age}

        Guidelines:
        - The task must take ≤ 30 minutes.
        - Be specific, actionable, and safe.
        - Tailor to the user's role and likely interests.
        - Prefer areas like: health & wellness, productivity, learning, mindfulness, organization, relationships, finances.
        - Avoid technical jargon unless clearly relevant to their role.
        - Output format:
        Title: <short title>
        Description: <2–3 sentences with clear steps>";

        // Ask for a single personalized suggestion
        var chatResponse = await _openAIClient.GetChatClient("gpt-4o")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage(systemPrompt),
                    ChatMessage.CreateUserMessage($"Suggest one personalized micro‑task for {user.Name} (role: {user.Job}, age: {user.Age}).")
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