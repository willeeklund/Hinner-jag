require('colors');
var request = require('request'),
    config = require('../config'),
    stationInfo,

capitalizeFirstLetterAndTrimEnd = function(str) {
  var capitalized = str.charAt(0).toUpperCase() + str.slice(1);
  return capitalized.substring(0, capitalized.indexOf('linje') + 5);
},

capitalizeAndPlural = function (str) {
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase() + 's';
},

transformDisplayTime = function (timeString) {
  var currTime = new Date();
  var currTimeDiff = currTime.getTimezoneOffset();
  var currTimeMinutes = currTime.getHours() * 60 + currTime.getMinutes() + (120 + currTimeDiff);

  var timeStringParts = timeString.split(':');
  var timeStringMinutes = parseInt(timeStringParts[0], 10) * 60 + parseInt(timeStringParts[1], 10);

  var diffMinutes = timeStringMinutes - currTimeMinutes;
  if (diffMinutes < 1) {
    return 'Nu';
  } else {
    return diffMinutes + ' min';
  }
},

fetchDeparturesFromSiteId = function (siteId, callback) {
  callback = callback || function () {};
  var travelPlannerKey = config.apiKeys.travelPlannerKey,
  destinationId = '9001', // T-centralen always destination for now
  SL_api_url = 'http://api.sl.se/api2/TravelplannerV2/trip.json?' +
               'key=' + travelPlannerKey +
               '&destId=' + destinationId +
               '&originId=' + siteId;

  request(SL_api_url, function (err, requestResult) {
    var retDepartures = [];
    var parsedBody = JSON.parse(requestResult.body);
    var trips = parsedBody.TripList.Trip;
    trips.forEach(function (trip) {
      var tripContent = trip.LegList.Leg;
      if ('METRO' === tripContent.type || 'TRAIN' == tripContent.type) {
        var usedInfo = {
          'SiteId': parseInt(siteId),
          'LineNumber': tripContent.line,
          'Destination': tripContent.dir,
          'GroupOfLine': capitalizeFirstLetterAndTrimEnd(tripContent.name),
          'StopAreaName': tripContent.Origin.name,
          'TransportMode': tripContent.type,
          'TransportModeCap': capitalizeAndPlural(tripContent.type),
          'JourneyDirection': stationInfo.getTowardsCentralDirection(siteId),
          'FromTravelPlanner': true,
          'DisplayTime': transformDisplayTime(tripContent.Origin.time)
        };
        retDepartures.push(usedInfo);
      }
    });

    callback(null, retDepartures);
  });
};

module.exports = {
  setStationInfo: function (object) {
    stationInfo = object;
  },
  fetchData: fetchDeparturesFromSiteId
};
