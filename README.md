# Animation Track 2

This is a custom animation track that uses the Motor6D's transform property to animate characters. The main goal of creating this is to enable the use of animation tracks traditionally, without needing to upload the animations to Roblox.
Personally, I got tired of uploading animations to each group that I plan on publishing my games to, so I tried to make a solution.


## Methods (Subject to change)

### Track:Play()

#### This plays the animation loaded.

### Track:Stop()

#### This stops the animation loaded.

### Limitations [Functionality not added]
  * Animation tracks played created in the clients are not automatically replicated.
  * Large amounts of keyframes cause the animation to slow down over time. [Still under investigation]

##### Refrain from using in live games, this is hardly done.
