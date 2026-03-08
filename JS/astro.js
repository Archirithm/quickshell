.pragma library

var RAD = Math.PI / 180;

// 角度规约：防止时间积累导致角度无限大，引发坐标崩溃
function rev(angle) {
    return angle - Math.floor(angle / 360.0) * 360.0;
}

function getJulianDay(date) {
    return date.getTime() / 86400000 + 2440587.5;
}

function getSunPosition(date, lat, lon) {
    var d = getJulianDay(date) - 2451545.0;
    var M = rev(357.5291 + 0.98560028 * d);
    var L = rev(280.4665 + 0.98564736 * d);
    
    var lambda = L + 1.9148 * Math.sin(M * RAD) + 0.0200 * Math.sin(2 * M * RAD);
    var obliq = 23.439 - 0.00000036 * d;
    
    var alpha = Math.atan2(Math.cos(obliq * RAD) * Math.sin(lambda * RAD), Math.cos(lambda * RAD));
    var delta = Math.asin(Math.sin(obliq * RAD) * Math.sin(lambda * RAD));
    
    var GMST = 18.697374558 + 24.06570982441908 * d;
    var LMST = rev((GMST * 15) + lon) * RAD;
    var H = LMST - alpha;
    var phi = lat * RAD;
    
    var altitude = Math.asin(Math.sin(phi) * Math.sin(delta) + Math.cos(phi) * Math.cos(delta) * Math.cos(H));
    var azimuth = Math.atan2(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(delta) * Math.cos(phi)) + Math.PI;
    
    return { az: azimuth, alt: altitude };
}

function getMoonPosition(date, lat, lon) {
    var d = getJulianDay(date) - 2451545.0;
    
    var L = rev(218.316 + 13.176396 * d);
    var M = rev(134.963 + 13.064993 * d);
    var F = rev(93.272 + 13.229350 * d);
    
    var l = L + 6.289 * Math.sin(M * RAD);
    var b = 5.128 * Math.sin(F * RAD);
    var obliq = 23.439 - 0.00000036 * d;
    
    var ra = Math.atan2(Math.sin(l * RAD) * Math.cos(obliq * RAD) - Math.tan(b * RAD) * Math.sin(obliq * RAD), Math.cos(l * RAD));
    var dec = Math.asin(Math.sin(b * RAD) * Math.cos(obliq * RAD) + Math.cos(b * RAD) * Math.sin(obliq * RAD) * Math.sin(l * RAD));
    
    var GMST = 18.697374558 + 24.06570982441908 * d;
    var LMST = rev((GMST * 15) + lon) * RAD;
    var H = LMST - ra;
    var phi = lat * RAD;
    
    var altitude = Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H));
    var azimuth = Math.atan2(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi)) + Math.PI;
    
    return { az: azimuth, alt: altitude };
}
