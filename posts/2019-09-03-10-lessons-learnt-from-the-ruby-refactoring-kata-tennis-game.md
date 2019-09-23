---
title: "10 lessons learnt from the Ruby Refactoring Kata - Tennis Game"
created_at: 2019-09-18 17:55:30 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Over the last ~2 months, I’ve been scheduling some time to work on a specific Ruby code which is designed to be a good starting point for a refactoring.

Those exercises are called Refactoring Katas. The one I picked up is called Tennis Game.

I've had around 20 coding sessions with this specific kata and I have recorded all the session on our Arkency YouTube channel. There's a whole playlist of all the videos for this kata.

This blogpost is a written summary of my lessons, thoughts, observations after those 20 coding/refactoring sessions.

<!-- more -->

## Introduction

The responsibility of this code is to return a string with a Tennis game result. The input comes as sequential calls to the `won_point` method. The result is returned via `score` method. Those 2 methods create the public API of the TennisGame1 object.

## Initial code

```ruby
class TennisGame1

  def initialize(player1Name, player2Name)
    @player1Name = player1Name
    @player2Name = player2Name
    @p1points = 0
    @p2points = 0
  end
        
  def won_point(playerName)
    if playerName == "player1"
      @p1points += 1
    else
      @p2points += 1
    end
  end
  
  def score
    result = ""
    tempScore=0
    if (@p1points==@p2points)
      result = {
          0 => "Love-All",
          1 => "Fifteen-All",
          2 => "Thirty-All",
      }.fetch(@p1points, "Deuce")
    elsif (@p1points>=4 or @p2points>=4)
      minusResult = @p1points-@p2points
      if (minusResult==1)
        result ="Advantage player1"
      elsif (minusResult ==-1)
        result ="Advantage player2"
      elsif (minusResult>=2)
        result = "Win for player1"
      else
        result ="Win for player2"
      end
    else
      (1...3).each do |i|
        if (i==1)
          tempScore = @p1points
        else
          result+="-"
          tempScore = @p2points
        end
        result += {
            0 => "Love",
            1 => "Fifteen",
            2 => "Thirty",
            3 => "Forty",
        }[tempScore]
      end
    end
    result
  end
end

```

## Initial tests
At the first glance the tests look quite cool - the code is declarative, you should be able to see the expectations. However, while working on this code for longer I came to the conclusion that those tests are not really that perfect.

```ruby
TEST_CASES = [
   [0, 0, "Love-All", 'player1', 'player2'],
   [1, 1, "Fifteen-All", 'player1', 'player2'],
   [2, 2, "Thirty-All", 'player1', 'player2'],
   [3, 3, "Deuce", 'player1', 'player2'],
   [4, 4, "Deuce", 'player1', 'player2'],
   
   [1, 0, "Fifteen-Love", 'player1', 'player2'],
   [0, 1, "Love-Fifteen", 'player1', 'player2'],
   [2, 0, "Thirty-Love", 'player1', 'player2'],
   [0, 2, "Love-Thirty", 'player1', 'player2'],
   [3, 0, "Forty-Love", 'player1', 'player2'],
   [0, 3, "Love-Forty", 'player1', 'player2'],
   [4, 0, "Win for player1", 'player1', 'player2'],
   [0, 4, "Win for player2", 'player1', 'player2'],
   
   [2, 1, "Thirty-Fifteen", 'player1', 'player2'],
   [1, 2, "Fifteen-Thirty", 'player1', 'player2'],
   [3, 1, "Forty-Fifteen", 'player1', 'player2'],
   [1, 3, "Fifteen-Forty", 'player1', 'player2'],
   [4, 1, "Win for player1", 'player1', 'player2'],
   [1, 4, "Win for player2", 'player1', 'player2'],
   
   [3, 2, "Forty-Thirty", 'player1', 'player2'],
   [2, 3, "Thirty-Forty", 'player1', 'player2'],
   [4, 2, "Win for player1", 'player1', 'player2'],
   [2, 4, "Win for player2", 'player1', 'player2'],
   
   [4, 3, "Advantage player1", 'player1', 'player2'],
   [3, 4, "Advantage player2", 'player1', 'player2'],
   [5, 4, "Advantage player1", 'player1', 'player2'],
   [4, 5, "Advantage player2", 'player1', 'player2'],
   [15, 14, "Advantage player1", 'player1', 'player2'],
   [14, 15, "Advantage player2", 'player1', 'player2'],
   
   [6, 4, 'Win for player1', 'player1', 'player2'], 
   [4, 6, 'Win for player2', 'player1', 'player2'], 
   [16, 14, 'Win for player1', 'player1', 'player2'], 
   [14, 16, 'Win for player2', 'player1', 'player2'], 

   [6, 4, 'Win for player1', 'player1', 'player2'],
   [4, 6, 'Win for player2', 'player1', 'player2'], 
   [6, 5, 'Advantage player1', 'player1', 'player2'],
   [5, 6, 'Advantage player2', 'player1', 'player2'] 
]

class TestTennis < Test::Unit::TestCase
  def play_game(tennisGameClass, p1Points, p2Points, p1Name, p2Name)
    game = tennisGameClass.new(p1Name, p2Name)
    (0..[p1Points, p2Points].max).each do |i|
      if i < p1Points
        game.won_point(p1Name)
      end
      if i < p2Points
        game.won_point(p2Name)
      end
    end
    game
  end

  def test_Score_Game1
    TEST_CASES.each do |testcase|
      (p1Points, p2Points, score, p1Name, p2Name) = testcase
      game = play_game(TennisGame1, p1Points, p2Points, p1Name, p2Name)
      assert_equal(score, game.score())
    end
  end
end
```

