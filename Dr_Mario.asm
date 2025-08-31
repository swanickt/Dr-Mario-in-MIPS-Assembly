######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    128
# - Display height in pixels:   128
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# constants that will be used to colour the current state in the game loop
blank_cell: # A background cell
    .word 0
yellow_virus: # A cell with a yellow virus
    .word 1
blue_virus: # A cell with a blue virus
    .word 2
red_virus: # A cell with a red virus
    .word 3
red_pill: # A cell with a red half-pill
    .word 4
yellow_pill: # A cell with a yellow half-pill
    .word 5
blue_pill: # A cell with a blue half-pill
    .word 6
bottle_cell: # A cell part of the surrounding bottle
    .word 7   
red_drawing_cell: # a cell for red art, not used in any game functionality
    .word 8
green_drawing_cell: # a cell for green art, not used in any game functionality
    .word 9
yellow_drawing_cell: # a cell for yellow art, not used in any game functionality
    .word 10
blue_drawing_cell: # a cell for blue art, not used in any game functionality
    .word 11
brown_drawing_cell: # a cell for brown art, not used in any game functionality
    .word 12  
mario_pants_colour: # a cell corresponding to parts of mario's pants
    .word 13
white_drawing_cell: # a cell for white art, not used in any game functionality
    .word 14  
grey_drawing_cell: # a cell for grey art, not used in any game functionality
    .word 15  
light_grey_drawing_cell: # a cell for grey art, not used in any game functionality
    .word 16
skin_colour_drawing_cell:  # a cell for skin coloured art, not used in any game functionality
    .word 17
mario_eye_colour:          # a cell for the eye coloured art, not used in any game functionality
    .word 18
initial_x: # x-coordinate for initial pill
    .word 31
initial_y: # y-coordinate for initial pill
    .word 24

##############################################################################
# Mutable Data
##############################################################################
# A 64x64 grid representing all pixels on the bitmap
game_field:
    .word 0:4096 # size is 64x64=4096 cells, each initialized to a value of 0.
    
match_tracker:
    .word 0:4096 # size is same as game field. Each cell intialized to 0 and made into 1 if it's part of a match.
    
past_pill_tracker:
    .word 0:4096    # size is the same as game field and match tracker. When a pill is frozen, this array is updated to 
                    # denote the two halves of the pill with a unique integer coming from past_pill_index.
past_pill_index:    # this index is incremented every time a pill is frozen and set in past_pill_tracker at the two cells 
    .word 1         # corresponding to the two halves of the recently frozen pill.

current_x: # the pills current x-coordinate (first half, top or left)
    .word 31
current_y: # the pills current y-coordinate (first half, top or left)
    .word 24 
current_orientation: # the pills current orientation. 0 for vertical, 1 for horizontal. Initially vertical
    .word 0

colour_1: # The colour of the top half when vertical and left half when horizontal (stored as pill colour state)
    .word 0
colour_2: # The colour of the bottom half when vertical and right half when horizontal (stored as pill colour state)
    .word 0
    
number_yellow_virus: # the number of yellow viruses still in the game
    .word 0 
    
number_red_virus: # the number of red viruses still in the game
    .word 0 
    
number_blue_virus: # the number blue viruses still in the game
    .word 0
    
gravity_index:      # to keep track of the number of iterations of the game loop and if it reaches 30, (i.e. one ~second passes), aritifically respond to s
    .word 0
    
gravity_index_reset_counter: # to keep track of the number of times gravity has been applied so that we can gradually increase the speed over time
    .word 0
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal New_Game
    jal Draw_Grid
game_loop:
    
################################## 1a. Check if key has been pressed ##########################################################
   
   key_press:
    lw $t0, ADDR_KBRD    # $t0 = base address for keyboard
    lw $t8, 0($t0)       # Load first word from keyboard into $t8
    beq $t8, 1, keyboard_input  #If first word == 1, key is pressed
    j draw_screen
    
    
#######################################################################################################################
    
################################### 1b. Check which key has been pressed ####################################################
    
    keyboard_input:     # A key is pressed
    
    lw $t2, 4($t0)      # load second word from keyboard
    
    beq $t2, 0x71, respond_to_Q     # branch to respond_to_Q when q is pressed (at end of program)
    beq $t2, 0x73, respond_to_S     # branch to respond_to_S when s is pressed 
    beq $t2, 0x61, respond_to_A     # branch to respond_to_A when a is pressed 
    beq $t2, 0x64, respond_to_D     # branch to respond_to_D when d is pressed
    beq $t2, 0x77, respond_to_W     # branch to respond_to_W when w is pressed
    beq $t2, 0x70, respond_to_P     # branch to respond_to_W when w is pressed
    
    j game_loop
    
#################################################################################################################
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	respond_to_S:
	jal Go_Down
	li $v0, 31
    li $a0, 45 # pitch
    li $a1, 3 # duration
    li $a2, 80 # instrument
    li $a3, 20 # volume
    syscall
				# li $v0, 31
    # li $a0, 47 # pitch
    # li $a1, 2 # duration
    # li $a2, 81 # instrument
    # li $a3, 20 # volume
    # syscall
	
	jal Check_Down
	bne $v0, $zero, new_spawn
	j key_press
	
	artificial_respond_to_S:
	jal Go_Down
	jal Check_Down
	bne $v0, $zero, new_spawn
	j key_press
	
	new_spawn:
	jal Freeze_Pill
	
				li $v0, 31
    li $a0, 47 # pitch
    li $a1, 25 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    
    continue_with_post_freeze_drop:
    
    jal Post_Freeze_Drop
    
    jal Erase_Virus_Drawings
    jal Draw_Grid
	
	jal Game_Over_Check
	bne $v0, $zero, Game_Over_Screen
	jal Game_Won_Check
	bne $v0, $zero, respond_to_Q
	jal New_Pill
	
	j key_press
	
	respond_to_A:
	jal Go_Left
		# li $v0, 31
    # li $a0, 45 # pitch
    # li $a1, 3 # duration
    # li $a2, 80 # instrument
    # li $a3, 20 # volume
    # syscall
	li $v0, 31
    li $a0, 45 # pitch
    li $a1, 25 # duration
    li $a2, 80 # instrument
    li $a3, 25 # volume
    syscall
	j key_press
	
	respond_to_D:
	jal Go_Right
	# li $v0, 31
    # li $a0, 45 # pitch
    # li $a1, 3 # duration
    # li $a2, 80 # instrument
    # li $a3, 20 # volume
    # syscall
	li $v0, 31
    li $a0, 45 # pitch
    li $a1, 25 # duration
    li $a2, 80 # instrument
    li $a3, 25 # volume
    syscall
	j key_press
	
	respond_to_W:
	jal Rotate
		li $v0, 31
    li $a0, 52 # pitch
    li $a1, 3 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
	j key_press
	
	respond_to_P:

			li $v0, 31
    li $a0, 65 # pitch
    li $a1, 2 # duration
    li $a2, 80 # instrument
    li $a3, 40 # volume
    syscall
	j Pause_Game
	unpause_game:
				li $v0, 31
    li $a0, 73 # pitch
    li $a1, 20 # duration
    li $a2, 80 # instrument
    li $a3, 40 # volume
    syscall
	j key_press
##################################	# 3. Draw the screen ########################################################################## 
	draw_screen:
	
	jal Draw_Grid
	
################################################################################################################################### 
	
	
################################## 4. Sleep ################################################################################################## 
	
	sleep:     # (see handout. sleeps for 20 ms here) 
    li $v0, 32
    li $a0, 20
    syscall
    
    jal Increment_Gravity_Index
    jal Gravity
    
################################################################################################################################### 

    # 5. Go back to Step 1
    j game_loop

##################################### Function: New_Game ##############################
# creates the initial state for a new game by setting the bottle cells and random viruses.

New_Game:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Grid caller

set_bottle:

#left_lip:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 29 # starting x coordinate of rectangle
    addi $t2, $zero, 24 # starting y coordinate of rectangle
    jal Rectangle_Setter

#right_lip:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 33 # starting x coordinate of rectangle
    addi $t2, $zero, 24 # starting y coordinate of rectangle
    jal Rectangle_Setter

#left_top:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 6 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 23 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#right_top:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 6 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 33 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter

#left:
    addi $a0, $zero, 26 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 23 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter

#right:
    addi $a0, $zero, 26 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 39 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter
    

#bottom:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 17 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 23 # starting x coordinate of rectangle
    addi $t2, $zero, 51 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #left of next pill staging area:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 27 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #right of next pill staging area:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 27 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        #bottom of next pill staging area:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 5 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 32 # starting y coordinate of rectangle
    jal Rectangle_Setter

set_viruses:

jal Initial_Viruses

set_new_game_pill:
jal Next_Pill
jal New_Pill

set_magnifying_glass:
jal Draw_Maginifying_Glass

set_red_virus_drawing:
jal Draw_Red_Virus

set_yellow_virus_drawing:
jal Draw_Yellow_Virus

set_blue_virus_drawing:
jal Draw_Blue_Virus

erase_uninitialized_viruses:
jal Erase_Virus_Drawings

draw_the_doc:
jal Draw_Doctor_Mario

end_initalization:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word
jr $ra


############################### FUNCTION: Cell_Getter ##################################
### A function to retrieve a given cell's value in the bitmap (64x64).
### Get the cell value at location ($a0, $a1) = (x_coord, y_coord).
### return value in $v0 is value at cell ($a0, $a1)

Cell_Getter:
la $t0, game_field      # $t0 stores the base address for the game state
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
lw $v0, 0( $t0 )        # return cell value in $v0

jr $ra
########################################################################################

################### FUNCTION: Cell_Setter ##################################
### A function to set the value of a given cell in the bitmap (64x64).
### Set the cell value at location ($a0, $a1) = (x_coord, y_coord) to $a2.

Cell_Setter:
la $t0, game_field      # $t0 stores the base adress for the game state
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
sw $a2, 0( $t0 )

jr $ra

##############################################################################

################### FUNCTION: Rectangle_Setter ##################################
### Set every cell in a rectangle of (height $a0, width $a1) at (x_position $t1, and y_position $t2) 
### with value in $a2

Rectangle_Setter:
la $t0, game_field     # $t0 stores the base address for the game state
add $t9, $t1, $zero    # $t9 now has x position of rectangle
add $t8, $t2, $zero    # $t8 now has y position of rectangle
sll $t8, $t8, 8        # multiply $t8 by 256 
sll $t9, $t9, 2        # multiply $t9 by 4
add $t0, $t0, $t9      # add x offset to $t0
add $t0, $t0, $t8      # add y offset to $t0

add $t6, $zero, $zero   # set starting value of index ($t6) to zero
set_rect_loop:
beq $t6, $a0, end_rect_loop # if $t6 == height ($t0), end rectangle loop

### Set a line (width $a1) ###
add $t5, $zero, $zero # set index value $t5=0

set_line_loop:
beq $t5, $a1, end_line_loop     # if $t5 == width ($a1), end loop.
sw $a2, 0( $t0 )                 # Store $a2 value at memory location $t0.
addi $t0, $t0, 4                # Increment $t0 to next location in memory
addi $t5, $t5, 1                # increment index value by 1
j set_line_loop

end_line_loop:
# set $t0 to first pixel on next line
addi $t0, $t0, 256  # bring $t0 to next line at last pixel
sll $t7, $a1, 2 # multiply width by 4 to determine number of mem adresses in one line
sub $t0, $t0, $t7 # go back number of memory address determined in above line
addi $t6, $t6, 1 # increment outer index

j set_rect_loop

end_rect_loop:
jr $ra

##############################################################################

################### FUNCTION: Draw_Grid ######################################

### Draws the grid

Draw_Grid:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Grid caller

addi $s5, $zero, 64 # the width of the grid is 64
addi $s6, $zero, 64 # the height of the grid is 64

add $t6, $zero, $zero           # set starting value of index ($t6) to zero
draw_grid_loop:
beq $t6, $s6, end_draw_grid # if $t6 == height ($s6), end rectangle loop

### Draw a line (width 64) ###

add $t5, $zero, $zero # set index value $t5=0
draw_row_loop:
beq $t5, $s5, end_row_loop     # if $t5 == width ($s5), end loop.
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1
jal Draw_Cell                   # draws colour on bitmap based on the value at the cell

addi $t5, $t5, 1                # increment index value by 1
j draw_row_loop                # jump to start of line drawing loop
end_row_loop:

addi $t6, $t6, 1                # increment row index
j draw_grid_loop

end_draw_grid:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word
jr $ra

##############################################################################

################### FUNCTION: Draw_Cell ######################################

### Draws the bitmap pixel corresponding to this cell ($a0, $a1)
Draw_Cell:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Cell caller

lw $s3, ADDR_DSPL       # $s3 stores the base adress for diplay
add $s0, $a0, $zero     # $s0 now has x_coord
add $s1, $a1, $zero     # $s1 now has y_coord
sll $s0, $s0, 2         # multiply $s0 by 4
sll $s1, $s1, 8         # multiply $s1 by 256
add $s3, $s3, $s0       # add x offset to $s3
add $s3, $s3, $s1       # add y offset to $s3

jal Cell_Getter         # get the value of the cell
add $t0, $zero, $v0     # store this value in $t0

add $t1, $zero, $zero   # comparator value
beq $t0, $t1, draw_black # check if cell value == 0
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_yellow_virus # check if cell value == 1
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_blue_virus # check if cell value == 2
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_red_virus # check if cell value == 3
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_red_pill # check if cell value == 4
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_yellow_pill # check if cell value == 5
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_blue_pill # check if cell value == 6
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_grey # check if cell value == 7
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_red_background # check if cell value == 8
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_green_background # check if cell value == 9
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_yellow_background # check if cell value == 10
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_blue_background # check if cell value == 11
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_brown_background # check if cell value == 12
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_mario_pants # check if cell value == 13
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_white_background # check if cell value == 14
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_grey_background # check if cell value == 15
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_light_grey_background # check if cell value == 16
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_skin_coloured_background # check if cell value == 17
addi $t1, $t1, 1   # increment comparator value
beq $t0, $t1, draw_eye_coloured_background # check if cell value == 18

