using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Interfaces;

public interface IReminderService
{
    Task<List<Reminder>> GetUpcomingAsync(int days);
    Task<ServiceResult<Reminder>> CreateReminderAsync(Reminder reminder);
    Task<bool> DeleteReminderAsync(int id);
    Task<bool> CompleteReminderAsync(int id);
}
