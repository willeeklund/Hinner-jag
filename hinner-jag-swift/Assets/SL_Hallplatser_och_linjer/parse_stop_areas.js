require('colors');
var fs = require('fs');
var excelParser = require('excel-parser');

var firstRowSites,
sites = {},
stopPointNumberDict = {};

createStopPointsDict = function () {
    fs.readFile(__dirname + '/stoppoints.json', function (err, data) {
        var content = JSON.parse(data.toString('utf8'));
        var list = content['ResponseData']['Result'];
        list.forEach(function (item) {
            stopPointNumberDict[item['StopPointNumber']] = item['StopAreaTypeCode'];
        });
        parseStopAreas();
    });
},

siteFromData = function (data) {
    var site = {};
    firstRowSites.forEach(function (name, index) {
        if (['SiteId', 'SiteName', 'StopAreaNumber'].indexOf(name) !== -1) {
            site[name] = data[index];
        }
    });
    // SiteId and StopAreaNumber is Integer
    site.SiteId = parseInt(site.SiteId, 10);
    site.StopAreaNumber = parseInt(site.StopAreaNumber, 10);
    return site;
},

// Parse all sites
parseStopAreas = function () {
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
                return;
            }
            // if (i > 10) {return;}
            var site = siteFromData(data);
            // Make sure this site exist in large structure
            if (!sites[site.SiteId]) {
                sites[site.SiteId] = [];
            }
            // Save site to large structure
            sites[site.SiteId].push({
                'StopAreaNumber': site.StopAreaNumber,
                'StopAreaTypeCode': stopPointNumberDict[site.StopAreaNumber]
            });
        });
        console.log('Done with sites'.yellow, Object.keys(sites).length);
        var output = {'siteIdAndStopArea': sites};
        // Print to file
        var outputFilename = __dirname + '/stopareasites.json';
        fs.writeFile(outputFilename, JSON.stringify(output, null, 2), function(err) {
            if (err) {
              console.log(err);
            } else {
              console.log('JSON saved to ' + outputFilename);
            }
        });
    });
};

createStopPointsDict();
