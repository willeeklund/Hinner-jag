require('nodetime').profile({
  accountKey: 'f8a193d2541fbb68eb35ac5b16ba610253f5e32b',
  appName: 'Hinner-jag backend'
});

require('colors');
var express = require('express'),
    path = require('path'),
    request = require('request'),

/**
 * Express application configuration
 */
app = express.createServer();
app.configure(function () {
  app.use(express.compress());
  app.use(express.logger());
  app.use(express.static(path.join(__dirname, 'public'), { 'maxAge': 1000*60 })); // 1 minute
  app.use(app.router);
});

/**
 * Express Routing
 */
app.get('/', function (req, res) {
  res.send('Hej test');
});

app.get('/api/realtimedepartures/:site_id.json', function (req, res) {
  var realtimeKey = 'bebfe14511a74ca5aef16db943ae8589',
  timewindow = 30,
  SL_api_url = 'http://api.sl.se/api2/realtimedepartures.json?' +
               'key=' + realtimeKey +
               '&timewindow=' + timewindow +
               '&siteid=' + req.params.site_id;

  request(SL_api_url, function (err, res) {
    if (err) {
      console.log('Error requesting from SL'.red, err);
      return;
    }
  }).pipe(res)
});

var port = Number(process.env.PORT || 3000);
app.listen(port, function() {
  console.log(('Listening on ' + port).green);
});
