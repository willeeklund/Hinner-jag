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
    dataSourceRealtimeDepartures = require('./dataSources/realtimeDepartures'),
    dataSourceTravelPlanner = require('./dataSources/travelPlanner2'),
    stationInfo = require('./stationInfo'),
    utils = require('./utils');
    dataSourceRealtimeDepartures.setStationInfo(stationInfo);
    dataSourceTravelPlanner.setStationInfo(stationInfo);

/**
 * Fetch data from SL api using asyncronous queue
 */
var result_queues = {},

getQueueNameFromReq = function (req) {
  return req.params.site_id;
},

fetchDeparturesForRequest = function (req, res, callback) {
  var siteId = req.params.site_id;
  var completeList;
  dataSourceRealtimeDepartures.fetchData(siteId, function (err, resultListRealtime) {
    completeList = resultListRealtime;
    // Check if too few departures from the realtime API
    var nbrDepartures = completeList.ResponseData.Metros.length + completeList.ResponseData.Trains.length;
    if (
      ( nbrDepartures < 3 && stationInfo.isEndStation(siteId) ) ||
      ( nbrDepartures < 6 && !stationInfo.isEndStation(siteId) )
    ) {
      // Too few metro departures in realtime result, add from travel planner
      if (0 === nbrDepartures) {
        console.log('Not enough metro departures'.red, 'siteId'.cyan, siteId, 'nbrDepartures'.cyan, nbrDepartures);
      } else {
        console.log('Not enough metro departures'.yellow, 'siteId'.cyan, siteId, 'nbrDepartures'.cyan, nbrDepartures);
      }
      dataSourceTravelPlanner.fetchData(siteId, function (err, resultList) {
        var nbrAddedTravelPlanner = 0;
        resultList.forEach(function (departure) {
          var typeKey = departure.TransportModeCap; // 'Metros' or 'Trains'
          var hasSameDeparture = false;
          completeList.ResponseData[typeKey].forEach(function (realtimeDeparture) {
            // Consider it the same if the time is less than 1 minute apart
            // and the destination label is the same
            var realtimeTime = parseInt(realtimeDeparture.DisplayTime);
            var travelplanTime = parseInt(departure.DisplayTime);
            if (
              (Math.abs(realtimeTime - travelplanTime) <= 1) &&
              realtimeDeparture.Destination === departure.Destination
            ) {
              hasSameDeparture = true;
            }
          });
          if (!hasSameDeparture && nbrAddedTravelPlanner < 3) {
            // console.log('adding with hasSameDeparture='.green, hasSameDeparture, 'nbrAddedTravelPlanner='.green, nbrAddedTravelPlanner, departure);
            completeList.ResponseData[typeKey].push(departure);
            nbrAddedTravelPlanner++;
          } else {
            console.log('skipped departure'.yellow, departure);
          }
        });
        console.log(
          ('Too few metro departures for siteid ' + siteId).yellow,
          ('(' + nbrDepartures + ' departures)').blue,
          ('Adding ' + nbrAddedTravelPlanner + '/' + resultList.length + ' departures with TravelPlanner').blue
        );
        callback(err, completeList);
      });
      return;
    }
    callback(err, completeList);
  });
},

getResultDataFromRequest = function (task, done) {
  var queueName = getQueueNameFromReq(task.req);
  var cachedResultData = memoryCache.get(queueName);
  if (cachedResultData && config.useMemoryCache) {
    // Send back cached result
    console.log('cache hit'.cyan, queueName);
    task.callback(cachedResultData);
    done();
  } else {
    // Fetch result from SL api
    console.log('cache miss'.yellow, queueName);
    fetchDeparturesForRequest(task.req, task.res, function (err, newResultData) {
      // Formatting for train departures
      newResultData.ResponseData.Trains = utils.fixTrainDepartureListForSiteId(
        newResultData.ResponseData.Trains
      );
      // The result will be the same for 50 seconds
      var ttl_age = Math.max(50 - newResultData.ResponseData.DataAge, 5);
      console.log('Data age'.blue, newResultData.ResponseData.DataAge, 'new in'.cyan, ttl_age);
      memoryCache.put(queueName, newResultData, 1000 * ttl_age);
      task.callback(newResultData);
      done();
    });
  }
},

queueResultRequest = function (req, res, callback) {
  var queueName = getQueueNameFromReq(req);
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
  var siteId = parseInt(req.params.site_id);
  if (-1 === stationInfo.whitelist.indexOf(siteId)) {
    var invalidSiteIdMsg = 'Invalid site id ' + siteId;
    console.log(invalidSiteIdMsg.red);
    res.send(invalidSiteIdMsg);
    return;
  }
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
