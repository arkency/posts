---
created_at: 2026-05-11 22:50:08 +0200
author: Maciej Korsan
tags: []
publish: false
---

# TERAZ - live collective ambient experience made with Rails & tone.js

The first time TERAZ actually worked, there were around seventy phones playing in one room.

I was standing at my laptop, looking at a grid of rectangles on the screen, slowly bringing the instruments in. Each rectangle was one person from the audience. Each phone had been randomly assigned a part: bass, piano, crackling noise, angel pads, drone, or bells.

Before pressing start, I was still not completely sure what would happen. Local tests are one thing. Seventy people with their own phones, batteries, browsers, volume settings, operating systems, and expectations are another.

Then the room started to sound like one strange, fragile ambient organism.

I got goosebumps.

## Why I wanted to make this

I have been orbiting around ambient music for years — as a DJ, artist, listener, and organizer of Up To Date Festival in Białystok. It is close to my heart. Ambient has always made sense to me because it can be both background and the whole world, depending on how much attention you give it.

At the same time, I spend a lot of my life in technology. I write code, build systems, and think about how things communicate with each other. For a long time I wanted to make something where those two parts of me would actually meet, not as a gimmick, but as one idea.

TERAZ came from that place.

The name means “now” in Polish. For me, that word became the whole mechanism of the piece. Now I am part of the orchestra. Now I am listening to what is happening around me. Now I might want to check my phone, take a photo, record something — but if I do, I fall out of the orchestra.

In TERAZ, I ask the audience to take out their phones. For once, not to record anything.

They scan a QR code, keep a finger on the screen, and their devices become a temporary orchestra spread across the room. I control the piece live from my panel: bringing instruments in and out, changing volumes, and reacting to what I hear from the audience.

The phones generate sound locally. They are little instruments, each one slightly different, slightly unreliable, slightly its own thing.

## A soft manifesto, with a finger on the screen

I have been thinking for a long time about how we use phones during concerts and performances. Very often, instead of being fully in the room, we document the room. We record, take photos, check notifications, look at something else for a second. A phone can pull us out of the exact thing we came to experience.

With TERAZ, I wanted to turn that around.

The phone stays in your hand, but its role changes. To remain in the piece, you have to keep touching the screen so it does not go to sleep. It is a very simple gesture, almost stupidly simple, but it works. You are holding the device that usually distracts you, and now that same device requires your attention in order to keep playing.

That is why TERAZ always felt a bit like a manifesto to me. A soft one, maybe. No slogans, no big statement from the stage — just a small rule: if you want to stay in the piece, stay with the phone.

The technical challenge and the artistic idea grew together. The system exists to make that gesture possible.

## Pogwar, Tone.js, and a useful ugly hack

A few years earlier I made a generative ambient music performance called Pogwar, which I presented at Arsenał Gallery in Białystok. It was based on Tone.js and gave me a lot of space to explore browser-based generative sound.

Some things from Pogwar came back later in TERAZ. One of them was a hack I discovered while working on that project: an infinite loop in an audio element, playing a silent MP3 file, which helps JavaScript keep running in the background on mobile devices.

I would not broadly recommend this trick. It does not run with full power and can introduce artifacts. But it taught me something about what mobile browsers allow, what they block, and where the weird edges are.

The idea for TERAZ had been sitting in my head for a few years. I liked it, but I did not have a deadline, a place, or enough pressure to actually build it.

Then wroclove.rb happened.

It is a Ruby conference supported by Arkency, the company I work for. I suggested the idea to the organizers, and suddenly the vague thing I had been thinking about had a date, a room, and an audience.

That usually helps.

## What the audience sees

From the audience side, it goes like this.

At the beginning I welcome everyone and explain the rules. During the premiere at wroclove.rb I could have done this better. It was the first public version, and I learned very quickly that people need to understand one important thing: their phone may not start playing immediately. The orchestra is built gradually.

After the intro, people scan a QR code shown on the main screen. The system randomly assigns each person one of six tracks:

- bass

- piano

- crackling noise

- angel pads

- drone

- bells

When I press start, the QR code screen changes into a visualization: a matrix of rectangles, each representing one participant. Every phone becomes one small block inside the larger organism.

My control panel is somewhere between a mixer, a conductor’s desk, and a small emergency room.

I can see the six tracks, each with a volume slider and controls for locking or unlocking the instrument. Below that, I can see the participants, their assigned instruments, and their operating systems. I can also manually change assignments, which turned out to be very useful.

For example: Android and bass were not exactly best friends.

On some Android devices, there was basically no sound below around 120 Hz. iPhones generally handled the sound much better and played more reliably. Because every instrument is technically available on every device, I could notice when an Android phone had received bass and move it to another instrument.

