include:
  - logstash.common

logstash-forwarder-repo:
  pkgrepo.managed:
    - humanname: logstash forwarder repository
    - baseurl: http://packages.elasticsearch.org/logstashforwarder/centos
    - gpgcheck: 1
    - gpgkey: http://packages.elasticsearch.org/GPG-KEY-elasticsearch

logstash-forwarder-pkg:
  pkg.installed:
    - name: logstash-forwarder
    - fromrepo: logstash-forwarder-repo

/etc/logstash/conf.d/30-lumberjack-output.conf:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/30-lumberjack-output.conf
    - require:
      - user: logstash
      - file: /etc/logstash

/etc/logstash-forwarder.conf:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/logstash-forwarder.conf
    - require:
      - user: logstash
      - file: /etc/logstash

logstash-forwarder.service:
  service.running:
    - name: logstash-forwarder
    - enable: True
    - require:
        - pkg: logstash-forwarder-pkg
    - watch:
        - file: /etc/logstash
        - file: /etc/logstash/conf.d/30-lumberjack-output.conf
        - file: /etc/logstash-forwarder.conf
