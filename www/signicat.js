var exec = require("cordova/exec");
/*
module.exports = {
  login: function (success, error) {
    exec(success, error, "Signicat", "loginAppToApp", []);
  },
};
*/

module.exports = {
  login: function (
    issuer,
    clientID,
    redirectURI,
    appToAppScopes,
    brokerDigidAppAcs
  ) {
    exec(
      function (result) {
                     self.alert("Success:\r\r" + result.status);
                 },
      null,
      "Signicat",
      "loginAppToApp",
      [
        issuer,
        clientID,
        redirectURI,
        appToAppScopes,
        brokerDigidAppAcs
      ]
    );
  },
};