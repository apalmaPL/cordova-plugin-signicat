var exec = require("cordova/exec");

module.exports = {
  login: function (success, error) {
    exec(success, error, "SignicatPlugin", "loginAppToApp", []);
  },
};
