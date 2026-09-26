#pragma once

#include <QNetworkRequest>
#include <QString>

namespace lyricsmpris {

inline void applyProviderNetworkPolicy(QNetworkRequest &request, const QString &provider) {
    if (provider == QLatin1String("netease")) {
        // music.163.com sets a long-lived NMTID cookie whose reuse can make a
        // later search return results for an unrelated query. Lyrics lookups
        // are stateless, so never load or persist provider cookies.
        request.setAttribute(QNetworkRequest::CookieLoadControlAttribute, QNetworkRequest::Manual);
        request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
        request.setRawHeader("Referer", "https://music.163.com/");
    } else if (provider == QLatin1String("qq")) {
        request.setRawHeader("Referer", "https://y.qq.com/");
    } else if (provider == QLatin1String("kugou")) {
        request.setRawHeader("Referer", "https://www.kugou.com/");
    }
}

} // namespace lyricsmpris
