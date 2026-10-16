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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "config_option.hpp"

#include "maininterface/mainctx.hpp"
#include "qt.hpp"

#include <vlc_configuration.h>
#include <vlc_variables.h>
#include <vlc_plugin.h>

#include <QVariantMap>
#include <QKeyEvent>

#include "util/vlchotkeyconverter.hpp"
#include <vlc_modules.h>
#include <vlc_actions.h>
#include <QDesktopServices>
#include <QFileDialog>
#include <QUrl>

ConfigOption::ConfigOption(QObject *parent)
    : QObject(parent)
{
}

void ConfigOption::setName(const QString &name)
{
    if (name == m_name)
        return;
    m_name = name;

    switch (config_GetType(qtu(m_name)))
    {
    case VLC_VAR_BOOL:    m_type = Bool; break;
    case VLC_VAR_INTEGER: m_type = Integer; break;
    case VLC_VAR_FLOAT:   m_type = Float; break;
    case VLC_VAR_STRING:  m_type = String; break;
    default:              m_type = None; break;
    }

    emit nameChanged();
    emit valueChanged();
}

QVariant ConfigOption::value() const
{
    const QByteArray name = m_name.toUtf8();
    switch (m_type)
    {
    case Bool:
        return config_GetInt(name.constData()) != 0;
    case Integer:
        return QVariant::fromValue<qint64>(config_GetInt(name.constData()));
    case Float:
        return config_GetFloat(name.constData());
    case String:
    {
        char *psz = config_GetPsz(name.constData());
        const QString str = qfu(psz);
        free(psz);
        return str;
    }
    default:
        return {};
    }
}

void ConfigOption::setValue(const QVariant &value)
{
    if (m_type == None || value == this->value())
        return;

    const QByteArray name = m_name.toUtf8();
    switch (m_type)
    {
    case Bool:
        config_PutInt(name.constData(), value.toBool() ? 1 : 0);
        break;
    case Integer:
        config_PutInt(name.constData(), value.toLongLong());
        break;
    case Float:
        config_PutFloat(name.constData(), value.toFloat());
        break;
    case String:
        config_PutPsz(name.constData(), qtu(value.toString()));
        break;
    default:
        return;
    }
    emit valueChanged();
}

QVariantList ConfigOption::choices() const
{
    QVariantList list;
    const QByteArray name = m_name.toUtf8();

    if (m_type == Integer)
    {
        int64_t *values = nullptr;
        char **texts = nullptr;
        const ssize_t count = config_GetIntChoices(name.constData(), &values, &texts);
        for (ssize_t i = 0; i < count; ++i)
        {
            list.append(QVariantMap{ { "value", QVariant::fromValue<qint64>(values[i]) },
                                     { "text", qfu(texts[i]) } });
            free(texts[i]);
        }
        free(values);
        free(texts);
    }
    else if (m_type == String)
    {
        char **values = nullptr;
        char **texts = nullptr;
        const ssize_t count = config_GetPszChoices(name.constData(), &values, &texts);
        for (ssize_t i = 0; i < count; ++i)
        {
            list.append(QVariantMap{ { "value", qfu(values[i]) },
                                     { "text", qfu(texts[i]) } });
            free(values[i]);
            free(texts[i]);
        }
        free(values);
        free(texts);
    }
    return list;
}

double ConfigOption::minimum() const
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    if (!config)
        return 0;
    if (m_type == Float)
        return config->min.f;
    if (m_type == Integer)
        return static_cast<double>(config->min.i);
    return 0;
}

double ConfigOption::maximum() const
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    if (!config)
        return 0;
    if (m_type == Float)
        return config->max.f;
    if (m_type == Integer)
        return static_cast<double>(config->max.i);
    return 0;
}

QString ConfigOption::text() const
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    return (config && config->psz_text) ? qfut(config->psz_text) : QString();
}

QString ConfigOption::longText() const
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    return (config && config->psz_longtext) ? qfut(config->psz_longtext) : QString();
}

void ConfigOption::browse()
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    if (!config || m_type != String)
        return;

    const QString current = value().toString();
    QString path;
    switch (config->i_type)
    {
    case CONFIG_ITEM_DIRECTORY:
        path = QFileDialog::getExistingDirectory(nullptr, text(), current);
        break;
    case CONFIG_ITEM_SAVEFILE:
        path = QFileDialog::getSaveFileName(nullptr, text(), current);
        break;
    default:
        path = QFileDialog::getOpenFileName(nullptr, text(), current);
        break;
    }
    if (!path.isEmpty())
        setValue(path);
}

QVariantList ConfigOption::hotkeys()
{
    QVariantList list;
    module_t *main = module_get_main();
    unsigned count = 0;
    module_config_t *config = module_config_get(main, &count);

    QStringList globals;
    for (unsigned i = 0; i < count; ++i)
    {
        if (config[i].i_type == CONFIG_ITEM_KEY && strncmp(config[i].psz_name, "global-", 7) == 0)
            globals << qfu(config[i].psz_name);
    }

    for (unsigned i = 0; i < count; ++i)
    {
        const module_config_t &item = config[i];
        if (item.i_type != CONFIG_ITEM_KEY || strncmp(item.psz_name, "global-", 7) == 0)
            continue;

        const QString name = qfu(item.psz_name);
        const QString global = QStringLiteral("global-") + name;
        list.append(QVariantMap{ { "name", name },
                                 { "global", globals.contains(global) ? global : QString() },
                                 { "text", item.psz_text ? qfut(item.psz_text) : name } });
    }
    module_config_free(config);
    return list;
}

QString ConfigOption::keyName(int key, int modifiers, const QString &text)
{
    QKeyEvent event(QEvent::KeyPress, key, Qt::KeyboardModifiers(modifiers), text);
    const int vlcKey = qtEventToVLCKey(&event);
    return VLCKeyToString(vlcKey, false);
}

QString ConfigOption::stringValue(const QString &name)
{
    char *psz = config_GetPsz(qtu(name));
    const QString value = qfu(psz);
    free(psz);
    return value;
}

QString ConfigOption::keysText(const QString &keys)
{
    QStringList out;
    for (const QString &key : keys.split('\t', Qt::SkipEmptyParts))
    {
        const uint code = vlc_str2keycode(qtu(key));
        out << ((code != KEY_UNSET) ? VLCKeyToString(code, true) : key);
    }
    return out.join(QStringLiteral(", "));
}

void ConfigOption::openConfigDirectory()
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(configDirectory()));
}

void ConfigOption::resetToDefault()
{
    const module_config_t *config = config_FindConfig(qtu(m_name));
    if (!config)
        return;
    switch (m_type)
    {
    case Bool:
    case Integer:
        config_PutInt(config->psz_name, config->orig.i);
        break;
    case Float:
        config_PutFloat(config->psz_name, config->orig.f);
        break;
    case String:
        config_PutPsz(config->psz_name, config->orig.psz);
        break;
    default:
        return;
    }
    emit valueChanged();
}

void ConfigOption::save(MainCtx *ctx)
{
    if (!ctx)
        return;
    config_SaveConfigFile(ctx->getIntf());
    ctx->reloadPrefs();
}

void ConfigOption::resetAll(MainCtx *ctx)
{
    config_ResetAll();
    save(ctx);
}

QString ConfigOption::configDirectory()
{
    char *dir = config_GetUserDir(VLC_CONFIG_DIR);
    const QString path = qfu(dir);
    free(dir);
    return path;
}
