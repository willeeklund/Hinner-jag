require('newrelic');
require('nodetime').profile({
  accountKey: 'f8a193d2541fbb68eb35ac5b16ba610253f5e32b',
  appName: 'Hinner-jag backend'
});

require('colors');
var express = require('express'),
    path = require('path'),
    request = require('request'),
    config = require('./config'),
    async = require('async'),
    memoryCache = require('memory-cache'),

/**
 * Fetch data from SL api using asyncronous queue
 */
result_queues = {},

getQueueNameFromReqParams = function (params) {
  return params.site_id;
},

updateResultCache = function (req, res, callback) {
  var realtimeKey = 'bebfe14511a74ca5aef16db943ae8589',
  timewindow = 30,
  SL_api_url = 'http://api.sl.se/api2/realtimedepartures.json?' +
               'key=' + realtimeKey +
               '&timewindow=' + timewindow +
               '&siteid=' + req.params.site_id;

  var queueName = getQueueNameFromReqParams(req.params);

  request(SL_api_url, function (err, requestResult) {
    if (err) {
      console.log('Error requesting from SL'.red, err);
      console.log('requestResult from SL'.red, requestResult);
      return;
    }
    var content = JSON.parse(requestResult.body);
    if (
      undefined === content ||
      undefined === content.ResponseData ||
      undefined === content.ResponseData.Metros ||
      0 === content.ResponseData.Metros.length
    ) {
      console.log('Error: no metro departures'.red, ('for siteid ' + req.params.site_id).yellow);
    }
    // Remove all fields except Metros
    content.ResponseData.Buses = [];
    content.ResponseData.Ships = [];
    content.ResponseData.Trains = [];
    content.ResponseData.StopPointDeviations = [];
    // The result will be the same for 1 minute
    var ttl_age = 60 - content.ResponseData.DataAge;
    console.log('Data age'.blue, content.ResponseData.DataAge, 'new in'.cyan, ttl_age);
    memoryCache.put(queueName, content, 1000 * ttl_age);
    callback(err, content);
  });
},

getResultDataFromRequest = function (task, done) {
  var queueName = getQueueNameFromReqParams(task.req.params);
  var cachedResultData = memoryCache.get(queueName);
  if (cachedResultData && config.useMemoryCache) {
    // Send back cached result
    console.log('cache hit'.cyan, queueName);
    task.callback(cachedResultData);
    done();
  } else {
    // Fetch result from SL api
    console.log('cache miss'.yellow, queueName);
    updateResultCache(task.req, task.res, function (err, newResultData) {
      task.callback(newResultData);
      done();
    });
  }
},

queueResultRequest = function (req, res, callback) {
  var queueName = getQueueNameFromReqParams(req.params);
  // Create the queue if it does not exist
  result_queues[queueName] = result_queues[queueName] || async.queue(getResultDataFromRequest, 1);
  // Add request to queue
  result_queues[queueName].push({
    req: req,
    res: res,
    callback: callback
  });
},

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
app.get('/hej', function (req, res) {
  res.send('Hej test');
});

app.get('/api/realtimedepartures/:site_id.json', function (req, res) {
  queueResultRequest(req, res, function (result) {
    res.header('Cache-Control', 'public, max-age=' + 30);
    res.send(result);
  });
});

var port = Number(process.env.PORT || 3000);
app.listen(port, function() {
  console.log(('Listening on ' + port).green);
});
