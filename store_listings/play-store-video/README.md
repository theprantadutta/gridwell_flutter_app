# Play Store promo video

- `gridwell-promo-1920x1080.mp4`: 82 s landscape promo, light theme, no ads (premium test account).
- `youtube-thumbnail-1280x720.png`: the feature graphic resized for YouTube (`tools/thumb.py`).
  The feature graphic itself is not changed.

Upload to YouTube (unlisted or public, ads off), then paste the `watch?v=` URL into
Play Console > Store listing > Video.

## Music

"The Puzzle Pieces" by soppsound, from Pixabay
(https://pixabay.com/music/ambient-the-puzzle-pieces-295312/), under the Pixabay Content License:
free for commercial use, no attribution required. The track is not Content ID registered, so
YouTube will not add claims or ads to the video.

## Rebuild

Recordings come from the A24 (1080x2340) with
`adb shell screenrecord --bit-rate 8000000 --time-limit 178`, saved as `tools/rec1.mp4` and `tools/rec2.mp4`
(gitignored). Scene cuts and captions are in `tools/scenes.json`.

```
python tools/render_landscape.py <ffmpeg.exe> tools/scenes.json <music.mp3> gridwell-promo-1920x1080.mp4
```

`ffmpeg.exe` is the one bundled with `imageio_ffmpeg`
(`python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"`).
screenrecord writes a variable frame rate, so check scene times against frames taken through the
same `fps=30,trim` path the renderer uses, not with `-ss` seeking.
