using System.Management;

namespace RentComProAgent.Services
{
    public class SystemInfoService
    {
        public static string GetBiosSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BIOS"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        var serial = obj["SerialNumber"]?.ToString();
                        if (!string.IsNullOrWhiteSpace(serial) && serial != "To Be Filled By O.E.M.")
                        {
                            return serial.Trim();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting BIOS serial: {ex.Message}");
            }
            
            return string.Empty;
        }

        public static string GetMotherboardSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BaseBoard"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        var serial = obj["SerialNumber"]?.ToString();
                        if (!string.IsNullOrWhiteSpace(serial) && serial != "To Be Filled By O.E.M.")
                        {
                            return serial.Trim();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting motherboard serial: {ex.Message}");
            }
            
            return string.Empty;
        }

        public static string GetSystemSerialNumber()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_SystemEnclosure"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        var serial = obj["SerialNumber"]?.ToString();
                        if (!string.IsNullOrWhiteSpace(serial) && serial != "To Be Filled By O.E.M.")
                        {
                            return serial.Trim();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting system serial: {ex.Message}");
            }
            
            return string.Empty;
        }

        // Get best available serial number
        public static string GetDeviceSerialNumber()
        {
            // Try BIOS serial first (most reliable for laptops)
            string serial = GetBiosSerialNumber();
            if (!string.IsNullOrEmpty(serial))
                return serial;

            // Try system enclosure (good for desktops)
            serial = GetSystemSerialNumber();
            if (!string.IsNullOrEmpty(serial))
                return serial;

            // Fallback to motherboard
            serial = GetMotherboardSerialNumber();
            if (!string.IsNullOrEmpty(serial))
                return serial;

            // Last resort - generate from MAC address
            return "CUSTOM-" + GetMacAddress().Replace(":", "").Substring(0, 8);
        }

        public static string GetMacAddress()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher("SELECT MACAddress FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL"))
                {
                    foreach (ManagementObject obj in searcher.Get())
                    {
                        var mac = obj["MACAddress"]?.ToString();
                        if (!string.IsNullOrWhiteSpace(mac))
                        {
                            return mac;
                        }
                    }
                }
            }
            catch { }

            return "00:00:00:00:00:00";
        }

        public static string GetComputerName()
        {
            return Environment.MachineName;
        }

        public static string GetIpAddress()
        {
            try
            {
                var host = System.Net.Dns.GetHostEntry(System.Net.Dns.GetHostName());
                foreach (var ip in host.AddressList)
                {
                    if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                    {
                        return ip.ToString();
                    }
                }
            }
            catch { }

            return "0.0.0.0";
        }
    }
}
