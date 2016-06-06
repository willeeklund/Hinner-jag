require('colors');
var fs = require('fs');
var excelParser = require('excel-parser');

var firstRowJourneyPatterns,
journeyPatternList = [],
pointFromData = function (data) {
    var point = {};
    firstRowJourneyPatterns.forEach(function (name, index) {
        if (-1 !== ['LineNumber', 'StopAreaNumber', 'DirectionCode'].indexOf(name)) {
            point[name] = parseInt(data[index], 10);
        }
    });
    return point;
},

i = 0,

// Parse all journey pattern points
parseJourneyPatterns = function () {
    excelParser.parse({
        inFile: __dirname + '/journeypatternpointonline.xls',
        worksheet: 1
    }, function(err, records) {
        if (err) {
            console.error(err);
            return;
        }
        records.forEach(function (data, i) {
            if (0 === i) {
                firstRowJourneyPatterns = data;
                i++;
                return;
            }
            var point = pointFromData(data);
            // Create dictionary with StopAreaNumber to point data
            journeyPatternList.push(point);
        });
        console.log('Done with points'.green, records.length);
        // Print to file
        var outputFilename = __dirname + '/journeypatternpoints.json';
        fs.writeFile(outputFilename, JSON.stringify({'journeyPatternList': journeyPatternList}, null, 2), function(err) {
            if (err) {
              console.log(err);
            } else {
              console.log('JSON saved to ' + outputFilename);
            }
        });
    });
};

parseJourneyPatterns();
