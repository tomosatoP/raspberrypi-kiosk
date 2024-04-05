require 'yaml'

# 天気予報の対象地域
URL_FORECAST_AREAS = "https://www.jma.go.jp/bosai/common/const/area.json"
# centers: {code: {name: "**地方", enName: "**", officeName: "**気象台", children: [...] }}
# offices: {code: {name: "都道府県名", enName: "**", officeName: "**気象台", parent: centers_code, children: [...]}}
# class10s: {code: {name: "**", enName: "** Region", parent: offcies_code, children: [...]}}
# class15s: {code: {name: "**", enName: "** Region", parent: class10s_code, children: [...]}}
# class20s: {code: {name: "**", enName: "** Region", parent: class15s_code}}
FORECAST_CLASS20_NAME = "千代田区"

# 明後日までの詳細
#   [05, 11, 17] 時に発報
#   timeDefines は、概況(天気、風向と風速、波とうねり)・降水確率・気温
#   area は一次細分区分 (class10) のおよび一次細分区分 (class10) に対応する AMeDAS 地点
# 7日先まで
#   [11, 17] 時に発報
#   timeDefines は、概況(天気、降水確率、降水確率の信頼度)・気温
#   area は府県 (office) および府県に対応する AMeDAS 地点
#   ただし、府県及び季節によっては、一次細分区部 (class10) のおよび一次細分区分 (class10) に対応する AMeDAS 地点
#   気温と降水量の平年値が付加されている
#
# office 単位の天気予報の構成を YAML形式で表示した場合
# - publishingOffice: officeName
#   reportDatetime: iso8601形式の日時で [05, 11, 17] 時に発報
#   timeSeries:
#     - timeDefines: [iso8601形式の日時,..]
#       areas:
#         - area: {name: class10-name, code: class10-code}
#           weatherCodes: {weathercode, ..}
#           ...
#     - timeDefines: [iso8601形式の日時,..]
#       areas:
#         - area: {name: class10-name, code: class10-code}
#           pops: {pops, ..}
#     - timeDefines: [iso8601形式の日時,..]
#       areas:
#         - area: {name: amedas-name, code: amedas-code}
#           temps: {temperature, ..}
# - publishingOffice: officeName
#   reportDatetime: iso8601形式の日時で [11, 17] 時に発報
#   timeSeries:
#     - timeDefines:   [iso8601形式の日時,..]
#       areas:
#        - area: {name: class10-name, code: class10-code}
#          weatherCodes: [weathercode, ..]
#          pops: [pops, ..]
#          reliabilities: [reliability, ..]
#     - timeDefines:   [iso8601形式の日時,..]
#       areas:
#        - area: {name: amedas-name , code: amedas-code}
#          tempsMin: [temperature, ..]
#          tempsMinUppser: [temperature, ..]
#          tempsMinLower: [temperature, ..]
#          tempsMax: [temperature, ..]
#          tempsMaxUppser: [temperature, ..]
#          tempsMaxLower: [temperature, ..]
#   tempAverage:
#     areas:
#      - area: {name: amedas-name, code: amedas-code}
#        min: temperature
#        max: temperature
#   precipAverage:
#     areas:
#      - area: {name: amedas-name, code: amedas-code}
#        min: precipitation
#        max: precipitation


### ここから
# 実行時に取得するのが難しい情報のなので、事前に登録します。

