var exec = require("cordova/exec");
/*
module.exports = {
  login: function (success, error) {
    exec(success, error, "Signicat", "loginAppToApp", []);
  },
};

window.handleOpenURL = function(url) {
    setTimeout(function() {
        alert(url);
        console.log(url);
    }, 0);
}
*/


module.exports = {
  login: function (successHandler,errorHandler,issuer,clientID,redirectURI,appToAppScopes,brokerDigidAppAcs,isAppToApp) {
    exec(successHandler,errorHandler,"SignicatPlugin","loginAppToApp",[issuer,clientID,redirectURI,appToAppScopes,brokerDigidAppAcs,isAppToApp]);
  },
  getAccessToken: function (successHandler,errorHandler,) {
    exec(successHandler,errorHandler,"SignicatPlugin","getAccessToken",[]);
  },
};