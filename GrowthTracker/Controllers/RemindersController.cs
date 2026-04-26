using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RemindersController : ControllerBase
    {
        private readonly IReminderService _reminderService;

        public RemindersController(IReminderService reminderService)
        {
            _reminderService = reminderService;
        }

        [HttpGet("upcoming")]
        public async Task<IActionResult> GetUpcoming([FromQuery] int days = 7)
        {
            var reminders = await _reminderService.GetUpcomingAsync(days);
            return Ok(reminders);
        }

        [HttpPost]
        public async Task<IActionResult> CreateReminder([FromBody] Reminder reminder)
        {
            if (reminder == null)
                return BadRequest();

            var result = await _reminderService.CreateReminderAsync(reminder);

            if (!result.IsSuccess)
                return BadRequest(result.Error);

            return CreatedAtAction(nameof(GetUpcoming), new { id = result.Data!.Id }, result.Data);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReminder(int id)
        {
            var found = await _reminderService.DeleteReminderAsync(id);
            return found ? NoContent() : NotFound();
        }

        [HttpPut("{id}/complete")]
        public async Task<IActionResult> CompleteReminder(int id)
        {
            var found = await _reminderService.CompleteReminderAsync(id);
            return found ? NoContent() : NotFound();
        }
    }
}
