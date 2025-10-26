using System;
using GrowthTracker.API.Data;
using GrowthTracker.API.Services;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.BackgroundServices;

public class ReminderJob
{
    private readonly AppDbContext _context;
    private readonly NotificationService _notificationService;

    public ReminderJob(AppDbContext context, NotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task SendPendingReminders()
    {
        var now = DateTime.UtcNow;
        var reminders = await _context.Reminders
            .Where(r => r.ReminderDate <= now && !r.IsCompleted)
            .ToListAsync();

        foreach (var reminder in reminders)
        {
            string fcmToken = "TEST_TOKEN";

            await _notificationService.SendNotificationAsync(fcmToken, reminder.Title, reminder.Description);

            reminder.IsCompleted = true;
        }   

        await _context.SaveChangesAsync();
    }
}
