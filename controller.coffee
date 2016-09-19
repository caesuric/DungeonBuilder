CanvasInitializer=
    initCanvas: ->
        document.viewSize = 768
        mainCanvasContainer = document.getElementById('mainCanvasContainer')
        mainCanvasContainer.style.width = @viewSize
        mainCanvasContainer.style.height = @viewSize
        document.canvas = new fabric.Canvas('mainCanvas', {width: @viewSize, height: @viewSize})
        document.canvas.backgroundColor="black"
        document.canvas.selection = false
        document.canvas.stateful = false
        document.canvas.renderOnAddRemove = false
        document.canvas.skipTargetFind = true
        document.canvas.renderAll()

app = angular.module('dungeonBuilder', ['ui.bootstrap', 'ngCookies', 'ngAnimate','angular-svg-round-progressbar'])

app.directive 'ngRightClick', ($parse) ->
    (scope, element, attrs) ->
        fn = $parse(attrs.ngRightClick)
        console.log(fn)
        element.bind 'contextmenu', (event) ->
            scope.$apply ->
                event.preventDefault()
                fn scope, $event: event
                return
            return
        return
app.service 'dungeon', class Dungeon
    constructor: ($rootScope) ->
        document.simulator = this
        document.rootScope = $rootScope
        @data = new DungeonData()
        @data.dungeonLevel = 1
        @data.dungeonOpen = true
        @data.totalReputationEarned = 0
        @data.currentTierReputation = 0
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
        @data.rooms = 6
        @data.roomObjects = []
        @data.roomObjects[0] = new Room()
        @data.roomObjects[0].population = 5
        @data.roomObjects[0].size = 10
        @data.roomObjects[0].occupantType = unitTypes.smallMonster
        @data.roomObjects[0].population = 5
        for i in [0..@data.smallMonsters-1]
            @data.roomObjects[0].monsters[i] = @data.monsterObjects[i]
        @data.roomObjects[1] = new Room()
        @data.roomObjects[1].population = 5
        @data.roomObjects[1].size = 10
        @data.roomObjects[1].occupantType = unitTypes.smallMinion
        for i in [0..@data.smallMinions-1]
            @data.roomObjects[1].minions[i] = @data.minionObjects[i]
        @data.roomObjects[2] = new Room()
        @data.roomObjects[2].occupantType = unitTypes.smallAcolyte
        @data.roomObjects[2].population = 5
        @data.roomObjects[2].size = 10
        for i in [0..@data.smallAcolytes-1]
            @data.roomObjects[2].acolytes[i] = @data.acolyteObjects[i]
        @data.roomObjects[3] = new Room()
        @data.roomObjects[4] = new Room()
        @data.roomObjects[5] = new Room()
        @data.roomObjects[5].occupantType = unitTypes.treasure

        @data.map = new Map()
        @data.roomObjects[0].boundaries = @data.map.initialRoomBoundaries
        for i in [1..5]
            @data.roomObjects[i].boundaries = @digRoom()
        @formRoomConnections()
        @data.adventurers = 0
        @data.reputation = 0
        @data.devMultiplier = 1
        @data.minionMultiplier = 1
        @data.acolyteMultiplier = 1
        @data.monsterXPMultiplier = 1
        @data.minionUpgradeCost = Math.floor(15000*0.2)
        @data.minionUpgradeNumber = 1
        @data.acolyteUpgradeCost = Math.floor(15000*0.2)
        @data.acolyteUpgradeNumber = 1
        @data.monsterUpgradeCost = Math.floor(15000*0.2)
        @data.monsterUpgradeNumber = 1
        @data.unitCombatMultiplier = 1
        @data.unitCombatUpgradeCost = Math.floor(15000*0.2)
        @data.unitCombatUpgradeNumber = 1
        @data.killBonus = 0
        @data.killBonusUpgradeCost = Math.floor(15000*0.2)
        @data.killBonusUpgradeNumber = 1
        @data.cost = 4000
        @data.adventurerMultiplier = 1
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
            for i in [1..@data.devMultiplier]
                @minionTick(minion)
        for acolyte in @data.acolyteObjects
            for i in [1..@data.devMultiplier]
                @acolyteTick(acolyte)
        @updateValues()
        @updateRoomBox()
        for monster in @data.monsterObjects
            for i in [1..@data.devMultiplier]
                monster.tick()
        if @data.firstTick
            @updateRoomCanvas()
            @data.firstTick = false
        if @tickCount == 600
            @tickCount = 0
            @megaTick()
    megaTick: =>
        document.rootScope.save()
    acolyteTick: (acolyte) =>
        if acolyte.health<acolyte.maxHealth
            acolyte.health+=1
            if acolyte.health==acolyte.maxHealth
                @narrate('One of your '+@unitName(acolyte.type)+'s has recovered.')
                @updateRoomCanvas()
        if acolyte.health>=acolyte.maxHealth
            rep = acolyte.reputation * @data.devMultiplier * @data.acolyteMultiplier
            @data.reputation += rep
            @data.totalReputationEarned += rep
            @data.currentTierReputation += rep
    minionTick: (minion) =>
        if minion.health<minion.maxHealth
            minion.health+=1
            if minion.health==minion.maxHealth
                @narrate('One of your '+@unitName(minion.type)+'s has recovered.')
                @updateRoomCanvas()
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
        if @data.currentTierReputation >= nextTierReputation[@data.dungeonLevel-1]
            @data.currentTierReputation -= nextTierReputation[@data.dungeonLevel-1]
            @data.dungeonLevel += 1
            @narrate("Your dungeon's level has increased to "+@data.dungeonLevel.toString()+"!")
        for i in [0..Math.floor(@data.treasure*@data.devMultiplier)-1]
            adventurerRoll = Math.floor((Math.random() * Math.floor(14500/@data.adventurerMultiplier)) + 1)
            if adventurerRoll == Math.floor(14500/@data.adventurerMultiplier) and @data.dungeonOpen
                @runDungeon()
        document.rootScope.$apply()
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
    monsterUpgradeProgressPercent: =>
        if @data.reputation >= @data.monsterUpgradeCost
            return '100'
        return (@data.reputation/@data.monsterUpgradeCost*100).toString()
    unitCombatUpgradeProgressPercent: =>
        if @data.reputation >= @data.unitCombatUpgradeCost
            return '100'
        return (@data.reputation/@data.unitCombatUpgradeCost*100).toString()
    killBonusUpgradeProgressPercent: =>
        if @data.reputation >= @data.killBonusUpgradeCost
            return '100'
        return (@data.reputation/@data.killBonusUpgradeCost*100).toString()

    tierProgressPercent: =>
        if @data.currentTierReputation >= nextTierReputation[@data.dungeonLevel-1]
            return '100'
        return (@data.currentTierReputation/nextTierReputation[@data.dungeonLevel-1]*100).toString()
    updateRoomBox: =>
        # text = "Room Summary:<br><br>"
        # for i in [0..@data.rooms-1]
            # room = @data.roomObjects[i]
            # text += "Room "+(i+1).toString()+":<br>Contains "
            # name = @unitName(room.occupantType)
            # text += name
            # if name!='nothing' and name!= 'treasure'
                # text += 's'
            # text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        # document.getElementById('roomsPanel').innerHTML = text
    upgradeMinionsText: =>
        return "Upgrade Minions #{@data.minionUpgradeNumber} (#{humanize(@data.minionUpgradeCost)} reputation). Upgrading minions increases their effectiveness by 20%"
    upgradeAcolytesText: =>
        return "Upgrade Acolytes #{@data.acolyteUpgradeNumber} (#{humanize(@data.acolyteUpgradeCost)} reputation). Upgrading acolytes increases their effectiveness by 20%"
    upgradeMonstersText: =>
        return "Upgrade Monsters #{@data.monsterUpgradeNumber} (#{humanize(@data.monsterUpgradeCost)} reputation). Upgrading monsters increases their leveling speed by 20%"
    upgradeUnitCombatText: =>
        return "Upgrade Acolyte/Minion Combat Ability #{@data.unitCombatUpgradeNumber} (#{humanize(@data.unitCombatUpgradeCost)} reputation). Upgrading increases effectiveness of all non-monster units in combat by 2%"
    upgradeKillBonusText: =>
        return "Upgrade Kill Bonus #{@data.killBonusUpgradeNumber} (#{humanize(@data.killBonusUpgradeCost)} reputation). Upgrading makes killing adventurers grand you reputation! Current bonus per kill: #{humanize(@data.killBonus)} if killed by a small unit. #{humanize(@data.killBonus*16)} if killed by a normal unit. #{humanize(@data.killBonus*256)} if killed by a big unit. #{humanize(@data.killBonus*4096)} if killed by a huge unit"
    humanizeETA: (eta) =>
        duration = moment.duration(eta*100) # Setting in milliseconds
        moment_time = duration.humanize()
        specific = ""
        specific += "#{duration.years()}y" if duration.years() > 0
        specific += "#{duration.months()}M" if duration.months() > 0
        specific += "#{duration.days()}d" if duration.days() > 0
        specific += "#{duration.hours()}h" if duration.hours() > 0
        specific += "#{duration.minutes()}m" if duration.minutes() > 0
        specific += "#{duration.seconds()}s" if duration.seconds() > 0
        if specific == "" and eta!=0
            specific +="0s"
        return specific
    roomETA: =>
        remaining = @roomCost() - @data.roomProgress
        rate = ((@data.smallMinions)+(@data.minions*16)+(@data.bigMinions*256)+(@data.hugeMinions*4096)) * @data.devMultiplier * @data.minionMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    unitETA: =>
        if @data.reputation > @data.cost
            remaining = 0
        else
            remaining = @data.cost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    smallUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*0.09375)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*0.09375) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    bigUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*119.42)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*119.42) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    hugeUnitETA: =>
        if @data.reputation > Math.floor(@data.cost*17752.88)
            remaining = 0
        else
            remaining = Math.floor(@data.cost*17752.88) - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    minionUpgradeETA: =>
        if @data.reputation > @data.minionUpgradeCost
            remaining = 0
        else
            remaining = @data.minionUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    acolyteUpgradeETA: =>
        if @data.reputation > @data.acolyteUpgradeCost
            remaining = 0
        else
            remaining = @data.acolyteUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    monsterUpgradeETA: =>
        if @data.reputation > @data.monsterUpgradeCost
            remaining = 0
        else
            remaining = @data.monsterUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    unitCombatUpgradeETA: =>
        if @data.reputation > @data.unitCombatUpgradeCost
            remaining = 0
        else
            remaining = @data.unitCombatUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    killBonusUpgradeETA: =>
        if @data.reputation > @data.killBonusUpgradeCost
            remaining = 0
        else
            remaining = @data.killBonusUpgradeCost - @data.reputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    tierETA: =>
        if @data.currentTierReputation > nextTierReputation[@data.dungeonLevel-1]
            remaining = 0
        else
            remaining = nextTierReputation[@data.dungeonLevel-1] - @data.currentTierReputation
        rate = ((@data.smallAcolytes)+(@data.acolytes*16)+(@data.bigAcolytes*256)+(@data.hugeAcolytes*4096)) * @data.devMultiplier * @data.acolyteMultiplier
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)
    recoveryETA: (number) =>
        if number>2400
            remaining = 0
        else
            remaining = 2400-number
        rate = 1
        eta = Math.floor(remaining/rate)
        return @humanizeETA (eta)

    updateProgressBar: (bar, percent) ->
      bar.width("#{percent}%")
      
    updateRoomCanvas: ->
        console.log('updating')
        document.canvas.clear()
        document.canvas.setBackgroundColor('gray')
        for i in [0..@data.map.sizeX-1]
            for j in [0..@data.map.sizeY-1]
                if @data.map.tiles[i][j]==' '
                    document.canvas.add new fabric.Rect(left: (i*12), top: (j*12), height: 12, width: 12, stroke: 'black', fill: 'black', strokeWidth: 1, selectable: false)
        for i in [0..@data.roomObjects.length-1]
            room = @data.roomObjects[i]
            color = 'white'
            if i==0
                color = 'cyan'
            if room.occupantType == unitTypes.treasure
                color = 'gold'
            document.canvas.add new fabric.Text((i+1).toString(),left: (room.boundaries[0]*12)+30, top: (room.boundaries[1]*12)+30, originX: 'center', originY: 'center', fill: color, fontWeight: 'bold', fontSize: 16, selectable: false)
            [unitRepresentation,color] = @unitCode(@data.roomObjects[i])
            document.canvas.add new fabric.Text(unitRepresentation,left: (room.boundaries[0]*12), top: (room.boundaries[1]*12), originX: 'left', originY: 'top', fill: color, fontWeight: 'bold', fontSize: 16, selectable: false)
        document.canvas.off()
        document.canvas.on 'mouse:move', (options) ->
            document.simulator.roomMouseOver(options)
        document.canvas.on 'mouse:down', (options) ->
            document.simulator.roomMouseDown(options)
        document.canvas.on 'mouse:up', (options) ->
            document.simulator.roomMouseUp(options)
        document.canvas.renderAll()
        
        if @acolyteChart==undefined
            acolyteChartElement = $("#acolyteChart")
            @acolyteChart = new Chart(acolyteChartElement,
                type: 'pie'
                data:
                    labels: [
                        'Small'
                        'Normal'
                        'Big'
                        'Huge'
                    ]
                    datasets: [ {
                        label: 'Reputation Generated'
                        data: [
                            Math.floor(@data.smallAcolytes*10*@data.acolyteMultiplier*@data.devMultiplier)
                            Math.floor(@data.acolytes*160*@data.acolyteMultiplier*@data.devMultiplier)
                            Math.floor(@data.bigAcolytes*2560*@data.acolyteMultiplier*@data.devMultiplier)
                            Math.floor(@data.hugeAcolytes*40960*@data.acolyteMultiplier*@data.devMultiplier)
                        ]
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.2)'
                            'rgba(54, 162, 235, 0.2)'
                            'rgba(255, 206, 86, 0.2)'
                            'rgba(75, 192, 192, 0.2)'
                        ]
                        borderColor: [
                            'rgba(255,99,132,1)'
                            'rgba(54, 162, 235, 1)'
                            'rgba(255, 206, 86, 1)'
                            'rgba(75, 192, 192, 1)'
                        ]
                        borderWidth: 0
                    } ]
                options:
                    title:
                        display: true
                        text: 'Reputation Generated'
                )
            minionChartElement = $("#minionChart")
            @minionChart = new Chart(minionChartElement,
                type: 'pie'
                data:
                    labels: [
                        'Small'
                        'Normal'
                        'Big'
                        'Huge'
                    ]
                    datasets: [ {
                        label: 'Labor Generated'
                        data: [
                            Math.floor(@data.smallMinions*10*@data.minionMultiplier*@data.devMultiplier)
                            Math.floor(@data.minions*160*@data.minionMultiplier*@data.devMultiplier)
                            Math.floor(@data.bigMinions*2560*@data.minionMultiplier*@data.devMultiplier)
                            Math.floor(@data.hugeMinions*40960*@data.minionMultiplier*@data.devMultiplier)
                        ]
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.2)'
                            'rgba(54, 162, 235, 0.2)'
                            'rgba(255, 206, 86, 0.2)'
                            'rgba(75, 192, 192, 0.2)'
                        ]
                        borderColor: [
                            'rgba(255,99,132,1)'
                            'rgba(54, 162, 235, 1)'
                            'rgba(255, 206, 86, 1)'
                            'rgba(75, 192, 192, 1)'
                        ]
                        borderWidth: 0
                    } ]
                options:
                    title:
                        display: true
                        text: 'Labor Generated'
                )
        else
            @acolyteChart.data.datasets[0].data = [
                Math.floor(@data.smallAcolytes*10*@data.acolyteMultiplier*@data.devMultiplier)
                Math.floor(@data.acolytes*160*@data.acolyteMultiplier*@data.devMultiplier)
                Math.floor(@data.bigAcolytes*2560*@data.acolyteMultiplier*@data.devMultiplier)
                Math.floor(@data.hugeAcolytes*40960*@data.acolyteMultiplier*@data.devMultiplier)
            ]
            @acolyteChart.update()
            @minionChart.data.datasets[0].data = [
                Math.floor(@data.smallMinions*10*@data.minionMultiplier*@data.devMultiplier)
                Math.floor(@data.minions*160*@data.minionMultiplier*@data.devMultiplier)
                Math.floor(@data.bigMinions*2560*@data.minionMultiplier*@data.devMultiplier)
                Math.floor(@data.hugeMinions*40960*@data.minionMultiplier*@data.devMultiplier)
            ]
            @minionChart.update()

    unitCode: (room) =>
        occupants = room.occupantType
        if occupants==unitTypes.none
            return ['','black']
        allDisabled = true
        if occupants == unitTypes.smallMinion or occupants == unitTypes.minion or occupants == unitTypes.bigMinion or occupants == unitTypes.hugeMinion
            text='Mi'
            color='yellow'
            for minion in room.minions
                if minion.health>=minion.maxHealth
                    allDisabled = false
                    break
        else if occupants == unitTypes.smallMonster or occupants == unitTypes.monster or occupants == unitTypes.bigMonster or occupants == unitTypes.hugeMonster
            text='Mo'
            color='red'
            for monster in room.monsters
                if monster.health>=monster.maxHealth
                    allDisabled = false
                    break
        else if occupants == unitTypes.smallAcolyte or occupants == unitTypes.acolyte or occupants == unitTypes.bigAcolyte or occupants == unitTypes.hugeAcolyte
            text='A'
            color='cyan'
            for acolyte in room.acolytes
                if acolyte.health>=acolyte.maxHealth
                    allDisabled = false
                    break
        else if occupants == unitTypes.treasure
            return ['Tr','gold']
        if allDisabled
            color='gray'
        if occupants == unitTypes.smallMinion or occupants == unitTypes.smallMonster or occupants == unitTypes.smallAcolyte
            text+='-1'
        else if occupants == unitTypes.minion or occupants == unitTypes.monster or occupants == unitTypes.acolyte
            text+='-2'
        else if occupants == unitTypes.bigMinion or occupants == unitTypes.bigMonster or occupants == unitTypes.bigAcolyte
            text+='-3'
        else if occupants == unitTypes.hugeMinion or occupants == unitTypes.hugeMonster or occupants == unitTypes.hugeAcolyte
            text+='-4'
        text+=' x'
        text+=room.population.toString()
        return [text,color]
    roomMouseOver: (options) ->
        x = options.e.layerX
        y = options.e.layerY
        if @data.dragMode
            if @data.dragBox != null
                document.canvas.remove @data.dragBox
            if @data.dragText != null
                document.canvas.remove @data.dragText
            @data.dragBox = new fabric.Rect(left: x, top: y, height: 60, width: 60, stroke: 'black', fill: 'black', strokeWidth: 1, selectable: false)
            room = @data.roomObjects[@data.dragRoom]
            [unitRepresentation,color] = @unitCode(room)
            @data.dragText = new fabric.Text(unitRepresentation,left: x, top: y, originX: 'left', originY: 'top', fill: color, fontWeight: 'bold', fontSize: 16, selectable: false)
            document.canvas.add @data.dragBox
            document.canvas.add @data.dragText
            document.canvas.renderAll()
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
                    swapAcolytes = @data.roomObjects[@data.dragRoom].acolytes
                    swapMinions = @data.roomObjects[@data.dragRoom].minions
                    @data.roomObjects[@data.dragRoom].population = @data.roomObjects[@data.dropRoom].population
                    @data.roomObjects[@data.dragRoom].size = @data.roomObjects[@data.dropRoom].size
                    @data.roomObjects[@data.dragRoom].occupantType = @data.roomObjects[@data.dropRoom].occupantType
                    @data.roomObjects[@data.dragRoom].monsters = @data.roomObjects[@data.dropRoom].monsters
                    @data.roomObjects[@data.dragRoom].acolytes = @data.roomObjects[@data.dropRoom].acolytes
                    @data.roomObjects[@data.dragRoom].minions = @data.roomObjects[@data.dropRoom].minions
                    @data.roomObjects[@data.dropRoom].population = swapPopulation
                    @data.roomObjects[@data.dropRoom].size = swapSize
                    @data.roomObjects[@data.dropRoom].occupantType = swapOccupantType
                    @data.roomObjects[@data.dropRoom].monsters = swapMonsters
                    @data.roomObjects[@data.dropRoom].acolytes = swapAcolytes
                    @data.roomObjects[@data.dropRoom].minions = swapMinions
                    @updateRoomCanvas()
                return
        @data.dragRoom = null
        @data.dropRoom = null
    displayPopup: (roomIndex,x,y) =>
        div = $('#roomTooltip')
        div.css({left: x+20, top: y-20, visibility: 'visible'})
        text = @getRoomPopupText(roomIndex)
        div.html text
        return
    getRoomPopupText: (roomIndex) =>
        room = @data.roomObjects[roomIndex]
        text = "Room "+(roomIndex+1).toString()+":"
        if roomIndex==0
            text +='<br><span style="color: blue;">Dungeon Entrance</span>'
        text +="<br>Contains "
        name = @unitName(room.occupantType)
        text += name
        if name!='nothing' and name!='treasure'
            text += 's'
        text += ".<br>Population: " + room.population.toString() + "/" + room.size.toString() + "<br><br>"
        text +=@getDisabledText(room)
    hidePopup: =>
        div = $('#roomTooltip')
        div.css({visibility: 'hidden'})
        return
    getDisabledText: (room) =>
        text = ''
        type = room.occupantType
        if type==unitTypes.monster or type==unitTypes.smallMonster or type==unitTypes.bigMonster or type==unitTypes.hugeMonster
            for monster in room.monsters
                if monster.health<monster.maxHealth
                    text += 'Disabled unit: Recovery in '+@recoveryETA(monster.health)+'.<br />'
        else if type==unitTypes.acolyte or type==unitTypes.smallAcolyte or type==unitTypes.bigAcolyte or type==unitTypes.hugeAcolyte
            for acolyte in room.acolytes
                if acolyte.health<acolyte.maxHealth
                    text += 'Disabled unit: Recovery in '+@recoveryETA(acolyte.health)+'.<br />'
        else if type==unitTypes.minion or type==unitTypes.smallMinion or type==unitTypes.bigMinion or type==unitTypes.hugeMinion
            for minion in room.minions
                if minion.health<minion.maxHealth
                    text += 'Disabled unit: Recovery in '+@recoveryETA(minion.health)+'.<br />'
        return text
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
        return (smallUnits*5)+(normalUnits*10)+(bigUnits*25)+(hugeUnits*50)+50
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
            if room.population == 0 and room.occupantType != unitTypes.treasure
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
    upgradeToAcolytes: =>
        if @data.reputation<@data.cost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.acolyte, 5)
        if number == 0
            @sellRoomOfSmallAcolytes()
        number = @calculateRoomCapacityForBuyAll(unitTypes.acolyte, 5)
        if number>0
            for i in [1..number]
                @buyAcolyte()
            @updateRoomCanvas()
    upgradeToBigAcolytes: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation<bigCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigAcolyte, 5)
        if number == 0
            @sellRoomOfAcolytes()
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigAcolyte, 5)
        if number>0
            for i in [1..number]
                @buyBigAcolyte()
            @updateRoomCanvas()
    upgradeToHugeAcolytes: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation<hugeCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeAcolyte, 5)
        if number == 0
            @sellRoomOfBigAcolytes()
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeAcolyte, 5)
        if number>0
            for i in [1..number]
                @buyHugeAcolyte()
            @updateRoomCanvas()
    upgradeToMinions: =>
        if @data.reputation<@data.cost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.minion, 5)
        if number == 0
            @sellRoomOfSmallMinions()
        number = @calculateRoomCapacityForBuyAll(unitTypes.minion, 5)
        if number>0
            for i in [1..number]
                @buyMinion()
            @updateRoomCanvas()
    upgradeToBigMinions: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation<bigCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMinion, 5)
        if number == 0
            @sellRoomOfMinions()
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMinion, 5)
        if number>0
            for i in [1..number]
                @buyBigMinion()
            @updateRoomCanvas()
    upgradeToHugeMinions: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation<hugeCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeMinion, 5)
        if number == 0
            @sellRoomOfBigMinions()
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeMinion, 5)
        if number>0
            for i in [1..number]
                @buyHugeMinion()
            @updateRoomCanvas()
    upgradeToMonsters: =>
        if @data.reputation<@data.cost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.monster, 5)
        if number == 0
            @sellRoomOfSmallMonsters()
        number = @calculateRoomCapacityForBuyAll(unitTypes.monster, 5)
        if number>0
            for i in [1..number]
                @buyMonster()
            @updateRoomCanvas()
    upgradeToBigMonsters: =>
        bigCost = Math.floor(@data.cost*119.42)
        if @data.reputation<bigCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMonster, 5)
        if number == 0
            @sellRoomOfMonsters()
        number = @calculateRoomCapacityForBuyAll(unitTypes.bigMonster, 5)
        if number>0
            for i in [1..number]
                @buyBigMonster()
            @updateRoomCanvas()
    upgradeToHugeMonsters: =>
        hugeCost = Math.floor(@data.cost*17752.88)
        if @data.reputation<hugeCost
            return
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeMonster, 5)
        if number == 0
            @sellRoomOfBigMonsters()
        number = @calculateRoomCapacityForBuyAll(unitTypes.hugeMonster, 5)
        if number>0
            for i in [1..number]
                @buyHugeMonster()
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
            return Math.min(number,@maxNumberToBuy(unitType))
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
            @data.minionUpgradeNumber += 1
            @data.minionMultiplier = @data.minionMultiplier*1.2
            @data.minionUpgradeCost = Math.floor(@data.minionUpgradeCost*2*1.2)
            @updateRoomCanvas()
    upgradeAcolytes: =>
        if @data.reputation >= @data.acolyteUpgradeCost
            @data.reputation -= @data.acolyteUpgradeCost
            @data.acolyteUpgradeNumber += 1
            @data.acolyteMultiplier = @data.acolyteMultiplier*1.2
            @data.acolyteUpgradeCost = Math.floor(@data.acolyteUpgradeCost*2*1.2)
            @updateRoomCanvas()
    upgradeMonsters: =>
        if @data.reputation >= @data.monsterUpgradeCost
            @data.reputation -= @data.monsterUpgradeCost
            @data.monsterUpgradeNumber += 1
            @data.monsterXPMultiplier = @data.monsterXPMultiplier*1.2
            @data.monsterUpgradeCost = Math.floor(@data.monsterUpgradeCost*2*1.2)
            @updateRoomCanvas()
    upgradeUnitCombat: =>
        if @data.reputation >= @data.unitCombatUpgradeCost
            @data.reputation -= @data.unitCombatUpgradeCost
            @data.unitCombatUpgradeNumber += 1
            @data.unitCombatMultiplier = @data.unitCombatMultiplier*1.02
            @data.unitCombatUpgradeCost = Math.floor(@data.unitCombatUpgradeCost*2*1.02)
            for acolyte in @data.acolyteObjects
                acolyte.hp = Math.floor(acolyte.hp*1.02)
                acolyte.maxHp = Math.floor(acolyte.maxHp*1.02)
                acolyte.damage = Math.floor(acolyte.damage*1.02)
            for minion in @data.minionObjects
                minion.hp = Math.floor(minion.hp*1.02)
                minion.maxHp = Math.floor(minion.maxHp*1.02)
                minion.damage = Math.floor(minion.damage*1.02)
            @updateRoomCanvas()
    upgradeKillBonus: =>
        if @data.reputation >= @data.killBonusUpgradeCost
            @data.reputation -= @data.killBonusUpgradeCost
            @data.killBonusUpgradeNumber += 1
            @data.killBonus += 30
            @data.killBonusUpgradeCost = Math.floor(@data.killBonusUpgradeCost*2*1.02)
            @updateRoomCanvas()
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
                    @data.monsterObjects.splice(@data.monsterObjects.indexOf(monster),1)
                    roomSelected.monsters.splice(i,1)
                    break
        else if type==unitTypes.acolyte or type==unitTypes.smallAcolyte or type==unitTypes.bigAcolyte or type==unitTypes.hugeAcolyte
            for i in [0..roomSelected.acolytes.length-1]
                acolyte = roomSelected.acolytes[i]
                if acolyte.type==type
                    @data.acolyteObjects.splice(@data.acolyteObjects.indexOf(acolyte),1)
                    roomSelected.acolytes.splice(i,1)
                    break
        else if type==unitTypes.minion or type==unitTypes.smallMinion or type==unitTypes.bigMinion or type==unitTypes.hugeMinion
            for i in [0..roomSelected.minions.length-1]
                minion = roomSelected.minions[i]
                if minion.type==type
                    @data.minionObjects.splice(@data.minionObjects.indexOf(minion),1)
                    roomSelected.minions.splice(i,1)
                    break
        if roomSelected.population == 0
            roomSelected.occupantType = unitTypes.none
    runDungeon: =>
        @narrate('A level '+@data.dungeonLevel.toString()+' adventurer arrives!')
        adventurer = new Adventurer(@data.dungeonLevel)
        done = false
        room = null
        hasTreasure = false
        while !done
            room = @traverseRooms(room)
            if room.population>0
                if @encounterMonsters(adventurer,room)
                    return
            if room.occupantType == unitTypes.treasure
                hasTreasure = true
            if hasTreasure and room == @data.roomObjects[0]
                done = true
        if @data.treasure>1
            @data.treasure -= 1
            @narrate('The adventurer has successfully escaped with one of your treasures!')
        else
            @narrate('The adventurer finds nothing and leaves.')
    unitName: (type) =>
        switch type
            when unitTypes.smallMinion
                return 'small minion'
            when unitTypes.smallAcolyte
                return 'small acolyte'
            when unitTypes.smallMonster
                return 'small monster'
            when unitTypes.minion
                return 'minion'
            when unitTypes.acolyte
                return 'acolyte'
            when unitTypes.monster
                return 'monster'
            when unitTypes.bigMinion
                return 'big minion'
            when unitTypes.bigAcolyte
                return 'big acolyte'
            when unitTypes.bigMonster
                return 'big monster'
            when unitTypes.hugeMinion
                return 'huge minion'
            when unitTypes.hugeAcolyte
                return 'huge acolyte'
            when unitTypes.hugeMonster
                return 'huge monster'
            when unitTypes.treasure
                return 'treasure'
            else
                return 'nothing'
    unitSize: (type) =>
        switch type
            when unitTypes.smallMinion
                return unitSizes.small
            when unitTypes.smallAcolyte
                return unitSizes.small
            when unitTypes.smallMonster
                return unitSizes.small
            when unitTypes.minion
                return unitSizes.medium
            when unitTypes.acolyte
                return unitSizes.medium
            when unitTypes.monster
                return unitSizes.medium
            when unitTypes.bigMinion
                return unitSizes.big
            when unitTypes.bigAcolyte
                return unitSizes.big
            when unitTypes.bigMonster
                return unitSizes.big
            when unitTypes.hugeMinion
                return unitSizes.huge
            when unitTypes.hugeAcolyte
                return unitSizes.huge
            when unitTypes.hugeMonster
                return unitSizes.huge
            when unitTypes.treasure
                return unitSizes.none
            else
                return unitSizes.none
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
            @defeatAdventurer(room,adventurer)
            return true
        else
            return false
    doCombat: (adventurer, room) =>
        if @anyUnitsActive(room)
            turnRoll = Math.floor((Math.random() * 2) + 1)
            while adventurer.hp>0 and @anyUnitsActive(room)
                if turnRoll==1
                    monster = @unitWithLowestHp(room)
                    if monster!=null
                        monster.hp -= (Math.floor((Math.random() * 8) + 3)*adventurer.damageMultiplier)
                    turnRoll = 2
                    if monster.hp<=0
                        monster.hp = 0
                        monster.health = 0
                        @narrate('One of your '+@unitName(room.occupantType)+'s has been disabled by an adventurer.')
                        @updateRoomCanvas()
                else if turnRoll==2
                    for monster in room.monsters
                        if monster.isActive()
                            adventurer.hp -= Math.max(((Math.floor((Math.random() * 12) + 4) * monster.damage)),1)
                    for acolyte in room.acolytes
                        if acolyte.health>=acolyte.maxHealth
                            adventurer.hp -= Math.max(((Math.floor((Math.random() * 12) + 4) * acolyte.damage)),1)
                    for minion in room.minions
                        if minion.health>=minion.maxHealth
                            adventurer.hp -= Math.max(((Math.floor((Math.random() * 12) + 4) * minion.damage)),1)
                    turnRoll = 1
    anyUnitsActive: (room) =>
        for monster in room.monsters
            if monster.isActive()
                return true
        for acolyte in room.acolytes
            if acolyte.health>=acolyte.maxHealth
                return true
        for minion in room.minions
            if minion.health>=minion.maxHealth
                return true
        return false
    unitWithLowestHp: (room) =>
        lowestHp = 1000000
        monsterSelected = null
        for monster in room.monsters
            if monster.hp<lowestHp and monster.isActive()
                lowestHp = monster.hp
                monsterSelected = monster
        for acolyte in room.acolytes
            if acolyte.hp<lowestHp and acolyte.health>=acolyte.maxHealth
                lowestHp = acolyte.hp
                monsterSelected = acolyte
        for minion in room.minions
            if minion.hp<lowestHp and minion.health>=minion.maxHealth
                lowestHp = minion.hp
                monsterSelected = minion
        return monsterSelected
    numActiveMonsters: (room) =>
        count = 0
        for monster in room.monsters
            if monster.isActive()
                count += 1
        return count
    defeatAdventurer: (room,adventurer) =>
        @data.adventurers+=1
        @data.treasure+=adventurer.level
        killBonus = @data.killBonus * @unitSize(room.occupantType)
        @data.reputation+=killBonus
        xp = Math.floor(100/@numActiveMonsters(room))
        for monster in room.monsters
            if monster.isActive()
                monster.xp += xp * @data.monsterXPMultiplier
                monster.checkForLevelUp()
        @narrate('Some of your '+@unitName(room.occupantType)+'s have slain the adventurer! You take their '+adventurer.level+' treasure!')
        if killBonus>0
            @narrate('You gain '+killBonus+' reputation!')
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
    razeTown: =>
        @data.adventurerMultiplier *= 1.2
        if @data.adventurerMultiplier>14500
            @data.adventurerMultiplier = 14500
    diplomacy: =>
        @data.adventurerMultiplier /= 1.2
    ritual: =>
        @data.reputation += @reputationRate()/10
    disintegrate: =>
        rate = ((@data.smallMinions)+(@data.minions*16)+(@data.bigMinions*256)+(@data.hugeMinions*4096)) * @data.devMultiplier * @data.minionMultiplier
        @data.roomProgress += rate
