$(document).ready ->
    simulator.initialize()
    setInterval(simulator.tick,10)

simulator =
    initialize: ->
        simulator.minions = 1
        simulator.monsters = 1
        simulator.acolytes = 10
        simulator.treasure = 1
        
        simulator.roomProgress = 0
        simulator.rooms = 0
        simulator.adventurers = 0
        simulator.reputation = 0
        simulator.devMultiplier = 1
        document.getElementById('buyMinion').addEventListener 'click', simulator.buyMinion
        document.getElementById('buyMonster').addEventListener 'click', simulator.buyMonster
        document.getElementById('buyAcolyte').addEventListener 'click', simulator.buyAcolyte
        document.getElementById('buyAllMinions').addEventListener 'click', simulator.buyAllMinions
        document.getElementById('buyAllMonsters').addEventListener 'click', simulator.buyAllMonsters
        document.getElementById('buyAllAcolytes').addEventListener 'click', simulator.buyAllAcolytes
    tick: ->
        simulator.roomProgress += simulator.minions * simulator.devMultiplier
        costToBuild = 2916000
        if simulator.rooms >= 100
            costToBuild = 1247114880
        else if simulator.rooms >= 30
            costToBuild = 1247114880
        else if simulator.rooms >= 20
            costToBuild = 1247114880
        else if simulator.rooms >= 5
            costToBuild = 56687040
        if simulator.roomProgress >= costToBuild
            simulator.roomProgress = 0
            simulator.rooms += 1
        roomProgressPercent = Math.floor((simulator.roomProgress/costToBuild*100)).toString()
        document.getElementById('roomProgress').innerHTML="Room Progress: "+roomProgressPercent+"%"
        document.getElementById('rooms').innerHTML="Rooms: "+simulator.rooms.toString()
        for i in [0,Math.floor(simulator.treasure*simulator.devMultiplier)]
            adventurerRoll = Math.floor((Math.random() * 6000) + 1)
            if adventurerRoll == 6000
                simulator.adventurers+=1
                simulator.treasure+=1
        document.getElementById('adventurers').innerHTML="Adventurers: "+simulator.adventurers.toString()
        document.getElementById('treasure').innerHTML="Treasure: "+simulator.treasure.toString()
        simulator.reputation += simulator.acolytes * simulator.devMultiplier
        document.getElementById('minions').innerHTML="Minions: "+simulator.minions.toString()
        document.getElementById('monsters').innerHTML="Monsters: "+simulator.monsters.toString()
        document.getElementById('acolytes').innerHTML="Acolytes: "+simulator.acolytes.toString()
        document.getElementById('reputation').innerHTML="Reputation: "+simulator.reputation.toString()
    buyMinion: ->
        if (simulator.reputation>30000)
            simulator.reputation -= 30000
            simulator.minions += 1
    buyMonster: ->
        if (simulator.reputation>30000)
            simulator.reputation -= 30000
            simulator.monsters += 1
    buyAcolyte: ->
        if (simulator.reputation>30000)
            simulator.reputation -= 30000
            simulator.acolytes += 1
    buyAllMinions: ->
        while (simulator.reputation>=30000)
            simulator.reputation -= 30000
            simulator.minions += 1
    buyAllMonsters: ->
        while (simulator.reputation>=30000)
            simulator.reputation -= 30000
            simulator.monsters += 1
    buyAllAcolytes: ->
        while (simulator.reputation>=30000)
            simulator.reputation -= 30000
            simulator.acolytes += 1
            