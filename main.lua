-----------------------------------------------------------------------------------------
--設計一個打磚塊遊戲
--每五秒會掉下不同顏色的珠子
--每種珠子有不同功能 
--可以獲得武器或是防護
--磚塊全部打完則遊戲結束


--Data: 2016/08/18  09:35
--Author:Ryan
-----------------------------------------------------------------------------------------

--=======================================================================================
--引入各種函式庫
--=======================================================================================
display.setStatusBar( display.HiddenStatusBar ) 
math.randomseed( os.time() )
local physics = require("physics") 
physics.start( )  
physics.pause( ) 
physics.setGravity( 0 , 0) 
-- physics.setDrawMode("hybrid") 

--=======================================================================================
--宣告各種變數
--=======================================================================================
_SCREEN = {
	W = display.contentWidth ,
	H = display.contentHeight
}
_SCREEN.CENTER = {
	X = display.contentCenterX ,
	Y = display.contentCenterY
}

local backGroup = display.newGroup( )
local brickGroup = display.newGroup( )
local middleGroup = display.newGroup( )
local frontGroup = display.newGroup( )
local bgMusic = audio.loadStream("sounds/bgMusic.mp3" )  --載入背景音樂
local sound1 = audio.loadSound("sounds/weapon.mp3") --載入音效
local sound2 = audio.loadSound("sounds/weapon2.mp3") --載入音效
local sound3 = audio.loadSound("sounds/weapon3.mp3") --載入音效
local sound4 = audio.loadSound("sounds/powerup.mp3") --載入音效
local bar 
local ball
local boundaryLeft
local boundaryRight
local boundaryTop
local bgImg
local defense
local brickNum = 50
local die
local weaponL
local weaponR
local weapon2
local weapon3
local boundaryData = {
	{ path = "images/boundaryLeft.png" , w = 15 , h =  _SCREEN.H , x = 0 , y = 240 } ,
	{ path = "images/boundaryRight.png" , w = 15 , h =  _SCREEN.H , x = 320 , y = 240 } ,
	{ path = "images/boundaryTop.png" , w =  _SCREEN.W , h =  15 , x = _SCREEN.CENTER.X , y = 0 } ,
	{ path = "images/boundaryTop.png" , w = _SCREEN.W , h = 5 , x = _SCREEN.CENTER.X , y = -20 } ,
	{ path = "images/boundaryTop.png" , w = _SCREEN.W , h = 5 , x = _SCREEN.CENTER.X , y = 490 }
}

local pools = {
	weapon = {} , 
	weapon2 = {} ,
	weapon3 = {} 
}

--=======================================================================================
--宣告各個函式名稱
--=======================================================================================
local initial
local moveBar
local ballCollision
local barCollision
local onCollision
local weaponShoot
local weapon2Shoot
local weapon3Shoot
local gameOver
local startGame
local removeTapStart
local brickMoveBack
local brickMove
local over
local recycleWeapon
local judge 
--=======================================================================================
--宣告與定義main()函式
--=======================================================================================
local main = function ( )
	initial()
end

--=======================================================================================
--定義其他函式
--=======================================================================================
initial = function ( )
	--加入起始畫面
	startBg = display.newImageRect( frontGroup , "images/startBg.png" , _SCREEN.W , _SCREEN.H )
	startBg.x , startBg.y = _SCREEN.CENTER.X , _SCREEN.CENTER.Y
	-- frontGroup:insert( startBg )

	tapToStart = display.newImageRect( frontGroup , "images/tap.png" , 150 , 40 )
	tapToStart.x ,tapToStart.y = 160 ,400
	-- frontGroup:insert( tapToStart )
	transition.to( tapToStart, {time = 800 , xScale = 1.3 , yScale = 1.3 , transition = easing.continuousLoop ,iterations = -1} )
	timer.performWithDelay( 500, function (  )
		Runtime:addEventListener( "tap", startGame )
		Runtime:addEventListener( "tap",removeTapStart )
	end )
end