class DungeonData
    
app.controller 'main', ($scope, dungeon, $rootScope, $cookies, $window) ->
    document.scope = $scope
    $scope.unitsOpen = true
    $scope.dungeonOpen = false
    $scope.narrationOpen = false
    $scope.settingsOpen = false
    $scope.devToolsOpen = false
    $scope.contextMenuOpen = false
    $scope.menuX = 0
    $scope.menuY = 0
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
    $scope.buyRoomOfSmallMinionsText = ""
    $scope.buyRoomOfMinionsText = ""
    $scope.buyRoomOfBigMinionsText = ""
    $scope.buyRoomOfSmallMonstersText = ""
    $scope.buyRoomOfMonstersText = ""
    $scope.buyRoomOfBigMonstersText = ""
    $scope.buyRoomOfSmallAcolytesText = ""
    $scope.buyRoomOfAcolytesText = ""
    $scope.buyRoomOfBigAcolytesText = ""
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
    $scope.monsterUpgradeProgressPercent = 0
    $scope.monsterUpgradeProgressPercentRounded = 0
    $scope.unitCombatUpgradeProgressPercent = 0
    $scope.unitCombatUpgradeProgressPercentRounded = 0
    $scope.killBonusUpgradeProgressPercent = 0
    $scope.killBonusUpgradeProgressPercentRounded = 0
    $scope.rooms = 0
    $scope.alerts = []
    $scope.roomETA = ""
    $scope.unitETA = ""
    $scope.smallUnitETA = ""
    $scope.bigUnitETA = ""
    $scope.hugeUnitETA = ""
    $scope.minionUpgradeETA = ""
    $scope.acolyteUpgradeETA = ""
    $scope.monsterUpgradeETA = ""
    $scope.unitCombatUpgradeETA = ""
    $scope.killBonusUpgradeETA = ""
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
    $scope.upgradeMonstersText = ""
    $scope.upgradeUnitCombatText = ""
    $scope.upgradeKillBonusText = ""
    $scope.emptyRooms = 0
    $scope.devMultiplier = 1
    $scope.skipDays = 0
    $scope.skipHours = 0
    $scope.skipMinutes = 0
    $scope.enableNarration = true
    $scope.enableAlerts = true
    $scope.acolyteMultiplier = 0
    $scope.minionMultiplier = 0
    $scope.monsterXPMultiplier = 0
    $scope.unitCombatMultiplier = 0
    $scope.killBonus = 0
    $scope.dungeonLevel = 0
    $scope.tierProgressPercent = 0
    $scope.tierProgressPercentRounded = 0
    $scope.tierETA = ""
    $scope.closeDungeonText = "Close Dungeon"
    $scope.adventurerMultiplier = 0
    $scope.humanize = humanize
    $scope.$watch 'dungeon.data.reputation', (newVal) ->
        $scope.reputation = humanize(Math.floor(newVal))
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
        $scope.buyRoomOfSmallMinionsText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.smallMinion,10)})"
        $scope.buyRoomOfMinionsText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.minion,5)})"
        $scope.buyRoomOfBigMinionsText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.bigMinion,2)})"
        $scope.buyRoomOfSmallMonstersText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.smallMonster,10)})"
        $scope.buyRoomOfMonstersText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.monster,5)})"
        $scope.buyRoomOfBigMonstersText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.bigMonster,2)})"
        $scope.buyRoomOfSmallAcolytesText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.smallAcolyte,10)})"
        $scope.buyRoomOfAcolytesText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.acolyte,5)})"
        $scope.buyRoomOfBigAcolytesText = "Fill Room (#{dungeon.calculateRoomCapacityForBuyAll(unitTypes.bigAcolyte,2)})"
    $scope.$watch 'dungeon.reputationRate()', (newVal) ->
        $scope.reputationRate = humanize(newVal)
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
    $scope.$watch 'dungeon.monsterUpgradeProgressPercent()', (newVal) ->
        $scope.monsterUpgradeProgressPercent = newVal
        $scope.monsterUpgradeProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.unitCombatUpgradeProgressPercent()', (newVal) ->
        $scope.unitCombatUpgradeProgressPercent = newVal
        $scope.unitCombatUpgradeProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.killBonusUpgradeProgressPercent()', (newVal) ->
        $scope.killBonusUpgradeProgressPercent = newVal
        $scope.killBonusUpgradeProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.data.rooms', (newVal) ->
        $scope.rooms = newVal
        if $scope.rooms > 6 and $scope.enableAlerts==true
            $scope.alerts.push({type: 'success', msg: 'Room constructed!', expired: "false"})
    $scope.$watch 'dungeon.data.dungeonLevel', (newVal) ->
        if $scope.enableAlerts and newVal!=1
            $scope.alerts.push({type: 'danger', msg: 'Your dungeon is now level '+newVal.toString()+'!', expired: "false"})
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
    $scope.$watch 'dungeon.monsterUpgradeETA()', (newVal) ->
        $scope.monsterUpgradeETA = newVal
    $scope.$watch 'dungeon.unitCombatUpgradeETA()', (newVal) ->
        $scope.unitCombatUpgradeETA = newVal
    $scope.$watch 'dungeon.killBonusUpgradeETA()', (newVal) ->
        $scope.killBonusUpgradeETA = newVal
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
    $scope.$watch 'dungeon.upgradeMonstersText()', (newVal) ->
        $scope.upgradeMonstersText = newVal
    $scope.$watch 'dungeon.upgradeUnitCombatText()', (newVal) ->
        $scope.upgradeUnitCombatText = newVal
    $scope.$watch 'dungeon.upgradeKillBonusText()', (newVal) ->
        $scope.upgradeKillBonusText = newVal
    $scope.$watch 'dungeon.emptyRooms()', (newVal) ->
        $scope.emptyRooms = newVal
    $scope.$watch 'dungeon.data.minionMultiplier', (newVal) ->
        $scope.minionMultiplier = Math.floor(newVal*100)
    $scope.$watch 'dungeon.data.acolyteMultiplier', (newVal) ->
        $scope.acolyteMultiplier = Math.floor(newVal*100)
    $scope.$watch 'dungeon.data.monsterXPMultiplier', (newVal) ->
        $scope.monsterXPMultiplier = Math.floor(newVal*100)
    $scope.$watch 'dungeon.data.unitCombatMultiplier', (newVal) ->
        $scope.unitCombatMultiplier = Math.floor(newVal*100)        
    $scope.$watch 'dungeon.data.killBonus', (newVal) ->
        $scope.killBonus = newVal
    $scope.$watch 'dungeon.data.dungeonLevel', (newVal) ->
        $scope.dungeonLevel = newVal
    $scope.$watch 'dungeon.tierProgressPercent()', (newVal) ->
        $scope.tierProgressPercent = newVal
        $scope.tierProgressPercentRounded = Math.floor(newVal)
    $scope.$watch 'dungeon.tierETA()', (newVal) ->
        $scope.tierETA = newVal
    $scope.$watch 'dungeon.data.adventurerMultiplier', (newVal) ->
        $scope.adventurerMultiplier = Math.floor(newVal*100)
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
        for i in [1..ticks]
            @dungeon.updateValuesNoApply()
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
    $scope.closeDungeon = ->
        if @dungeon.data.dungeonOpen == true
            @dungeon.data.dungeonOpen = false
            $scope.alerts.push({type: 'success', msg: 'Dungeon closed!', expired: "false"})
            $scope.closeDungeonText = "Open Dungeon"
        else if @dungeon.data.dungeonOpen == false
            @dungeon.data.dungeonOpen = true
            $scope.alerts.push({type: 'danger', msg: 'Dungeon open for business!', expired: "false"})
            $scope.closeDungeonText = "Close Dungeon"
    $scope.showContextMenu = ($event)->
        $scope.contextMenuOpen = !$scope.contextMenuOpen
        $scope.menuX = $event.pageX
        $scope.menuY = $event.pageY
        $('#dropdownMenu').css('visibility','hidden')
        if $event.currentTarget.id=='smallAcolyteButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllSmallAcolytes()">'+$scope.buyAllSmallAcolytesText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfSmallAcolytes()">'+$scope.buyRoomOfSmallAcolytesText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellSmallAcolyte()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfSmallAcolytes()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='acolyteButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllAcolytes()">'+$scope.buyAllAcolytesText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfAcolytes()">'+$scope.buyRoomOfAcolytesText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellAcolyte()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfAcolytes()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='bigAcolyteButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllBigAcolytes()">'+$scope.buyAllBigAcolytesText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfBigAcolytes()">'+$scope.buyRoomOfBigAcolytesText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellBigAcolyte()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfBigAcolytes()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='hugeAcolyteButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllHugeAcolytes()">'+$scope.buyAllHugeAcolytesText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellHugeAcolyte()">Dismiss One</a></li>')
        else if $event.currentTarget.id=='smallMinionButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllSmallMinions()">'+$scope.buyAllSmallMinionsText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfSmallMinions()">'+$scope.buyRoomOfSmallMinionsText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellSmallMinion()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfSmallMinions()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='minionButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllMinions()">'+$scope.buyAllMinionsText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfMinions()">'+$scope.buyRoomOfMinionsText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellMinion()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfMinions()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='bigMinionButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllBigMinions()">'+$scope.buyAllBigMinionsText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfBigMinions()">'+$scope.buyRoomOfBigMinionsText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellBigMinion()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfBigMinions()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='hugeMinionButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllHugeMinions()">'+$scope.buyAllHugeMinionsText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellHugeMinion()">Dismiss One</a></li>')
        else if $event.currentTarget.id=='smallMonsterButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllSmallMonsters()">'+$scope.buyAllSmallMonstersText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfSmallMonsters()">'+$scope.buyRoomOfSmallMonstersText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellSmallMonster()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfSmallMonsters()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='monsterButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllMonsters()">'+$scope.buyAllMonstersText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfMonsters()">'+$scope.buyRoomOfMonstersText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellMonster()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfMonsters()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='bigMonsterButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllBigMonsters()">'+$scope.buyAllBigMonstersText+'</a></li><li role="menuitem"><a href="#" onclick="document.simulator.buyRoomOfBigMonsters()">'+$scope.buyRoomOfBigMonstersText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellBigMonster()">Dismiss One</a></li><li role="menuitem"><a href="#" onclick="document.simulator.sellRoomOfBigMonsters()">Dismiss Room</a></li>')
        else if $event.currentTarget.id=='hugeMonsterButton'
            $('#dropdownMenu').html('<li role="menuitem"><a href="#" onclick="document.simulator.buyAllHugeMonsters()">'+$scope.buyAllHugeMonstersText+'</a></li><li class="divider"></li><li role="menuitem"><a href="#" onclick="document.simulator.sellHugeMonster()">Dismiss One</a></li>')            
        return
    $scope.dropdownToggle = ->
        setTimeout (->
            $('#dropdownMenu').css('left',$scope.menuX)
            $('#dropdownMenu').css('top',$scope.menuY)
            $('#dropdownMenu').css('visibility','visible')
            return
        ), 1
        return
    $scope.wipeOutSaveFile = ->
        console.log('deleting save')
        localStorage.removeItem('dungeon')
    $rootScope.save = ->
        console.log('saving')
        obj = document.simulator.data
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
                for i in [0..obj.minionObjects.length-1]
                    minion = obj.minionObjects[i]
                    for room in obj.roomObjects
                        if room.minions.length>0
                            for j in [0..room.minions.length-1]
                                if room.minions[j].uuid==minion.uuid
                                    room.minions[j] = minion
                for i in [0..obj.acolyteObjects.length-1]
                    acolyte = obj.acolyteObjects[i]
                    for room in obj.roomObjects
                        if room.acolytes.length>0
                            for j in [0..room.acolytes.length-1]
                                if room.acolytes[j].uuid==acolyte.uuid
                                    room.acolytes[j] = acolyte  
            newMap = new Map()
            newMap.sizeX = obj.map.sizeX
            newMap.sizeY = obj.map.sizeY
            newMap.roomDimensions = obj.map.roomDimensions
            newMap.tiles = obj.map.tiles
            newMap.border = obj.map.border
            obj.map = newMap
            obj.firstTick = true
            obj.lastTickTime = moment().valueOf()
            document.simulator.data = obj
            document.simulator.formRoomConnections()
            $rootScope.save()
    $rootScope.load()