# Forecast.Const.TELOPS
# Code: [DaySvg, NightSvg, UndefCode, JpWeather, EnWeather]
FORECAST_CONST_TELOPS = YAML.load <<YAML_TELOPS_EOT
100: ["100.svg","500.svg","100","晴","CLEAR"]
101: ["101.svg","501.svg","100","晴時々曇","PARTLY CLOUDY"]
102: ["102.svg","502.svg","300","晴一時雨","CLEAR, OCCASIONAL SCATTERED SHOWERS"]
103: ["102.svg","502.svg","300","晴時々雨","CLEAR, FREQUENT SCATTERED SHOWERS"]
104: ["104.svg","504.svg","400","晴一時雪","CLEAR, SNOW FLURRIES"]
105: ["104.svg","504.svg","400","晴時々雪","CLEAR, FREQUENT SNOW FLURRIES"]
106: ["102.svg","502.svg","300","晴一時雨か雪","CLEAR, OCCASIONAL SCATTERED SHOWERS OR SNOW FLURRIES"]
107: ["102.svg","502.svg","300","晴時々雨か雪","CLEAR, FREQUENT SCATTERED SHOWERS OR SNOW FLURRIES"]
108: ["102.svg","502.svg","300","晴一時雨か雷雨","CLEAR, OCCASIONAL SCATTERED SHOWERS AND/OR THUNDER"]
110: ["110.svg","510.svg","100","晴後時々曇","CLEAR, PARTLY CLOUDY LATER"]
111: ["110.svg","510.svg","100","晴後曇","CLEAR, CLOUDY LATER"]
112: ["112.svg","512.svg","300","晴後一時雨","CLEAR, OCCASIONAL SCATTERED SHOWERS LATER"]
113: ["112.svg","512.svg","300","晴後時々雨","CLEAR, FREQUENT SCATTERED SHOWERS LATER"]
114: ["112.svg","512.svg","300","晴後雨","CLEAR,RAIN LATER"]
115: ["115.svg","515.svg","400","晴後一時雪","CLEAR, OCCASIONAL SNOW FLURRIES LATER"]
116: ["115.svg","515.svg","400","晴後時々雪","CLEAR, FREQUENT SNOW FLURRIES LATER"]
117: ["115.svg","515.svg","400","晴後雪","CLEAR,SNOW LATER"]
118: ["112.svg","512.svg","300","晴後雨か雪","CLEAR, RAIN OR SNOW LATER"]
119: ["112.svg","512.svg","300","晴後雨か雷雨","CLEAR, RAIN AND/OR THUNDER LATER"]
120: ["102.svg","502.svg","300","晴朝夕一時雨","OCCASIONAL SCATTERED SHOWERS IN THE MORNING AND EVENING, CLEAR DURING THE DAY"]
121: ["102.svg","502.svg","300","晴朝の内一時雨","OCCASIONAL SCATTERED SHOWERS IN THE MORNING, CLEAR DURING THE DAY"]
122: ["112.svg","512.svg","300","晴夕方一時雨","CLEAR, OCCASIONAL SCATTERED SHOWERS IN THE EVENING"]
123: ["100.svg","500.svg","100","晴山沿い雷雨","CLEAR IN THE PLAINS, RAIN AND THUNDER NEAR MOUTAINOUS AREAS"]
124: ["100.svg","500.svg","100","晴山沿い雪","CLEAR IN THE PLAINS, SNOW NEAR MOUTAINOUS AREAS"]
125: ["112.svg","512.svg","300","晴午後は雷雨","CLEAR, RAIN AND THUNDER IN THE AFTERNOON"]
126: ["112.svg","512.svg","300","晴昼頃から雨","CLEAR, RAIN IN THE AFTERNOON"]
127: ["112.svg","512.svg","300","晴夕方から雨","CLEAR, RAIN IN THE EVENING"]
128: ["112.svg","512.svg","300","晴夜は雨","CLEAR, RAIN IN THE NIGHT"]
130: ["100.svg","500.svg","100","朝の内霧後晴","FOG IN THE MORNING, CLEAR LATER"]
131: ["100.svg","500.svg","100","晴明け方霧","FOG AROUND DAWN, CLEAR LATER"]
132: ["101.svg","501.svg","100","晴朝夕曇","CLOUDY IN THE MORNING AND EVENING, CLEAR DURING THE DAY"]
140: ["102.svg","502.svg","300","晴時々雨で雷を伴う","CLEAR, FREQUENT SCATTERED SHOWERS AND THUNDER"]
160: ["104.svg","504.svg","400","晴一時雪か雨","CLEAR, SNOW FLURRIES OR OCCASIONAL SCATTERED SHOWERS"]
170: ["104.svg","504.svg","400","晴時々雪か雨","CLEAR, FREQUENT SNOW FLURRIES OR SCATTERED SHOWERS"]
181: ["115.svg","515.svg","400","晴後雪か雨","CLEAR, SNOW OR RAIN LATER"]
200: ["200.svg","200.svg","200","曇","CLOUDY"]
201: ["201.svg","601.svg","200","曇時々晴","MOSTLY CLOUDY"]
202: ["202.svg","202.svg","300","曇一時雨","CLOUDY, OCCASIONAL SCATTERED SHOWERS"]
203: ["202.svg","202.svg","300","曇時々雨","CLOUDY, FREQUENT SCATTERED SHOWERS"]
204: ["204.svg","204.svg","400","曇一時雪","CLOUDY, OCCASIONAL SNOW FLURRIES"]
205: ["204.svg","204.svg","400","曇時々雪","CLOUDY FREQUENT SNOW FLURRIES"]
206: ["202.svg","202.svg","300","曇一時雨か雪","CLOUDY, OCCASIONAL SCATTERED SHOWERS OR SNOW FLURRIES"]
207: ["202.svg","202.svg","300","曇時々雨か雪","CLOUDY, FREQUENT SCCATERED SHOWERS OR SNOW FLURRIES"]
208: ["202.svg","202.svg","300","曇一時雨か雷雨","CLOUDY, OCCASIONAL SCATTERED SHOWERS AND/OR THUNDER"]
209: ["200.svg","200.svg","200","霧","FOG"]
210: ["210.svg","610.svg","200","曇後時々晴","CLOUDY, PARTLY CLOUDY LATER"]
211: ["210.svg","610.svg","200","曇後晴","CLOUDY, CLEAR LATER"]
212: ["212.svg","212.svg","300","曇後一時雨","CLOUDY, OCCASIONAL SCATTERED SHOWERS LATER"]
213: ["212.svg","212.svg","300","曇後時々雨","CLOUDY, FREQUENT SCATTERED SHOWERS LATER"]
214: ["212.svg","212.svg","300","曇後雨","CLOUDY, RAIN LATER"]
215: ["215.svg","215.svg","400","曇後一時雪","CLOUDY, SNOW FLURRIES LATER"]
216: ["215.svg","215.svg","400","曇後時々雪","CLOUDY, FREQUENT SNOW FLURRIES LATER"]
217: ["215.svg","215.svg","400","曇後雪","CLOUDY, SNOW LATER"]
218: ["212.svg","212.svg","300","曇後雨か雪","CLOUDY, RAIN OR SNOW LATER"]
219: ["212.svg","212.svg","300","曇後雨か雷雨","CLOUDY, RAIN AND/OR THUNDER LATER"]
220: ["202.svg","202.svg","300","曇朝夕一時雨","OCCASIONAL SCCATERED SHOWERS IN THE MORNING AND EVENING, CLOUDY DURING THE DAY"]
221: ["202.svg","202.svg","300","曇朝の内一時雨","CLOUDY OCCASIONAL SCCATERED SHOWERS IN THE MORNING"]
222: ["212.svg","212.svg","300","曇夕方一時雨","CLOUDY, OCCASIONAL SCCATERED SHOWERS IN THE EVENING"]
223: ["201.svg","601.svg","200","曇日中時々晴","CLOUDY IN THE MORNING AND EVENING, PARTLY CLOUDY DURING THE DAY,"]
224: ["212.svg","212.svg","300","曇昼頃から雨","CLOUDY, RAIN IN THE AFTERNOON"]
225: ["212.svg","212.svg","300","曇夕方から雨","CLOUDY, RAIN IN THE EVENING"]
226: ["212.svg","212.svg","300","曇夜は雨","CLOUDY, RAIN IN THE NIGHT"]
228: ["215.svg","215.svg","400","曇昼頃から雪","CLOUDY, SNOW IN THE AFTERNOON"]
229: ["215.svg","215.svg","400","曇夕方から雪","CLOUDY, SNOW IN THE EVENING"]
230: ["215.svg","215.svg","400","曇夜は雪","CLOUDY, SNOW IN THE NIGHT"]
231: ["200.svg","200.svg","200","曇海上海岸は霧か霧雨","CLOUDY, FOG OR DRIZZLING ON THE SEA AND NEAR SEASHORE"]
240: ["202.svg","202.svg","300","曇時々雨で雷を伴う","CLOUDY, FREQUENT SCCATERED SHOWERS AND THUNDER"]
250: ["204.svg","204.svg","400","曇時々雪で雷を伴う","CLOUDY, FREQUENT SNOW AND THUNDER"]
260: ["204.svg","204.svg","400","曇一時雪か雨","CLOUDY, SNOW FLURRIES OR OCCASIONAL SCATTERED SHOWERS"]
270: ["204.svg","204.svg","400","曇時々雪か雨","CLOUDY, FREQUENT SNOW FLURRIES OR SCATTERED SHOWERS"]
281: ["215.svg","215.svg","400","曇後雪か雨","CLOUDY, SNOW OR RAIN LATER"]
300: ["300.svg","300.svg","300","雨","RAIN"]
301: ["301.svg","701.svg","300","雨時々晴","RAIN, PARTLY CLOUDY"]
302: ["302.svg","302.svg","300","雨時々止む","SHOWERS THROUGHOUT THE DAY"]
303: ["303.svg","303.svg","400","雨時々雪","RAIN,FREQUENT SNOW FLURRIES"]
304: ["300.svg","300.svg","300","雨か雪","RAINORSNOW"]
306: ["300.svg","300.svg","300","大雨","HEAVYRAIN"]
308: ["308.svg","308.svg","300","雨で暴風を伴う","RAINSTORM"]
309: ["303.svg","303.svg","400","雨一時雪","RAIN,OCCASIONAL SNOW"]
311: ["311.svg","711.svg","300","雨後晴","RAIN,CLEAR LATER"]
313: ["313.svg","313.svg","300","雨後曇","RAIN,CLOUDY LATER"]
314: ["314.svg","314.svg","400","雨後時々雪","RAIN, FREQUENT SNOW FLURRIES LATER"]
315: ["314.svg","314.svg","400","雨後雪","RAIN,SNOW LATER"]
316: ["311.svg","711.svg","300","雨か雪後晴","RAIN OR SNOW, CLEAR LATER"]
317: ["313.svg","313.svg","300","雨か雪後曇","RAIN OR SNOW, CLOUDY LATER"]
320: ["311.svg","711.svg","300","朝の内雨後晴","RAIN IN THE MORNING, CLEAR LATER"]
321: ["313.svg","313.svg","300","朝の内雨後曇","RAIN IN THE MORNING, CLOUDY LATER"]
322: ["303.svg","303.svg","400","雨朝晩一時雪","OCCASIONAL SNOW IN THE MORNING AND EVENING, RAIN DURING THE DAY"]
323: ["311.svg","711.svg","300","雨昼頃から晴","RAIN, CLEAR IN THE AFTERNOON"]
324: ["311.svg","711.svg","300","雨夕方から晴","RAIN, CLEAR IN THE EVENING"]
325: ["311.svg","711.svg","300","雨夜は晴","RAIN, CLEAR IN THE NIGHT"]
326: ["314.svg","314.svg","400","雨夕方から雪","RAIN, SNOW IN THE EVENING"]
327: ["314.svg","314.svg","400","雨夜は雪","RAIN,SNOW IN THE NIGHT"]
328: ["300.svg","300.svg","300","雨一時強く降る","RAIN, EXPECT OCCASIONAL HEAVY RAINFALL"]
329: ["300.svg","300.svg","300","雨一時みぞれ","RAIN, OCCASIONAL SLEET"]
340: ["400.svg","400.svg","400","雪か雨","SNOWORRAIN"]
350: ["300.svg","300.svg","300","雨で雷を伴う","RAIN AND THUNDER"]
361: ["411.svg","811.svg","400","雪か雨後晴","SNOW OR RAIN, CLEAR LATER"]
371: ["413.svg","413.svg","400","雪か雨後曇","SNOW OR RAIN, CLOUDY LATER"]
400: ["400.svg","400.svg","400","雪","SNOW"]
401: ["401.svg","801.svg","400","雪時々晴","SNOW, FREQUENT CLEAR"]
402: ["402.svg","402.svg","400","雪時々止む","SNOWTHROUGHOUT THE DAY"]
403: ["403.svg","403.svg","400","雪時々雨","SNOW,FREQUENT SCCATERED SHOWERS"]
405: ["400.svg","400.svg","400","大雪","HEAVYSNOW"]
406: ["406.svg","406.svg","400","風雪強い","SNOWSTORM"]
407: ["406.svg","406.svg","400","暴風雪","HEAVYSNOWSTORM"]
409: ["403.svg","403.svg","400","雪一時雨","SNOW, OCCASIONAL SCCATERED SHOWERS"]
411: ["411.svg","811.svg","400","雪後晴","SNOW,CLEAR LATER"]
413: ["413.svg","413.svg","400","雪後曇","SNOW,CLOUDY LATER"]
414: ["414.svg","414.svg","400","雪後雨","SNOW,RAIN LATER"]
420: ["411.svg","811.svg","400","朝の内雪後晴","SNOW IN THE MORNING, CLEAR LATER"]
421: ["413.svg","413.svg","400","朝の内雪後曇","SNOW IN THE MORNING, CLOUDY LATER"]
422: ["414.svg","414.svg","400","雪昼頃から雨","SNOW, RAIN IN THE AFTERNOON"]
423: ["414.svg","414.svg","400","雪夕方から雨","SNOW, RAIN IN THE EVENING"]
425: ["400.svg","400.svg","400","雪一時強く降る","SNOW, EXPECT OCCASIONAL HEAVY SNOWFALL"]
426: ["400.svg","400.svg","400","雪後みぞれ","SNOW, SLEET LATER"]
427: ["400.svg","400.svg","400","雪一時みぞれ","SNOW, OCCASIONAL SLEET"]
450: ["400.svg","400.svg","400","雪で雷を伴う","SNOW AND THUNDER"]
YAML_TELOPS_EOT

