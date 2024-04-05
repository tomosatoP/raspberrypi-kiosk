require 'open-uri'
require 'json'


# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '5m', :first_in => 0 do |job|

  amedastable = JSON.load(URI.open(URL_AMEDASTABLE))
  closest_amedas = amedastable.select{ |code, content| content["kjName"] == CLOSEST_AMEDAS_KJNAME}
  latest_time = Time.iso8601(URI.open(URL_LATEST_TIME).read)

  # 最新のAMeDAS観測結果
  url_map_latest = "https://www.jma.go.jp/bosai/amedas/data/map/" + latest_time.strftime("%Y%m%d%H%M%S") + ".json"
  amedastable_latest = JSON.load(URI.open(url_map_latest))

  # 指定のAMeDAS観測地点のみ抽出し、異常値を削除
  closest_amedas_latest = amedastable_latest[closest_amedas.keys[0]].select{|key, array| array[1] == 0}
  closest_amedas_latest = closest_amedas_latest.each{|key, array| array.pop}

  if closest_amedas_latest.key?("windDirection")
    closest_amedas_latest["windDirection"] = [WIND_DIRECTION_CODES[closest_amedas_latest["windDirection"][0]]]
  else
    closest_amedas_latest["windDirection"] = "--"
  end
  closest_amedas_latest["temp"] = "--" if closest_amedas_latest.key?("temp") == false
  closest_amedas_latest["precipitation10m"] = "--" if closest_amedas_latest.key?("precipitation10m") == false
  closest_amedas_latest["wind"] = "--" if closest_amedas_latest.key?("wind") == false

  closest_amedas_latest["kjname"] = [CLOSEST_AMEDAS_KJNAME]
  closest_amedas_latest["time"] = [latest_time.strftime("%H:%M")]

  send_event('amedas', { items: closest_amedas_latest }) unless closest_amedas_latest.empty?
end
