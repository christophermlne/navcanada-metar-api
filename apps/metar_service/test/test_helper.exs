# start all application dependencies, but don't start the application itself
Application.load(:metar_service)
for app <- Application.spec(:metar_service, :applications) do
  Application.ensure_all_started(app)
end
ExUnit.start()
