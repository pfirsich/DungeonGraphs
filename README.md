# Dungeon Graphs
A really bad, prototype tool for making Dungeon Graphs as Mark Brown uses them in his Boss Key series: https://www.patreon.com/posts/how-my-boss-key-13801754
The images in this repo are all from the Dropbox-link on the bottom of this article.

It's made using [löve](https://love2d.org/), so to start it, you will have to download it from the website and start love.exe with this projects root folder as an argument (e.g. by drag&dropping the folder onto love.exe).

Fill tiles by left-clicking on them and selecting one. If you need additional tiles, just drop them into the /tiles directory (or delete the ones you don't like).

If you right click on a filled tile, you empty it instead.

If you right-click on a line, it becomes the start of a new horizontal "root line" (a connector).
Every tile connects itself upwards with a line until it hits a root line.

Root lines can also be ended, which is so far only supported by the line-generating algorithm, but not by the UI. So they can be ended, but you can't (yet) :>.

Stuff that someone might want to add before actually using it:
* Saving
* A camera (panning and zooming)
* Placing root-line-end-tiles
* Placing connectors on empty tiles

The code is really bad and essentially subpar gamejam code, this prototype was developed in less than 3h (including distractions), so no one ever, ever judge my by it please.

Also follow Game Maker's Toolkit, please, it's really good: https://www.youtube.com/channel/UCqJ-Xo29CKyLTjn6z2XwYAw