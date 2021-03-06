require 'goby'

RSpec.describe Goby::Attack do

  let!(:user) { Player.new(stats: { max_hp: 50, attack: 6, defense: 4 }) }
  let!(:enemy) { Monster.new(stats: { max_hp: 30, attack: 3, defense: 2 }) }
  let(:attack) { Attack.new(strength: 5) }
  let(:cry) { Attack.new(name: "Cry", success_rate: 0) }

  context "constructor" do
    it "has the correct default parameters" do
      attack = Attack.new
      expect(attack.name).to eq "Attack"
      expect(attack.strength).to eq 1
      expect(attack.success_rate).to eq 100
    end

    it "correctly assigns all custom parameters" do
      poke = Attack.new(name: "Poke",
                        strength: 12,
                        success_rate: 95)
      expect(poke.name).to eq "Poke"
      expect(poke.strength).to eq 12
      expect(poke.success_rate).to eq 95
    end

    it "correctly assigns only one custom parameter" do
      attack = Attack.new(success_rate: 77)
      expect(attack.name).to eq "Attack"
      expect(attack.strength).to eq 1
      expect(attack.success_rate).to eq 77
    end
  end

  context "equality operator" do
    it "returns true for the seemingly trivial case" do
      expect(Attack.new).to eq Attack.new
    end

    it "returns false for commands with different names" do
      poke = Attack.new(name: "Poke")
      kick = Attack.new(name: "Kick")
      expect(poke).not_to eq kick
    end
  end

  context "run" do
    it "does the appropriate amount of damage for attack > defense" do
      attack.run(user, enemy)
      expect(enemy.stats[:hp]).to be_between(21, 24)
    end

    it "prevents the enemy's HP from falling below 0" do
      user.set_stats(attack: 200)
      attack.run(user, enemy)
      expect(enemy.stats[:hp]).to be_zero
    end

    it "does the appropriate amount of damage for defense > attack" do
      attack.run(enemy, user)
      expect(user.stats[:hp]).to be_between(45, 46)
    end

    it "does no damage when the defense is very high" do
      enemy.set_stats(defense: 100)
      attack.run(user, enemy)
      expect(enemy.stats[:hp]).to eq 30
    end

    it "prints an appropriate message for a failed attack" do
      expect { cry.run(user, enemy) }.to output(
        "Player tries to use Cry, but it fails.\n\n"
      ).to_stdout
    end
  end
end
