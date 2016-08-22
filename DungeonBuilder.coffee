class Dungeon
    constructor: ->
        @minions = 5
        @monsters = 5
        @monsterObjects = []
        for i in [0..@monsters-1]
            @monsterObjects[i]=new Monster()
        @acolytes = 5
        @treasure = 10

        @roomProgress = 0
        @rooms = 5
        @adventurers = 0
        @reputation = 0
        @devMultiplier = 60

        @cost = 1500

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
        for monster in @monsterObjects
            for i in [0..@devMultiplier-1]
                monster.tick()

    updateValues: =>
        @roomProgress += @minions * @devMultiplier
        if @roomProgress >= @roomCost()
            @roomProgress -= @roomCost()
            @rooms += 1

        @reputation += @acolytes * @devMultiplier


        for i in [0..Math.floor(@treasure*@devMultiplier)-1]
            adventurerRoll = Math.floor((Math.random() * 14500) + 1)
            if adventurerRoll == 14500
                @runDungeon()

    updateReputationBox: =>
        $('#reputationCount').text @reputation
        $('#reputationRate').text @acolytes*10

    updateMinionBox: =>
        $('#minionCount').text @minions
        $('#buyAllMinions').text "Buy All (#{@maxNumberToBuy @cost})"
        $('#population').text @totalPopulation()
        $('#maxPopulation').text @maxPopulation()

        roomProgressPercent = (@roomProgress/@roomCost()*100).toString()
        $('#roomCount').text @rooms
        @updateProgressBar($('#roomBar'), roomProgressPercent)

        @setRoomETA()

    updateMonsterBox: =>
        $('#monsterCount').text @monsters
        $('#monsterActiveCount').text @monstersActive()
        $('#buyAllMonsters').text "Buy All (#{@maxNumberToBuy @cost})"

    updateAcolyteBox: =>
        $('#acolyteCount').text @acolytes
        $('#acolyteReputationRate').text @acolytes*10
        $('#buyAllAcolytes').text "Buy All (#{@maxNumberToBuy @cost})"

    updateTreasureBox: =>
        $('#adventurerCount').text @adventurers
        $('#treasureCount').text @treasure

    setRoomETA: =>
        remaining = @roomCost() - @roomProgress
        rate = @minions * @devMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
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
        costToBuild = 12240
        if @rooms >= 100
            costToBuild = 124711488
        else if @rooms >= 30
            costToBuild = 124711488
        else if @rooms >= 20
            costToBuild = 124711488
        return costToBuild
    totalPopulation: =>
        return @minions+@monsters+@acolytes
    maxPopulation: =>
        return @rooms*5
    availablePopulation: =>
        return Math.max(@maxPopulation()-@totalPopulation(),0)
    monstersActive: =>
        count = 0
        for monster in @monsterObjects
            if monster.isActive()
                count += 1
        return count
    
    maxNumberToBuy: (cost) =>
      Math.min(Math.floor(@reputation/cost),@availablePopulation())
    buyMinion: =>
        if @reputation>@cost and @totalPopulation()<@maxPopulation()
            @minions += 1
            @reputation -= @cost
    buyMonster: =>
        if @reputation>@cost and @totalPopulation()<@maxPopulation()
            @reputation -= @cost
            @monsters += 1
            @monsterObjects[@monsters-1]=new Monster()
    buyAcolyte: =>
        if @reputation>@cost and @totalPopulation()<@maxPopulation()
            @reputation -= @cost
            @acolytes += 1
    buyAllMinions: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        @minions += number
    buyAllMonsters: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        for [0..number]
            @monsters +=1
            @monsterObjects[@monsters-1]=new Monster()
        
    buyAllAcolytes: =>
        number = @maxNumberToBuy @cost
        @reputation -= @cost * number
        @acolytes += number
        
    runDungeon: =>
        @narrate('An adventurer arrives!')
        adventurer = new Adventurer()
        for monster in @monsterObjects
            @encounterMonster(adventurer,monster)
        if @treasure>1
            @treasure -= 1
            @narrate('The adventurer has successfully beaten all of your monsters! They take one of your treasures!')
        else
            @narrate('The adventurer finds nothing and leaves.')
    encounterMonster: (adventurer, monster) =>
        if monster.isActive()
            @doCombat(adventurer,monster)
            if adventurer.hp<=0
                @defeatAdventurer(monster)
                return
            else
                monster.health = 0
                @narrate('One of your monsters has been disabled by an adventurer.')
    doCombat: (adventurer, monster) =>
        turnRoll = Math.floor((Math.random() * 2) + 1)
        while adventurer.hp>0 and monster.hp>0
            if turnRoll==1
                monster.hp -= Math.floor((Math.random() * 8) + 3)
                turnRoll = 2
                if monster.hp<=0
                    monster.hp = 0
            else if turnRoll==2
                adventurer.hp -= Math.floor((Math.random() * 12) + 4 + monster.damage)
                turnRoll = 1
    defeatAdventurer: (monster) =>
        @adventurers+=1
        @treasure+=1
        monster.xp += 100
        monster.checkForLevelUp()
        @narrate('One of your monsters has slain the adventurer! You take their treasure!')
    narrate: (text) =>
        document.getElementById('narrationContainer').innerHTML+='<br>'+text
        document.getElementById('narrationContainer').scrollTop = document.getElementById('narrationContainer').scrollHeight

class Monster
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @hp = 15
        @maxHp = 15
        @xp = 0
        @level = 1
        @damage = 0
    isActive: ->
        return (@health==@maxHealth)
    tick: ->
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                window.simulator.narrate('One of your monsters has recovered.')
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 160) + 1)
            if roll==160
                @hp += 1
    checkForLevelUp: ->
        xpTable = [300,900,2700,6500,14000,23000,34000,48000,64000,85000,100000,120000,140000,165000,195000,225000,265000,305000,355000]
        level = 1
        for tier in xpTable
            if @xp > tier
                level += 1
            else
                break
        if level > @level
            while level > @level
                @levelUp()
    levelUp: ->
        @level += 1
        window.simulator.narrate('One of your monsters has attained level '+@level.toString()+'!')
        @hp += 7
        @maxHp += 7
        @damage += 1
class Adventurer
    constructor: ->
        @hp = 13

$ ->
    window.simulator = new Dungeon
    setInterval(window.simulator.tick,100)
    # setInterval(simulator.tick,1000)

