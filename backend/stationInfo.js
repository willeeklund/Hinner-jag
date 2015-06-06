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

sections.forEach(function (section) {
    stationData[section].forEach(function (item) {
        whitelistSiteId.push(item.siteid);
    });
});

module.exports = {
    whitelist: whitelistSiteId
};
