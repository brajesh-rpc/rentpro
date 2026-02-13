namespace RentComProAgent
{
    public class AgentConfig
    {
        public string ApiBaseUrl { get; set; } = "https://rentcompro-backend.brajesh-jimmc.workers.dev";
        public string DeviceId { get; set; } = string.Empty;
        public string DeviceToken { get; set; } = string.Empty;
        public int ReportingIntervalSeconds { get; set; } = 300; // 5 minutes
        public bool EnableLocking { get; set; } = true;
        public bool EnableHardwareMonitoring { get; set; } = true;
    }
}
