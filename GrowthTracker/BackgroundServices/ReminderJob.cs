using System;
using GrowthTracker.API.Data;
using GrowthTracker.API.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.BackgroundServices;

public class ReminderJob
{
    private readonly AppDbContext _context;
    private readonly IFirebaseService _firebaseService;
    private readonly ILogger<ReminderJob> _logger;

    public ReminderJob(AppDbContext context, IFirebaseService firebaseService, ILogger<ReminderJob> logger)
    {
        _context = context;
        _firebaseService = firebaseService;
        _logger = logger;
    }

    public async Task SendPendingReminders()
    {
        var now = DateTime.UtcNow;

        var reminders = await _context.Reminders
            .Include(r => r.DailyTask)
            .Where(r => r.ReminderDate <= now && !r.IsCompleted && r.UserId != null)
            .ToListAsync();

        if (reminders.Count == 0)
        {
            _logger.LogInformation("No pending reminders at {Time}.", now);
            return;
        }

        foreach (var reminder in reminders)
        {
            // Kullanıcının kayıtlı device token'larını al
            var deviceTokens = await _context.DeviceTokens
                .Where(dt => dt.UserId == reminder.UserId)
                .Select(dt => dt.Token)
                .ToListAsync();

            if (deviceTokens.Count == 0)
            {
                _logger.LogWarning("No device tokens for UserId {UserId}. Skipping reminder {ReminderId}.",
                    reminder.UserId, reminder.Id);
                reminder.IsCompleted = true;
                continue;
            }

            // Bildirim içeriğini zenginleştir
            string title = reminder.DailyTask != null
                ? $"⏰ Görev Zamanı: {reminder.DailyTask.Title}"
                : $"⏰ Hatırlatma: {reminder.Title}";

            string body = reminder.DailyTask != null
                ? $"{reminder.DailyTask.Description} ({reminder.DailyTask.EstimatedMinutes} dk) — Hadi başla! 💪"
                : reminder.Description;

            foreach (var token in deviceTokens)
            {
                try
                {
                    await _firebaseService.SendNotificationAsync(token, title, body);
                    _logger.LogInformation("Notification sent for reminder {ReminderId} to token ending ...{TokenEnd}",
                        reminder.Id, token.Length > 8 ? token[^8..] : token);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send notification for reminder {ReminderId}.", reminder.Id);
                }
            }

            reminder.IsCompleted = true;
        }

        await _context.SaveChangesAsync();
    }
}

