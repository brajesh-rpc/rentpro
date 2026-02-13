using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RentComProAgent.Services;

namespace RentComProAgent
{
    public class AgentWorker : BackgroundService
    {
        private readonly ILogger<AgentWorker> _logger;
        private readonly AgentConfig _config;
        private readonly HardwareMonitorService _hardwareMonitor;
        private readonly ApiCommunicationService _apiService;
        private readonly LockService _lockService;

        public AgentWorker(
            ILogger<AgentWorker> logger,
            IOptions<AgentConfig> config,
            HardwareMonitorService hardwareMonitor,
            ApiCommunicationService apiService,
            LockService lockService)
        {
            _logger = logger;
            _config = config.Value;
            _hardwareMonitor = hardwareMonitor;
            _apiService = apiService;
            _lockService = lockService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("RentComPro Agent starting...");

            // First-time setup if needed
            if (string.IsNullOrEmpty(_config.DeviceId))
            {
                _logger.LogWarning("Device not registered. Please run setup first.");
                return;
            }

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Collect hardware stats
                    if (_config.EnableHardwareMonitoring)
                    {
                        var stats = _hardwareMonitor.CollectStats();
                        _logger.LogInformation("Hardware stats collected: CPU {cpu}%, RAM {ram}%", 
                            stats.CpuUsage, stats.RamUsage);

                        // Send stats to server
                        var response = await _apiService.SendHardwareStatsAsync(stats);
                        
                        if (response != null && response.LockStatus)
                        {
                            _logger.LogWarning("Device lock requested by server");
                            if (_config.EnableLocking)
                            {
                                _lockService.LockDevice();
                            }
                        }
                        else
                        {
                            _lockService.UnlockDevice();
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in agent worker loop");
                }

                // Wait for next interval
                await Task.Delay(TimeSpan.FromSeconds(_config.ReportingIntervalSeconds), stoppingToken);
            }

            _logger.LogInformation("RentComPro Agent stopping...");
        }
    }
}
