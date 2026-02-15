using System.Management;
using System.Net.NetworkInformation;

namespace RentComProAgent.Services
{
    public class NetworkDetectionService
    {
        public class NetworkInfo
        {
            public string LanMacAddress { get; set; } = "";  // PERMANENT ID
            public string ActiveMacAddress { get; set; } = "";  // Current connection
            public string ConnectionType { get; set; } = "";  // LAN/WIFI/DONGLE
            public string IpAddress { get; set; } = "";
        }

        public static NetworkInfo DetectNetwork()
        {
            var info = new NetworkInfo();
            
            try
            {
                var adapters = NetworkInterface.GetAllNetworkInterfaces();
                
                string lanMac = "";
                string activeMac = "";
                string connectionType = "";

                foreach (var adapter in adapters)
                {
                    if (adapter.NetworkInterfaceType == NetworkInterfaceType.Loopback ||
                        adapter.NetworkInterfaceType == NetworkInterfaceType.Tunnel)
                        continue;

                    var mac = FormatMac(adapter.GetPhysicalAddress().ToString());
                    if (string.IsNullOrEmpty(mac) || mac == "00:00:00:00:00:00")
                        continue;

                    var name = adapter.Description.ToLower();
                    bool isActive = adapter.OperationalStatus == OperationalStatus.Up &&
                                   HasValidIP(adapter);

                    // Detect INTEGRATED LAN (motherboard/laptop ethernet port)
                    if (IsIntegratedLAN(name, adapter.NetworkInterfaceType))
                    {
                        lanMac = mac;
                        Console.WriteLine($"✓ Found Integrated LAN: {mac} ({adapter.Description})");
                    }

                    // Detect ACTIVE connection
                    if (isActive && string.IsNullOrEmpty(activeMac))
                    {
                        activeMac = mac;
                        connectionType = GetConnectionType(name, adapter.NetworkInterfaceType);
                        
                        // Get IP address
                        var ipProps = adapter.GetIPProperties();
                        var ipAddress = ipProps.UnicastAddresses
                            .FirstOrDefault(ip => ip.Address.AddressFamily == 
                                System.Net.Sockets.AddressFamily.InterNetwork);
                        
                        if (ipAddress != null)
                            info.IpAddress = ipAddress.Address.ToString();

                        Console.WriteLine($"✓ Active Connection: {mac} ({connectionType}) - {adapter.Description}");
                    }
                }

                // Assign results
                info.LanMacAddress = lanMac;
                info.ActiveMacAddress = activeMac;
                info.ConnectionType = connectionType;

                // Validation
                if (string.IsNullOrEmpty(lanMac))
                {
                    Console.WriteLine("⚠ Warning: Could not detect integrated LAN MAC!");
                    // Fallback: Use active MAC as LAN MAC
                    info.LanMacAddress = activeMac;
                }

                Console.WriteLine("=================================");
                Console.WriteLine($"LAN MAC (Permanent ID): {info.LanMacAddress}");
                Console.WriteLine($"Active MAC: {info.ActiveMacAddress}");
                Console.WriteLine($"Connection Type: {info.ConnectionType}");
                Console.WriteLine($"IP Address: {info.IpAddress}");
                Console.WriteLine("=================================");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error detecting network: {ex.Message}");
            }

            return info;
        }

        private static bool IsIntegratedLAN(string name, NetworkInterfaceType type)
        {
            // Integrated LAN identifiers
            if (type == NetworkInterfaceType.Ethernet ||
                type == NetworkInterfaceType.Ethernet3Megabit ||
                type == NetworkInterfaceType.FastEthernetT ||
                type == NetworkInterfaceType.GigabitEthernet)
            {
                // Integrated chipsets (common in motherboards)
                if (name.Contains("realtek") ||
                    name.Contains("intel") && !name.Contains("wifi") ||
                    name.Contains("marvell") ||
                    name.Contains("broadcom") && !name.Contains("wireless") ||
                    name.Contains("atheros") && !name.Contains("wireless") ||
                    name.Contains("killer") && !name.Contains("wireless"))
                {
                    // Exclude USB ethernet adapters
                    if (!name.Contains("usb"))
                        return true;
                }

                // Generic ethernet without brand (likely integrated)
                if (name.Contains("ethernet") && 
                    !name.Contains("usb") && 
                    !name.Contains("wireless"))
                    return true;
            }

            return false;
        }

        private static string GetConnectionType(string name, NetworkInterfaceType type)
        {
            // WiFi Dongle (USB wireless)
            if (name.Contains("usb") && 
                (name.Contains("wireless") || name.Contains("wifi") || name.Contains("802.11")))
                return "DONGLE";

            // Built-in WiFi (laptop)
            if (type == NetworkInterfaceType.Wireless80211 ||
                name.Contains("wifi") || name.Contains("wireless") || name.Contains("802.11"))
                return "WIFI";

            // LAN
            if (type == NetworkInterfaceType.Ethernet ||
                type == NetworkInterfaceType.GigabitEthernet)
                return "LAN";

            return "OTHER";
        }

        private static bool HasValidIP(NetworkInterface adapter)
        {
            try
            {
                var ipProps = adapter.GetIPProperties();
                return ipProps.UnicastAddresses.Any(ip => 
                    ip.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork &&
                    !ip.Address.ToString().StartsWith("169.254")); // Exclude APIPA
            }
            catch
            {
                return false;
            }
        }

        private static string FormatMac(string mac)
        {
            if (mac.Length == 12)
            {
                return string.Join(":", Enumerable.Range(0, 6)
                    .Select(i => mac.Substring(i * 2, 2)));
            }
            return mac;
        }
    }
}
