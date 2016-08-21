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
        @updateValues()
        @updateTreasureBox()
        @updateMinionBox()
        @updateMonsterBox()
        @updateAcolyteBox()
        @updateReputationBox()


    updateValues: =>
        @roomProgress += @minions * @devMultiplier
        if @roomProgress >= @roomCost()
            @roomProgress -= @roomCost()
            @rooms += 1

        @reputation += @acolytes * @devMultiplier


        for i in [0,Math.floor(@treasure*@devMultiplier)]
            adventurerRoll = Math.floor((Math.random() * 6000) + 1)
            if adventurerRoll == 6000
                @adventurers+=1
                @treasure+=1

    updateReputationBox: =>
        $('#reputationCount').text @reputation
        $('#reputationRate').text @acolytes*100

    updateMinionBox: =>
        $('#minionCount').text @minions
        $('#buyAllMinions').text "Buy All (#{@maxNumberToBuy @cost})"

        roomProgressPercent = (@roomProgress/@roomCost()*100).toString()
        $('#roomCount').text @rooms
        @updateProgressBar($('#roomBar'), roomProgressPercent)

        @setRoomETA()

    updateMonsterBox: =>
        $('#monsterCount').text @monsters
        $('#buyAllMonsters').text "Buy All (#{@maxNumberToBuy @cost})"

    updateAcolyteBox: =>
        $('#acolyteCount').text @acolytes
        $('#acolyteReputationRate').text @acolytes*100
        $('#buyAllAcolytes').text "Buy All (#{@maxNumberToBuy @cost})"

    updateTreasureBox: =>
        $('#adventurerCount').text @adventurers
        $('#treasureCount').text @treasure

    setRoomETA: =>
        remaining = @roomCost() - @roomProgress
        rate = @minions * @devMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*10) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()} years " if duration.years() > 0
        specific += "#{duration.months()} months " if duration.months() > 0
        specific += "#{duration.days()} days " if duration.days() > 0
        specific += "#{duration.hours()} hours " if duration.hours() > 0
        specific += "#{duration.minutes()} minutes " if duration.minutes() > 0
        specific += "#{duration.seconds()} seconds " if duration.seconds() > 0

        $('#roomETA').text specific

    updateProgressBar: (bar, percent) ->
      bar.width("#{percent}%")

    roomCost: =>
        costToBuild = 2916000
        if @rooms >= 100
            costToBuild = 1247114880
        else if @rooms >= 30
            costToBuild = 1247114880
        else if @rooms >= 20
            costToBuild = 1247114880
        else if @rooms >= 5
            costToBuild = 56687040
        return costToBuild

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

