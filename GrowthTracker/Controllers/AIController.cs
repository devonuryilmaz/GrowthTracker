using GrowthTracker.API.Interfaces;
using GrowthTracker.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AIController : ControllerBase
    {
        private readonly OpenAIService _openAIService;
        private readonly IUserService _userService;
        private readonly IDailyTaskService _dailyTaskService;

        public AIController(OpenAIService openAIService, IUserService userService, IDailyTaskService dailyTaskService)
        {
            _openAIService = openAIService;
            _userService = userService;
            _dailyTaskService = dailyTaskService;
        }

        /// <summary>
        /// Kullanıcı için AI ile 3 görev önerisi üretir.
        /// </summary>
        [HttpGet("suggestions")]
        public async Task<IActionResult> GetTaskSuggestions([FromQuery] Guid userId)
        {
            var user = await _userService.GetUserById(userId);

            if (user == null)
                return NotFound("User not found.");

            var suggestions = await _openAIService.GenerateTaskSuggestionsAsync(user);

            if (suggestions.Count == 0)
                return StatusCode(StatusCodes.Status500InternalServerError, "Failed to generate task suggestions.");

            return Ok(suggestions);
        }

        /// <summary>
        /// Belirli bir görev için AI ile somut örnek öneriler üretir.
        /// </summary>
        [HttpGet("task-examples")]
        public async Task<IActionResult> GetTaskExamples([FromQuery] int taskId, [FromQuery] Guid userId)
        {
            var user = await _userService.GetUserById(userId);
            if (user == null)
                return NotFound("User not found.");

            var task = await _dailyTaskService.GetTaskByIdAsync(taskId, userId);

            if (task == null)
                return NotFound("Task not found.");

            var examples = await _openAIService.GenerateTaskExamplesAsync(task, user);

            if (examples.Count == 0)
                return StatusCode(StatusCodes.Status500InternalServerError, "Failed to generate task examples.");

            return Ok(examples);
        }
    }
}

