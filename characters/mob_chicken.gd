extends CharacterBody2D

# _animated_sprite.flip_h = true # or false <- make use of this in order to flip the walking sprite
# chicken sprites are very simple, making use of this should be a fun challenge.

# todo: figure an algorithm to use random numbers to figure (1) state and (2) movement, if applicable
enum CHICKEN_STATE { IDLE, RESTING, WALKING } 
