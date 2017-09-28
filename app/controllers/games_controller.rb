require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def game
    @grid = generate_grid(9)
    @start_time = Time.now
    session[:amount] = 0 if !session[:amount]
    session[:average_score] = [] if !session[:average_score]
  end

  def score
    @end_time = Time.now
    @attempt = params[:attempt]
    @start_time = Time.parse(params[:start_time])
    @grid = params[:grid]
    @result = run_game(@attempt, @grid, @start_time, @end_time)
    @amount = session[:amount]
    session[:amount] += 1
    session[:average_score] << @result[:score]
    @average_score = session[:average_score].inject{ |sum, el| sum + el }.to_f / session[:average_score].size

  end

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a.sample }
  end

  def included?(guess, grid)
  guess.chars.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    time_taken > 60.0 ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    score_and_message = score_and_message(attempt, grid, result[:time])
    result[:score] = score_and_message.first
    result[:message] = score_and_message.last

    result
  end

  def score_and_message(attempt, grid, time)
    if included?(attempt.upcase, grid)
      if english_word?(attempt)
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not an english word"]
      end
    else
      [0, "not in the grid"]
    end
  end

  def english_word?(word)
    response = open("https://wagon-dictionary.herokuapp.com/#{word}")
    json = JSON.parse(response.read)
    return json['found']
  end

end
