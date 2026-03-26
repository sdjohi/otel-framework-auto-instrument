using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web.Http;
using NLog;

namespace OtelSqlDemo.Controllers
{
    public class ProductsController : ApiController
    {
        private static readonly Logger Log = LogManager.GetLogger("OtelSqlDemo.Controllers.ProductsController");

        // GET api/products
        public IHttpActionResult Get()
        {
            Log.Info("Getting all products");
            var products = new List<object>();

            using (var conn = new SqlConnection(DatabaseInitializer.ConnectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT Id, Name, Price, CreatedAt FROM Products ORDER BY Id";

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            products.Add(new
                            {
                                Id = reader.GetInt32(0),
                                Name = reader.GetString(1),
                                Price = reader.GetDecimal(2),
                                CreatedAt = reader.GetDateTime(3)
                            });
                        }
                    }
                }
            }

            return Ok(products);
        }

        // GET api/products/5
        public IHttpActionResult Get(int id)
        {
            Log.Info("Getting product by Id={ProductId}", id);
            using (var conn = new SqlConnection(DatabaseInitializer.ConnectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT Id, Name, Price, CreatedAt FROM Products WHERE Id = @Id";
                    cmd.Parameters.AddWithValue("@Id", id);

                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return Ok(new
                            {
                                Id = reader.GetInt32(0),
                                Name = reader.GetString(1),
                                Price = reader.GetDecimal(2),
                                CreatedAt = reader.GetDateTime(3)
                            });
                        }
                    }
                }
            }

            return NotFound();
        }

        // POST api/products
        public IHttpActionResult Post([FromBody] ProductCreateRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Name))
            {
                Log.Warn("Bad request: Name is required");
                return BadRequest("Name is required.");
            }

            Log.Info("Creating product Name={ProductName}, Price={Price}", request.Name, request.Price);

            int newId;

            using (var conn = new SqlConnection(DatabaseInitializer.ConnectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        INSERT INTO Products (Name, Price) 
                        VALUES (@Name, @Price);
                        SELECT CAST(SCOPE_IDENTITY() AS INT);";
                    cmd.Parameters.AddWithValue("@Name", request.Name);
                    cmd.Parameters.AddWithValue("@Price", request.Price);

                    newId = (int)cmd.ExecuteScalar();
                }
            }

            return Ok(new { Id = newId, request.Name, request.Price });
        }
    }

    public class ProductCreateRequest
    {
        public string Name { get; set; }
        public decimal Price { get; set; }
    }
}
