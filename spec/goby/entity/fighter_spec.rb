require 'goby'

RSpec.describe Fighter do

  let!(:empty_fighter) { Class.new { extend Fighter } }
  let(:fighter_class) {
    Class.new(Entity) do
      include Fighter
      def initialize(name: "Fighter", stats: {}, inventory: [], gold: 0, battle_commands: [], outfit: [])
        super(name: name, stats: stats, inventory: inventory, gold: gold, outfit: outfit)
        add_battle_commands(battle_commands)
      end
    end
  }
  let(:fighter) { fighter_class.new }

  context "fighter" do
    it "is a fighter" do
      expect(fighter.class.included_modules.include?(Fighter)).to be true
    end
  end

  context "placeholder methods" do
    it "forces :die to be implemented" do
      expect { empty_fighter.die }.to raise_error(NotImplementedError, 'A Fighter must know how to die.')
    end

    it "forces :handle_victory to be implemented" do
      expect { empty_fighter.handle_victory(fighter) }.to raise_error(NotImplementedError, 'A Fighter must know how to handle victory.')
    end

    it "forces :sample_treasures to be implemented" do
      expect { empty_fighter.sample_treasures }.to raise_error(NotImplementedError, 'A Fighter must know whether it returns treasure or not after losing a battle.')
    end

    it "forces :sample_gold to be implemented" do
      expect { empty_fighter.sample_gold }.to raise_error(NotImplementedError, 'A Fighter must return some gold after losing a battle.')
    end
  end

  context "add battle command" do
    it "properly adds the command in a trivial case" do
      fighter.add_battle_command(BattleCommand.new)
      expect(fighter.battle_commands.length).to eq 1
      expect(fighter.battle_commands).to eq [BattleCommand.new]
    end

    it "maintains the sorted invariant for a more complex case" do
      fighter.add_battle_command(BattleCommand.new(name: "Kick"))
      fighter.add_battle_command(BattleCommand.new(name: "Chop"))
      fighter.add_battle_command(BattleCommand.new(name: "Grab"))
      expect(fighter.battle_commands.length).to eq 3
      expect(fighter.battle_commands).to eq [
                                                BattleCommand.new(name: "Chop"),
                                                BattleCommand.new(name: "Grab"),
                                                BattleCommand.new(name: "Kick")]
    end
  end

  context "battle" do
    it "raises an error when starting a battle against a non-Fighter Entity" do
      expect {empty_fighter.battle(Class.new)}.to raise_error(Fighter::UnfightableException,
                                                              "You can't start a battle with an Entity of type Class as it doesn't implement the Fighter module")
    end
  end

  context "choose attack" do
    it "randomly selects one of the available commands" do
      kick = BattleCommand.new(name: "Kick")
      zap = BattleCommand.new(name: "Zap")
      entity = fighter_class.new(battle_commands: [kick, zap])
      attack = entity.choose_attack
      expect(attack.name).to eq("Kick").or(eq("Zap"))
    end
  end

  context "choose item and on whom" do
    it "randomly selects both item and on whom" do
      banana = Item.new(name: "Banana")
      axe = Item.new(name: "Axe")

      entity = fighter_class.new(inventory: [C[banana, 1],
                                             C[axe, 3]])
      enemy = fighter_class.new(name: "Enemy")

      pair = entity.choose_item_and_on_whom(enemy)
      expect(pair.first.name).to eq("Banana").or(eq("Axe"))
      expect(pair.second.name).to eq("Fighter").or(eq("Enemy"))
    end
  end

  context "equip item" do
    it "correctly equips the weapon and alters the stats of a Fighter Entity" do
      entity = fighter_class.new(inventory: [C[
                                                 Weapon.new(stat_change: {attack: 3},
                                                            attack: Attack.new), 1]])
      entity.equip_item("Weapon")
      expect(entity.outfit[:weapon]).to eq Weapon.new
      expect(entity.stats[:attack]).to eq 4
      expect(entity.battle_commands).to eq [Attack.new]
    end

    it "correctly switches the equipped items and alters status of a Fighter Entity as appropriate" do
      entity = fighter_class.new(inventory: [C[
                                                 Weapon.new(name: "Hammer",
                                                            stat_change: {attack: 3,
                                                                          defense: 2,
                                                                          agility: 4},
                                                            attack: Attack.new(name: "Bash")), 1],
                                             C[
                                                 Weapon.new(name: "Knife",
                                                            stat_change: {attack: 5,
                                                                          defense: 3,
                                                                          agility: 7},
                                                            attack: Attack.new(name: "Stab")), 1]])
      entity.equip_item("Hammer")
      stats = entity.stats
      expect(stats[:attack]).to eq 4
      expect(stats[:defense]).to eq 3
      expect(stats[:agility]).to eq 5
      expect(entity.outfit[:weapon].name).to eq "Hammer"
      expect(entity.battle_commands).to eq [Attack.new(name: "Bash")]
      expect(entity.find_item('Hammer')).to be_nil
      expect(entity.find_item('Knife')).not_to be_nil

      entity.equip_item("Knife")
      stats = entity.stats
      expect(stats[:attack]).to eq 6
      expect(stats[:defense]).to eq 4
      expect(stats[:agility]).to eq 8
      expect(entity.outfit[:weapon].name).to eq "Knife"
      expect(entity.battle_commands).to eq [Attack.new(name: "Stab")]
      expect(entity.find_item('Knife')).to be_nil
      expect(entity.find_item('Hammer')).not_to be_nil
    end
  end

  context "has battle command" do
    it "correctly indicates an absent command for an object argument" do
      entity = fighter_class.new(battle_commands: [
                                     BattleCommand.new(name: "Kick"),
                                     BattleCommand.new(name: "Poke")])
      index = entity.find_battle_command(BattleCommand.new(name: "Chop"))
      expect(index).to be_nil
    end

    it "correctly indicates a present command for an object argument" do
      entity = fighter_class.new(battle_commands: [
                                     BattleCommand.new(name: "Kick"),
                                     BattleCommand.new(name: "Poke")])
      index = entity.find_battle_command(BattleCommand.new(name: "Poke"))
      expect(index).to eq BattleCommand.new(name: "Poke")
    end

    it "correctly indicates an absent command for a string argument" do
      entity = fighter_class.new(battle_commands: [
                                     BattleCommand.new(name: "Kick"),
                                     BattleCommand.new(name: "Poke")])
      index = entity.find_battle_command("Chop")
      expect(index).to be_nil
    end

    it "correctly indicates a present command for a string argument" do
      entity = fighter_class.new(battle_commands: [
                                     BattleCommand.new(name: "Kick"),
                                     BattleCommand.new(name: "Poke")])
      index = entity.find_battle_command("Poke")
      expect(index).to eq BattleCommand.new(name: "Poke")
    end
  end

  context "print battle commands" do
    it "should print only the default header when there are no battle commands" do
      expect { fighter.print_battle_commands }.to output("Battle Commands:\n\n").to_stdout
    end

    it "should print the custom header when one is passed" do
      expect { fighter.print_battle_commands("Choose an attack:") }.to output("Choose an attack:\n\n").to_stdout
    end

    it "should print each battle command in a list" do
      kick = Attack.new(name: "Kick")
      entity = fighter_class.new(battle_commands: [kick, Use.new, Escape.new])
      expect { entity.print_battle_commands }.to output(
                                                     "Battle Commands:\n❊ Escape\n❊ Kick\n❊ Use\n\n"
                                                 ).to_stdout
    end
  end

  context "print status" do
    it "prints all of the entity's information without battle commands" do
      entity = fighter_class.new(stats: {max_hp: 50,
                                         hp: 30,
                                         attack: 5,
                                         defense: 3,
                                         agility: 4},
                                 outfit: [Helmet.new, Legs.new, Shield.new, Torso.new, Weapon.new])
      expect { entity.print_status }.to output(
                                            "Stats:\n* HP: 30/50\n* Attack: 5\n* Defense: 3\n* Agility: 4\n\n"\
        "Equipment:\n* Weapon: Weapon\n* Shield: Shield\n* Helmet: Helmet\n"\
        "* Torso: Torso\n* Legs: Legs\n\n"
                                        ).to_stdout
    end

    it "prints all of the entity's information including battle commands" do
      entity = fighter_class.new(stats: {max_hp: 50,
                                         hp: 30,
                                         attack: 5,
                                         defense: 3,
                                         agility: 4},
                                 outfit: [Helmet.new, Legs.new, Shield.new, Torso.new, Weapon.new],
                                 battle_commands: [Escape.new])
      expect { entity.print_status }.to output(
                                            "Stats:\n* HP: 30/50\n* Attack: 5\n* Defense: 3\n* Agility: 4\n\n"\
        "Equipment:\n* Weapon: Weapon\n* Shield: Shield\n* Helmet: Helmet\n"\
        "* Torso: Torso\n* Legs: Legs\n\nBattle Commands:\n❊ Escape\n\n"
                                        ).to_stdout
    end
  end

  context "remove battle command" do
    it "has no effect when no such command is present" do
      fighter.add_battle_command(Attack.new(name: "Kick"))
      fighter.remove_battle_command(BattleCommand.new(name: "Poke"))
      expect(fighter.battle_commands.length).to eq 1
    end

    it "correctly removes the command in the trivial case" do
      fighter.add_battle_command(Attack.new(name: "Kick"))
      fighter.remove_battle_command(Attack.new(name: "Kick"))
      expect(fighter.battle_commands.length).to eq 0
    end
  end

end
