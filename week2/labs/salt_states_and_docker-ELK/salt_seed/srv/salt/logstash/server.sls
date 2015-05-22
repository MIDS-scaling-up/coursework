include:
  - logstash.common

logstash-repo:
  pkgrepo.managed:
    - humanname: logstash repository for 1.5.x packages
    - baseurl: http://packages.elasticsearch.org/logstash/1.5/centos
    - gpgcheck: 1
    - gpgkey: http://packages.elasticsearch.org/GPG-KEY-elasticsearch

/etc/hosts:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/hosts
    - require:
      - user: logstash

logstash-pkg:
  pkg.installed:
    - name: logstash
    - fromrepo: logstash-repo

/etc/ssl/logstash-forwarder.key:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 600
    - contents_pillar: sslkeys:logstash-forwarder-key
    - require:
      - user: logstash
      - pkg: logstash-pkg
      - file: /etc/logstash

/etc/logstash/conf.d/10-filters.conf:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/10-filters.conf
    - require:
      - user: logstash
      - pkg: logstash-pkg
      - file: /etc/logstash

/etc/logstash/conf.d/01-lumberjack-input.conf:
  file.managed:
    - user: logstash
    - group: logstash
    - mode: 644
    - source: salt://logstash/01-lumberjack-input.conf
    - require:
      - user: logstash
      - pkg: logstash-pkg
      - file: /etc/logstash

logstash.service:
  service.running:
    - name: logstash
    - enable: True
    - require:
        - pkg: logstash-pkg
    - watch:
        - file: /etc/logstash/conf.d/10-filters.conf
        - file: /etc/logstash/conf.d/01-lumberjack-input.conf
        - file: /etc/ssl/logstash-forwarder.key
        - file: /etc/hosts
