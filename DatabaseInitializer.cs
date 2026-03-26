using System;
using System.Data.SqlClient;

namespace OtelSqlDemo
{
    public static class DatabaseInitializer
    {
        public const string ConnectionString =
            @"Data Source=(LocalDB)\MSSQLLocalDB;Initial Catalog=OtelSqlDemo;Integrated Security=True";

        private const string MasterConnectionString =
            @"Data Source=(LocalDB)\MSSQLLocalDB;Initial Catalog=master;Integrated Security=True";

        public static void EnsureDatabase()
        {
            // Create the database if it doesn't exist
            using (var conn = new SqlConnection(MasterConnectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'OtelSqlDemo')
                        BEGIN
                            CREATE DATABASE OtelSqlDemo
                        END";
                    cmd.ExecuteNonQuery();
                }
            }

            // Create table and seed data
            using (var conn = new SqlConnection(ConnectionString))
            {
                conn.Open();

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
                        BEGIN
                            CREATE TABLE Products (
                                Id INT IDENTITY(1,1) PRIMARY KEY,
                                Name NVARCHAR(200) NOT NULL,
                                Price DECIMAL(18,2) NOT NULL,
                                CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
                            )
                        END";
                    cmd.ExecuteNonQuery();
                }

                // Seed sample data if empty
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT COUNT(*) FROM Products";
                    var count = (int)cmd.ExecuteScalar();

                    if (count == 0)
                    {
                        Console.WriteLine("Seeding sample products...");
                        SeedProducts(conn);
                    }
                }
            }
        }

        private static void SeedProducts(SqlConnection conn)
        {
            var products = new[]
            {
                ("Wireless Mouse", 29.99m),
                ("Mechanical Keyboard", 89.99m),
                ("USB-C Hub", 45.50m),
                ("Monitor Stand", 34.99m),
                ("Webcam HD", 59.99m)
            };

            foreach (var (name, price) in products)
            {
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "INSERT INTO Products (Name, Price) VALUES (@Name, @Price)";
                    cmd.Parameters.AddWithValue("@Name", name);
                    cmd.Parameters.AddWithValue("@Price", price);
                    cmd.ExecuteNonQuery();
                }
            }

            Console.WriteLine($"Seeded {products.Length} products.");
        }
    }
}
