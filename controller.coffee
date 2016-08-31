CanvasInitializer =
    initCanvas: ->
        window.viewSize = 512
        mainCanvasContainer = document.getElementById('mainCanvasContainer')
        mainCanvasContainer.style.width = @viewSize
        mainCanvasContainer.style.height = @viewSize
        window.canvas = new fabric.Canvas('mainCanvas', {width: @viewSize, height: @viewSize})
        window.canvas.backgroundColor="black"
        window.canvas.selection = false
        window.canvas.stateful = false
        window.canvas.renderOnAddRemove = false
        window.canvas.renderAll()

app = angular.module('dungeonBuilder', [])
app.service 'dungeon', class Dungeon
    constructor: ($rootScope) ->
        @rootScope = $rootScope
        @minions = 5
        @smallMinions = 0
        @bigMinions = 0
        @monsters = 5
        @smallMonsters = 0
        @bigMonsters = 0
        @monsterObjects = []
        for i in [0..@monsters-1]
            @monsterObjects[i]=new Monster()
        @acolytes = 5
        @smallAcolytes = 0
        @bigAcolytes = 0
        @treasure = 10
        $(document).ready( ->
            CanvasInitializer.initCanvas()
        )
            
        @map = new Map()
        for i in [1..4]
            @digRoom()

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
        @minionMultiplier = 1
        @acolyteMultiplier = 1
        @minionUpgradeCost = Math.floor(15000*0.2)
        @acolyteUpgradeCost = Math.floor(15000*0.2)

        @cost = 1500

        setInterval(@tick,100)
    tick: =>
        @updateValues()
        @updateRoomBox()
        @updateRoomCanvas()
        for monster in @monsterObjects
            for i in [0..@devMultiplier-1]
                monster.tick()

    updateValues: =>
        @roomProgress += ((@smallMinions/4)+@minions+(@bigMinions*4)) * @devMultiplier * @minionMultiplier
        if @roomProgress >= @roomCost()
            @roomProgress -= @roomCost()
            @rooms += 1
            @roomObjects[@rooms-1] = new Room()
            @digRoom()

        @reputation += ((@smallAcolytes/4)+@acolytes+(@bigAcolytes*4)) * @devMultiplier * @acolyteMultiplier


        for i in [0..Math.floor(@treasure*@devMultiplier)-1]
            adventurerRoll = Math.floor((Math.random() * 14500) + 1)
            if adventurerRoll == 14500
                @runDungeon()
        @rootScope.$apply()

    reputationRate: =>
        return Math.floor(((@smallAcolytes*2.5)+(@acolytes*10)+(@bigAcolytes*40))*@acolyteMultiplier)
    roomProgressPercent: =>
        return (@roomProgress/@roomCost()*100).toString()

    updateRoomBox: =>
        text = "Room Summary:<br><br>"
        for i in [0..@rooms-1]
            room = @roomObjects[i]
            text += "Room "+(i+1).toString()+":<br>Contains "
            if room.occupantType == unitTypes.none
                text += "nothing"
            else if room.occupantType == unitTypes.minion
                text += "minions"
            else if room.occupantType == unitTypes.smallMinion
                text += "mini-ons"
            else if room.occupantType == unitTypes.bigMinion
                text += "big minions"
            else if room.occupantType == unitTypes.monster
                text += "monsters"
            else if room.occupantType == unitTypes.smallMonster
                text += "small monsters"
            else if room.occupantType == unitTypes.bigMonster
                text += "big monsters"
            else if room.occupantType == unitTypes.acolyte
                text += "acolytes"
            else if room.occupantType == unitTypes.smallAcolyte
                text += "small acolytes"
            else if room.occupantType == unitTypes.bigAcolyte
                text += "big acolytes"
            text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        document.getElementById('roomsPanel').innerHTML = text
    upgradeMinionsText: =>
        return "Upgrade Minions (#{@minionUpgradeCost} reputation)"
    upgradeAcolytesText: =>
        return "Upgrade Acolytes (#{@acolyteUpgradeCost} reputation)"
    roomETA: =>
        remaining = @roomCost() - @roomProgress
        rate = ((@smallMinions/4)+@minions+(@bigMinions*4)) * @devMultiplier * @minionMultiplier
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
        return specific

    updateProgressBar: (bar, percent) ->
      bar.width("#{percent}%")
      
    updateRoomCanvas: ->
        window.canvas.clear()
        for i in [0..@map.sizeX-1]
            for j in [0..@map.sizeY-1]
                if @map.tiles[i][j]=='W'
                    window.canvas.add new fabric.Rect(left: (i*8), top: (j*8), height: 8, width: 8, stroke: 'gray', fill: 'gray', strokeWidth: 2, selectable: false)
        window.canvas.renderAll()

    roomCost: =>
        costToBuild = 12240
        if @rooms >= 100
            costToBuild = 1328065992
        else if @rooms >= 30
            costToBuild = 6324123
        else if @rooms >= 20
            costToBuild = 799632
        return costToBuild
    totalPopulation: =>
        return @minions+@monsters+@acolytes+@smallMinions+@bigMinions+@smallMonsters+@bigMonsters+@smallAcolytes+@bigAcolytes
    maxPopulation: =>
        count = 0
        for room in @roomObjects
            count += room.size
        return count
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
        if @reputation>@cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.minion)
                @minions += 1
                @reputation -= @cost
    buySmallMinion: =>
        smallCost = Math.floor(@cost/4)
        if @reputation>smallCost
            if @allocateRoom(unitTypes.smallMinion)
                @smallMinions += 1
                @reputation -= smallCost
    buyBigMinion: =>
        bigCost = Math.floor(@cost*2.8)
        if @reputation>bigCost
            if @allocateRoom(unitTypes.bigMinion)
                @bigMinions += 1
                @reputation -= bigCost
    buyMonster: =>
        if @reputation>@cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.monster)
                @reputation -= @cost
                @monsters += 1
    buySmallMonster: =>
        smallCost = Math.floor(@cost/4)
        if @reputation>smallCost
            if @allocateRoom(unitTypes.smallMonster)
                @smallMonsters += 1
                @reputation -= smallCost
    buyBigMonster: =>
        bigCost = Math.floor(@cost*2.8)
        if @reputation>bigCost
            if @allocateRoom(unitTypes.bigMonster)
                @bigMonsters += 1
                @reputation -= bigCost
    buyAcolyte: =>
        if @reputation>@cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.acolyte)
                @reputation -= @cost
                @acolytes += 1
    buySmallAcolyte: =>
        smallCost = Math.floor(@cost/4)
        if @reputation>smallCost
            if @allocateRoom(unitTypes.smallAcolyte)
                @smallAcolytes += 1
                @reputation -= smallCost
    buyBigAcolyte: =>
        bigCost = Math.floor(@cost*2.8)
        if @reputation>bigCost
            if @allocateRoom(unitTypes.bigAcolyte)
                @bigAcolytes += 1
                @reputation -= bigCost
    buyAllMinions: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyMinion()
    buyAllSmallMinions: =>
        number = @maxNumberToBuy Math.floor(@cost/4)
        for i in [0..number-1]
            @buySmallMinion()
    buyAllBigMinions: =>
        number = @maxNumberToBuy Math.floor(@cost*2.8)
        for i in [0..number-1]
            @buyBigMinion()
    buyAllMonsters: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyMonster()
    buyAllSmallMonsters: =>
        number = @maxNumberToBuy Math.floor(@cost/4)
        for i in [0..number-1]
            @buySmallMonster()
    buyAllBigMonsters: =>
        number = @maxNumberToBuy Math.floor(@cost*2.8)
        for i in [0..number-1]
            @buyBigMonster()
    buyAllAcolytes: =>
        number = @maxNumberToBuy @cost
        for i in [0..number-1]
            @buyAcolyte()
    buyAllSmallAcolytes: =>
        number = @maxNumberToBuy Math.floor(@cost/4)
        for i in [0..number-1]
            @buySmallAcolyte()
    buyAllBigAcolytes: =>
        number = @maxNumberToBuy Math.floor(@cost*2.8)
        for i in [0..number-1]
            @buyBigAcolyte()
    sellMinion: =>
        if @minions>1
            @minions -= 1
            @optimizeRemoval(unitTypes.minion)
    sellSmallMinion: =>
        if @smallMinions>0
            @smallMinions -= 1
            @optimizeRemoval(unitTypes.smallMinion)
    sellBigMinion: =>
        if @bigMinions>0
            @bigMinions -= 1
            @optimizeRemoval(unitTypes.bigMinion)
    sellMonster: =>
        if @monsters>0
            @monsters -= 1
            @optimizeRemoval(unitTypes.monster)
    sellSmallMonster: =>
        if @smallMonsters>0
            @smallMonsters -= 1
            @optimizeRemoval(unitTypes.smallMonster)
    sellBigMonster: =>
        if @bigMonsters>0
            @bigMonsters -= 1
            @optimizeRemoval(unitTypes.bigMonster)
    sellAcolyte: =>
        if @acolytes>1
            @acolytes -= 1
            @optimizeRemoval(unitTypes.acolyte)
    sellSmallAcolyte: =>
        if @smallAcolytes>0
            @smallAcolytes -= 1
            @optimizeRemoval(unitTypes.smallAcolyte)
    sellBigAcolyte: =>
        if @bigAcolytes>0
            @bigAcolytes -= 1
            @optimizeRemoval(unitTypes.bigAcolyte)
    upgradeMinions: =>
        if @reputation >= @minionUpgradeCost
            @reputation -= @minionUpgradeCost
            @minionMultiplier = @minionMultiplier*1.2
            @minionUpgradeCost = Math.floor(@minionUpgradeCost*2*1.2)
    upgradeAcolytes: =>
        if @reputation >= @acolyteUpgradeCost
            @reputation -= @acolyteUpgradeCost
            @acolyteMultiplier = @acolyteMultiplier*1.2
            @acolyteUpgradeCost = Math.floor(@acolyteUpgradeCost*2*1.2)
    optimizeRemoval: (type) =>
        roomSelected = null
        for room in @roomObjects
            if room.occupantType!=type
                continue
            if roomSelected==null and room.population > 0
                roomSelected = room
            else if room.population < roomSelected.population and room.population > 0
                roomSelected = room
        roomSelected.population -= 1
        if roomSelected.population == 0
            roomSelected.occupantType = unitTypes.none
    runDungeon: =>
        @narrate('An adventurer arrives!')
        adventurer = new Adventurer()
        for room in @roomObjects
            if room.occupantType == unitTypes.monster
                if @encounterMonsters(adventurer,room)
                    return
        if @treasure>1
            @treasure -= 1
            @narrate('The adventurer has successfully beaten all of your monsters! They take one of your treasures!')
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
                        adventurer.hp -= Math.max((Math.floor((Math.random() * 12) + 4 + monster.damage)),0)
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
        if room.occupantType == unitTypes.monster
            type = "monsters"
        else if room.occupantType == unitTypes.smallMonster
            type = "small monsters"
        else if room.occupantType == unitTypes.bigMonster
            type = "big monsters"
        @narrate('Some of your '+type+' have slain the adventurer! You take their treasure!')
    narrate: (text) =>
        document.getElementById('narrationContainer').innerHTML+='<br>'+text
        document.getElementById('narrationContainer').scrollTop = document.getElementById('narrationContainer').scrollHeight
    allocateRoom: (type) =>
        for room in @roomObjects
            if room.occupantType == unitTypes.none
                room.occupantType = type
                room.population += 1
                @addMonsterToRoom(room)
                @adjustMaxPopulation(room)
                return true
            else if room.occupantType == type and room.population < room.size
                room.population += 1
                @addMonsterToRoom(room)
                @adjustMaxPopulation(room)
                return true
        return false
    addMonsterToRoom: (room) =>
        if room.occupantType == unitTypes.monster or room.occupantType == unitTypes.smallMonster or room.occupantType == unitTypes.bigMonster
            if room.occupantType == unitTypes.monster
                monster = new Monster()
            else if room.occupantType == unitTypes.smallMonster
                monster = new SmallMonster()
            else if room.occupantType == unitTypes.bigMonster
                monster = new BigMonster()
            @monsterObjects[@monsters+@smallMonsters+@bigMonsters] = monster
            room.monsters[room.population-1] = monster
    adjustMaxPopulation: (room) =>
        if room.occupantType == unitTypes.smallMinion or room.occupantType == unitTypes.smallMonster or room.occupantType == unitTypes.smallAcolyte
            room.size = 10
        else if room.occupantType == unitTypes.bigMinion or room.occupantType == unitTypes.bigMonster or room.occupantType == unitTypes.bigAcolyte
            room.size = 2
        else
            room.size = 5
    digRoom: =>
        result = false
        while result==false
            [x,y,facing] = @pickRandomWall()
            result = @map.excavate(x,y,facing)
    pickRandomWall: =>
        facing = null
        while facing==null
            x = Math.floor(Math.random()*(@map.sizeX-(@map.border*2)-1))+@map.border
            y = Math.floor(Math.random()*(@map.sizeY-(@map.border*2)-1))+@map.border
            facing = @checkForEmptySpace(x,y)
        return [x,y,facing]
    checkForEmptySpace: (x,y) =>
        if @map.tiles[x][y+1]==' '
            return 2
        if @map.tiles[x-1][y]==' '
            return 3
        if @map.tiles[x][y-1]==' '
            return 0
        if @map.tiles[x+1][y]==' '
            return 1
        return null
    
