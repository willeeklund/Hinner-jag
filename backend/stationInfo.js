require('colors');
var fs = require('fs'),
    path = require('path'),
    config = require('./config'),
    fileName = path.join(__dirname, '../HinnerJagKit/metro_stations.json'),
    stationsFileContent = fs.readFileSync(fileName),
    stationData = JSON.parse(stationsFileContent);

var sections = ['metro_and_train_stations', 'metro_stations', 'train_stations'];

// Whitelist for allowed site ids
var whitelistSiteId = [];

// Identify endstations
var endStationSiteIdList = [
    // Metro end stations
    9100, // Hässelby strand
    9140, // Skarpnäck
    9160, // Hagsätra
    9180, // Farsta strand
    9200, // Mörby centrum
    9220, // Ropsten
    9260, // Fruängen
    9280, // Norsborg
    9300, // Akalla
    9320, // Hjulsta
    9340, // Kungsträdgården
    // Train end stations
    9500, // Märsta
    9520, // Södertälje centrum
    9710, // Bålsta
    9720 // Nynäshamn
];

sections.forEach(function (section) {
    stationData[section].forEach(function (item) {
        whitelistSiteId.push(item.siteid);
    });
});

var isEndStation = function (siteId) {
    return endStationSiteIdList.indexOf(parseInt(siteId)) > -1
},

getFromCentralDirection = function (siteId) {
    var direction;
    sections.forEach(function (section) {
        stationData[section].forEach(function (item) {
            if (item.siteid === parseInt(siteId)) {
                direction = item.from_central_direction;
            }
        });
    });
    return direction;
},

getTowardsCentralDirection = function (siteId) {
    return (1 === getFromCentralDirection(siteId)) ? 2 : 1;
};

module.exports = {
    isEndStation: isEndStation,
    getFromCentralDirection: getFromCentralDirection,
    getTowardsCentralDirection: getTowardsCentralDirection,
    whitelist: whitelistSiteId
};
