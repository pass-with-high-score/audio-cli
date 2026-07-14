package player

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/faiface/beep"
	"github.com/faiface/beep/flac"
	"github.com/faiface/beep/mp3"
	"github.com/faiface/beep/vorbis"
	"github.com/faiface/beep/wav"
	"github.com/faiface/beep/speaker"
)

func (m model) loadSongCmd(index int) tea.Cmd {
	return func() tea.Msg {
		if index < 0 || index >= len(m.filteredTracks) {
			return loadMsg{err: fmt.Errorf("invalid track index")}
		}
		track := m.tracks[m.filteredTracks[index]]
		f, err := os.Open(track.Path)
		if err != nil {
			return loadMsg{err: err}
		}

		var streamer beep.StreamSeekCloser
		var format beep.Format
		ext := strings.ToLower(filepath.Ext(track.Path))

		switch ext {
		case ".mp3":
			streamer, format, err = mp3.Decode(f)
		case ".wav":
			streamer, format, err = wav.Decode(f)
		case ".ogg":
			streamer, format, err = vorbis.Decode(f)
		case ".flac":
			streamer, format, err = flac.Decode(f)
		default:
			err = fmt.Errorf("unsupported format: %s", ext)
		}

		if err != nil {
			return loadMsg{err: err}
		}

		return loadMsg{streamer: streamer, format: format}
	}
}

func (m model) nextSong() (model, tea.Cmd) {
	if len(m.filteredTracks) == 0 {
		return m, nil
	}
	m.currentIndex++
	if m.currentIndex >= len(m.filteredTracks) {
		if m.loop {
			m.currentIndex = 0
		} else {
			m.currentIndex = len(m.filteredTracks) - 1
			// Stay at last song and pause
			if m.ctrl != nil {
				speaker.Lock()
				m.ctrl.Paused = true
				speaker.Unlock()
			}
			return m, nil
		}
	}
	return m, m.loadSongCmd(m.currentIndex)
}

func (m model) prevSong() (model, tea.Cmd) {
	if len(m.filteredTracks) == 0 {
		return m, nil
	}
	m.currentIndex--
	if m.currentIndex < 0 {
		m.currentIndex = len(m.filteredTracks) - 1
	}
	return m, m.loadSongCmd(m.currentIndex)
}
