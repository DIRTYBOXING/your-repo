# This is a more powerful V2 script that avoids tricky quote errors.

Write-Host "Starting the DFC file creator script (V2)..."

# --- File 1: The Guardian Contact Data Model ---
$entityDir = "DataFightCentral.Domain/Entities"
$entityPath = "$entityDir/GuardianContact.cs"
if (-not (Test-Path $entityDir)) { New-Item -ItemType Directory -Force -Path $entityDir }
$entityContent = @(
    "namespace DataFightCentral.Domain.Entities",
    "{",
    "    public class GuardianContact",
    "    {",
    "        public string Name { get; set; }",
    "        public string PhoneNumber { get; set; }",
    "    }",
    "}"
)
Set-Content -Path $entityPath -Value $entityContent
Write-Host "SUCCESS: Created GuardianContact.cs"


# --- File 2: The Guardian Protocol Controller ---
$controllerDir = "DataFightCentral.Api/Controllers"
$controllerPath = "$controllerDir/GuardianProtocolController.cs"
if (-not (Test-Path $controllerDir)) { New-Item -ItemType Directory -Force -Path $controllerDir }
$controllerContent = @(
    "using DataFightCentral.Domain.Entities;",
    "using DataFightCentral.Api.Services;",
    "using Microsoft.AspNetCore.Mvc;",
    "using System.Threading.Tasks;",
    "using System.Collections.Generic;",
    "",
    "namespace DataFightCentral.Api.Controllers",
    "{",
    "    [ApiController]",
    "    [Route(`"api/[controller]`")]",
    "    public class GuardianProtocolController : ControllerBase",
    "    {",
    "        private readonly GuardianProtocolService _guardianProtocolService;",
    "",
    "        public GuardianProtocolController(GuardianProtocolService guardianProtocolService)",
    "        {",
    "            _guardianProtocolService = guardianProtocolService;",
    "        }",
    "",
    "        [HttpPost(`"circle`")]",
    "        public async Task<IActionResult> SaveGuardianCircle([FromBody] GuardianCircleUpdateRequest request)",
    "        {",
    "            var userId = `"temp-user-id`"; // Placeholder for real user ID",
    "            await _guardianProtocolService.SaveGuardianCircle(userId, request.Contacts);",
    "            return Ok();",
    "        }",
    "",
    "        [HttpPost(`"activate`")]",
    "        public async Task<IActionResult> ActivateProtocol()",
    "        {",
    "            var userId = `"temp-user-id`"; // Placeholder for real user ID",
    "            await _guardianProtocolService.ActivateProtocol(userId);",
    "            return Ok();",
    "        }",
    "    }",
    "",
    "    public class GuardianCircleUpdateRequest",
    "    {",
    "        public List<GuardianContact> Contacts { get; set; }",
    "    }",
    "}"
)
Set-Content -Path $controllerPath -Value $controllerContent
Write-Host "SUCCESS: Created GuardianProtocolController.cs"


# --- File 3: The Guardian Protocol Service (The Engine) ---
$serviceDir = "DataFightCentral.Api/Services"
$servicePath = "$serviceDir/GuardianProtocolService.cs"
if (-not (Test-Path $serviceDir)) { New-Item -ItemType Directory -Force -Path $serviceDir }
$serviceContent = @(
    "using DataFightCentral.Domain.Entities;",
    "using System.Collections.Generic;",
    "using System.Text.Json;",
    "using System.Threading.Tasks;",
    "",
    "namespace DataFightcentral.Api.Services",
    "{",
    "    // This is a placeholder service for now.",
    "    public class GuardianProtocolService",
    "    {",
    "        public Task SaveGuardianCircle(string userId, List<GuardianContact> contacts)",
    "        {",
    "            var contactsJson = JsonSerializer.Serialize(contacts);",
    "            // In the real version, we will encrypt this data and save it to the database.",
    "            System.Console.WriteLine($`"Saving contacts for user {userId}: {contactsJson}`");",
    "            return Task.CompletedTask;",
    "        }",
    "",
    "        public Task ActivateProtocol(string userId)",
    "        {",
    "            var contacts = new List<GuardianContact> { new GuardianContact { Name = `"Jane Doe`", PhoneNumber = `"+15551234567`" } };",
    "            // In the real version, we will get contacts from the DB and send a real SMS.",
    "            foreach (var contact in contacts)",
    "            {",
    "                var message = $`"This is a test of the DFC Guardian Protocol for {userId}. Please check on them.`";",
    "                System.Console.WriteLine($`"SENDING ALERT to {contact.Name} at {contact.PhoneNumber}: {message}`");",
    "            }",
    "            return Task.CompletedTask;",
    "        }",
    "    }",
    "}"
)
Set-Content -Path $servicePath -Value $serviceContent
Write-Host "SUCCESS: Created GuardianProtocolService.cs"


Write-Host ""
Write-Host "-------------------------------------------"
Write-Host "ALL DONE! The magic script has finished."
Write-Host "-------------------------------------------"
