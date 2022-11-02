pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init()
    color = {}
    color.black = 0
    color.dark_gray = 5
    color.white = 7

    timer = 0

    player = {}
    player.spr = 0
    player.x = 64
    player.y = 64
    player.speed = 1

    enemy = {}
    enemy.spr = 1
    enemy.x = 0
    enemy.y = 0
    enemy.speed = .2
end

function _draw()
    cls(color.black)
    print(tostr(flr(timer)), 0, 0, color.white)
    spr(player.spr, player.x, player.y, 1, 1, player.flipX)
    spr(enemy.spr, enemy.x, enemy.y)
end

function _update60()
    timer += 1/60

    updatePlayer()
    updateEnemy()
end

function updatePlayer()
    if (btn(0)) then
        player.x -= player.speed
        player.flipX = true
    end
    if (btn(1)) then
        player.x += player.speed
        player.flipX = false
    end
    if (btn(2)) then player.y -= player.speed end
    if (btn(3)) then player.y += player.speed end
end

function updateEnemy()
    if (enemy.x < player.x) then
        enemy.x += enemy.speed
    end
    if (enemy.x > player.x) then
        enemy.x -= enemy.speed
    end
    if (enemy.y < player.y) then
        enemy.y += enemy.speed
    end
    if (enemy.y > player.y) then
        enemy.y -= enemy.speed
    end
end

__gfx__
0444444400aaaa000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444ffff00aa99aa011d1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44fff4f0aa9aa9aa1111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44ffffffaa9aaaaa0110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044fff00aa9aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc00aa9aa9aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccc00aa99aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccc000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
