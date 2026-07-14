package main

import (
	"fmt"
	"time"

	"github.com/getlantern/systray"
)

func main() {
	systray.Run(onReady, onExit)
}

func onReady() {
	systray.SetTitle("🎵 Test")
	systray.SetTooltip("Audio CLI")
	
	go func() {
		for {
			time.Sleep(time.Second)
			fmt.Println("Running...")
		}
	}()
	
	mQuit := systray.AddMenuItem("Quit", "Quit the whole app")
	go func() {
		<-mQuit.ClickedCh
		systray.Quit()
	}()
}

func onExit() {
	// clean up
}
