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
    }
}