# To test for faulty states:
j draw_white

draw_red_pill:
li $s4, 0xFF9079 # store the colour red pill in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_blue_pill:
li $s4, 0x76BDFF # store the colour blue pill in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_yellow_pill:
li $s4, 0xFFFF99 # store the colour yellow pill in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_yellow_virus:
li $s4, 0xFFFF00 # store the colour yellow virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_black:
li $s4, 0x000000 # store the colour black in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_red_virus:
li $s4, 0xFF0000 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_blue_virus:
li $s4, 0x0000FF # store the colour blue virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_grey:
li $s4, 0x808080 # store the colour grey in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_white:
li $s4, 0xFFFFFF # store the colour white in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_red_background:
li $s4, 0xFF0000 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_green_background:
li $s4, 0x00FF00 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_yellow_background:
li $s4, 0xFFFF00 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_blue_background:
li $s4, 0x0000FF # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_brown_background:
li $s4, 0x964B00 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_white_background:
li $s4, 0xFFFFFF # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_grey_background:
li $s4, 0x909090 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_light_grey_background:
li $s4, 0xDE3D3D3 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_skin_coloured_background:
li $s4, 0xF1C27D # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_eye_coloured_background:
li $s4, 0x303030 # store the colour red virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

draw_mario_pants:
li $s4, 0x0044FF # store the colour for mario's pants virus in $s4
sw $s4, 0( $s3 ) # draw pixel at $s3
j end_draw_cell

end_draw_cell:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word
jr $ra

##################################################################################

################### FUNCTION: Random_Num_14 #####################################
# SEE PROJECT HANDOUT FOR DESCRIPTION (stores a random number between 0 and 5 in $a0)
Random_Num_14:

li $v0, 42
li $a0, 0
li $a1, 15
syscall         # after this, the return value is in $a0

jr $ra
##############################################################################

################### FUNCTION: Random_Num_12 #####################################
# SEE PROJECT HANDOUT FOR DESCRIPTION (stores a random number between 0 and 12 in $a0)
Random_Num_12:

li $v0, 42
li $a0, 0
li $a1, 13
syscall         # after this, the return value is in $a0

jr $ra
##############################################################################

################### FUNCTION: Random_Num_3 #####################################
# SEE PROJECT HANDOUT FOR DESCRIPTION (stores a random number between 0 and 3 in $a0)
Random_Num_3:

li $v0, 42
li $a0, 0
li $a1, 3
syscall         # after this, the return value is in $a0

jr $ra
#################################################################################################

################### FUNCTION: Initialize_Viruses ################################################
### Initial virus states. 4 viruses in a random location. was initially 4 viruses to start a game.

Initial_Viruses:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Initial_Viruses caller

add $s5, $zero, $zero   # set loop index to 0
addi $s6, $zero, 11      # end of loop value

initial_virus_loop:

addi $t0, $zero, 24     # initial possible x
addi $t1, $zero, 38     # initial possible y

beq $s5, $s6, end_initial_viruses

add $t2, $t0, $zero     # x for virus 
add $t3, $t1, $zero     # y for virus 

jal Random_Num_14       # random x increment for the virus
add $t2, $t2, $a0

jal Random_Num_12       # random y increment for the virus
add $t3, $t3, $a0

### check if spot is already taken: ###
add $a0, $zero, $t2 # x coordinate argument for set cell
add $a1, $zero, $t3 # y coordinate argument for set cell
jal Cell_Getter # get cell value 
lw $s4, blank_cell # get blank_cell value
bne $v0, $s4, initial_virus_loop # if the cell_value is not blank, redo loop

jal Random_Num_3
add $s7, $a0, $zero # storing random number in $s7
addi $t7, $zero, 1  # comparator value set to 1
beq $s7, $zero, set_initial_virus_red # if random num is 0, make virus red
beq $s7, $t7, set_initial_virus_blue # if random num is 1, make virus blue
# else (random num is 2), make virus yellow.

set_initial_virus_yellow:
add $a0, $zero, $t2 # x coordinate argument for set cell
add $a1, $zero, $t3 # y coordinate argument for set cell
lw $s0, yellow_virus # get the state value for a yellow virus
add $a2, $s0, $zero # set the state argument for set cell to yellow_virus

la $s1, number_yellow_virus # load the adress storing the number of yellow_viruses
lw $s2, number_yellow_virus # load the number of yellow_viruses
addi $s2, $s2, 1            # increment the number of yellow_viruses by 1
sw $s2, 0($s1)              # update this number in memory

j set_virus

set_initial_virus_red:
add $a0, $zero, $t2 # x coordinate argument for set cell
add $a1, $zero, $t3 # y coordinate argument for set cell
lw $s0, red_virus # get the state value for a red virus
add $a2, $s0, $zero # set the state argument for set cell to red_virus

la $s1, number_red_virus   # load the adress storing the number of red_viruses
lw $s2, number_red_virus   # load the number of red_viruses
addi $s2, $s2, 1            # increment the number of red_viruses by 1
sw $s2, 0($s1)              # update this number in memory

j set_virus

set_initial_virus_blue:
add $a0, $zero, $t2 # x coordinate argument for set cell
add $a1, $zero, $t3 # y coordinate argument for set cell
lw $s0, blue_virus # get the state value for a blue virus
add $a2, $s0, $zero # set the state argument for set cell to blue_virus

la $s1, number_blue_virus   # load the adress storing the number of blue_viruses
lw $s2, number_blue_virus   # load the number of blue_viruses
addi $s2, $s2, 1            # increment the number of blue_viruses by 1
sw $s2, 0($s1)              # update this number in memory

j set_virus

set_virus:
jal Cell_Setter # set the virus state
addi $s5, $s5, 1 # increment loop index
j initial_virus_loop


end_initial_viruses:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
#######################################################################################

################### FUNCTION: Next_Pill ################################################
### Creates a new next pill in the next pill box (to be called by new pill)

Next_Pill:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Cell caller

li $s0, 17  # store the next pill x position in $s0
li $s1, 28   # store the next pill y position in $s1

# We need a random colour (from pill states 4,5 or 6)
jal Random_Num_3
addi $t6, $zero, 1  # Storing one in t6 for randum num comparison

beq $a0, $zero, new_red_pill_half
beq $a0, $t6, new_yellow_pill_half

new_blue_pill_half:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 6               # state for blue pill is 6
jal Cell_Setter
j second_pill_half

new_red_pill_half:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 4               # state for red pill is 6
jal Cell_Setter
j second_pill_half

new_yellow_pill_half:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 5               # state for yellow pill is 5
jal Cell_Setter
j second_pill_half

second_pill_half:
addi $s1, $s1, 1        # increment y coordinate by 1

# We need a random colours (from pill states 4,5 or 6)
jal Random_Num_3
addi $t6, $zero, 1  # Storing one in t6 for randum num comparison

beq $a0, $zero, new_red_pill_half_2
beq $a0, $t6, new_yellow_pill_half_2

new_blue_pill_half_2:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 6               # state for blue pill is 6
jal Cell_Setter
j end_next_pill

new_red_pill_half_2:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 4               # state for red pill is 6
jal Cell_Setter
j end_next_pill

new_yellow_pill_half_2:
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
li $a2, 5               # state for yellow pill is 5
jal Cell_Setter
j end_next_pill

end_next_pill:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#######################################################################################

################### FUNCTION: New_Pill ################################################
### Creates a new pill at the top of the playing field (initial location) with random colours

New_Pill:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Cell caller

# We first update the pill state
lw $s0, initial_x   # store the initial x position in $s0
lw $s1, initial_y   # store the initial y position in $s1
la $t2, current_x   # load the address for the current x position of the pill
la $t3, current_y   # load the address for the current y position of the pill
sw $s0, 0($t2)      # update current x to initial x
sw $s1, 0($t3)      # update current y to initial y

li $t4, 0                       # store 0 in $t4
la $t5, current_orientation     # retrieve the address for the current orientation
sw $t4, 0($t5)                  # set current orientation to 0 (vertical)

first_new_pill_half:
addi $a0, $zero, 17
addi $a1, $zero, 28

jal Cell_Getter

la $s7, colour_1        # get the adress for the first colour
add $t7, $zero, $v0      # store pill state to $t7
sw $t7, 0($s7)          # set colour 1 to pill state
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
lw $a2, colour_1       # state for first pill half
jal Cell_Setter
j second_new_pill_half

second_new_pill_half:
addi $s1, $s1, 1

addi $a0, $zero, 17
addi $a1, $zero, 29

jal Cell_Getter

la $s7, colour_2        # get the adress for the second colour
add $t7, $zero, $v0      # store pill state to $t7
sw $t7, 0($s7)          # set colour 2 to pill state
add $a0, $s0, $zero     # x coordinate for function call
add $a1, $s1, $zero     # y coordinate for function call
lw $a2, colour_2       # state for second pill half
jal Cell_Setter
j end_new_pill

end_new_pill:
jal Next_Pill

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
#########################################################################################

################### FUNCTION: Set_Vertical_Pill ################################################
### Sets a new vertical pill at location ($a0, $a1) with colour 1 state ($a2) and colour 2 state ($a3).

Set_Vertical_Pill:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Set_Vertical_Pill caller

# We first update the pill state
add $s0, $zero, $a0   # store the x position in $s0
add $s1, $zero, $a1   # store the y position in $s1
la $t2, current_x   # load the address for the current x position of the pill
la $t3, current_y   # load the address for the current y position of the pill
sw $s0, 0($t2)      # update current x to new x
sw $s1, 0($t3)      # update current y to new y

la $t4, colour_1    # load the address for colour 1 of the pill
sw $a2, 0($t4)      # update colour 1 state for the pill
la $t5, colour_2    # load the address for colour 2 of the pill
sw $a3, 0($t5)      # update colour 2 state for the pill

add $t7, $zero, $zero       # set $t7 to 0
la $t6, current_orientation # load_orientation address
sw $t7, 0($t6)              # set orientation to 0 (vertical)

add $a0, $a0, $zero         # x coordinate parameter for Cell_Setter (first half)
add $a1, $a1, $zero         # y coordinate parameter for Cell_Setter (first half)
add $a2, $a2, $zero         # colour parameter for colour 1 (first half)

jal Cell_Setter

addi $a1, $a1, 1            # increment y coordinate parameter for Cell_Setter (second half)
add $a2, $a3, $zero         # colour parameter for colour 2 (second half)

jal Cell_Setter

end_vertical_pill_set:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

################### FUNCTION: Set_Horizontal_Pill ################################################
### Sets a new horizontal pill at location ($a0, $a1) with colour 1 state ($a2) and colour 2 state ($a3).

Set_Horizontal_Pill:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Set_Horizontal_Pill caller

# We first update the pill state
add $s0, $zero, $a0   # store the x position in $s0
add $s1, $zero, $a1   # store the y position in $s1
la $t2, current_x   # load the address for the current x position of the pill
la $t3, current_y   # load the address for the current y position of the pill
sw $s0, 0($t2)      # update current x to new x
sw $s1, 0($t3)      # update current y to new y

la $t4, colour_1    # load the address for colour 1 of the pill
sw $a2, 0($t4)      # update colour 1 state for the pill
la $t5, colour_2    # load the address for colour 2 of the pill
sw $a3, 0($t5)      # update colour 2 state for the pill

addi $t7, $zero, 1          # set $t7 to 1
la $t6, current_orientation # load_orientation address
sw $t7, 0($t6)              # set orientation to 1 (horizontal)

add $a0, $a0, $zero         # x coordinate parameter for Cell_Setter (first half)
add $a1, $a1, $zero         # y coordinate parameter for Cell_Setter (first half)
add $a2, $a2, $zero         # colour parameter for colour 1 (first half)

jal Cell_Setter

addi $a0, $a0, 1            # increment x coordinate parameter for Cell_Setter (second half)
add $a2, $a3, $zero         # colour parameter for colour 2 (second half)

jal Cell_Setter

end_horizontal_pill_set:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
#########################################################################################

################### FUNCTION: Erase_Pill ################################################
### Erases the current game pill from the game field.

Erase_Pill:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Erase_Pill caller

lw $t2, current_x   # load the current x position of the pill
lw $t3, current_y   # load the current y position of the pill
lw $t4, blank_cell  # load the blank cell state
lw $t5, current_orientation # load the current pill's orientation

add $a0, $zero, $t2  # set x coordinate parameter for Cell_Setter
add $a1, $zero, $t3  # set y coordinate parameter for Cell_Setter
add $a2, $zero, $t4  # set blank cell state for Cell_Setter call

jal Cell_Setter

beq $t5, $zero, erase_vertical_pill  # If current orientation is 0 (vertical pill), branch to that case

erase_horizontal_pill:
addi $a0, $a0, 1    # increment x coordinate
jal Cell_Setter     # set second pill half to blank
j end_erase_pill

erase_vertical_pill:
addi $a1, $a1, 1    # increment y coordinate
jal Cell_Setter     # set second pill half to blank
j end_erase_pill

end_erase_pill:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
#########################################################################################

################### FUNCTION: Go_Down ################################################
### Moves the current pill down 

Go_Down:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Go_Down caller

jal Check_Down          # check whether we can go down
bne $v0, $zero, end_go_down  # if return value is not 0 (i.e. cant go down), do nothing

jal Erase_Pill          # Erase the current pill from the game_field

lw $t0, current_y       # load the current y_value
addi $t0, $t0, 1         # increment y value
la $t1, current_y       # get address for current y_value
sw $t0, 0($t1)          # store new y_value

lw $a0, current_x      # load the x coordinate parameter
lw $a1, current_y      # load the y coordinate parameter
lw $a2, colour_1       # load the first half colour parameter
lw $a3, colour_2       # load the second half colour parameter

lw $s0, current_orientation # load orientation
beq $s0, $zero, go_down_vertical # if orientation is 0 (vertical), branch to vertical case

go_down_horizontal:
jal Set_Horizontal_Pill
j end_go_down

go_down_vertical:
jal Set_Vertical_Pill

end_go_down:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#########################################################################################

################### FUNCTION: Go_Left ################################################
### Moves the current pill left 

Go_Left:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Go_Down caller

