#pragma once

#include <QObject>
#include <QString>
#include <QHash>
#include <QLocale>
#include <QtQml/qqml.h>

class I18nBackend final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(I18n)
    QML_SINGLETON

    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged FINAL)
    Q_PROPERTY(QString currentLanguage READ currentLanguage NOTIFY languageChanged FINAL)
    Q_PROPERTY(QString systemLanguage READ systemLanguage CONSTANT FINAL)
    Q_PROPERTY(bool isItalian READ isItalian NOTIFY languageChanged FINAL)
    Q_PROPERTY(bool isEnglish READ isEnglish NOTIFY languageChanged FINAL)
    Q_PROPERTY(bool isGerman READ isGerman NOTIFY languageChanged FINAL)
    Q_PROPERTY(bool isSpanish READ isSpanish NOTIFY languageChanged FINAL)
    Q_PROPERTY(bool isFrench READ isFrench NOTIFY languageChanged FINAL)

public:
    explicit I18nBackend(QObject *parent = nullptr);
    static I18nBackend *instance();

    QString language() const;
    void setLanguage(const QString &lang);

    QString currentLanguage() const;
    QString systemLanguage() const;
    bool isItalian() const;
    bool isEnglish() const;
    bool isGerman() const;
    bool isSpanish() const;
    bool isFrench() const;

    Q_INVOKABLE QString tr(const QString &text) const;
    Q_INVOKABLE QString t(const QString &text) const { return tr(text); }

signals:
    void languageChanged();

private:
    void initTranslations();
    QString detectSystemLanguage() const;

    static I18nBackend *s_instance;
    QString m_language = QStringLiteral("auto");
    QString m_systemLanguage;
    QHash<QString, QHash<QString, QString>> m_translations;
};