--遊戲開始
startGame = function ( )
	physics.start( )  
	--增加50個磚塊
	brick = {}
	for i = 1 , 10 do 
	brick[i] = {}
		for j = 1, 5 do
			brick[i][j] = display.newImageRect( brickGroup , "images/pig.png" , 30 , 30 )
			brick[i][j].x , brick[i][j].y = -5+i*30 ,  j*30 
			brick[i][j].id = "brick"
			-- brickGroup:insert(brick[i][j])
			physics.addBody( brick[i][j] ,"static" , { bounce = 1 } )
			brick[i][j].collision = onCollision
			brick[i][j]:addEventListener( "collision", brick[i][j] )
		end
	end
	
	--加入背景音樂及設定音量
	audio.play( bgMusic , { channel = 1 , loops = -1 } )
	audio.setVolume( 0.65 )
	
	--加入背景
	bgImg = display.newImageRect( backGroup , "images/bg5.png", _SCREEN.W , _SCREEN.H ) 
	bgImg.x , bgImg.y = _SCREEN.CENTER.X , _SCREEN.CENTER.Y

	--加入Bar
	bar = display.newImageRect( middleGroup , "images/bar.png" , 80, 20 )
	bar.x , bar.y = 160 , 450
	bar.id = "bar"
	physics.addBody( bar , "static" ,{ bounce = 1} )
	Runtime:addEventListener( "touch", moveBar )

	--加入主角
	ball = display.newImageRect( middleGroup , "images/ball.png", 30 , 30 )
	ball.x , ball.y = _SCREEN.CENTER.X , 400
	ball.id = "ball"
	physics.addBody( ball , "dynamics" ,{ bounce = 1 ,radius = 10 } )
	
	--增加邊界
	boundary = {}
	for i = 1 , #boundaryData do
		bud = boundaryData[i]
		boundary[i] = display.newImageRect( middleGroup , bud.path , bud.w , bud.h )
		boundary[i].x , boundary[i].y = bud.x , bud.y
		physics.addBody( boundary[i] , "static" ,{ bounce = 1 } )
	end
	boundary[4].id = "net"
	boundary[5].id = "die"
	
	--監聽碰撞事件
	ball.collision = ballCollision
	ball:addEventListener( "collision", ball )

	bar.collision = barCollision
	bar:addEventListener( "collision", bar )

	boundary[4].collision = netCollision
	boundary[4]:addEventListener( "collision", boundary[4] )

	Runtime:addEventListener( "tap", ballGo)
	foodTimer = timer.performWithDelay( 5000 , addFood ,-1 )

	brickTo = transition.to ( brickGroup , {time = 1500 , x = 15 , onComplete = brickMoveBack })
end

--來回移動brick
brickMoveBack = function (  )
	transition.to( brickGroup , {time = 1500 , x = -15 ,onComplete = brickMove} )
end

--來回移動brick
brickMove = function (  )
	transition.to( brickGroup , {time = 1500 , x = 15 ,onComplete = brickMoveBack } )
end

--移除開始畫面物件
removeTapStart = function ( )
	frontGroup:removeSelf( )
	Runtime:removeEventListener("tap",startGame)
	Runtime:removeEventListener("tap",removeTapStart)
end

--增加食物及隨機掉落
addFood = function ( )
	food = {}
	food[1] = { path="images/food1.png" ,id = "food1" }
	food[2] = { path="images/food2.png" ,id = "food2" }
	food[3] = { path="images/food3.png" ,id = "food3" }
	food[4] = { path="images/food4.png" ,id = "food4" }

	i = math.random( 1,9 )  -- 隨機在九個位置之一落下
	j = math.random( 1,4 ) -- 一共四種食物
	local foodImg = display.newImageRect( food[j].path , 30 , 30 )
	foodImg.x ,foodImg.y = i*32 , 0
	foodImg.id = food[j].id
	physics.addBody( foodImg , "dynamics" )
	foodImg.isSensor = true
	transition.to( foodImg , {time = 2000 , y = 500 ,onComplete = function()
		foodImg:removeSelf( )
	end} )
	-- print( foodImg.id )
end

--將球發射出去
ballGo = function (  )
	ball:applyForce( 1 , -1 , ball.x , ball.y )
	Runtime:removeEventListener( "tap", ballGo )
