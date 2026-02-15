using System.Management;
using System.Net.NetworkInformation;

namespace RentComProAgent.Services
{
    public class NetworkInfoService
    {
        public class MacAddressInfo
        {
            public string PrimaryMac { get; set; } = "";
            public string SecondaryMac { get; set; } = "";
            public List<string> AllMacs { get; set; } = new List<string>();
            public string ActiveAdapterName { get; set; } = "";
        }

        public static MacAddressInfo GetMacAddresses()
        {
            var info = new MacAddressInfo();
            var macList = new List<(string mac, string name, bool isActive)>();

            try
            {
                // Get all network adapters
                var adapters = NetworkInterface.GetAllNetworkInterfaces();
                
                foreach (var adapter in adapters)
                {
                    // Skip loopback and tunnel adapters
                    if (adapter.NetworkInterfaceType == NetworkInterfaceType.Loopback ||
                        adapter.NetworkInterfaceType == NetworkInterfaceType.Tunnel)
                        continue;

                    var mac = adapter.GetPhysicalAddress().ToString();
                    
                    // Skip empty MAC
                    if (string.IsNullOrEmpty(mac) || mac == "000000000000")
                        continue;

                    // Format MAC address (add colons)
                    mac = FormatMacAddress(mac);
                    
                    // Check if adapter is active (has IP and is up)
                    bool isActive = adapter.OperationalStatus == OperationalStatus.Up &&
                                   adapter.GetIPProperties().UnicastAddresses.Any(ip => 
                                       ip.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork);

                    macList.Add((mac, adapter.Description, isActive));
                    info.AllMacs.Add(mac);
                }

                // Sort: Active adapters first, then by preference
                var sortedMacs = macList.OrderByDescending(m => m.isActive)
                                       .ThenBy(m => GetAdapterPriority(m.name))
                                       .ToList();

                if (sortedMacs.Count > 0)
                {
                    // Primary MAC: First active adapter (WiFi dongle or LAN)
                    info.PrimaryMac = sortedMacs[0].mac;
                    info.ActiveAdapterName = sortedMacs[0].name;
                }

                if (sortedMacs.Count > 1)
                {
                    // Secondary MAC: Second adapter (usually integrated LAN as backup)
                    info.SecondaryMac = sortedMacs[1].mac;
                }

                Console.WriteLine($"Detected MACs:");
                Console.WriteLine($"Primary (Active): {info.PrimaryMac} - {info.ActiveAdapterName}");
                Console.WriteLine($"Secondary (Backup): {info.SecondaryMac}");
                Console.WriteLine($"Total MACs: {info.AllMacs.Count}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error detecting MAC addresses: {ex.Message}");
            }

            return info;
        }

        private static string FormatMacAddress(string mac)
        {
            // Convert 001B638445E6 to 00:1B:63:84:45:E6
            if (mac.Length == 12)
            {
                return string.Join(":", Enumerable.Range(0, 6)
                    .Select(i => mac.Substring(i * 2, 2)));
            }
            return mac;
        }

        private static int GetAdapterPriority(string adapterName)
        {
            // Lower number = higher priority
            var name = adapterName.ToLower();

            // Prefer Ethernet/LAN over WiFi (for stability)
            if (name.Contains("ethernet") || name.Contains("realtek") || 
                name.Contains("intel") || name.Contains("lan"))
                return 1;

            // WiFi dongles (Quantum, etc.) - active but may change
            if (name.Contains("wifi") || name.Contains("wireless") || 
                name.Contains("802.11") || name.Contains("usb"))
                return 2;

            // Bluetooth and others - lowest priority
            return 3;
        }

        public static string GetActiveIpAddress()
        {
            try
            {
                var adapters = NetworkInterface.GetAllNetworkInterfaces()
                    .Where(a => a.OperationalStatus == OperationalStatus.Up &&
                               a.NetworkInterfaceType != NetworkInterfaceType.Loopback);

                foreach (var adapter in adapters)
                {
                    var ipProps = adapter.GetIPProperties();
                    var ipAddress = ipProps.UnicastAddresses
                        .FirstOrDefault(ip => ip.Address.AddressFamily == 
                            System.Net.Sockets.AddressFamily.InterNetwork);

                    if (ipAddress != null)
                        return ipAddress.Address.ToString();
                }
            }
            catch { }

            return "0.0.0.0";
        }
    }
}