class Monster
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @hp = 64
        @maxHp = 64
        @xp = 0
        @level = 1
        @damage = 1
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
                document.simulator.narrate('One of your monsters has recovered.')
                document.simulator.updateRoomCanvas()
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
        document.simulator.narrate('One of your monsters has attained level '+@level.toString()+'!')
        @hp += 7
        @maxHp += 7
        @damage += 1
class SmallMonster extends Monster
    constructor: ->
        super()
        @hp = 4
        @maxHp = 4
        @damage = 1/16
        @type = unitTypes.smallMonster
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                document.simulator.narrate('One of your small monsters has recovered.')
                document.simulator.updateRoomCanvas()
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 640) + 1)
            if roll==640
                @hp += 1
    levelUp: =>
        @level += 1
        document.simulator.narrate('One of your small monsters has attained level '+@level.toString()+'!')
        @hp += 2
        @maxHp += 2
        @damage += 1
class BigMonster extends Monster
    constructor: ->
        super()
        @hp = 1024
        @maxHp = 1024
        @damage = 16
        @type = unitTypes.bigMonster
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                document.simulator.narrate('One of your big monsters has recovered.')
                document.simulator.updateRoomCanvas()
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 40) + 1)
            if roll==40
                @hp += 1
    levelUp: =>
        @level += 1
        document.simulator.narrate('One of your big monsters has attained level '+@level.toString()+'!')
        @hp += 7
        @maxHp += 7
        @damage += 1
