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

#include "media_timeline.hpp"

#include <vlc_common.h>
#include <vlc_player.h>
#include <vlc_input_item.h>
#include <vlc_es.h>
#include <vlc_block.h>
#include <vlc_sout.h>
#include <vlc_cxx_helpers.hpp>

using vlc_player_locker = vlc_locker<vlc_player_t, vlc_player_Lock, vlc_player_Unlock>;

#include <QVariantMap>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <map>
#include <mutex>
#include <string>
#include <vector>

namespace {

constexpr const char *SINK_VARIABLE = "qt-media-timeline-sink";

// Length of the media covered by one audio level value.
constexpr vlc_tick_t PEAK_INTERVAL = VLC_TICK_FROM_MS(50);

// A subtitle line without a length is shown until the next line, up to this.
constexpr vlc_tick_t DEFAULT_CUE_LENGTH = VLC_TICK_FROM_SEC(4);

struct Cue
{
    vlc_tick_t start; // stream timestamp
    vlc_tick_t end;
};

// Data written by the stream output (input threads) and read by the GUI thread.
struct TimelineSink
{
    std::mutex lock;

    // Timestamp of the first audio block, used as the start of the media.
    vlc_tick_t base = VLC_TICK_INVALID;
    // Largest media time read so far, relative to `base`.
    vlc_tick_t readTime = 0;

    std::vector<float> peaks;
    std::map<std::string, std::vector<Cue>> cues; // by ES string identifier

    bool hasDecodedAudio = false;

    bool done = false;
};

enum class StreamKind { DecodedAudio, EncodedAudio, Subtitle };

struct StreamId
{
    StreamKind kind;
    std::string esId;
    unsigned channels = 1;
    unsigned rate = 0;
};

vlc_tick_t blockTime(const block_t *block)
{
    return (block->i_pts != VLC_TICK_INVALID) ? block->i_pts : block->i_dts;
}

void *StreamAdd(sout_stream_t *stream, const es_format_t *fmt, const char *es_id)
{
    auto sink = static_cast<TimelineSink *>(stream->p_sys);

    StreamId *id = nullptr;
    if (fmt->i_cat == AUDIO_ES)
    {
        const bool decoded = (fmt->i_codec == VLC_CODEC_S16N) && fmt->audio.i_channels > 0
                             && fmt->audio.i_rate > 0;

        // Only the first decoded audio track is used for the audio level.
        std::lock_guard<std::mutex> guard(sink->lock);
        if (decoded && sink->hasDecodedAudio)
            return nullptr;
        if (decoded)
            sink->hasDecodedAudio = true;

        id = new (std::nothrow) StreamId{ decoded ? StreamKind::DecodedAudio : StreamKind::EncodedAudio,
                                          es_id ? es_id : "", fmt->audio.i_channels, fmt->audio.i_rate };
    }
    else if (fmt->i_cat == SPU_ES)
    {
        id = new (std::nothrow) StreamId{ StreamKind::Subtitle, es_id ? es_id : "" };
        if (id)
        {
            std::lock_guard<std::mutex> guard(sink->lock);
            sink->cues[id->esId]; // list the track even if it has no lines
        }
    }
    return id;
}

void StreamDel(sout_stream_t *, void *id)
{
    delete static_cast<StreamId *>(id);
}

void addPeaks(TimelineSink *sink, const StreamId *id, const block_t *block, vlc_tick_t time)
{
    const auto samples = reinterpret_cast<const int16_t *>(block->p_buffer);
    const size_t frames = block->i_buffer / (sizeof(int16_t) * id->channels);
    if (frames == 0)
        return;

    const vlc_tick_t endTime = time + vlc_tick_from_samples(frames, id->rate);
    const size_t lastBucket = endTime / PEAK_INTERVAL;
    if (sink->peaks.size() <= lastBucket)
        sink->peaks.resize(lastBucket + 1, 0.f);

    for (size_t i = 0; i < frames; ++i)
    {
        const size_t bucket = (time + vlc_tick_from_samples(i, id->rate)) / PEAK_INTERVAL;
        int peak = 0;
        for (unsigned c = 0; c < id->channels; ++c)
            peak = std::max(peak, std::abs(int(samples[i * id->channels + c])));
        sink->peaks[bucket] = std::max(sink->peaks[bucket], peak / 32768.f);
    }
    sink->readTime = std::max(sink->readTime, endTime);
}

int StreamSend(sout_stream_t *stream, void *_id, block_t *chain)
{
    auto sink = static_cast<TimelineSink *>(stream->p_sys);
    auto id = static_cast<StreamId *>(_id);

    {
        std::lock_guard<std::mutex> guard(sink->lock);

        for (block_t *block = chain; block != nullptr; block = block->p_next)
        {
            const vlc_tick_t ts = blockTime(block);
            if (ts == VLC_TICK_INVALID)
                continue;

            switch (id->kind)
            {
            case StreamKind::DecodedAudio:
            case StreamKind::EncodedAudio:
                if (sink->base == VLC_TICK_INVALID)
                    sink->base = ts;
                if (ts < sink->base)
                    break;
                if (id->kind == StreamKind::DecodedAudio)
                    addPeaks(sink, id, block, ts - sink->base);
                else
                    sink->readTime = std::max(sink->readTime, ts - sink->base);
                break;

            case StreamKind::Subtitle:
            {
                auto &cues = sink->cues[id->esId];
                if (!cues.empty() && cues.back().end == VLC_TICK_INVALID)
                    cues.back().end = std::min(ts, cues.back().start + DEFAULT_CUE_LENGTH);

                // Empty blocks only clear the previous line.
                if (block->i_buffer > 0)
                    cues.push_back({ ts, block->i_length > 0 ? ts + block->i_length
                                                              : VLC_TICK_INVALID });
                break;
            }
            }
        }
    }

    block_ChainRelease(chain);
    return VLC_SUCCESS;
}

void StreamClose(sout_stream_t *stream)
{
    auto sink = static_cast<TimelineSink *>(stream->p_sys);
    std::lock_guard<std::mutex> guard(sink->lock);
    for (auto &[esId, cues] : sink->cues)
    {
        if (!cues.empty() && cues.back().end == VLC_TICK_INVALID)
            cues.back().end = cues.back().start + DEFAULT_CUE_LENGTH;
    }
    sink->done = true;
}

const struct sout_stream_operations streamOps = []() {
    sout_stream_operations ops{};
    ops.add = StreamAdd;
    ops.del = StreamDel;
    ops.send = StreamSend;
    ops.close = StreamClose;
    return ops;
}();

} // namespace

