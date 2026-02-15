using System.Diagnostics;
using System.Management;
using Microsoft.Extensions.Logging;
using RentComProAgent.Models;

namespace RentComProAgent.Services
{
    public class HardwareMonitorService
    {
        private readonly ILogger<HardwareMonitorService> _logger;
        private readonly PerformanceCounter _cpuCounter;
        private readonly PerformanceCounter _ramCounter;

        public HardwareMonitorService(ILogger<HardwareMonitorService> logger)
        {
            _logger = logger;
            
            // Initialize performance counters
            _cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
            _ramCounter = new PerformanceCounter("Memory", "% Committed Bytes In Use");
        }

        public HardwareStats CollectStats()
        {
            try
            {
                // Collect network info
                var networkInfo = NetworkDetectionService.DetectNetwork();
                
                var stats = new HardwareStats
                {
                    CpuUsage = GetCpuUsage(),
                    RamUsage = GetRamUsage(),
                    RamTotal = GetTotalRam(),
                    RamUsed = GetUsedRam(),
                    DiskUsage = GetDiskUsage(),
                    DiskTotal = GetTotalDisk(),
                    DiskUsed = GetUsedDisk(),
                    IsOnline = CheckInternetConnection(),
                    CurrentUser = GetCurrentUser(),
                    Timestamp = DateTime.UtcNow,
                    
                    // NEW: Network information
                    LanMacAddress = networkInfo.LanMacAddress,
                    ActiveMacAddress = networkInfo.ActiveMacAddress,
                    ConnectionType = networkInfo.ConnectionType,
                    IpAddress = networkInfo.IpAddress,
                    ComputerName = Environment.MachineName
                };

                _logger.LogInformation("Network detected - LAN MAC: {lanMac}, Active MAC: {activeMac}, Type: {type}", 
                    stats.LanMacAddress, stats.ActiveMacAddress, stats.ConnectionType);

                return stats;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error collecting hardware stats");
                throw;
            }
        }

        private float GetCpuUsage()
        {
            try
            {
                _cpuCounter.NextValue(); // First call always returns 0
                Thread.Sleep(100); // Small delay for accurate reading
                return _cpuCounter.NextValue();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting CPU usage");
                return 0;
            }
        }

        private float GetRamUsage()
        {
            try
            {
                return _ramCounter.NextValue();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting RAM usage");
                return 0;
            }
        }

        private long GetTotalRam()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher("SELECT TotalVisibleMemorySize FROM Win32_OperatingSystem");
                foreach (ManagementObject obj in searcher.Get())
                {
                    return Convert.ToInt64(obj["TotalVisibleMemorySize"]) * 1024; // Convert KB to Bytes
                }
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting total RAM");
                return 0;
            }
        }

        private long GetUsedRam()
        {
            try
            {
                var totalRam = GetTotalRam();
                var availableRam = GetAvailableRam();
                return totalRam - availableRam;
            }
            catch
            {
                return 0;
            }
        }

        private long GetAvailableRam()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher("SELECT FreePhysicalMemory FROM Win32_OperatingSystem");
                foreach (ManagementObject obj in searcher.Get())
                {
                    return Convert.ToInt64(obj["FreePhysicalMemory"]) * 1024; // Convert KB to Bytes
                }
                return 0;
            }
            catch
            {
                return 0;
            }
        }

        private float GetDiskUsage()
        {
            try
            {
                var cDrive = DriveInfo.GetDrives().FirstOrDefault(d => d.Name == "C:\\");
                if (cDrive != null && cDrive.IsReady)
                {
                    var usedSpace = cDrive.TotalSize - cDrive.AvailableFreeSpace;
                    return (float)(usedSpace * 100.0 / cDrive.TotalSize);
                }
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting disk usage");
                return 0;
            }
        }

        private long GetTotalDisk()
        {
            try
            {
                var cDrive = DriveInfo.GetDrives().FirstOrDefault(d => d.Name == "C:\\");
                return cDrive?.TotalSize ?? 0;
            }
            catch
            {
                return 0;
            }
        }

        private long GetUsedDisk()
        {
            try
            {
                var cDrive = DriveInfo.GetDrives().FirstOrDefault(d => d.Name == "C:\\");
                if (cDrive != null && cDrive.IsReady)
                {
                    return cDrive.TotalSize - cDrive.AvailableFreeSpace;
                }
                return 0;
            }
            catch
            {
                return 0;
            }
        }

        private bool CheckInternetConnection()
        {
            try
            {
                using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
                var response = client.GetAsync("https://www.google.com").GetAwaiter().GetResult();
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        private string GetCurrentUser()
        {
            try
            {
                return Environment.UserName;
            }
            catch
            {
                return "Unknown";
            }
        }
    }
}
