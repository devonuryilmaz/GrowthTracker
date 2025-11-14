using System;

namespace GrowthTracker.API.Entity;

public class DailyTask
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsCompleted { get; set; } = false;
}