## Lessons learnt

## 1. Merciless refactoring can be a nice learning technique

Let me quote the extreme programming definition of what I mean here:

```
Refactor mercilessly to keep the design simple as you go and to avoid needless clutter and complexity. Keep your code clean and concise so it is easier to understand, modify, and extend. Make sure everything is expressed once and only once. In the end it takes less time to produce a system that is well groomed.
￼
There is a certain amount of Zen to refactoring. It is hard at first because you must be able to let go of that perfect design you have envisioned and accept the design that was serendipitously discovered for you by refactoring. You must realize that the design you envisioned was a good guide post, but is now obsolete.
```

The above definition makes most sense when applied to a situation when you think you know what is the perfect design and then you try to apply it. Usually, the code would tell you why your vision may not be so perfect. The solution is to follow the code.

In this Refactoring Kata, you can see my initial attempts to actually understand what the code does, by changing the code.

<iframe width="560" height="315" src="https://www.youtube.com/embed/swokhWHKDmc" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

Even though, I don’t understand the domain yet - I’m following the typical code smells to restructure the code. It’s purely technical at this stage. I have no idea what the code really does (I’m trying to guess) but I know that certain technical transformations will keep the behaviour the same, while allow me to look at the code from a different angle.

## 2. After Red/Green comes the Refactor phase

Another refactoring lesson was the reminder that TDD (which I try to practice) is not only Red/Green, it's also Refactor after the Green part.

<iframe width="560" height="315" src="https://www.youtube.com/embed/KdBpPsvLA5Q" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>



## 3. Don’t trust the tests

At first, I thought that the tests give me enough coverage, that I can do the initial refactoring safely. However, it’s only over time that I learnt what are the drawbacks of the current tests design. The main problem is this code:

```ruby
  def play_game(tennisGameClass, p1Points, p2Points, p1Name, p2Name)
    game = tennisGameClass.new(p1Name, p2Name)
    (0..[p1Points, p2Points].max).each do |i|
      if i < p1Points
        game.won_point(p1Name)
      end
      if i < p2Points
        game.won_point(p2Name)
      end
    end
    game
  end
```

You see, this code plays through the game always in the same manner — first add all possible points to player1 and only later add player2 points. 
For certain implementations this might be a correct suite of tests, but if we switch to more stateful implementations, we’re lacking the coverage.

I consider refactoring a process of learning. It’s learning of the domain, of the code and of the tests. When you look at it this way, maybe it was alright - I started refactoring and through this process I learnt about the problems with tests. However, this is only valid, if I don’t push my changes before I learn the lessons. If I do, I risk introducing breaking changes.

## 4. Learn at least some basics of the domain

I’m not a big fan of tennis, but I thought I knew enough about it to work on this code.

In practice, this was hard. I kept forgetting what’s the meaning of `Love`, I had to constantly look up the possible results.

I think this led me to overgeneralising the code sometimes. The names I used for method names, for object names - they were not really names that would appear in a conversation among the real fans of the game.

That’s something what I’m trying to be more professional in my commercial projects. When I worked on accounting project, I took an online class on accounting. When I worked on a publishing project, I have studied the publishing industry, including the possible business models, what publishers struggle with, how publishers cooperate with authors. I talked to certain publishers.

In this kata, I clearly failed at it. I wasted some time, because I couldn’t visualise the domain well enough.

My domain vocabulary was very poor here - I kept using the words: `game`, `score`, `result` without learning some more.

## 5. Extract method is a no-brainer refactoring with a good IDE support

As you can see in the initial videos, I'm very aggressive in using the extract method technique. There are several reasons but the main one is to make the main algorithm, the main scenario as concise and clear as possible. This way I have the main method which represents the algorithm in an abstract way, but everything stays at the same level of abstraction. All the details are left to the other methods or even classes to be extracted.

