require('colors');
var request = require('request'),
    config = require('../config'),

getJourneyDirectionsFromSiteId = function(siteId) {
  siteId = parseInt(siteId, 10);
  switch(siteId) {
    case 9280: return 1; // Norsborg
    case 9340: return 2; // Kungsträdgården
    case 9100: return 2; // Hässelby strand
  }
  return 1;
},

transformDisplayTime = function (timeString) {
  var currTime = new Date();
  var currTimeDiff = currTime.getTimezoneOffset();
  var currTimeMinutes = currTime.getHours() * 60 + currTime.getMinutes() + (120 + currTimeDiff);

  var timeStringParts = timeString.split(':');
  var timeStringMinutes = parseInt(timeStringParts[0], 10) * 60 + parseInt(timeStringParts[1], 10);

  var diffMinutes = timeStringMinutes - currTimeMinutes;
  return diffMinutes + ' min';
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
      if ('METRO' === tripContent.type) {
        var usedInfo = {
          'SiteId': siteId,
          'LineNumber': tripContent.line,
          'Destination': tripContent.dir,
          'GroupOfLine': tripContent.name,
          'StopAreaName': tripContent.Origin.name,
          'TransportMode': 'METRO',
          'JourneyDirection': getJourneyDirectionsFromSiteId(siteId),
          'DisplayTime': transformDisplayTime(tripContent.Origin.time)
        };
        retDepartures.push(usedInfo);
      }
    });

    callback(null, retDepartures);
  });
};

module.exports = {
  fetchData: fetchDeparturesFromSiteId
};
