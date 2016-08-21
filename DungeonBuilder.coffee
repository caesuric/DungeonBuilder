class Dungeon
    constructor: ->
        @minions = 1
        @monsters = 1
        @acolytes = 10
        @treasure = 1

        @roomProgress = 0
        @rooms = 0
        @adventurers = 0
        @reputation = 0
        @devMultiplier = 1

        @cost = 30000

        $('#buyMinion').on 'click', @buyMinion
        $('#buyMonster').on 'click', @buyMonster
        $('#buyAcolyte').on 'click', @buyAcolyte
        $('#buyAllMinions').on 'click', @buyAllMinions
        $('#buyAllMonsters').on 'click', @buyAllMonsters
        $('#buyAllAcolytes').on 'click', @buyAllAcolytes
    tick: =>
        @roomProgress += @minions * @devMultiplier
        costToBuild = 2916000
        if @rooms >= 100
            costToBuild = 1247114880
        else if @rooms >= 30
            costToBuild = 1247114880
        else if @rooms >= 20
            costToBuild = 1247114880
        else if @rooms >= 5
            costToBuild = 56687040
        if @roomProgress >= costToBuild
            @roomProgress = 0
            @rooms += 1
        roomProgressPercent = Math.floor((@roomProgress/costToBuild*100)).toString()
        $('#roomProgressCount').text "#{roomProgressPercent}%"
        $('#roomCount').text @rooms
        for i in [0,Math.floor(@treasure*@devMultiplier)]
            adventurerRoll = Math.floor((Math.random() * 6000) + 1)
            if adventurerRoll == 6000
                @adventurers+=1
                @treasure+=1
        $('#adventurerCount').text @adventurers
        $('#treasureCount').text @treasure
        @reputation += @acolytes * @devMultiplier
        $('#minionCount').text @minions
        $('#monsterCount').text @monsters
        $('#acolyteCount').text @acolytes
        $('#reputationCount').text @reputation
        $('#buyAllMinions').text "Buy All (#{@maxNumberToBuy @cost})"
        $('#buyAllMonsters').text "Buy All (#{@maxNumberToBuy @cost})"
        $('#buyAllAcolytes').text "Buy All (#{@maxNumberToBuy @cost})"

    maxNumberToBuy: (cost) =>
      Math.floor(@reputation/cost)
    buyMinion: =>
        if (@reputation>30000)
            @reputation -= 30000
            @minions += 1
    buyMonster: =>
        if (@reputation>30000)
            @reputation -= 30000
            @monsters += 1
    buyAcolyte: =>
        if (@reputation>30000)
            @reputation -= 30000
            @acolytes += 1
    buyAllMinions: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        @minions += number
    buyAllMonsters: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        @monsters += number
    buyAllAcolytes: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        @acolytes += number

$(document).ready ->
    simulator = new Dungeon
    setInterval(simulator.tick,10)
    # setInterval(simulator.tick,1000)

