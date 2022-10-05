# frozen_string_literal: true

require_relative 'menuable'
require_relative 'save_and_load'
require_relative 'chess_tools'
# This is the class for chess
class Game
  include Menuable
  include SaveAndLoad
  include ChessTools
  attr_reader :board, :player1, :player2, :current_player, :move, :move_list

  def initialize(**args)
    @board = args[:board] || Board.new
    @player1 = args[:player1] || Player.new(color: 'white')
    @player2 = args[:player2] || Player.new(color: 'black')
    @current_player = @player1
    # @opposing_player = @player2
    @move = Move
    post_initialize(**args)
  end

  def post_initialize(**args)
    @move_list = args[:move_list] || MoveList.new
    white_set = PieceFactory.create_set('white')
    black_set = PieceFactory.create_set('black')
    pieces = { white_pcs: white_set, black_pcs: black_set }
    setup_board(pieces)
  end

  def setup_board(chess_pieces)
    tl = TempLayout.new(current_player: current_player, board: board, move_list: move_list, game: self) # delete later

    # tl.normal(chess_pieces)

    tl.self_check
    # tl.pawn_vs_pawn
    # tl.en_passant_white_version1
    # tl.en_passant_white_version2
    # tl.en_passant_black
    # tl.castle
    # tl.w_pawn_attack
    # tl.b_pawn_attack
  end

  def play
    Display.greeting # change Display to display somehow
    start_sequence
    # Display.draw_board(board)

    # turn_sequence # run once, testing
    50.times { turn_sequence }
    # turn_sequence until game_over?
  end

  def start_sequence

    # start_input = gets.chomp # auto new game, revert later
    start_input = '1'

    case start_input
    when '1'
      Display.draw_board(board)
      puts "\nA new game has started!".magenta
    when '2'
      # puts 'Loading game!'
      load_game_file
      press_any_key
    end
  end

  def turn_sequence
    new_move = legal_move
    new_move.test_check_other_player
    new_move.test_checkmate_other_player if new_move.checks
    move_list.add(new_move)

    # gets
    # board.test_mate
    # We use board_clone for #test_mate
    # board_clone = board.clone

    Display.draw_board(board)
    switch_players
    puts 'Check!'.bg_red if new_move.checks
  end

  def legal_move(new_move = nil)
    loop do
      grid_json = board.serialize
      start_sq, end_sq = user_input
      new_move = create_move(start_sq, end_sq)

      new_move.transfer_piece if new_move.validated
      break if !board.check?(current_player.color) && new_move.validated

      Display.invalid_input_message
      revert_board(grid_json) if board.check?(current_player.color) # duplicated board.check, better way??
    end
    new_move
  end

  def revert_board(grid_json)
    load_board(grid_json)
  end

  # create factory for this?
  def create_move(start_sq, end_sq)
    move.factory(player: current_player, board: board, move_list: move_list, start_sq: start_sq, end_sq: end_sq)
  end

  def switch_players
    @current_player = current_player == player1 ? player2 : player1
    # @opposing_player = current_player == player1 ? player2 : player1
  end

  # the follow 4 methods could be moved, or extracted
  def user_input(start_sq = '', end_sq = '')
    loop do
      Display.turn_message(current_player.color)
      input = gets.chomp.downcase

      if input == 'menu'
        menu_sequence
      else
        cleaned_input = clean(input) # cleaned input may be nil now
        start_sq, end_sq = convert_to_squares(cleaned_input)
        break if pass_prelim_check?(start_sq, end_sq)
      end

      Display.invalid_input_message unless input == 'menu'
    end
    [start_sq, end_sq]
  end

  def clean(input)
    input = input.gsub(/[^0-8a-h]/, '')
    input if input.match(/^[a-h][0-8][a-h][0-8]$/) # same as checking if in-bounds
  end

  def convert_to_squares(input)
    return if input.nil?

    inputted_beg_sq = input[0..1]
    inputted_fin_sq = input[2..3]
    start_sq = translate_notation_to_square_index(inputted_beg_sq)
    end_sq = translate_notation_to_square_index(inputted_fin_sq)
    [start_sq, end_sq]
  end

  def pass_prelim_check?(start_sq, end_sq)
    # return false if board.object(start_sq) == 'unoccupied'
    return false if out_of_bound?(board, start_sq, end_sq)
    return false if board.object(end_sq).is_a?(Piece) && board.object(end_sq).color == current_player.color
    return true if board.object(start_sq).is_a?(Piece) && board.object(start_sq).color == current_player.color
  end

  def menu_sequence
    menu_choice = game_menu
    case menu_choice
    when 'save'
      save_game_file
    when 'load'
      load_game_file
    when 'move_list'
      puts move_list.all_moves.join(', ').magenta
      puts ' '
    when 'help'
    end
    press_any_key
    Display.draw_board(board)
  end

  def game_over?
    # check_mate
    # draw
    false
  end
end
