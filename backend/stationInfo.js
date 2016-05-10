require('colors');
var fs = require('fs'),
    path = require('path'),
    config = require('./config'),
    fileName = path.join(__dirname, '../HinnerJagKit/metro_stations.json'),
    stationsFileContent = fs.readFileSync(fileName),
    stationData = JSON.parse(stationsFileContent);

var sections = ['METROSTN', 'RAILWSTN', 'TRAMSTN', 'FERRYBER', 'BUSTERM'];

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
    if (stationData[section]) {
        stationData[section].forEach(function (item) {
            whitelistSiteId.push(item.SiteId);
        });
    }
});

var isEndStation = function (siteId) {
    return endStationSiteIdList.indexOf(parseInt(siteId)) > -1
},

getSiteDataFromId = function (siteId) {
    var siteData;
    sections.forEach(function (section) {
        stationData[section].forEach(function (item) {
            if (item.siteid === parseInt(siteId)) {
                siteData = item;
                siteData.type = section;
            }
        });
    });
    return siteData;
},

getFromCentralDirection = function (siteId) {
    return getSiteDataFromId(siteId).from_central_direction;
},

getTowardsCentralDirection = function (siteId) {
    return (1 === getFromCentralDirection(siteId)) ? 2 : 1;
};

module.exports = {
    isEndStation: isEndStation,
    getSiteDataFromId: getSiteDataFromId,
    getFromCentralDirection: getFromCentralDirection,
    getTowardsCentralDirection: getTowardsCentralDirection,
    whitelist: whitelistSiteId
};