app.controller 'main', ($scope, dungeon) ->
    $scope.dungeon = dungeon
    $scope.reputation = 0
    $scope.reputationRate = 0
    $scope.minions = 0
    $scope.smallMinions = 0
    $scope.bigMinions = 0
    $scope.buyAllMinionsText = ""
    $scope.buyAllSmallMinionsText = ""
    $scope.buyAllBigMinionsText = ""
    $scope.population = 0
    $scope.maxPopulation = 0
    $scope.roomProgressPercent = 0
    $scope.rooms = 0
    $scope.roomETA = ""
    $scope.monsters = 0
    $scope.smallMonsters = 0
    $scope.bigMonsters = 0
    $scope.monstersActive = 0
    $scope.buyAllMonstersText = ""
    $scope.buyAllSmallMonstersText = ""
    $scope.BuyAllBigMonstersText = ""
    $scope.acolytes = 0
    $scope.smallAcolytes = 0
    $scope.bigAcolytes = 0
    $scope.buyAllAcolytesText = ""
    $scope.buyAllSmallAcolytesText = ""
    $scope.buyAllBigAcolytesText = ""
    $scope.adventurers = 0
    $scope.treasure = 0
    $scope.upgradeMinionsText = ""
    $scope.upgradeAcolytesText = ""
    $scope.$watch 'dungeon.reputation', (newVal) ->
        $scope.reputation = Math.floor(newVal)
        $scope.buyAllMinionsText = "Buy All (#{dungeon.maxNumberToBuy dungeon.cost})"
        $scope.buyAllSmallMinionsText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost/4)})"
        $scope.buyAllBigMinionsText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost*2.8)})"
        $scope.buyAllMonstersText = "Buy All (#{dungeon.maxNumberToBuy dungeon.cost})"
        $scope.buyAllSmallMonstersText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost/4)})"
        $scope.buyAllBigMonstersText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost*2.8)})"
        $scope.buyAllAcolytesText = "Buy All (#{dungeon.maxNumberToBuy dungeon.cost})"
        $scope.buyAllSmallAcolytesText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost/4)})"
        $scope.buyAllBigAcolytesText = "Buy All (#{dungeon.maxNumberToBuy Math.floor(dungeon.cost*2.8)})"
    $scope.$watch 'dungeon.reputationRate()', (newVal) ->
        $scope.reputationRate = newVal
    $scope.$watch 'dungeon.minions', (newVal) ->
        $scope.minions = newVal
    $scope.$watch 'dungeon.smallMinions', (newVal) ->
        $scope.smallMinions = newVal
    $scope.$watch 'dungeon.bigMinions', (newVal) ->
        $scope.bigMinions = newVal
    $scope.$watch 'dungeon.totalPopulation()', (newVal) ->
        $scope.population = newVal
    $scope.$watch 'dungeon.maxPopulation()', (newVal) ->
        $scope.maxPopulation = newVal
    $scope.$watch 'dungeon.roomProgressPercent()', (newVal) ->
        $scope.roomProgressPercent = newVal
    $scope.$watch 'dungeon.rooms', (newVal) ->
        $scope.rooms = newVal
    $scope.$watch 'dungeon.roomETA()', (newVal) ->
        $scope.roomETA = newVal
    $scope.$watch 'dungeon.monsters', (newVal) ->
        $scope.monsters = newVal
    $scope.$watch 'dungeon.smallMonsters', (newVal) ->
        $scope.smallMonsters = newVal
    $scope.$watch 'dungeon.bigMonsters', (newVal) ->
        $scope.bigMonsters = newVal
    $scope.$watch 'dungeon.monstersActive()', (newVal) ->
        $scope.monstersActive = newVal
    $scope.$watch 'dungeon.acolytes', (newVal) ->
        $scope.acolytes = newVal
    $scope.$watch 'dungeon.smallAcolytes', (newVal) ->
        $scope.smallAcolytes = newVal
    $scope.$watch 'dungeon.bigAcolytes', (newVal) ->
        $scope.bigAcolytes = newVal
    $scope.$watch 'dungeon.adventurers', (newVal) ->
        $scope.adventurers = newVal
    $scope.$watch 'dungeon.treasure', (newVal) ->
        $scope.treasure = newVal
    $scope.$watch 'dungeon.upgradeMinionsText()', (newVal) ->
        $scope.upgradeMinionsText = newVal
    $scope.$watch 'dungeon.upgradeAcolytesText()', (newVal) ->
        $scope.upgradeAcolytesText = newVal

