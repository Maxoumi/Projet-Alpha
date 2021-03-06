#noyard
module GamePlay
  class InputNumber < Sprite
    BitmapFile = "NumIn_BG"
    BltCoords = [
      Rect.new(0,0,30,48), #>Surface de début de l'interface
      Rect.new(33,0,14,48), #>Surface d'un numéro
      Rect.new(57,0,6,48), #> Surface d'un séparateur
      Rect.new(174,0,20,48), #> Surface de la fin de l'interface
      Rect.new(174,0,20,48)
    ]
    Minus = ""
    attr_accessor :max, :min
    attr_reader :number
    include Text::Util
    #===
    #> Génération de l'objet, on prend un nombre max de digits et accessoirement le nombre dé départ
    #===
    def initialize(max_digits, default_number = 0, viewport = nil, accept_negatives = false)
      raise RangeError, "Bad value for max_digits : #{max_digits}" if max_digits <= 0
      super(viewport)
      @text = Sprite.new(viewport)
      @max_digits = max_digits #> Nombre max de digits
      max_digits += 1 if accept_negatives
      @accept_negatives = accept_negatives #> Si on accepte les nombres négatifs
      @max = (10**@max_digits) - 1
      @min = accept_negatives ? -@max : 0
      self.number = default_number
      @default_number = @number
      #>Génération du background
      #>Calcul des deux surfaces
      BltCoords[1] = Rect.new(33,0,12,48) if $game_temp.shop_calling
      BltCoords[2] = Rect.new(57,0,6,48) if $game_temp.shop_calling
      BltCoords[3] = Rect.new(83,0,67,48) if $game_temp.shop_calling
      BltCoords[4] = Rect.new(96,0,96,48) if $game_temp.shop_calling
      text_width = (BltCoords[1].width + BltCoords[2].width) * max_digits
      width = BltCoords[0].width + text_width + BltCoords[3].width
      width += BltCoords[4].width if $game_temp.shop_calling
      height = BltCoords[0].height
      #>Génération des surfaces
      bmp = self.bitmap = Bitmap.new(width, height)
      init_text(0, viewport)
      bg_bmp = ::RPG::Cache.interface(BitmapFile)
      #>Position de l'interface sur l'axe x
      self.x = 320 - width + BltCoords[2].width
      @text_x = self.x + BltCoords[0].width
      #>Calculs du tableau de positions et dessin du background
      #>Début de l'interface
      x = 0
      width = BltCoords[0].width
      array = Array.new
      bmp.blt(x, 0, bg_bmp, BltCoords[0])
      x += width
      #>Contenu de l'interface
      1.step(max_digits-1) do
        array << x - width
        bmp.blt(x, 0, bg_bmp, BltCoords[1])
        x += BltCoords[1].width
        bmp.blt(x, 0, bg_bmp, BltCoords[2])
        x += BltCoords[2].width
      end
      #> Dernier digit
      array << x - width
      bmp.blt(x, 0, bg_bmp, BltCoords[1])
      x += BltCoords[1].width
      #>Fin de l'interface
      bmp.blt(x, 0, bg_bmp, BltCoords[3])
      if $game_temp.shop_calling
        x += BltCoords[3].width
        bmp.blt(x, 0, bg_bmp, BltCoords[4])
      end
      bmp.update
      #>Enregistrement de la position des digits
      generate_texts(array)
      #@text_positions = array
      @digit_index = -1
      @y = 0
      draw_digits
    end
    
    def update
      #@text.y = self.y
      #@text.z = self.z + 1
      if(Input.repeat?(:DOWN))
        self.number -= 1
        #self.number -= (10**(-@digit_index - 1))
      elsif(Input.repeat?(:UP))
        self.number += 1
        #self.number += (10**(-@digit_index - 1))
      elsif(Input.trigger?(:LEFT))
          if(self.number < 10)
            self.number -= self.number
          else
            self.number -= 10
          end
      elsif(Input.trigger?(:RIGHT))
          if(self.number > @max-9)
            self.number = @max
          else
            self.number += 10
          end
      elsif(Input.trigger?(:B))
        self.number = @default_number
      end
      draw_digits
    end
    
    def generate_texts(array)
      width = BltCoords[1].width
      height = BltCoords[1].height
      array.each do |x|
        add_text(x + @text_x, 0, width, height, Minus, 0)
      end
      if $game_temp.shop_calling
        #add_text(@text_x + self.bitmap.width - width - BltCoords[4].width-44, 0, BltCoords[4].width, height, Minus, 2)
        add_text(210, 0, BltCoords[4].width, height, Minus, 2)
      end
    end
    
    def draw_digits
      if $game_temp.shop_calling
        @texts.last.text = _parse(11, 9, /\[VAR NUM7[^\]]*\]/ => (@number*$game_temp.shop_calling).to_s)
        offset = 1
      else
        offset = 0
      end
      
      value = @number
      if(value < 0)
        value = value.abs
        @texts.first.text = Minus
      end
      
      max_digit = @max_digits
      max_digit -= 1 if @accept_negatives
      index = -1
      
      max_digit.times do |i|
        text = @texts[index - offset]
        text.visible = (i == 0 or value != 0)
        text.text = (value%10).to_s
        text.load_color(@digit_index == index ? 0 : 0)
        value /= 10
        index -= 1
      end
      
      if self.y != @y
        @texts.each do |text|
          self.y = 288 - height if $game_temp.shop_calling
          text.y = self.y - FOY
        end
        #@y = self.y
        self.y = 288 - height if $game_temp.shop_calling
      end
    end
    
    def number=(v)
      if(v > @max)
        v = @min
      elsif(v < @min)
        v = @max
      end
      @number = v
    end
    
    def dispose
      text_dispose
      super
    end
  end
end