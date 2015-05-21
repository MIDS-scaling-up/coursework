(function() {

  'use strict';

  var express = require('express'),
      fs = require('fs'),
      sys = require('sys'),
      exec = require('child_process').exec,
      server = express(),
      expressLog = require('express-bunyan-logger'),
      bunyan = require('bunyan'),
      bunyan_lumber = require('bunyan-lumberjack');

  var log = bunyan.createLogger({
    name: 'loggen',
    streams: [{
      level: 'debug',
      type: 'raw',
      stream: bunyan_lumber({
        tlsOptions: {
          host: 'elk.mids',
          port: 5000,
          ca: [fs.readFileSync('/etc/ssl/logstash-forwarder.crt', {
              encoding: 'utf-8'
            })]
        }
      })
    }]
  });

  log.info('Starting loggen');

  server.use('/*', function(req, res) {
    exec('fortune', function(error, stdout, stderr) {
      if (error) {
        res.status(500);
        res.send("server error");
        log.error(stderr);
      } else {
        var fortune = stdout;
        res.set('Content-Type', 'text/plain');
        res.send(fortune);

        log.info("Sent fortune: ", fortune, " in response to req: ", req);
      }
    });
  });

  server.use(expressLog());
  server.use(expressLog.errorLogger());
  server.listen(80);
  log.info('Listening on port', 80);
})();
