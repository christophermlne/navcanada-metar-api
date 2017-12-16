defmodule MetarServiceTest do
  require Logger
  use ExUnit.Case, async: false
  doctest MetarService

  setup_all do
    startup = Task.async(fn ->
      metar_service = Task.async(fn ->
        :ok = Application.ensure_started(:metar_service)
      end)

      Logger.info("Initializing data for Acceptance tests (may take up to 8 seconds )...")
      Task.await(metar_service)
      :timer.sleep(:timer.seconds(8))
      {:ok, %{}}
    end)

    on_exit(fn ->
      Application.stop(:metar_service)
    end)

    Task.await(startup, 10000)
    Logger.info("Done initializing data")
  end

  test "it returns an error for a non-sensical input" do
    assert MetarService.get("Not a station id") == {:error, "Not a valid station id."}
  end

  test "it returns an error for a valid station without data" do
    assert MetarService.get("CYYZ") == {:error, "Report not available."}
  end

  test "it returns the metar for the requested reporting station" do
    {:ok,
      %{metar: %MetarService.Station{station: "CYVR", elevation_m: '2.0', flight_category: 'VFR',
       latest_observation_time: '2017-11-16T12:53:00Z', latitude: '49.17',
       longitude: '-123.17',
       reports: %{
         current:  current,
         history: history
       },
       sea_level_pressure_mb: '999.5'
     },
       nearby_stations: nearby_stations,
       retrieved_at: _,
       taf: "TAF CYVR 231739Z 2318/2424 10005KT P6SM FEW030 SCT050 BKN080 TEMPO 2318/2408 P6SM -SHRA SCT030 BKN050 OVC080 BECMG 2319/2321 16012KT FM240800 20010KT P6SM -SHRA FEW020 BKN050 OVC150 FM241600 18010KT P6SM -RA SCT015 BKN030 OVC050 TEMPO 2416/2424 5SM -SHRA BR FEW008 BKN015 OVC030 BECMG 2417/2419 13012KT RMK NXT FCST BY 232100Z"}
    } = MetarService.get("CYVR")

    assert nearby_stations == ["CYVR", "CYYY", "CYDF", "CYQX", "CYGP", "CYJT"]
    assert current == 'CYVR 161253Z VRB02KT 20SM FEW022 SCT063 BKN120 06/03 A2951 RMK SC2SC1AC4 SLP995'
    assert history == ['CYVR 161216Z 24010KT 180V240 15SM -RA BKN023 OVC039 06/04 A2951 RMK SC6SC2 WSHFT 1207 SLP995',
                   'CYVR 161213Z 24011KT 180V240 15SM -RA BKN027 OVC044 07/04 A2951 RMK SC6SC2 SLP995',
                   'CYVR 161200Z 22004KT 170V230 20SM FEW028 BKN054 OVC079 07/06 A2951 RMK SC2SC5AC1 SLP995',
                   'CYVR 161100Z 13007KT 20SM FEW032 BKN065 BKN078 06/05 A2949 RMK SC1SC5AC1 SLP989',
                   'CYVR 161000Z 13006KT 20SM FEW039 FEW051 BKN066 OVC094 06/06 A2948 RMK SC1SC1AC5AC1 SLP984',
                   'CYVR 160938Z 12005KT 20SM FEW027 SCT041 OVC056 07/06 A2948 RMK SC1SC2SC5 SLP984',
                   'CYVR 160900Z 15005KT 15SM -RA FEW016 BKN031 OVC055 07/06 A2948 RMK SC2SC5SC1 SLP985']
  end
end