jal Check_Left          # check whether we can move left
bne $v0, $zero, end_go_left  # if return value is not 0 (i.e. cant go left), do nothing

jal Erase_Pill          # Erase the current pill from the game_field

lw $t0, current_x       # load the current x_value
addi $t0, $t0, -1       # decrement x value
la $t1, current_x       # get address for current x_value
sw $t0, 0($t1)          # store new x_value

lw $a0, current_x      # load the x coordinate parameter
lw $a1, current_y      # load the y coordinate parameter
lw $a2, colour_1       # load the first half colour parameter
lw $a3, colour_2       # load the second half colour parameter

lw $s0, current_orientation # load orientation
beq $s0, $zero, go_left_vertical # if orientation is 0 (vertical), branch to vertical case

go_left_horizontal:
jal Set_Horizontal_Pill
j end_go_left

go_left_vertical:
jal Set_Vertical_Pill

end_go_left:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#########################################################################################

##################### FUNCTION: Go_Right ################################################
### Moves the current pill right 

Go_Right:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Go_Down caller

jal Check_Right          # check whether we can move right
bne $v0, $zero, end_go_right  # if return value is not 0 (i.e. cant go right), do nothing

jal Erase_Pill          # Erase the current pill from the game_field

lw $t0, current_x       # load the current x_value
addi $t0, $t0, 1        # increment x value
la $t1, current_x       # get address for current x_value
sw $t0, 0($t1)          # store new x_value


lw $a0, current_x      # load the x coordinate parameter
lw $a1, current_y      # load the y coordinate parameter
lw $a2, colour_1       # load the first half colour parameter
lw $a3, colour_2       # load the second half colour parameter

lw $s0, current_orientation # load orientation
beq $s0, $zero, go_right_vertical # if orientation is 0 (vertical), branch to vertical case

go_right_horizontal:
jal Set_Horizontal_Pill
j end_go_right

go_right_vertical:
jal Set_Vertical_Pill

end_go_right:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#########################################################################################

##################### FUNCTION: Rotate ################################################
### Rotates the current pill 90 degrees clockwise 

Rotate:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Rotate caller

jal Check_Rotation          # check whether we can rotate
bne $v0, $zero, end_rotate  # if return value is not 0 (i.e. cant rotate), do nothing

jal Erase_Pill          # Erase the current pill from the game_field

lw $t0, current_x       # load the current x value
lw $t1, current_y       # load the current y value
lw $t2, colour_1        # load colour 1
lw $t3, colour_2        # load colour 2
lw $t4, current_orientation # load current orientation

beq $t4, $zero, vertical_rotate # if current orientation is 0 (vertical), branch to vertical rotation case

horizontal_rotate:
add $a0, $t0, $zero     # same x coordinate
addi $a1, $t1, -1       # decrement y coordinate by 1
add $a2, $t2, $zero     # colour 1 for new pill is colour 1 for old pill
add $a3, $t3, $zero     # colour 2 for new pill is colour 2 for old pill
jal Set_Vertical_Pill   # note that this function takes care of setting the current_orientation
j end_rotate

vertical_rotate:
add $a0, $t0, $zero       # same x coordinate
addi $a1, $t1, 1         # increment y coordinate by 1
add $a2, $t3, $zero       # colour 1 for new pill is colour 2 for old pill
add $a3, $t2, $zero       # colour 2 for new pill is colour 1 for old pill
jal Set_Horizontal_Pill   # note that this function takes care of setting the current_orientation
j end_rotate

end_rotate:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#########################################################################################

################################### FUNCTION: Check_Left ##############################
### Checks whether clicking the a key is a valid move
### Returns $v0 = 0 if it is and $v0 = 1, otherwise.

Check_Left:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Rotate caller

lw $t1, current_x       # load the current x value
lw $t2, current_y       # load the current y value
lw $t3, current_orientation # load the current orientation
addi $t1, $t1, -1       # decrement x value by 1

add $a0, $t1, $zero       # x parameter for cell getter call
add $a1, $t2, $zero       # y parameter for cell getter call
jal Cell_Getter


bne $v0, $zero, bad_check_left # If cell was not blank, return 1
bne $t3, $zero, good_check_left # If cell was blank and pill was horizontal, return good check

vertical_check_left:    # When $t3 is 0 (current orientation vertical), we must check whether the cell beneath the one just check is also clear
addi $a1, $a1, 1        # increment y value by 1 to now check bottom half of pill move left
jal Cell_Getter

beq $v0, $zero, good_check_left  # If cell was blank, return good check. Else, proceed to bad check.

bad_check_left:
addi $v0, $zero, 1 # set return value to 1
j end_check_left

good_check_left:
add $v0, $zero, $zero # set return value to 0

end_check_left:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

#########################################################################################

###################### FUNCTION: Check_Right ############################################
### Checks whether clicking the d key is a valid move
### Returns $v0 = 0 if it is and $v0 = 1, otherwise.

Check_Right:

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Rotate caller

lw $t1, current_x       # load the current x value
lw $t2, current_y       # load the current y value
lw $t3, current_orientation # load the current orientation

add $a0, $t1, $zero       # x parameter for cell getter calls
add $a1, $t2, $zero       # y parameter for cell getter calls

beq $t3, $zero, vertical_check_right # If pill is vertical, branch to vertical check

# else check cell to the right of our horizontal pill (x=x+2, y=y)
horizontal_check_right:
addi $a0, $a0, 2        # increment x by 2
jal Cell_Getter         # check whether cell is blank
beq $v0, $zero, good_check_right    # if cell is blank (i.e. $v0==0), return good check
j bad_check_right       # else, return bad check

vertical_check_right:
addi $a0, $a0, 1        # increment x value by 1
jal Cell_Getter         # check cell to the right of top pill half is empty

bne $v0, $zero, bad_check_right  # If cell not blank, return bad check.

# else, check cell to the right of bottom pill half is empty

addi $a1, $a1, 1        # increment y value by 1
jal Cell_Getter         # check cell to the right of bottom pill half is empty
beq $v0, $zero, good_check_right    # If it is, branch to good check. Else, continue to bad check.

bad_check_right:
addi $v0, $zero, 1 # set return value to 1
j end_check_right

good_check_right:
add $v0, $zero, $zero # set return value to 0

end_check_right:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

###################### FUNCTION: Check_Rotation ##################################################
### Checks whether the pill is clear to rotate.
### Returns $v0 = 0 if it is and $v0 = 1, otherwise.

Check_Rotation:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Rotate caller

lw $t1, current_x       # load the current x value
lw $t2, current_y       # load the current y value
lw $t3, current_orientation # load the current orientation

add $a0, $t1, $zero       # x parameter for cell getter calls
add $a1, $t2, $zero       # y parameter for cell getter calls

beq $t3, $zero, vertical_check_rotation # If pill is vertical, branch to vertical check

# else, check horizontal
addi $a1, $a1, -1 # decrement y by 1
jal Cell_Getter
bne $v0, $zero, bad_check_rotation # if cell above left half is not clear, return 1

addi $a0, $a0, 1 # increment x by 1
jal Cell_Getter
bne $v0, $zero, bad_check_rotation # if cell above right half is not clear, return 1
j good_check_rotation # if both cells about horizontal pill are clear, return 0

vertical_check_rotation:
addi $a0, $a0, 1 # increment x by 1
jal Cell_Getter
bne $v0, $zero, bad_check_rotation # if cell to the right of top half is not clear, return 1

addi $a1, $a1, 1 # increment y by 1
jal Cell_Getter
bne $v0, $zero, bad_check_rotation # if cell to the right of bottom half is not clear, return 1
j good_check_rotation # if both cells to the right of vertical pill are clear, return 0

bad_check_rotation:
addi $v0, $zero, 1 # set return value to 1
j end_check_rotation

good_check_rotation:
add $v0, $zero, $zero # set return value to 0

end_check_rotation:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

###################### FUNCTION: Check_Down ##################################################
### Checks whether the pill is clear to move down when clicking s.
### Returns $v0 = 0 if it is and $v0 = 1, otherwise.

Check_Down:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Down caller

lw $t1, current_x       # load the current x value
lw $t2, current_y       # load the current y value
lw $t3, current_orientation # load the current orientation

add $a0, $t1, $zero       # x parameter for cell getter calls
add $a1, $t2, $zero       # y parameter for cell getter calls

beq $t3, $zero, vertical_check_down # If pill is vertical, branch to vertical down check

# else, check down for horizontal pill

addi $a1, $a1, 1        # increment y coordinate by one (to check cell below left half)
jal Cell_Getter

bne $v0, $zero, bad_check_down  # if that cell is not clear/blank (i.e. $v0 = 1), return 1

addi $a0, $a0, 1        # else, increment x coordinate by one (to check cell below right half)
jal Cell_Getter

beq $v0, $zero, good_check_down     # if that cell is clear, horizontal pill is free to move down (return 0)
j bad_check_down                    # otherwise, it is not, return 1

vertical_check_down:
addi $a1, $a1, 2        # increment y coordiante by 2 to check cell is blank/empty below vertical pill
jal Cell_Getter
beq $v0, $zero, good_check_down     # if cell is clear (i.e. $v0 = 0), return good check (return 0)
#else, proceed to bad check

bad_check_down:
addi $v0, $zero, 1 # set return value to 1
j end_check_down

good_check_down:
add $v0, $zero, $zero # set return value to 0

end_check_down:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

###################### FUNCTION: Freeze_Pill #####################################################
### This function freezes a pill in its current location
### (used when either of the player's capsule's halves vertically hit another object (see handout))

Freeze_Pill:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Down caller

lw $t1, current_x       # load the current x value
lw $t2, current_y       # load the current y value
lw $t3, current_orientation # load the current orientation
lw $t4, colour_1            # load the first colour (top or left half)
lw $t5, colour_2            # load the second_colour (bottom or right half)

add $a0, $zero, $t1      # x coordinate for cell setter call
add $a1, $zero, $t2      # y coordinate for cell setter call
add $a2, $zero, $t4      # first pill colour to set

jal Cell_Setter

beq $t3, $zero, freeze_vertical  # if the pill is vertical, handle that case

# else, handle horizontal case
freeze_horizontal:
addi $a0, $a0, 1 # increment x coordinate by 1 so that (x,y) now refers to the cell to the right of original x and y coordinates
add $a2, $zero, $t5  # second pill colour to set
jal Cell_Setter
j end_freeze

freeze_vertical:
addi $a1, $a1, 1    # increment y coordinate by 1 so that (x,y) now refers to cell below original x and y coordinates
add $a2, $zero, $t5  # second pill colour to set
jal Cell_Setter

end_freeze:

update_past_pill_tracker:
lw $s7, past_pill_index  # load the current past pill index
addi $s7, $s7, 1         # increment the past pill index by 1
sw $s7, past_pill_index  # store this new past pill index in memory

add $a0, $t1, $zero     # x coordinate of pill half 1 in a0
add $a1, $t2, $zero     # y coordinate of pill half 1 in a1
add $a2, $s7, $zero     # past pill index to set

jal Past_Pill_Setter    # set first half of pill in past_pill_tracker

beq $t3, $zero, update_past_pill_tracker_vertical # If pill is vertical (i.e. orientation in t3 is 0), proceed to that case
# else, consider horizontal case
addi $a0, $a0, 1  # increment x coordinate by 1 (y coordinate for secon pill half and setting value do not change)
jal Past_Pill_Setter # set second half of horizontal pill in past_pill_tracker
j return_coordinates    # proceed to the returning coordiantes step

update_past_pill_tracker_vertical:
addi $a1, $a1, 1  # increment y coordinate by 1 (x coordinate for second pill half and setting value do not change)
jal Past_Pill_Setter # set second half of vertical pill in past_pill_tracker
# procced to returning coordinates

return_coordinates:
add $a0, $t1, $zero     # x coordinate of pill half 1 in a0
add $a1, $t2, $zero     # y coordinate of pill half 1 in a1

beq $t3, $zero, return_vertical_coordinates # if orientation is 0 (vertical, proceed to that case)

#else, consider horizontal case
addi $t1, $t1, 1        # increment x coordinate by 1
add $a2, $t1, $zero     # x coordiante for second half of horizontal pill
add $a3, $t2, $zero     # y coordinate for second pill half does not change
j end_freeze_return

return_vertical_coordinates:
add $a2, $t1, $zero     # x coordinate does not change for second half of vertical pill
addi $t2, $t2, 1        # increment y coordinate by 1
add $a3, $t2, $zero     # y coordinate for second pill half

end_freeze_return:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

########################## FUNCTION: Game_Won_Check #############################################
### Checks whether the game won condition has been reached. That is, if all 3 virus counts in memory
### are 0. returns 1 in $v0 if game won condition is reached and 0 in $v0 if it is not.

Game_Won_Check:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Game_Won_Check caller

lw $s0, number_yellow_virus # load the number of yellow viruses into $s0
bne $s0, $zero, game_not_won # if number of yellow viruses is not 0, the game has not been won
lw $s0, number_blue_virus # load the number of blue viruses into $s0
bne $s0, $zero, game_not_won # if number of blue viruses is not 0, the game has not been won
lw $s0, number_red_virus # load the number of red viruses into $s0
bne $s0, $zero, game_not_won # if number of red viruses is not 0, the game has not been won

game_won:   # if we reached this point the game has been won (all virus counts are zero)
addi $v0, $zero, 1  # load return value of 1 (for game being won)

				li $v0, 33
    li $a0, 60 # pitch
    li $a1, 1000 # duration
    li $a2, 100 # instrument
    li $a3, 40 # volume
    syscall
    				li $v0, 33
    li $a0, 64 # pitch
    li $a1, 1000 # duration
    li $a2, 100 # instrument
    li $a3, 40 # volume
    syscall
    				li $v0, 33
    li $a0, 67 # pitch
    li $a1, 1000 # duration
    li $a2, 100 # instrument
    li $a3, 40 # volume
    syscall
    
        				li $v0, 33
    li $a0, 64 # pitch
    li $a1, 1000 # duration
    li $a2, 100 # instrument
    li $a3, 40 # volume
    syscall
    
    				li $v0, 33
    li $a0, 60 # pitch
    li $a1, 1000 # duration
    li $a2, 100 # instrument
    li $a3, 40 # volume
    syscall
    
            				li $v0, 33
    li $a0, 69 # pitch
    li $a1, 2000 # duration
    li $a2, 80 # instrument
    li $a3, 40 # volume
    syscall

