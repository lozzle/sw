#!/usr/bin/ruby

require_relative 'sw_whats_happening'

$debug = true

def wait_for_user(message)
  puts "#{message}.  Press enter to continue..."
  return gets.strip
end

while(true)
  test_file = wait_for_user("Debug waiting.  Enter test file (optional)") if $debug
  test_file = nil if test_file.empty?
  game_state = get_game_state(test_file)
  case game_state.screen_state
    when :victory
      if game_state.is_fodder_maxed
        wait_for_user("Fodder is maxed")
        next
      else
        puts "victory screen, open reward routine"
      end
    when :reward_ok
      puts "reward ok, click ok"
    when :reward_rune
      puts "reward rune, click sell"
    when :need_energy
      wait_for_user("Out of energy")
    when :replay
      puts "replay, click replay"
    when :team_comp
      puts "team comp, click start battle"
  end
end