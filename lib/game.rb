# frozen_string_literal: true

require_relative 'menuable'
require_relative 'save_and_load'
require_relative 'chess_tools'

# This is the class for chess
class Game
  include Menuable
  include SaveAndLoad
  include ChessTools
  attr_reader :board, :player1, :player2, :current_player, :move, :move_list, :game_over

  def initialize(**args)
    @player1 = args[:player1] || Player.new(color: 'white')
    @player2 = args[:player2] || Player.new(color: 'black')
    @current_player = @player1
    @move = Move
    post_initialize(**args)
  end

  def play
    Display.greeting # remove concretion?
    start_sequence
    turn_sequence until game_over
    play_again
  end

  # create factory for the factory? for this?
  def create_move(start_sq, end_sq)
    init_hsh = { player: current_player, board: board, move_list: move_list, start_sq: start_sq, end_sq: end_sq }
    move.factory(**init_hsh)
  end

  private

  def post_initialize(**args)
    @board = args[:board] || Board.new
    @move_list = args[:move_list] || MoveList.new
    white_set = PieceFactory.create_set('white')
    black_set = PieceFactory.create_set('black')
    pieces = { white_pcs: white_set, black_pcs: black_set }
    setup_board(pieces)
  end

  # can we remove instantiation of BoardLayout?
  def setup_board(chess_pieces, bl = nil)
    bl ||= BoardLayout.new(current_player: current_player, board: board, move_list: move_list, game: self) # delete later

    # bl.normal(chess_pieces)
    bl.pawn_promotion
    # bl.checkmate_scenarios
    # bl.self_check
    # bl.pawn_vs_pawn
    # bl.en_passant_white_version1
    # bl.en_passant_white_version2
    # bl.en_passant_black
    # bl.castle
    # bl.w_pawn_attack
    # bl.b_pawn_attack
  end


  def start_sequence
    start_input = gets.chomp
    # start_input = '1' # auto new game

    case start_input
    when '1'
      Display.draw_board(board)
      puts "\nA new game has started!".magenta
    when '2'
      load_game_file
      press_any_key
    end
  end

  def turn_sequence
    Display.draw_board(board)
    new_move = legal_move
    board.promote_pawn(new_move) if board.promotion?(new_move) # write this method
    new_move.test_check_other_player
    move_list.add(new_move)
    checkmate_seq(new_move) if new_move.checks
    switch_players
  end

  def checkmate_seq(new_move)
    new_move.test_checkmate_other_player(move_data)
    win(current_player) if new_move.checkmates
  end

  def move_data
    { player: other_player, board: board, move_list: move_list, move: move}
  end

  def legal_move(new_move = nil)
    loop do
      grid_json = board.serialize
      start_sq, end_sq = user_input
      new_move = create_move(start_sq, end_sq)
      new_move.transfer_piece if new_move.validated
      break if !board.check?(current_player.color) && new_move.validated

      Display.invalid_input_message
      revert_board(grid_json, board) if board.check?(current_player.color) # duplicated board.check, better way??
    end
    new_move
  end

  def switch_players
    @current_player = other_player
  end

  def other_player
    current_player == player1 ? player2 : player1
  end

  def win(player)
    Display.draw_board(board)
    Display.win(player)
    @game_over = true
  end

  def tie
    @game_over = true
  end

  def play_again
    Display.play_again_question
    input = gets.chomp
    case input
    when 'y'
      post_initialize
      @game_over = false
      @current_player = player1
      play
    when 'n'
      puts 'Oh okay. See you next time!'
      exit
    end
  end
end
