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
        public AIController(OpenAIService openAIService, IUserService userService)
        {
            _openAIService = openAIService;
            _userService = userService;
        }

        [HttpGet("suggest")]
        public async Task<IActionResult> GetTaskSuggestion(Guid userId)
        {
            var user = await _userService.GetUserById(userId);
            
            if (user == null)
            {
                return NotFound("User not found.");
            }

            var suggestion = await _openAIService.GenerateTaskSuggestionsAsync(user);

            if (string.IsNullOrEmpty(suggestion))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, "Failed to generate task suggestion.");
            }

            return Ok(new { TaskSuggestion = suggestion });
        }
    }
}
