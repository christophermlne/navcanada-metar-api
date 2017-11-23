use Mix.Config

config :metar_service, :metar_data_adapter, MetarService.Adapters.Dev
config :metar_service, :taf_data_adapter,   MetarService.Adapters.Dev
