# frozen_string_literal: true

# This is the class for chess
class Chess
  attr_reader :board, :player1, :player2, :current_player

  def initialize(board = nil, player1 = nil, player2 = nil)
    @board = board || Board.new
    @player1 = player1 || Player.new(color: 'white')
    @player2 = player2 || Player.new(color: 'black')
    @current_player = @player1
    white_set = PieceFactory.create_set('white')
    black_set = PieceFactory.create_set('black')
    pieces = { white_pcs: white_set, black_pcs: black_set }
    setup_board(pieces)
  end

  # Array of all 64 squares in index notation
  def board_squares
    squares = []
    8.times do |x|
      8.times do |y|
        squares << [x, y]
      end
    end
    squares
  end

  def setup_board(chess_pieces)
    (0..1).each { |x| board.grid[1][x] = chess_pieces[:white_pcs][x] }
    (0..1).each { |x| board.grid[6][x] = chess_pieces[:black_pcs][x] }

    # We can combine these 2 lines somehow. Do it later.
    # (0..7).each { |x| board.grid[1][x] = chess_pieces[:white_pcs][x] }
    # (0..7).each { |x| board.grid[6][x] = chess_pieces[:black_pcs][x] }
  end

  def play
    Display.greeting
    Display.draw_board(board)

    4.times { turn_loop }

    # turn_loop until game_over?
  end

  def game_over?
    false
  end

  def turn_loop
    Display.turn_message(current_player.color)
    move_sequence
    Display.draw_board(board)
    switch_players
  end

  def move_sequence
    start_sq, end_sq = input_move
    transfer_piece(start_sq, end_sq)
  end

  def transfer_piece(start_sq, end_sq)
    start_piece = board_object(start_sq)
    start_piece.moved
    board.grid[end_sq[0]][end_sq[1]] = start_piece
    board.grid[start_sq[0]][start_sq[1]] = 'unoccupied'
  end

  def input_move
    loop do
      Display.input_start_msg
      start_sq = gets.chomp.split('').map(&:to_i)
      Display.input_end_msg
      end_sq = gets.chomp.split('').map(&:to_i)
      return [start_sq, end_sq] if permissible?(start_sq, end_sq)

      Display.invalid_input_message
    end
  end

  def board_object(position_arr)
    board.grid[position_arr[0]][position_arr[1]]
  end

  def permissible?(start_sq, end_sq)
    # both inputs must be on the board
    return false unless board_squares.include?(start_sq) && board_squares.include?(end_sq)
    # start point must be a game piece
    return false if board_object(start_sq) == 'unoccupied'
    # false if piece cannot reach end square
    return false unless reachable?(start_sq, end_sq)

    true

    # You must match player color and piece color

    # false if second input is not one of piece's next moves
    # false if puts own king into check

    # array.fetch(1, 'dft val') # fetch uses a value for lookup. dig uses indexing
    # return false unless board.grid.fetch([end_sq[0]], [end_sq[1]])
    # return false unless board.include? board.grid[end_sq[0]][end_sq[1]]
  end

  def reachable?(start_sq, end_sq)
    piece = board_object(start_sq)
    return false if piece.color != current_player.color

    # Create array of possible squares piece can travel to
    reachable_squares = piece.legal_next_moves(start_sq, piece.color, board_squares)
    puts 'legal move!' if reachable_squares.include?(end_sq)
    reachable_squares.include?(end_sq) ? true : false
  end

  def switch_players
    @current_player = current_player == player1 ? player2 : player1
  end
end
