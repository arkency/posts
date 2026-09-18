---
created_at: 2026-09-18 22:50:08 +0200
author: Maciej Korsan
tags: [hotwire, lifestyle, rails]
publish: true
---
# TERAZ - live collective ambient experience made with Rails & Tone.js

The first time TERAZ actually worked, there were around seventy phones in the audience at the wroclove.rb conference.

Before pressing start, I was still not completely sure what would happen. Local tests are one thing. Seventy people with their own phones, batteries, browsers, volume settings, operating systems, and expectations are another.

I was standing at my laptop, looking at a grid of rectangles on the screen, slowly bringing the instruments in. Each rectangle was one person from the audience. Each phone had been randomly assigned a part: bass, piano, crackling noise, angel pads, drone, or bells.

Then the room started to sound like one strange, fragile ambient organism, and I got goosebumps.

<iframe width="100%" height="315" src="https://www.youtube.com/embed/hT6QU2p8-AQ?si=oy-7QZajYfFnw8vC" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Why I made TERAZ

I have been orbiting around ambient music for years - as a DJ, artist, listener, and organizer of Up To Date Festival in Białystok. It is close to my heart. Ambient has always made sense to me because it can be both background and the whole world, depending on how much attention you give it.

At the same time, I spend a lot of my life in technology. I write code, build systems, and think about how things communicate with each other. For a long time, I wanted to make something where those two parts of me would actually meet, not as a gimmick, but as one idea. TERAZ came from that place.

Let's talk a bit about the name. TERAZ means NOW in Polish. For me, that word became the whole mechanism of the piece. Participants can say: NOW I am part of the orchestra, NOW I am listening to what is happening around me, NOW I might want to check my phone, take a photo, record something - but if I do, I fall out of the orchestra.

## The phone as part of the performance

I have been thinking for a long time about how we use phones during concerts and performances. Very often, instead of being fully in the room, we "document" the thing. We record, take photos, check notifications, look at something else for a second. A phone can pull us out of the exact thing we came to experience.

With TERAZ, I wanted to turn that around - the phone stays in your hand, but its role changes. To remain in the piece, you have to keep touching the screen so it does not go to sleep. It is a very simple gesture, almost stupidly simple, but it works. You are holding the device that usually distracts you, and now that same device requires your attention in order to keep playing.

That is why TERAZ has always felt a bit like a small manifesto to me. No slogans, no big statement from the stage - just a small rule: if you want to stay in the piece, stay with the phone. The technical challenge and the artistic idea grew together. The system exists to make that gesture possible.

## What I learned from Pogwar

A few years earlier, I made a generative ambient music performance called Pogwar, which I presented at Arsenał Gallery in Białystok. It was based on Tone.js and gave me a lot of space to explore browser-based generative sound.

Some things from Pogwar came back later in TERAZ. One of them was a hack I discovered while working on that project: an audio element playing a silent MP3 file on an infinite loop, which helps JavaScript keep running in the background on mobile devices.

I would not broadly recommend this trick. It does not run at full power and can introduce artifacts. But it taught me something about what mobile browsers allow, what they block, and where the weird edges are.

## How TERAZ works

From the audience side, it goes like this: at the beginning, I welcome everyone and explain the rules. During the premiere at wroclove.rb, I could have done this better. It was the first public version, and I learned very quickly that people need to understand one important thing: their phone may not start playing immediately. The orchestra is built gradually.

After the intro, people scan a QR code shown on the main screen. The system randomly assigns each person one of six tracks:

- bass
- piano
- crackling noise
- angel pads
- drone
- bells

When I press start, the QR code screen changes into a visualization: a matrix of rectangles, each representing one participant. Every phone becomes one small block inside the larger organism.

My control panel is somewhere between a mixer, a conductor’s desk, and a small emergency room.

<img src="https://blog-arkency.imgix.net/teraz-live-collective-ambient-experience/teraz-conductor.avif" class="w-full"/>

I can see the six tracks, each with a volume slider and controls for locking or unlocking the instrument. Below that, I can see the participants, their assigned instruments, and their operating systems. I can also manually change assignments, which turned out to be very useful - for example, Android and bass were not exactly best friends.

On some Android devices, there was basically no sound below around 120 Hz. iPhones generally handled the sound much better and played more reliably. Because every instrument is technically available on every device, I could spot when an Android phone had been assigned bass and move it to another instrument.

## Building for many different phones

The system is built with Ruby on Rails, Action Cable, Stimulus, and Hotwire. Sound generation happens in JavaScript with Tone.js.

I did not stream audio to the phones. That felt too heavy and too fragile. Instead, each phone can play any of the instruments locally. The server only sends small control messages through Action Cable: this track is active, this is the current volume, something has changed.

The piano is the one exception in the sound design. It uses a sample downloaded to the user's phone, because generating a convincing piano directly on all those devices would be too computationally expensive. Everything else is generated on the participants’ phones.

I was ready for more than 120 people. At home, I tested with phones borrowed from my wife and neighbors, creating a tiny domestic orchestra. I also tested with around 100 browser tabs in Chrome. This was funny, because my Mac gave up before the server did. I kept opening tabs, but only some of them were actually able to play sound. Others started hanging or failing because I was clogging up the local audio context. So I added special test parameters that skipped audio initialization and tested only the Action Cable communication.

## Designing sound for phone speakers

The music did not start in code. At first, I used Ableton Move to search for sounds. I improvised a lot, trying to find textures that made sense for a room full of small speakers. When something felt right, I started translating it into code and rebuilding the idea as a Tone.js instrument.

The six tracks have different roles: bass, piano, crackling noise, angel pads, drone, and bells. Together they create a slow ambient environment, but each participant only carries one part of it.

But not everything is set in stone. I wanted to create controlled chaos. Each instrument moves somewhat randomly within a defined range. I did not want all phones to play perfectly evenly or identically. That would probably feel too clean. The small differences between devices, timing, and generated material give the whole thing a bit of life.

At first, I thought I should make everything very precisely synchronized. Later, I let go of that idea. This is ambient music. Small timing differences are fine. They actually help. I did not measure latency in detail, because once I heard it in the room, it made sense.

Tone.js is a great library, but you need to be careful with optimization, especially on weaker phones. Some ideas that worked nicely on my machine were too heavy or unreliable across devices. I had to simplify, remove, or limit some parts to keep compatibility as broad as possible.

This was probably the biggest technical lesson for me: designing a real-time system for hundreds of phones is not the same as designing for a regular browser.

## What I would change next time

Before doing it again, I need to fix one very basic thing: the intro.

People should know from the start that the piece grows slowly, and that waiting for your phone to enter is part of the experience. Otherwise, some participants expect everything to play immediately, because that is how most digital interfaces behave.

I would love to show TERAZ in a more ambient or art-oriented context. I also want to try it at a larger scale. With this project, more phones really make a big difference.

It could probably become an installation one day, but for now I am most interested in performing it live. The live version has tension. I can hear the room, see the system, feel the audience, and make decisions in the moment.

From a technical perspective, I'd love to add Rails Event Store and create a performance timeline using the events, and also make a nice timeline visualization for RES itself.

## Where music and code meet

I think TERAZ worked for me because I did not have to choose which hat to wear.

The ambient-artistic part of me could care about slowness, texture, atmosphere, and attention. The programmer part could obsess over Action Cable, Android audio, sending as little data as possible, and keeping the thing alive on the cheapest Hetzner box.

Somehow, for once, these were part of a single thing.