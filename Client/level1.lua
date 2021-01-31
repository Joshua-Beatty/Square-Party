-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

crypto = require("crypto")
-- include Corona's "physics" library
local physics = require "physics"
local serverIP = "localhost"
-- serverIP = "178.128.131.201"
local id
local defaultGrav = 5
if system.getInfo("platform") == 'html5' then
  timejs = require "timejs"
  newSeed = timejs.now();
  math.randomseed(newSeed)
  --print(newSeed)
  id = timejs.now()
  --defaultGrav = 15.288
else
  math.randomseed( os.time())
  id = crypto.digest( crypto.md5, system.getTimer()  ..  math.random()   )
end
--print(id)
local yourColor = {math.random(), math.random(), math.random()}
local composer = require( "composer" )
local scene = composer.newScene()


--------------------------------------------
-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local yourPlayer
local speed = 100
local aDown, dDown = false
local grounded = 0
local wDown = false
local function onKeyEvent( event )

  --print( "Key '" .. event.keyName .. "' was pressed " .. event.phase )


  if ( event.keyName == "a" and event.phase == "down") then
    aDown=true
  end 
  if ( event.keyName == "a" and event.phase == "up") then
    aDown=false
  end
  if ( event.keyName == "d" and event.phase == "down") then
    dDown=true
  end 
  if ( event.keyName == "d" and event.phase == "up") then
    dDown=false
  end
  if ( event.keyName == "w" and event.phase == "down") then
    wDown = true
  end
  if ( event.keyName == "w" and event.phase == "up") then
    wDown = false
  end
  if ( event.keyName == "s" and event.phase == "down") then
    physics.setGravity(0, defaultGrav * 4)
    local vx, vy = yourPlayer:getLinearVelocity()
    if(vy < 0) then
    yourPlayer:setLinearVelocity( vx, 0 )
    end
  end
  if ( event.keyName == "s" and event.phase == "up") then
    physics.setGravity(0, defaultGrav)
  end
  return false
end

local hits
local players = {}
local playersTimeMade = {}
local timeCount = 0
local sceneGroup
hubCallback = function(message)
  if(type(message) == "table" and message.user == "host") then
    print(message.data)
    end
  if(type(message) == "table" and message["typeMessage"] == "playerInfo") then
    --if (message.user ~= id) then

      if(players[message.user] == nil) then
        players[message.user] = display.newImageRect( "square.png", 30, 30)
        physics.addBody( players[message.user], { shape ={-14,-14,14,-14,14,14,-14,14},density=1.0, friction=0, bounce=0 })
        players[message.user].x = message.x
        players[message.user].y = message.y
        players[message.user]:setLinearVelocity(message.vel)
        players[message.user].isFixedRotation = true
        players[message.user]:setFillColor(unpack(message.color))
        sceneGroup:insert( players[message.user] )
        playersTimeMade[message.user] = timeCount
      else
        players[message.user].x = message.x
        players[message.user].y = message.y
        players[message.user]:setLinearVelocity(message.vel)
        playersTimeMade[message.user] = timeCount
      end
    --end
  end
end
subscribeCallbackFunc = function()

end
errorCallbackFunc = function()

end
if system.getInfo("platform") == 'html5' then
  hub = require "noobhubwraper"
  hub.init(hubCallback, subscribeCallbackFunc, errorCallbackFunc)
else
  require("noobhub")
  hub = noobhub.new({ server = serverIP; port = 1337; });
  hub:subscribe({
      channel = "game";
      callback = hubCallback;
      errorCallback = errorCallbackFunc;
      subscribedCallback = subscribeCallbackFunc;
    });
end
publish  = function(data) 
  if system.getInfo("platform") == 'html5' then
    hub.publish(data)
  else
    hub:publish({
        message = data
      });
  end
end

local function myListener ( event )
  local vx, vy = yourPlayer:getLinearVelocity()
  if(aDown) then
    vx = -speed
  elseif(dDown) then
    vx = speed
  else 
    vx = 0
  end
  if (grounded > 0 and wDown) then

    vy = -215
    if system.getInfo("platform") == 'html5' then
      --vy = -374.7
    end 
  end
  yourPlayer:setLinearVelocity( vx, vy )
  publish({
      typeMessage = "playerInfo",
      user = id, 
      color = yourColor,
      x = yourPlayer.x,
      y = yourPlayer.y,
      vel = yourPlayer:getLinearVelocity()
    }
  );
  timeCount = timeCount + 1
  for k,v in pairs(playersTimeMade) do
    if(timeCount  - 30 > v) then
      players[k]:removeSelf()
      players[k] = nil
      playersTimeMade[k] = nil
    end
  end

end
local landed = false
local function onLocalCollision( self, event )
  errorMargin = 4
  above = event.target.y + event.target.height - errorMargin < event.other.y
  below =  event.target.y > event.other.y + event.other.height - errorMargin
  onLeft = event.target.x + event.target.width - errorMargin  < event.other.x
  onRight  =  event.target.x > event.other.x + event.other.width  - errorMargin
  if( false ) then
    print("---------------------------------------------------------------------------------------------------------")
    print(event.phase)
    print("Object 1 : X- " .. event.target.x .. " Y- " ..  event.target.y .. " W- " .. event.target.width .. " H- " .. event.target.height )
    print("Object 2 : X- " .. event.other.x .. " Y- " ..  event.other.y .. " W- " .. event.other.width .. " H- " .. event.other.height )
    print(above)
    print(below)
    print(onLeft)
    print(onRight)
    print(grounded)
  end
  if ( event.selfElement == 2) then
    -- Foot sensor has entered (overlapped) a ground object
    if ( event.phase == "began" ) then
      grounded = grounded + 1
      -- Foot sensor has exited a ground object
    elseif ( event.phase == "ended" ) then
      grounded = grounded - 1
    end
  end
