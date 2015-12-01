require('colors');
var request = require('request'),
    config = require('../config'),
    stationInfo,

fetchDeparturesFromSiteId = function (siteId, callback) {
  callback = callback || function () {};
  var realtimeKey = config.apiKeys.realtimeKey,
  timewindow = 60,
  SL_api_url = 'http://api.sl.se/api2/realtimedepartures.json?' +
               'key=' + realtimeKey +
               '&timewindow=' + timewindow +
               '&siteid=' + siteId;

  request(SL_api_url, function (err, requestResult) {
    if (err) {
      console.log('Error requesting from SL'.red, err);
      console.log('requestResult from SL'.red, requestResult);
      return;
    }
    try {
      var content = JSON.parse(requestResult.body);
      // Remove all fields except Metros and Trains
      content.ResponseData.Buses = [];
      content.ResponseData.Ships = [];
      content.ResponseData.Trams = [];
      content.ResponseData.StopPointDeviations = [];
      callback(err, content);
    } catch(err) {
      console.log('Error parsing response from Realtimedepartures'.red);
      callback(err, {
        ResponseData: {
          Metros: [],
          Trains: []
        }
      });
    }
  });
};

module.exports = {
  setStationInfo: function (object) {
    stationInfo = object;
  },
  fetchData: fetchDeparturesFromSiteId
};
