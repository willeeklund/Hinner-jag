require('colors');
var
  // request = require('request'),
  fs = require('fs'),
  pg = require('pg'),
  csv = require('csv'),
  path = require('path'),
  // async = require('async'),
  // MongoClient = require('mongodb').MongoClient,
  stopPointsFilename = path.join(__dirname, 'stop_points.csv'),
  sitesFilename = path.join(__dirname, 'sites.csv'),
  parser = csv.parse({delimiter: ';'}),
  connection;

  var postgresObject = {
    user: 'ctilmaicakplft',
    password: 'jXPwfQL1t-2JBtXS1VIspYKhST',
    host: 'ec2-107-22-253-198.compute-1.amazonaws.com',
    database: 'd5is54voppc8uu',
    port: 5432,
    ssl: true
  };
  var db = new pg.Client(postgresObject);

// var downloadStopPoints = function () {
//   var csvUrl = 'http://api.sl.se/api2/FileService?key=dc065cb4058f43b6aa9992ff360cbe0f&filename=stoppoints.csv';
//   var outStream = fs.createWriteStream(stopPointsFilename),
//   reader = request(csvUrl, function (err, res) {
//     if (err) {
//       console.error('Error requesting ZIP'.red, err);
//       return;
//     }
//     console.log('lastModifiedHeader in the GET request'.blue, res.headers['last-modified']);
//   });

//   reader.pipe(outStream);
//   reader.on('end', function (err) {
//     if (err) {
//       console.error('Error when firing "end" event for CSV download'.red, err);
//       return;
//     }
//     console.log('CSV file downloaded'.cyan);
//   });
// };

var endPipeHandler = {
  on: function (a,b,c) {
    // console.log('on what?'.green, a, b, c);
  },
  once: function (a,b,c) {
    // console.log('just once?'.green, a, b, c);
  },
  emit: function (a,b,c) {
    // console.log('emit?'.green, a, b, c);
  },
  write: function (a,b,c) {
    // console.log('write?'.green, a, b, c);
  },
  end: function (a,b,c) {
    console.log('The end! Now we have parsed everything'.green);
  }
};

var applyQueryStringAndCallback = function (queryString, callback) {
  connection.query(queryString, function (err, res) {
    if (err) { console.log('Error inserting:'.red, err, res); return; }
    console.log('applyQueryStringAndCallback results'.cyan, res);
    callback(err, res)
  });
};

var parseStopPoints = function () {
  var readStream = fs.createReadStream(stopPointsFilename);
  var transformer = csv.transform(function (record, callback) {
    if ('METROSTN' !== record[6]) {
      callback(null, record);
      return;
    }

    var queryString = 'INSERT INTO stop_points ' +
    '(StopPointNumber, StopPointName, StopAreaNumber, latitude, longitude, StopAreaTypeCode) ' +
    'VALUES (' +
    "'" + record[0] + "', " +
    "'" + record[1] + "', " +
    "'" + record[2] + "', " +
    "'" + record[3] + "', " +
    "'" + record[4] + "', " +
    "'" + record[6] + "'" +
    ')';
    // console.log('record'.green, recordObj);
    console.log('queryString'.yellow, queryString);

    // Add points to database
    applyQueryStringAndCallback(queryString, callback)
    // // Or do nothing
    // callback(null);
  });

  readStream
    .pipe(parser)
    .pipe(transformer)
    .pipe(endPipeHandler);
};

var parseSites = function () {
  var readStream = fs.createReadStream(sitesFilename);
  var transformer = csv.transform(function (record, callback) {
    var SiteId = record[0];
    var SiteName = record[1];
    var StopAreaNumber = record[2];

    connection.query("SELECT * FROM stop_points WHERE StopAreaNumber = '" + StopAreaNumber + "'", function (err, res) {
      if (undefined === res || 0 === res.rows.length) {
        // No such metro station
        callback(null);
      } else {
        // var queryString_sites = 'INSERT INTO sites ' +
        // '(SiteId, SiteName, StopAreaNumber) ' +
        // 'VALUES (' +
        // "'" + SiteId + "', " +
        // "'" + SiteName + "', " +
        // "'" + StopAreaNumber + "'" +
        // ')';
        var latitude = res.rows[0].latitude;
        var longitude = res.rows[0].longitude;
        var queryString_metro_stations = 'INSERT INTO metro_stations ' +
        '(SiteId, SiteName, latitude, longitude) ' +
        'VALUES (' +
        "'" + SiteId + "', " +
        "'" + SiteName + "', " +
        "'" + latitude + "', " +
        "'" + longitude + "'" +
        ')';
        if (4 === SiteId.length) {
          console.log(
            'Now adding this record'.green,
            'SiteId'.green, SiteId,
            'SiteName'.green, SiteName,
            'StopAreaNumber'.cyan, StopAreaNumber,
            'result:'.cyan, res.rows,
            'queryString'.yellow, queryString_metro_stations
          );
          applyQueryStringAndCallback(queryString_metro_stations, callback)
        } else {
          console.log('Bad length of SiteId:'.red, SiteId);
          callback(null);
        }
      }
    });

    // // // Add points to database
    // // applyQueryStringAndCallback(queryString, callback)
    // // Or do nothing
    // callback(null);
  });

  readStream
    .pipe(parser)
    .pipe(transformer)
    .pipe(endPipeHandler);
};

var readFromDb = function () {
    connection.query("SELECT * FROM metro_stations", function (err, res) {
      if (!res) {
        console.log('No results found');
        return;
      }
      console.log('result rows'.green);
      console.log({ metro_stations: res.rows });
    });
};

db.connect(function (err, conn) {
  if (err) {
    console.log('Error with DB'.red, err);
    return;
  }
  connection = conn;
  // parseStopPoints();
  // parseSites();
  readFromDb();
});
