#encoding: utf-8

module PFM
  # The wild battle management
  # 
  # The main object is stored in $wild_battle and $pokemon_party.wild_battle
  # @author Nuri Yuri
  class Wild_Battle
    # The number of zone type that can be stored
    MAX_Zone = 9
    # List of Roaming Pokemon
    # @return [Array<PFM::Wild_RoamingInfo>]
    attr_reader :roaming_pokemons
    # List of Remaining Pokemon groups
    # @return [Array<Array<PFM::Wild_Info>>]
    attr_reader :remaining_pokemons
    # The fish group information
    # @return [Hash]
    attr_reader :fishing
    # The actual code to determine if the group should be realoaded (Time change)
    # @return [Integer]
    attr_reader :code
    # Create a new Wild_Battle manager
    def initialize
      #>Initilisation des fuyards
      @roaming_pokemons = Array.new
      #>Initialisation des Pokémons rencontrable dans les herbes
      #[ (grass)[(tag 0)Wild_info, (tag1)Wild_info,...], (tall_grass)[...], ...]
      @remaining_pokemons = Array.new(MAX_Zone) { Array.new }
      #>Informations de déclanchement du combat (Si c'est un combat normal ou forcé)
      @forced_wild_battle = false
      #>Information des pokémon par pêche :normal => [] par canne, :super => [] par super, :mega => par mega canne
      @fishing = {}
      #>Code indiquant l'infomation de la génération actuelle
      @code = 0
    end
    # Reset the wild battle
    def reset
      i = nil
      @remaining_pokemons.each do |i|
        i.clear
      end
      @roaming_pokemons.each do |i|
        i.update
      end
      @roaming_pokemons.delete_if { |i| i.pokemon.dead? }
      #@forced_wild_battle=false
      @fishing.clear
      @fishing[:normal] = Array.new
      @fishing[:super] = Array.new
      @fishing[:mega] = Array.new
      @fishing[:rock] = Array.new
      @fishing[:headbutt] = Array.new
      @fished = false
      @fish_battle = nil
    end
    # Load the groups of Wild Pokemon (map change/ time change)
    def load_groups
      groups = $env.get_current_zone_data.groups
      @code = groups.size
      sw = nil
      if groups
        groups.each do |group|
          map_id = group.instance_variable_get(:@map_id)
          if(!map_id or $game_map.map_id == map_id)
            sw = group.instance_variable_get(:@enable_switch)
            set(*group) if !sw or $game_switches[sw]
            @code = (@code * 2 + sw) if sw and $game_switches[sw]
          end
        end
      end
    end
    # Set the battle up with the right parameter
    # @note Must be called in Scene_Battle as the current $scene
    def setup
      return if($scene.class!=Scene_Battle)
      #>Si c'est un combat provoqué
      if(@forced_wild_battle)
        $scene.enemy_party.actors.clear
        $scene.enemy_party.actors=@forced_wild_battle
        $scene.setup_battle(@forced_wild_battle.size,1,1)
        @forced_wild_battle=false
        return
      end
      wi = @fish_battle ? @fish_battle : @remaining_pokemons[$env.get_zone_type][$game_player.terrain_tag]
      return unless wi
      troop=$data_troops[1].members
      wi.ids.each_index do |i|
        troop[i]=RPG::Troop::Member.new unless troop[i]
        troop[i].enemy_id=wi.ids[i]
      end
      $scene.setup_battle(wi.vs_type,1,1)
      $scene.configure_pokemons(*wi.levels)
      $scene.select_pokemon(*wi.chances)
      $scene.fished = (@fish_battle ? @fished : false)
      @fish_battle = nil
    end
    # List of ability that force strong Pokemon to battle (Intimidation / Regard vif)
    WeakPokemonAbility = %i[intimidate keen_eye]
    # Is a wild battle available ?
    # @return [Boolean]
    def available?
      return false if($scene.is_a?(Scene_Battle))
      return true if @fish_battle
      #> Vérification des fuyards :
      roaming_info = nil
      @roaming_pokemons.each do |roaming_info|
        if roaming_info.appearing?
          init_battle(roaming_info.pokemon)
          return true
        end
      end
      #> Vérification des pokémon normaux
      @forced_wild_battle=false
      var = @remaining_pokemons[$env.get_zone_type]
      return false unless var
      return false unless $actors[0]
      if var[$game_player.terrain_tag].class==Wild_Info
        var = var[$game_player.terrain_tag]
        level = nil
        if(WeakPokemonAbility.include?($actors[0].ability_db_symbol))
          var.levels.each do |i|
            level = (i.is_a?(Integer) ? i : i[:level])
            return true if (level+5) >= $actors[0].level
          end
          return rand(100) < 50
        end
        return true
      end
      return false
    end
    # Test if there's any fish battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :norma, :super, :mega
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_fish?(rod = :normal, start = false)
      st = $game_player.front_system_tag
      zone_type = (st == 399 ? 6 : (st == 405 ? 7 : 0))
      if($env.can_fish? and @fishing[rod] and @fishing[rod][zone_type])
        if(start)
          @fish_battle = @fishing[rod][zone_type]
          if rod == :normal or rod == :super or rod == :mega
            @fished = true
          else
            @fished = false
          end
        else
          return true
        end
      else
        return false
      end
      return nil
    end
    # Test if there's any hidden battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :rock, :headbutt
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_hidden_pokemon?(rod = :rock, start = false)
      zone_type = $env.convert_zone_type($game_player.front_system_tag)
      if(@fishing[rod] and @fishing[rod][zone_type])
        if(start)
          @fish_battle = @fishing[rod][zone_type]
          @fished = false
        else
          return true
        end
      else
        return false
      end
      return nil
    end
    # Start a wild battle
    # @note call the common event 1 to start the battle
    # @overload start_battle(id, level, *args)
    #   @param id [PFM::Pokemon] First Pokemon in the wild battle.
    #   @param level [Object] ignored
    #   @param args [Array<PFM::Pokemon>] other pokemon in the wild battle.
    # @overload start_battle(id, level, *args)
    #   @param id [Integer] id of the Pokemon in the database
    #   @param level [Integer] level of the first Pokemon
    #   @param args [Array<Integer, Integer>] array of id, level of the other Pokemon in the wild battle.
    def start_battle(id, level = 70, *others)
      init_battle(id, level, *others)
      $game_system.map_interpreter.launch_common_event(1)
    end
    # Init a wild battle
    # @note Does not start the battle
    # @overload init_battle(id, level, *args)
    #   @param id [PFM::Pokemon] First Pokemon in the wild battle.
    #   @param level [Object] ignored
    #   @param args [Array<PFM::Pokemon>] other pokemon in the wild battle.
    # @overload init_battle(id, level, *args)
    #   @param id [Integer] id of the Pokemon in the database
    #   @param level [Integer] level of the first Pokemon
    #   @param args [Array<Integer, Integer>] array of id, level of the other Pokemon in the wild battle.
    def init_battle(id, level = 70, *others)
      if(id.class == PFM::Pokemon)
        @forced_wild_battle = [id, *others]
      else
        id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
        @forced_wild_battle = [PFM::Pokemon.new(id, level)]
        0.step(others.size-1,2) do |i|
          others[i] = GameData::Pokemon.get_id(others[i]) if others[i].is_a?(Symbol)
          @forced_wild_battle << PFM::Pokemon.new(others[i], others[i+1])
        end
      end
    end
    # Define a group of remaining wild battle
    # @param zone_type [Integer] type of the zone, see $env.get_zone_type to know the id
    # @param tag [Integer] terrain_tag on which the player should be to start a battle with wild Pokemon of this group
    # @param delta_level [Integer] the disparity of the Pokemon levels
    # @param vs_type [Integer] the vs_type the Wild Battle are
    # @param data [Array<Integer, Integer, Integer>, Array<Integer, Hash, Integer>] Array of id, level/informations, chance to see (Pokemon informations)
    def set(zone_type, tag, delta_level, vs_type, *data)
      return if MAX_Zone<=zone_type
      wi=Wild_Info.new
      wi.delta_level=delta_level
      ids=wi.ids
      levels=wi.levels
      chances=wi.chances
      wi.vs_type=vs_type
      if((data.size/3*3)!=data.size)
        raise ArgumentError, "Wild Pokémon aren't correctly configured"
      end
      0.step(data.size-1,3) do |i|
        j=i/3
        ids[j]=data[i]
        levels[j]=data[i+1]
        chances[j+1]=data[i+2]
      end
      if(tag < 8)
        @remaining_pokemons[zone_type][tag] = wi
      elsif(tag < 11)
        @fishing[tag == 8 ? :normal : tag == 9 ? :super : :mega][zone_type] = wi
      else
        @fishing[tag == 11 ? :rock : :headbutt][zone_type] = wi
      end
    end
    # Test if a Pokemon is a roaming Pokemon (Usefull in battle)
    def is_roaming?(pokemon)
      roaming_info = nil
      @roaming_pokemons.each do |roaming_info|
        return true if roaming_info.pokemon == pokemon
      end
      return false
    end
    # Add a roaming Pokemon
    # @param chance [Integer] the chance divider to see the Pokemon
    # @param proc_id [Integer] ID of the Wild_RoamingInfo::RoamingProcs
    # @param pokemon_hash [Hash] the Hash that help the generation of the Pokemon, see PFM::Pokemon#generate_from_hash
    # @return [PFM::Pokemon] the generated roaming Pokemon
    def add_roaming_pokemon(chance, proc_id, pokemon_hash)
      pokemon = ::PFM::Pokemon.generate_from_hash(pokemon_hash)
      @roaming_pokemons << Wild_RoamingInfo.new(pokemon, chance, proc_id)
      @code += 1
      return pokemon
    end
    # Remove a roaming Pokemon from the roaming Pokemon array
    # @param pokemon [PFM::Pokemon] the Pokemon that should be removed
    def remove_roaming_pokemon(pokemon)
      @roaming_pokemons.delete_if { |i| i.pokemon == pokemon }
    end
    # Ability that increase the rate of any fishing rod # Glue / Ventouse
    FishIncRate = %i[sticky_hold suction_cups]
    # Check if a Pokemon can be fished there with a specific fishing rod type
    # @param type [Symbol] :mega, :super, :normal
    # @return [Boolean]
    def check_fishing_chances(type)
      case type
      when :mega
        rate = 60
      when :super
        rate = 45
      else
        rate = 30
      end
      rate *= 1.5 if FishIncRate.include?($actors[0] ? $actors[0].ability_db_symbol : -1)
      return rate < rand(100)
    end
    # yield a block on every available roaming Pokemon
    def each_roaming_pokemon
      @roaming_pokemons.each do |roaming_info|
        yield(roaming_info.pokemon)
      end
    end
  end
end