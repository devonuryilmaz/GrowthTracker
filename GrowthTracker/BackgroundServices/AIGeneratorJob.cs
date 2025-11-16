using System;
using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Services;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.BackgroundServices;

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
        
        var devices = await _dbContext.DeviceTokens.AsNoTracking()
            .Include(d => d.User)
            .ToListAsync();

        var taskList = new List<DailyTask>();
        
        if (devices.Count == 0)
        {
            _logger.LogWarning("No device tokens found. Skipping AI task generation.");
            return;
        }

        foreach (var device in devices)
        {
            _logger.LogInformation("Generating tasks for User: {UserId}, Device: {DeviceId}", device.UserId, device.Id);
        
            var taskSuggestions = await _openAIService.GenerateTaskSuggestionsAsync(device.User);

            var task = new DailyTask
            {
                Title = taskSuggestions.Length > 50 ? taskSuggestions.Substring(0, 50) : taskSuggestions,
                Description = taskSuggestions
            };

            taskList.Add(task);
       
            if (!string.IsNullOrEmpty(taskSuggestions))
            {
                _logger.LogInformation("Generated Task Suggestions: {Suggestions}", taskSuggestions);
            }
            else
            {
                _logger.LogWarning("No task suggestions were generated.");
            }
        }

        await _dbContext.DailyTasks.AddRangeAsync(taskList);
        await _dbContext.SaveChangesAsync();
    }
}
