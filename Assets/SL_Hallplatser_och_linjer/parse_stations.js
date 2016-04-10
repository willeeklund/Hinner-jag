require('colors');
var fs = require('fs');
var excelParser = require('excel-parser');

var firstRowStoppoints,
firstRowSites,
stoppoints = {},
sites = {},
nbrFound = 0,
nbrError = 0,
stoppointFromData = function (data) {
    var stoppoint = {};
    firstRowStoppoints.forEach(function (name, index) {
        stoppoint[name] = data[index];
    });
    // StopAreaNumber is Integer
    stoppoint.StopAreaNumber = parseInt(stoppoint.StopAreaNumber, 10);
    return stoppoint;
},
siteFromData = function (data) {
    var site = {};
    firstRowSites.forEach(function (name, index) {
        if (['SiteId', 'SiteName', 'StopAreaNumber'].indexOf(name) !== -1) {
            // Make SiteId and SiteName lowercase
            if (['SiteId', 'SiteName'].indexOf(name) !== -1) {
                name = name.toLowerCase()
            }
            site[name] = data[index];
        }
    });
    // SiteId and StopAreaNumber is Integer
    site.siteid = parseInt(site.siteid, 10);
    site.StopAreaNumber = parseInt(site.StopAreaNumber, 10);
    // See if we have the corresponding stoppoint
    if (stoppoints[site.StopAreaNumber]) {
        var point = stoppoints[site.StopAreaNumber];
        site.StopAreaTypeCode = point.StopAreaTypeCode;
        site.latitude = parseFloat(point.LocationNorthingCoordinate);
        site.longitude = parseFloat(point.LocationEastingCoordinate);
        // console.log(('Found stoppoint named "' + site.SiteName + '"').yellow, point.StopAreaTypeCode, '@', point.LocationEastingCoordinate, point.LocationNorthingCoordinate);
        nbrFound++;
    } else {
        // console.log('No stoppoint found'.red,(site.StopAreaNumber+ '').yellow, site.SiteName);
        nbrError++;
    }
    return site;
},
i = 0,

// Parse all stoppoints
parseStoppoints = function () {
    excelParser.parse({
        inFile: __dirname + '/stoppoints.xls',
        worksheet: 1
    }, function(err, records) {
        if (err) {
            console.error(err);
            return;
        }
        firstRowStoppoints = records[0];
        records.forEach(function (data, i) {
            if (0 === i) {
                firstRowStoppoints = data;
                i++;
                return;
            }
            var point = stoppointFromData(data);
            // Create dictionary with StopAreaNumber to point data
            stoppoints[point.StopAreaNumber] = point;
        });
        console.log('Done with stoppoints'.green, records.length);
        parseSites();
    });
},
// Parse all sites
parseSites = function () {
    excelParser.parse({
      inFile: __dirname + '/sites.xls',
      worksheet: 1
    }, function(err, records) {
        if (err) {
            console.error(err);
            return;
        }
        records.forEach(function (data, i) {
            if (0 === i) {
                firstRowSites = data;
                i++;
                return;
            }
            var site = siteFromData(data);
            // Make sure this type of station exist in large structure
            if (!sites[site.StopAreaTypeCode]) {
                sites[site.StopAreaTypeCode] = [];
            }
            // Save site to large structure
            sites[site.StopAreaTypeCode].push(site);
        });
        console.log('Done with sites'.yellow, (nbrFound + '').green, 'vs', (nbrError + '').red);
        getUniqueSites();
    });
},
getUniqueSites = function () {
    var sitesUnique = 0;
    var sitesDuplicate = 0;
    var sitesDuplicateName = 0;
    var dict_siteid = {};
    var dict_sitename = {};
    var sites_unique = {};
    var transport_types = Object.keys(sites);
    var transport_order = ['METROSTN', 'RAILWSTN', 'TRAMSTN', 'FERRYBER', 'BUSTERM'];
    console.log('transport_order'.green, transport_order);
    transport_order.forEach(function (key) {
        sites[key].forEach(function (site) {
            // Check if already added by 'siteid'
            if (dict_siteid[site.siteid]) {
                sitesDuplicate++;
            }
            // Check if already added by 'sitename'
            else if (dict_sitename[site.sitename]) {
                sitesDuplicate++;
                sitesDuplicateName++;
            } else {
                // New unique site, add to dictionaries
                dict_siteid[site.siteid] = true;
                dict_sitename[site.sitename] = true;
                dict_sitename[site.sitename.toLowerCase()] = true;
                dict_sitename[site.sitename.replace(/\-/g, '')] = true;
                sitesUnique++;
                // Make sure this type of station exist in 'sites_unique'
                if (!sites_unique[site.StopAreaTypeCode]) {
                    sites_unique[site.StopAreaTypeCode] = [];
                }
                // Save site to large structure
                sites_unique[site.StopAreaTypeCode].push(site);
            }
        });
        console.log(key.green, Object.keys(sites[key]).length, 'sitesUnique'.green, sitesUnique, 'sitesDuplicate'.red, sitesDuplicate, 'sitesDuplicateName'.red, sitesDuplicateName);
    });
    console.log('dict_siteid'.green, Object.keys(dict_siteid).length);
    // -----
    console.log('-----\nUnique sites\n-----'.green);
    transport_order.forEach(function (key) {
        console.log(key.green, Object.keys(sites_unique[key]).length);
    });

    // Print to file
    var outputFilename = __dirname + '/sites.json';
    fs.writeFile(outputFilename, JSON.stringify(sites_unique, null, 2), function(err) {
        if (err) {
          console.log(err);
        } else {
          console.log('JSON saved to ' + outputFilename);
        }
    });
};

parseStoppoints();
