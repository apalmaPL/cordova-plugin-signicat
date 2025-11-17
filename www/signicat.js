var exec = require("cordova/exec");

module.exports = {

    startAuthentication: function (config, success, error) {
        exec(success, error, "SignicatPlugin", "startAuthentication", [config]);
    }
};