j end_game_won_check

game_not_won:
addi $v0, $zero, 0  # load return value of 0 (for game not being won)
j end_game_won_check

end_game_won_check:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

########################## FUNCTION: Game_Over_Check #############################################
### Checks whether the game over condition has been reached. (whether the any of the 3 cells
### connecting the pill spawn to the rectangular bottle area are not empty). This check is made
### right before a pill spawns. The 3 cells to be checked are (30, 27), (31, 27), and (32, 27).
### returns 1 in $v0 if game over condition is reached and 0 in $v0 if it is not.

Game_Over_Check:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Down caller

li $a1, 27              # the y coordinate of all 3 cells we need to check
li $a0, 30              # the first x coordinate we need to check

jal Cell_Getter         # get cell (30, 27)'s value

bne $v0, $zero, game_is_over # if cell not blank, return game over (1)

# else, check (31, 27)
addi $a0, $a0, 1    # increment x coordinate
jal Cell_Getter     # get cell (31, 27)'s value

bne $v0, $zero, game_is_over # if cell not blank, return game over (1)

# else, check (31, 27)
addi $a0, $a0, 1    # increment x coordinate
jal Cell_Getter     # get cell (32, 27)'s value

bne $v0, $zero, game_is_over # if cell not blank, return game over (1)

# else, all 3 cells are clear. return game not over
j game_not_over

game_is_over:
addi $v0, $zero, 1 # return 1 to indicate game over condition is reached
    
j end_game_over_check

game_not_over:
add $v0, $zero, $zero # return 0 to indicate game over condition is reached

end_game_over_check:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Get_Match_Tracker_Cell ##################################
### A function to retrieve a given cell's value in our match tracker array (64x64).
### Get the cell value at location ($a0, $a1) = (x_coord, y_coord).
### return value in $v0 is value at cell ($a0, $a1) (0 for not part of a match and 1 for part of a match)

Get_Match_Tracker_Cell:

la $t0, match_tracker   # $t0 stores the base address for our match tracker
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
lw $v0, 0( $t0 )        # return cell value in $v0

jr $ra

##################################################################################################

############################### FUNCTION: Set_Match_Tracker_Cell ##################################
### A function to set a given cell's value in our match tracker array (64x64).
### Set the cell value at location ($a0, $a1) = (x_coord, y_coord) to $a2.

Set_Match_Tracker_Cell:

la $t0, match_tracker   # $t0 stores the base adress for for our match tracker
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
sw $a2, 0( $t0 )

jr $ra

##################################################################################################

############################### FUNCTION: Check_Red_Left #########################################
### returns the number of red cells to the left of input ($a0, $a1) in $v0.
### Either red pill halves or red viruses

Check_Red_Left:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Red_Left caller

addi $t1, $zero, 0         # initlaize counter for number of red cells to the left to 0

check_red_left_loop:
addi $a0, $a0, -1           # decrement x value by 1

jal Cell_Getter             # check cell for red

li $t2, 3         # comparator of 3 for $v0 (3 corresponds to red virus)
beq $v0, $t2, yes_red_left  # if cell is red virus, branch to yes_red_left
li $t2, 4                     # increment comparator for $v0 to 4 (4 corresponds to red virus)
beq $v0, $t2, yes_red_left # if $v0 is 4, branch to yes_red_left
j end_check_red_left       # if we get to this line, $v0 was not 4 or 3, end count

yes_red_left:
addi $t1, $t1, 1            # increment counter by 1
j check_red_left_loop

end_check_red_left:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Red_Right #########################################
### returns the number of red cells to the right of input ($a0, $a1) in $v0.
### Either red pill halves or red viruses

Check_Red_Right:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Red_Left caller

addi $t5, $zero, 0         # initlaize counter for number of red cells to the right to 0

check_red_right_loop:
addi $a0, $a0, 1           # increment x coordiante value by 1

jal Cell_Getter             # check cell for red

li $t6, 3         # comparator of 3 for $v0 (3 corresponds to red virus)
beq $v0, $t6, yes_red_right  # if cell is red virus, branch to yes_red_left
li $t6, 4           # increment comparator for $v0 to 4 (4 corresponds to red virus)
beq $v0, $t6, yes_red_right # if $v0 is 4, branch to yes_red_right
j end_check_red_right      # if we get to this line, $v0 was not 4 or 3, end count

yes_red_right:
addi $t5, $t5, 1            # increment counter by 1
j check_red_right_loop

end_check_red_right:
add $v0, $zero, $t5     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Red_Horizontal #########################################
### Checks whether there are any red horizontal matches for red cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Red_Horizontal:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_matches caller

addi $s0, $zero, 1      # counter for number of red cells in a row. starts at 1 for ($a0, $a1)

jal Check_Red_Left      # check number of red cells to the left
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells to left
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for right check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for right check call


jal Check_Red_Right     # check number of red cells to the right
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells to right


blt $s0, 4, end_check_red_horizontal # if total count of red cells in a row horizontally is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set left loop counter ( when greater than number of red cells to the left, we are done setting left)
add $t2, $zero, $zero           # set right loop counter ( when greater than number of red cells to the right, we are done setting right)
set_red_left_match:             # now we set the cells to the left
addi $a0, $a0, -1               # decrement x value by 1
addi $t1, $t1, 1                # increlement left loop counter
bgt $t1, $s5, set_red_right_match # if loop counter is greater than number of red cells to the left, proceed to setting red cells to the right 

jal Set_Match_Tracker_Cell
j set_red_left_match

set_red_right_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_red_right:                  # now we set the cells to the right

addi $a0, $a0, 1               # increment x value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_red_horizontal # if loop counter is greater than number of red cells to the right, proceed to end

jal Set_Match_Tracker_Cell
j set_red_right

end_check_red_horizontal:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Erase_Matches #########################################
### A function to erase the matches currently stored in match_tracker

Erase_Matches:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_mathes caller

addi $s5, $zero, 64 # the width of the grid is 64
addi $s6, $zero, 64 # the height of the grid is 64

add $t6, $zero, $zero           # set starting value of index ($t6) to zero

erase_matches_loop:
beq $t6, $s6, end_erase_matches # if $t6 == height ($s6), end erasing loop

### Erase matches in a line (width 64) ###

add $t5, $zero, $zero # set index value $t5=0

erase_matches_row_loop:
beq $t5, $s5, end_erase_matches_row_loop    # if $t5 == width ($s5), end loop.
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1
jal Get_Match_Tracker_Cell      # check whether coordinate is part of a match

bne $v0, 1, end_erase_cell_check        # if return value is not 1, cell is not part of a match, and we dont want to erase it

# else, erase the cell! Start by updating the necessary memory
erase_in_memory:
add $s0, $zero, $t5             # store current x index in $s0
add $s1, $zero, $t6             # store current y index in $s1
jal Update_Memory_Before_Erase  # update the necessary data in memory

# now, we erase in the game field and update the match tracker
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1

lw $a2, blank_cell              # value to set is for a blank cell
jal Cell_Setter

add $a2, $zero, $zero           # reset corresponding cell in match_tracker array to 0
jal Set_Match_Tracker_Cell

end_erase_cell_check:
addi $t5, $t5, 1                        # increment index value by 1
j erase_matches_row_loop                # jump to start of line erasing loop

end_erase_matches_row_loop:

addi $t6, $t6, 1                # increment row index
j erase_matches_loop

end_erase_matches:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

############################### FUNCTION: Update_Memory_Before_Erase ##############################
### This function is called strictly by Erase_Matches, and updates the necessary data in memory
### for the cell at coordinates ($s0, $s1), based on its value. For instance, if it's a virus,
### it decrements the necessary counter in memory.

Update_Memory_Before_Erase:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Update_Memory_Before_Erase caller

add $a0, $s0, $zero     # x coordinate for cell getter call
add $a1, $s1, $zero     # y coordinate for cell getter call

jal Cell_Getter

beq $v0, 4, update_past_pill_memory # if cell is a red pill, update past pill tracker array
beq $v0, 5, update_past_pill_memory # if cell is a yellow pill, update past pill tracker array
beq $v0, 6, update_past_pill_memory # if cell is a blue pill, update past pill tracker array
beq $v0, 1, update_yellow_virus_count  # if cell is a yellow virus, update yellow virus counter in memory
beq $v0, 2, update_blue_virus_count  # if cell is a blue virus, update blue virus counter in memory
beq $v0, 3, update_red_virus_count  # if cell is a red virus, update red virus counter in memory
j end_update_memory_before_erase    # if cell is not a virus or pill half, nothing to update in memory

update_past_pill_memory:
add $a0, $s0, $zero     # x coordinate for past pill setter call
add $a1, $s1, $zero     # y coordinate for past pill setter call
add $a2, $zero, $zero   # value to set is 0, to remove this as a "past pill" in our game state
jal Past_Pill_Setter    # set the value at (s0, s1) in our past pill tracker to 0
j end_update_memory_before_erase # memory updates before erasing are done

update_yellow_virus_count:
lw $s2, number_yellow_virus # load the current number of yellow viruses into s2
addi $s2, $s2, -1            # decrement this number by 1
sw $s2, number_yellow_virus  # update number of yellow viruses in memory to the new value
j end_update_memory_before_erase # memory updates before erasing are done

update_blue_virus_count:
lw $s2, number_blue_virus # load the current number of blue viruses into s2
addi $s2, $s2, -1            # decrement this number by 1
sw $s2, number_blue_virus  # update number of blue viruses in memory to the new value
j end_update_memory_before_erase # memory updates before erasing are done

update_red_virus_count:
lw $s2, number_red_virus # load the current number of red viruses into s2
addi $s2, $s2, -1            # decrement this number by 1
sw $s2, number_red_virus  # update number of red viruses in memory to the new value
j end_update_memory_before_erase # memory updates before erasing are done

end_update_memory_before_erase:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra


##################################################################################################

############################### FUNCTION: Check_Blue_Left #########################################
### returns the number of blue cells to the left of input ($a0, $a1) in $v0.
### Either blue pill halves or blue viruses. Iterates through the bottle from bottom to top.

Check_Blue_Left:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_mathes caller

li $t1, 0               # set counter number to 0

check_blue_left_loop:
addi $a0, $a0, -1       # decrement x value by 1
jal Cell_Getter         # check cell for blue
beq $v0, 6, yes_blue_left   # if there's a blue pill cell to the left, jump to yes
beq $v0, 2, yes_blue_left   # if there's a blue virus to the left, jump to yes
j end_blue_left_check       # cell to the left is not blue, so we end out count

yes_blue_left:
addi $t1, $t1, 1        # increment counter by 1
j check_blue_left_loop  # go back to loop and check cell to the left

end_blue_left_check:
add $v0, $t1, $zero     # store count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

############################### FUNCTION: Check_Blue_Right #########################################
### returns the number of blue cells to the right of input ($a0, $a1) in $v0.
### Either blue pill halves or blue viruses

Check_Blue_Right:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_mathes caller

li $t1, 0               # set counter number to 0

check_blue_right_loop:
addi $a0, $a0, 1       # increment x value by 1
jal Cell_Getter
beq $v0, 6, yes_blue_right   # if there's a blue pill cell to the right, jump to yes
beq $v0, 2, yes_blue_right   # if there's a blue virus to the right, jump to yes
j end_blue_right_check       # cell to the right is not blue, so we end our count

yes_blue_right:
addi $t1, $t1, 1        # increment counter by 1
j check_blue_right_loop  # go back to loop and check cell to the right

end_blue_right_check:
add $v0, $t1, $zero     # store count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Blue_Horizontal #########################################
### Checks whether there are any horizontal matches for blue cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Blue_Horizontal:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_matches caller

addi $s0, $zero, 1      # counter for number of blue cells in a row. starts at 1 for ($a0, $a1)

jal Check_Blue_Left      # check number of blue cells to the left
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells to left
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for right check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for right check call


jal Check_Blue_Right     # check number of blue cells to the right
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells to right


blt $s0, 4, end_check_blue_horizontal # if total count of blue cells in a row horizontally is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set left loop counter ( when greater than number of blue cells to the left, we are done setting left)
add $t2, $zero, $zero           # set right loop counter ( when greater than number of blue cells to the right, we are done setting right)
set_blue_left_match:             # now we set the cells to the left
addi $a0, $a0, -1               # decrement x value by 1
addi $t1, $t1, 1                # increlement left loop counter
bgt $t1, $s5, set_blue_right_match # if loop counter is greater than number of blue cells to the left, proceed to setting blue cells to the right 

jal Set_Match_Tracker_Cell
j set_blue_left_match

set_blue_right_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_blue_right:                  # now we set the cells to the right

addi $a0, $a0, 1               # increment x value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_blue_horizontal # if loop counter is greater than number of blue cells to the right, proceed to end

jal Set_Match_Tracker_Cell
j set_blue_right

end_check_blue_horizontal:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Yellow_Left #########################################
### returns the number of yellow cells to the left of input ($a0, $a1) in $v0.
### Either yellow pill halves or yellow viruses

Check_Yellow_Left:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_mathes caller

li $t1, 0               # set counter number to 0

check_yellow_left_loop:
addi $a0, $a0, -1       # decrement x value by 1
jal Cell_Getter         # check cell for yellow
beq $v0, 5, yes_yellow_left   # if there's a yellow pill cell to the left, jump to yes
beq $v0, 1, yes_yellow_left   # if there's a yellow virus to the left, jump to yes
j end_yellow_left_check       # cell to the left is not yellow, so we end our count

yes_yellow_left:
addi $t1, $t1, 1        # increment counter by 1
j check_yellow_left_loop  # go back to loop and check cell to the left

end_yellow_left_check:
add $v0, $t1, $zero     # store count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

############################### FUNCTION: Check_Yellow_Right #########################################
### returns the number of yellow cells to the right of input ($a0, $a1) in $v0.
### Either yellow pill halves or yellow viruses

Check_Yellow_Right:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Yellow_Right caller

