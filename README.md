# homer-metric-all

Docker container running [HOMER Metric](https://github.com/sipcapture/homer-config/tree/master/metric) branch

Default: **HEP** + **ELASTICSEARCH/KIBI/SENTINL**

## Usage
```
docker-compose up -d
```

### HEP Stack
![ezgif com-crop](https://user-images.githubusercontent.com/1423657/30537079-a2545750-9c68-11e7-997e-57151ee046b6.gif)

### ELK Stack
![ezgif com-optimize 25](https://user-images.githubusercontent.com/1423657/30553272-0ab7d4f6-9ca1-11e7-848f-5ac97308b1f7.gif)

#### Available Backends
```
   DO_INFLUXDB
   DO_MYSQL_STATS
   DO_ELASTICSEARCH
   DO_GRAYLOG
```   
#### Available Metrics
```
   DO_GEO
   DO_ISUP
   DO_KPI
   DO_MALICIOUS
   DO_METHOD
   DO_RESPONSE
   DO_RTCPXR
   DO_USERAGENT
   DO_XHTTP
   DO_XRTP
```
