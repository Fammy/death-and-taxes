pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

function _init()
    color = {}
    color.black = 0
    color.darkGray = 5
    color.lightGray = 6
    color.white = 7

    timer = 0
    lastSpawn = 0
    spawnRate = 2
    kills = 0
    spawnBuffer = 36

    player = {}
    player.spr = 0
    player.sprDamage = 16
    player.x = 60
    player.y = 60
    player.w = 8
    player.h = 8
    player.speed = .5
    player.health = 3
    player.invincible = 0
    player.lastFire = 0
    player.fireRate = 1

    enemies = {}
    projectiles = {}

    music(0)
    musicPlaying = true
end

function _draw()
    cls(color.black)

    print(tostr(flr(timer)), 0, 0, color.darkGray)
    print(tostr(flr(score())), 62, 0, color.white)
    drawHealth()

    if (player.health > 0) then
        foreach(enemies, drawEnemy)
        foreach(projectiles, drawProjectile)
    end
    drawPlayer()
end

function _update60()
    timer += 1/60

    if (player.health <= 0) then
        if (musicPlaying) then
            musicPlaying = false
            music(-1, 300)
        end
        if (btn(4)) then _init() end
        return
    end

    player.invincible -= 1
    if (player.invincible < 0) then player.invincible = 0 end

    spawnEnemy()

    foreach(enemies, checkCollisions)

    updatePlayer()
    foreach(projectiles, updateProjectile)
    foreach(enemies, updateEnemy)
end

function drawPlayer()
    local s = player.spr
    if (flr(player.invincible) % 10 > 0 or player.health <= 0) then
        s = player.sprDamage
    end
    spr(s, player.x, player.y, 1, 1, player.flipX, player.health <= 0)
end

function drawHealth()
    for i = 0,player.health do
        spr(2, 128 - (i * 6), 0, .625, .5)
    end
end

function drawProjectile(p)
    pset(p.x, p.y, color.lightGray)
end

function drawEnemy(enemy)
    spr(enemy.spr, enemy.x, enemy.y, enemy.w / 8, enemy.h / 8)
end

function score()
    return kills-- + flr(timer / 10)
end

function spawnEnemy()
    if (timer - lastSpawn > spawnRate) then
        local i = flr(rnd(2)) + 3
        local x = flr(rnd(128))
        local y = flr(rnd(128))

        if (abs(x - player.x) < spawnBuffer or abs(y - player.y) < spawnBuffer) then
            spawnEnemy()
            return
        end

        makeEnemy(i, x, y)
    end
end

function makeEnemy(spr, x, y)
    local enemy = {}
    enemy.spr = spr
    enemy.x = x
    enemy.y = y
    enemy.w = 5
    enemy.h = 5
    enemy.health = 2
    enemy.speed = .1

    add(enemies, enemy)

    lastSpawn = timer

    return enemy
end

function makeProjectile()
    local nearest = getNearestEnemy()
    if (nearest == nil) then return end

    local angle = atan2(centerX(nearest) - centerX(player), centerY(nearest) - centerY(player))

    local p = {}
    p.x = centerX(player)
    p.y = centerY(player)
    p.w = 1
    p.h = 1
    p.dx = cos(angle)
    p.dy = sin(angle)

    add(projectiles, p)

    player.lastFire = timer

    return p
end

function getNearestEnemy()
    local nearest
    local nearestD = 999

    for e in all(enemies) do
        local d = approx_dist(e, player)
        if (d < nearestD) then
            nearestD = d
            nearest = e
        end
    end

    return nearest
end

function approx_dist(e1, e2)
    local dx = e1.x - e2.x
    local dy = e1.y - e2.y
    local maskx,masky=dx>>31,dy>>31
    local a0,b0=(dx+maskx)^^maskx,(dy+masky)^^masky
    if a0>b0 then
     return a0*0.9609+b0*0.3984
    end
    return b0*0.9609+a0*0.3984
end

function centerX(entity)
    return entity.x + (entity.w / 2)
end

function centerY(entity)
    return entity.y + (entity.h / 2)
end

function updatePlayer()
    if (btn(0) and player.x > -4) then
        player.x -= player.speed
        player.flipX = true
    end
    if (btn(1) and player.x < 124) then
        player.x += player.speed
        player.flipX = false
    end
    if (btn(2) and player.y > -4) then player.y -= player.speed end
    if (btn(3) and player.y < 124) then player.y += player.speed end

    if (player.lastFire + player.fireRate <= timer) then
        makeProjectile()
    end
end

function updateProjectile(p)
    p.x += p.dx
    p.y += p.dy

    if (p.x < 0 or p.x > 128 or p.y < 0 or p.y > 128) then
        del(projectiles, p)
    end
end

function updateEnemy(enemy)
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

function checkCollisions(enemy)
    checkPlayerCollision(enemy)
    for p in all(projectiles) do
        checkProjectileCollision(enemy, p)
    end
end

function checkPlayerCollision(enemy)
    if (player.invincible <= 0 and collide(enemy, player)) then
        player.health -=1
        player.invincible = 60
    end
end

function checkProjectileCollision(enemy, p)
    if (collide(enemy, p)) then
        enemy.health -= 1
        del(projectiles, p)
        if (enemy.health <= 0) then
            del(enemies, enemy)
            kills += 1
            spawnRate -= .1
            if (spawnRate < .1) then spawnRate = .1 end
        end
    end
end

function collide(e1, e2)
    if (e1 == nil or e2 == nil) then return false end

    return not (e1.x > e2.x + e2.w or
           e1.y > e2.y + e2.h or
           e1.x + e1.w < e2.x or
           e1.y + e1.h < e2.y)
end

__gfx__
044ffff000aaaa0008080000077700000aaa00000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44ff1f1f0aa99aa0888e800075757000a999a00011d1000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444fffffaa9aa9aa0888000077777000a9aaa0001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044ffef0aa9aaaaa0080000007570000a999a0000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07778770aa9aaaaa00000000000000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f77877faa9aa9aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066666600aa99aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0550055000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022eeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22ee1e1e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222eeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022ee0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07778770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e77877e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
70700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000aa99aa0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000aa9aa9aa000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000aa9aaaaa000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000aa9aaaaa000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000aa9aa9aa000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000aa99aa0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000444444400000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000444ffff000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000044fff4f000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000044ffffff00000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000044fff0000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc0000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200200405004050040500405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000d7500e75010750127500d7500c7500c7500d7500e75013750127501475013750117500e7500b750117500e7500c75009750107500c75008750057500a75006750037500075006750027500075000750
001000000a5000a5000a5000a5000a5000a5000a5000a500075000a5000a5000a5000a5000a5000a5000a5000a5000950009500095000950009500095000950009500095000950009500235201c520295202c520
__music__
02 01020344

