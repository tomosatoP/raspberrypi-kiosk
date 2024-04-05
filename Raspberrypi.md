# Raspberry Pi の設定 -bullseye編-

Raspberry Pi と周辺機器
|項目|名称|補足|
|---|---|---|
|SBC|[Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)|4GByte|
|Display|[MPI4008](https://github.com/goodtft/LCD-show)|4inch, 800x480|
|Storage|uSD card|32GByte|

OS カスタマイズ - Raspberry Pi OS with desktop and recommended software (64bit)(bullseye)
|項目|適否|設定値1|設定値2|設定値3|
|---|:-:|---|---|---|
|ホスト名|☒|\<hostname\>|-|-|
|ユーザー名とパスワードを設定する|☒|\<username\>|\<PASSWORD\>|-|
|Wi-Fiを設定する|☒|\<SSID\>|\<PASSWORD\>|JP|
|ロケール設定をする|☒|Asia/Tokyo|jp|-|
|SSHを有効化する|☒|パスワード認証を使う|-|-|

## 初期設定

### システム設定
~~~sh
sudo apt update
sudu apt full-upgrade -y
sudo apt autoremove -y

sudo raspi-config nonint do_boot_behaviour B4
sudo raspi-config nonint do_boot_wait 1
~~~

### Bluetooth を停止

/boot/config.txt
~~~diff
@@ -46,4 +46,4 @@
 otg_mode=1

 [all]
-
+dtoverlay=disable-bt
~~~

### スワップファイルの拡張

/etc/dphys-swapfile
~~~diff
@@ -13,7 +13,7 @@

 # set size to absolute value, leaving empty (default) then uses computed value
 #   you most likely don't want this, unless you have an special disk situation
-CONF_SWAPSIZE=100
+CONF_SWAPSIZE=2048

 # set size to computed value, this times RAM size, dynamically adapts,
 #   guarantees that there is enough swap without wasting disk space on excess
~~~

~~~sh
sudo systemctl restart dphys-swapfile

# check
free -h
~~~

## ディスプレイ (MPI4008) 設定

### ドライバーのインストール

~~~sh
git clone https://github.com/goodtft/LCD-show.git

chmod -R 755 LCD-show
cd LCD-show
sudo ./MPI4008-show
# 自動で再起動
~~~

### 画面の回転

~~~sh
cd LCD-show

sudo ./rotate [0 | 90 | 180 | 270 | 360 | 450]
~~~

## docker engine 導入

まずルートモードをインストールした後、ルートレスモードをインストール

### ルートモードの導入

古いバージョンを削除
~~~sh
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
~~~

apt リポジトリを追加
~~~sh
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
~~~

インストール
~~~sh
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
~~~

停止
~~~sh
sudo systemctl disable --now docker.service docker.socket
~~~

### ルートレスモードの導入

関連パッケージをインストール
~~~sh
sudo apt update
sudo apt install -y uidmap
~~~

インストール
~~~sh
sudo apt update
sudo apt install -y docker-ce-rootless-extras

dockerd-rootless-setuptool.sh check
dockerd-rootless-setuptool.sh install
~~~

開始
~~~sh
systemctl --user enable docker
systemctl --user restart docker
~~~

## KIOSK 設定

マウスカーソルを自動で非表示に
~~~sh
sudo apt install unclutter
~~~

起動時、KIOSK モード "chromium-browser" で `KIOSK画面` を自動表示

/etc/xdg/lxsession/LXDE-pi/autostart
~~~text
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash

@xset s off
@xset -dpms
@xset s noblank
@unclutter
@chromium-browser --remote-debugging-port=9222 --no-default-browser-check --noerrdialogs --kiosk --incognito http://localhost:3030
~~~

---

bookworm with Wayland/Wayfire では？

~~起動時、KIOSK モード "chromium-browser" で `KIOSK画面` を自動表示~~

~~~sh
chromium-browser --kiosk http://localhost:3030 --start-maximized --start-fullscreen
~~~