I use RubyMine and I learnt to trust its Extract Method tooling. It's just an alt-cmd-m keystroke, type the new name and it's done.

## 6. Preserve the public API if you have no control on the client calls

I like to use modules to package my code. Sometimes, I don't have control on the client calls, though. In such cases, I leave the public API untouched, but then delegate everything to the code behind modules. This is like building a facade/wall in front of my "well-packaged" code.

The name `TennisGame1` remained untouched in my initial commits, even though it's a terrible name. However, over time, I moved more code into the `Tennis` module.

```ruby
class TennisGame1

  def initialize(player1Name, player2Name)
    @player1Name = player1Name
    @player2Name = player2Name
    @p1points = 0
    @p2points = 0
  end
        
  def won_point(playerName)
    if playerName == "player1"
      @p1points += 1
    else
      @p2points += 1
    end
  end
  
  def score
    return draw_result              if (@p1points==@p2points)
    return advantage_or_win_result  if (@p1points>=4 or @p2points>=4)
    return ongoing_result
  end

  private

  def ongoing_result
    Tennis::OngoingResult.new(@p1points, @p2points).score
  end

  def draw_result
    Tennis::DrawResult.new(@p1points).score
  end
end
```

## 7. Extracting new classes helped my encapsulate concepts like Draw or Win

Similarly as Extract Method, I found Extract Class useful. I usually follow the same pattern, where I create a constructor method which sets the state and then 1 or 2 public methods to retrieve the data. In a way, this is a function and can be implemented as a function too. However, what I learnt is that often those objects are just a temporary thing. They're not the final result of the refactoring, more like a step in-between. 

```ruby
module Tennis
  class DrawResult
    def initialize(points)
      @points = points
    end

    def score
      {
        0 => "Love-All",
        1 => "Fifteen-All",
        2 => "Thirty-All",
      }.fetch(@points, "Deuce")
    end
  end

  class OngoingResult
    def initialize(points_1, points_2)
      @points_1 = points_1
      @points_2 = points_2
    end

    def score
      "#{ongoing_result_names[@points_1]}-#{ongoing_result_names[@points_2]}"
    end

    private

    def ongoing_result_names
      {
        0 => "Love",
        1 => "Fifteen",
        2 => "Thirty",
        3 => "Forty",
      }
    end
  end
end
```


<iframe width="560" height="315" src="https://www.youtube.com/embed/33rfX6bUo3w" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>


## 8. Simplify if conditions with Guards

There's something about if conditions that I dislike. They often hide some important logic and I feel like ifs are sometimes a too primitive way of encapsulating this logic (often some state machines).

The most dangerous code I usually see are the nested if statements. 

"No one ever got fired for adding the n+1 if statement, right"?

When I saw this initial code, trying to simplify it was my main goal:

```ruby
  def score
    result = ""
    tempScore=0
    if (@p1points==@p2points)
      result = {
          0 => "Love-All",
          1 => "Fifteen-All",
          2 => "Thirty-All",
      }.fetch(@p1points, "Deuce")
    elsif (@p1points>=4 or @p2points>=4)
      minusResult = @p1points-@p2points
      if (minusResult==1)
        result ="Advantage player1"
      elsif (minusResult ==-1)
        result ="Advantage player2"
      elsif (minusResult>=2)
        result = "Win for player1"
      else
        result ="Win for player2"
      end
    else
      (1...3).each do |i|
        if (i==1)
          tempScore = @p1points
        else
          result+="-"
          tempScore = @p2points
        end
        result += {
            0 => "Love",
            1 => "Fifteen",
            2 => "Thirty",
            3 => "Forty",
        }[tempScore]
      end
    end
    result
  end
```

Here is the result after Extract Method, Extract Class and Replace If with Guard:

```ruby
  
  def score
    return draw_result              if (@p1points==@p2points)
    return advantage_or_win_result  if (@p1points>=4 or @p2points>=4)
    return ongoing_result
  end
```

Obviously the ugliness of nested ifs didn't disappear, but starting from the top-level code allowed me to make the main algorithm more clear and let me deal with other nested ifs in more localized methods/objects.

## 9. Code as data sounded more exciting in theory than in practice

<iframe width="560" height="315" src="https://www.youtube.com/embed/G2s2GlENGZM" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

I've been always excited by the idea of treating code as data. What I mean here is that some code doesn't need to be code, because it's actually data. In the video above you can see that I started refactoring some of the code (state machine transitions between possible results) into "code like data" direction. However, I never really finished it. It felt very "primitive" to represent those concepts as pure data without any behaviour. 

This is a topic I need to think more about. Maybe this example wasn't a good fit. Or maybe the idea isn't as good as I thought. Maybe I'm just missing some skills here.

## 10. Mutation testing

<iframe width="560" height="315" src="https://www.youtube.com/embed/ey431Gi1050" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

