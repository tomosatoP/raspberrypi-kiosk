require 'open-uri'
require 'json'

# 指定地域　FORECAST_CLASS20_NAME を含む office, class10 のコード、名前を遡及
forecast_areas = JSON.load(URI.open(URL_FORECAST_AREAS))
forecast_class20 = forecast_areas["class20s"].select {|key, value| value["name"] == FORECAST_CLASS20_NAME}
FORECAST_CLASS20_CODE = forecast_class20.keys[0]
FORECAST_CLASS15_CODE = forecast_areas["class20s"][FORECAST_CLASS20_CODE]["parent"]
FORECAST_CLASS10_CODE = forecast_areas["class15s"][FORECAST_CLASS15_CODE]["parent"]
FORECAST_CLASS10_NAME = forecast_areas["class10s"][FORECAST_CLASS10_CODE]["name"]
FORECAST_OFFICE_CODE = forecast_areas["class10s"][FORECAST_CLASS10_CODE]["parent"]
FORECAST_OFFICE_NAME = forecast_areas["offices"][FORECAST_OFFICE_CODE]["name"]
FORECAST_CENTER_CODE = forecast_areas["offices"][FORECAST_OFFICE_CODE]["parent"]


forecast_tables = Hash.new([])

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '20m', :first_in => 0 do |job|

  # 現在時 : "明後日までの詳細" の日付文字列の判定用
  current_hour = Time.now.localtime.hour

  # 指定地域を含む府県週間天気予報
  url_forecast_office = "https://www.jma.go.jp/bosai/forecast/data/forecast/" + FORECAST_OFFICE_CODE + ".json"
  forecast_office = JSON.load(URI.open(url_forecast_office))

  ## index_term = 0 : 明後日までの詳細 （[05, 11, 17]時に発報）
  ## index_term = 1 : 7日先まで （[11, 17]時に発報）
  list_term = Array.new(2){Hash.new([])}
  list_term[0] = convert_forecast_3days(current_hour, forecast_office[0])
  list_term[1] = convert_forecast_7days(current_hour, forecast_office[1])

  # 表示用テーブルに変換
  num_drops = (5...11).cover?(current_hour) ? 2 : 1

  forecast_tables["reportHour"] =  list_term.dig(0, "hour")
  forecast_tables["area"] = [list_term.dig(0, "area_name"), list_term.dig(1, "area_name")]
  forecast_tables["spot"] = [list_term.dig(0, "spot_name"), list_term.dig(1, "spot_name")]

  forecast_tables["dates"] = list_term[0]["dates"] + list_term[1]["dates"].drop(2)
  forecast_tables["weathers"] = list_term[0]["weathers"] + list_term[1]["weathers"].drop(2)

  forecast_tables["pops"] = list_term[0]["pops"] + list_term[1]["pops"].drop(num_drops)
  forecast_tables["rels"] = Array.new(2){""} + list_term[1]["reliabilities"].drop(num_drops)

  forecast_tables["tempsMax"] = list_term[0]["tempsMax"] + list_term[1]["tempsMax"].drop(num_drops)
  forecast_tables["tempsMin"] = list_term[0]["tempsMin"] + list_term[1]["tempsMin"].drop(num_drops)

  send_event('forecast', { items: forecast_tables}) unless forecast_tables.empty?
end


# 指定地域を含む areas 配列の index
def index_areas(areas)
  case areas.length
  when 1 # area は、OFFICE (府県)
    result = 0
  else # area は、CLASS10 (一次細分区分)
    areas.each_with_index do |item_area, index_area|
      result = index_area if item_area.dig("area", "code") == FORECAST_CLASS10_CODE
    end
  end

  result
end

