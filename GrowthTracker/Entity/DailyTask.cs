using System;

namespace GrowthTracker.API.Entity;

public class DailyTask
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsCompleted { get; set; } = false;

    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public string Category { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
    public bool IsSelected { get; set; } = false;
    public DateTime? CompletedAt { get; set; }

    public ICollection<TaskSelection> TaskSelections { get; set; } = new List<TaskSelection>();
}