// Stream output module "qt_media_timeline", declared in qt.cpp.
int MediaTimelineStreamOpen(vlc_object_t *obj)
{
    auto stream = reinterpret_cast<sout_stream_t *>(obj);
    auto sink = static_cast<TimelineSink *>(var_InheritAddress(obj, SINK_VARIABLE));
    if (sink == nullptr)
        return VLC_EGENERIC;

    stream->p_sys = sink;
    stream->ops = &streamOps;
    return VLC_SUCCESS;
}

// A second player that reads one media through the stream output above.
struct MediaTimelineScan
{
    vlc_object_t *object = nullptr;
    vlc_player_t *player = nullptr;
    TimelineSink sink;

    // Deletes the player. The data read stays in `sink`.
    void finish()
    {
        if (player)
            vlc_player_Delete(player);
        if (object)
            vlc_object_delete(object);
        player = nullptr;
        object = nullptr;
    }

    bool finished() const { return player == nullptr; }

    ~MediaTimelineScan() { finish(); }
};

MediaTimeline::MediaTimeline(qt_intf_t *intf, QObject *parent)
    : QObject(parent)
    , m_intf(intf)
{
    m_timer.setInterval(500);
    connect(&m_timer, &QTimer::timeout, this, &MediaTimeline::update);
}

MediaTimeline::~MediaTimeline() = default;

void MediaTimeline::setWaveformRequested(bool requested)
{
    if (m_waveformRequested == requested)
        return;
    m_waveformRequested = requested;
    emit requestChanged();
    // Wait for the next timer tick, so that a request that changes while
    // the media opens does not start a scan that is stopped right away.
    if (!m_timer.isActive())
        m_timer.start();
}

void MediaTimeline::setSubtitlesRequested(bool requested)
{
    if (m_subtitlesRequested == requested)
        return;
    m_subtitlesRequested = requested;
    emit requestChanged();
    // Wait for the next timer tick, so that a request that changes while
    // the media opens does not start a scan that is stopped right away.
    if (!m_timer.isActive())
        m_timer.start();
}

