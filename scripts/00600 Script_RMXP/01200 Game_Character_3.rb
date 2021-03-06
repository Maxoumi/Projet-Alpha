#encoding: utf-8

class Game_Character
  # Move Game_Character down
  # @param turn_enabled [Boolean] if the Game_Character turns when impossible move
  def move_down(turn_enabled = true)
    # 下を向く
    if turn_enabled
      turn_down
    end
    # 通行可能な場合
    if passable?(@x, @y, 2)
      #Check du talus
      if($game_map.system_tag(@x,@y+1) == JumpD)
        jump(0,2,false)
        return follower_move
      end
      # 下を向く
      turn_down
      #> Check du pont
      bridge_down_check(@z)
      # 座標を更新
      @y += 1
      movement_process_end
      # 歩数増加
      increase_steps
    # 通行不可能な場合
    else
      @sliding = false
      # 接触イベントの起動判定
      check_event_trigger_touch(@x, @y+1)
    end
  end
  # Move Game_Character left
  # @param turn_enabled [Boolean] if the Game_Character turns when impossible move
  def move_left(turn_enabled = true)
    # 左を向く
    if turn_enabled
      turn_left
    end
    unless @through
      if front_system_tag==StairsL
        return unless $game_map.system_tag(@x - 1, @y - 1) == StairsL
        return move_upper_left
      elsif system_tag==StairsR
        return move_lower_left
      end
    end
    # 通行可能な場合
    if passable?(@x, @y, 4)
      if($game_map.system_tag(@x-1,@y) == JumpL)
        jump(-2,0,false)
        return follower_move
      end
      # 左を向く
      turn_left
      #> Check du pont
      bridge_left_check(@z)
      # 座標を更新
      @x -= 1
      movement_process_end
      # 歩数増加
      increase_steps
    # 通行不可能な場合
    else
      @sliding = false
      # 接触イベントの起動判定
      check_event_trigger_touch(@x-1, @y)
    end
  end
  # Move Game_Character right
  # @param turn_enabled [Boolean] if the Game_Character turns when impossible move
  def move_right(turn_enabled = true)
    # 右を向く
    if turn_enabled
      turn_right
    end
    unless @through
      if system_tag==StairsL
        return move_lower_right
      elsif front_system_tag==StairsR
        return unless $game_map.system_tag(@x + 1, @y - 1) == StairsR
        return move_upper_right
      end
    end
    # 通行可能な場合
    if passable?(@x, @y, 6)
      #Check du talus
      if($game_map.system_tag(@x+1,@y) == JumpR)
        return (jump(2,0,false) ? follower_move : nil)
      end
      # 右を向く
      turn_right
      #> Check du pont
      bridge_right_check(@z)
      # 座標を更新
      @x += 1
      movement_process_end
      # 歩数増加
      increase_steps
    # 通行不可能な場合
    else
      @sliding = false
      # 接触イベントの起動判定
      check_event_trigger_touch(@x+1, @y)
    end
  end
  # Move Game_Character up
  # @param turn_enabled [Boolean] if the Game_Character turns when impossible move
  def move_up(turn_enabled = true)
    # 上を向く
    if turn_enabled
      turn_up
    end
    # 通行可能な場合
    if passable?(@x, @y, 8)
      #Check du talus
      if($game_map.system_tag(@x,@y-1) == JumpU)
        return (jump(0,-2,false) ? follower_move : nil)
      end
      # 上を向く
      turn_up
      #> Check du pont
      bridge_up_check(@z)
      # 座標を更新
      @y -= 1
      movement_process_end
      # 歩数増加
      increase_steps
    # 通行不可能な場合
    else
      @sliding = false
      # 接触イベントの起動判定
      check_event_trigger_touch(@x, @y-1)
    end
  end
  # Move the Game_Character lower left
  def move_lower_left
    # 向き固定でない場合
    unless @direction_fix
      # 右向きだった場合は左を、下向きだった場合は上を向く
      @direction = (@direction == 6 ? 4 : @direction == 2 ? 8 : @direction)
    end
    # 上→左、左→上 のどちらかのコースが通行可能な場合
    if (passable?(@x, @y, 2) and passable?(@x, @y + 1, 4)) or
       (passable?(@x, @y, 4) and passable?(@x - 1, @y, 2)) #8 à la place de 2 sur les deux lignes
      # 座標を更新
      move_follower_to_character
      @x -= 1
      #follower_move
      @y += 1
      if @follower
        @memorized_move=:move_lower_left if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
      end
      movement_process_end(true)
      # 歩数増加
      increase_steps
    end
  end
  # Move the Game_Character lower right
  def move_lower_right
    # 向き固定でない場合
    unless @direction_fix
      # 左向きだった場合は右を、下向きだった場合は上を向く
      @direction = (@direction == 4 ? 6 : @direction == 2 ? 8 : @direction)
    end
    # 上→右、右→上 のどちらかのコースが通行可能な場合
    if (passable?(@x, @y, 2) and passable?(@x, @y + 1, 6)) or
       (passable?(@x, @y, 6) and passable?(@x + 1, @y, 2))
      # 座標を更新
      move_follower_to_character
      @x += 1
      #follower_move
      @y += 1
      if @follower
        @memorized_move=:move_lower_right if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
      end
      movement_process_end(true)
      # 歩数増加
      increase_steps
    end
  end
  # Move the Game_Character upper left
  def move_upper_left
    # 向き固定でない場合
    unless @direction_fix
      # 右向きだった場合は左を、上向きだった場合は下を向く
      @direction = (@direction == 6 ? 4 : @direction == 8 ? 2 : @direction)
    end
    # 下→左、左→下 のどちらかのコースが通行可能な場合
    if (passable?(@x, @y, 8) and passable?(@x, @y - 1, 4)) or
       (passable?(@x, @y, 4) and passable?(@x - 1, @y, 8))
      # 座標を更新
      move_follower_to_character
      @x -= 1
      #follower_move
      @y -= 1
      if @follower
        @memorized_move = :move_upper_left if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
      end
      movement_process_end(true)
      # 歩数増加
      increase_steps
    end
  end
  # Move the Game_Character upper right
  def move_upper_right
    # 向き固定でない場合
    unless @direction_fix
      # 左向きだった場合は右を、上向きだった場合は下を向く
      @direction = (@direction == 4 ? 6 : @direction == 8 ? 2 : @direction)
    end
    # 下→右、右→下 のどちらかのコースが通行可能な場合
    if (passable?(@x, @y, 8) and passable?(@x, @y - 1, 6)) or
       (passable?(@x, @y, 6) and passable?(@x + 1, @y, 8))
      # 座標を更新
      move_follower_to_character
      @x += 1
      #follower_move
      @y -= 1
      if @follower
        @memorized_move = :move_upper_right if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
      end
      movement_process_end(true)
      # 歩数増加
      increase_steps
    end
  end
  # Move the Game_Character to a random direction
  def move_random
    case rand(4)
    when 0  # 下に移動
      move_down(false)
    when 1  # 左に移動
      move_left(false)
    when 2  # 右に移動
      move_right(false)
    when 3  # 上に移動
      move_up(false)
    end
  end
  # Move the Game_Character toward the player
  def move_toward_player
    # プレイヤーの座標との差を求める
    sx = @x - $game_player.x
    sy = @y - $game_player.y
    # 座標が等しい場合
    if sx == 0 and sy == 0
      return
    end
    # 差の絶対値を求める
    abs_sx = sx.abs
    abs_sy = sy.abs
    # 横の距離と縦の距離が等しい場合
    if abs_sx == abs_sy
      # ランダムでどちらかを 1 増やす
      rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
    end
    # 横の距離のほうが長い場合
    if abs_sx > abs_sy
      # 左右方向を優先し、プレイヤーのいるほうへ移動
      sx > 0 ? move_left : move_right
      if not moving? and sy != 0
        sy > 0 ? move_up : move_down
      end
    # 縦の距離のほうが長い場合
    else
      # 上下方向を優先し、プレイヤーのいるほうへ移動
      sy > 0 ? move_up : move_down
      if not moving? and sx != 0
        sx > 0 ? move_left : move_right
      end
    end
  end
  # Move the Game_Character away from the player
  def move_away_from_player
    # プレイヤーの座標との差を求める
    sx = @x - $game_player.x
    sy = @y - $game_player.y
    # 座標が等しい場合
    if sx == 0 and sy == 0
      return
    end
    # 差の絶対値を求める
    abs_sx = sx.abs
    abs_sy = sy.abs
    # 横の距離と縦の距離が等しい場合
    if abs_sx == abs_sy
      # ランダムでどちらかを 1 増やす
      rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
    end
    # 横の距離のほうが長い場合
    if abs_sx > abs_sy
      # 左右方向を優先し、プレイヤーのいないほうへ移動
      sx > 0 ? move_right : move_left
      if not moving? and sy != 0
        sy > 0 ? move_down : move_up
      end
    # 縦の距離のほうが長い場合
    else
      # 上下方向を優先し、プレイヤーのいないほうへ移動
      sy > 0 ? move_down : move_up
      if not moving? and sx != 0
        sx > 0 ? move_right : move_left
      end
    end
  end
  # Move the Game_Character forward
  def move_forward
    case @direction
    when 2
      move_down(false)
    when 4
      move_left(false)
    when 6
      move_right(false)
    when 8
      move_up(false)
    end
  end
  # Move the Game_Character backward
  def move_backward
    # 向き固定の状態を記憶
    last_direction_fix = @direction_fix
    # 強制的に向き固定
    @direction_fix = true
    # 向きで分岐
    case @direction
    when 2  # 下
      move_up(false)
    when 4  # 左
      move_right(false)
    when 6  # 右
      move_left(false)
    when 8  # 上
      move_down(false)
    end
    # 向き固定の状態を元に戻す
    @direction_fix = last_direction_fix
  end
  # Make the Game_Character jump
  # @param x_plus [Integer] the number of tile the Game_Character will jump on x
  # @param y_plus [Integer] the number of tile the Game_Character will jump on y
  # @param follow_move [Boolean] if the follower moves when the Game_Character starts jumping
  def jump(x_plus, y_plus,follow_move = true)
    Audio.se_play("Audio/SE/2G_Jump")
    # 加算値が (0,0) ではない場合
    if x_plus != 0 or y_plus != 0
      # 横の距離のほうが長い場合
      if x_plus.abs > y_plus.abs
        # 左右どちらかに向き変更
        x_plus < 0 ? turn_left : turn_right
        bridge_left_check(@z)
      # 縦の距離のほうが長いか等しい場合
      else
        # 上下どちらかに向き変更
        y_plus < 0 ? turn_up : turn_down
        bridge_down_check(@z)
      end
    end
    # 新しい座標を計算
    new_x = @x + x_plus
    new_y = @y + y_plus
    # 加算値が (0,0) の場合か、ジャンプ先が通行可能な場合
    if (x_plus == 0 and y_plus == 0) or passable?(new_x, new_y, 0) or 
        ($game_switches[::Yuki::Sw::EV_AccroBike] and front_system_tag == AcroBike)
      # 姿勢を矯正
      straighten
      # 座標を更新
      @x = new_x
      @y = new_y
      # 距離を計算
      distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
      # ジャンプカウントを設定
      @jump_peak = 10 + distance - @move_speed
      @jump_count = @jump_peak * 2
      # 停止カウントをクリア
      @stop_count = 0
      @pattern=(rand(2)==0 ? 1 : 3) unless follow_move
      movement_process_end(true)
      if follow_move and @follower and $game_variables[Yuki::Var::FM_Sel_Foll] == 0 and (x_plus != 0 or y_plus != 0)
        follower_move
        @memorized_move = :jump
        @memorized_move_arg = [x_plus, y_plus]
      end
    end
    particle_push
    return @jump_count > 0
  end
  # Turn down unless direction fix
  def turn_down
    unless @direction_fix
      @direction = 2
      @stop_count = 0
    end
  end
  # Turn left unless direction fix
  def turn_left
    unless @direction_fix
      @direction = 4
      @stop_count = 0
    end
  end
  # Turn right unless direction fix
  def turn_right
    unless @direction_fix
      @direction = 6
      @stop_count = 0
    end
  end
  # Turn up unless direction fix
  def turn_up
    unless @direction_fix
      @direction = 8
      @stop_count = 0
    end
  end
  # Turn 90° to the right of the Game_Character
  def turn_right_90
    case @direction
    when 2
      turn_left
    when 4
      turn_up
    when 6
      turn_down
    when 8
      turn_right
    end
  end
  # Turn 90° to the left of the Game_Character
  def turn_left_90
    case @direction
    when 2
      turn_right
    when 4
      turn_down
    when 6
      turn_up
    when 8
      turn_left
    end
  end
  # Turn 180°
  def turn_180
    case @direction
    when 2
      turn_up
    when 4
      turn_right
    when 6
      turn_left
    when 8
      turn_down
    end
  end
  # Turn random right or left 90°
  def turn_right_or_left_90
    if rand(2) == 0
      turn_right_90
    else
      turn_left_90
    end
  end
  # Turn in a random direction
  def turn_random
    case rand(4)
    when 0
      turn_up
    when 1
      turn_right
    when 2
      turn_left
    when 3
      turn_down
    end
  end
  # Turn toward the player
  def turn_toward_player
    # プレイヤーの座標との差を求める
    sx = @x - $game_player.x
    sy = @y - $game_player.y
    # 座標が等しい場合
    if sx == 0 and sy == 0
      return
    end
    # 横の距離のほうが長い場合
    if sx.abs > sy.abs
      # 左右方向でプレイヤーのいるほうを向く
      sx > 0 ? turn_left : turn_right
    # 縦の距離のほうが長い場合
    else
      # 上下方向でプレイヤーのいるほうを向く
      sy > 0 ? turn_up : turn_down
    end
  end
  # Turn away from the player
  def turn_away_from_player
    # プレイヤーの座標との差を求める
    sx = @x - $game_player.x
    sy = @y - $game_player.y
    # 座標が等しい場合
    if sx == 0 and sy == 0
      return
    end
    # 横の距離のほうが長い場合
    if sx.abs > sy.abs
      # 左右方向でプレイヤーのいないほうを向く
      sx > 0 ? turn_right : turn_left
    # 縦の距離のほうが長い場合
    else
      # 上下方向でプレイヤーのいないほうを向く
      sy > 0 ? turn_down : turn_up
    end
  end
end
