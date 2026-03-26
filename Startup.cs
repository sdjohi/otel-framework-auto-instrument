using System.Web.Http;
using Owin;

namespace OtelSqlDemo
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            app.Use<TracingMiddleware>();

            var config = new HttpConfiguration();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            config.Formatters.Remove(config.Formatters.XmlFormatter);

            app.UseWebApi(config);
        }
    }
}
