/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifndef VLC_QT_CONFIG_OPTION_HPP
#define VLC_QT_CONFIG_OPTION_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QString>

class MainCtx;

/**
 * One option of the VLC configuration, for the settings pages.
 *
 * Set `name` to the name of the option ("fullscreen", "qt-system-tray", ...).
 * `value` reads and writes the option. `choices` lists the values that the
 * option accepts, as objects with `value` and `text`, when the option has a
 * list. `available` is false when no loaded module has this option, so the
 * page can hide the row.
 *
 * The configuration file is written with ConfigOption.save().
 */
class ConfigOption : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged FINAL)
    Q_PROPERTY(bool available READ available NOTIFY nameChanged FINAL)
    Q_PROPERTY(Type type READ type NOTIFY nameChanged FINAL)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged FINAL)
    Q_PROPERTY(QVariantList choices READ choices NOTIFY nameChanged FINAL)
    Q_PROPERTY(double minimum READ minimum NOTIFY nameChanged FINAL)
    Q_PROPERTY(double maximum READ maximum NOTIFY nameChanged FINAL)
    Q_PROPERTY(QString text READ text NOTIFY nameChanged FINAL)
    Q_PROPERTY(QString longText READ longText NOTIFY nameChanged FINAL)

public:
    enum Type { None, Bool, Integer, Float, String };
    Q_ENUM(Type)

    explicit ConfigOption(QObject *parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString &name);

    bool available() const { return m_type != None; }
    Type type() const { return m_type; }

    QVariant value() const;
    void setValue(const QVariant &value);

    QVariantList choices() const;
    double minimum() const;
    double maximum() const;
    QString text() const;
    QString longText() const;

    /// Asks for a file or a folder, for the options that are paths, and sets the value
    Q_INVOKABLE void browse();

    /// The hotkey options of VLC, as objects with \c name (option of the key),
    /// \c global (option of the global key, or empty) and \c text
    Q_INVOKABLE static QVariantList hotkeys();

    /// Name of a key pressed in QML, as stored in the hotkey options ("Ctrl+q")
    Q_INVOKABLE static QString keyName(int key, int modifiers, const QString &text);

    /// Value of a string option
    Q_INVOKABLE static QString stringValue(const QString &name);

    /// Keys of a hotkey option, separated by tabs, as shown to the user
    Q_INVOKABLE static QString keysText(const QString &keys);

    /// Shows the directory of the configuration file in the file manager
    Q_INVOKABLE static void openConfigDirectory();

    /// Puts the option back to its default value
    Q_INVOKABLE void resetToDefault();

    /// Writes the configuration file
    Q_INVOKABLE static void save(MainCtx *ctx);

    /// Puts every option back to its default value and writes the file
    Q_INVOKABLE static void resetAll(MainCtx *ctx);

    /// Directory of the configuration file
    Q_INVOKABLE static QString configDirectory();

signals:
    void nameChanged();
    void valueChanged();

private:
    QString m_name;
    Type m_type = None;
};

#endif