void MediaTimeline::startScan(const QString &uri)
{
    stopScan();

    // Set before trying, so a media that cannot be read is not retried.
    m_scannedAudio = m_waveformRequested;
    m_scannedSubtitles = m_subtitlesRequested;

#ifdef ENABLE_SOUT
    auto scan = std::make_unique<MediaTimelineScan>();

    scan->object = static_cast<vlc_object_t *>(vlc_object_create(VLC_OBJECT(m_intf), sizeof(vlc_object_t)));
    if (!scan->object)
        return;

    var_Create(scan->object, "vout", VLC_VAR_STRING);
    var_SetString(scan->object, "vout", "dummy");
    var_Create(scan->object, "aout", VLC_VAR_STRING);
    var_SetString(scan->object, "aout", "dummy");
    var_Create(scan->object, SINK_VARIABLE, VLC_VAR_ADDRESS);
    var_SetAddress(scan->object, SINK_VARIABLE, &scan->sink);

    scan->player = vlc_player_New(scan->object, VLC_PLAYER_LOCK_NORMAL);
    if (!scan->player)
        return;

    input_item_t *item = input_item_New(qtu(uri), nullptr);
    if (!item)
        return;

    const bool readAudio = m_waveformRequested;
    const bool readSubtitles = m_subtitlesRequested;

    // Without decoding, the audio track still gives the start time of the media.
    const char *sout = readAudio ? "sout=#transcode{acodec=s16l,channels=1,samplerate=8000}:qt_media_timeline"
                                 : "sout=#qt_media_timeline";
    input_item_AddOption(item, sout, VLC_INPUT_OPTION_TRUSTED);
    // Video stays enabled because subtitle tracks are only selected with it.
    // It is not decoded: video blocks are dropped by the stream output.
    input_item_AddOption(item, "sout-all", VLC_INPUT_OPTION_TRUSTED);
    if (!readSubtitles)
        input_item_AddOption(item, "no-sout-spu", VLC_INPUT_OPTION_TRUSTED);
    // Read the whole media, whatever the options of the main player are.
    input_item_AddOption(item, "start-time=0", VLC_INPUT_OPTION_TRUSTED);
    input_item_AddOption(item, "stop-time=0", VLC_INPUT_OPTION_TRUSTED);
    input_item_AddOption(item, "run-time=0", VLC_INPUT_OPTION_TRUSTED);
    input_item_AddOption(item, "input-repeat=0", VLC_INPUT_OPTION_TRUSTED);

    // Read the subtitle files that were added to the current media.
    {
        vlc_player_locker lock{ m_intf->p_player };
        input_item_t *current = vlc_player_GetCurrentMedia(m_intf->p_player);
        if (current && readSubtitles)
        {
            vlc_mutex_lock(&current->lock);
            for (int i = 0; i < current->i_slaves; ++i)
            {
                const input_item_slave_t *slave = current->pp_slaves[i];
                input_item_slave_t *copy = input_item_slave_New(slave->psz_uri, slave->i_type, slave->i_priority);
                if (copy && input_item_AddSlave(item, copy) != VLC_SUCCESS)
                    input_item_slave_Delete(copy);
            }
            vlc_mutex_unlock(&current->lock);
        }
    }

    {
        vlc_player_locker lock{ scan->player };
        if (vlc_player_SetCurrentMedia(scan->player, item) == VLC_SUCCESS)
            vlc_player_Start(scan->player);
    }
    input_item_Release(item);

    m_scan = std::move(scan);
#else
    // Reading a media in the background needs stream output.
    VLC_UNUSED(uri);
#endif
}

void MediaTimeline::stopScan()
{
    // Deleting the player waits for its input thread to stop.
    m_scan.reset();
}

void MediaTimeline::update()
{
    const bool requested = m_waveformRequested || m_subtitlesRequested;

    if (!requested)
    {
        if (m_scan && !m_scan->finished())
        {
            // Unfinished data is dropped, the next request reads the media again.
            stopScan();
            m_scannedAudio = m_scannedSubtitles = false;
        }
        m_timer.stop();
        return;
    }

    QString uri;
    {
        vlc_player_locker lock{ m_intf->p_player };
        if (input_item_t *media = vlc_player_GetCurrentMedia(m_intf->p_player))
        {
            char *psz = input_item_GetURI(media);
            uri = qfu(psz);
            free(psz);
        }
    }

    if (uri != m_uri)
    {
        stopScan();
        m_uri = uri;
        m_scannedAudio = m_scannedSubtitles = false;
        m_peaks.clear();
        m_peakMax = 0.f;
        m_cuesCount = 0;
        m_cuesTrackId.clear();
        m_subtitleCues.clear();
        m_progress = 0.0;
        m_hasWaveform = false;
        emit waveformChanged();
        emit subtitleCuesChanged();
        emit progressChanged();
    }

    const bool missingData = (m_waveformRequested && !m_scannedAudio)
                             || (m_subtitlesRequested && !m_scannedSubtitles);
    if (requested && missingData && m_uri.startsWith(QLatin1String("file://")))
        startScan(m_uri);

    if (!m_scan)
        return;

    vlc_tick_t length;
    {
        vlc_player_locker lock{ m_intf->p_player };
        length = vlc_player_GetLength(m_intf->p_player);
    }

    bool done;
    {
        std::lock_guard<std::mutex> guard(m_scan->sink.lock);
        done = m_scan->sink.done;

        if (m_scan->sink.peaks.size() != size_t(m_peaks.size()))
        {
            m_peaks = QList<float>(m_scan->sink.peaks.begin(), m_scan->sink.peaks.end());
            m_peakMax = m_peaks.isEmpty() ? 0.f : *std::max_element(m_peaks.cbegin(), m_peaks.cend());
            m_hasWaveform = m_peakMax > 0.f;
            emit waveformChanged();
        }

        const double progress = done ? 1.0
                                     : (length > 0 ? std::min(1.0, double(m_scan->sink.readTime) / length) : 0.0);
        if (progress != m_progress)
        {
            m_progress = progress;
            emit progressChanged();
        }
    }

    updateSubtitleCues(false);

    if (done && !m_scan->finished())
    {
        updateSubtitleCues(true);
        m_scan->finish();
    }
}

