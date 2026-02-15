namespace RentComProAgent.Models
{
    public class ServerResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public bool LockStatus { get; set; }
        public string DeviceStatus { get; set; } = string.Empty;
    }
}
