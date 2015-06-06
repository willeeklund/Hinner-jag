require('colors');
var request = require('request'),
    config = require('../config'),

fixTrainDepartureList = function (trainDepartureList) {
  trainDepartureList.forEach(function (item) {
    item.GroupOfLine = 'Pendeltåg ' + item.LineNumber;
  });
  return trainDepartureList;
},

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
    var content = JSON.parse(requestResult.body);
    // Remove all fields except Metros and Trains
    content.ResponseData.Buses = [];
    content.ResponseData.Ships = [];
    content.ResponseData.Trams = [];
    content.ResponseData.StopPointDeviations = [];
    content.ResponseData.Trains = fixTrainDepartureList(content.ResponseData.Trains);

    callback(err, content);
  });
};

module.exports = {
  fetchData: fetchDeparturesFromSiteId
};
