CanvasInitializer=
    initCanvas: ->
        window.viewSize = 768
        mainCanvasContainer = document.getElementById('mainCanvasContainer')
        mainCanvasContainer.style.width = @viewSize
        mainCanvasContainer.style.height = @viewSize
        window.canvas = new fabric.Canvas('mainCanvas', {width: @viewSize, height: @viewSize})
        window.canvas.backgroundColor="black"
        window.canvas.selection = false
        window.canvas.stateful = false
        window.canvas.renderOnAddRemove = false
        window.canvas.skipTargetFind = true
        window.canvas.renderAll()

app = angular.module('dungeonBuilder', ['ui.bootstrap', 'ngCookies', 'ngAnimate'])
app.service 'dungeon', class Dungeon
    constructor: ($rootScope) ->
        window.simulator = this
        window.rootScope = $rootScope
        @data = new DungeonData()
        @data.dragMode = false
        @data.dragRoom = null
        @data.dropRoom = null
        @data.dragBox = null
        @data.dragText = null
        @data.minions = 0
        @data.smallMinions = 5
        @data.bigMinions = 0
        @data.hugeMinions = 0
        @data.minionObjects = []
        for i in [0..@data.smallMinions-1]
            @data.minionObjects[i]=new SmallMinion()
        @data.monsters = 0
        @data.smallMonsters = 5
        @data.bigMonsters = 0
        @data.hugeMonsters = 0
        @data.monsterObjects = []
        for i in [0..@data.smallMonsters-1]
            @data.monsterObjects[i]=new SmallMonster()
        @data.acolytes = 0
        @data.smallAcolytes = 5
        @data.bigAcolytes = 0
        @data.hugeAcolytes = 0
        @data.acolyteObjects = []
        for i in [0..@data.smallAcolytes-1]
            @data.acolyteObjects[i]=new SmallAcolyte()
        @data.treasure = 10
        $(document).ready( ->
            CanvasInitializer.initCanvas()
        )
            
        @data.roomProgress = 0
        @data.rooms = 5
        @data.roomObjects = []
        @data.roomObjects[0] = new Room()
        @data.roomObjects[0].population = 5
        @data.roomObjects[0].size = 10
        @data.roomObjects[0].occupantType = unitTypes.smallMinion
        for i in [0..@data.smallMinions-1]
            @data.roomObjects[0].minions[i] = @data.minionObjects[i]
        @data.roomObjects[1] = new Room()
        @data.roomObjects[1].population = 5
        @data.roomObjects[1].size = 10
        @data.roomObjects[1].occupantType = unitTypes.smallMonster
        @data.roomObjects[1].population = 5
        for i in [0..@data.smallMonsters-1]
            @data.roomObjects[1].monsters[i] = @data.monsterObjects[i]
        @data.roomObjects[2] = new Room()
        @data.roomObjects[2].occupantType = unitTypes.smallAcolyte
        @data.roomObjects[2].population = 5
        @data.roomObjects[2].size = 10
        for i in [0..@data.smallAcolytes-1]
            @data.roomObjects[2].acolytes[i] = @data.acolyteObjects[i]
        @data.roomObjects[3] = new Room()
        @data.roomObjects[4] = new Room()

        @data.map = new Map()
        @data.roomObjects[0].boundaries = @data.map.initialRoomBoundaries
        for i in [1..4]
            @data.roomObjects[i].boundaries = @digRoom()
        @formRoomConnections()
        @data.adventurers = 0
        @data.reputation = 0
        @data.devMultiplier = 1
        @data.minionMultiplier = 1
        @data.acolyteMultiplier = 1
        @data.minionUpgradeCost = Math.floor(15000*0.2)
        @data.acolyteUpgradeCost = Math.floor(15000*0.2)
        @data.cost = 4000
        
        @data.lastTickTime = moment().valueOf()
        @data.firstTick = true
        @tickCount = 0
        setInterval(@catchUp,100)
    
    catchUp: =>
        newTickTime = moment().valueOf()
        calc = Math.floor((newTickTime - @data.lastTickTime)/100)
        if calc>0
            for i in [1..calc]
                @tick()
        @data.lastTickTime = @data.lastTickTime + (calc*100)
        
    tick: =>
        @tickCount += 1
        for minion in @data.minionObjects
            for i in [0..@data.devMultiplier-1]
                @minionTick(minion)
        for acolyte in @data.acolyteObjects
            for i in [0..@data.devMultiplier-1]
                @acolyteTick(acolyte)
        @updateValues()
        @updateRoomBox()
        for monster in @data.monsterObjects
            for i in [0..@data.devMultiplier-1]
                monster.tick()
        if @data.firstTick
            @updateRoomCanvas()
            @data.firstTick = false
        if @tickCount == 600
            @tickCount = 0
            @megaTick()
    megaTick: =>
        window.rootScope.save()
    acolyteTick: (acolyte) =>
        if acolyte.health<acolyte.maxHealth
            acolyte.health+=1
        if acolyte.health>=acolyte.maxHealth
            @data.reputation += acolyte.reputation * @data.devMultiplier * @data.acolyteMultiplier
    minionTick: (minion) =>
        if minion.health<minion.maxHealth
            minion.health+=1
        if minion.health>= minion.maxHealth
            @data.roomProgress += minion.labor * @data.devMultiplier * @data.minionMultiplier
    updateValues: =>
        if @data.roomProgress >= @roomCost()
            @data.roomProgress -= @roomCost()
            @data.rooms += 1
            @data.roomObjects[@data.rooms-1] = new Room()
            @data.roomObjects[@data.rooms-1].boundaries = @digRoom()
            @formRoomConnections()
            @updateRoomCanvas()
        for i in [0..Math.floor(@data.treasure*@data.devMultiplier)-1]
            adventurerRoll = Math.floor((Math.random() * 14500) + 1)
            if adventurerRoll == 14500
                @runDungeon()
        window.rootScope.$apply()
    updateValuesNoApply: =>
        if @data.roomProgress >= @roomCost()
            @data.roomProgress -= @roomCost()
            @data.rooms += 1
            @data.roomObjects[@data.rooms-1] = new Room()
            @data.roomObjects[@data.rooms-1].boundaries = @digRoom()
            @formRoomConnections()
            @updateRoomCanvas()
        for i in [0..Math.floor(@data.treasure*@data.devMultiplier)-1]
            adventurerRoll = Math.floor((Math.random() * 14500) + 1)
            if adventurerRoll == 14500
                @runDungeon()

    reputationRate: =>
        return Math.floor(((@data.smallAcolytes*10)+(@data.acolytes*160)+(@data.bigAcolytes*2560)+(@data.hugeAcolytes*40960))*@data.acolyteMultiplier)
    roomProgressPercent: =>
        return (@data.roomProgress/@roomCost()*100).toString()
    unitProgressPercent: =>
        if @data.reputation >= @data.cost
            return '100'
        return ((@data.reputation % @data.cost)/@data.cost*100).toString()
    smallUnitProgressPercent: =>
        if @data.reputation >= Math.floor(@data.cost*0.09375)
            return '100'
        return ((@data.reputation % Math.floor(@data.cost*0.09375))/Math.floor(@data.cost*0.09375)*100).toString()
    bigUnitProgressPercent: =>
        if @data.reputation >= Math.floor(@data.cost*119.42)
            return '100'
        return ((@data.reputation % Math.floor(@data.cost*119.42))/Math.floor(@data.cost*119.42)*100).toString()
    hugeUnitProgressPercent: =>
        if @data.reputation >= Math.floor(@data.cost*17752.88)
            return '100'
        return ((@data.reputation % Math.floor(@data.cost*17752.88))/Math.floor(@data.cost*17752.88)*100).toString()
    minionUpgradeProgressPercent: =>
        if @data.reputation >= @data.minionUpgradeCost
            return '100'
        return (@data.reputation/@data.minionUpgradeCost*100).toString()
    acolyteUpgradeProgressPercent: =>
        if @data.reputation >= @data.acolyteUpgradeCost
            return '100'
        return (@data.reputation/@data.acolyteUpgradeCost*100).toString()

    updateRoomBox: =>
        text = "Room Summary:<br><br>"
        for i in [0..@data.rooms-1]
            room = @data.roomObjects[i]
            text += "Room "+(i+1).toString()+":<br>Contains "
            if room.occupantType == unitTypes.none
                text += "nothing"
            else if room.occupantType == unitTypes.minion
                text += "minions"
            else if room.occupantType == unitTypes.smallMinion
                text += "mini-ons"
            else if room.occupantType == unitTypes.bigMinion
                text += "big minions"
            else if room.occupantType == unitTypes.hugeMinion
                text += "huge minion"
            else if room.occupantType == unitTypes.monster
                text += "monsters"
            else if room.occupantType == unitTypes.smallMonster
                text += "small monsters"
            else if room.occupantType == unitTypes.bigMonster
                text += "big monsters"
            else if room.occupantType == unitTypes.hugeMonster
                text += "huge monster"
            else if room.occupantType == unitTypes.acolyte
                text += "acolytes"
            else if room.occupantType == unitTypes.smallAcolyte
                text += "small acolytes"
            else if room.occupantType == unitTypes.bigAcolyte
                text += "big acolytes"
            else if room.occupantType == unitTypes.hugeAcolyte
                text += "huge acolyte"
            text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        document.getElementById('roomsPanel').innerHTML = text
    upgradeMinionsText: =>
        return "Upgrade Minions (#{@data.minionUpgradeCost} reputation)"
    upgradeAcolytesText: =>
        return "Upgrade Acolytes (#{@data.acolyteUpgradeCost} reputation)"
    roomETA: =>
        remaining = @roomCost() - @data.roomProgress
        rate = ((@data.smallMinions)+(@data.minions*16)+(@data.bigMinions*256)+(@data.hugeMinions*4096)) * @data.devMultiplier * @data.minionMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    unitETA: =>
        if @data.reputation > @data.cost
            remaining = 0
        else
            remaining = @data.cost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    smallUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*0.09375)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*0.09375) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    bigUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*119.42)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*119.42) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    hugeUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*17752.88)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*17752.88) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    minionUpgradeETA: =>
        if @data.reputation > @data.minionUpgradeCost
            remaining = 0
        else
            remaining = @data.minionUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific
    acolyteUpgradeETA: =>
        if @data.reputation > @data.acolyteUpgradeCost
            remaining = 0
        else
            remaining = @data.acolyteUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        return specific


        
    updateProgressBar: (bar, percent) ->
      bar.width("#{percent}%")
      
    updateRoomCanvas: ->
        console.log('updating')
        window.canvas.clear()
        window.canvas.setBackgroundColor('gray')
        for i in [0..@data.map.sizeX-1]
            for j in [0..@data.map.sizeY-1]
                if @data.map.tiles[i][j]==' '
                    window.canvas.add new fabric.Rect(left: (i*12), top: (j*12), height: 12, width: 12, stroke: 'black', fill: 'black', strokeWidth: 1, selectable: false)
        for i in [0..@data.roomObjects.length-1]
            room = @data.roomObjects[i]
            window.canvas.add new fabric.Text((i+1).toString(),left: (room.boundaries[0]*12)+30, top: (room.boundaries[1]*12)+30, originX: 'center', originY: 'center', fill: 'white', fontSize: 16, selectable: false)
            [unitRepresentation,color] = @unitCode(@data.roomObjects[i])
            window.canvas.add new fabric.Text(unitRepresentation,left: (room.boundaries[0]*12), top: (room.boundaries[1]*12), originX: 'left', originY: 'top', fill: color, fontWeight: 'bold', fontSize: 16, selectable: false)
        window.canvas.off
        window.canvas.on 'mouse:move', (options) ->
            window.simulator.roomMouseOver(options)
        window.canvas.on 'mouse:down', (options) ->
            window.simulator.roomMouseDown(options)
        window.canvas.on 'mouse:up', (options) ->
            window.simulator.roomMouseUp(options)
        window.canvas.renderAll()
    unitCode: (room) =>
        occupants = room.occupantType
        if occupants == unitTypes.smallMinion or occupants == unitTypes.minion or occupants == unitTypes.bigMinion or occupants == unitTypes.hugeMinion
            text='Mi'
            color='yellow'
        else if occupants == unitTypes.smallMonster or occupants == unitTypes.monster or occupants == unitTypes.bigMonster or occupants == unitTypes.hugeMonster
            text='Mo'
            color='red'
        else if occupants == unitTypes.smallAcolyte or occupants == unitTypes.acolyte or occupants == unitTypes.bigAcolyte or occupants == unitTypes.hugeAcolyte
            text='A'
            color='cyan'
        if occupants == unitTypes.smallMinion or occupants == unitTypes.smallMonster or occupants == unitTypes.smallAcolyte
            text+='1'
        else if occupants == unitTypes.minion or occupants == unitTypes.monster or occupants == unitTypes.acolyte
            text+='2'
        else if occupants == unitTypes.bigMinion or occupants == unitTypes.bigMonster or occupants == unitTypes.bigAcolyte
            text=+'3'
        else if occupants == unitTypes.hugeMinion or occupants == unitTypes.hugeMonster or occupants == unitTypes.hugeAcolyte
            text=+'3'
        text+=' x'
        text+=room.population.toString()
        return [text,color]
    roomMouseOver: (options) ->
        x = options.e.layerX
        y = options.e.layerY
        if @data.dragMode
            if @data.dragBox != null
                window.canvas.remove @data.dragBox
            if @data.dragText != null
                window.canvas.remove @data.dragText
            @data.dragBox = new fabric.Rect(left: x, top: y, height: 60, width: 60, stroke: 'black', fill: 'black', strokeWidth: 1, selectable: false)
            room = @data.roomObjects[@data.dragRoom]
            [unitRepresentation,color] = @unitCode(room)
            @data.dragText = new fabric.Text(unitRepresentation,left: x, top: y, originX: 'left', originY: 'top', fill: color, fontWeight: 'bold', fontSize: 16, selectable: false)
            window.canvas.add @data.dragBox
            window.canvas.add @data.dragText
            window.canvas.renderAll()
            @hidePopup()
            return
        for i in [0..@data.roomObjects.length-1]
            room = @data.roomObjects[i]
            boundaries = room.boundaries
            if x>=boundaries[0]*12 and x<=(boundaries[2]+1)*12 and y>=boundaries[1]*12 and y<=(boundaries[3]+1)*12
                @displayPopup(i, options.e.x, options.e.y)
                return
        @hidePopup()
        return
    roomMouseDown: (options) ->
        @data.dragMode = true
        x = options.e.layerX
        y = options.e.layerY
        for i in [0..@data.roomObjects.length-1]
            room = @data.roomObjects[i]
            boundaries = room.boundaries
            if x>=boundaries[0]*12 and x<=(boundaries[2]+1)*12 and y>=boundaries[1]*12 and y<=(boundaries[3]+1)*12
                @data.dragRoom = i
                return
    roomMouseUp: (options) ->
        if @data.dragMode==false
            return
        @data.dragMode = false
        x = options.e.layerX
        y = options.e.layerY
        for i in [0..@data.roomObjects.length-1]
            room = @data.roomObjects[i]
            boundaries = room.boundaries
            if x>=boundaries[0]*12 and x<=(boundaries[2]+1)*12 and y>=boundaries[1]*12 and y<=(boundaries[3]+1)*12
                @data.dropRoom = i
                if @data.dragRoom!=null
                    swapPopulation = @data.roomObjects[@data.dragRoom].population
                    swapSize = @data.roomObjects[@data.dragRoom].size
                    swapOccupantType = @data.roomObjects[@data.dragRoom].occupantType
                    swapMonsters = @data.roomObjects[@data.dragRoom].monsters
                    @data.roomObjects[@data.dragRoom].population = @data.roomObjects[@data.dropRoom].population
                    @data.roomObjects[@data.dragRoom].size = @data.roomObjects[@data.dropRoom].size
                    @data.roomObjects[@data.dragRoom].occupantType = @data.roomObjects[@data.dropRoom].occupantType
                    @data.roomObjects[@data.dragRoom].monsters = @data.roomObjects[@data.dropRoom].monsters
                    @data.roomObjects[@data.dropRoom].population = swapPopulation
                    @data.roomObjects[@data.dropRoom].size = swapSize
                    @data.roomObjects[@data.dropRoom].occupantType = swapOccupantType
                    @data.roomObjects[@data.dropRoom].monsters = swapMonsters
                    @updateRoomCanvas()
                return
        @data.dragRoom = null
        @data.dropRoom = null
    displayPopup: (roomIndex,x,y) =>
        div = $('#roomTooltip')
        div.css({left: x+20, top: y-20, visibility: 'visible'})
        room = @data.roomObjects[roomIndex]
        text = "Room "+(roomIndex+1).toString()+":"
        if roomIndex==0
            text +='<br><span style="color: blue;">Dungeon Entrance</span>'
        text +="<br>Contains "
        if room.occupantType == unitTypes.none
            text += "nothing"
        else if room.occupantType == unitTypes.minion
            text += "minions"
        else if room.occupantType == unitTypes.smallMinion
            text += "mini-ons"
        else if room.occupantType == unitTypes.bigMinion
            text += "big minions"
        else if room.occupantType == unitTypes.hugeMinion
            text += "huge minion"
        else if room.occupantType == unitTypes.monster
            text += "monsters"
        else if room.occupantType == unitTypes.smallMonster
            text += "small monsters"
        else if room.occupantType == unitTypes.bigMonster
            text += "big monsters"
        else if room.occupantType == unitTypes.hugeMonster
            text += "huge monster"
        else if room.occupantType == unitTypes.acolyte
            text += "acolytes"
        else if room.occupantType == unitTypes.smallAcolyte
            text += "small acolytes"
        else if room.occupantType == unitTypes.bigAcolyte
            text += "big acolytes"
        else if room.occupantType == unitTypes.hugeAcolyte
            text += "huge acolyte"
        text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        div.html text
        return
    hidePopup: =>
        div = $('#roomTooltip')
        div.css({visibility: 'hidden'})
        return
    roomCost: =>
        costToBuild = 14528
        if @data.rooms >= 100
            costToBuild = 8366815749600*8
        else if @data.rooms >= 30
            costToBuild = 39841974900*8
        else if @data.rooms >= 25
            costToBuild = 79963200*8
        else if @data.rooms >= 20
            costToBuild = 3719216*8
        else if @data.rooms >= 15
            costToBuild = 929804
        else if @data.rooms >= 10
            costToBuild = 232451
        
        return costToBuild
    totalPopulation: =>
        smallUnits = @data.smallMinions+@data.smallMonsters+@data.smallAcolytes
        normalUnits = @data.minions+@data.monsters+@data.acolytes
        bigUnits = @data.bigMinions+@data.bigMonsters+@data.bigAcolytes
        hugeUnits = @data.hugeMinions+@data.hugeMonsters+@data.hugeAcolytes
        return (smallUnits*5)+(normalUnits*10)+(bigUnits*25)+(hugeUnits*50)
        # return @data.minions+@data.monsters+@data.acolytes+@data.smallMinions+@data.bigMinions+@data.smallMonsters+@data.bigMonsters+@data.smallAcolytes+@data.bigAcolytes
    maxPopulation: =>
        # count = 0
        # for room in @data.roomObjects
            # count += room.size
        # return count
        return @data.rooms * 50
    emptyRooms: =>
        count = 0
        for room in @data.roomObjects
            if room.population == 0
                count += 1
        return count
    availablePopulation: =>
        return Math.max(@maxPopulation()-@totalPopulation(),0)
    monstersActive: =>
        count = 0
        for monster in @data.monsterObjects
            if monster.isActive()
                count += 1
        return count
    maxNumberToBuy: (type) =>
        if type==unitTypes.minion or type==unitTypes.monster or type==unitTypes.acolyte
            cost = @data.cost
            max = 5
        else if type==unitTypes.smallMinion or type==unitTypes.smallMonster or type==unitTypes.smallAcolyte
            cost = @data.cost*0.09375
            max = 10
        else if type==unitTypes.bigMinion or type==unitTypes.bigMonster or type==unitTypes.bigAcolyte
            cost = @data.cost*119.42
            max = 2
        else if type==unitTypes.hugeMinion or type==unitTypes.hugeMonster or type==unitTypes.hugeAcolyte
            cost = @data.cost*17752.88
            max = 1
        maxBasedOnCost = Math.floor(@data.reputation/cost)
        maxBasedOnRooms = 0
        for room in @data.roomObjects
            if room.occupantType==type
                maxBasedOnRooms += (max-room.population)
            else if room.occupantType==unitTypes.none
                maxBasedOnRooms += max
        return Math.min(maxBasedOnCost,maxBasedOnRooms)      
    buyMinion: =>
        if @data.reputation>@data.cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.minion)
                @data.minions += 1
                @data.reputation -= @data.cost
                @updateRoomCanvas()
    buySmallMinion: =>
        smallCost = Math.floor(@data.cost*0.09375)
        if @data.reputation>smallCost
            if @allocateRoom(unitTypes.smallMinion)
                @data.smallMinions += 1
                @data.reputation -= smallCost
                @updateRoomCanvas()
    buyBigMinion: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation>bigCost
            if @allocateRoom(unitTypes.bigMinion)
                @data.bigMinions += 1
                @data.reputation -= bigCost
                @updateRoomCanvas()
    buyHugeMinion: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation>hugeCost
            if @allocateRoom(unitTypes.hugeMinion)
                @data.hugeMinions += 1
                @data.reputation -= hugeCost
                @updateRoomCanvas()
    buyMonster: =>
        if @data.reputation>@data.cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.monster)
                @data.reputation -= @data.cost
                @data.monsters += 1
                @updateRoomCanvas()
    buySmallMonster: =>
        smallCost = Math.floor(@data.cost*0.09375)
        if @data.reputation>smallCost
            if @allocateRoom(unitTypes.smallMonster)
                @data.smallMonsters += 1
                @data.reputation -= smallCost
                @updateRoomCanvas()
    buyBigMonster: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation>bigCost
            if @allocateRoom(unitTypes.bigMonster)
                @data.bigMonsters += 1
                @data.reputation -= bigCost
                @updateRoomCanvas()
    buyHugeMonster: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation>hugeCost
            if @allocateRoom(unitTypes.hugeMonster)
                @data.hugeMonsters += 1
                @data.reputation -= hugeCost
                @updateRoomCanvas()
    buyAcolyte: =>
        if @data.reputation>@data.cost #and @totalPopulation()<@maxPopulation()
            if @allocateRoom(unitTypes.acolyte)
                @data.reputation -= @data.cost
                @data.acolytes += 1
                @updateRoomCanvas()
    buySmallAcolyte: =>
        smallCost = Math.floor(@data.cost*0.09375)
        if @data.reputation>smallCost
            if @allocateRoom(unitTypes.smallAcolyte)
                @data.smallAcolytes += 1
                @data.reputation -= smallCost
                @updateRoomCanvas()
    buyBigAcolyte: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation>bigCost
            if @allocateRoom(unitTypes.bigAcolyte)
                @data.bigAcolytes += 1
                @data.reputation -= bigCost
                @updateRoomCanvas()
    buyHugeAcolyte: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation>hugeCost
            if @allocateRoom(unitTypes.hugeAcolyte)
                @data.hugeAcolytes += 1
                @data.reputation -= hugeCost
                @updateRoomCanvas()
    buyAllMinions: =>
        number = @maxNumberToBuy unitTypes.minion
        for i in [0..number-1]
            @buyMinion()
        @updateRoomCanvas()
    buyAllSmallMinions: =>
        number = @maxNumberToBuy unitTypes.smallMinion
        for i in [0..number-1]
            @buySmallMinion()
        @updateRoomCanvas()
    buyAllBigMinions: =>
        number = @maxNumberToBuy unitTypes.bigMinion
        for i in [0..number-1]
            @buyBigMinion()
        @updateRoomCanvas()
    buyAllHugeMinions: =>
        number = @maxNumberToBuy unitTypes.hugeMinion
        for i in [0..number-1]
            @buyHugeMinion()
        @updateRoomCanvas()
    buyAllMonsters: =>
        number = @maxNumberToBuy unitTypes.monster
        for i in [0..number-1]
            @buyMonster()
        @updateRoomCanvas()
    buyAllSmallMonsters: =>
        number = @maxNumberToBuy unitTypes.smallMonster
        for i in [0..number-1]
            @buySmallMonster()
        @updateRoomCanvas()
    buyAllBigMonsters: =>
        number = @maxNumberToBuy unitTypes.bigMonster
        for i in [0..number-1]
            @buyBigMonster()
        @updateRoomCanvas()
    buyAllHugeMonsters: =>
        number = @maxNumberToBuy unitTypes.hugeMonster
        for i in [0..number-1]
            @buyHugeMonster()
        @updateRoomCanvas()
    buyAllAcolytes: =>
        number = @maxNumberToBuy unitTypes.acolyte
        for i in [0..number-1]
            @buyAcolyte()
        @updateRoomCanvas()
    buyAllSmallAcolytes: =>
        number = @maxNumberToBuy unitTypes.smallAcolyte
        for i in [0..number-1]
            @buySmallAcolyte()
        @updateRoomCanvas()
    buyAllBigAcolytes: =>
        number = @maxNumberToBuy unitTypes.bigAcolyte
        for i in [0..number-1]
            @buyBigAcolyte()
        @updateRoomCanvas()
    buyAllHugeAcolytes: =>
        number = @maxNumberToBuy unitTypes.hugeAcolyte
        for i in [0..number-1]
            @buyHugeAcolyte()
        @updateRoomCanvas()
    buyRoomOfSmallMinions: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.smallMinion, 10)
        if number>0
            for i in [1..number]
                @buySmallMinion()
            @updateRoomCanvas()
    buyRoomOfMinions: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.minion, 5)
        if number>0
            for i in [1..number]
                @buyMinion()
            @updateRoomCanvas()
    buyRoomOfBigMinions: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMinion, 2)
        if number>0
            for i in [1..number]
                @buyBigMinion()
            @updateRoomCanvas()
    buyRoomOfSmallMonsters: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.smallMonster, 10)
        if number>0
            for i in [1..number]
                @buySmallMonster()
            @updateRoomCanvas()
    buyRoomOfMonsters: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.monster, 5)
        if number>0
            for i in [1..number]
                @buyMonster()
            @updateRoomCanvas()
    buyRoomOfBigMonsters: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMonster, 2)
        if number>0
            for i in [1..number]
                @buyBigMonster()
            @updateRoomCanvas()
    buyRoomOfSmallAcolytes: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.smallAcolyte, 10)
        if number>0
            for i in [1..number]
                @buySmallAcolyte()
            @updateRoomCanvas()
    buyRoomOfAcolytes: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.acolyte, 5)
        if number>0
            for i in [1..number]
                @buyAcolyte()
            @updateRoomCanvas()
    buyRoomOfBigAcolytes: =>
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigAcolyte, 2)
        if number>0
            for i in [1..number]
                @buyBigAcolyte()
            @updateRoomCanvas()
    sellRoomOfSmallMinions: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.smallMinion)
        if number>0
            for i in [1..number]
                @sellSmallMinion()
            @updateRoomCanvas()
    sellRoomOfMinions: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.minion)
        if number>0
            for i in [1..number]
                @sellMinion()
            @updateRoomCanvas()
    sellRoomOfBigMinions: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.bigMinion)
        if number>0
            for i in [1..number]
                @sellBigMinion()
            @updateRoomCanvas()
    sellRoomOfSmallMonsters: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.smallMonster)
        if number>0
            for i in [1..number]
                @sellSmallMonster()
            @updateRoomCanvas()
    sellRoomOfMonsters: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.monster)
        if number>0
            for i in [1..number]
                @sellMonster()
            @updateRoomCanvas()
    sellRoomOfBigMonsters: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.bigMonster)
        if number>0
            for i in [1..number]
                @sellBigMonster()
            @updateRoomCanvas()
    sellRoomOfSmallAcolytes: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.smallAcolyte)
        if number>0
            for i in [1..number]
                @sellSmallAcolyte()
            @updateRoomCanvas()
    sellRoomOfAcolytes: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.acolyte)
        if number>0
            for i in [1..number]
                @sellAcolyte()
            @updateRoomCanvas()
    sellRoomOfBigAcolytes: =>
        number = @calculateRoomCapacityForSellAll(unitTypes.bigAcolyte)
        if number>0
            for i in [1..number]
                @sellBigAcolyte()
            @updateRoomCanvas()
                
    calculateRoomCapacityForBuyAll: (unitType, max) =>
        number = max+1
        for room in @data.roomObjects
            if room.occupantType == unitType and room.population < max
                newPotentialNumber = max-room.population
            else if room.occupantType == unitTypes.none
                newPotentialNumber = max
            if newPotentialNumber < number
                number = newPotentialNumber
        if number == max+1
            return 0
        else
            return number
    calculateRoomCapacityForSellAll: (unitType) =>
        number = 999
        for room in @data.roomObjects
            if room.occupantType == unitType and room.population != 0
                newPotentialNumber = room.population
            if newPotentialNumber < number
                number = newPotentialNumber
        if number == 999
            return 0
        else
            return number

    sellMinion: =>
        if @data.minions+@data.smallMinions+@data.bigMinions+@data.hugeMinions>1
            @data.minions -= 1
            @optimizeRemoval(unitTypes.minion)
    sellSmallMinion: =>
        if @data.minions+@data.smallMinions+@data.bigMinions+@data.hugeMinions>1
            @data.smallMinions -= 1
            @optimizeRemoval(unitTypes.smallMinion)
    sellBigMinion: =>
        if @data.minions+@data.smallMinions+@data.bigMinions+@data.hugeMinions>1
            @data.bigMinions -= 1
            @optimizeRemoval(unitTypes.bigMinion)
    sellHugeMinion: =>
        if @data.minions+@data.smallMinions+@data.bigMinions+@data.hugeMinions>1
            @data.hugeMinions -= 1
            @optimizeRemoval(unitTypes.hugeMinion)
    sellMonster: =>
        if @data.monsters>0
            @data.monsters -= 1
            @optimizeRemoval(unitTypes.monster)
    sellSmallMonster: =>
        if @data.smallMonsters>0
            @data.smallMonsters -= 1
            @optimizeRemoval(unitTypes.smallMonster)
    sellBigMonster: =>
        if @data.bigMonsters>0
            @data.bigMonsters -= 1
            @optimizeRemoval(unitTypes.bigMonster)
    sellHugeMonster: =>
        if @data.hugeMonsters>0
            @data.hugeMonsters -= 1
            @optimizeRemoval(unitTypes.hugeMonster)
    sellAcolyte: =>
        if @data.acolytes+@data.smallAcolytes+@data.bigAcolytes+@data.hugeAcolytes>1
            @data.acolytes -= 1
            @optimizeRemoval(unitTypes.acolyte)
    sellSmallAcolyte: =>
        if @data.acolytes+@data.smallAcolytes+@data.bigAcolytes+@data.hugeAcolytes>1
            @data.smallAcolytes -= 1
            @optimizeRemoval(unitTypes.smallAcolyte)
    sellBigAcolyte: =>
        if @data.acolytes+@data.smallAcolytes+@data.bigAcolytes+@data.hugeAcolytes>1
            @data.bigAcolytes -= 1
            @optimizeRemoval(unitTypes.bigAcolyte)
    sellHugeAcolyte: =>
        if @data.acolytes+@data.smallAcolytes+@data.bigAcolytes+@data.hugeAcolytes>1
            @data.hugeAcolytes -= 1
            @optimizeRemoval(unitTypes.hugeAcolyte)
    upgradeMinions: =>
        if @data.reputation >= @data.minionUpgradeCost
            @data.reputation -= @data.minionUpgradeCost
            @data.minionMultiplier = @data.minionMultiplier*1.2
            @data.minionUpgradeCost = Math.floor(@data.minionUpgradeCost*2*1.2)
    upgradeAcolytes: =>
        if @data.reputation >= @data.acolyteUpgradeCost
            @data.reputation -= @data.acolyteUpgradeCost
            @data.acolyteMultiplier = @data.acolyteMultiplier*1.2
            @data.acolyteUpgradeCost = Math.floor(@data.acolyteUpgradeCost*2*1.2)
    optimizeRemoval: (type) =>
        roomSelected = null
        for room in @data.roomObjects
            if room.occupantType!=type
                continue
            if roomSelected==null and room.population > 0
                roomSelected = room
            else if room.population < roomSelected.population and room.population > 0
                roomSelected = room
        roomSelected.population -= 1
        if type==unitTypes.monster or type==unitTypes.smallMonster or type==unitTypes.bigMonster or type==unitTypes.hugeMonster
            for i in [0..roomSelected.monsters.length-1]
                monster = roomSelected.monsters[i]
                if monster.type==type
                    roomSelected.monsters.splice(i,1)
                    break
        if roomSelected.population == 0
            roomSelected.occupantType = unitTypes.none
    runDungeon: =>
        @narrate('An adventurer arrives!')
        adventurer = new Adventurer()
        done = false
        room = null
        hasTreasure = false
        while !done
            room = @traverseRooms(room)
            if room.occupantType == unitTypes.monster or room.occupantType == unitTypes.smallMonster or room.occupantType == unitTypes.bigMonster or room.occupantType == unitTypes.hugeMonster
                if @encounterMonsters(adventurer,room)
                    return
            else
                for acolyte in room.acolytes
                    acolyte.health = 0
                for minion in room.minions
                    minion.health = 0
            if room == @data.roomObjects[@data.roomObjects.length-1]
                hasTreasure = true
            if hasTreasure and room == @data.roomObjects[0]
                done = true
        if @data.treasure>1
            @data.treasure -= 1
            @narrate('The adventurer has successfully beaten all of your monsters! They take one of your treasures!')
        else
            @narrate('The adventurer finds nothing and leaves.')
    traverseRooms: (room) =>
        if room == null
            return @data.roomObjects[0]
        possibleConnections = []
        for connection in @data.connections
            if room==@data.roomObjects[connection.room]
                possibleConnections.push(connection.room2)
            else if room==@data.roomObjects[connection.room2]
                possibleConnections.push(connection.room)
        rand = possibleConnections[Math.floor(Math.random() * possibleConnections.length)]
        return @data.roomObjects[rand]
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
        @data.adventurers+=1
        @data.treasure+=1
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
        else if room.occupantType == unitTypes.hugeMonster
            type = "huge monsters"
        @narrate('Some of your '+type+' have slain the adventurer! You take their treasure!')
    narrate: (text) =>
        document.getElementById('narrationContainer').innerHTML+='<br>'+text
        document.getElementById('narrationContainer').scrollTop = document.getElementById('narrationContainer').scrollHeight
    allocateRoom: (type) =>
        for room in @data.roomObjects
            if room.occupantType == unitTypes.none
                room.occupantType = type
                room.population += 1
                @addUnitObjectToRoom(room)
                @adjustMaxPopulation(room)
                return true
            else if room.occupantType == type and room.population < room.size
                room.population += 1
                @addUnitObjectToRoom(room)
                @adjustMaxPopulation(room)
                return true
        return false
    addUnitObjectToRoom: (room) =>
        if room.occupantType == unitTypes.monster or room.occupantType == unitTypes.smallMonster or room.occupantType == unitTypes.bigMonster or room.occupantType == unitTypes.hugeMonster
            if room.occupantType == unitTypes.monster
                monster = new Monster()
            else if room.occupantType == unitTypes.smallMonster
                monster = new SmallMonster()
            else if room.occupantType == unitTypes.bigMonster
                monster = new BigMonster()
            else if room.occupantType == unitTypes.hugeMonster
                monster = new HugeMonster()
            @data.monsterObjects[@data.monsters+@data.smallMonsters+@data.bigMonsters+@data.hugeMonsters] = monster
            room.monsters[room.population-1] = monster
        else if room.occupantType == unitTypes.minion or room.occupantType == unitTypes.smallMinion or room.occupantType == unitTypes.bigMinion or room.occupantType == unitTypes.hugeMinion
            if room.occupantType == unitTypes.minion
                minion = new Minion()
            else if room.occupantType == unitTypes.smallMinion
                minion = new SmallMinion()
            else if room.occupantType == unitTypes.bigMinion
                minion = new BigMinion()
            else if room.occupantType == unitTypes.hugeMinion
                minion = new HugeMinion()
            @data.minionObjects[@data.minions+@data.smallMinions+@data.bigMinions+@data.hugeMinions] = minion
            room.minions[room.population-1] = minion
        else if room.occupantType == unitTypes.acolyte or room.occupantType == unitTypes.smallAcolyte or room.occupantType == unitTypes.bigAcolyte or room.occupantType == unitTypes.hugeAcolyte
            if room.occupantType == unitTypes.acolyte
                acolyte = new Acolyte()
            else if room.occupantType == unitTypes.smallAcolyte
                acolyte = new SmallAcolyte()
            else if room.occupantType == unitTypes.bigAcolyte
                acolyte = new BigAcolyte()
            else if room.occupantType == unitTypes.hugeAcolyte
                acolyte = new HugeAcolyte()
            @data.acolyteObjects[@data.acolytes+@data.smallAcolytes+@data.bigAcolytes+@data.hugeAcolytes] = acolyte
            room.acolytes[room.population-1] = acolyte
    adjustMaxPopulation: (room) =>
        if room.occupantType == unitTypes.smallMinion or room.occupantType == unitTypes.smallMonster or room.occupantType == unitTypes.smallAcolyte
            room.size = 10
        else if room.occupantType == unitTypes.bigMinion or room.occupantType == unitTypes.bigMonster or room.occupantType == unitTypes.bigAcolyte
            room.size = 2
        else if room.occupantType == unitTypes.hugeMinion or room.occupantType == unitTypes.hugeMonster or room.occupantType == unitTypes.hugeAcolyte
            room.size = 1
        else
            room.size = 5
    digRoom: =>
        result = false
        while result==false
            [x,y,facing] = @pickRandomWall()
            [result,boundaries] = @data.map.excavate(x,y,facing)
        return boundaries
    pickRandomWall: =>
        facing = null
        while facing==null
            x = Math.floor(Math.random()*(@data.map.sizeX-(@data.map.border*2)-1))+@data.map.border
            y = Math.floor(Math.random()*(@data.map.sizeY-(@data.map.border*2)-1))+@data.map.border
            facing = @checkForEmptySpace(x,y)
        return [x,y,facing]
    checkForEmptySpace: (x,y) =>
        if @data.map.tiles[x][y+1]==' '
            return 2
        if @data.map.tiles[x-1][y]==' '
            return 3
        if @data.map.tiles[x][y-1]==' '
            return 0
        if @data.map.tiles[x+1][y]==' '
            return 1
        return null
    formRoomConnections: =>
        @data.connections = []
        for i in [0..@data.roomObjects.length-1]
            for j in [0..@data.roomObjects.length-1]
                room = @data.roomObjects[i]
                room2 = @data.roomObjects[j]
                if @roomsConnected(room,room2)
                    obj = new RoomConnection
                    obj.room = i
                    obj.room2 = j
                    if !@checkIfConnectionExists(obj)
                        @data.connections.push(obj)
    roomsConnected: (room, room2) =>
        if room==room2
            return false
        if !@roomsAdjacent(room,room2)
            return false
        doorLocations = @findDoors(room)
        if @checkDoorAdjacency(doorLocations,room2)
            return true
        return false
    findDoors: (room) =>
        results = []
        #check left side
        x = room.boundaries[0]-1
        for y in [room.boundaries[1]..room.boundaries[3]]
            if @data.map.tiles[x][y]==' '
                results.push([x,y])
        #check right side
        x = room.boundaries[2]+1
        for y in [room.boundaries[1]..room.boundaries[3]]
            if @data.map.tiles[x][y]==' '
                results.push([x,y])
        #check top
        y = room.boundaries[1]-1
        for x in [room.boundaries[0]..room.boundaries[2]]
            if @data.map.tiles[x][y]==' '
                results.push([x,y])
        #check bottom
        y = room.boundaries[3]+1
        for x in [room.boundaries[0]..room.boundaries[2]]
            if @data.map.tiles[x][y]==' '
                results.push([x,y])
        return results
    checkDoorAdjacency: (doorLocations,room2) =>
        for coords in doorLocations
            [x,y] = coords
            #check left side
            x2 = room2.boundaries[0]-1
            for y2 in [room2.boundaries[1]..room2.boundaries[3]]
                if x==x2 and y==y2
                    return true
            #check right side
            x2 = room2.boundaries[2]+1
            for y2 in [room2.boundaries[1]..room2.boundaries[3]]
                if x==x2 and y==y2
                    return true
            #check top
            y2 = room2.boundaries[1]-1
            for x2 in [room2.boundaries[0]..room2.boundaries[2]]
                if x==x2 and y==y2
                    return true
            #check bottom
            y2 = room2.boundaries[3]+1
            for x2 in [room2.boundaries[0]..room2.boundaries[2]]
                if x==x2 and y==y2
                    return true
        return false
    roomsAdjacent: (room,room2) =>
        #check left side
        x = room.boundaries[0]-2
        for y in [room.boundaries[1]..room.boundaries[3]]
            if x==room2.boundaries[2] and y>=room2.boundaries[1] and y<=room2.boundaries[3]
                return true
        #check right side
        x = room.boundaries[2]+2
        for y in [room.boundaries[1]..room.boundaries[3]]
            if x==room2.boundaries[0] and y>=room2.boundaries[1] and y<=room2.boundaries[3]
                return true
        #check top
        y = room.boundaries[1]-2
        for x in [room.boundaries[0]..room.boundaries[2]]
            if y==room2.boundaries[3] and x>=room2.boundaries[0] and x<=room2.boundaries[2]
                return true
        #check bottom
        y = room.boundaries[3]+2
        for x in [room.boundaries[0]..room.boundaries[2]]
            if y==room2.boundaries[1] and x>=room2.boundaries[0] and x<=room2.boundaries[2]
                return true
        return false
    checkIfConnectionExists: (obj) =>
        for connection in @data.connections
            if connection.room==obj.room and connection.room2==obj.room2
                return true
            else if connection.room2==obj.room and connection.room2==obj.room
                return true
        return false
