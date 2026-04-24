using System;
using System.Text.Json;
using GrowthTracker.API.Dtos;
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

    public async Task<List<TaskSuggestionDto>> GenerateTaskSuggestionsAsync(User user)
    {
        var focusArea = string.IsNullOrWhiteSpace(user.FocusArea) ? "genel kişisel gelişim" : user.FocusArea;

        var systemPrompt = $@"Sen kişisel gelişim koçusun. Kullanıcı için 3 farklı kategoride, günlük yapılabilir mikro-görevler öneriyorsun.

Kullanıcı Profili:
- İsim: {user.Name}
- Meslek: {user.Job}
- Yaş: {user.Age}
- Odak Alanı: {focusArea}

Kurallar:
- Birincil kategori kullanıcının odak alanıyla ilgili olmalı ({focusArea}).
- İkinci ve üçüncü kategoriler tamamlayıcı alanlarda olsun (sağlık, zihin, üretkenlik, öğrenme, mindfulness, finans).
- Her görev ≤ 30 dakika sürmeli.
- Görevler Türkçe olmalı.
- Spesifik, uygulanabilir ve pratik ol.

Yanıtı SADECE aşağıdaki JSON formatında ver, başka hiçbir metin ekleme:
{{
  ""tasks"": [
    {{""title"": ""..."", ""description"": ""..."", ""category"": ""..."", ""estimatedMinutes"": 15}},
    {{""title"": ""..."", ""description"": ""..."", ""category"": ""..."", ""estimatedMinutes"": 20}},
    {{""title"": ""..."", ""description"": ""..."", ""category"": ""..."", ""estimatedMinutes"": 10}}
  ]
}}";

        var chatResponse = await _openAIClient.GetChatClient("gpt-4o")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage(systemPrompt),
                    ChatMessage.CreateUserMessage($"{user.Name} için bugünkü 3 görevi öner.")
                },
                options: new ChatCompletionOptions
                {
                    Temperature = 1.0f,
                    MaxOutputTokenCount = 600,
                    ResponseFormat = ChatResponseFormat.CreateJsonObjectFormat()
                }
            );

        if (chatResponse?.Value?.Content == null || chatResponse.Value.Content.Count == 0)
            return new List<TaskSuggestionDto>();

        var json = chatResponse.Value.Content[0].Text.Trim();

        using var doc = JsonDocument.Parse(json);
        var tasksArray = doc.RootElement.GetProperty("tasks");
        var result = JsonSerializer.Deserialize<List<TaskSuggestionDto>>(
            tasksArray.GetRawText(),
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
        );

        return result ?? new List<TaskSuggestionDto>();
    }

    public async Task<List<TaskDetailSuggestionDto>> GenerateTaskExamplesAsync(DailyTask task, User user)
    {
        var systemPrompt = $@"Sen kişisel gelişim koçusun. Kullanıcıya verilen görev için somut, uygulanabilir 4 örnek öneriyorsun.

Kullanıcı Profili:
- İsim: {user.Name}
- Meslek: {user.Job}
- Yaş: {user.Age}
- Odak Alanı: {user.FocusArea}

Görev:
- Başlık: {task.Title}
- Açıklama: {task.Description}
- Kategori: {task.Category}
- Tahmini Süre: {task.EstimatedMinutes} dakika

Kurallar:
- Her örnek, kullanıcının mesleği ve odak alanıyla alakalı olmalı.
- Örnekler somut ve spesifik olmalı (""Redis"", ""Atomic Habits kitabı"", ""10 dakika nefes egzersizi"" gibi).
- Her örnek için kısa bir neden (why) açıklaması yaz.
- Tüm metinler Türkçe olmalı.

Yanıtı SADECE aşağıdaki JSON formatında ver, başka hiçbir metin ekleme:
{{
  ""examples"": [
    {{""example"": ""..."", ""why"": ""...""}},
    {{""example"": ""..."", ""why"": ""...""}},
    {{""example"": ""..."", ""why"": ""...""}},
    {{""example"": ""..."", ""why"": ""...""}}
  ]
}}";

        var chatResponse = await _openAIClient.GetChatClient("gpt-4o")
            .CompleteChatAsync(
                messages: new List<ChatMessage>
                {
                    ChatMessage.CreateSystemMessage(systemPrompt),
                    ChatMessage.CreateUserMessage($"'{task.Title}' görevi için {user.Name}'a 4 somut örnek öner.")
                },
                options: new ChatCompletionOptions
                {
                    Temperature = 1.0f,
                    MaxOutputTokenCount = 400,
                    ResponseFormat = ChatResponseFormat.CreateJsonObjectFormat()
                }
            );

        if (chatResponse?.Value?.Content == null || chatResponse.Value.Content.Count == 0)
            return new List<TaskDetailSuggestionDto>();

        var json = chatResponse.Value.Content[0].Text.Trim();

        using var doc = JsonDocument.Parse(json);
        var examplesArray = doc.RootElement.GetProperty("examples");
        var result = JsonSerializer.Deserialize<List<TaskDetailSuggestionDto>>(
            examplesArray.GetRawText(),
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
        );

        return result ?? new List<TaskDetailSuggestionDto>();
    }
}
