---
created_at: 2026-05-11 22:50:08 +0200
author: Maciej Korsan
tags: []
publish: false
---

# TERAZ - live collective ambient experience made with Rails & tone.js

For years I have been moving around ambient music as a DJ, artist, listener, and organizer of Up To Date Festival in Białystok. Ambient is very close to my heart. I keep discovering it, returning to it, and looking for new ways of experiencing it. At the same time, I have always been deeply involved in technology. I work with code, I think through systems, and I am naturally attracted to projects where music and software can meet in a meaningful way.

TERAZ came from that place — from wanting to connect those two parts of myself.

The name means “now” in Polish. For me, that word is not just a title. It is the core mechanism of the project. Now I am part of the orchestra. Now I am focusing on other sounds. Now I might be tempted to use my phone in the usual way, but if I do, I fall out of the orchestra.

TERAZ is a live ambient performance in which the audience becomes a distributed smartphone orchestra. People scan a QR code, join the system, and their phones are randomly assigned one of six musical parts. I control those parts live from my panel, gradually bringing instruments in and out, changing volumes, and shaping the whole piece in real time.

The phones are not just passive speakers. They are small instruments.

That distinction was important to me from the beginning. I did not want to stream audio to the devices. Instead, each phone generates its own sound locally. The server sends only control messages: whether a given track is active, how loud it should be, and when something changes. The actual sound happens on the devices in the audience.

## Why phones?

For a long time I have been thinking about how people use phones during concerts and performances. Very often, instead of simply being present, we document: we record, take photos, check something, look at notifications. The phone becomes a tool for escaping the moment, even when we are physically inside it.

With TERAZ, I wanted to reverse that relationship.

The phone becomes an instrument, but also a constraint. To stay in the orchestra, the participant has to keep a finger on the screen so the phone does not go to sleep. It is a simple physical gesture, but it changes the role of the device completely. You are still holding your phone, but you are not using it to leave the situation. You are holding it to remain inside it.

That is why TERAZ has always felt a bit like a manifesto to me. It is about presence, attention, and collective listening. It is also a technological experiment, of course, and that part is very attractive to me. But the technical challenge is not separate from the artistic idea. The system exists in order to make that gesture possible.

## Before TERAZ

A few years ago, I created a generative ambient music performance called Pogwar, which I presented at Arsenał Gallery in Białystok. That project was based on Tone.js and gave me an earlier opportunity to explore browser-based generative sound.

Some of the ideas and technical tricks from Pogwar later returned in TERAZ. One of them was a hack that allowed JavaScript to keep running in the background on mobile devices: an infinite loop in an audio element, playing a silent MP3 file. It is not something I would broadly recommend, because it does not run with full power and can introduce artifacts, but in this context it helped me understand what was possible.

The idea for TERAZ had been with me for a few years, but I did not have the right motivation or occasion to finally build it. That changed with wroclove.rb, a Ruby conference supported by Arkency, the company I work for. I suggested the idea to the organizers, and suddenly the abstract concept had a deadline, a room, and an audience.

## How it works

The flow of the performance is simple from the audience perspective.

At the beginning, I welcome everyone and explain the rules. During the premiere at wroclove.rb, I could have prepared this introduction better, but it was the first public version of the project, so I also learned a lot from that situation.

Participants scan a QR code shown on the main screen. After joining, the system randomly assigns each person one of six tracks:

- bass
- piano
- crackling noise
- angel pads
- drone
- bells

Once I press start, the QR code screen changes into a visualization: a matrix of rectangles, each representing one participant in the orchestra. Every phone in the room becomes one small element of a larger visual and sonic body.

My control panel has a few main sections. I can see the six tracks, each with a volume slider and controls for locking or unlocking the instrument. Below that, I can see the list of participants, their assigned instruments, and their operating systems. I can also manually change assignments, which turned out to be very useful.

For example, Android devices had problems with bass. On some of them, there was basically no sound below around 120 Hz. Because every instrument is technically available on every device, I could move an Android participant away from bass and assign a different instrument instead.

The system is built with Ruby on Rails, Action Cable, Stimulus, and Hotwire. The sound generation happens in JavaScript with Tone.js. Apart from the piano, which uses a sample because generating it directly on the device would be more expensive computationally, the sounds are generated on participants’ phones.

