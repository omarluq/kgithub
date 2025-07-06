import QtQuick 2.15

QtObject {
    id: client

    property string token: ""
    property string username: ""

    function makeRequest(url, callback, useAuth = true) {
        var request = new XMLHttpRequest();
        request.open("GET", url);

        if (useAuth && token !== "") {
            request.setRequestHeader("Authorization", "Bearer " + token);
        }
        request.setRequestHeader("Accept", "application/vnd.github+json");
        request.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        var data = JSON.parse(request.responseText);
                        callback(data, null);
                    } catch (e) {
                        callback(null, "Failed to parse response: " + e.message);
                    }
                } else {
                    callback(null, "Request failed: " + request.status + " - " + request.responseText);
                }
            }
        };

        request.send();
    }
}