end

--移動Bar函式
moveBar = function (e)
	if ( e.phase == "moved" ) or (e.phase == "ended" ) then
		bar.x = e.x
	end
end

--球本身碰撞發生事件
ballCollision = function ( self , e )
	if ( e.phase == "began" ) then
		if ( self.id == "ball" ) and ( e.other.id == "brick" ) then
			e.other.alpha = e.other.alpha*0.8
			if e.other.alpha <= 0.52 then
				e.other:removeSelf( )
				brickNum = brickNum - 1
				print( brickNum )
				judge()
			end
		end

		if ( self.id == "ball" ) and (e.other.id == "defense" ) then
			e.other:removeSelf()
		end

		if (self.id == "ball" ) and (e.other.id == "die" ) then
			gameOver()
		end
	end
end

--Bar碰撞函式，吃到食物增加監聽器以發射武器
barCollision = function ( self , e )
	if ( e.phase=="began" ) then
		if ( self.id =="bar" ) and ( e.other.id == "food1") then
			e.other.isVisible = false
			timer.performWithDelay( 200 , weaponShoot , 25 )
			audio.play( sound4 )
		end

		if ( self.id =="bar" ) and ( e.other.id == "food2") then
			e.other.isVisible = false
			timer.performWithDelay( 500 , weapon2Shoot , 8 )
			audio.play( sound4 )	
		end

		if ( self.id =="bar" ) and ( e.other.id == "food3") then
			e.other.isVisible = false
			timer.performWithDelay( 600 , weapon3Shoot , 6 )
			audio.play( sound4 )
		end

		if ( self.id =="bar" ) and ( e.other.id == "food4") then
			e.other.isVisible = false
			audio.play( sound4 )
			timer.performWithDelay( 10 , function ( )
				defense = display.newImageRect("images/defense.png" , _SCREEN.W , 20 )
				defense.x , defense.y  = 160 , 460
				defense.id = "defense"
				physics.addBody( defense ,"static",{ bounce = 1} )
			end )
		end
	end
end

--回收未命中武器
netCollision = function ( self , e )
	if ( e.phase == "began" ) then
		if (e.other.id == "weapon") or (e.other.id == "weapon2") or (e.other.id == "weapon3") then
			recycleWeapon(e.other)
		end
	end
end