class DungeonData
    
app.controller 'main', ($scope, dungeon, $rootScope, $cookies) ->
    $scope.cookies = $cookies
    $scope.dungeon = dungeon
    $scope.reputation = 0
    $scope.reputationRate = 0
    $scope.minions = 0
    $scope.smallMinions = 0
    $scope.bigMinions = 0
    $scope.hugeMinions = 0
    $scope.buyAllMinionsText = ""
    $scope.buyAllSmallMinionsText = ""
    $scope.buyAllBigMinionsText = ""
    $scope.buyAllHugeMinionsText = ""
    $scope.population = 0
    $scope.maxPopulation = 0
    $scope.roomProgressPercent = 0
    $scope.roomProgressPercentRounded = 0
    $scope.unitProgressPercent = 0
    $scope.unitProgressPercentRounded = 0
    $scope.smallUnitProgressPercent = 0
    $scope.smallUnitProgressPercentRounded = 0
    $scope.bigUnitProgressPercent = 0
    $scope.bigUnitProgressPercentRounded = 0
    $scope.hugeUnitProgressPercent = 0
    $scope.hugeUnitProgressPercentRounded = 0
    $scope.minionUpgradeProgressPercent = 0
    $scope.minionUpgradeProgressPercentRounded = 0
    $scope.acolyteUpgradeProgressPercent = 0
    $scope.acolyteUpgradeProgressPercentRounded = 0
    $scope.rooms = 0
    $scope.alerts = []
    $scope.roomETA = ""
    $scope.unitETA = ""
    $scope.smallUnitETA = ""
    $scope.bigUnitETA = ""
    $scope.hugeUnitETA = ""
    $scope.minionUpgradeETA = ""
    $scope.acolyteUpgradeETA = ""
    $scope.monsters = 0
    $scope.smallMonsters = 0
    $scope.bigMonsters = 0
    $scope.hugeMonsters = 0
    $scope.monstersActive = 0
    $scope.buyAllMonstersText = ""
    $scope.buyAllSmallMonstersText = ""
    $scope.BuyAllBigMonstersText = ""
    $scope.BuyAllHugeMonstersText = ""
    $scope.acolytes = 0
    $scope.smallAcolytes = 0
    $scope.bigAcolytes = 0
    $scope.hugeAcolytes = 0
    $scope.buyAllAcolytesText = ""
    $scope.buyAllSmallAcolytesText = ""
    $scope.buyAllBigAcolytesText = ""
    $scope.buyAllHugeAcolytesText = ""
    $scope.adventurers = 0
    $scope.treasure = 0
    $scope.upgradeMinionsText = ""
    $scope.upgradeAcolytesText = ""
    $scope.emptyRooms = 0
    $scope.devMultiplier = 1
    $scope.skipDays = 0
    $scope.skipHours = 0
    $scope.skipMinutes = 0
    $scope.enableNarration = true
    $scope.enableAlerts = true
    $scope.$watch 'dungeon.data.reputation', (newVal) ->
        $scope.reputation = Math.floor(newVal)
        $scope.buyAllMinionsText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.minion})"
        $scope.buyAllSmallMinionsText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.smallMinion})"
        $scope.buyAllBigMinionsText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.bigMinion})"
        $scope.buyAllHugeMinionsText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.hugeMinion})"
        $scope.buyAllMonstersText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.monster})"
        $scope.buyAllSmallMonstersText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.smallMonster})"
        $scope.buyAllBigMonstersText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.bigMonster})"
        $scope.buyAllHugeMonstersText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.hugeMonster})"
        $scope.buyAllAcolytesText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.acolyte})"
        $scope.buyAllSmallAcolytesText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.smallAcolyte})"
        $scope.buyAllBigAcolytesText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.bigAcolyte})"
        $scope.buyAllHugeAcolytesText = "Buy All (#{dungeon.maxNumberToBuy unitTypes.hugeAcolyte})"
    $scope.$watch 'dungeon.reputationRate()', (newVal) ->
        $scope.reputationRate = newVal
    $scope.$watch 'dungeon.data.minions', (newVal) ->
        $scope.minions = newVal
    $scope.$watch 'dungeon.data.smallMinions', (newVal) ->
        $scope.smallMinions = newVal
    $scope.$watch 'dungeon.data.bigMinions', (newVal) ->
        $scope.bigMinions = newVal
    $scope.$watch 'dungeon.data.hugeMinions', (newVal) ->
        $scope.hugeMinions = newVal
    $scope.$watch 'dungeon.totalPopulation()', (newVal) ->
        $scope.population = newVal
    $scope.$watch 'dungeon.maxPopulation()', (newVal) ->
        $scope.maxPopulation = newVal
    $scope.$watch 'dungeon.roomProgressPercent()', (newVal) ->
        $scope.roomProgressPercent = newVal
        $scope.roomProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.unitProgressPercent()', (newVal) ->
        $scope.unitProgressPercent = newVal
        $scope.unitProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.smallUnitProgressPercent()', (newVal) ->
        $scope.smallUnitProgressPercent = newVal
        $scope.smallUnitProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.bigUnitProgressPercent()', (newVal) ->
        $scope.bigUnitProgressPercent = newVal
        $scope.bigUnitProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.hugeUnitProgressPercent()', (newVal) ->
        $scope.hugeUnitProgressPercent = newVal
        $scope.hugeUnitProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.minionUpgradeProgressPercent()', (newVal) ->
        $scope.minionUpgradeProgressPercent = newVal
        $scope.minionUpgradeProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.acolyteUpgradeProgressPercent()', (newVal) ->
        $scope.acolyteUpgradeProgressPercent = newVal
        $scope.acolyteUpgradeProgressPercentRounded = Math.floor(newVal)        
    $scope.$watch 'dungeon.data.rooms', (newVal) ->
        $scope.rooms = newVal
        if $scope.rooms > 5 and $scope.enableAlerts==true
            $scope.alerts.push({type: 'success', msg: 'Room constructed!', expired: "false"})
    $scope.$watch 'dungeon.roomETA()', (newVal) ->
        $scope.roomETA = newVal
    $scope.$watch 'dungeon.unitETA()', (newVal) ->
        $scope.unitETA = newVal
    $scope.$watch 'dungeon.smallUnitETA()', (newVal) ->
        $scope.smallUnitETA = newVal
    $scope.$watch 'dungeon.bigUnitETA()', (newVal) ->
        $scope.bigUnitETA = newVal
    $scope.$watch 'dungeon.hugeUnitETA()', (newVal) ->
        $scope.hugeUnitETA = newVal
    $scope.$watch 'dungeon.minionUpgradeETA()', (newVal) ->
        $scope.minionUpgradeETA = newVal
    $scope.$watch 'dungeon.acolyteUpgradeETA()', (newVal) ->
        $scope.acolyteUpgradeETA = newVal
    $scope.$watch 'dungeon.data.monsters', (newVal) ->
        $scope.monsters = newVal
    $scope.$watch 'dungeon.data.smallMonsters', (newVal) ->
        $scope.smallMonsters = newVal
    $scope.$watch 'dungeon.data.bigMonsters', (newVal) ->
        $scope.bigMonsters = newVal
    $scope.$watch 'dungeon.data.hugeMonsters', (newVal) ->
        $scope.hugeMonsters = newVal
    $scope.$watch 'dungeon.monstersActive()', (newVal) ->
        $scope.monstersActive = newVal
    $scope.$watch 'dungeon.data.acolytes', (newVal) ->
        $scope.acolytes = newVal
    $scope.$watch 'dungeon.data.smallAcolytes', (newVal) ->
        $scope.smallAcolytes = newVal
    $scope.$watch 'dungeon.data.bigAcolytes', (newVal) ->
        $scope.bigAcolytes = newVal
    $scope.$watch 'dungeon.data.hugeAcolytes', (newVal) ->
        $scope.hugeAcolytes = newVal
    $scope.$watch 'dungeon.data.adventurers', (newVal) ->
        $scope.adventurers = newVal
    $scope.$watch 'dungeon.data.treasure', (newVal) ->
        $scope.treasure = newVal
    $scope.$watch 'dungeon.upgradeMinionsText()', (newVal) ->
        $scope.upgradeMinionsText = newVal
    $scope.$watch 'dungeon.upgradeAcolytesText()', (newVal) ->
        $scope.upgradeAcolytesText = newVal
    $scope.$watch 'dungeon.emptyRooms()', (newVal) ->
        $scope.emptyRooms = newVal
    $scope.closeAlert = (index) ->
        if $scope.alerts[index]!=undefined
            $scope.alerts[index].expired = "true"
            setTimeout (->
                $scope.alerts.splice(index,1)
                return
            ), 500
    $scope.setDevMultiplier = ->
        $scope.dungeon.data.devMultiplier = @devMultiplier
    $scope.timeSkip = ->
        days = @skipDays
        hours = (days*24) + @skipHours
        minutes = (hours*60) + @skipMinutes
        seconds = minutes * 60
        ticks = seconds * 10
        console.log(ticks)
        @dungeon.data.devMultiplier *= ticks
        @dungeon.updateValuesNoApply()
        @dungeon.data.devMultiplier /= ticks
        for i in [1..ticks]
            console.log(i,ticks)
            for monster in @dungeon.data.monsterObjects
                for j in [0..@dungeon.data.devMultiplier-1]
                    monster.tick()
    $scope.toggleNarrationBox = ->
        if @enableNarration == true
            $('#narrationContainer').hide()
            @enableNarration = false
        else if @enableNarration == false
            $('#narrationContainer').show()
            @enableNarration = true
    $scope.toggleAlerts = ->
        if @enableAlerts == true
            $scope.enableAlerts = false
        else if @enableAlerts == false
            $scope.enableAlerts = true
    $scope.wipeOutSaveFile = ->
        console.log('deleting save')
        localStorage.removeItem('dungeon')
    $rootScope.save = ->
        console.log('saving')
        obj = window.simulator.data
        serialized = JSON.stringify(obj)
        localStorage.setItem('dungeon',serialized)
        if $scope.enableAlerts==true
            $scope.alerts.push({type: 'success', msg: 'Game saved!', expired: "false"})
    $rootScope.load = ->
        console.log('attempting to load')
        obj = localStorage.getItem('dungeon')
        if obj!= null
            obj = JSON.parse(obj)
            console.log('loading')
            for i in [0..obj.monsterObjects.length-1]
                monster = obj.monsterObjects[i]
                newMob = null
                if monster.type == unitTypes.smallMonster
                    newMob = new SmallMonster()
                else if monster.type == unitTypes.monster
                    newMob = new Monster()
                else if monster.type == unitTypes.bigMonster
                    newMob = new BigMonster()
                else if monster.type == unitTypes.hugeMonster
                    newMob = new HugeMonster()
                if newMob!=null
                    newMob.maxHealth = monster.maxHealth
                    newMob.health = monster.health
                    newMob.hp = monster.hp
                    newMob.maxHp = monster.maxHp
                    newMob.xp = monster.xp
                    newMob.level = monster.level
                    newMob.damage = monster.damage
                    newMob.type = monster.type
                    newMob.uuid = monster.uuid
                    for room in obj.roomObjects
                        for j in [0..room.monsters.length-1]
                            monster2 = room.monsters[j]
                            # if monster2!=undefined and monster2!=null
                                # console.log(monster.uuid,monster2.uuid)
                            if monster2!=undefined and monster2!=null and monster.uuid==monster2.uuid
                                room.monsters[j]=newMob
                    obj.monsterObjects[i] = newMob
                        
            newMap = new Map()
            newMap.sizeX = obj.map.sizeX
            newMap.sizeY = obj.map.sizeY
            newMap.roomDimensions = obj.map.roomDimensions
            newMap.tiles = obj.map.tiles
            newMap.border = obj.map.border
            obj.map = newMap
            obj.firstTick = true
            obj.lastTickTime = moment().valueOf()
            window.simulator.data = obj
            window.simulator.formRoomConnections()
            $rootScope.save()
    $rootScope.load()