li $t1, 0               # set counter number to 0

check_yellow_right_loop:
addi $a0, $a0, 1       # increment x value by 1
jal Cell_Getter
beq $v0, 5, yes_yellow_right   # if there's a yellow pill cell to the right, jump to yes
beq $v0, 1, yes_yellow_right   # if there's a yellow virus to the right, jump to yes
j end_yellow_right_check       # cell to the right is not yellow, so we end our count

yes_yellow_right:
addi $t1, $t1, 1           # increment counter by 1
j check_yellow_right_loop  # go back to loop and check cell to the right

end_yellow_right_check:
add $v0, $t1, $zero     # store count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Yellow_Horizontal #########################################
### Checks whether there are any yellow horizontal matches for yellow cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Yellow_Horizontal:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for erase_matches caller

addi $s0, $zero, 1      # counter for number of yellow cells in a row. starts at 1 for ($a0, $a1)

jal Check_Yellow_Left      # check number of yellow cells to the left
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells to left
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for right check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for right check call


jal Check_Yellow_Right     # check number of yellow cells to the right
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells to right


blt $s0, 4, end_check_yellow_horizontal # if total count of yellow cells in a row horizontally is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set left loop counter ( when greater than number of yellow cells to the left, we are done setting left)
add $t2, $zero, $zero           # set right loop counter ( when greater than number of yellow cells to the right, we are done setting right)
set_yellow_left_match:             # now we set the cells to the left
addi $a0, $a0, -1               # decrement x value by 1
addi $t1, $t1, 1                # increlement left loop counter
bgt $t1, $s5, set_yellow_right_match # if loop counter is greater than number of yellow cells to the left, proceed to setting yellow cells to the right 

jal Set_Match_Tracker_Cell
j set_yellow_left_match

set_yellow_right_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_yellow_right:                  # now we set the cells to the right

addi $a0, $a0, 1               # increment x value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_yellow_horizontal # if loop counter is greater than number of yellow cells to the right, proceed to end

jal Set_Match_Tracker_Cell
j set_yellow_right

end_check_yellow_horizontal:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Horizontal_Match #########################################
### Checks whether there are any horizontal matches for the cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Horizontal_Match:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Horizontal_Match caller

jal Cell_Getter         # get the value of the cell for which we are checking matches

beq $v0, 4, check_red_horizontal_matches        # if cell is red pill, check red matches
beq $v0, 3, check_red_horizontal_matches        # if cell is red virus, check red matches
beq $v0, 6, check_blue_horizontal_matches       # if cell is blue pill, check blue matches
beq $v0, 2, check_blue_horizontal_matches        # if cell is blue virus, check blue matches
beq $v0, 5, check_yellow_horizontal_matches       # if cell is yellow pill, check yellow matches
beq $v0, 1, check_yellow_horizontal_matches        # if cell is yellow virus, check yellow matches
j end_check_horizontal_matches                  # if cell is not blue, red, or yellow, do nothing

check_red_horizontal_matches:
jal Check_Red_Horizontal        # check red horizontal matches and update match tracker
j end_check_horizontal_matches

check_blue_horizontal_matches:
jal Check_Blue_Horizontal        # check blue horizontal matches and update match tracker
j end_check_horizontal_matches

check_yellow_horizontal_matches:
jal Check_Yellow_Horizontal        # check yellow horizontal matches and update match tracker
j end_check_horizontal_matches

end_check_horizontal_matches:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

############################### FUNCTION: Check_Red_Up #########################################
### returns the number of red cells to above the input ($a0, $a1) in $v0.
### Either red pill halves or red viruses

Check_Red_Up:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Red_Left caller

addi $t1, $zero, 0         # initlaize counter for number of red cells above to 0

check_red_up_loop:
addi $a1, $a1, -1           # decrement y value by 1

jal Cell_Getter             # check cell for red

li $t2, 3                 # comparator of 3 for $v0 (3 corresponds to red virus)
beq $v0, $t2, yes_red_up  # if cell is red virus, branch to yes_red_up
li $t2, 4                     # increment comparator for $v0 to 4 (4 corresponds to red virus)
beq $v0, $t2, yes_red_up # if $v0 is 4, branch to yes_red_up
j end_check_red_up       # if we get to this line, $v0 was not 4 or 3, end count

yes_red_up:
addi $t1, $t1, 1            # increment counter by 1
j check_red_up_loop

end_check_red_up:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Red_Down #########################################
### returns the number of red cells below the input ($a0, $a1) in $v0.
### Either red pill halves or red viruses

Check_Red_Down:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Red_Left caller

addi $t1, $zero, 0         # initlaize counter for number of red cells below to 0

check_red_down_loop:
addi $a1, $a1, 1           # increment y value by 1

jal Cell_Getter             # check cell for red

li $t2, 3                 # comparator of 3 for $v0 (3 corresponds to red virus)
beq $v0, $t2, yes_red_down  # if cell is red virus, branch to yes_red_down
li $t2, 4                     # increment comparator for $v0 to 4 (4 corresponds to red virus)
beq $v0, $t2, yes_red_down # if $v0 is 4, branch to yes_red_down
j end_check_red_down       # if we get to this line, $v0 was not 4 or 3, end count

yes_red_down:
addi $t1, $t1, 1            # increment counter by 1
j check_red_down_loop

end_check_red_down:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Red_Vertical #########################################
### Checks whether there are any red vertical matches for red cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Red_Vertical:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Red_Vertical caller

addi $s0, $zero, 1      # counter for number of red cells in a row. starts at 1 for ($a0, $a1)

jal Check_Red_Up      # check number of red cells above
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells above
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for right check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for right check call


jal Check_Red_Down    # check number of red cells below
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells below


blt $s0, 4, end_check_red_vertical # if total count of red cells in a row vertically is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set up loop counter ( when greater than number of red cells above, we are done setting above)
add $t2, $zero, $zero           # set down loop counter ( when greater than number of red cells below, we are done setting below)
set_red_up_match:               # now we set the cells above
addi $a1, $a1, -1               # decrement y value by 1
addi $t1, $t1, 1                # increlement up loop counter
bgt $t1, $s5, set_red_down_match # if loop counter is greater than number of red cells above, proceed to setting red cells below

jal Set_Match_Tracker_Cell
j set_red_up_match

set_red_down_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_red_down:                  # now we set the cells below

addi $a1, $a1, 1               # increment y value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_red_vertical # if loop counter is greater than number of red cells below, proceed to end

jal Set_Match_Tracker_Cell
j set_red_down

end_check_red_vertical:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Vertical_Match #########################################
### Checks whether there are any vertical matches for the cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Vertical_Match:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Vertical_Match caller

jal Cell_Getter         # get the value of the cell for which we are checking matches

beq $v0, 4, check_red_vertical_matches        # if cell is red pill, check red matches
beq $v0, 3, check_red_vertical_matches        # if cell is red virus, check red matches
beq $v0, 6, check_blue_vertical_matches        # if cell is blue pill, check blue matches
beq $v0, 2, check_blue_vertical_matches        # if cell is blue virus, check blue matches
beq $v0, 5, check_yellow_vertical_matches        # if cell is yellow pill, check yellow matches
beq $v0, 1, check_yellow_vertical_matches        # if cell is yellow virus, check yellow matches
j end_check_vertical_matches                  # if cell is not red, blue, or yellow, do nothing

check_red_vertical_matches:
jal Check_Red_Vertical        # check red vertical matches and update match tracker
j end_check_vertical_matches

check_blue_vertical_matches:
jal Check_Blue_Vertical        # check blue vertical matches and update match tracker
j end_check_vertical_matches

check_yellow_vertical_matches:
jal Check_Yellow_Vertical        # check yellow vertical matches and update match tracker
j end_check_vertical_matches

end_check_vertical_matches:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

##################################################################################################

############################### FUNCTION: Check_Blue_Up #########################################
### returns the number of blue cells above the input ($a0, $a1) in $v0.
### Either blue pill halves or blue viruses

Check_Blue_Up:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Blue_Up caller

addi $t1, $zero, 0         # initlaize counter for number of blue cells above to 0

check_blue_up_loop:
addi $a1, $a1, -1           # decrement y value by 1

jal Cell_Getter             # check cell for blue

li $t2, 2                 # comparator of 2 for $v0 (2 corresponds to blue virus)
beq $v0, $t2, yes_blue_up  # if cell is blue virus, branch to yes_blue_up
li $t2, 6                     # make comparator for $v0 to 6 (6 corresponds to blue pill)
beq $v0, $t2, yes_blue_up # if $v0 is 6, branch to yes_blue_up
j end_check_blue_up       # if we get to this line, $v0 was not 6 or 2, end count

yes_blue_up:
addi $t1, $t1, 1            # increment counter by 1
j check_blue_up_loop

end_check_blue_up:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Blue_Down #########################################
### returns the number of blue cells below the input ($a0, $a1) in $v0.
### Either blue pill halves or blue viruses

Check_Blue_Down:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Blue_Down caller

addi $t1, $zero, 0         # initlaize counter for number of blue cells below to 0

check_blue_down_loop:
addi $a1, $a1, 1           # increment y value by 1

jal Cell_Getter             # check cell for blue

li $t2, 2                 # comparator of 2 for $v0 (2 corresponds to blue virus)
beq $v0, $t2, yes_blue_down  # if cell is blue virus, branch to yes_blue_down
li $t2, 6                     # make comparator for $v0 6 (6 corresponds to blue pill)
beq $v0, $t2, yes_blue_down # if $v0 is 6, branch to yes_blue_down
j end_check_blue_down       # if we get to this line, $v0 was not 6 or 2, end count

yes_blue_down:
addi $t1, $t1, 1            # increment counter by 1
j check_blue_down_loop

end_check_blue_down:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Blue_Vertical #########################################
### Checks whether there are any blue vertical matches for blue cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Blue_Vertical:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Blue_Vertical caller

addi $s0, $zero, 1      # counter for number of blue cells in a row. starts at 1 for ($a0, $a1)

jal Check_Blue_Up      # check number of blue cells above
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells above
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for down check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for down check call


jal Check_Blue_Down    # check number of blue cells below
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells below


blt $s0, 4, end_check_blue_vertical # if total count of blue cells in a row vertically is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set up loop counter ( when greater than number of blue cells above, we are done setting above)
add $t2, $zero, $zero           # set down loop counter ( when greater than number of blue cells below, we are done setting below)
set_blue_up_match:              # now we set the cells above
addi $a1, $a1, -1               # decrement y value by 1
addi $t1, $t1, 1                # increlement up loop counter
bgt $t1, $s5, set_blue_down_match # if loop counter is greater than number of blue cells above, proceed to setting blue cells below

jal Set_Match_Tracker_Cell
j set_blue_up_match

set_blue_down_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_blue_down:                  # now we set the cells below

addi $a1, $a1, 1               # increment y value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_blue_vertical # if loop counter is greater than number of blue cells below, proceed to end

jal Set_Match_Tracker_Cell
j set_blue_down

end_check_blue_vertical:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Yellow_Up #########################################
### returns the number of yellow cells above the input ($a0, $a1) in $v0.
### Either yellow pill halves or yellow viruses

Check_Yellow_Up:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Yellow_Up caller

addi $t1, $zero, 0         # initlaize counter for number of yellow cells above to 0

check_yellow_up_loop:
addi $a1, $a1, -1           # decrement y value by 1

jal Cell_Getter             # check cell for yellow

li $t2, 1                 # comparator of 1 for $v0 (1 corresponds to yellow virus)
beq $v0, $t2, yes_yellow_up  # if cell is yellow virus, branch to yes_yellow_up
li $t2, 5                     # make comparator for $v0 to 5 (5 corresponds to yellow pill)
beq $v0, $t2, yes_yellow_up # if $v0 is 5, branch to yes_yellow_up
j end_check_yellow_up       # if we get to this line, $v0 was not 5 or 1, end count

yes_yellow_up:
addi $t1, $t1, 1            # increment counter by 1
j check_yellow_up_loop

end_check_yellow_up:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Yellow_Down #########################################
### returns the number of yellow cells below the input ($a0, $a1) in $v0.
### Either yellow pill halves or yellow viruses

Check_Yellow_Down:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_yellow_Down caller

addi $t1, $zero, 0         # initlaize counter for number of yellow cells below to 0

check_yellow_down_loop:
addi $a1, $a1, 1           # increment y value by 1

jal Cell_Getter             # check cell for yellow

li $t2, 1                 # comparator of 1 for $v0 (1 corresponds to yellow virus)
beq $v0, $t2, yes_yellow_down  # if cell is yellow virus, branch to yes_yellow_down
li $t2, 5                     # increment comparator for $v0 to 5 (5 corresponds to yellow virus)
beq $v0, $t2, yes_yellow_down # if $v0 is 5, branch to yes_yellow_down
j end_check_yellow_down       # if we get to this line, $v0 was not 5 or 1, end count

yes_yellow_down:
addi $t1, $t1, 1            # increment counter by 1
j check_yellow_down_loop

end_check_yellow_down:
add $v0, $zero, $t1     # store final count in $v0 and return

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Check_Yellow_Vertical #########################################
### Checks whether there are any yellow vertical matches for yellow cell at ($a0, $a1)
### If so, it updates the match_tracker array accordingly.

Check_Yellow_Vertical:
add $s7, $a0, $zero     # store original x coordinate
add $s6, $a1, $zero     # store original y coordinate

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Yellow_Vertical caller

addi $s0, $zero, 1      # counter for number of yellow cells in a row. starts at 1 for ($a0, $a1)

jal Check_Yellow_Up      # check number of yellow cells above
add $s0, $s0, $v0       # adds this number to the count
add $s5, $v0, $zero     # store number of cells above
add $a0, $s7, $zero     # reset original value of $a0 (x coordinate) for right check call
add $a1, $s6, $zero     # reset original value of $a1 (y coordiante) for right check call


jal Check_Yellow_Down    # check number of yellow cells below
add $s0, $s0, $v0       # adds this number to the count
add $s4, $v0, $zero     # store number of cells below


blt $s0, 4, end_check_yellow_vertical # if total count of yellow cells in a row vertically is less than 4, do nothing