This kind of thing is exactly why the panel had to be more than a pretty interface. It had to let me conduct, but also fix things while the piece was running.

## The server was fine. The phones were weird.

The system is built with Ruby on Rails, Action Cable, Stimulus, and Hotwire. Sound generation happens in JavaScript with Tone.js.

I did not stream audio to the phones. That felt too heavy and too fragile. Instead, each phone can play any of the instruments locally. The server only sends small control messages through Action Cable: this track is active, this is the current volume, this changed.

No audio stream. No constant flood of information. Just state changes.

The piano is the one exception in the sound design. It uses a sample, because generating a convincing piano directly on all those devices would be too expensive computationally. Everything else is generated on the participants’ phones.

I was ready for more than 120 people. At home, I tested with phones borrowed from my wife and neighbors, creating a tiny domestic orchestra. I also tested with around 100 browser tabs in Chrome.

This was funny, because my Mac gave up before the server did.

I kept opening tabs, but only some of them were actually able to play sound. Others started hanging or failing because I was clogging the local audio context. So I added special test parameters that skipped audio initialization and tested only the Action Cable communication.

I was ready to blame the cheapest Hetzner box. In the end, the server was fine. The real fun was in the devices: mobile browsers, audio policies, operating systems, weird performance limits, and all the small differences between phones.

Every phone is a slightly different instrument. Some are better instruments than others.

## Writing ambient music for tiny speakers

The music did not start in code.

At first I used Ableton Move to search for sounds. I improvised a lot, trying to find textures that made sense for a room full of small speakers. When something felt right, I started translating it into code and rebuilding the idea as a Tone.js instrument.

The six tracks have different roles: bass, piano, crackling noise, angel pads, drone, and bells. Together they create a slow ambient environment, but each participant only carries one part of it.

I wanted controlled chaos.

Each instrument moves somewhat randomly inside a defined area. I did not want all phones to play perfectly evenly or identically. That would probably feel too clean. The small differences between devices, timing, and generated material give the whole thing a bit of life.

At first I thought I should make everything very precisely synchronized. Later I let go of that idea. This is ambient music. Small timing differences are fine. They actually help. I did not measure latency in detail, because once I heard it in the room, it made sense.

Tone.js is a great library, but you need to be careful with optimization, especially on weaker phones. Some ideas that worked nicely on my machine were too heavy or unreliable across devices. I had to simplify, remove, or limit some parts to keep compatibility as wide as possible.

This was probably the biggest technical lesson for me: designing for a hundred phones is not the same as designing for “a browser”. There is no single browser. There is a crowd of strange little machines pretending to be one platform.

## The first time the room played

The first public performance of TERAZ happened at wroclove.rb. Around 70 people joined.

I had hoped for a bit more, but it was enough to feel the idea properly.

Technically, it worked really well. And when I heard the first sounds of the whole phone orchestra, I got goosebumps. That was the moment when the project stopped being a weird idea in my head and became something actually happening in the room.

The audience was a room full of curious programmers rather than a typical ambient crowd, so the reaction was lively. People were commenting, laughing, reacting to what their phones were doing, and trying to understand the mechanism while it was happening.

For a quiet ambient performance this was not ideal. For a first public test at a Ruby conference, it was perfect in its own strange way.

The recording has quite a lot of room noise because of that. I cleaned the audio as much as I could and pulled out what was possible. I will include the video with this post, because it also shows the visualization from the screen.

During the performance I felt a bit like a conductor. I had a structure in mind, but I was reacting to the room. Normally I would have stretched the quiet intro much longer. But I could see people getting impatient when their phones were not playing yet, so I brought in more layers faster.

That was an interesting moment. The system was working, but the room was also teaching me how the piece should behave.

## What I need to fix before the next one

Before doing it again, I need to fix one very basic thing: the intro.

People should know from the start that the piece grows slowly, and that waiting for your phone to enter is part of the experience. Otherwise some participants expect everything to play immediately, because that is how most digital interfaces behave.

I would love to show TERAZ in a more ambient or art-oriented context, with an audience more prepared for silence, focus, and slow development. I also want to try it at a larger scale. With this project, more phones really means more orchestra.

It could probably become an installation one day, but for now I am most interested in performing it live. The live version has tension. I can hear the room, see the system, feel the audience, and make decisions in the moment.

That part matters to me.

## Two hats, one problem

I think TERAZ worked for me because I did not have to choose which hat to wear.

The ambient part of me could care about slowness, texture, atmosphere, and attention. The programmer part could obsess over Action Cable, Android audio, sending as little data as possible, and keeping the thing alive on the cheapest Hetzner box.

Somehow, for once, these were the same problem.

TERAZ comes from my love for ambient music, my experience with generative sound, my work around Up To Date Festival, and my need to question what we do with our attention during performances.