--回收未命中武器
recycleWeapon = function ( weaponObj )
	weaponObj.isVisible  = false
	print("recycle weapon:" , weaponObj)
	timer.performWithDelay( 1 , function (  )
		weaponObj.isBodyActive = false
		transition.cancel( weaponObj.tran )
		table.insert( weaponObj.t , #weaponObj.t + 1 , weaponObj )
	end )
end

--武器發射函式
weaponShoot = function (  )
	audio.play( sound1 )
	
	if #pools.weapon <= 1 then
		weaponL = display.newImageRect( "images/weapon.png", 5 , 20 )
		physics.addBody( weaponL,"dynamics")
		weaponL.id = "weapon"
		weaponL.t = pools.weapon

		weaponR = display.newImageRect( "images/weapon.png", 5 , 20 )
		physics.addBody( weaponR , "dynamics")
		weaponR.id = "weapon"
		weaponR.t = pools.weapon
	else
		weaponL = pools.weapon[#pools.weapon]
		table.remove( pools.weapon , #pools.weapon ) 
		weaponL.isBodyActive = true

		weaponR = pools.weapon[#pools.weapon] 
		table.remove( pools.weapon , #pools.weapon ) 
		weaponR.isBodyActive = true 
	end
		weaponL.x , weaponL.y = bar.x - 40 , bar.y - 40
		weaponL.tran = transition.to( weaponL , {time = 1000 , y = -20 } )
		weaponL.isVisible = true
		weaponL.isSensor = true 

		weaponR.x , weaponR.y = bar.x + 40 , bar.y -40
		weaponR.tran = transition.to( weaponR , {time = 1000 , y = -20 } )
		weaponR.isVisible = true
		weaponR.isSensor = true
end

--武器2發射函式
weapon2Shoot = function ( )
	audio.play( sound2 , { channel = 2 } )

	if #pools.weapon2 <= 0 then
		weapon2 = display.newImageRect( "images/weapon2.png", 50 , 50 )
		weapon2.id = "weapon2"
		physics.addBody( weapon2 ,"dynamics")
		weapon2.t = pools.weapon2
	else
		weapon2 = pools.weapon2[#pools.weapon2]
		table.remove( pools.weapon2 , #pools.weapon2 )
		weapon2.isBodyActive = true
	end

	weapon2.x , weapon2.y = bar.x , bar.y
	weapon2.isSensor = true
	weapon2.isVisible = true
	weapon2.tran = transition.to( weapon2 , {time = 2000 , y = -20 , x = weapon2.x + 100 , transition = easing.outCirc })
end

--武器3發射函式
weapon3Shoot = function ( )
	audio.play( sound3 , { channel = 2 } )

	if #pools.weapon3 <= 0 then
		weapon3 = display.newImageRect( "images/weapon3.png", 30 , 50 )
		weapon3.id = "weapon3"
		physics.addBody( weapon3 ,"dynamics")
		weapon3.t = pools.weapon3
	else	
		weapon3 = pools.weapon3[#pools.weapon3]
		table.remove( pools.weapon3 , #pools.weapon3 )
		weapon3.isBodyActive = true
	end

	weapon3.x , weapon3.y = bar.x , bar.y
	weapon3.isSensor = true
	weapon3.isVisible = true
	weapon3.tran = transition.to( weapon3 , {time = 1500 , y = -20 })
end

--武器碰撞磚塊後發生事件
onCollision = function ( self , e )
	
	if ( e.phase == "began" ) then
		if ( self.id == "brick") and ( e.other.id == "weapon" ) then
			recycleWeapon(e.other)		
			self.alpha = self.alpha * 0.8 --被武器1擊中透明度降低，擊中三次後消失
			if (self.alpha <= 0.52 ) then
				self:removeSelf( )
				brickNum = brickNum - 1
				judge()
			end
		end
		
		if ( self.id == "brick") and ( e.other.id == "weapon2" )then
			recycleWeapon(e.other)	
			--被武器2擊中後變大，擊中兩次後消失
			self.xScale , self.yScale  = self.xScale *1.5 , self.yScale * 1.5
			
			if ( self.xScale >= 1.6) then 
				self:removeSelf( )
				brickNum = brickNum - 1
				print( brickNum )
				judge()
			end
		end

		if ( self.id == "brick") and ( e.other.id == "weapon3" )then
			recycleWeapon(e.other)	
			self:removeSelf( )
			brickNum = brickNum - 1
			print( brickNum )
			judge()
		end
	end
	
end

--遊戲完成函式
gameFinish = function (  )
	over()
	winImg = display.newImageRect( "images/win.png", 150 ,150 )
	winImg.x , winImg.y = 0 , 240 
	transition.to( winImg , {time = 1000 , x = 160 , xScale = 1.5 ,yScale = 1.5 , onComplete = function (  )
		transition.to( winImg , {time = 800 ,xScale = 0.8 , yScale = 0.8 , transition = easing.continuousLoop , interations = -1 })
	end } )
end

--遊戲結束函式
gameOver = function (  )
	over()
	gameoverImg = display.newImageRect( "images/gameover.png" , 150 , 150 )
	gameoverImg.x ,gameoverImg.y = 160 , 0
	middleGroup:insert( gameoverImg )
	transition.to( gameoverImg , { time = 1000 , y = 240 } )
	transition.cancel( brickGroup )
end

over = function (  )
	timer.cancel( foodTimer )
	Runtime:removeEventListener( "touch", moveBar )
	ball:removeSelf( )
	audio.stop( 1 )
	audio.rewind( bgMusic )
	bar:removeEventListener( "collision", bar )
end

--判斷結束函式
judge = function ( )
	if ( brickNum == 0 ) then
		gameFinish()
	end
end

--=======================================================================================
--呼叫主函式
--=======================================================================================
main()


