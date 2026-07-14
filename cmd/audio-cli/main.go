package main

import (
	"os"

	"audio-cli/internal/player"
)

func main() {
	path := ""
	if len(os.Args) >= 2 {
		path = os.Args[1]
	}
	shuffleFlag := false
	loopFlag := false

	for _, arg := range os.Args[2:] {
		if arg == "-shuffle" {
			shuffleFlag = true
		}
		if arg == "-loop" {
			loopFlag = true
		}
	}

	player.Run(path, shuffleFlag, loopFlag)
}
