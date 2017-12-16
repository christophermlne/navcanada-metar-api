use Mix.Config

config :metar_service, :metar_data_adapter, MetarService.Adapters.Test
config :metar_service, :taf_data_adapter,   MetarService.Adapters.Test
