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
    dataSourceTravelPlanner = require('./dataSources/travelPlanner2'),

/**
 * Fetch data from SL api using asyncronous queue
 */
result_queues = {},

getQueueNameFromReqParams = function (params) {
  return params.site_id;
},

updateResultCache = function (req, res, callback) {
  var realtimeKey = config.apiKeys.realtimeKey,
  timewindow = 60,
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
    // Remove all fields except Metros
    content.ResponseData.Buses = [];
    content.ResponseData.Ships = [];
    content.ResponseData.Trains = [];
    content.ResponseData.Trams = [];
    content.ResponseData.StopPointDeviations = [];
    // The result will be the same for 1 minute
    var ttl_age = Math.max(60 - content.ResponseData.DataAge, 5);
    console.log('Data age'.blue, content.ResponseData.DataAge, 'new in'.cyan, ttl_age);
    var nbrDepartures = content.ResponseData.Metros.length;
    if (0 === nbrDepartures) {
      // Too few metro departures in realtime result, add from travel planner
      console.log(
        'Error: too few metro departures'.red,
        ('for siteid ' + req.params.site_id).yellow,
        ('(' + nbrDepartures + ' departures)').blue
      );
      dataSourceTravelPlanner.fetchData(req.params.site_id, function (err, resultList) {
        console.log(('Adding ' + resultList.length + ' departures from TravelPlanner').blue);
        resultList.forEach(function (departure) {
          content.ResponseData.Metros.push(departure);
        });
        memoryCache.put(queueName, content, 1000 * ttl_age);
        callback(err, content);
      });
      return;
    }
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
  try {
    queueResultRequest(req, res, function (result) {
      res.header('Cache-Control', 'public, max-age=' + 30);
      res.send(result);
    });
  } catch (error) {
    console.log('Caught an error: '.red, error);
    res.send('Sorry, something went wrong with this request.');
  }
});

var port = Number(process.env.PORT || 3000);
app.listen(port, function() {
  console.log(('Listening on ' + port).green);
});
