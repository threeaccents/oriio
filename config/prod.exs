import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
http_host = System.get_env("ORIIO_HOST") || "localhost"
http_port = String.to_integer(System.get_env("ORIIO_PORT") || "4200")

config :oriio_web, OriioWeb.Endpoint,
  url: [host: http_host, port: http_port],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :oriio_web,
       :auth_secret_key,
       System.get_env("ORIIO_AUTH_TOKEN") || raise("auth token is required")

config :oriio,
       :signed_upload_secret_key,
       System.get_env("ORIIO_SIGNED_UPLOAD_SECRET_KEY") ||
         raise("signed upload secret key is required")

config :oriio, :file_storage, storage_engine: "local"

config :oriio, :base_url, System.get_env("ORIIO_BASE_URL") || raise("oriio base url is required")

# ## SSL Support
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :oriio_web, OriioWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# Do not print debug messages in production
config :logger, level: :info