# else, update the match tracker
add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

jal Set_Match_Tracker_Cell

add $a0, $s7, $zero             # reset x coordinate paramater for setter call
add $a1, $s6, $zero             # reset y coordinate paramater for setter call
addi $a2, $zero, 1              # cell value to set is 1

add $t1, $zero, $zero           # set up loop counter ( when greater than number of yellow cells above, we are done setting above)
add $t2, $zero, $zero           # set down loop counter ( when greater than number of yellow cells below, we are done setting below)
set_yellow_up_match:               # now we set the cells above
addi $a1, $a1, -1               # decrement y value by 1
addi $t1, $t1, 1                # increlement up loop counter
bgt $t1, $s5, set_yellow_down_match # if loop counter is greater than number of yellow cells above, proceed to setting yellow cells below

jal Set_Match_Tracker_Cell
j set_yellow_up_match

set_yellow_down_match:
add $a0, $s7, $zero             # reset x coordinate paramater for setter call to original x coordinate input
add $a1, $s6, $zero             # reset y coordinate paramater for setter call to original y coordinate input
addi $a2, $zero, 1              # cell value to set is 1

set_yellow_down:                  # now we set the cells below

addi $a1, $a1, 1               # increment y value by 1
addi $t2, $t2, 1
bgt $t2, $s4, end_check_yellow_vertical # if loop counter is greater than number of yellow cells below, proceed to end

jal Set_Match_Tracker_Cell
j set_yellow_down

end_check_yellow_vertical:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##################################################################################################

############################### FUNCTION: Past_Pill_Getter ##################################
### A function to retrieve a given cell's value in the past pill tracker array.
### Get the cell value at location ($a0, $a1) = (x_coord, y_coord).
### return value in $v0 is value at cell ($a0, $a1)

Past_Pill_Getter:
la $t0, past_pill_tracker      # $t0 stores the base address for the past pill tracker array
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
lw $v0, 0( $t0 )        # return cell value in $v0

jr $ra
########################################################################################

################### FUNCTION: Past_Pill_Setter ##################################
### A function to set the value of a given cell in past pill tracker array.
### Set the cell value at location ($a0, $a1) = (x_coord, y_coord) to $a2.

Past_Pill_Setter:
la $t0, past_pill_tracker      # $t0 stores the base adress for the past pill tracker array
add $t9, $a0, $zero     # $t9 now has x_coord
add $t8, $a1, $zero     # $t8 now has y_coord
sll $t9, $t9, 2         # multiply $t9 by 4
sll $t8, $t8, 8         # multiply $t8 by 256
add $t0, $t0, $t9       # add x offset to $t0
add $t0, $t0, $t8       # add y offset to $t0
sw $a2, 0( $t0 )

jr $ra

##############################################################################

################### FUNCTION: Check_Pill_Half_Unsupported ####################
### Checks whether the pill half at ($a0, $a1) is unsupported. Should be called after
### erasing matches and in the dropping unsupported pills segment of the program.
### returns 1 in $v0 if the pill half is unsupported and 0 in $v0 if it is

Check_Pill_Half_Unsupported:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_Pill_Half_Unsupported caller

add $t1, $a0, $zero     # store original x coordinate in t1
add $t2, $a1, $zero     # store original y coordinate in t2

jal Cell_Getter         # retrieve the value at the cell in question to check whether it is even a pill half
beq $v0, 4, check_cell_beneath_empty # if cell is a red pill half, proceed to unsupported check
beq $v0, 5, check_cell_beneath_empty # if cell is a yellow pill half, proceed to unsupported check
beq $v0, 6, check_cell_beneath_empty # if cell is a blue pill half, proceed to unsupported check

j not_unsupported_pill_half  # if this point is reached, cell is not a pill half, so we can end the check

check_cell_beneath_empty:
addi $a1, $a1, 1        # increment y coordiante by 1
jal Cell_Getter         # get the value of the cell beneath through cell getter (will be in v0)

lw $s4, blank_cell      # store the value of a blank cell in s4 to compare with v0.
bne $v0, $s4, not_unsupported_pill_half # if the cell beneath is not blank, pill half is supported.
# at this point, the cell beneath is blank, so we check whether its left and right neighbours are a corresponding pill half,
# and if so, whether they are supported.

add $a0, $t1, $zero       # reset x coordiante parameter to original x coordinate
add $a1, $t2, $zero       # reset y coordiante parameter to original y coordinate
jal Past_Pill_Getter      # get the past pill index for this half pill cell
add $s5, $v0, $zero         # store this past pill index in $s5

# now we check whether our cell is supported by the cell to the left
check_left_support: 
addi $a0, $a0, -1       # decrement x coordinate by 1
jal Past_Pill_Getter    # get the past pill index for the cell to the left
bne $v0, $s5, check_right_support # if the cell to the left is not the other pill half for our cell, it is not supported to the left, check the right
# at this point the cell to the left is the other half of the pill 

addi $a1, $a1, 1       # increment y coordinate by 1 to check cell beneath cell to the left
jal Cell_Getter         # get the value of the cell beneath cell to the left through cell getter (will be in v0)
beq $v0, $s4, unsupported_pill_half # if the cell is blank, the left pill half is unsupported, so our pill half is also unsupported.
# else, left pill half is supported so our pill half is also supported
j not_unsupported_pill_half

check_right_support:
addi $a0, $t1, 1          # reset x coordiante parameter to original x coordinate + 1
add $a1, $t2, $zero       # reset y coordiante parameter to original y coordinate

jal Past_Pill_Getter    # get the past pill index for the cell to the right
bne $v0, $s5, unsupported_pill_half # if the cell to the right is not the other pill half for our cell, it is not supported by the right either

# at this point the cell to the right is the other half of the pill 

addi $a1, $a1, 1        # increment y coordinate by 1 to check cell beneath cell to the right
jal Cell_Getter         # get the value of the cell beneath cell to the right through cell getter (will be in v0)
beq $v0, $s4, unsupported_pill_half # if the cell is blank, the right pill half is unsupported, so our pill half is also unsupported.
# else, right pill half is supported so our pill half is also supported
j not_unsupported_pill_half

not_unsupported_pill_half:
add $v0, $zero, $zero       # pill half is supported, so we return 0
j end_check_pill_half_unsupported

unsupported_pill_half:
addi $v0, $zero, 1       # pill half is unsupported, so we return 1
j end_check_pill_half_unsupported

end_check_pill_half_unsupported:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
############################################################################################################################################################

################### FUNCTION: Lower_Unsupported_Pill_Half ####################
### Lowers the unsupported pill half at ($a0, $a1) by one cell and updates the corresponding
### cells in the game field and past_pill_tracker. This should only ever be called on an unsupported pill half,
### as verified by Check_Pill_Half_Unsupported.

Lower_Unsupported_Pill_Half:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Lower_Unsupported_Pill_Half caller

add $t1, $a0, $zero     # storing original x-coordinate
add $t2, $a1, $zero     # storing original y-coordinate

jal Cell_Getter         # getting the cells value
add $t3, $v0, $zero     # store our cells value in $t3

lw $a2, blank_cell      # blank cell value to set in game field
jal Cell_Setter         # set the current cell in our game field to be blank

jal Past_Pill_Getter    # getting our cells past pill index
add $t4, $v0, $zero     # store the past pill index for our cell in t4
li $a2, 0               # blank cell value to set in past_pill_tracker
jal Past_Pill_Setter    # set past pill index at our cell to 0

add $a0, $t1, $zero     # reset a0 to original x-coordinate
addi $a1, $t2, 1        # reset a1 to original y-coordinate + 1

add $a2, $t3, $zero     # our cells value into a2
jal Cell_Setter         # set the vell below our original cell to have its value

add $a2, $t4, $zero          # our cells past pill index into a2
jal Past_Pill_Setter         # set the cell below our original cell to have its past pill index

end_lower_unsupported_pill_half:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

############################################################################################################################################################

################### FUNCTION: Lower_All_Unsupported_Pills ####################
### Lowers the unsupported pill haves by one cell and updates the corresponding
### cells in the game field and past_pill_tracker. Returns v0=1 if at least one pill half was lowered,
### and otherwise v0=0 (if all pill halves were supported).

Lower_All_Unsupported_Pills:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Lower_All_Unsupported_Pills caller

addi $s0, $zero, 0      # current return value is 0, and will be swapped to 1 if a pill half was lowered.

addi $t6, $zero, 50   # row (y) index for loop, starting at bottom row of bottle (y=50)

drop_unsupported_pills_row_loop:
blt $t6, 27, end_lowering_unsupported_pill_halves
addi $t7, $zero, 38 # column (x) index for loop, starting at right column of bottle (x=38)

drop_unsupported_pills_column_loop:
blt $t7, 24, end_drop_unsupported_pills_column_loop

add $a0, $zero, $t7     # set current x coordinate in a0
add $a1, $zero, $t6     # set current y coordinate in a1

jal Check_Pill_Half_Unsupported # check whether the pill half at our current (x,y) is unsupported (i.e. if v0=1)

beq $v0, 1, current_cell_is_unsupported_pill_half # if it is unsupported, handle that case
#else, decrement column index and check next column
addi $t7, $t7, -1       # decrement column index
j drop_unsupported_pills_column_loop # check next column

current_cell_is_unsupported_pill_half:
add $a0, $zero, $t7     # set current x coordinate in a0
add $a1, $zero, $t6     # set current y coordinate in a1

jal Lower_Unsupported_Pill_Half # lower the unsupported pill half
addi $s0, $zero, 1      # set our return value for later to 1

addi $t7, $t7, -1       # decrement column index
j drop_unsupported_pills_column_loop # check next column

end_drop_unsupported_pills_column_loop:
addi $t6, $t6, -1   # decrement row index by 1
j drop_unsupported_pills_row_loop   # jump to next row above and restart column loop

end_lowering_unsupported_pill_halves:
add $v0, $s0, $zero     # set our return value

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
###################################################################################################################

################### FUNCTION: Match_Present ####################################################################
### Iterates through the entire bottle (in match_tracker), checks for matches at each cell
### and returns v0=1 if there are any matches, and v0=0, otherwise.

Match_Present:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Match_Present caller

add $s0, $zero, $zero  # current return value is 0 (i.e. no matches) and will be updated to 1 if we detect a match

addi $t6, $zero, 50   # row (y) index for loop, starting at bottom row of bottle (y=50)

match_present_row_loop:
blt $t6, 27, end_match_present
addi $t7, $zero, 38 # column (x) index for loop, starting at right column of bottle (x=38)

match_present_column_loop:
blt $t7, 24, end_match_present_column_loop 

add $a0, $zero, $t7     # set current x coordinate in a0
add $a1, $zero, $t6     # set current y coordinate in a1

jal Get_Match_Tracker_Cell  # get the match tracker value at the current (x,y) coordinate
beq $v0, 1, yes_match_present  # if the value is 1 (i.e. part of a match), we return 1
# else, we continue to the next cell in the column

addi $t7, $t7, -1       # decrement column index
j match_present_column_loop # check next column

end_match_present_column_loop:
addi $t6, $t6, -1   # decrement row index by 1
j match_present_row_loop   # jump to next row above and restart column loop

yes_match_present:
addi $s0, $zero, 1          # set return value to 1

end_match_present:
add $v0, $s0, $zero         # put return value in v0

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Check_All_Matches ####################################################################
### Iterates through the entire bottle, checks for matches at each cell and updates match tracker accordingly.
### Most work diverged to Check_Horizontal_Match and Check_Vertical_Match. Returns v0=1 if any matches are present
### and v0=0 otherwise.

Check_All_Matches:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Check_All_Matches caller

addi $t6, $zero, 50   # row (y) index for loop, starting at bottom row of bottle (y=50)

check_all_matches_row_loop:
blt $t6, 27, end_check_all_matches
addi $t7, $zero, 38 # column (x) index for loop, starting at right column of bottle (x=38)

check_all_matches_column_loop:
blt $t7, 24, end_check_all_matches_column_loop 

add $a0, $zero, $t7     # set current x coordinate in a0
add $a1, $zero, $t6     # set current y coordinate in a1

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $t6, 0($sp)        # storing current y value
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $t7, 0($sp)        # storing current x value

jal Check_Horizontal_Match

lw $t7, 0( $sp )        # retrieving current x value from stack
addi $sp, $sp, 4        # moving stack pointer down a word
lw $t6, 0( $sp )        # retrieving current y value from stack
addi $sp, $sp, 4        # moving stack pointer down a word

add $a0, $zero, $t7     # set current x coordinate in a0
add $a1, $zero, $t6     # set current y coordinate in a1

addi $sp, $sp, -4       # moving stack pointer up a word
sw   $t6, 0($sp)        # storing current y value
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $t7, 0($sp)        # storing current x value

jal Check_Vertical_Match

lw $t7, 0( $sp )        # retrieving current x value from stack
addi $sp, $sp, 4        # moving stack pointer down a word
lw $t6, 0( $sp )        # retrieving current y value from stack
addi $sp, $sp, 4        # moving stack pointer down a word

addi $t7, $t7, -1       # decrement column index
j check_all_matches_column_loop # check next column

end_check_all_matches_column_loop:
addi $t6, $t6, -1   # decrement row index by 1
j check_all_matches_row_loop  # jump to next row above and restart column loop

end_check_all_matches:
jal Match_Present # will set the reutrn value v0 to 1 if there is a match, and v0=0, otherwise.

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Post_Freeze_Drop ####################################################################
### Called After, freezing a pill and erasing the initial matches.
### Drops all unsuported capsules (until they can no longer be dropped)
### Checks for new matches, updates match_tracker, and returns v0=1 if there are new matches, and v0=0, if there are not.

Post_Freeze_Drop:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Lower_All_Unsupported_Pills caller

lower_capsules:
jal Lower_All_Unsupported_Pills # lowering all the unsuported pills by 1 row
beq $v0, 1, lower_capsules      # if there are still unsupported pills, repeat the above line

# else check if there are any new matches (but first, draw the grid with the lowered capsules)
jal Draw_Grid
li $v0, 32 # sleep for a tiny bit so the erased matches are shown
li $a0, 310
syscall

