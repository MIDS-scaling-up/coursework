logstash:
  group:
    - present
  user:
    - present
    - groups:
      - logstash
    - require:
      - group: logstash

/etc/logstash:
  file.directory:
    - user: logstash
    - group: logstash
    - mode: 755
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: logstash

/etc/ssl/logstash-forwarder.crt:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/logstash-forwarder.crt
    - require:
      - user: logstash
