# 表示をカスタマイズする際の参考

## 表示色
表示色を目に優しい "暗め" の設定としている

[smashing/widgets/amedas/amedas.scss](smashing/widgets/amedas/amedas.scss)<br>
[smashing/widgets/forecast/forecast.scss](smashing/widgets/forecast/forecast.scss)<br>
[smashing/widgets/tokei/tokei.scss](smashing/widgets/tokei/tokei.scss)<br>
[smashing/widgets/sensor/sensor.scss](smashing/widgets/sensor/sensor.scss)

|項目|RGB|
|---|---|
|color|rbga(255, 255, 255, 0.3)|
|background-color|black|

## AMeDAS

[smashig/lib/amedas.rb](smashing/lib/amedas.rb)
~~~text
CLOSEST_AMEDAS_KJNAME = "表示させたい地域のAMeDAS"
~~~

## FORECAST

[smashing/lib/forecast.rb](smashing/lib/forecast.rb)
~~~text
FORECAST_CLASS20_NAME = "表示させたい市町村名"
~~~

## SENSOR
参照のこと https://github.com/tomosatoP/raspberrypi-amedas

[smashing/lib/sensor.rb](smashing/lib/sensor.rb)
~~~text
SENSORS = YAML.load <<YAML_SENSORS_EOL
"表示名": "http://<host-name or ip-address>/sensors/118"
...
YAML_SENSORS_EOL
~~~