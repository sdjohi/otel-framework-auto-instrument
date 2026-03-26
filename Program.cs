using System;
using Microsoft.Owin.Hosting;
using NLog;

namespace OtelSqlDemo
{
    class Program
    {
        static void Main(string[] args)
        {
            var log = LogManager.GetCurrentClassLogger();

            const string baseUrl = "http://localhost:9000";

            log.Info("Initializing database...");
            DatabaseInitializer.EnsureDatabase();
            log.Info("Database ready.");

            using (WebApp.Start<Startup>(baseUrl))
            {
                log.Info("OtelSqlDemo Web API running at {BaseUrl}", baseUrl);
                Console.WriteLine($"OtelSqlDemo Web API running at {baseUrl}");
                Console.WriteLine("Endpoints:");
                Console.WriteLine("  GET    /api/products");
                Console.WriteLine("  GET    /api/products/{id}");
                Console.WriteLine("  POST   /api/products  (JSON body: {\"Name\":\"...\",\"Price\":12.99})");
                Console.WriteLine();
                Console.WriteLine("Press Enter to stop...");
                Console.ReadLine();
            }

            LogManager.Shutdown();
        }
    }
}
