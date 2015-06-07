require('colors');

var fixTrainDepartureListForSiteId = function (trainDepartureList) {
  trainDepartureList.forEach(function (item) {
    if (1 === item.JourneyDirection) {
      item.GroupOfLine = 'Pendeltåg Söder';
    } else if (2 === item.JourneyDirection) {
      item.GroupOfLine = 'Pendeltåg Norr ';
    } else {
      item.GroupOfLine = 'Pendeltåg ' + item.lineNumber;
    }
  });

  return trainDepartureList;
};

module.exports = {
  fixTrainDepartureListForSiteId: fixTrainDepartureListForSiteId
};