The server does not stream audio. It only broadcasts small control messages through Action Cable when something changes. That makes the data flow very light and keeps the architecture much simpler and more reliable.

I was prepared for more than 120 people. I tested locally using borrowed mobile devices from my wife and neighbors, and also with around 100 browser tabs in Chrome. That test was funny in its own way: I started clogging the audio context on my Mac. Only some tabs were able to play sound, while others froze or failed. I had to add special test parameters to avoid initializing audio and test only Action Cable communication.

The whole thing was hosted on the cheapest Hetzner server.

In the end, I was worried about the performance of the “mother server” much more than I needed to be. The real complexity was not on the server side. It was in the unpredictable ecosystem of mobile devices, browsers, audio implementations, and operating systems.

## Composing for many small instruments

The musical process did not start in code. It started with sound.

At first, I used Ableton Move to search for textures and ideas. I improvised a lot, looking for sounds that felt right for this kind of distributed ambient orchestra. Once I found something that worked musically, I started translating it into code and building instruments in Tone.js.

Each instrument moves somewhat randomly inside a defined area. I wanted controlled chaos. I did not want every phone to play perfectly evenly or identically. The small differences between devices, timing, behavior, and generated material give each phone a bit of individuality.

At the beginning, I had an idea that everything should be very precisely synchronized. Later I gave up on that. This is ambient music, and small timing differences are not a problem. They are part of the character of the piece. I did not measure latency in detail, because I did not need to. It sounded good, and the slight looseness helped the orchestra feel alive.

Working with Tone.js was both enjoyable and demanding. It is a great library, but on weaker devices you have to think carefully about optimization. During testing, I discovered that some ideas were too heavy or unreliable across phones, so I simplified and limited parts of the system to get the widest possible compatibility.

That was one of the main lessons of the project: the phone is not an abstract device. Every phone is a slightly different instrument.

## The premiere at wroclove.rb

The first public performance of TERAZ happened at wroclove.rb. Around 70 people joined the orchestra.

Technically, everything worked very well. When I heard the first sounds of the whole smartphone orchestra, I had goosebumps. That was the moment when the project stopped being only an idea and became a real experience in the room.

The audience was not a typical ambient audience. It was a room full of curious programmers, so the reaction was lively. People commented on what was happening, reacted audibly, and were interested in the mechanism of the whole thing. In a more ambient or art-oriented context, I would expect a different kind of attention and probably a quieter atmosphere.

Because of that, the recording from the premiere contains quite a lot of room noise. I cleaned the audio as much as I could and extracted what was possible. The video also shows the visualization, so I will include it with this post.

From a performance perspective, I felt a bit like a conductor. I had a structure in mind, but I was also reacting to what I heard and saw in the room. Under different circumstances, I would probably stretch the quiet intro for longer. But during the premiere I could see people becoming impatient when their phones were not playing yet, so I brought in more layers faster than planned.

That tension was interesting. I was not only mixing six tracks. I was conducting a room full of devices and people, adjusting the form of the piece in response to the situation.

## What I would change

The main thing I would improve before the next performance is the introduction.

The audience needs to understand that this is not an app where everything immediately starts playing on every phone. It is an orchestra, and the orchestra is built gradually. Some people may wait before their phone becomes audible. That waiting is part of the composition, but it needs to be explained clearly.

I would also love to present TERAZ in a more ambient or art-oriented context, where the audience is more prepared for focus, silence, and slow development. At the same time, the project benefits from scale. More phones means a richer and more powerful orchestra. In this case, more really is better.

I can imagine TERAZ becoming an installation, but for now I am most interested in performing it live. The live version has a specific tension: the system, the room, the devices, the people, and my decisions all meet in one moment.

## Two hats

TERAZ is important to me because it proves that I can make something real while wearing both hats: artist and programmer.

It is an ambient performance, a technological experiment, a small manifesto about phones, and a live system for collective listening. It comes from my love for ambient music, my experience with generative sound, my work around Up To Date Festival, and my need to question what we do with our attention during performances.

TERAZ is a unique ambient experience in which smartphones stop being tools for escaping the concert and become part of the orchestra.

And for a couple of minutes, the audience is not only watching or listening. They are playing.