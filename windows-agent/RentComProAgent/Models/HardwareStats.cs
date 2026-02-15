namespace RentComProAgent.Models
{
    public class HardwareStats
    {
        public float CpuUsage { get; set; }
        public float RamUsage { get; set; }
        public long RamTotal { get; set; }
        public long RamUsed { get; set; }
        public float DiskUsage { get; set; }
        public long DiskTotal { get; set; }
        public long DiskUsed { get; set; }
        public bool IsOnline { get; set; }
        public string CurrentUser { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
        
        // NEW: Network information
        public string LanMacAddress { get; set; } = string.Empty;
        public string ActiveMacAddress { get; set; } = string.Empty;
        public string ConnectionType { get; set; } = string.Empty;
        public string IpAddress { get; set; } = string.Empty;
        public string ComputerName { get; set; } = string.Empty;
    }
}