app.directive 'tab', ->
    {
        restrict: 'E'
        transclude: true
        template: '<div role="tabpanel" class="tabContents" ng-show="active" ng-transclude></div>'
        require: '^tabset'
        scope: { heading: '@' }
        link: (scope, elem, attr, tabsetCtrl) ->
            scope.active = false
            console.log(tabsetCtrl)
            tabsetCtrl.addTab(scope)
    }
app.directive 'tabset', ->
    {
        restrict: 'E'
        transclude: true
        scope: {}
        templateUrl: 'tabset.html'
        bindToController: true
        controllerAs: 'tabset'
        controller: ->
            @tabs = []
            @addTab = (tab) ->
                @tabs.push tab
                if @tabs.length == 1
                    tab.active = true
                return
            @select = (selectedTab) ->
                for tab in @tabs
                    if tab.active  and tab != selectedTab
                        tab.active = false
                selectedTab.active = true
                return
            return
    }

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
class SmallMonster extends Monster
    constructor: ->
        super()
        @hp = 4
        @maxHp = 4
        @damage = -7
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                window.simulator.narrate('One of your monsters has recovered.')
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 640) + 1)
            if roll==640
                @hp += 1
    levelUp: =>
        @level += 1
        window.simulator.narrate('One of your small monsters has attained level '+@level.toString()+'!')
        @hp += 2
        @maxHp += 2
        @damage += 1
