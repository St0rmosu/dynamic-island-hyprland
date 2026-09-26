#pragma once

#include <QColor>
#include <QObject>
#include <QtQml/qqml.h>

class StyleTokensBackend final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(StyleTokens)
    QML_SINGLETON

    Q_PROPERTY(QColor transparent READ transparent CONSTANT FINAL)
    Q_PROPERTY(QColor black READ black CONSTANT FINAL)
    Q_PROPERTY(QColor white READ white CONSTANT FINAL)
    Q_PROPERTY(QColor clearBlack READ clearBlack CONSTANT FINAL)

    Q_PROPERTY(QColor panel READ panel CONSTANT FINAL)
    Q_PROPERTY(QColor module READ module CONSTANT FINAL)
    Q_PROPERTY(QColor moduleHover READ moduleHover CONSTANT FINAL)
    Q_PROPERTY(QColor track READ track CONSTANT FINAL)
    Q_PROPERTY(QColor cardFillActive READ cardFillActive CONSTANT FINAL)
    Q_PROPERTY(QColor cardFillHover READ cardFillHover CONSTANT FINAL)
    Q_PROPERTY(QColor connectivityCard READ connectivityCard CONSTANT FINAL)
    Q_PROPERTY(QColor connectivityCardHover READ connectivityCardHover CONSTANT FINAL)
    Q_PROPERTY(QColor prompt READ prompt CONSTANT FINAL)
    Q_PROPERTY(QColor input READ input CONSTANT FINAL)
    Q_PROPERTY(QColor inputBorder READ inputBorder CONSTANT FINAL)
    Q_PROPERTY(QColor secondaryButton READ secondaryButton CONSTANT FINAL)

    Q_PROPERTY(QColor textPrimary READ textPrimary CONSTANT FINAL)
    Q_PROPERTY(QColor textPrimaryBright READ textPrimaryBright CONSTANT FINAL)
    Q_PROPERTY(QColor textSecondary READ textSecondary CONSTANT FINAL)
    Q_PROPERTY(QColor textMuted READ textMuted CONSTANT FINAL)
    Q_PROPERTY(QColor textSoft READ textSoft CONSTANT FINAL)
    Q_PROPERTY(QColor textTertiary READ textTertiary CONSTANT FINAL)
    Q_PROPERTY(QColor textDisabled READ textDisabled CONSTANT FINAL)
    Q_PROPERTY(QColor textSubtle READ textSubtle CONSTANT FINAL)
    Q_PROPERTY(QColor textDim READ textDim CONSTANT FINAL)

    Q_PROPERTY(QColor accent READ accent CONSTANT FINAL)
    Q_PROPERTY(QColor accentPressed READ accentPressed CONSTANT FINAL)
    Q_PROPERTY(QColor accentSoft READ accentSoft CONSTANT FINAL)
    Q_PROPERTY(QColor success READ success CONSTANT FINAL)
    Q_PROPERTY(QColor warning READ warning CONSTANT FINAL)
    Q_PROPERTY(QColor danger READ danger CONSTANT FINAL)
    Q_PROPERTY(QColor error READ error CONSTANT FINAL)
    Q_PROPERTY(QColor disabledControl READ disabledControl CONSTANT FINAL)
    Q_PROPERTY(QColor switchOff READ switchOff CONSTANT FINAL)

    Q_PROPERTY(QColor buttonFill READ buttonFill CONSTANT FINAL)
    Q_PROPERTY(QColor buttonFillHover READ buttonFillHover CONSTANT FINAL)
    Q_PROPERTY(QColor buttonFillPressed READ buttonFillPressed CONSTANT FINAL)

    Q_PROPERTY(QColor overviewCard READ overviewCard CONSTANT FINAL)
    Q_PROPERTY(QColor overviewBorder READ overviewBorder CONSTANT FINAL)
    Q_PROPERTY(QColor overviewInnerBorder READ overviewInnerBorder CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceCell READ workspaceCell CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceCellHover READ workspaceCellHover CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceCellBorder READ workspaceCellBorder CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceCellBorderHover READ workspaceCellBorderHover CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceOverlay READ workspaceOverlay CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceOverlayHover READ workspaceOverlayHover CONSTANT FINAL)
    Q_PROPERTY(QColor workspaceActiveBorder READ workspaceActiveBorder CONSTANT FINAL)

    Q_PROPERTY(int radiusPanel READ radiusPanel CONSTANT FINAL)
    Q_PROPERTY(int radiusModule READ radiusModule CONSTANT FINAL)
    Q_PROPERTY(int radiusPrompt READ radiusPrompt CONSTANT FINAL)
    Q_PROPERTY(int radiusButton READ radiusButton CONSTANT FINAL)
    Q_PROPERTY(int durationFast READ durationFast CONSTANT FINAL)
    Q_PROPERTY(int durationControl READ durationControl CONSTANT FINAL)
    Q_PROPERTY(int durationQuick READ durationQuick CONSTANT FINAL)
    Q_PROPERTY(int durationStandard READ durationStandard CONSTANT FINAL)

public:
    explicit StyleTokensBackend(QObject *parent = nullptr);

    QColor transparent() const;
    QColor black() const;
    QColor white() const;
    QColor clearBlack() const;
    QColor panel() const;
    QColor module() const;
    QColor moduleHover() const;
    QColor track() const;
    QColor cardFillActive() const;
    QColor cardFillHover() const;
    QColor connectivityCard() const;
    QColor connectivityCardHover() const;
    QColor prompt() const;
    QColor input() const;
    QColor inputBorder() const;
    QColor secondaryButton() const;
    QColor textPrimary() const;
    QColor textPrimaryBright() const;
    QColor textSecondary() const;
    QColor textMuted() const;
    QColor textSoft() const;
    QColor textTertiary() const;
    QColor textDisabled() const;
    QColor textSubtle() const;
    QColor textDim() const;
    QColor accent() const;
    QColor accentPressed() const;
    QColor accentSoft() const;
    QColor success() const;
    QColor warning() const;
    QColor danger() const;
    QColor error() const;
    QColor disabledControl() const;
    QColor switchOff() const;
    QColor buttonFill() const;
    QColor buttonFillHover() const;
    QColor buttonFillPressed() const;
    QColor overviewCard() const;
    QColor overviewBorder() const;
    QColor overviewInnerBorder() const;
    QColor workspaceCell() const;
    QColor workspaceCellHover() const;
    QColor workspaceCellBorder() const;
    QColor workspaceCellBorderHover() const;
    QColor workspaceOverlay() const;
    QColor workspaceOverlayHover() const;
    QColor workspaceActiveBorder() const;

    int radiusPanel() const;
    int radiusModule() const;
    int radiusPrompt() const;
    int radiusButton() const;
    int durationFast() const;
    int durationControl() const;
    int durationQuick() const;
    int durationStandard() const;
};
