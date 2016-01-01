#!/usr/bin/ruby

require 'rubygems'
require 'tesseract'
#run to grab ss from device: adb shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > test.png

class GameState
  #:victory (victory is at the top of the screen)
  #:reward_ok (reward with only ok button)
  #:reward_rune (rune reward, needs decision)
  #:need_energy (out of juice)
  #:replay (press replay screen)
  #:team_comp (selecting team screen)
  attr_accessor :screen_state
  @screen_state #:victory (just won, nothing pushed) :reward_ok (reward with only ok btuton):reward_rune
  attr_accessor :is_fodder_maxed
  @is_fodder_maxed
  
  def to_s
    return "GameState: [screen_state = #{@screen_state}][is_fodder_maxed = #{@is_fodder_maxed}]"
  end
end

$debug = true;
$all_whitelist = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"

def bin_and_crop(bin_amount, x, y, width, height)
  system "convert #{$image_path} -crop #{width}x#{height}+#{x}+#{y} -threshold #{bin_amount}%  -blur 1x1 temp.png"
  return "temp.png"
end

def get_game_state(test_image = nil)
  if (test_image)
    $image_path = test_image
  else
    $image_path = "curr.png"
    system "adb shell screencap -p | perl -pe 's/\\x0D\\x0A/\\x0A/g' > #{$image_path}"
  end
  @ocrEngine = Tesseract::Engine.new {|e|
    e.language = :eng
    e.blacklist = "|"
    #e.page_segmentation_mode = :SINGLE_BLOCK
  }
  #system "convert curr.png -threshold 57% curr.png"
  
  res = GameState.new
  if (is_need_energy?)
    puts "need energy detected" if $debug
    res.screen_state = :need_energy
  elsif (is_replay_screen?)
    puts "replay screen detected" if $debug
    res.screen_state = :replay
  elsif (is_victory_screen?)
    puts "victory screen detected" if $debug
    res.screen_state = :victory
    if (is_reward_ok_screen?)
      puts "reward ok only detected" if $debug
      res.screen_state = :reward_ok
    elsif (is_reward_rune_screen?)
      puts "reward rune detected" if $debug
      res.screen_state = :reward_rune
    elsif (is_fodder_maxed?)
      puts "fodder max detected" if $debug
      res.is_fodder_maxed = true;
    end
  elsif (is_team_comp_screen?)
    puts "team comp screen detected" if $debug
    res.screen_state = :team_comp
  end
  if ($debug)
    puts @ocrEngine.page_segmentation_mode
    puts res.to_s
  end
  return res
end

def is_victory_screen?
  time = Time.now if $debug
  @ocrEngine.whitelist = "VICTORY"
  @ocrEngine.page_segmentation_mode = :SINGLE_WORD
  # this is supposed to be x/y/width/height but doesnt work unless its ltrb?
  #ltrb box: 566, 122, 1209, 236
  #actual bounding box: 566, 122, 643, 114
  @ocrEngine.image = bin_and_crop(57, 566, 122, 643, 114)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_victory_screen? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text.include? "VICTORY"
end

def is_reward_ok_screen?
  # 770 840 250 110
  time = Time.now if $debug
  @ocrEngine.whitelist = "OK"
  @ocrEngine.page_segmentation_mode = :SINGLE_WORD
  @ocrEngine.image = bin_and_crop(57, 770, 840, 250, 110)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_reward_ok_screen? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text.include? "OK"
end

def is_reward_rune_screen?
  time = Time.now if $debug
  @ocrEngine.whitelist = $all_whitelist + "()-"
  @ocrEngine.page_segmentation_mode = :SINGLE_LINE
  @ocrEngine.image = bin_and_crop(75, 520, 260, 770, 90)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_reward_rune_screen? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text.include?("Rune")
end

def is_fodder_maxed?
  time = Time.now if $debug
  @ocrEngine.whitelist = "MAXLEV"
  @ocrEngine.page_segmentation_mode = :AUTO
  @ocrEngine.image = bin_and_crop(60, 419, 615, 1100, 260)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_fodder_maxed? parse time: #{parse_time}\n----------\n#{text}\n----------"
    puts text.scan(/MAX LEVEL/)
  end
  return text.scan(/MAX LEVEL/).size == 4
end

def is_need_energy?
  time = Time.now if $debug
  @ocrEngine.whitelist = "Not enough Energy."
  @ocrEngine.page_segmentation_mode = :SINGLE_BLOCK
  @ocrEngine.image = bin_and_crop(57, 650, 350, 530, 160)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_need_energy? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text.include?("Not enough Energy.")
end

def is_replay_screen?
  time = Time.now if $debug
  @ocrEngine.whitelist = "Replay"
  @ocrEngine.page_segmentation_mode = :SINGLE_BLOCK
  @ocrEngine.image = bin_and_crop(57, 250, 370, 1300, 400)
  text = @ocrEngine.text
  if ($debug)
    parse_time = Time.now - time
    puts "is_replay_screen? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text.include?("Replay")
end

def is_team_comp_screen?
  time = Time.now if $debug
  @ocrEngine.whitelist = $all_whitelist
  @ocrEngine.page_segmentation_mode = :SINGLE_LINE
  @ocrEngine.image = bin_and_crop(60, 750, 280, 290, 170)
  text = @ocrEngine.text.strip
  if ($debug)
    parse_time = Time.now - time
    puts "is_team_comp_screen? parse time: #{parse_time}\n----------\n#{text}\n----------"
  end
  return text == "VS"
end