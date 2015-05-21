base:
  '*':
    - logstash.forwarder

  '*logger':
    - elasticsearch
    - logstash.server
    - kibana
