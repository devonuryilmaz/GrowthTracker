using GrowthTracker.API.Data;
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.Services;

public class ReminderService : IReminderService
{
    private readonly AppDbContext _context;
    private readonly ILogger<ReminderService> _logger;

    public ReminderService(AppDbContext context, ILogger<ReminderService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<List<Reminder>> GetUpcomingAsync(int days)
    {
        var now = DateTime.UtcNow;
        var endDate = now.AddDays(days);

        var reminders = await _context.Reminders.AsNoTracking()
            .Where(r => r.ReminderDate >= now && r.ReminderDate <= endDate && !r.IsCompleted)
            .OrderBy(r => r.ReminderDate)
            .ToListAsync();

        _logger.LogInformation("Retrieved upcoming reminders for the next {Days} days", days);
        return reminders;
    }

    public async Task<ServiceResult<Reminder>> CreateReminderAsync(Reminder reminder)
    {
        if (reminder.ReminderDate <= DateTime.UtcNow)
            return ServiceResult<Reminder>.Failure("Reminder date must be in the future.", 400);

        if (string.IsNullOrWhiteSpace(reminder.Title))
            return ServiceResult<Reminder>.Failure("Title is required.", 400);

        _context.Reminders.Add(reminder);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Created new reminder: {Title}", reminder.Title);
        return ServiceResult<Reminder>.Success(reminder, 201);
    }

    public async Task<bool> DeleteReminderAsync(int id)
    {
        var reminder = await _context.Reminders.FindAsync(id);
        if (reminder == null)
            return false;

        _context.Reminders.Remove(reminder);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Deleted reminder with ID: {Id}", id);
        return true;
    }

    public async Task<bool> CompleteReminderAsync(int id)
    {
        var reminder = await _context.Reminders.FindAsync(id);
        if (reminder == null)
            return false;

        reminder.IsCompleted = true;
        await _context.SaveChangesAsync();

        _logger.LogInformation("Marked reminder with ID: {Id} as completed", id);
        return true;
    }
}
