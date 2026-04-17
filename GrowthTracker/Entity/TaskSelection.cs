using System;

namespace GrowthTracker.API.Entity;

public class TaskSelection
{
    public int Id { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public int DailyTaskId { get; set; }
    public DailyTask DailyTask { get; set; } = null!;

    public DateTime SelectedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public string Status { get; set; } = TaskSelectionStatus.Pending;
}

public static class TaskSelectionStatus
{
    public const string Pending = "Pending";
    public const string Active = "Active";
    public const string Completed = "Completed";
    public const string Skipped = "Skipped";
}
