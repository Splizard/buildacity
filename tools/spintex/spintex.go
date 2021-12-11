package main

import (
	"fmt"
	"image"
	"image/draw"
	"image/png"
	"os"
	"path"
	"strconv"

	"github.com/anthonynsimon/bild/transform"
)

//spintex creates rotation animations
//by spinning a texture. Output tex is
//named input + "_spinning.png"
//used for windturbine texture.
func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: spintex <texture> <frames=16>")
		os.Exit(1)
	}

	var name = os.Args[1]
	var frames = 16
	if len(os.Args) == 3 {
		frames, _ = strconv.Atoi(os.Args[2])
	}

	output, err := os.Create(name[:len(name)-len(path.Ext(name))] + "_spinning.png")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	f, err := os.Open(name)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	img, _, err := image.Decode(f)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var animation = image.NewNRGBA(image.Rect(0, 0, img.Bounds().Dx(), img.Bounds().Dy()*frames))

	for i := 0; i < frames; i++ {
		var frame = transform.Rotate(img, float64(i)*360.0/float64(frames), &transform.RotationOptions{
			Pivot: &image.Point{
				img.Bounds().Dx() / 2,
				img.Bounds().Dy() / 2,
			},
		})

		draw.Draw(animation, image.Rect(0, img.Bounds().Dy()*i, img.Bounds().Dx(), img.Bounds().Dy()*frames), frame, image.Point{}, draw.Src)
	}

	if err := png.Encode(output, animation); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
