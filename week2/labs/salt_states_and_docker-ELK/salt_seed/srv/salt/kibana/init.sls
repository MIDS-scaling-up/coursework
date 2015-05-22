get-kibana:
  file.managed:
    - name: /usr/local/kibana-4.0.1-linux-x64.tar.gz
    - source: https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
    - source_hash: md5=ae5019e3c36a03fc57a069c235ca97e4
  cmd.wait:
    - cwd: /usr/local
    - names:
      - tar -zxf /usr/local/kibana-4.0.1-linux-x64.tar.gz -C /usr/local --show-transformed --transform='s,/*[^/]*,kibana,'
    - watch:
      - file: get-kibana

/etc/systemd/system/kibana4.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://kibana/kibana4.service

/usr/local/kibana/config/kibana.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://kibana/kibana.yml
    - require:
      - cmd: get-kibana

kibana.service:
  service.running:
    - name: kibana4
    - enable: True
    - watch:
      - file: /etc/systemd/system/kibana4.service
      - file: /usr/local/kibana/config/kibana.yml