class HugeMonster extends Monster
    constructor: ->
        super()
        @hp = 16384
        @maxHp = 16384
        @damage = 256
        @type = unitTypes.hugeMonster
    tick: =>
        if @health<@maxHealth
            @health += 1
            if @health==@maxHealth
                @hp = @maxHp
                document.simulator.narrate('One of your huge monsters has recovered.')
                document.simulator.updateRoomCanvas()
        if @hp < @maxHp
            roll = Math.floor((Math.random() * 10) + 1)
            if roll==10
                @hp += 1
    levelUp: =>
        @level += 1
        document.simulator.narrate('One of your huge monsters has attained level '+@level.toString()+'!')
        @hp += 28
        @maxHp += 28
        @damage += 1
class Minion
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @labor = 16
        @hp = Math.floor(4*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(4*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1/16*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.minion
        @uuid = guid()
class SmallMinion extends Minion
    constructor: ->
        super()
        @labor = 1
        @hp = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1/256*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.smallMinion
class BigMinion extends Minion
    constructor: ->
        super()
        @labor = 256
        @hp = Math.floor(64*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(64*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.bigMinion
class HugeMinion extends Minion
    constructor: ->
        super()
        @labor = 4096
        @hp = Math.floor(1024*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(1024*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(16*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.hugeMinion
class Acolyte
    constructor: ->
        @maxHealth = 2400
        @health = 2400
        @reputation = 16
        @hp = Math.floor(4*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(4*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1/16*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.acolyte
        @uuid = guid()
class SmallAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 1
        @hp = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1/256*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.smallAcolyte
class BigAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 256
        @hp = Math.floor(64*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(64*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(1*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.bigAcolyte
class HugeAcolyte extends Acolyte
    constructor: ->
        super()
        @reputation = 4096
        @hp = Math.floor(1024*document.simulator.data.unitCombatMultiplier)
        @maxHp = Math.floor(1024*document.simulator.data.unitCombatMultiplier)
        @damage = Math.floor(16*document.simulator.data.unitCombatMultiplier)
        @type = unitTypes.hugeAcolyte
class Adventurer
    constructor: (level) ->
        multiplier = @getMultiplier (level)
        @hp = 13*multiplier
        @damageMultiplier = multiplier
        @level = level
    getMultiplier: (level) ->
        table = [
            1
            2
            3
            4
            5
            6
            8
            10
            12
            15
            18
            22
            27
            33
            40
            48
            58
            70
            84
            101
            122
            147
            177
            213
            256
            307
            369
            443
            532
            639
            767
            921
            1106
            1328
            1594
            1913
            2296
            2756
            3276
            3276
        ]
        return table[level-1]
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
    treasure: 12
unitSizes = 
    none: -1
    small: 1
    medium: 16
    big: 256
    huge: 4096
guid = ->
    s4 = ->
        Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
    s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()
humanize = (num) ->
    if num>1000000000000000
        return (Math.round(num/1000000000000000 * 100) / 100).toString()+'Q'
    else if num>1000000000000
        return (Math.round(num/1000000000000 * 100) / 100).toString()+'T'
    else if num>1000000000
        return (Math.round(num/1000000000 * 100) / 100).toString()+'B'
    else if num>1000000
        return (Math.round(num/1000000 * 100) / 100).toString()+'M'
    else if num>1000
        return (Math.round(num/1000 * 100) / 100).toString()+'k'
    else
        return num.toString()
nextTierReputation = [4500,7300,14700,71600,121207,143400,242414,363621,484828,606035,727242,848450,969657,1090864,1212071,1333279,1454486,1575693,1696900,1818107,1939314,2060521,2181729,2302936,2424143,20854802,41709604,62564406,83419208,104274010,125128813,145983615,166838417,187693219,208548021,229402824,250257626,271112428, 1000000000000000000000000000000000000000000]