class BigMonster extends Monster
    constructor: ->
        super()
        @hp = 60
        @maxHp = 60
        @damage = 30
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                window.simulator.narrate('One of your monsters has recovered.')
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 40) + 1)
            if roll==40
                @hp += 1
    levelUp: =>
        @level += 1
        window.simulator.narrate('One of your big monsters has attained level '+@level.toString()+'!')
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
class Map
    constructor: ->
        @sizeX = 64
        @sizeY = 64
        @roomDimensions=5
        @tiles = []
        @border = 1
        @initFillMap()
        @digInitialRoom()
    initFillMap: ->
        for i in [0..@sizeX-1]
            @tiles[i]=[]
            for j in [0..@sizeY-1]
                @tiles[i][j]='W'
    digInitialRoom: ->
        rollX = Math.floor((Math.random() * (@sizeX-(@border*2)-@roomDimensions)-1)+@border)
        rollY = Math.floor((Math.random() * (@sizeY-(@border*2)-@roomDimensions)-1)+@border)
        for i in [rollX..rollX+@roomDimensions-1]
            for j in [rollY..rollY+@roomDimensions-1]
                @tiles[i][j]=' '
    excavate: (x,y,facing) ->
        [xStep,yStep] = @determineStep(facing)
        [xMax,yMax] = @determineBounds(x,y,xStep,yStep,facing)
        for i in [x..xMax] by xStep
            for j in [y..yMax] by yStep
                if @tiles[i]==undefined
                    return false
                if @tiles[i][j]!='W'
                    return false
        [x,y]=@excavateDoor(x,y,xStep,yStep,facing)
        for i in [x..xMax] by xStep
            for j in [y..yMax] by yStep
                @tiles[i][j]=' '
        return true
    excavateDoor: (x,y,xStep,yStep,facing) =>
        valid = false
        while valid==false
            if facing==0 or facing==2
                xDoor = Math.floor(Math.random()*5)+x
                yDoor = y
            else if facing==1 or facing==3
                xDoor = x
                yDoor = Math.floor(Math.random()*5)+y
            valid = @checkOpenings(xDoor,yDoor)
        @tiles[xDoor][yDoor]=' '
        if facing==0 or facing==2
            y += yStep
        else if facing==1 or facing==3
            x += xStep
        return [x,y]
    checkOpenings: (x,y) =>
        count = 0
        if @tiles[x-1][y]==' '
            count +=1
        if @tiles[x+1][y]==' '
            count +=1
        if @tiles[x][y-1]==' '
            count +=1
        if @tiles[x][y+1]==' '
            count +=1
        console.log(count)
        if count==1
            return true
        return false
    determineStep: (facing) =>
        if facing==0
            return [1,1]
        if facing==1
            return [-1,1]
        if facing==2
            return [1,-1]
        if facing==3
            return [1,1]
    determineBounds: (x, y, xStep, yStep,facing) =>
        if facing==0 or facing==2
            return [x+(xStep*(@roomDimensions-1)),y+(yStep*(@roomDimensions))]
        if facing==1 or facing==3
            return [x+(xStep*(@roomDimensions)),y+(yStep*(@roomDimensions-1))]
unitTypes =
    none: -1
    minion: 0
    monster: 1
    acolyte: 2
    smallMinion: 3
    bigMinion: 4
    smallMonster: 5
    bigMonster: 6
    smallAcolyte: 7
    bigAcolyte: 8
