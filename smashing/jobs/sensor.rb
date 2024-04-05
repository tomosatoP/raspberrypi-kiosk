require 'net/http'
require 'uri'
require 'json'

NUM_SENSORS = SENSORS.length
index = -1
datasets = Hash.new([])

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '20s', :first_in => 0 do |job|

  index = (index + 1) % NUM_SENSORS
  sensor_info = [SENSORS.keys[index], SENSORS.values[index]]

  begin
    response = Net::HTTP.get_response(URI.parse(sensor_info[1]))

    JSON.parse(response.body)["list_dataset"].each do |dataset|
      case dataset["name"]
      when "TEMPERATURE"
        datasets["time"] = Time.iso8601(dataset["date_time"]).strftime(sensor_info[0] + " %H:%M 現在")
        datasets["temp"] = dataset["data"].to_f.round(1)
      when "HUMIDITY"
        datasets["humi"] = dataset["data"].to_f.round()
      when "PRESSURE"
        datasets["pres"] = dataset["data"].to_f.round()
      end
    end

  rescue => e
    datasets = {"time":e.class, "temp":"--", "humi":"--", "pres":"--"}
  end

  send_event('sensor', { items: datasets }) unless datasets.empty?
end
