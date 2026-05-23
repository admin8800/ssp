### 启动

修改`.config.php`配置，修改域名，数据库，redis等配置信息。

```bash
docker compose up -d
```

### 导入数据
```
docker compose exec -i ssp sh
```
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

### GeoIP2配置（可选）

[GeoIP2配置文档](https://docs.sspanel.io/docs/configuration/basic#geoip2-%E9%85%8D%E7%BD%AE)

更新GeoIP2命令：`php xcat Tool updateGeoIP2`

更多命令：`php xcat Tool`


### 反代并开启HTTPS

反代`8080`端口并开启HTTPS即可正常访问面板
