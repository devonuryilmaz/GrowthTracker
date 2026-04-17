using System;

namespace GrowthTracker.API.Entity;

public class Reminder
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public DateTime ReminderDate { get; set; }
    public bool IsCompleted { get; set; }

    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public int? DailyTaskId { get; set; }
    public DailyTask? DailyTask { get; set; }
}
