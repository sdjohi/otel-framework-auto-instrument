using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.Owin;

namespace OtelSqlDemo
{
    public class TracingMiddleware : OwinMiddleware
    {
        private static readonly ActivitySource Source = new ActivitySource("OtelSqlDemo.Http");

        public TracingMiddleware(OwinMiddleware next) : base(next) { }

        public override async Task Invoke(IOwinContext context)
        {
            var request = context.Request;
            var activityName = $"{request.Method} {request.Path}";

            using (var activity = Source.StartActivity(activityName, ActivityKind.Server))
            {
                if (activity != null)
                {
                    activity.SetTag("http.request.method", request.Method);
                    activity.SetTag("url.path", request.Path.ToString());
                    activity.SetTag("url.scheme", request.Scheme);
                    activity.SetTag("server.address", request.Host.Value);
                }

                try
                {
                    await Next.Invoke(context);
                }
                catch (Exception ex)
                {
                    activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                    throw;
                }

                if (activity != null)
                {
                    activity.SetTag("http.response.status_code", context.Response.StatusCode);
                    if (context.Response.StatusCode >= 400)
                        activity.SetStatus(ActivityStatusCode.Error);
                }
            }
        }
    }
}
