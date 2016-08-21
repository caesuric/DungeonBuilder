// Generated by CoffeeScript 1.10.0
(function() {
  var simulator;

  $(document).ready(function() {
    simulator.initialize();
    return setInterval(simulator.tick, 10);
  });

  simulator = {
    initialize: function() {
      simulator.minions = 1;
      simulator.monsters = 1;
      simulator.acolytes = 10;
      simulator.treasure = 1;
      simulator.roomProgress = 0;
      simulator.rooms = 0;
      simulator.adventurers = 0;
      simulator.reputation = 0;
      simulator.devMultiplier = 1;
      document.getElementById('buyMinion').addEventListener('click', simulator.buyMinion);
      document.getElementById('buyMonster').addEventListener('click', simulator.buyMonster);
      document.getElementById('buyAcolyte').addEventListener('click', simulator.buyAcolyte);
      document.getElementById('buyAllMinions').addEventListener('click', simulator.buyAllMinions);
      document.getElementById('buyAllMonsters').addEventListener('click', simulator.buyAllMonsters);
      return document.getElementById('buyAllAcolytes').addEventListener('click', simulator.buyAllAcolytes);
    },
    tick: function() {
      var adventurerRoll, costToBuild, i, j, len, ref, roomProgressPercent;
      simulator.roomProgress += simulator.minions * simulator.devMultiplier;
      costToBuild = 2916000;
      if (simulator.rooms >= 100) {
        costToBuild = 1247114880;
      } else if (simulator.rooms >= 30) {
        costToBuild = 1247114880;
      } else if (simulator.rooms >= 20) {
        costToBuild = 1247114880;
      } else if (simulator.rooms >= 5) {
        costToBuild = 56687040;
      }
      if (simulator.roomProgress >= costToBuild) {
        simulator.roomProgress = 0;
        simulator.rooms += 1;
      }
      roomProgressPercent = Math.floor(simulator.roomProgress / costToBuild * 100).toString();
      document.getElementById('roomProgress').innerHTML = "Room Progress: " + roomProgressPercent + "%";
      document.getElementById('rooms').innerHTML = "Rooms: " + simulator.rooms.toString();
      ref = [0, Math.floor(simulator.treasure * simulator.devMultiplier)];
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        adventurerRoll = Math.floor((Math.random() * 6000) + 1);
        if (adventurerRoll === 6000) {
          simulator.adventurers += 1;
          simulator.treasure += 1;
        }
      }
      document.getElementById('adventurers').innerHTML = "Adventurers: " + simulator.adventurers.toString();
      document.getElementById('treasure').innerHTML = "Treasure: " + simulator.treasure.toString();
      simulator.reputation += simulator.acolytes * simulator.devMultiplier;
      document.getElementById('minions').innerHTML = "Minions: " + simulator.minions.toString();
      document.getElementById('monsters').innerHTML = "Monsters: " + simulator.monsters.toString();
      document.getElementById('acolytes').innerHTML = "Acolytes: " + simulator.acolytes.toString();
      return document.getElementById('reputation').innerHTML = "Reputation: " + simulator.reputation.toString();
    },
    buyMinion: function() {
      if (simulator.reputation > 30000) {
        simulator.reputation -= 30000;
        return simulator.minions += 1;
      }
    },
    buyMonster: function() {
      if (simulator.reputation > 30000) {
        simulator.reputation -= 30000;
        return simulator.monsters += 1;
      }
    },
    buyAcolyte: function() {
      if (simulator.reputation > 30000) {
        simulator.reputation -= 30000;
        return simulator.acolytes += 1;
      }
    },
    buyAllMinions: function() {
      var results;
      results = [];
      while (simulator.reputation >= 30000) {
        simulator.reputation -= 30000;
        results.push(simulator.minions += 1);
      }
      return results;
    },
    buyAllMonsters: function() {
      var results;
      results = [];
      while (simulator.reputation >= 30000) {
        simulator.reputation -= 30000;
        results.push(simulator.monsters += 1);
      }
      return results;
    },
    buyAllAcolytes: function() {
      var results;
      results = [];
      while (simulator.reputation >= 30000) {
        simulator.reputation -= 30000;
        results.push(simulator.acolytes += 1);
      }
      return results;
    }
  };

}).call(this);