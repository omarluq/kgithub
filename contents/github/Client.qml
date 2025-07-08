import QtQuick

QtObject {
    id: client

    property string token: ""
    property string username: ""
    property string baseUrl: "https://api.github.com"
    property int rateLimitRemaining: -1
    property int rateLimitReset: -1

    // Error types
    readonly property int errorNone: 0
    readonly property int errorNetwork: 1
    readonly property int errorAuth: 2
    readonly property int errorRateLimit: 3
    readonly property int errorNotFound: 4
    readonly property int errorParse: 5
    readonly property int errorUnknown: 6

    signal rateLimitChanged(int remaining, int reset)
    signal errorOccurred(int errorType, string message)

    function makeRequest(url, callback, options = {}) {
        var retryCount = options.retryCount || 0;
        var maxRetries = options.maxRetries || 2;
        var timeout = options.timeout || 10000;
        var useAuth = options.useAuth !== false;

        var request = new XMLHttpRequest();
        request.timeout = timeout;
        request.open("GET", url);

        // Set headers
        if (useAuth && token !== "") {
            request.setRequestHeader("Authorization", "Bearer " + token);
        }
        request.setRequestHeader("Accept", "application/vnd.github+json");
        request.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");
        request.setRequestHeader("User-Agent", "KGitHub-Plasmoid/1.0.0");

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                handleResponse(request, callback, url, options, retryCount, maxRetries);
            }
        };

        request.ontimeout = function() {
            if (retryCount < maxRetries) {
                var delay = Math.pow(2, retryCount) * 1000; // Exponential backoff
                Qt.callLater(function() {
                        var newOptions = {};
                    for (var key in options) {
                        newOptions[key] = options[key];
                    }
                    newOptions.retryCount = retryCount + 1;
                    makeRequest(url, callback, newOptions);
                });
            } else {
                callback(null, createError(errorNetwork, "Request timeout after " + maxRetries + " retries"));
            }
        };

        request.send();
    }

    function handleResponse(request, callback, url, options, retryCount, maxRetries) {
        // Update rate limit info
        var remaining = request.getResponseHeader('X-RateLimit-Remaining');
        var reset = request.getResponseHeader('X-RateLimit-Reset');
        if (remaining !== null) {
            rateLimitRemaining = parseInt(remaining);
            rateLimitReset = parseInt(reset);
            rateLimitChanged(rateLimitRemaining, rateLimitReset);
        }

        if (request.status === 200) {
            try {
                var data = JSON.parse(request.responseText);
                callback(data, null);
            } catch (e) {
                var error = createError(errorParse, "Failed to parse response: " + e.message);
                callback(null, error);
                errorOccurred(error.type, error.message);
            }
        } else {
            var error = handleHttpError(request.status, request.responseText);

            // Retry for certain error types
            if (shouldRetry(request.status) && retryCount < maxRetries) {
                var delay = Math.pow(2, retryCount) * 1000;
                Qt.callLater(function() {
                        var newOptions = {};
                    for (var key in options) {
                        newOptions[key] = options[key];
                    }
                    newOptions.retryCount = retryCount + 1;
                    makeRequest(url, callback, newOptions);
                });
            } else {
                callback(null, error);
                errorOccurred(error.type, error.message);
            }
        }
    }

    function shouldRetry(status) {
        // Retry on server errors and rate limits (but not auth or not found)
        return status >= 500 || status === 429;
    }

    function handleHttpError(status, responseText) {
        switch (status) {
            case 401:
                return createError(errorAuth, "Invalid or expired GitHub token");
            case 403:
                var message = "Access forbidden";
                try {
                    var response = JSON.parse(responseText);
                    if (response.message && response.message.includes("rate limit")) {
                        message = "Rate limit exceeded. Try again later.";
                        return createError(errorRateLimit, message);
                    }
                } catch (e) {}
                return createError(errorAuth, message);
            case 404:
                return createError(errorNotFound, "Resource not found");
            case 422:
                return createError(errorUnknown, "Validation failed");
            case 429:
                return createError(errorRateLimit, "Rate limit exceeded");
            default:
                return createError(errorNetwork, "HTTP " + status + ": " + responseText);
        }
    }

    function createError(type, message) {
        return {
            type: type,
            message: message,
            timestamp: Date.now()
        };
    }

    // High-level API methods
    function getUser(username, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username);
        makeRequest(url, callback);
    }

    function getUserRepositories(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/repos";
        url += "?sort=updated&per_page=" + perPage + "&page=" + page + "&type=all";
        makeRequest(url, callback);
    }

    function searchIssues(query, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query);
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function searchPullRequests(query, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query + " is:pr");
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function getUserOrganizations(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/orgs";
        url += "?per_page=" + perPage + "&page=" + page;
        makeRequest(url, callback);
    }

    function getUserStarredRepositories(username, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/starred";
        url += "?per_page=" + perPage + "&page=" + page;
        makeRequest(url, callback);
    }

    function getUserStarredCount(username, callback) {
        var totalCount = 0;
        var currentPage = 1;

        function fetchPage() {
            getUserStarredRepositories(username, currentPage, 100, function(data, error) {
                if (error) {
                    callback(null, error);
                    return;
                }

                totalCount += data.length;

                if (data.length === 100) {
                    currentPage++;
                    fetchPage();
                } else {
                    callback(totalCount, null);
                }
            });
        }

        fetchPage();
    }

    function getRepositoryIssues(owner, repo, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues";
        url += "?state=all&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function getRepositoryPullRequests(owner, repo, page = 1, perPage = 5, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/pulls";
        url += "?state=all&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function getRepositoryReadme(owner, repo, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/readme";
        makeRequest(url, callback);
    }

    // Detailed data fetching for issues and PRs
    function getIssueDetails(owner, repo, issueNumber, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues/" + issueNumber;
        makeRequest(url, function(issue, error) {
            if (error) {
                callback(null, error);
                return;
            }

            // Fetch reactions for the issue
            getIssueReactions(owner, repo, issueNumber, function(reactions, reactionError) {
                if (!reactionError && reactions) {
                    issue.reactions = processReactions(reactions);
                } else {
                    issue.reactions = [];
                }
                callback(issue, null);
            });
        });
    }

    function getPullRequestDetails(owner, repo, prNumber, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/pulls/" + prNumber;
        makeRequest(url, function(pr, error) {
            if (error) {
                callback(null, error);
                return;
            }

            // Fetch reactions for the PR
            getIssueReactions(owner, repo, prNumber, function(reactions, reactionError) {
                if (!reactionError && reactions) {
                    pr.reactions = processReactions(reactions);
                } else {
                    pr.reactions = [];
                }
                callback(pr, null);
            });
        });
    }

    function getIssueComments(owner, repo, issueNumber, callback, page = 1, perPage = 30) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues/" + issueNumber + "/comments";
        url += "?sort=created&direction=asc";
        url += "&page=" + page + "&per_page=" + perPage;
        makeRequest(url, function(comments, error) {
            if (error) {
                callback(null, error);
                return;
            }

            // Fetch reactions for each comment
            fetchCommentsWithReactions(owner, repo, comments, callback);
        });
    }

    function getPullRequestComments(owner, repo, prNumber, callback, page = 1, perPage = 30) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues/" + prNumber + "/comments";
        url += "?sort=created&direction=asc";
        url += "&page=" + page + "&per_page=" + perPage;
        makeRequest(url, function(comments, error) {
            if (error) {
                callback(null, error);
                return;
            }

            // Fetch reactions for each comment
            fetchCommentsWithReactions(owner, repo, comments, callback);
        });
    }

    function fetchCommentsWithReactions(owner, repo, comments, callback) {
        if (!comments || comments.length === 0) {
            callback(comments, null);
            return;
        }

        var completedRequests = 0;
        var totalRequests = comments.length;
        var commentsWithReactions = [];

        // Initialize array with correct order
        for (var i = 0; i < comments.length; i++) {
            commentsWithReactions[i] = comments[i];
            commentsWithReactions[i].reactions = [];
        }

        function checkCompletion() {
            if (completedRequests >= totalRequests) {
                callback(commentsWithReactions, null);
            }
        }

        // Fetch reactions for each comment
        for (var i = 0; i < comments.length; i++) {
            (function(index) {
                var comment = comments[index];
                getCommentReactions(owner, repo, comment.id, function(reactions, error) {
                    if (!error && reactions) {
                        commentsWithReactions[index].reactions = processReactions(reactions);
                    } else {
                        commentsWithReactions[index].reactions = [];
                    }
                    completedRequests++;
                    checkCompletion();
                });
            })(i);
        }
    }

    function getCommentReactions(owner, repo, commentId, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues/comments/" + commentId + "/reactions";
        makeRequest(url, callback);
    }

    function getIssueReactions(owner, repo, issueNumber, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(owner) + "/" + encodeURIComponent(repo) + "/issues/" + issueNumber + "/reactions";
        makeRequest(url, callback);
    }

    function processReactions(reactions) {
        if (!reactions || !Array.isArray(reactions)) {
            return [];
        }

        // Count reactions by type
        var reactionCounts = {};
        var reactionEmojis = {
            // Official GitHub reactions
            "+1": "👍",
            "-1": "👎",
            "laugh": "😄",
            "hooray": "🎉",
            "confused": "😕",
            "heart": "❤️",
            "rocket": "🚀",
            "eyes": "👀",

            // Face emojis
            "smile": "😊",
            "smiley": "😃",
            "grinning": "😀",
            "blush": "😊",
            "wink": "😉",
            "kissing_heart": "😘",
            "joy": "😂",
            "sweat_smile": "😅",
            "laughing": "😆",
            "innocent": "😇",
            "smiling_imp": "😈",
            "sunglasses": "😎",
            "neutral_face": "😐",
            "expressionless": "😑",
            "unamused": "😒",
            "sweat": "😓",
            "pensive": "😔",
            "disappointed": "😞",
            "confounded": "😖",
            "fearful": "😨",
            "weary": "😩",
            "sleepy": "😪",
            "tired_face": "😫",
            "grimacing": "😬",
            "sob": "😭",
            "open_mouth": "😮",
            "hushed": "😯",
            "cold_sweat": "😰",
            "scream": "😱",
            "astonished": "😲",
            "flushed": "😳",
            "sleeping": "😴",
            "dizzy_face": "😵",
            "no_mouth": "😶",
            "mask": "😷",
            "grin": "😁",
            "stuck_out_tongue": "😛",
            "stuck_out_tongue_winking_eye": "😜",
            "stuck_out_tongue_closed_eyes": "😝",
            "disappointed_relieved": "😥",
            "worried": "😟",
            "angry": "😠",
            "rage": "😡",
            "triumph": "😤",
            "relieved": "😌",
            "nerd_face": "🤓",
            "thinking": "🤔",
            "thinking_face": "🤔",
            "face_with_raised_eyebrow": "🤨",
            "neutral_face": "😐",
            "expressionless": "😑",
            "face_without_mouth": "😶",
            "smirk": "😏",
            "persevere": "😣",
            "disappointed_relieved": "😥",
            "open_mouth": "😮",
            "zipper_mouth_face": "🤐",
            "hushed": "😯",
            "sleepy": "😪",
            "tired_face": "😫",
            "sleeping": "😴",
            "relieved": "😌",
            "stuck_out_tongue": "😛",
            "stuck_out_tongue_winking_eye": "😜",
            "stuck_out_tongue_closed_eyes": "😝",
            "drooling_face": "🤤",
            "unamused": "😒",
            "sweat": "😓",
            "pensive": "😔",
            "confused": "😕",
            "upside_down_face": "🙃",
            "money_mouth_face": "🤑",
            "astonished": "😲",
            "frowning": "☹️",
            "slightly_frowning_face": "🙁",
            "confounded": "😖",
            "disappointed": "😞",
            "worried": "😟",
            "triumph": "😤",
            "cry": "😢",
            "sob": "😭",
            "flushed": "😳",
            "dizzy_face": "😵",
            "rage": "😡",
            "angry": "😠",
            "smiling_imp": "😈",
            "imp": "👿",
            "skull": "💀",
            "heart_eyes": "😍",
            "kissing": "😗",
            "kissing_smiling_eyes": "😙",
            "kissing_closed_eyes": "😚",
            "yum": "😋",

            // Hand/gesture emojis
            "thumbsup": "👍",
            "thumbsdown": "👎",
            "ok_hand": "👌",
            "punch": "👊",
            "fist": "✊",
            "v": "✌️",
            "wave": "👋",
            "raised_hand": "✋",
            "open_hands": "👐",
            "point_up": "☝️",
            "point_down": "👇",
            "point_left": "👈",
            "point_right": "👉",
            "raised_hands": "🙌",
            "pray": "🙏",
            "clap": "👏",
            "muscle": "💪",
            "metal": "🤘",
            "fu": "🖕",
            "walking": "🚶",
            "runner": "🏃",
            "couple": "👫",
            "family": "👪",
            "two_men_holding_hands": "👬",
            "two_women_holding_hands": "👭",
            "dancer": "💃",
            "dancers": "👯",
            "ok_woman": "🙆",
            "no_good": "🙅",
            "information_desk_person": "💁",
            "raising_hand": "🙋",
            "massage": "💆",
            "haircut": "💇",
            "nail_care": "💅",
            "boy": "👦",
            "girl": "👧",
            "woman": "👩",
            "man": "👨",
            "baby": "👶",
            "older_woman": "👵",
            "older_man": "👴",

            // Heart emojis
            "yellow_heart": "💛",
            "blue_heart": "💙",
            "purple_heart": "💜",
            "green_heart": "💚",
            "broken_heart": "💔",
            "heartbeat": "💓",
            "heartpulse": "💗",
            "two_hearts": "💕",
            "revolving_hearts": "💞",
            "cupid": "💘",
            "sparkling_heart": "💖",

            // Nature emojis
            "sunny": "☀️",
            "umbrella": "☔",
            "cloud": "☁️",
            "snowflake": "❄️",
            "snowman": "⛄",
            "zap": "⚡",
            "cyclone": "🌀",
            "foggy": "🌁",
            "ocean": "🌊",
            "cat": "🐱",
            "dog": "🐶",
            "mouse": "🐭",
            "hamster": "🐹",
            "rabbit": "🐰",
            "wolf": "🐺",
            "frog": "🐸",
            "tiger": "🐯",
            "koala": "🐨",
            "bear": "🐻",
            "pig": "🐷",
            "pig_nose": "🐽",
            "cow": "🐮",
            "boar": "🐗",
            "monkey_face": "🐵",
            "monkey": "🐒",
            "horse": "🐴",
            "racehorse": "🐎",
            "camel": "🐫",
            "sheep": "🐑",
            "elephant": "🐘",
            "panda_face": "🐼",
            "snake": "🐍",
            "bird": "🐦",
            "baby_chick": "🐤",
            "hatched_chick": "🐥",
            "hatching_chick": "🐣",
            "chicken": "🐔",
            "penguin": "🐧",
            "turtle": "🐢",
            "bug": "🐛",
            "honeybee": "🐝",
            "ant": "🐜",
            "beetle": "🪲",
            "snail": "🐌",
            "octopus": "🐙",
            "tropical_fish": "🐠",
            "fish": "🐟",
            "whale": "🐳",
            "whale2": "🐋",
            "dolphin": "🐬",
            "cow2": "🐄",
            "ram": "🐏",
            "rat": "🐀",
            "water_buffalo": "🐃",
            "tiger2": "🐅",
            "rabbit2": "🐇",
            "dragon": "🐲",
            "goat": "🐐",
            "rooster": "🐓",
            "dog2": "🐕",
            "pig2": "🐖",
            "mouse2": "🐁",
            "ox": "🐂",

            // Food emojis
            "apple": "🍎",
            "green_apple": "🍏",
            "tangerine": "🍊",
            "lemon": "🍋",
            "cherries": "🍒",
            "grapes": "🍇",
            "watermelon": "🍉",
            "strawberry": "🍓",
            "peach": "🍑",
            "melon": "🍈",
            "banana": "🍌",
            "pear": "🍐",
            "pineapple": "🍍",
            "sweet_potato": "🍠",
            "eggplant": "🍆",
            "tomato": "🍅",
            "corn": "🌽",

            // Objects emojis
            "fire": "🔥",
            "100": "💯",
            "bomb": "💣",
            "tada": "🎉",
            "confetti_ball": "🎊",
            "balloon": "🎈",
            "crystal_ball": "🔮",
            "dizzy": "💫",
            "boom": "💥",
            "collision": "💥",
            "anger": "💢",
            "hotsprings": "♨️",
            "octagonal_sign": "🛑",
            "clock12": "🕛",
            "clock1": "🕐",
            "clock2": "🕑",
            "clock3": "🕒",
            "clock4": "🕓",
            "clock5": "🕔",
            "clock6": "🕕",
            "clock7": "🕖",
            "clock8": "🕗",
            "clock9": "🕘",
            "clock10": "🕙",
            "clock11": "🕚",
            "new_moon": "🌑",
            "waxing_crescent_moon": "🌒",
            "first_quarter_moon": "🌓",
            "moon": "🌔",
            "full_moon": "🌕",
            "waning_gibbous_moon": "🌖",
            "last_quarter_moon": "🌗",
            "waning_crescent_moon": "🌘",
            "crescent_moon": "🌙",
            "new_moon_with_face": "🌚",
            "first_quarter_moon_with_face": "🌛",
            "last_quarter_moon_with_face": "🌜",
            "full_moon_with_face": "🌝",
            "sun_with_face": "🌞",
            "star2": "🌟",
            "stars": "🌠",

            // Activity emojis
            "sparkles": "✨",
            "star": "⭐",
            "exclamation": "❗",
            "question": "❓",
            "grey_exclamation": "❕",
            "grey_question": "❔",
            "zzz": "💤",
            "dash": "💨",
            "sweat_drops": "💦",
            "notes": "🎶",
            "musical_note": "🎵",
            "fire": "🔥",
            "hankey": "💩",
            "poop": "💩",
            "shit": "💩",
            "tent": "⛺",
            "umbrella": "☔",
            "coffee": "☕",
            "airplane": "✈️",
            "anchor": "⚓",
            "zap": "⚡",
            "white_check_mark": "✅",
            "ballot_box_with_check": "☑️",
            "heavy_check_mark": "✔️",
            "heavy_multiplication_x": "✖️",
            "x": "❌",
            "negative_squared_cross_mark": "❎",
            "heavy_plus_sign": "➕",
            "heavy_minus_sign": "➖",
            "heavy_division_sign": "➗",
            "curly_loop": "➰",
            "loop": "➿",
            "part_alternation_mark": "〽️",
            "eight_spoked_asterisk": "✳️",
            "eight_pointed_black_star": "✴️",
            "sparkle": "❇️",
            "bangbang": "‼️",
            "interrobang": "⁉️",
            "tm": "™️",
            "information_source": "ℹ️",
            "left_right_arrow": "↔️",
            "arrow_up_down": "↕️",
            "arrow_upper_left": "↖️",
            "arrow_upper_right": "↗️",
            "arrow_lower_right": "↘️",
            "arrow_lower_left": "↙️",
            "leftwards_arrow_with_hook": "↩️",
            "arrow_right_hook": "↪️",
            "watch": "⌚",
            "hourglass": "⌛",
            "keyboard": "⌨️",
            "eject": "⏏️",
            "fast_forward": "⏩",
            "rewind": "⏪",
            "arrow_double_up": "⏫",
            "arrow_double_down": "⏬",
            "black_right_pointing_double_triangle_with_vertical_bar": "⏭️",
            "black_left_pointing_double_triangle_with_vertical_bar": "⏮️",
            "black_right_pointing_triangle_with_double_vertical_bar": "⏯️",
            "alarm_clock": "⏰",
            "stopwatch": "⏱️",
            "timer_clock": "⏲️",
            "hourglass_flowing_sand": "⏳",
            "double_vertical_bar": "⏸️",
            "black_square_for_stop": "⏹️",
            "black_circle_for_record": "⏺️",
            "m": "Ⓜ️",
            "black_small_square": "▪️",
            "white_small_square": "▫️",
            "arrow_forward": "▶️",
            "arrow_backward": "◀️",
            "white_medium_square": "◻️",
            "black_medium_square": "◼️",
            "white_medium_small_square": "◽",
            "black_medium_small_square": "◾",
            "sunny": "☀️",
            "cloud": "☁️",
            "umbrella": "☔",
            "snowman": "☃️",
            "comet": "☄️",
            "phone": "☎️",
            "ballot_box_with_check": "☑️",
            "umbrella_with_rain_drops": "☔",
            "coffee": "☕",
            "shamrock": "☘️",
            "point_up": "☝️",
            "skull_and_crossbones": "☠️",
            "radioactive": "☢️",
            "biohazard": "☣️",
            "orthodox_cross": "☦️",
            "star_and_crescent": "☪️",
            "peace_symbol": "☮️",
            "yin_yang": "☯️",
            "wheel_of_dharma": "☸️",
            "white_frowning_face": "☹️",
            "relaxed": "☺️",
            "female_sign": "♀️",
            "male_sign": "♂️",
            "aries": "♈",
            "taurus": "♉",
            "gemini": "♊",
            "cancer": "♋",
            "leo": "♌",
            "virgo": "♍",
            "libra": "♎",
            "scorpius": "♏",
            "sagittarius": "♐",
            "capricorn": "♑",
            "aquarius": "♒",
            "pisces": "♓",
            "chess_pawn": "♟️",
            "spades": "♠️",
            "clubs": "♣️",
            "hearts": "♥️",
            "diamonds": "♦️",
            "hotsprings": "♨️",
            "recycle": "♻️",
            "infinity": "♾️",
            "wheelchair": "♿",
            "hammer_and_pick": "⚒️",
            "anchor": "⚓",
            "crossed_swords": "⚔️",
            "medical_symbol": "⚕️",
            "balance_scale": "⚖️",
            "alembic": "⚗️",
            "gear": "⚙️",
            "atom_symbol": "⚛️",
            "fleur_de_lis": "⚜️",
            "warning": "⚠️",
            "high_voltage": "⚡",
            "white_circle": "⚪",
            "black_circle": "⚫",
            "red_circle": "🔴",
            "large_blue_circle": "🔵",
            "small_orange_diamond": "🔸",
            "small_blue_diamond": "🔹",
            "large_orange_diamond": "🔶",
            "large_blue_diamond": "🔷",
            "small_red_triangle": "🔺",
            "small_red_triangle_down": "🔻",
            "diamond_shape_with_a_dot_inside": "💠",
            "radio_button": "🔘",
            "white_square_button": "🔳",
            "black_square_button": "🔲"
        };

        for (var i = 0; i < reactions.length; i++) {
            var reaction = reactions[i];
            var content = reaction.content;

            if (!reactionCounts[content]) {
                reactionCounts[content] = {
                    type: content,
                    emoji: reactionEmojis[content] || "❓", // Fallback for unknown reaction types
                    count: 0,
                    users: []
                };
            }

            reactionCounts[content].count++;
            if (reaction.user && reaction.user.login) {
                reactionCounts[content].users.push(reaction.user.login);
            }
        }

        // Convert to array and sort by count (descending)
        var sortedReactions = [];
        for (var type in reactionCounts) {
            sortedReactions.push(reactionCounts[type]);
        }

        sortedReactions.sort(function(a, b) {
            return b.count - a.count;
        });

        // Return top 5 reactions
        return sortedReactions.slice(0, 5);
    }

    // Commit activity API methods
    function getUserEvents(username, callback, page = 1, perPage = 100) {
        var url = baseUrl + "/users/" + encodeURIComponent(username) + "/events";
        url += "?per_page=" + perPage + "&page=" + page;
        makeRequest(url, callback);
    }

    function makeGraphQLRequest(query, callback) {
        var request = new XMLHttpRequest();
        request.timeout = 30000; // 30 seconds for GraphQL
        request.open("POST", "https://api.github.com/graphql");

        if (token !== "") {
            request.setRequestHeader("Authorization", "Bearer " + token);
        }
        request.setRequestHeader("Content-Type", "application/json");
        request.setRequestHeader("User-Agent", "KGitHub-Plasmoid/1.0.0");

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        var data = JSON.parse(request.responseText);
                        if (data.errors) {
                            callback(null, createError(errorUnknown, "GraphQL errors: " + JSON.stringify(data.errors)));
                        } else {
                            callback(data.data, null);
                        }
                    } catch (e) {
                        callback(null, createError(errorParse, "Failed to parse GraphQL response: " + e.message));
                    }
                } else {
                    callback(null, createError(errorNetwork, "GraphQL request failed: HTTP " + request.status));
                }
            }
        };

        request.send(JSON.stringify({ query: query }));
    }

    function getUserCommitActivity(username, callback) {
        // Use GraphQL to get all contribution types for the full year
        var finalQuery = `query {
            user(login: "${username}") {
                contributionsCollection {
                    contributionCalendar {
                        totalContributions
                        weeks {
                            contributionDays {
                                date
                                contributionCount
                                color
                            }
                        }
                    }
                    totalCommitContributions
                    totalIssueContributions
                    totalPullRequestContributions
                    totalPullRequestReviewContributions
                    totalRepositoryContributions
                }
            }
        }`;

        makeGraphQLRequest(finalQuery, function(data, error) {
            if (error) {
                console.log("GraphQL error, falling back to events API:", error.message);
                // Fallback to events API with enhanced data
                fallbackToEventsAPI(username, callback);
                return;
            }

            if (data && data.user && data.user.contributionsCollection) {
                var contributionData = processContributionCalendar(data.user.contributionsCollection);
                callback(contributionData, null);
            } else {
                console.log("No contribution data found, falling back to events API");
                fallbackToEventsAPI(username, callback);
            }
        });
    }

    function processContributionCalendar(contributionsCollection) {
        var calendar = contributionsCollection.contributionCalendar;
        var activityData = [];
        var maxCommits = 0;
        var totalCommits = calendar.totalContributions || 0;

        // Process all weeks and days
        if (calendar.weeks) {
            for (var w = 0; w < calendar.weeks.length; w++) {
                var week = calendar.weeks[w];
                if (week.contributionDays) {
                    for (var d = 0; d < week.contributionDays.length; d++) {
                        var day = week.contributionDays[d];
                        var commits = day.contributionCount || 0;
                        maxCommits = Math.max(maxCommits, commits);

                        var date = new Date(day.date);
                        activityData.push({
                            date: day.date,
                            commits: commits,
                            activity: 0, // Will be calculated after we know maxCommits
                            dayOfWeek: date.getDay(),
                            weekOfYear: getWeekOfYear(date)
                        });
                    }
                }
            }
        }

        // Normalize activity levels (0-1 scale)
        for (var i = 0; i < activityData.length; i++) {
            activityData[i].activity = maxCommits > 0 ? activityData[i].commits / maxCommits : 0;
        }

        // Add detailed contribution breakdown
        var contributionBreakdown = {
            totalCommits: contributionsCollection.totalCommitContributions || 0,
            totalIssues: contributionsCollection.totalIssueContributions || 0,
            totalPRs: contributionsCollection.totalPullRequestContributions || 0,
            totalReviews: contributionsCollection.totalPullRequestReviewContributions || 0,
            totalRepos: contributionsCollection.totalRepositoryContributions || 0
        };

        return {
            data: activityData,
            maxCommits: maxCommits,
            totalDays: activityData.length,
            totalCommits: totalCommits,
            breakdown: contributionBreakdown
        };
    }

    function fallbackToEventsAPI(username, callback) {
        // Enhanced fallback using events + repository analysis
        var commitsByDate = {};
        var completedRequests = 0;
        var totalRequests = 2;

        // Get recent events (last 90 days of real data)
        function fetchRecentEvents() {
            var allEvents = [];
            var currentPage = 1;
            var maxPages = 3;

            function fetchEventsPage() {
                getUserEvents(username, function(data, error) {
                    if (error || !data || !Array.isArray(data)) {
                        completedRequests++;
                        checkCompletion();
                        return;
                    }

                    allEvents = allEvents.concat(data);

                    if (data.length === 100 && currentPage < maxPages) {
                        currentPage++;
                        fetchEventsPage();
                    } else {
                        processAllEvents(allEvents);
                        completedRequests++;
                        checkCompletion();
                    }
                }, currentPage, 100);
            }

            fetchEventsPage();
        }

        function processAllEvents(events) {
            for (var i = 0; i < events.length; i++) {
                var event = events[i];
                if (event.type === "PushEvent" && event.created_at) {
                    var date = new Date(event.created_at);
                    var dateKey = date.getFullYear() + "-" +
                                String(date.getMonth() + 1).padStart(2, '0') + "-" +
                                String(date.getDate()).padStart(2, '0');

                    if (!commitsByDate[dateKey]) {
                        commitsByDate[dateKey] = 0;
                    }

                    var commitCount = event.payload && event.payload.commits ? event.payload.commits.length : 1;
                    commitsByDate[dateKey] += commitCount;
                }
            }
        }

        // Estimate historical activity from repository patterns
        function estimateHistoricalActivity() {
            getUserRepositories(username, 1, 30, function(data, error) {
                if (!error && data && Array.isArray(data)) {
                    addEstimatedHistoricalCommits(data, commitsByDate);
                }
                completedRequests++;
                checkCompletion();
            });
        }

        function checkCompletion() {
            if (completedRequests >= totalRequests) {
                callback(generateCommitActivityData(commitsByDate), null);
            }
        }

        fetchRecentEvents();
        estimateHistoricalActivity();
    }

    function addEstimatedHistoricalCommits(repositories, commitsByDate) {
        var today = new Date();
        var oneYearAgo = new Date(today);
        oneYearAgo.setFullYear(today.getFullYear() - 1);

        for (var i = 0; i < repositories.length; i++) {
            var repo = repositories[i];
            if (!repo.updated_at || !repo.created_at) continue;

            var lastUpdate = new Date(repo.updated_at);
            var createdDate = new Date(repo.created_at);

            // Only consider repos that had activity in the last year
            if (lastUpdate > oneYearAgo) {
                // Estimate activity based on repository characteristics
                var estimatedCommitsPerWeek = Math.min(
                    Math.floor((repo.size || 0) / 100) + 1, // Based on repo size
                    repo.stargazers_count > 10 ? 5 : 2      // Popular repos get more commits
                );

                // Distribute estimated commits over time
                var weeksActive = Math.min(52, Math.floor((lastUpdate - Math.max(createdDate, oneYearAgo)) / (7 * 24 * 60 * 60 * 1000)));

                for (var w = 0; w < weeksActive; w += 2) { // Every 2 weeks
                    var estimateDate = new Date(lastUpdate);
                    estimateDate.setDate(estimateDate.getDate() - (w * 7));

                    if (estimateDate < oneYearAgo) break;

                    var dateKey = estimateDate.getFullYear() + "-" +
                                String(estimateDate.getMonth() + 1).padStart(2, '0') + "-" +
                                String(estimateDate.getDate()).padStart(2, '0');

                    // Only add estimates where we don't have real data
                    if (!commitsByDate[dateKey]) {
                        commitsByDate[dateKey] = Math.floor(Math.random() * estimatedCommitsPerWeek) + 1;
                    }
                }
            }
        }
    }

    function generateCommitActivityData(commitsByDate) {
        var today = new Date();
        var oneYearAgo = new Date(today);
        oneYearAgo.setFullYear(today.getFullYear() - 1);

        var activityData = [];
        var maxCommits = 0;

        // Generate data for each day in the last year
        for (var d = new Date(oneYearAgo); d <= today; d.setDate(d.getDate() + 1)) {
            var dateKey = d.getFullYear() + "-" +
                         String(d.getMonth() + 1).padStart(2, '0') + "-" +
                         String(d.getDate()).padStart(2, '0');

            var commits = commitsByDate[dateKey] || 0;
            maxCommits = Math.max(maxCommits, commits);

            activityData.push({
                date: dateKey,
                commits: commits,
                dayOfWeek: d.getDay(),
                weekOfYear: getWeekOfYear(d)
            });
        }

        // Normalize activity levels (0-1 scale)
        for (var i = 0; i < activityData.length; i++) {
            activityData[i].activity = maxCommits > 0 ? activityData[i].commits / maxCommits : 0;
        }

        return {
            data: activityData,
            maxCommits: maxCommits,
            totalDays: activityData.length,
            totalCommits: Object.values(commitsByDate).reduce(function (a, b) {
                return a + b;
            }, 0)
        };
    }

    function getWeekOfYear(date) {
        var d = new Date(date);
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
        var week1 = new Date(d.getFullYear(), 0, 4);
        return 1 + Math.round(((d.getTime() - week1.getTime()) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
    }

    // Validation helpers
    function isValidToken() {
        return token && token.length > 0;
    }

    function isValidUsername() {
        return username && username.length > 0;
    }

    function isConfigured() {
        return isValidToken() && isValidUsername();
    }

    // Rate limit helpers
    function getRateLimitStatus() {
        return {
            remaining: rateLimitRemaining,
            reset: rateLimitReset,
            resetDate: rateLimitReset > 0 ? new Date(rateLimitReset * 1000) : null
        };
    }

    function isRateLimited() {
        return rateLimitRemaining !== -1 && rateLimitRemaining <= 0;
    }

    // Get user profile README
    function getUserProfileReadme(username, callback) {
        var url = baseUrl + "/repos/" + encodeURIComponent(username) + "/" + encodeURIComponent(username) + "/readme";
        makeRequest(url, callback);
    }

    // Global search methods
    function searchRepositories(query, page = 1, perPage = 10, callback) {
        var url = baseUrl + "/search/repositories";
        url += "?q=" + encodeURIComponent(query);
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function globalSearchIssues(query, page = 1, perPage = 10, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query + " is:issue");
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }

    function globalSearchPullRequests(query, page = 1, perPage = 10, callback) {
        var url = baseUrl + "/search/issues";
        url += "?q=" + encodeURIComponent(query + " is:pr");
        url += "&per_page=" + perPage + "&page=" + page + "&sort=updated";
        makeRequest(url, callback);
    }
}
