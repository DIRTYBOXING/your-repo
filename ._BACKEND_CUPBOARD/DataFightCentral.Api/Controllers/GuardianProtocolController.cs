using DataFightCentral.Domain.Entities;
using DataFightCentral.Api.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace DataFightCentral.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GuardianProtocolController : ControllerBase
    {
        private readonly GuardianProtocolService _guardianProtocolService;

        public GuardianProtocolController(GuardianProtocolService guardianProtocolService)
        {
            _guardianProtocolService = guardianProtocolService;
        }

        [HttpPost("circle")]
        public async Task<IActionResult> SaveGuardianCircle([FromBody] GuardianCircleUpdateRequest request)
        {
            var userId = "temp-user-id"; // Placeholder for real user ID
            await _guardianProtocolService.SaveGuardianCircle(userId, request.Contacts);
            return Ok();
        }

        [HttpPost("activate")]
        public async Task<IActionResult> ActivateProtocol()
        {
            var userId = "temp-user-id"; // Placeholder for real user ID
            await _guardianProtocolService.ActivateProtocol(userId);
            return Ok();
        }
    }

    public class GuardianCircleUpdateRequest
    {
        public List<GuardianContact> Contacts { get; set; }
    }
}
