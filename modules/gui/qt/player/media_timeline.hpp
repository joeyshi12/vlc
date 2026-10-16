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
#ifndef QT_MEDIA_TIMELINE_HPP
#define QT_MEDIA_TIMELINE_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QList>
#include <QString>
#include <QTimer>
#include <QVariantList>

#include <memory>

#include "qt.hpp"

struct MediaTimelineScan;

/**
 * Reads the current local media file once in the background, without
 * playing it, to collect:
 *  - the audio level over time, drawn as a waveform on the seek bar;
 *  - the start and end time of every subtitle line, drawn on the seek bar.
 *
 * The file is read by a second player whose stream output is
 * "transcode" (audio decoded to 16 bit mono) followed by the
 * "qt_media_timeline" stream output declared by this plugin. Stream output
 * is not paced by the clock, so the file is read as fast as possible.
 *
 * Only local files are read, so network streams are never downloaded twice.
 */
class MediaTimeline : public QObject
{
    Q_OBJECT

    // Set by QML when a seek bar needs the data. No scan runs while false.
    Q_PROPERTY(bool waveformRequested READ waveformRequested WRITE setWaveformRequested NOTIFY requestChanged FINAL)
    Q_PROPERTY(bool subtitlesRequested READ subtitlesRequested WRITE setSubtitlesRequested NOTIFY requestChanged FINAL)

    // Part of the media read so far, from 0 to 1.
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged FINAL)
    Q_PROPERTY(bool hasWaveform READ hasWaveform NOTIFY waveformChanged FINAL)

    // Subtitle lines of the selected subtitle track, as a list of
    // { start, end } objects. Both values are positions from 0 to 1.
    Q_PROPERTY(QVariantList subtitleCues READ subtitleCues NOTIFY subtitleCuesChanged FINAL)

public:
    MediaTimeline(qt_intf_t *intf, QObject *parent = nullptr);
    ~MediaTimeline() override;

    bool waveformRequested() const { return m_waveformRequested; }
    bool subtitlesRequested() const { return m_subtitlesRequested; }
    void setWaveformRequested(bool);
    void setSubtitlesRequested(bool);

    double progress() const { return m_progress; }
    bool hasWaveform() const { return m_hasWaveform; }
    QVariantList subtitleCues() const { return m_subtitleCues; }

    // Audio level for `count` equal parts of the media, from 0 to 1.
    // Parts that are not read yet are -1.
    Q_INVOKABLE QList<qreal> waveform(int count) const;

signals:
    void requestChanged();
    void progressChanged();
    void waveformChanged();
    void subtitleCuesChanged();

private:
    void update();
    void startScan(const QString &uri);
    void stopScan();
    void updateSubtitleCues(bool force);

    qt_intf_t *m_intf = nullptr;
    QTimer m_timer;

    bool m_waveformRequested = false;
    bool m_subtitlesRequested = false;

    // Media the data below belongs to.
    QString m_uri;
    // Whether the current data was read with audio decoding.
    bool m_scannedAudio = false;
    bool m_scannedSubtitles = false;

    std::unique_ptr<MediaTimelineScan> m_scan;

    double m_progress = 0.0;
    bool m_hasWaveform = false;
    QVariantList m_subtitleCues;
    QString m_cuesTrackId;
    size_t m_cuesCount = 0;

    // Copy of the scanned data, used from the GUI thread only.
    QList<float> m_peaks;          // one value per MediaTimelineScan::PEAK_INTERVAL
    float m_peakMax = 0.f;
};

#endif // QT_MEDIA_TIMELINE_HPP
