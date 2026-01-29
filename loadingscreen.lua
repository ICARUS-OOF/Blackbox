function _init()
spritetop=81
spritebottom=97
stimer=0
ani_speed=20
topportal=84
bottomportal=100
spritedot1=54
spritedot1max=57
spritedot2=59
spritedot2max=62
spritedot3=43
spritedot3max=46
end



function _update()

if stimer<ani_speed then
	stimer+=1
	else
		if spritetop<topportal then
		spritetop+=1
		spritebottom+=1
		spritedot1+=1
		spritedot2+=1
		spritedot3+=1
		else
		spritetop=81
		spritebottom=97
		spritedot1=54
		spritedot2=59
		spritedot3=43
		end
	stimer=0
	end


end


function _draw()

cls()

map()

spr(spritedot1,80,0)

spr(spritedot2,88,0)

spr(spritedot3,96,0)

spr(spritetop,16,24)

spr(spritetop,64,24)

spr(spritetop,112,24)

spr(spritebottom,16,32)

spr(spritebottom,64,32)

spr(spritebottom,112,32)


end