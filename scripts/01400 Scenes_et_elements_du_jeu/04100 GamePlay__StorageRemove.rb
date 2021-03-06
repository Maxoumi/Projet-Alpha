#noyard
module GamePlay
  class StorageRemove < Base
    RET = "Retirer"
    INF = "Résumé"
    REL = "Relâcher"
    QTT = "Quitter"
    def initialize
      @utils = StorageUtils.new
      @index = 1
      @utils.draw_selector(@index)
      @running = true
    end

    def update
      @utils.update
      return if $game_temp.message_text
      if (Input.trigger?(:B))
        c = @utils.display_message("Rester sur cet écran ?", 2, *["Oui", "Non"])
        if (c == 1)
          @running = false
          $game_switches[26] = true
        end
      end
      if (@index == 0) # Changement de boîte
        @index = @utils.changer_boite(@index)
      else # Déplacement dans la boîte
        @index = @utils.deplacement_boite(@index, :remove)
        if (Input.trigger?(:A))
          return if (!$storage.isPokemon?(@index - 1))
          choice
        end
      end
    end

    def choice
      arr = Array.new
      arr.push(RET, INF, REL, QTT)
      ind = @utils._party_window(*arr)
      if (ind == 0)
        remove_pokemon
      elsif (ind == 1)
        @utils.sumary_pokemon(@index)
      elsif (ind == 2)
        @utils.release_pokemon(@index) if $pokemon_party.actors.size > 0
      end
    end

    def remove_pokemon
      if ($pokemon_party.actors.size > 5)
        @utils.display_message("Votre équipe est déjà au complet !", 1)
        return
      end
      pokemon = $storage.remove(@index - 1)
      $pokemon_party.actors.push(pokemon)
      @utils.draw_init
      @utils.draw_info_pokemon(@index)
    end

    def dispose
      @utils.dispose
    end
  end
end