This lesson came too late ;)

In my next refactoring kata I will try to "hire" mutant to check my tests earlier than I did here.
Somehow, I connect mutant with some "big deal", while in fact it's very easy to start with, especially in such katas. Mutant shows very nicely that the tests are far from perfect and that my merciless refactoring attempts might be too brave sometimes.

## The "final" code

```ruby
class TennisGame1

  def initialize(player1Name, player2Name)
    @player_1_name = player1Name
    @player_2_name = player2Name
    @game     = Tennis::LoveAll.new
  end
        
  def won_point(playerName)
    if playerName == @player_1_name
      @game = @game.player_1_score
    else
      @game = @game.player_2_score
    end
  end
  
  def score
    @game.score % {player_1: @player_1_name, player_2: @player_2_name}
  end

end

module Tennis

  class LoveAll
    def score;          "Love-All"      end
    def player_1_score; FifteenLove.new end
    def player_2_score; LoveFifteen.new end
  end

  class FifteenLove
    def score; "Fifteen-Love" end
    def player_1_score; ThirtyLove.new end
    def player_2_score; FifteenAll.new end
  end

  class ThirtyLove
    def score; "Thirty-Love" end
    def player_1_score; FortyLove.new end
    def player_2_score; ThirtyFifteen.new end
  end

  class FortyLove
    def score; "Forty-Love" end
    def player_1_score; WinPlayer_1.new end
    def player_2_score; FortyFifteen.new end
  end

  class LoveFifteen
    def score; "Love-Fifteen" end
    def player_1_score; FifteenAll.new end
    def player_2_score; LoveThirty.new end
  end

  class LoveThirty
    def score; "Love-Thirty" end
    def player_1_score; FifteenThirty.new end
    def player_2_score; LoveForty.new end
  end

  class LoveForty
    def score; "Love-Forty" end
    def player_1_score; FifteenForty.new end
    def player_2_score; WinPlayer_2.new end
  end

  class FifteenAll
    def score; "Fifteen-All" end
    def player_1_score; ThirtyFifteen.new end
    def player_2_score; FifteenThirty.new end
  end

  class ThirtyFifteen
    def score; "Thirty-Fifteen" end
    def player_2_score; ThirtyAll.new end
    def player_1_score; FortyFifteen.new end
  end

  class FortyFifteen
    def score; "Forty-Fifteen" end
    def player_1_score; WinPlayer_1.new end
    def player_2_score; FortyThirty.new end
  end

  class ThirtyAll
    def score; "Thirty-All" end
    def player_1_score; FortyThirty.new end
    def player_2_score; ThirtyForty.new end
  end

  class FortyThirty
    def score; "Forty-Thirty" end
    def player_1_score; WinPlayer_1.new end
    def player_2_score; Deuce.new end
  end

  class WinPlayer_1
    def score; "Win for %{player_1}" end
  end

  class WinPlayer_2
    def score; "Win for %{player_2}" end
  end

  class Deuce
    def score; "Deuce" end
    def player_1_score; AdvantagePlayer_1.new end
    def player_2_score; AdvantagePlayer_2.new end
  end

  class AdvantagePlayer_1
    def score; "Advantage %{player_1}" end
    def player_1_score; WinPlayer_1.new end
    def player_2_score; Deuce.new end
  end

  class AdvantagePlayer_2
    def score; "Advantage %{player_2}" end
    def player_1_score; Deuce.new end
    def player_2_score; WinPlayer_2.new end
  end

  class FifteenThirty
    def score; "Fifteen-Thirty" end
    def player_1_score; ThirtyAll.new end
    def player_2_score; FifteenForty.new end
  end

  class FifteenForty
    def score; "Fifteen-Forty" end
    def player_2_score; WinPlayer_2.new end
  end

  class ThirtyForty
    def score; "Thirty-Forty" end
    def player_1_score; Deuce.new end
    def player_2_score; WinPlayer_2.new end
  end
end
```

## Summary

Those lessons are not all, I just picked the ones I thought were the most important.

It was a nice experience overall and I learnt a lot from doing the kata. I have recorded the YouTube videos along the way and it was nice to receive feedback from the audience which of my changes could be better (thank you everyone!).

The sad thing is that I'm still not satisfied with the end result code, but on the more optimistic side is that I like the current solution better than the initial one.

Such katas are a wonderful way of practicing outside of our commercial projects, while the lessons can be incorporated into our daily coding sessions.

If you'd like to follow my next such coding sessions and/or watch my other software/Ruby/DDD/TDD-related thoughts, follow us on the Arkency YouTube channel, thank you!

<script src="https://apis.google.com/js/platform.js"></script>

<div class="g-ytsubscribe" data-channelid="UCL8YpXFH1-y3AaELb0H7c3Q" data-layout="full" data-count="default"></div>