# app.directive 'tab', ->
    # {
        # restrict: 'E'
        # transclude: true
        # template: '<div role="tabpanel" class="tabContents" ng-show="active" ng-transclude></div>'
        # require: '^tabset'
        # scope: { heading: '@' }
        # link: (scope, elem, attr, tabsetCtrl) ->
            # scope.active = false
            # console.log(tabsetCtrl)
            # tabsetCtrl.addTab(scope)
    # }
# app.directive 'tabset', ->
    # {
        # restrict: 'E'
        # transclude: true
        # scope: {}
        # templateUrl: 'tabset.html'
        # bindToController: true
        # controllerAs: 'tabset'
        # controller: ->
            # @tabs = []
            # @addTab = (tab) ->
                # @tabs.push tab
                # if @tabs.length == 1
                    # tab.active = true
                # return
            # @select = (selectedTab) ->
                # for tab in @tabs
                    # if tab.active  and tab != selectedTab
                        # tab.active = false
                # selectedTab.active = true
                # return
            # return
    # }

class Monster
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @hp = 15
        @maxHp = 15
        @xp = 0
        @level = 1
        @damage = 0
        @uuid = guid()
        @type = unitTypes.monster
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
        @type = unitTypes.smallMonster
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
        @type = unitTypes.bigMonster
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
class HugeMonster extends Monster
    constructor: ->
        super()
        @hp = 240
        @maxHp = 240
        @damage = 90
        @type = unitTypes.hugeMonster
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                window.simulator.narrate('One of your monsters has recovered.')
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 10) + 1)
            if roll==10
                @hp += 1
    levelUp: =>
        @level += 1
        window.simulator.narrate('One of your huge monsters has attained level '+@level.toString()+'!')
        @hp += 28
        @maxHp += 28
        @damage += 1
