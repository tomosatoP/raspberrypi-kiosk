require 'yaml'

# SENSOR へのリクエスト方法
#  https://github.com/tomosatoP/raspberrypi-amedas

# "表示名": "http://<host-name or ip-address>/sensors/118"
SENSORS = YAML.load <<YAML_SENSORS_EOL
"居間": "http://192.168.68.11:8000/sensors/118"
"寝室": "http://192.168.68.12:8000/sensors/118"
YAML_SENSORS_EOL

# sensors からの response (body のみ) の形式
#   response:
#     sensor:
#       {"name" => "EXTERNAL BME280", "i2c_address" => 118}
#     list_dataset:
#       - {"name" => "TEMPERATURE", "date_time" => ***, "data" => ***}
#         {"name" => "HUMIDITY",    "date_time" => ***, "data" => ***}
#         {"name" => "PRESSURE",    "date_time" => ***, "data" => ***}
