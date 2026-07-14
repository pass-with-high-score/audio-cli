package main

import (
	"fmt"
	"os"

	"audio-cli/internal/player"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: audio-cli <file or directory> [-shuffle] [-loop]")
		os.Exit(1)
	}

	path := os.Args[1]
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
