using DataFightCentral.Domain.Entities;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;

namespace DataFightcentral.Api.Services
{
    // This is a placeholder service for now.
    public class GuardianProtocolService
    {
        public Task SaveGuardianCircle(string userId, List<GuardianContact> contacts)
        {
            var contactsJson = JsonSerializer.Serialize(contacts);
            // In the real version, we will encrypt this data and save it to the database.
            System.Console.WriteLine($"Saving contacts for user {userId}: {contactsJson}");
            return Task.CompletedTask;
        }

        public Task ActivateProtocol(string userId)
        {
            var contacts = new List<GuardianContact> { new GuardianContact { Name = "Jane Doe", PhoneNumber = "+15551234567" } };
            // In the real version, we will get contacts from the DB and send a real SMS.
            foreach (var contact in contacts)
            {
                var message = $"This is a test of the DFC Guardian Protocol for {userId}. Please check on them.";
                System.Console.WriteLine($"SENDING ALERT to {contact.Name} at {contact.PhoneNumber}: {message}");
            }
            return Task.CompletedTask;
        }
    }
}