class Minion
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @labor = 16
class SmallMinion extends Minion
    constructor: ->
        super()
        @labor = 1
class BigMinion extends Minion
    constructor: ->
        super()
        @labor = 256
class HugeMinion extends Minion
    constructor: ->
        super()
        @labor = 4096
class Acolyte
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @reputation = 16
class SmallAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 1
class BigAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 256
class HugeAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 4096
class Adventurer
    constructor: ->
        @hp = 13
class Room
    constructor: ->
        @population = 0
        @size = 5
        @occupantType = unitTypes.none
        @monsters = []
        @minions = []
        @acolytes = []
        @boundaries = []
class Map
    constructor: ->
        @sizeX = 64
        @sizeY = 64
        @roomDimensions=5
        @tiles = []
        @border = 1
        @initFillMap()
        @initialRoomBoundaries = @digInitialRoom()
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
        return [rollX,rollY,rollX+@roomDimensions-1,rollY+@roomDimensions-1]
    excavate: (x,y,facing) ->
        [xStep,yStep] = @determineStep(facing)
        [xMax,yMax] = @determineBounds(x,y,xStep,yStep,facing)
        if facing==0 or facing==2 #bottom, top
            xStart=x
            yStart=y+yStep
        else if facing==1 or facing==3 #left, right
            xStart=x+xStep
            yStart=y
        for i in [xStart-xStep..xMax+xStep] by xStep
            for j in [yStart-yStep..yMax+yStep] by yStep
                if @tiles[i]==undefined
                    return [false,undefined]
                if @tiles[i][j]!='W'
                    return [false,undefined]
        [x,y]=@excavateDoor(x,y,xStep,yStep,facing)
        for i in [x..xMax] by xStep
            for j in [y..yMax] by yStep
                @tiles[i][j]=' '
        return [true,[Math.min(x,xMax),Math.min(y,yMax),Math.max(x,xMax),Math.max(y,yMax)]]
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
class RoomConnection
    @room = -1
    @room2 = -1
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
    hugeMinion: 9
    hugeMonster: 10
    hugeAcolyte: 11
guid = ->
    s4 = ->
        Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
    s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()