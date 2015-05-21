/etc/ssl/logstash-forwarder.crt:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/logstash-forwarder.crt