# 明後日までの詳細
def convert_forecast_3days(current_hour, jma_3days)
  forecast_3days = Hash.new([])
  areas_index = index_areas(jma_3days.dig("timeSeries", 0, "areas"))

  # 発報時刻
  forecast_3days["hour"] = Time.iso8601(jma_3days["reportDatetime"]).hour

  # 日付
  case current_hour
  when 0 .. 4
    forecast_3days["dates"] = ["昨夜","今日","明日"]
  when 5 .. 10
    forecast_3days["dates"] = ["今日","明日"]
  when 11 .. 16
    forecast_3days["dates"] = ["今日","明日","明後日"]
  when 17 .. 23
    forecast_3days["dates"] = ["今夜","明日","明後日"]
  end

  # 予報
  jma_3days["timeSeries"].each do |item_timeDefine|

    time_define = item_timeDefine["timeDefines"]
    item_area = item_timeDefine.dig("areas", areas_index)

    if item_area.key?("weatherCodes")
      # 地域
      forecast_3days["area_name"] = item_area.dig("area", "name")
      forecast_3days["area_code"] = item_area.dig("area", "name")

      # 天気を抽出
      # 予報値の時系列
      #  05時発報　[今日/明日]
      #  11時発報　[今日/明日/明後日]
      #  17時発報　[今夜/明日/明後日] (日が替わると [昨夜/今日/明日])
      forecast_3days["weathers"] = item_area.dig("weatherCodes").map { |code| FORECAST_CONST_TELOPS[code.to_i][0]}
      if current_hour < 5 or current_hour >= 17 # 夜間の対応
        forecast_3days["weathers"][0] = FORECAST_CONST_TELOPS[item_area.dig("weatherCodes", 0).to_i][1]
      end
    end

    if item_area.key?("pops")
      # 降水確率を抽出
      # 予報値の時系列
      #  05時発報　[06/12/18, 00/06/12/18]
      #  11時発報　   [12/18, 00/06/12/18]
      #  17時発報      　[18, 00/06/12/18]
      buffer = ["--"] * (8 - item_area["pops"].length) + item_area["pops"]
      forecast_3days["pops"] = buffer.each_slice(4).map {|item| item.join("/")}
    end

    if item_area.key?("temps")
      # 地点
      forecast_3days["spot_name"] = item_area.dig("area", "name")
      forecast_3days["spot_code"] = item_area.dig("area", "code")
      # 気温を抽出
      # 予報値の時系列
      #  05時発報 [日中の最高, 朝の最低, 朝の最低, 日中の最高]
      #  11時発報 [日中の最高, 朝の最低, 朝の最低, 日中の最高]
      #  17時発報                     [朝の最低, 日中の最高]
      buffer = ["--"] * (4 - item_area["temps"].length) + item_area["temps"]
      forecast_3days["tempsMax"] = buffer[0...1] + buffer[3...4]
      forecast_3days["tempsMin"] = buffer[1...2] + buffer[2...3]
    end
  end

  forecast_3days
end

# 7日先まで
def convert_forecast_7days(current_hour, jma_7days)
  forecast_7days = Hash.new([])
  areas_index = index_areas(jma_7days.dig("timeSeries", 0, "areas"))

  # 発報時刻
  forecast_7days["hour"] = Time.iso8601(jma_7days["reportDatetime"]).hour

  # 日付
  forecast_7days["dates"] = jma_7days.dig("timeSeries", 0 ,"timeDefines").map { |value| Time.iso8601(value).strftime("%2d日") }

  # 予報
  jma_7days["timeSeries"].each do |item_timeDefine|
    time_define = item_timeDefine["timeDefines"]
    item_area = item_timeDefine.dig("areas", areas_index)

    if item_area.key?("weatherCodes")
      # 地域
      forecast_7days["area_name"] = item_area.dig("area", "name")
      forecast_7days["area_code"] = item_area.dig("area", "code")
      # 天気を抽出
      forecast_7days["weathers"] = item_area["weatherCodes"].map { |code| FORECAST_CONST_TELOPS[code.to_i][0]}
      # 降水確率を抽出
      forecast_7days["pops"] = item_area["pops"] if item_area.key?("pops")
      # 降水確率の信頼度を抽出
      forecast_7days["reliabilities"] = item_area["reliabilities"] if item_area.key?("reliabilities")
    end

    if item_area.key?("tempsMin")
      # 地点
      forecast_7days["spot_name"] = item_area.dig("area", "name")
      forecast_7days["spot_code"] = item_area.dig("area", "code")
      # 最高気温を抽出
      forecast_7days["tempsMin"] = item_area["tempsMin"] if item_area.key?("tempsMin")
      # 最低気温を抽出
      forecast_7days["tempsMax"] = item_area["tempsMax"] if item_area.key?("tempsMax")
    end
  end

  # 平年値
  average_temp = jma_7days["tempAverage"]
  average_precip = jma_7days["precipAverage"]

  forecast_7days
end
