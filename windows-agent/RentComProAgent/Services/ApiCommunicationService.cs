using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RentComProAgent.Models;

namespace RentComProAgent.Services
{
    public class ApiCommunicationService
    {
        private readonly ILogger<ApiCommunicationService> _logger;
        private readonly AgentConfig _config;
        private readonly HttpClient _httpClient;

        public ApiCommunicationService(
            ILogger<ApiCommunicationService> logger,
            IOptions<AgentConfig> config)
        {
            _logger = logger;
            _config = config.Value;
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(_config.ApiBaseUrl),
                Timeout = TimeSpan.FromSeconds(30)
            };
        }

        public async Task<ServerResponse?> SendHardwareStatsAsync(HardwareStats stats)
        {
            try
            {
                var payload = new
                {
                    deviceId = _config.DeviceId,
                    deviceToken = _config.DeviceToken,
                    cpuUsage = stats.CpuUsage,
                    ramUsage = stats.RamUsage,
                    ramTotal = stats.RamTotal,
                    ramUsed = stats.RamUsed,
                    diskUsage = stats.DiskUsage,
                    diskTotal = stats.DiskTotal,
                    diskUsed = stats.DiskUsed,
                    isOnline = stats.IsOnline,
                    currentUser = stats.CurrentUser,
                    timestamp = stats.Timestamp
                };

                var json = JsonSerializer.Serialize(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("/api/devices/stats", content);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    var serverResponse = JsonSerializer.Deserialize<ServerResponse>(responseBody, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    _logger.LogInformation("Stats sent successfully. Lock status: {lockStatus}", 
                        serverResponse?.LockStatus);

                    return serverResponse;
                }
                else
                {
                    _logger.LogWarning("Failed to send stats. Status code: {statusCode}", response.StatusCode);
                    return null;
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Network error while sending stats");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending hardware stats to server");
                return null;
            }
        }

        public async Task<bool> RegisterDeviceAsync(string deviceName, string deviceInfo)
        {
            try
            {
                var payload = new
                {
                    deviceName,
                    deviceInfo,
                    timestamp = DateTime.UtcNow
                };

                var json = JsonSerializer.Serialize(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("/api/devices/register", content);

                if (response.IsSuccessStatusCode)
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    var result = JsonSerializer.Deserialize<RegistrationResponse>(responseBody, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    if (result?.Success == true && result.Data != null)
                    {
                        // Save device ID and token to config
                        _logger.LogInformation("Device registered successfully. ID: {deviceId}", result.Data.DeviceId);
                        return true;
                    }
                }

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error registering device");
                return false;
            }
        }
    }

    public class ServerResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public bool LockStatus { get; set; }
    }

    public class RegistrationResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public RegistrationData? Data { get; set; }
    }

    public class RegistrationData
    {
        public string DeviceId { get; set; } = string.Empty;
        public string DeviceToken { get; set; } = string.Empty;
    }
}
