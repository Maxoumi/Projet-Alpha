module GamePlay
  class Sumary
    # Show the Informations of the Pokémon in the Sumary interface
    class Skill_B < UI::SpriteStack
      include UI
      def initialize(viewport, i, x = 0, y = 0, default_cache: :interface)
        super(viewport, x, y + i * 32, default_cache: default_cache)
        #push(164, 90, nil, type: TypeSprite)
        add_text(96, 160, 85, 16, :name_upper, type: SymText)
        #add_text(211, 105, 20, 16, _get(27, 32)) # PP
        push(192, 178, "PP")
        add_text(216, 176, 52, 16, :pp, 2, type: SymText)
        add_text(232, 176, 52, 16, "/", 2)
        add_text(264, 176, 52, 16, :ppmax, 2, type: SymText)
        @i = i
      end
      # Change the Pokemon shown
      # @param v [PFM::Pokemon]
      def data=(v)
        return self.visible = false unless v
        v = v.skills_set[@i]
        return self.visible = false unless v
        self.visible = true
        super
      end
    end
  end
end