check_matches:
jal Check_All_Matches    # This check the match tracker array for any potential new matches
beq $v0, 0, end_post_freeze_drop  # if check_all_matches returns 0, there are no new matches and we can end our post freeze drop logic
# else, there are new matches

jal Erase_Matches       # erase these matches
jal Draw_Grid          # draw the grid

			# li $v0, 31
    # li $a0, 84 # pitch
    # li $a1, 50 # duration
    # li $a2, 80 # instrument
    # li $a3, 40 # volume
    # syscall

li $v0, 32 # sleep for a tiny bit so the erased matches are shown
li $a0, 310
syscall

			li $v0, 31
    li $a0, 64 # pitch
    li $a1, 50 # duration
    li $a2, 102 # instrument
    li $a3, 40 # volume
    syscall
    
j lower_capsules        # recheck and lower unsupported pills after erasing the new matches

end_post_freeze_drop:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Draw_Maginifying_Glass ##############################################################
### This function sets the grid values so that the maginfying glass is drawn, called through New_Game.

Draw_Maginifying_Glass:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Maginifying_Glass caller

#handle_square_1:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 2 # starting x coordinate of rectangle
    addi $t2, $zero, 55 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#handle_square_2:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 53 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#handle_square_3:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 4 # starting x coordinate of rectangle
    addi $t2, $zero, 51 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# From here on, drawing circular part of magnifying glass, refer to grid paper diagram, first rectangle is the 
# 1x1 rectangle to the right of handle_square_3, and then we go counter clockwise until we reach the rectangle above handle_square_3

#1:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 51 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#2:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 52 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#3:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 5 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 53 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#3:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 52 # starting y coordinate of rectangle
    jal Rectangle_Setter

#4:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 51 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#5:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 16 # starting x coordinate of rectangle
    addi $t2, $zero, 50 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#6:
    addi $a0, $zero, 6 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 17 # starting x coordinate of rectangle
    addi $t2, $zero, 44 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#7:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 16 # starting x coordinate of rectangle
    addi $t2, $zero, 42 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#8:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 41 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#9:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 40 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#10:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 6 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 39 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#11:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 40 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#12:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 41 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#13:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 4 # starting x coordinate of rectangle
    addi $t2, $zero, 42 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#14:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 43 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#15:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 4 # starting x coordinate of rectangle
    addi $t2, $zero, 48 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#16:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, bottle_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 50 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
end_draw_magnifying_glass:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Draw_Red_Virus ##############################################################
### This function sets the grid values so that the red virus is drawn, called through New_Game.
### See grid paper diagram for coordinate considerations

Draw_Red_Virus:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Red_Virus caller

#red background square:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#green contrast squares:

#left_green_square:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 47 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#right_green_square:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 47 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#up_green_square:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#down_green_square:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 48 # starting y coordinate of rectangle
    jal Rectangle_Setter


end_draw_red_virus:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Draw_Yellow_Virus ##############################################################
### This function sets the grid values so that the yellow virus is drawn, called through New_Game.
### See grid paper diagram for coordinate considerations

Draw_Yellow_Virus:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Yellow_Virus caller

#Yellow background square:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 3 # width
    lw $a2, yellow_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 42 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#yellow ears:

# left ear
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, yellow_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 41 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right ear
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, yellow_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 41 # starting y coordinate of rectangle
    jal Rectangle_Setter
 
# red eye:

# left eye
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 43 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right eye
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 43 # starting y coordinate of rectangle
    jal Rectangle_Setter

end_draw_yellow_virus:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

###################################################################################################################

################### FUNCTION: Draw_Blue_Virus ##############################################################
### This function sets the grid values so that the blue virus is drawn, called through New_Game.
### See grid paper diagram for coordinate considerations

Draw_Blue_Virus:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Yellow_Virus caller

#Blue background square:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 3 # width
    lw $a2, blue_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 47 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# the four extended out blue corners

#top left
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, blue_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 10 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#top right
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, blue_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 14 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#bottom right
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, blue_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 14 # starting x coordinate of rectangle
    addi $t2, $zero, 50 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#bottom left
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, blue_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 10 # starting x coordinate of rectangle
    addi $t2, $zero, 50 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# the four brown corners inside the inner blue square

#top left
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 47 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#top right
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 47 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#bottom right
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 49 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#bottom left
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 49 # starting y coordinate of rectangle
    jal Rectangle_Setter

# middle brown square
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 12 # starting x coordinate of rectangle
    addi $t2, $zero, 48 # starting y coordinate of rectangle
    jal Rectangle_Setter

end_draw_blue_virus:

lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

######################################################################################################

######################################## Erase_Virus_Drawings ########################################
### A function to erase the virus drawings as all viruses of that colour are eliminated from the bottle.

Erase_Virus_Drawings:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Yellow_Virus caller

check_num_yellow_virus:
lw $s0, number_yellow_virus # load the number of yellow viruses into s0
bne $s0, $zero, check_num_blue_virus # if there are more than 0 yellow viruses, skip erasing yellow and check blue
# if we get here, the number of yellow viruses is 0, we reset all the cells covering the yellow virus area to blank.

#erase yellow virus:
    addi $a0, $zero, 4 # height
    addi $a1, $zero, 3 # width
    lw $a2, blank_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 41 # starting y coordinate of rectangle
    jal Rectangle_Setter

check_num_blue_virus:

lw $s0, number_blue_virus # load the number of blue viruses into s0
bne $s0, $zero, check_num_red_virus # if there are more than 0 blue viruses, skip erasing blue and check red
# if we get here, the number of blue viruses is 0, we reset all the cells covering the blue virus area to blank.

#erase blue virus:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 5 # width
    lw $a2, blank_cell # value to store in rectangle cells
    addi $t1, $zero, 10 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter

check_num_red_virus:

lw $s0, number_red_virus # load the number of red viruses into s0
bne $s0, $zero, end_erase_virus_drawings # if there are more than 0 red viruses, skip erasing red, and go to return
# if we get here, the number of red viruses is 0, we reset all the cells covering the red virus area to blank.

#erase red virus:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 3 # width
    lw $a2, blank_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 46 # starting y coordinate of rectangle
    jal Rectangle_Setter

end_erase_virus_drawings:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

######################################################################################################

################### FUNCTION:Erase_Paused ######################################################
### This function sets the grid values so that the Paused message is erased when the game is unpaused

Erase_Paused:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Paused caller

    addi $a0, $zero, 5 # height
    addi $a1, $zero, 23 # width
    lw $a2, blank_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
end_erase_paused:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

################### FUNCTION: Draw_Paused ######################################################
### This function sets the grid values so that the Paused message is displayed when the game is paused.
### Future Thomas, see grid paper diagram for coordinate considerations, we are just spamming drawing 
### rectanglws here.

Draw_Paused:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Paused caller

# P:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 4 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # A:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #U
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 12 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #S
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 4 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 17 # starting x coordinate of rectangle
    addi $t2, $zero, 6 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        #E
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #D
            addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 23 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 24 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 24 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter

        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 6 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 4 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter



end_draw_paused:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra


######################################################################################################

################### FUNCTION: Draw_Doctor_Mario ######################################################
### This function sets the grid values so that dr mario is drawn in the top right of the screen.
### Future Thomas, see grid paper diagram for coordinate considerations, we are just spamming drawing 
### rectanglws here.

Draw_Doctor_Mario:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Doctor_Mario caller

#test sqaure for colours:
    # addi $a0, $zero, 5 # height
    # addi $a1, $zero, 5 # width
    # lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    # addi $t1, $zero, 46 # starting x coordinate of rectangle
    # addi $t2, $zero, 26 # starting y coordinate of rectangle
    # jal Rectangle_Setter

draw_boots:
# left boot (bottom row):
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 46 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# left boot (top row):
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 47 # starting x coordinate of rectangle
    addi $t2, $zero, 25 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right boot (bottom row):
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 54 # starting x coordinate of rectangle
    addi $t2, $zero, 26 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right boot (top row):
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 54 # starting x coordinate of rectangle
    addi $t2, $zero, 25 # starting y coordinate of rectangle
    jal Rectangle_Setter

draw_pants:
# left pant leg:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, mario_pants_colour # value to store in rectangle cells
    addi $t1, $zero, 48 # starting x coordinate of rectangle
    addi $t2, $zero, 24 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right pant leg:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, mario_pants_colour # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 24 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_hands:
# left arm sleeve cuff thing:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 45 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# left hand, longer rectangle:

    addi $a0, $zero, 3 # height
    addi $a1, $zero, 1 # width
    lw $a2, light_grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 44 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# left hand, shorter rectangle:

    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, light_grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 43 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right arm sleeve cuff thing:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 56 # starting x coordinate of rectangle
    addi $t2, $zero, 21 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# right hand, longer rectangle:

    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, light_grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 55 # starting x coordinate of rectangle
    addi $t2, $zero, 22 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# left hand, shorter rectangle:

    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, light_grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 56 # starting x coordinate of rectangle
    addi $t2, $zero, 23 # starting y coordinate of rectangle
    jal Rectangle_Setter

draw_coat:
# left arm coat sleave:

    addi $a0, $zero, 2 # height
    addi $a1, $zero, 5 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 46 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# left hip coat, part:
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 2 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 48 # starting x coordinate of rectangle
    addi $t2, $zero, 21 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# rest of bottom coat part rectangle:
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 5 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 22 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# bottom right, single coat pixel under mario's left thumb:
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 55 # starting x coordinate of rectangle
    addi $t2, $zero, 23 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# 3x3 coat square on right side of tie
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 3 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 52 # starting x coordinate of rectangle
    addi $t2, $zero, 20 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# coat column to the right of the square drawn above
    addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 55 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# L shaped coat part aboce mario's left hand 
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 56 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 57 # starting x coordinate of rectangle
    addi $t2, $zero, 20 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# L shaped coat part anext to mario's stethescope
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 54 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# Isolated 1x1 coat pixel under chin
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 52 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_tie:

#top horizontal tie part 
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
#bottom right tie pixel 
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_stesthescope:

#bottom horizontal stesthescope part
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 21 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# 1x1 pixel above the right side of the above
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 20 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# 1x1 pixel up 1 and right 1 from the above pixel
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 52 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# 1x1 pixel up 1 and right 1 from the above pixel
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter

draw_face_skin:

    # bottom horizontal row of skin coloured face
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 7 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 48 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # horizontal row, one row above the one we just drew
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # mario's ear
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 55 # starting x coordinate of rectangle
    addi $t2, $zero, 14 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # vertical skin coloured rectangle next to eye
    addi $a0, $zero, 3 # height
    addi $a1, $zero, 2 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # isolated skin coloured face pixel on left side of J shaped hair part
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 14 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # isolated skin coloured face pixel on top of mouth
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # bottom row of nose
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 46 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # second from bottom row of nose
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 47 # starting x coordinate of rectangle
    addi $t2, $zero, 14 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # top pixel of nose
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, skin_colour_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 49 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_hair:

# bottom right horizontal row of hair
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 55 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# bottom right vertical column of hair
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 56 # starting x coordinate of rectangle
    addi $t2, $zero, 14 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# bottom horizontal row of J part of hair
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# top horizontal row of J part of hair
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 53 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# isolated middle pixel of J part of hair
addi $a0, $zero, 1 # height
addi $a1, $zero, 1 # width
lw $a2, brown_drawing_cell # value to store in rectangle cells
addi $t1, $zero, 54 # starting x coordinate of rectangle
addi $t2, $zero, 14 # starting y coordinate of rectangle
jal Rectangle_Setter

# top horizontal row of hair
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
# vertical 2 pixel hair bit at the top left of head
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, brown_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 48 # starting x coordinate of rectangle
    addi $t2, $zero, 10 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_head_band:

    # vertical 2 pixel white part of head_band medallion
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, white_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 49 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # vertical 2 pixel light grey part of head_band medallion, immediately to the right of the above
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, light_grey_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # blue head band strap (same colour as pants)
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 5 # width
    lw $a2, mario_pants_colour # value to store in rectangle cells
    addi $t1, $zero, 51 # starting x coordinate of rectangle
    addi $t2, $zero, 12 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
draw_eye_and_mouth:
    # mario's eye
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, mario_eye_colour # value to store in rectangle cells
    addi $t1, $zero, 50 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # mario's mouth
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 5 # width
    lw $a2, mario_eye_colour # value to store in rectangle cells
    addi $t1, $zero, 47 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # mario's isolated mouth pixel
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, mario_eye_colour # value to store in rectangle cells
    addi $t1, $zero, 49 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    
end_draw_doctor_mario:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra

######################################################################################################

################### FUNCTION: Increment_Gravity_Index ################################################
### This function increments the gravity index by 1.

Increment_Gravity_Index:
lw $s0, gravity_index # load the current gravity index value into s0
addi $s0, $s0, 1      # increment said index by 1
sw $s0, gravity_index # update the index in memory

jr $ra

######################################################################################################

################### FUNCTION: Gravity ################################################################
### This function checks the gravity index, if it is >30, it resets it back to 0, and jumps to respond_to_S
### this artifically simulates pressing the s key (moving down)

Gravity:
lw $s0, gravity_index_reset_counter     # load the number of times gravity has occured into s0
lw $s1, gravity_index # load the current gravity index from memory into s1

blt $s0, 30, level_one_gravity # if the current amount of times gravity has been applied is less than 30, jump to level_one_gravity handling
bgt $s0, 90, level_three_gravity    # if the current amount of times gravity has been applied is greater than 90, jump to level_three_gravity handling
j level_two_gravity         # else, the current number of times gravity has been applied is between 30 and 90, so we jump to level_two_gravity handling


level_one_gravity: # WAS 19
bgt $s1, 24, cause_level_one_gravity # if the current gravity index is greater than 19 (i.e. 20 or higher), cause gravity level one gravity to occur (move down)
addi $s1, $s1, 1        # else, increment the gravity index by 1 and end our gravity check

# we have not yet reached level one gravity condition, so we do nothing and exit
j end_gravity_check

cause_level_one_gravity:
sw $zero, gravity_index     # reset the gravity index to 0
addi $s0, $s0, 1            # increase the number of times gravity has occured by 1
sw $s0, gravity_index_reset_counter     # store the above update in memory

