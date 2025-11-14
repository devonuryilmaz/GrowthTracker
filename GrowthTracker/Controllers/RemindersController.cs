using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RemindersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<RemindersController> _logger;
        private readonly NotificationService _notificationService;

        public RemindersController(AppDbContext context, ILogger<RemindersController> logger, NotificationService notificationService)
        {
            _context = context;
            _logger = logger;
            _notificationService = notificationService;
        }

        [HttpGet("upcoming")]
        public async Task<IActionResult> GetUpcoming([FromQuery] int days = 7)
        {
            var now = DateTime.UtcNow;
            var endDate = now.AddDays(days);

            var reminders = await _context.Reminders.AsNoTracking()
                .Where(r => r.ReminderDate >= now && r.ReminderDate <= endDate && !r.IsCompleted)
                .OrderBy(r => r.ReminderDate)
                .ToListAsync();

            _logger.LogInformation("Retrieved upcoming reminders for the next {Days} days", days);

            return Ok(reminders);
        }

        [HttpPost]
        public async Task<IActionResult> CreateReminder([FromBody] Reminder reminder)
        {
            if (reminder == null)
                return BadRequest();

            if (reminder.ReminderDate <= DateTime.UtcNow)
                return BadRequest("Reminder date must be in the future.");

            if (string.IsNullOrWhiteSpace(reminder.Title))
                return BadRequest("Title is required.");

            _context.Reminders.Add(reminder);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created new reminder: {Title}", reminder.Title);

            return CreatedAtAction(nameof(GetUpcoming), new { id = reminder.Id }, reminder);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReminder(int id)
        {
            var reminder = await _context.Reminders.FindAsync(id);
            if (reminder == null)
            {
                return NotFound();
            }

            _context.Reminders.Remove(reminder);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Deleted reminder with ID: {Id}", id);

            return NoContent();
        }

        [HttpPut("{id}/complete")]
        public async Task<IActionResult> CompleteReminder(int id)
        {
            var reminder = await _context.Reminders.FindAsync(id);
            if (reminder == null)
            {
                return NotFound();
            }

            reminder.IsCompleted = true;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Marked reminder with ID: {Id} as completed", id);

            return NoContent();
        }
    }
}
