(function() {
  var Dungeon,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Dungeon = (function() {
    function Dungeon() {
      this.buyAllAcolytes = __bind(this.buyAllAcolytes, this);
      this.buyAllMonsters = __bind(this.buyAllMonsters, this);
      this.buyAllMinions = __bind(this.buyAllMinions, this);
      this.buyAcolyte = __bind(this.buyAcolyte, this);
      this.buyMonster = __bind(this.buyMonster, this);
      this.buyMinion = __bind(this.buyMinion, this);
      this.maxNumberToBuy = __bind(this.maxNumberToBuy, this);
      this.tick = __bind(this.tick, this);
      this.minions = 1;
      this.monsters = 1;
      this.acolytes = 10;
      this.treasure = 1;
      this.roomProgress = 0;
      this.rooms = 0;
      this.adventurers = 0;
      this.reputation = 0;
      this.devMultiplier = 1;
      this.cost = 30000;
      $('#buyMinion').on('click', this.buyMinion);
      $('#buyMonster').on('click', this.buyMonster);
      $('#buyAcolyte').on('click', this.buyAcolyte);
      $('#buyAllMinions').on('click', this.buyAllMinions);
      $('#buyAllMonsters').on('click', this.buyAllMonsters);
      $('#buyAllAcolytes').on('click', this.buyAllAcolytes);
    }

    Dungeon.prototype.tick = function() {
      var adventurerRoll, costToBuild, i, roomProgressPercent, _i, _len, _ref;
      this.roomProgress += this.minions * this.devMultiplier;
      costToBuild = 2916000;
      if (this.rooms >= 100) {
        costToBuild = 1247114880;
      } else if (this.rooms >= 30) {
        costToBuild = 1247114880;
      } else if (this.rooms >= 20) {
        costToBuild = 1247114880;
      } else if (this.rooms >= 5) {
        costToBuild = 56687040;
      }
      if (this.roomProgress >= costToBuild) {
        this.roomProgress = 0;
        this.rooms += 1;
      }
      roomProgressPercent = Math.floor(this.roomProgress / costToBuild * 100).toString();
      $('#roomProgressCount').text("" + roomProgressPercent + "%");
      $('#roomCount').text(this.rooms);
      _ref = [0, Math.floor(this.treasure * this.devMultiplier)];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        adventurerRoll = Math.floor((Math.random() * 6000) + 1);
        if (adventurerRoll === 6000) {
          this.adventurers += 1;
          this.treasure += 1;
        }
      }
      $('#adventurerCount').text(this.adventurers);
      $('#treasureCount').text(this.treasure);
      this.reputation += this.acolytes * this.devMultiplier;
      $('#minionCount').text(this.minions);
      $('#monsterCount').text(this.monsters);
      $('#acolyteCount').text(this.acolytes);
      $('#reputationCount').text(this.reputation);
      $('#buyAllMinions').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
      $('#buyAllMonsters').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
      return $('#buyAllAcolytes').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
    };

    Dungeon.prototype.maxNumberToBuy = function(cost) {
      return Math.floor(this.reputation / cost);
    };

    Dungeon.prototype.buyMinion = function() {
      if (this.reputation > 30000) {
        this.reputation -= 30000;
        return this.minions += 1;
      }
    };

    Dungeon.prototype.buyMonster = function() {
      if (this.reputation > 30000) {
        this.reputation -= 30000;
        return this.monsters += 1;
      }
    };

    Dungeon.prototype.buyAcolyte = function() {
      if (this.reputation > 30000) {
        this.reputation -= 30000;
        return this.acolytes += 1;
      }
    };

    Dungeon.prototype.buyAllMinions = function() {
      var number;
      number = this.maxNumberToBuy(this.cost);
      this.reputation -= this.cost * number;
      return this.minions += number;
    };

    Dungeon.prototype.buyAllMonsters = function() {
      var number;
      number = this.maxNumberToBuy(this.cost);
      this.reputation -= this.cost * number;
      return this.monsters += number;
    };

    Dungeon.prototype.buyAllAcolytes = function() {
      var number;
      number = this.maxNumberToBuy(this.cost);
      this.reputation -= this.cost * number;
      return this.acolytes += number;
    };

    return Dungeon;

  })();

  $(document).ready(function() {
    var simulator;
    simulator = new Dungeon;
    return setInterval(simulator.tick, 10);
  });

}).call(this);
