```
services:
  ssp:
    image: ghcr.io/admin8800/ssp
    container_name: ssp
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - mariadb
      - redis
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./.config.php:/var/www/html/config/.config.php

  mariadb:
    image: mariadb:10.11
    container_name: mariadb-ssp
    restart: always
    environment:
      - TZ=Asia/Shanghai
      - MARIADB_ROOT_PASSWORD=sspanel
      - MARIADB_DATABASE=sspanel
      - MARIADB_USER=sspanel
      - MARIADB_PASSWORD=sspanel
    command:
      - --sql-mode=
    volumes:
      - ./data/mysql:/var/lib/mysql

  redis:
    image: redis:7-alpine
    container_name: redis-ssp
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - ./data/redis:/data
```

### 启动

修改`.config.php`配置，修改域名，数据库，redis等配置信息。

```bash
docker compose up -d
```

### 进入容器
```
docker compose exec -i ssp sh
```

### 导入数据
```bash
# 导入基础数据库
php xcat Migration new

# 执行更新逻辑
php xcat Update

# 导入数据库配置
php xcat Tool importSetting

# 升级数据库至当前源码最新版本
php xcat Migration latest

# 再次补全新版本配置
php xcat Tool importSetting

# 创建管理员
php xcat Tool createAdmin

# 重置用户流量
php xcat Tool resetBandwidth

# 下载客户端
su -s /bin/sh www-data -c 'php xcat ClientDownload'

# 下载 GeoLite2-City.mmdb
curl -L https://github.com/du5/geoip/raw/refs/heads/main/GeoLite2-City.mmdb \
  -o storage/GeoLite2-City/GeoLite2-City.mmdb

# 下载 GeoLite2-Country.mmdb
curl -L https://github.com/du5/geoip/raw/refs/heads/main/GeoLite2-Country.mmdb \
  -o storage/GeoLite2-Country/GeoLite2-Country.mmdb
```

### 反代并开启HTTPS

ssp面板要求必须反代并开启HTTPS，否则无法正常访问

### GeoIP2配置（可选）

[GeoIP2配置文档](https://docs.sspanel.io/docs/configuration/basic#geoip2-%E9%85%8D%E7%BD%AE)

更新GeoIP2命令：`php xcat Tool updateGeoIP2`

更多命令：`php xcat Tool`