end


---------------------------------------------------------------------

function scene:create( event )
  sceneGroup = self.view
  display.setDefault( "anchorX", -1 )
  display.setDefault( "anchorY", -1 )
  physics.start()
  physics.pause() 
  physics.setGravity( 0, defaultGrav )
  physics.setTimeStep( 1/30 )
  --physics.setDrawMode( 'hybrid' )

  local background = display.newImageRect( "sky.png", 800, 600 )
  background.x, background.y = 0,0
  sceneGroup:insert( background )


  --Tile Map Displaying
  local map = display.newImageRect(  "Tiled-level1Map.png", 800, 600 )
  sceneGroup:insert( map )

-------------------------------------------
  --Tile Map Collision Creation
-------------------------------------------

  --create array of array, z means collision should go there otherwise 0
  local thing = require("Tiled-level1MapMap")
  local platforms = {}
  local grid = {}
  local tempRow = {}
  for k,v in pairs(thing.layers[1].data) do
    if(v ~= 0) then
      table.insert(tempRow,"z")
    else
      table.insert(tempRow,v)
    end
    if(math.fmod(k-1,32) == 31) then
      table.insert(grid,tempRow)
      tempRow = {}
    end
  end
  local spawnpoints = {}
  for k,v in pairs(thing.layers[2].objects) do
    table.insert(spawnpoints, {v.x, v.y})
  end


  local topLeftx 
  local topLefty
  local building = false
  local height = 0
  local width = 1
  --iterate through each column
  for j=1,32 do
    --iterate through the column top to bottom
    for i=1,24 do
      --once you reach a block that needs collision, and you arent "building" a collider set the topLeft x and y properties
      if(grid[i][j] == "z") then
        if(building == false) then
          topLeftx, topLefty = j , i
          building = true
        end
        --increase the height each time you reach a z in a row
        height = height + 1
      end
      --once you dont reach a z or your at the end of a column and a collider has been building start widening process
      if(building and grid[i][j] ~= "z" or i ==24 and building) then
        --widening process is true as it is going
        local widening = true
        --iterate through each column
        for k=topLeftx + 1,32 do
          local isGround = true
          --though only check the cells next to the discovered collider
          for l=topLefty,topLefty + height - 1 do
            --ensure every if every cell next to the discovered collider is a "z"
            if(isGround) then
              isGround  = grid[l][k]== "z" 
              --check that you are not widening into a square thats better suited for another collider
              -- AKA Prioritize vertical colliders
              if (grid[topLefty - 1] ~= nil and isGround) then
                isGround = grid[topLefty - 1][k] ~= "z" 
              end
              if(isGround ~= true) then
                --if you reach one that isnt stop widening
                widening = false
              end
            end
          end
          --if that has past that means that the column next to the discovered collider is all "z"'z
          if(isGround and widening) then
            --set them all to x's so they cant be made into another collider
            for l=topLefty,topLefty + height - 1 do
              grid[l][k] = "x"
            end
            -- and widen the collider by one
            width = width+1
          end
          --repeate for each column, once widening has stopped it stays stopped
        end
        table.insert(platforms, display.newRect((topLeftx-1) * 25 ,(topLefty-1) * 25 , 25 * width, 25 *height ))
        building = false
        height = 0
        width = 1
      end
    end
  end

  for k,v in pairs(platforms) do
    v:setFillColor(0,0,0,0)
    physics.addBody(v, "static", { friction=0 } )
    sceneGroup:insert(v)
  end


  yourPlayer = display.newImageRect( "square.png", 30, 30)
  yourPlayer.x, yourPlayer.y =  unpack(spawnpoints[ math.random( #spawnpoints ) ])
  physics.addBody( yourPlayer, { shape ={-14,-14,14,-14,14,14,-14,14},density=1.0, friction=0, bounce=0 }, { box={ halfWidth=13, halfHeight=1, x=15, y=28 }, isSensor = true} )
  yourPlayer:setFillColor(unpack(yourColor))
  yourPlayer.isFixedRotation = true
  yourPlayer.collision = onLocalCollision
  yourPlayer:addEventListener( "collision" )
  sceneGroup:insert( yourPlayer )
end


function scene:show( event )
  local sceneGroup = self.view
  local phase = event.phase

  if phase == "will" then
    -- Called when the scene is still off screen and is about to move on screen

  elseif phase == "did" then
    Runtime:addEventListener( "enterFrame", myListener )
    Runtime:addEventListener( "key", onKeyEvent )






    physics.start()
  end
end

function scene:hide( event )
  local sceneGroup = self.view

  local phase = event.phase
  Runtime:removeEventListener( "enterFrame", myListener )
  Runtime:removeEventListener( "key", onKeyEvent )
  if event.phase == "will" then
    -- Called when the scene is on screen and is about to move off screen
    --
    -- INSERT code here to pause the scene
    -- e.g. stop timers, stop animation, unload sounds, etc.)
    physics.stop()

  elseif phase == "did" then
    -- Called when the scene is now off screen
  end	

end

function scene:destroy( event )
  local sceneGroup = self.view

  package.loaded[physics] = nil
  physics = nil
end
-----------------------------------------------------------------------------




---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene