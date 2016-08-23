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
        @roomObjects = []
        @roomObjects[0] = new Room()
        @roomObjects[0].population = 5
        @roomObjects[0].occupantType = unitTypes.minion
        @roomObjects[1] = new Room()
        @roomObjects[1].population = 5
        @roomObjects[1].occupantType = unitTypes.monster
        @roomObjects[1].population = 5
        for i in [0..@monsters-1]
            @roomObjects[1].monsters[i] = @monsterObjects[i]
        @roomObjects[2] = new Room()
        @roomObjects[2].occupantType = unitTypes.acolyte
        @roomObjects[2].population = 5
        @roomObjects[3] = new Room()
        @roomObjects[4] = new Room()
        
        @adventurers = 0
        @reputation = 0
        @devMultiplier = 1

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
        @updateRoomBox()
        for monster in @monsterObjects
            for i in [0..@devMultiplier-1]
                monster.tick()

    updateValues: =>
        @roomProgress += @minions * @devMultiplier
        if @roomProgress >= @roomCost()
            @roomProgress -= @roomCost()
            @rooms += 1
            @roomObjects[@rooms-1] = new Room()

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

    updateRoomBox: =>
        text = "Room Summary:<br><br>"
        for i in [0..@rooms-1]
            room = @roomObjects[i]
            text += "Room "+(i+1).toString()+":<br>Contains "
            if room.occupantType == unitTypes.none
                text += "nothing"
            else if room.occupantType == unitTypes.minion
                text += "minions"
            else if room.occupantType == unitTypes.monster
                text += "monsters"
            else if room.occupantType == unitTypes.acolyte
                text += "acolytes"
            text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        document.getElementById('roomsPanel').innerHTML = text
    
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
            if @allocateRoom(unitTypes.minion)
                @minions += 1
                @reputation -= @cost
    buyMonster: =>
        if @reputation>@cost and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.monster)
                @reputation -= @cost
                @monsters += 1
    buyAcolyte: =>
        if @reputation>@cost and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.acolyte)
                @reputation -= @cost
                @acolytes += 1
    buyAllMinions: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyMinion()
    buyAllMonsters: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyMonster()
    buyAllAcolytes: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyAcolyte()
    runDungeon: =>
        @narrate('An adventurer arrives!')
        adventurer = new Adventurer()
        for room in @roomObjects
            if room.occupantType == unitTypes.monster
                console.log(room)
                if @encounterMonsters(adventurer,room)
                    return
        if @treasure>1
            @treasure -= 1
            @narrate('The adventurer has successfully beaten all of your monsters! They take one of your treasures!')
            console.log("activemonsters: #{@monstersActive()}")
        else
            @narrate('The adventurer finds nothing and leaves.')
    encounterMonsters: (adventurer, room) =>
        @doCombat(adventurer,room)
        if adventurer.hp<=0
            @defeatAdventurer(room)
            return true
        else
            return false
    doCombat: (adventurer, room) =>
        if @anyMonstersActive(room)
            turnRoll = Math.floor((Math.random() * 2) + 1)
            while adventurer.hp>0 and @anyMonstersActive(room)
                if turnRoll==1
                    monster = @monsterWithLowestHp(room)
                    monster.hp -= Math.floor((Math.random() * 8) + 3)
                    turnRoll = 2
                    if monster.hp<=0
                        monster.hp = 0
                        monster.health = 0
                        @narrate('One of your monsters has been disabled by an adventurer.')
                else if turnRoll==2
                    for monster in room.monsters
                        adventurer.hp -= (Math.floor((Math.random() * 12) + 4 + monster.damage))
                    turnRoll = 1
    anyMonstersActive: (room) =>
        for monster in room.monsters
            if monster.isActive()
                return true
        return false
    monsterWithLowestHp: (room) =>
        lowestHp = 1000000
        monsterSelected = null
        for monster in room.monsters
            if monster.hp<lowestHp and monster.isActive()
                lowestHp = monster.hp
                monsterSelected = monster
        return monsterSelected
    numActiveMonsters: (room) =>
        count = 0
        for monster in room.monsters
            if monster.isActive()
                count += 1
        return count
    defeatAdventurer: (room) =>
        @adventurers+=1
        @treasure+=1
        xp = Math.floor(100/@numActiveMonsters(room))
        for monster in room.monsters
            if monster.isActive()
                monster.xp += xp
                monster.checkForLevelUp()
        @narrate('Some of your monsters have slain the adventurer! You take their treasure!')
    narrate: (text) =>
        document.getElementById('narrationContainer').innerHTML+='<br>'+text
        document.getElementById('narrationContainer').scrollTop = document.getElementById('narrationContainer').scrollHeight
    allocateRoom: (type) =>
        for room in @roomObjects
            if room.occupantType == unitTypes.none
                room.occupantType = type
                room.population += 1
                @addMonsterToRoom(room)
                return true
            else if room.occupantType == type and room.population < room.size
                room.population += 1
                @addMonsterToRoom(room)
                return true
        return false
    addMonsterToRoom: (room) =>
        if room.occupantType == unitTypes.monster
            monster = new Monster()
            @monsterObjects[@monsters] = monster
            room.monsters[room.population-1] = monster                    

class Monster
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @hp = 15
        @maxHp = 15
        @xp = 0
        @level = 1
        @damage = 0
    isActive: =>
        if (@health==@maxHealth)
            return true
        else
            return false
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                window.simulator.narrate('One of your monsters has recovered.')
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 160) + 1)
            if roll==160
                @hp += 1
    checkForLevelUp: =>
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
    levelUp: =>
        @level += 1
        window.simulator.narrate('One of your monsters has attained level '+@level.toString()+'!')
        @hp += 7
        @maxHp += 7
        @damage += 1
class Adventurer
    constructor: ->
        @hp = 13
class Room
    constructor: ->
        @population = 0
        @size = 5
        @occupantType = unitTypes.none
        @monsters = []
unitTypes =
    none: -1
    minion: 0
    monster: 1
    acolyte: 2
        
        
$ ->
    window.simulator = new Dungeon
    setInterval(window.simulator.tick,100)
    # setInterval(simulator.tick,1000)

