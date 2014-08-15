Ruby Torrent
============

A BitTorrent client written in ruby using EventMachine for concurrency.

This BitTorrent clients has lots of fun and useful features but is certainly not feature complete. I wrote this in a very short amount of time and therefore the code is not alwyas as beautiful I'd like... so please don't judge me for that :)

## Features
* Connect to trackers over HTTP
* Connets to multiple peers at once over TCP using EventMachine
* Downloads and manages pieces of the file

## Next Steps
* Support multi-file downloads
* Command line input of file names
* UDP tracker support
* Smarts around which piece to download
* BitField + Have message implementation
* Write to file
