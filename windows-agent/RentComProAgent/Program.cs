using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using RentComProAgent.Services;

namespace RentComProAgent
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .UseWindowsService(options =>
                {
                    options.ServiceName = "RentComPro Agent";
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Register configuration
                    services.Configure<AgentConfig>(hostContext.Configuration.GetSection("Agent"));
                    
                    // Register services
                    services.AddSingleton<HardwareMonitorService>();
                    services.AddSingleton<ApiCommunicationService>();
                    services.AddSingleton<LockService>();
                    
                    // Register background worker
                    services.AddHostedService<AgentWorker>();
                });
    }
}