void MediaTimeline::updateSubtitleCues(bool force)
{
    if (!m_scan)
        return;

    QString selectedId;
    vlc_tick_t length;
    {
        vlc_player_locker lock{ m_intf->p_player };
        length = vlc_player_GetLength(m_intf->p_player);
        const size_t count = vlc_player_GetSubtitleTrackCount(m_intf->p_player);
        for (size_t i = 0; i < count; ++i)
        {
            const vlc_player_track *track = vlc_player_GetSubtitleTrackAt(m_intf->p_player, i);
            if (track && track->selected)
            {
                selectedId = qfu(vlc_es_id_GetStrId(track->es_id));
                break;
            }
        }
    }

    if (length <= 0)
        return;

    std::lock_guard<std::mutex> guard(m_scan->sink.lock);
    auto &sink = m_scan->sink;

    if (selectedId.isEmpty())
    {
        if (!m_subtitleCues.isEmpty())
        {
            m_subtitleCues.clear();
            m_cuesCount = 0;
            m_cuesTrackId.clear();
            emit subtitleCuesChanged();
        }
        return;
    }

    // Use the selected track, or the first track with lines when the
    // identifiers of the two players do not match.
    auto it = sink.cues.find(selectedId.toStdString());
    if (it == sink.cues.end())
        it = std::find_if(sink.cues.begin(), sink.cues.end(),
                          [](const auto &entry) { return !entry.second.empty(); });
    if (it == sink.cues.end())
        return;

    const QString trackId = QString::fromStdString(it->first);
    if (!force && trackId == m_cuesTrackId && it->second.size() == m_cuesCount)
        return;

    const vlc_tick_t base = (sink.base != VLC_TICK_INVALID) ? sink.base : VLC_TICK_0;

    QVariantList cues;
    cues.reserve(it->second.size());
    for (const Cue &cue : it->second)
    {
        const vlc_tick_t end = (cue.end != VLC_TICK_INVALID) ? cue.end : cue.start + DEFAULT_CUE_LENGTH;
        QVariantMap entry;
        entry[QStringLiteral("start")] = std::clamp(double(cue.start - base) / length, 0.0, 1.0);
        entry[QStringLiteral("end")] = std::clamp(double(end - base) / length, 0.0, 1.0);
        cues.append(entry);
    }

    m_cuesTrackId = trackId;
    m_cuesCount = it->second.size();
    m_subtitleCues = std::move(cues);
    emit subtitleCuesChanged();
}

QList<qreal> MediaTimeline::waveform(int count) const
{
    QList<qreal> values;
    if (count <= 0)
        return values;

    vlc_tick_t length;
    {
        vlc_player_locker lock{ m_intf->p_player };
        length = vlc_player_GetLength(m_intf->p_player);
    }

    values.fill(-1.0, count);
    if (length <= 0 || m_peakMax <= 0.f)
        return values;

    const double bucketsPerPart = double(length) / PEAK_INTERVAL / count;
    for (int i = 0; i < count; ++i)
    {
        const qsizetype first = qsizetype(i * bucketsPerPart);
        const qsizetype last = std::max(first + 1, qsizetype((i + 1) * bucketsPerPart));
        if (first >= m_peaks.size())
            break;

        float peak = 0.f;
        for (qsizetype b = first; b < last && b < m_peaks.size(); ++b)
            peak = std::max(peak, m_peaks[b]);
        values[i] = peak / m_peakMax;
    }
    return values;
}
