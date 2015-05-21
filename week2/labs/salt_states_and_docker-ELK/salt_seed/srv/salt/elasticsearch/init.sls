java-1.8.0-openjdk-headless:
  pkg.installed

elasticsearch-repo:
  pkgrepo.managed:
    - humanname: Elasticsearch repository for 1.4.x packages
    - baseurl: http://packages.elasticsearch.org/elasticsearch/1.4/centos
    - gpgcheck: 1
    - gpgkey: http://packages.elasticsearch.org/GPG-KEY-elasticsearch

elasticsearch:
  pkg.installed:
    - fromrepo: elasticsearch-repo

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://elasticsearch/elasticsearch.yml

elasticsearch.service:
  service.running:
    - name: elasticsearch
    - enable: True
    - reload: True
    - watch:
      - pkg: elasticsearch
