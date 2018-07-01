require 'rest-client'
require 'pp'
require 'json'
require 'colorize'

class RotaAPI

  def initialize
    @base_url = 'https://rota.praetorian.com/rota/service/play.php'
    res = RestClient.get("#{@base_url}?request=new&email=jonahliamhharris@gmail.com")
    @cookies = res.cookies
  end

  def place(x)
    JSON.parse(RestClient.get("#{@base_url}?request=place&location=#{x}", :cookies => @cookies))
  end

  def move(x, y)
    JSON.parse(RestClient.get("#{@base_url}?request=move&from=#{x}&to=#{y}", :cookies => @cookies))
  end

  def status
    JSON.parse(RestClient.get("#{@base_url}?request=status", :cookies => @cookies))
  end

  def reset
    res = RestClient.get("#{@base_url}?request=new&email=jonahliamhharris@gmail.com")
    @cookies = res.cookies
    JSON.parse(res)
  end

end

# Begin solution of ROTA Challenge
if __FILE__ == $0

  # Definitions for left and right positions of adjacent $board positions
  # Accessed via the current position index
  $right_of = [
    -1, # No board position for 0, so -1
    4,  # 1
    1,  # 2
    2,  # 3
    7,  # 4
    6,  # 5 is center, but maybe this will prove useful
    3,  # 6
    8,  # 7
    9,  # 8
    6,  # 9
  ]  
  $left_of = [
    -1, # No board position for 0, so -1
    2,  # 1
    3,  # 2
    6,  # 3
    1,  # 4
    4,  # 5 is center, but maybe this will prove useful
    9,  # 6
    4,  # 7
    7,  # 8
    8,  # 9
  ]
  $opposite_of = [
    -1, # No board position for 0, so -1
    9,  # 1
    8,  # 2
    7,  # 3
    6,  # 4
    -1, # 5 is center and should not be called at any time when using this array
    4,  # 6
    3,  # 7
    2,  # 8
    1,  # 9
  ]

  # List of all possible positions from current position
  $possible_moves = [
    [-1, -1, -1], # No board position for 0, so -1
    [4, 2, 5], # 1
    [1, 3, 5], # 2
    [2, 6, 5], # 3
    [7, 1, 5], # 4
    [1, 2, 3, 4, 6, 7, 8, 9], # 5, all positions possible
    [3, 9, 5], # 6
    [8, 4, 5], # 7
    [9, 7, 5], # 8
    [6, 8, 5], # 9
  ]



  # Computer locations found and covered
  $coms
  # Player locations
  $players
  # Current board status
  $board
  # Last board status for updates
  $last_board
  # Instance of ROTA class we are using for game
  $rota
  # Current number of games played
  $games = 0
  # Goal for number of games
  $game_goal = 50
  # Current number of total moves for the game
  $moves = 0
  # Goal for number of moves
  $move_goal = 30
  # Is it my move or not
  $my_move = false



  # Function for pulling current player placements
  def current_board(status)
    status = status.to_s
    #puts String.colors
    status = status[40, 10]   # extra first character to allow indexing by correct placements values
    return status
  end

  # Function for returning status of game (computer has won or not)
  def computer_won(status)
    status = status.to_s
    if status.include? "\"computer_wins\"=>1"
      return true
    else
      return false
    end
  end

  # Function for obtaining the current moves of the game
  def current_moves(status)
    status = status.to_s
    status = status[100, 2] # index of current move counter
    status = status.to_i
    return status
  end

  # Function for checking for diagonal solution for computer placement if c at center position
  def check_for_diagonal()
    if $coms.include? 5
      coms_temp = $coms.clone
      coms_temp.delete(5)     # remove the center position
      if coms_temp.length == 0 # first move at center position
        return false
      else
        while coms_temp.length > 0
          temp = coms_temp.pop    # get another computer position
          if $board[$opposite_of[temp]] == "-"
            if $board[$left_of[$opposite_of[temp]]] == "p" || $board[$right_of[$opposite_of[temp]]] == "p"
              return false
            end
            $rota.place($opposite_of[temp])
            $players.push($opposite_of[temp])
            puts "Diagonal avoided: Outer Placment".red
            return true
          end
        end
      end
    else
      coms_temp = $coms.clone
      if coms_temp.length < 2 # At least 2 computer placements so far
        return false
      else 
        while coms_temp.length > 0    
          temp = coms_temp.pop    # get another computer position
          if coms_temp.include? $opposite_of[temp]
            $rota.place(5)
            $players.push(5)
            puts "Diagonal avoided: Center Placement".red
            return true
          end
        end
      end
    end
    return false
  end

  # Function for checking for diagonal solution for computer placement if c at center position
  def check_for_diagonal_game()
    if $coms.include? 5
      coms_temp = $coms.clone
      coms_temp.delete(5)     # remove the center position
      while coms_temp.length > 0
        temp = coms_temp.pop    # get another computer position
        if $board[$opposite_of[temp]] == "-"
          if $board[$right_of[$opposite_of[temp]]] == "p"
            move = $right_of[$opposite_of[temp]]
            if move_player(move)
              $rota.move(move, $opposite_of[temp])
              $players.push($opposite_of[temp])
              $players.delete(move)
              puts "Diagonal avoided: Outer Placment".red
              return true
            end
          elsif $board[$left_of[$opposite_of[temp]]] == "p"
            move = $left_of[$opposite_of[temp]]
            if move_player(move)
              $rota.move(move, $opposite_of[temp])
              $players.push($opposite_of[temp])
              $players.delete(move)
              puts "Diagonal avoided: Outer Placment".red
              return true
            end
          end
        end
      end
    # else
    #   coms_temp = $coms.clone
    #   while coms_temp.length > 0    
    #     temp = coms_temp.pop    # get another computer position
    #     if coms_temp.include? $opposite_of[temp]
    #       $rota.place(5)
    #       $players.push(5)
    #       puts "Diagonal avoided: Center Placement".red
    #       return true
    #     end
    #   end
    end
    return false
  end

  # Function for finding an open space for piece placement
  def find_space(com)
    if $coms.include? com 
      return false
    else
      $coms.push(com)
      puts "New computer piece recorded".yellow
      if $players.length == 3   # Already placed 3 players, we are done
        return false
      end
      if check_for_diagonal()
        return true
      end
    end
    if $board[$right_of[com]] == "-" && $board[$right_of[$right_of[com]]] != "p"
      $rota.place($right_of[com])
      $players.push($right_of[com])
      return true
    elsif $board[$left_of[com]] == "-" && $board[$left_of[$left_of[com]]] != "p"
      $rota.place($left_of[com])
      $players.push($left_of[com])
      return true
    else
      # Other placement procedure if above does not work
    end
    puts "\nCould not find open space for placement!!! :(\n\n".red
    puts $rota.status
    exit(1)  # Kill program for revisions
  end

  # Function to check if we should attempt to move player
  def move_player(player)
    if $board[$opposite_of[player]] == "c" && $board[5] == "c" && 
      ($board[$right_of[player]] == "c" || $board[$left_of[player]] == "c")
      return false  # Don't move; we are blocking a diagonal computer solution
    end
    return true
  end

  # Function to check if space is a good move
  def good_move(player, move)
    coms_temp = $coms.clone
    coms_temp.delete(5)
    while coms_temp.length > 0
      temp = coms_temp.pop    # get another computer position
      if ($board[$right_of[temp]] == "-" && $left_of[temp] == player) || 
          ($board[$left_of[temp]] == "-" &&  $right_of[temp] == player)
        return false
      end
    end
    if player == 5  # Check if by moving we are creating easy computer diagonal
      coms_temp = $coms.clone
      while coms_temp.length > 0
        temp = coms_temp.pop    # get another computer position
        if $board[$opposite_of[temp]] == "c"
          return false
        end
      end
    end
    if $board[move] == "-" && 
      (($board[$right_of[move]] != "p" || $right_of[move] == player) && 
        ($board[$left_of[move]] != "p" ||  $left_of[move] == player) || move == 5)
      $rota.move(player, move)
      $players.delete(player)
      $players.push(move)
      return true
    end
    return false  # No move placed
  end

  # Function for deciding on a move
  def make_move()
    players_temp = $players.clone
    while players_temp.length > 0 && $my_move == true
      player = players_temp.pop
      puts "Picking player: #{player}".cyan
      if move_player(player)
        move_check = $possible_moves[player].clone
        while move_check.length > 0 && $my_move == true
          possible_move = move_check.pop
          puts "Picking move: #{possible_move}".cyan
          if good_move(player, possible_move) # If space open, check if good move
            $my_move = false
            puts "Move found and placed: #{player} to #{possible_move}".magenta
          end # Check for if space open
        end # Loop for possible moves of a player
      end # Check if we should move player
    end # Loop for players
  end

  # Function for resetting game for testing
  def reset_game()
    $coms = Array.new
    $players = Array.new
  end

  # Function for color coding board tokens
  def print_token(token)
    if token == "p"
      print "#{token}".blue
    elsif token == "c"
      print "#{token}".red
    else
      print "#{token}"
    end
  end

  # Function for printing board for debugging
  def print_board()
    print "\t\t\t"
    print_token($board[2])
    print "\n\n"
    print "\t\t"
    print_token($board[1])
    print "\t\t"
    print_token($board[3])
    print "\n\n"
    print "\t"
    print_token($board[4])
    print "\t\t"
    print_token($board[5])
    print "\t\t"
    print_token($board[6])
    print "\n\n"
    print "\t\t"
    print_token($board[7])
    print "\t\t"
    print_token($board[9])
    print "\n\n"
    print "\t\t\t"
    print_token($board[8])
    print "\n"
  end

  # Begin new instance of ROTA class
    $rota = RotaAPI.new

  while $games < $game_goal

    if $games != 0
      $rota.reset
    end

    puts $rota.status
    $board = current_board($rota.status)
    com = -1
    count = 1
    waiting_for = 1

    # Reset procedure for testing
    reset_game()

    # Place start pieces
    start = 0
    while start == 0

      # Need to use board.count("c") to know when to update board.
      # Break after every loop: for 1 c do first if, second c second if, etc
      if $board.include? "c"
        while count != waiting_for
          $board = current_board($rota.status)
          count = $board.count("c")
        end
        waiting_for += 1
        if waiting_for > 3
          waiting_for = 3
        end
        com = $board.index('c')
        if find_space(com)
          $last_board = $board
          $board = current_board($rota.status)
        end
        if count >= 2 && $coms.length < 3
          com = $board.index('c', com + 1)
          if find_space(com)
            $last_board = $board
            $board = current_board($rota.status)
          end
          if count == 3 && $coms.length < 3
            com = $board.index('c', com + 1)
            if find_space(com)
              $last_board = $board
              $board = current_board($rota.status)
            end
          end
        end
      else
        $rota.place(2)   # If my move first, place at 2
        $players.push(2)
        $my_move = true
      end
      if $coms.length >= 3
        start = 1
      end
      # puts "Number of computer placements: #{$coms.length}".blue
      puts "Current coms: #{$coms}".yellow
      puts "Current players: #{$players}".yellow
      $board = current_board($rota.status)
      puts $rota.status
    end

    $board = current_board($rota.status)
    print_board()

    if computer_won($rota.status)
      puts "\n\n"
      puts "\n\nBUG: COMPUTER WON! :(\n\n".colorize(:color => :red,:background => :blue)
      puts "\n\n"
      exit(1)
    end

    puts "\n\n"
    puts "Placement Complete!".colorize(:background => :blue)
    puts "\n\n"

    $board = current_board($rota.status)
    puts "\n\n"
    print_board()
    puts "\n\n"


    # Begin game
    # Goal is 31 moves to see if the game automatically stops at 30
    # Assumption: a computer move also counts for total moves
    while $moves <= $move_goal

      # Update mappings of players and computers
      $board = current_board($rota.status)
      i = 1
      while i < $board.length
        if $board[i] == "c"
          if !($coms.include? i)
            puts "New com location: #{i}".light_red
            $coms.push(i)
            $my_move = true
          end
        elsif $board[i] == "-"
          if $coms.include? i
            puts "Old com location: #{i}".red
            $coms.delete(i)
          end
        end
        i += 1
      end

      # Go through all player pieces and look at available moves...
      # If the move would allow a diagonal win for the com, go to next move possible...
      # If all moves exhausted, go to next piece to move
      # If all moves by all pieces results in loss, exit and modify program!
      if $my_move
        if !check_for_diagonal_game()
          make_move()
        else
          $my_move = false
        end # Diagonal check
      end

      $board = current_board($rota.status)
      puts "\n\n"
      print_board()
      puts "\n\n"
      $moves = current_moves($rota.status)
      puts "Current moves: #{$moves}".yellow
      puts "Current coms: #{$coms}".yellow
      puts "Current players: #{$players}".yellow
      puts $rota.status
      if computer_won($rota.status)
        puts "\n\n"
        puts "BUG: COMPUTER WON! :(".colorize(:color => :red,:background => :blue)
        puts "\n\n"
        $board = current_board($rota.status)
        print_board()
        exit(1)
      end
      if $my_move
        puts "\n\n"
        puts "BUG: STUCKKKKKK :(".colorize(:color => :red,:background => :blue)
        puts "\n\n"
        $board = current_board($rota.status)
        print_board()
        exit(1)
      end
    end

    $moves = 0
    $games += 1

    puts "\n\n\n\n\n"
    puts "Successful Games: #{$games}".colorize(:color => :black,:background => :green)
    puts "\n\n\n\n\n"
  end
end
