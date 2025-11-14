using GrowthTracker.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AIController : ControllerBase
    {
        private readonly OpenAIService _openAIService;

        public AIController(OpenAIService openAIService)
        {
            _openAIService = openAIService;
        }

        [HttpGet("suggest")]
        public async Task<IActionResult> GetTaskSuggestion()
        {
            var suggestion = await _openAIService.GenerateTaskSuggestionsAsync();

            if (string.IsNullOrEmpty(suggestion))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, "Failed to generate task suggestion.");
            }

            return Ok(new { TaskSuggestion = suggestion });
        }
    }
}