# Forecast.Const.AREA_FUKEN
FORECAST_CONST_AREA_FUKEN = YAML.load <<YAML_AREA_FUKEN_EOT
{center: "016000", offices: ["016000","011000","013000","014030","014100","015000","012000","017000"]}
{center: "040000", offices: ["040000","060000","070000","020000","050000","030000"]}
{center: "130000", offices: ["130000","120000","140000","190000","090000","100000","110000","080000","200000"]}
{center: "150000", offices: ["150000","170000","180000","160000"]}
{center: "230000", offices: ["230000","240000","220000","210000"]}
{center: "270000", offices: ["270000","300000","260000","250000","280000","290000"]}
{center: "340000", offices: ["340000","310000","330000","320000"]}
{center: "370000", offices: ["370000","380000","360000","390000"]}
{center: "400000", offices: ["400000","440000","410000","430000","420000","350000"]}
{center: "460100", offices: ["460100","450000","460040"]}
{center: "471000", offices: ["471000","473000","474000","472000"]}
YAML_AREA_FUKEN_EOT

# Forecast.Const.WEEK_AREAS
FORECAST_CONST_WEEK_AREAS = YAML.load <<YAML_WEEK_AREAS_EOT
"011000": "Soya Region"
"012000": "Kamikawa Rumoi Region"
"013000": "Abashiri Kitami Mombetsu Region"
"014000": "Kushiro Nemuro Tokachi Region"
"014030": "Tokachi Region"
"014100": "Kushiro Nemuro Region"
"015000": "Iburi Hidaka Region"
"016000": "Ishikari Sorachi Shiribeshi Region"
"017000": "Oshima Hiyama Region"
"020000": "Aomori Prefecture"
"020010": "Tsugaru"
"020030": "Sanpachi Kamikita"
"020100": "Tsugaru Shimokita"
"020200": "Shimokita Sanpachi Kamikita"
"030000": "Iwate Prefecture"
"030010": "Inland"
"030100": "Coast"
"040000": "Miyagi Prefecture"
"040010": "Eastern Region"
"040020": "Western Region"
"050000": "Akita Prefecture"
"060000": "Yamagata Prefecture"
"070000": "Fukushima Prefecture"
"070030": "Aizu"
"070100": "Nakadori Hamadori"
"080000": "Ibaraki Prefecture"
"090000": "Tochigi Prefecture"
"100000": "Gunma Prefecture"
"100010": "Southern Region"
"100020": "Northern Region"
"110000": "Saitama Prefecture"
"120000": "Chiba Prefecture"
"130010": "Tokyo Region"
"130020": "Northern Izu Islands"
"130030": "Southern Izu Islands"
"130040": "Ogasawara Islands"
"130100": "Izu Islands"
"140000": "Kanagawa Prefecture"
"150000": "Niigata Prefecture"
"160000": "Toyama Prefecture"
"170000": "Ishikawa Prefecture"
"180000": "Fukui Prefecture"
"190000": "Yamanashi Prefecture"
"200000": "Nagano Prefecture"
"200010": "Northern Region"
"200100": "Central Region Southern Region"
"210000": "Gifu Prefecture"
"210010": "Mino Region"
"210020": "Hida Region"
"220000": "Shizuoka Prefecture"
"230000": "Aichi Prefecture"
"240000": "Mie Prefecture"
"250000": "Shiga Prefecture"
"250010": "Southern Region"
"250020": "Northern Region"
"260000": "Kyoto Prefecture"
"260010": "Southern Region"
"260020": "Northern Region"
"270000": "Osaka Prefecture"
"280000": "Hyogo Prefecture"
"280010": "Southern Region"
"280020": "Northern Region"
"290000": "Nara Prefecture"
"300000": "Wakayama Prefecture"
"310000": "Tottori Prefecture"
"320000": "Shimane Prefecture"
"330000": "Okayama Prefecture"
"330010": "Southern Region"
"330020": "Northern Region"
"340000": "Hiroshima Prefecture"
"340010": "Southern Region"
"340020": "Northern Region"
"350000": "Yamaguchi Prefecture"
"360000": "Tokushima Prefecture"
"370000": "Kagawa Prefecture"
"380000": "Ehime Prefecture"
"390000": "Kochi Prefecture"
"400000": "Fukuoka Prefecture"
"410000": "Saga Prefecture"
"420000": "Nagasaki Prefecture"
"420030": "Iki Tsushima"
"420100": "Southern Region Northern Region Goto"
"430000": "Kumamoto Prefecture"
"440000": "Oita Prefecture"
"450000": "Miyazaki Prefecture"
"460040": "Amami Region"
"460100": "Kagoshima Prefecture"
"471000": "Okinawa Main Island Region"
"472000": "Daitojima Region"
"473000": "Miyakojima Region"
"474000": "Yaeyama Region"
YAML_WEEK_AREAS_EOT
