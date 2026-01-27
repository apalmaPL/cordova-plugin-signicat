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
  login: function (issuer,clientID,redirectURI,appToAppScopes,brokerDigidAppAcs,isAppToApp) {

    let successHandler = function (result) {
      self.alert("Success:\r\r" + result.status);
    };

    let errorHandler = function (error) {
      self.alert("Error:\r\r" + error);
    }

    exec(successHandler,errorHandler,"Signicat","loginAppToApp",[issuer,clientID,redirectURI,appToAppScopes,brokerDigidAppAcs,isAppToApp]);
  },
  getAccessToken: function (success,error) {
    exec(success,error,"Signicat","getAccessToken",[]);
  },
};