j artificial_respond_to_S             # pretend as if the S key was called 

level_two_gravity: # WAS 7

bgt $s1, 13, cause_level_two_gravity # if the current index is greater than 7 (i.e. 8 or higher), cause level two gravity to occur (move down)
addi $s1, $s1, 1        # else, increment the gravity index by 1 and end our gravity check

# we have not yet reached level two gravity condition, so we do nothing and exit
j end_gravity_check

cause_level_two_gravity:
sw $zero, gravity_index     # reset the gravity index to 0
addi $s0, $s0, 1            # increase the number of times gravity has occured by 1
sw $s0, gravity_index_reset_counter     # store the above update in memory

j artificial_respond_to_S              # pretend as if the S key was called 

level_three_gravity: # WAS 3
bgt $s1, 8, cause_level_three_gravity # if the current gravity index is greater than 3 (i.e. 4 or higher), cause level three gravity to occur (move down)
addi $s1, $s1, 1        # else, update the gravity index by 1 and end our gravity check

# we have not yet reached level three gravity condition, so we do nothing and exit
j end_gravity_check

cause_level_three_gravity:
sw $zero, gravity_index     # reset the gravity index to 0
addi $s0, $s0, 1            # increase the number of times gravity has occured by 1
sw $s0, gravity_index_reset_counter     # store the above update in memory

j artificial_respond_to_S              # pretend as if the S key was called 

end_gravity_check:
jr $ra

#####################################################################################################

################### FUNCTION: Pause_Game ################################################################
### This function pauses the game when the 'p' key is pressed and resumes the game when it is pressed again.

Pause_Game:

jal Draw_Paused
jal Draw_Grid

check_for_unpause_press:
lw $t0, ADDR_KBRD    # $t0 = base address for keyboard
lw $t8, 0($t0)       # Load first word from keyboard into $t8
beq $t8, 1, pause_keyboard_input  #If first word == 1, key is pressed
j pause_sleep # if not key is pressed, continue to pause sleep

pause_keyboard_input:

lw $t2, 4($t0)      # load second word from keyboard

beq $t2, 0x70, end_pause    # branch to end_pause
# else, continue to pause sleep

pause_sleep:
li $v0, 32 # slight sleeping needed for pause loop
li $a0, 20
syscall

j check_for_unpause_press    # jump back to Pause_Game if p is yet to be clicked a second time

end_pause:
jal Erase_Paused
j unpause_game


#####################################################################################################

################### FUNCTION: Draw_Game_Over_Screen ######################################################
### This function displays game over on the screen when the game over condition is reached and starts
### a new game if the player selects retry by clicking r.

Draw_Game_Over_Screen:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Draw_Game_Over_Screen caller


# G:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 6 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    
    # A:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 10 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #M
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 12 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 16 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 4 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 14 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 4 # starting y coordinate of rectangle
    jal Rectangle_Setter

    
        #E
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 18 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 18 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 18 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 18 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #O
            addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 24 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 26 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        #V
            addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 28 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 29 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 30 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                        addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 31 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                            addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 32 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #E
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 34 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2,red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 34 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 34 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 34 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #R
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 40 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 38 # starting x coordinate of rectangle
    addi $t2, $zero, 5 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 38 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 38 # starting x coordinate of rectangle
    addi $t2, $zero, 3 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 40 # starting x coordinate of rectangle
    addi $t2, $zero, 6 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, red_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 40 # starting x coordinate of rectangle
    addi $t2, $zero, 7 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # N:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 4 # starting x coordinate of rectangle
    addi $t2, $zero, 10 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 6 # starting x coordinate of rectangle
    addi $t2, $zero, 12 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        # E:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 8 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            # W:
    addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 12 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 16 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 13 # starting x coordinate of rectangle
    addi $t2, $zero, 12 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 14 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 12 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    # G:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 20 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 20 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 4 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 20 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 22 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 23 # starting x coordinate of rectangle
    addi $t2, $zero, 12 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    
    # A:
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 27 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 26 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 26 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #M
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 29 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 33 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 30 # starting x coordinate of rectangle
    addi $t2, $zero, 10 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 31 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 32 # starting x coordinate of rectangle
    addi $t2, $zero, 10 # starting y coordinate of rectangle
    jal Rectangle_Setter

    
        #E
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 35 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 35 # starting x coordinate of rectangle
    addi $t2, $zero, 11 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 35 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 35 # starting x coordinate of rectangle
    addi $t2, $zero, 9 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 39 # starting x coordinate of rectangle
    addi $t2, $zero, 10 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 39 # starting x coordinate of rectangle
    addi $t2, $zero, 13 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #P
    
        addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 3 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 5 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #R
    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 2 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 7 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 9 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        #E
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 4 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 11 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            #S
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 15 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 17 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                #S
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 19 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 19 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 21 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
    #r
            addi $a0, $zero, 5 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
        addi $a0, $zero, 1 # height
    addi $a1, $zero, 3 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 25 # starting x coordinate of rectangle
    addi $t2, $zero, 15 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
            addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 27 # starting x coordinate of rectangle
    addi $t2, $zero, 16 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                addi $a0, $zero, 1 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 26 # starting x coordinate of rectangle
    addi $t2, $zero, 17 # starting y coordinate of rectangle
    jal Rectangle_Setter
    
                    addi $a0, $zero, 2 # height
    addi $a1, $zero, 1 # width
    lw $a2, green_drawing_cell # value to store in rectangle cells
    addi $t1, $zero, 27 # starting x coordinate of rectangle
    addi $t2, $zero, 18 # starting y coordinate of rectangle
    jal Rectangle_Setter
    

    end_draw_game_over_screen:
    lw $ra, 0( $sp )        # retrieving return adress from stack
    addi $sp, $sp, 4        # moving stack pointer down a word
    
    jr $ra


#####################################################################################################

################### FUNCTION: Game_Over_Screen ######################################################
### This function displays game over on the screen when the game over condition is reached and starts
### a new game if the player selects retry by clicking r.

Game_Over_Screen:
jal Draw_Game_Over_Screen
jal Draw_Grid

				li $v0, 33
    li $a0, 38 # pitch
    li $a1, 1000 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    
    				li $v0, 33
    li $a0, 36 # pitch
    li $a1, 1000 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    				li $v0, 33
    li $a0, 34 # pitch
    li $a1, 1000 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    
        				li $v0, 33
    li $a0, 36 # pitch
    li $a1, 1000 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    
    				li $v0, 33
    li $a0, 38 # pitch
    li $a1, 1000 # duration
    li $a2, 81 # instrument
    li $a3, 20 # volume
    syscall
    
check_for_retry_press:
lw $t0, ADDR_KBRD    # $t0 = base address for keyboard
lw $t8, 0($t0)       # Load first word from keyboard into $t8
beq $t8, 1, retry_keyboard_input  #If first word == 1, key is pressed
j game_over_screen_sleep # if not key is pressed, continue to game over screen sleep

retry_keyboard_input:

lw $t2, 4($t0)      # load second word from keyboard

beq $t2, 0x72, retry    # branch to retry when r is pressed to start a new game
beq, $t2, 0x71, respond_to_Q
# else, continue to game over screen sleep

game_over_screen_sleep:
li $v0, 32 # slight sleeping needed for game over screen loop
li $a0, 20
syscall

j Game_Over_Screen   # jump back to Pause_Game if p is yet to be clicked a second time

retry:
jal Reset_Memory
j main

#####################################################################################################

################### FUNCTION: Reset_Virus_Memory ####################################################
### This function resets the number of each virus to 0 (in memory).
Reset_Virus_Memory:

la $t5, number_yellow_virus # load the address for the number of yellow viruses in $t5
sw $zero, 0( $t5 )          # reset the number of yellow viruses in memory to 0  
la $t5, number_red_virus # load the address for the number of red viruses in $t5
sw $zero, 0( $t5 )          # reset the number of red viruses in memory to 0  
la $t5, number_blue_virus # load the address for the number of blue viruses in $t5
sw $zero, 0( $t5 )          # reset the number of blue viruses in memory to 0  

# we are also gonna reset the number of erased lines in this function
la $t5, gravity_index_reset_counter # load the address for the number of times gravity has been applied
sw $zero, 0( $t5 )          # reset the number of times gravity has been applied to 0

end_reset_virus_memory:
jr $ra

#####################################################################################################

################### FUNCTION: Reset_Memory_Pill_Stats ####################################################
### This function resets the pill stats in memory (current_x, current_y, colour_1, colour_2, current_orientation,
### past_pill_index, and gravity_index)

Reset_Memory_Pill_Stats:

la $t4, current_x               # load the address for the current x coordinate in memory
lw $t5, initial_x               # load the value for the inital x value into t5
sw $t5, 0( $t4 )                # reset the current x value to initial x value 

la $t4, current_y               # load the address for the current y coordinate in memory
lw $t5, initial_y               # load the value for the inital x value into t5
sw $t5, 0( $t4 )                # reset the current x value to initial x value 

la $t4, colour_1                # load the address for the first pill hald colour into t4
sw $zero, 0( $t4 )              # reset colour 1 to 0 in memory

la $t4, colour_2                # load the address for the second pill hald colour into t4
sw $zero, 0( $t4 )              # reset colour 2 to 0 in memory

la $t4, current_orientation     # load the address for the current orientation colour into t4
sw $zero, 0( $t4 )              # reset orientation to 0 (vertical)

la $t4, past_pill_index         # load the address for the current orientation colour into t4
li $t5, 1                       # store a value of 1 in t5
sw $t5, 0( $t4 )              # reset past pill index to 1

la $t4, gravity_index           # load the address for the gravity index into t4
sw $zero, 0( $t4 )              # reset gravity index value to 0

end_reset_memory_pill_stats:
jr $ra

#####################################################################################################

################### FUNCTION: Reset_Memory_Game_Field ###############################################
### Resets each cell value in the game field grid to 0.

Reset_Memory_Game_Field:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Reset_Memory_Game_Field caller

addi $s5, $zero, 64 # the width of the grid is 64
addi $s6, $zero, 64 # the height of the grid is 64

add $t6, $zero, $zero           # set starting value of index ($t6) to zero

reset_memory_game_field_loop:
beq $t6, $s6, end_reset_memory_game_field # if $t6 == height ($s6), end resetting loop

### reset cells in a line (width 64) ###

add $t5, $zero, $zero # set index value $t5=0

reset_memory_game_field_row_loop:
beq $t5, $s5, end_reset_memory_game_field_row_loop   # if $t5 == width ($s5), end loop.
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1
add $a2, $zero, $zero           # value to reset to is zero

jal Cell_Setter

addi $t5, $t5, 1               # increment column index by 1
j reset_memory_game_field_row_loop

end_reset_memory_game_field_row_loop:
addi $t6, $t6, 1                # increment row index
j reset_memory_game_field_loop

end_reset_memory_game_field:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##########################################################################################

################### FUNCTION: Reset_Memory_Match_Tracker #################################
### Resets each cell value in the match tracker grid to 0.

Reset_Memory_Match_Tracker:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Reset_Memory_Match_Tracker caller

addi $s5, $zero, 64 # the width of the grid is 64
addi $s6, $zero, 64 # the height of the grid is 64

add $t6, $zero, $zero           # set starting value of index ($t6) to zero

reset_memory_match_tracker_loop:
beq $t6, $s6, end_reset_memory_match_tracker # if $t6 == height ($s6), end resetting loop

### reset cells in a line (width 64) ###

add $t5, $zero, $zero # set index value $t5=0

reset_memory_match_tracker_row_loop:
beq $t5, $s5, end_reset_memory_match_tracker_row_loop   # if $t5 == width ($s5), end loop.
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1
add $a2, $zero, $zero           # value to reset to is zero

jal Set_Match_Tracker_Cell

addi $t5, $t5, 1               # increment column index by 1
j reset_memory_match_tracker_row_loop

end_reset_memory_match_tracker_row_loop:
addi $t6, $t6, 1                # increment row index
j reset_memory_match_tracker_loop

end_reset_memory_match_tracker:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##########################################################################################

################### FUNCTION: Reset_Memory_Past_Pill_Tracker #################################
### Resets each cell value in the past pill tracker grid to 0.

Reset_Memory_Past_Pill_Tracker:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Reset_Memory_Past_Pill_Tracker caller

addi $s5, $zero, 64 # the width of the grid is 64
addi $s6, $zero, 64 # the height of the grid is 64

add $t6, $zero, $zero           # set starting value of index ($t6) to zero

reset_memory_past_pill_tracker_loop:
beq $t6, $s6, end_reset_memory_past_pill_tracker # if $t6 == height ($s6), end resetting loop

### reset cells in a line (width 64) ###

add $t5, $zero, $zero # set index value $t5=0

reset_memory_past_pill_tracker_row_loop:
beq $t5, $s5, end_reset_memory_past_pill_tracker_row_loop   # if $t5 == width ($s5), end loop.
add $a0, $zero, $t5             # store current x index in $a0
add $a1, $zero, $t6             # store current y index in $a1
add $a2, $zero, $zero           # value to reset to is zero

jal Past_Pill_Setter

addi $t5, $t5, 1               # increment column index by 1
j reset_memory_past_pill_tracker_row_loop

end_reset_memory_past_pill_tracker_row_loop:
addi $t6, $t6, 1                # increment row index
j reset_memory_past_pill_tracker_loop

end_reset_memory_past_pill_tracker:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
##########################################################################################

################### FUNCTION: Reset_Memory ###############################################
### Resets all values in memory to their original states.

Reset_Memory:
addi $sp, $sp, -4       # moving stack pointer up a word
sw   $ra, 0($sp)        # storing return adress for Reset_Memory caller

jal Reset_Virus_Memory
jal Reset_Memory_Pill_Stats
jal Reset_Memory_Game_Field
jal Reset_Memory_Match_Tracker
jal Reset_Memory_Past_Pill_Tracker

end_reset_memory:
lw $ra, 0( $sp )        # retrieving return adress from stack
addi $sp, $sp, 4        # moving stack pointer down a word

jr $ra
#####################################################################################################

respond_to_Q:
Exit:
li $v0, 10 # terminate the program gracefully
syscall
