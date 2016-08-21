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
      this.roomCost = __bind(this.roomCost, this);
      this.setRoomETA = __bind(this.setRoomETA, this);
      this.updateTreasureBox = __bind(this.updateTreasureBox, this);
      this.updateAcolyteBox = __bind(this.updateAcolyteBox, this);
      this.updateMonsterBox = __bind(this.updateMonsterBox, this);
      this.updateMinionBox = __bind(this.updateMinionBox, this);
      this.updateReputationBox = __bind(this.updateReputationBox, this);
      this.updateValues = __bind(this.updateValues, this);
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
      this.updateValues();
      this.updateTreasureBox();
      this.updateMinionBox();
      this.updateMonsterBox();
      this.updateAcolyteBox();
      return this.updateReputationBox();
    };

    Dungeon.prototype.updateValues = function() {
      var adventurerRoll, i, _i, _len, _ref, _results;
      this.roomProgress += this.minions * this.devMultiplier;
      if (this.roomProgress >= this.roomCost()) {
        this.roomProgress -= this.roomCost();
        this.rooms += 1;
      }
      this.reputation += this.acolytes * this.devMultiplier;
      _ref = [0, Math.floor(this.treasure * this.devMultiplier)];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        adventurerRoll = Math.floor((Math.random() * 6000) + 1);
        if (adventurerRoll === 6000) {
          this.adventurers += 1;
          _results.push(this.treasure += 1);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Dungeon.prototype.updateReputationBox = function() {
      $('#reputationCount').text(this.reputation);
      return $('#reputationRate').text(this.acolytes * 100);
    };

    Dungeon.prototype.updateMinionBox = function() {
      var roomProgressPercent;
      $('#minionCount').text(this.minions);
      $('#buyAllMinions').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
      roomProgressPercent = (this.roomProgress / this.roomCost() * 100).toString();
      $('#roomCount').text(this.rooms);
      this.updateProgressBar($('#roomBar'), roomProgressPercent);
      return this.setRoomETA();
    };

    Dungeon.prototype.updateMonsterBox = function() {
      $('#monsterCount').text(this.monsters);
      return $('#buyAllMonsters').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
    };

    Dungeon.prototype.updateAcolyteBox = function() {
      $('#acolyteCount').text(this.acolytes);
      $('#acolyteReputationRate').text(this.acolytes * 100);
      return $('#buyAllAcolytes').text("Buy All (" + (this.maxNumberToBuy(this.cost)) + ")");
    };

    Dungeon.prototype.updateTreasureBox = function() {
      $('#adventurerCount').text(this.adventurers);
      return $('#treasureCount').text(this.treasure);
    };

    Dungeon.prototype.setRoomETA = function() {
      var duration, eta, moment_time, rate, remaining, specific;
      remaining = this.roomCost() - this.roomProgress;
      rate = this.minions * this.devMultiplier;
      eta = Math.floor(remaining / rate);
      duration = moment.duration(eta * 10);
      moment_time = duration.humanize();
      specific = "";
      if (duration.years() > 0) {
        specific += "" + (duration.years()) + " years ";
      }
      if (duration.months() > 0) {
        specific += "" + (duration.months()) + " months ";
      }
      if (duration.days() > 0) {
        specific += "" + (duration.days()) + " days ";
      }
      if (duration.hours() > 0) {
        specific += "" + (duration.hours()) + " hours ";
      }
      if (duration.minutes() > 0) {
        specific += "" + (duration.minutes()) + " minutes ";
      }
      if (duration.seconds() > 0) {
        specific += "" + (duration.seconds()) + " seconds ";
      }
      return $('#roomETA').text(specific);
    };

    Dungeon.prototype.updateProgressBar = function(bar, percent) {
      return bar.width("" + percent + "%");
    };

    Dungeon.prototype.roomCost = function() {
      var costToBuild;
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
      return costToBuild;
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
