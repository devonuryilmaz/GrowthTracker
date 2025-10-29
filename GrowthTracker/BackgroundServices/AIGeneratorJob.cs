using System;
using GrowthTracker.API.Data;
using GrowtTracker.API.Models;
using GrowtTracker.API.Services;

namespace GrowtTracker.API.BackgroundServices;

public class AIGeneratorJob
{
    private readonly ILogger<AIGeneratorJob> _logger;
    private readonly OpenAIService _openAIService;
    private readonly AppDbContext _dbContext;

    public AIGeneratorJob(ILogger<AIGeneratorJob> logger, OpenAIService openAIService, AppDbContext dbContext)
    {
        _logger = logger;
        _openAIService = openAIService;
        _dbContext = dbContext;
    }

    public async Task GenerateTasksAsync()
    {
        _logger.LogInformation("AI Task Generation started at: {Time}", DateTimeOffset.Now);

        var taskSuggestions = await _openAIService.GenerateTaskSuggestionsAsync();

        var task = new DailyTask
        {
            Title = taskSuggestions.Length > 50 ? taskSuggestions.Substring(0, 50) : taskSuggestions,
            Description = taskSuggestions
        };

        _dbContext.DailyTasks.Add(task);
        await _dbContext.SaveChangesAsync();

        if (!string.IsNullOrEmpty(taskSuggestions))
        {
            _logger.LogInformation("Generated Task Suggestions: {Suggestions}", taskSuggestions);
        }
        else
        {
            _logger.LogWarning("No task suggestions were generated.");
        }
    }
}
