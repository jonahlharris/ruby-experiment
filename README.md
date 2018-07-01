# ruby-experiment

Here is my solution the tech challenge for beating the ROTA AI in Ruby.

The object of the game is to get your three pieces in a row on the 9 placement board. Here we want to keep the computer from winning for 50 consecutive games of 30 moves each, not including the initial 3 placement moves of each game.

The game begins with placing the initial 3 pieces for the computer and player. My algorithm determines whether the computer has gone first and then begins placing a piece based on the computer piece's initial location. If it's my turn, I just place at the top of board like so:

			P

		-		-

	-		-		-

		-		-	

			-

After all the pieces are placed, the program enters the second algorithm for determing safe moves to ensure I do not give the computer a victory. After that, the program waits for the data feedback of the server to say 30 moves and then increase the game count and reset the game. It then begins with placement again and repeats 50 times.

You are welcome to run the program and see output of each move and flags for different statuses of the game! You may just have to install some json and color scheme packages.

Thank you for looking!