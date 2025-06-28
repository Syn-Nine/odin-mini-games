//-----------------------------------------------------------------------------
// Dungeon of the Phoenix - by Syn9
// Tested with Odin version dev-2025-04-nightly:d9f990d
//-----------------------------------------------------------------------------

package main

import rl "vendor:raylib"

import "core:math/rand"
import "core:math"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

//-----------------------------------------------------------------------------
//  Utility Functions
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
util_console_input :: proc() -> string {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	return fmt.tprintf(strings.trim(string(buf[:n]), "\r\n"))
}

//-----------------------------------------------------------------------------
util_rand_range :: proc(lhs: i32, rhs: i32) -> i32 {
	return lhs + i32(rand.int_max(int(rhs - lhs)))
}

//-----------------------------------------------------------------------------
util_str_to_int :: proc(val: string) -> i32 {
	return i32(strconv.atoi(val))
}

//-----------------------------------------------------------------------------
util_str_cat :: proc(lhs: string, rhs: string) -> string {
	return fmt.tprintf("{}{}", lhs, rhs)
}

//-----------------------------------------------------------------------------
util_str_equal :: proc(lhs: string, rhs: string) -> bool {
	return 0 == strings.compare(lhs, rhs)
}


//-----------------------------------------------------------------------------
myDrawTextureProRGBA :: proc(texture: rl.Texture2D, tx: f32, ty: f32, tw: f32, th: f32, dx: f32, dy: f32, dw: f32, dh: f32, ox: f32, oy: f32, rot: f32, r: i32, g: i32, b: i32, a: i32) {
	rl.DrawTexturePro(texture, rl.Rectangle{tx, ty, tw, th}, rl.Rectangle{dx, dy, dw, dh}, rl.Vector2{ox, oy}, rot, rl.Color{u8(r), u8(g), u8(b), u8(a)})
}

myDrawTexturePro :: proc(texture: rl.Texture2D, tx: f32, ty: f32, tw: f32, th: f32, dx: f32, dy: f32, dw: f32, dh: f32, ox: f32, oy: f32, rot: f32, c: rl.Color) {
	rl.DrawTexturePro(texture, rl.Rectangle{tx, ty, tw, th}, rl.Rectangle{dx, dy, dw, dh}, rl.Vector2{ox, oy}, rot, c)
}

//-----------------------------------------------------------------------------
// Global Enumeration
//-----------------------------------------------------------------------------

enumtype :: enum {
    ARM_HELMET,
    ARM_MAIL,
    ARM_SHIELD,
    CHASE,
    CONTROLS,
    GAME,
    HEART,
    INTRO,
    INVALID,
    KEY,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP,
    POTION_HEALTH,
    POTION_MANA,
    ROD,
    TURKEY_LEG,
    WANDER,
    WIN,
}


//-----------------------------------------------------------------------------
// Structure Definitions
//-----------------------------------------------------------------------------

notification :: struct {
    txt: string,
    color: rl.Color,
    timer: f64,
}

entity_s :: struct {
    px: f64,
    py: f64,
    ix: i32,
    iy: i32,
    kx: i32,
    ky: i32,
    r: i32,
    g: i32,
    b: i32,
    sprite: i32,
    health: i32,
    max_health: i32,
    mana: i32,
    max_mana: i32,
    defense: i32,
    power: i32,
    level: i32,
    skip_update: i32,
    cooldown: f64,
    state: enumtype,
    enemy: bool,
    block_movement: bool,
}

vec2i :: struct {
    x: i32,
    y: i32,
}

projectile_s :: struct {
    px: f64,
    py: f64,
    vx: f64,
    vy: f64,
    active: bool,
}

room_s :: struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    cx: i32,
    cy: i32,
}

item_s :: struct {
    ix: i32,
    iy: i32,
    sprite: i32,
    name: string,
    color: rl.Color,
    kind: enumtype,
    skip_update: i32,
    block_movement: bool,
    found: bool,
}



//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

unload_sounds :: proc() {
    rl.UnloadSound(snd_blip)
    rl.UnloadSound(snd_hurt)
    rl.UnloadSound(snd_attack)
    rl.UnloadSound(snd_pickup)
    rl.UnloadSound(snd_potion)
    rl.UnloadSound(snd_ambient_1)
    rl.UnloadSound(snd_ambient_2)
    rl.UnloadSound(snd_ambient_3)
    rl.UnloadSound(snd_cast)
    rl.UnloadSound(snd_dead)
    rl.UnloadSound(snd_door)
    rl.UnloadSound(snd_levelup)
    rl.UnloadSound(snd_shake)
    rl.UnloadSound(snd_melody)
}

ui_draw :: proc() {
    if screen_shake {
        dt: f64 = 1.0 / 60.0
        phoenix_frame = phoenix_frame + dt
        if phoenix_frame > 1 {
            phoenix_frame = phoenix_frame + dt * f64(0.50)
        }
        if phoenix_frame > 8 {
            phoenix_frame = 8
        }
        t_shake_timer = t_shake_timer - dt
        if t_shake_timer < f64(4.50) && !shake_sound_played {
            rl.PlaySound(snd_shake)
            shake_sound_played = true
            found_tears = true
            rl.PlaySound(snd_levelup)
            note.txt = "Found Phoenix Tears!"
            note.color = CYAN
            note.timer = f64(999.00)
        }
        if shake_sound_played {
            t_shake_move = t_shake_move - dt
            if 0 > t_shake_move {
                t_shake_move = f64(0.05)
                an: f64 = rand.float64() * 2 * f64(3.141593)
                shake_x = math.cos_f64(an) * 4
                shake_y = math.sin_f64(an) * 4
            }
            if 0 > t_shake_timer {
                screen_shake = false
                shake_x = 0
                shake_y = 0
                menu = enumtype.WIN
                rl.PlaySound(snd_melody)
                game_win = true
                for eidx in 1 ..< num_entities {
                    if 0 < eidx && game_win {
                        entities[eidx].health = 0
                        entities[eidx].sprite = 39
                        entities[eidx].block_movement = false
                    }
                }
            }
        }
    }
	
    t_delta: f64 = 1.0 / 60.0
    lvl: i32 = entities[0].level
    draw_text(0, ( YRES - 30 ) * SCALE, fmt.tprintf("Level: {}", lvl), rl.DARKGRAY)
    draw_text(76 * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("Pwr: {}", entities[0].power), rl.DARKGRAY)
    draw_text(144 * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("Def: {}", entities[0].defense), rl.DARKGRAY)
    
	tx: i32 = 0
    ty: i32 = 5
    if found_shield {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(208 * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 128, 0, 255, 255)
    }
    tx = 1
    if found_helmet {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(224 * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 128, 0, 255, 255)
    }
    tx = 2
    if found_mail {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(240 * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 128, 0, 255, 255)
    }
    tx = 7
    ty = 6
    if found_key {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(256 * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 255, 255, 0, 255)
    }
    tx = 7
    ty = 7
    if found_tears {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(256 * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 32, 192, 255, 255)
    }
	
    if !game_win && !screen_shake {
        t_game = rl.GetTime() - t_clock
    }
    time: string = "GameTime: "
    m: i32 = i32(t_game / 60.0)
    s: i32 = i32(t_game - f64(m) * 60.0)
    time = fmt.tprintf("{}{}:", time, m)
    if s < 10 {
        time = fmt.tprintf("{}0", time)
    }
    time = fmt.tprintf("{}{}", time, s)
    draw_text_sm(208 * SCALE, ( YRES - 10 ) * SCALE, time, rl.GRAY)
	
    if f64(0.00) < note.timer {
        note.timer = note.timer - t_delta
        color: rl.Color = note.color
        if f64(2.00) > note.timer {
            color = rl.DARKGRAY
        }
        if f64(1.00) > note.timer {
            color = DARKDARKGRAY
        }
        draw_text(0, ( YRES - 16 ) * SCALE, fmt.tprintf("> {}", note.txt), color)
    }
    else {
        draw_text(0, ( YRES - 16 ) * SCALE, ">", DARKDARKGRAY)
    }
	
    r: f64 = f64(entities[0].health) / f64(entities[0].max_health)
    inc: f64 = f64(1.00) / f64( lvl * 3 * 2 )
    tot: f64 = 0
    for i in 0 ..< lvl * 2 {
        tx: i32 = 0
        ty: i32 = 6
        myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.DARKGRAY)
        tot = tot + inc
        if r > tot {
            myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, DARKRED)
        }
        tot = tot + inc
        if r > tot {
            tx: i32 = 1
            myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.RED)
        }
        tot = tot + inc
    }
    draw_text(( XRES_HALF - 16 ) * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("HP: {}/{}", entities[0].health, entities[0].max_health), DARKRED)
    
	tx = 3
    ty = 6
    myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 84 ) * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.RED)
    draw_text(( XRES_HALF + 100 ) * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("x{}", inventory[0]), rl.RED)
    draw_text(( XRES_HALF + 68 ) * SCALE, ( YRES - 30 ) * SCALE, "H:", rl.RED)
    
	
	if found_rod {
        r: f64 = f64(entities[0].mana) / f64(entities[0].max_mana)
        inc: f64 = f64(1.00) / f64( lvl * 3 * 2 )
        tot: f64 = 0
        for i in 0 ..< lvl * 2 {
            tx: i32 = 6
            ty: i32 = 6
            myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.DARKGRAY)
            tot = tot + inc
            if r > tot {
                myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.DARKGREEN)
            }
            tot = tot + inc
            if r > tot {
                myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), f32(( YRES - 16 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.GREEN)
            }
            tot = tot + inc
        }
        draw_text(( XRES_HALF + 150 ) * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("MP: {}/{}", entities[0].mana, entities[0].max_mana), rl.DARKGREEN)
        
		tx = 2
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 150 - 18 ) * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 128, 255, 128, 255)
        
		tx = 3
        myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(( XRES_HALF + 252 ) * SCALE), f32(( YRES - 32 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, rl.GREEN)
        draw_text(( XRES_HALF + 268 ) * SCALE, ( YRES - 30 ) * SCALE, fmt.tprintf("x{}", inventory[1]), rl.GREEN)
        draw_text(( XRES_HALF + 234 ) * SCALE, ( YRES - 30 ) * SCALE, "M:", rl.GREEN)
        draw_text(( XRES_HALF + 134 ) * SCALE, ( YRES - 15 ) * SCALE, "C:", rl.GREEN)
    }
	
    if enumtype.INTRO == menu {
        draw_intro()
    }
    else if enumtype.CONTROLS == menu {
        draw_controls()
    }
    else if enumtype.WIN == menu {
        draw_win()
    }
}

draw_house :: proc() {
    x: i32 = XRES_HALF - 110
    y: i32 = YRES_HALF
    myDrawTexturePro(gradient, 0, 0, 110, 26, f32(x * SCALE), f32(( y - 52 ) * SCALE), f32(220 * SCALE), f32(52 * SCALE), 0, 0, 0, rl.WHITE)
    myDrawTexturePro(icons, f32(5 * 8), 0, 8, 8, f32(x * SCALE), f32(y * SCALE), f32(220 * SCALE), f32(46 * SCALE), 0, 0, 0, SHARKGRAY)
    myDrawTexturePro(icons, 0, 80, 8, 8, f32(( x - 8 ) * SCALE), f32(( y - 60 ) * SCALE), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 40, 80, 8, 8, f32(( x + 220 ) * SCALE), f32(( y - 60 ) * SCALE), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 48, 80, 8, 8, f32(( x - 8 ) * SCALE), f32(( y + 46 ) * SCALE), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 56, 80, 8, 8, f32(( x + 220 ) * SCALE), f32(( y + 46 ) * SCALE), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 8, 80, 8, 8, f32(x * SCALE), f32(( y - 60 ) * SCALE), f32(220 * SCALE), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 32, 80, 8, 8, f32(x * SCALE), f32(( y + 46 ) * SCALE), f32(220 * SCALE), f32(SCALE_8), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 24, 80, 8, 8, f32(( x - 8 ) * SCALE), f32(( y - 52 ) * SCALE), f32(SCALE_8), f32(98 * SCALE), 0, 0, 0, rl.GOLD)
    myDrawTexturePro(icons, 16, 80, 8, 8, f32(( x + 220 ) * SCALE), f32(( y - 52 ) * SCALE), f32(SCALE_8), f32(98 * SCALE), 0, 0, 0, rl.GOLD)
}

draw_intro :: proc() {
    draw_house()
    x: i32 = XRES_HALF - 110
    y: i32 = YRES_HALF
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, f32(( XRES_HALF - 40 ) * SCALE), f32(( y - 30 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 0, 128, 255, 255)
    myDrawTexturePro(icons, 0, 8, 8, 8, f32(( XRES_HALF - 8 ) * SCALE), f32(( y - 30 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, BITTERSWEET)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Dear", rl.WHITE)
    draw_text_sm(( x + 30 ) * SCALE, ( y + 4 ) * SCALE, "Adventurer", rl.BLUE)
    draw_text_sm(( x + 81 ) * SCALE, ( y + 4 ) * SCALE, ", your mother is gravely ill.", rl.WHITE)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 14 ) * SCALE, "You must find the", rl.LIGHTGRAY)
    draw_text_sm(( x + 87 ) * SCALE, ( y + 14 ) * SCALE, "Tears of the Phoenix", CYAN)
    draw_text_sm(( x + 186 ) * SCALE, ( y + 14 ) * SCALE, "in the", rl.LIGHTGRAY)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 24 ) * SCALE, "forbidden ruins to save her. Please hurry...", rl.GRAY)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", rl.GRAY)
}

draw_controls :: proc() {
    draw_house()
    x: i32 = XRES_HALF - 110
    y: i32 = YRES_HALF
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, f32(( XRES_HALF - 40 ) * SCALE), f32(( y - 30 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 0, 128, 255, 255)
    myDrawTexturePro(icons, 0, 8, 8, 8, f32(( XRES_HALF - 8 ) * SCALE), f32(( y - 30 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, BITTERSWEET)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Controls:", rl.WHITE)
    draw_text_sm(( x + 19 ) * SCALE, ( y + 14 ) * SCALE, "Move: Arrow Keys", rl.WHITE)
    draw_text_sm(( x + 14 ) * SCALE, ( y + 24 ) * SCALE, "Attack: Bump", rl.WHITE)
    draw_text_sm(( x + 121 ) * SCALE, ( y + 4 ) * SCALE, "H: Heal Potion", rl.RED)
    draw_text_sm(( x + 120 ) * SCALE, ( y + 14 ) * SCALE, "M: Mana Potion", rl.GREEN)
    draw_text_sm(( x + 121 ) * SCALE, ( y + 24 ) * SCALE, "C: Cast Magic", rl.GREEN)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", rl.GRAY)
}

draw_win :: proc() {
    x: i32 = XRES_HALF - 110
    y: i32 = YRES_HALF
    t_win = t_win + 1.0 / 60.0
    if t_win < f64(0.50) {
        return 
    }
    draw_house()
    xx: f64 = t_win * 10
    alpha: f64 = 255 * ( 1 - t_win / 10 )
    if alpha < 0 {
        alpha = 0
    }
	
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, ( f32(XRES_HALF) - 40 + f32(xx)) * f32(SCALE), f32(( y - 30 ) * SCALE), f32(SCALE_8 * 2), f32(SCALE_8 * 2), 0, 0, 0, 0, 128, 255, i32(alpha))
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 10 ) * SCALE, "I'm almost there, please hold on...", CYAN)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to end.", rl.GRAY)
}

add_note :: proc(text: string, color: rl.Color, cooldown: f64) {
    note.txt = text
    note.color = color
    note.timer = cooldown
}

draw_text :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
	rl.DrawTextEx(fnt, strings.clone_to_cstring(txt, context.temp_allocator), rl.Vector2{f32(x), f32(y)}, f32(15 * SCALE), 1, color)
}

draw_text_center :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
    m: i32 = i32(rl.MeasureTextEx(fnt, strings.clone_to_cstring(txt, context.temp_allocator), f32(15 * SCALE), 1).x)
    draw_text(x - m / 2, y, txt, color)
}

draw_text_right :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
    m: i32 = i32(rl.MeasureTextEx(fnt, strings.clone_to_cstring(txt, context.temp_allocator), f32(15 * SCALE), 1).x)
    draw_text(x - m, y, txt, color)
}

draw_text_sm :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
    rl.DrawTextEx(fnt_sm, strings.clone_to_cstring(txt, context.temp_allocator), rl.Vector2{f32(x), f32(y)}, f32(SCALE_8), 0, color)
}

draw_text_sm_center :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
    m: i32 = i32(rl.MeasureTextEx(fnt_sm, strings.clone_to_cstring(txt, context.temp_allocator), f32(SCALE_8), 0).x)
    draw_text_sm(x - m / 2, y, txt, color)
}

draw_text_sm_right :: proc(x: i32, y: i32, txt: string, color: rl.Color) {
    m: i32 = i32(rl.MeasureTextEx(fnt_sm, strings.clone_to_cstring(txt, context.temp_allocator), f32(SCALE_8), 0).x)
    draw_text_sm(x - m, y, txt, color)
}

entity_new :: proc(x: i32, y: i32, sprite: i32, health: i32, level: i32, power: i32, defense: i32, enemy: bool) {
    e: entity_s
    e.px = f64(x)
    e.py = f64(y)
    e.ix = x
    e.iy = y
    e.sprite = sprite
    e.block_movement = true
    e.health = health
    e.max_health = e.health
    e.defense = defense
    e.power = power
    e.mana = 0
    e.max_mana = 0
    e.level = level
    e.enemy = enemy
    e.state = enumtype.WANDER
    e.skip_update = - 1
	entities[num_entities] = e
	num_entities += 1
}

entity_draw_all :: proc() {
    px: f64 = entities[0].px
    py: f64 = entities[0].py
    if 0 == entities[0].health {
        entity_draw_player()
    }
	
    for i in 1 ..< num_entities {
        if 0 > entities[i].skip_update {
            if !seen[entities[i].iy * MAP_WIDTH + entities[i].ix] {
                continue
            }
            x: f64 = entities[i].px
            y: f64 = entities[i].py
            if 0 < entities[i].health {
                dx: f64 = px - entities[i].px
                dy: f64 = py - entities[i].py
                dist: f64 = math.sqrt_f64(f64(dx * dx + dy * dy))
                if dist < f64(7.00) {
                    sprite: i32 = entities[i].sprite
                    tx: i32 = sprite % 8
                    ty: i32 = ( sprite - tx ) / 8
                    ratio: f64 = f64(entities[0].level) / f64( entities[i].level + 2 ) * f64(0.75)
                    if ratio > 1 {
                        ratio = 1
                    }
                    r: i32 = 48
                    g: i32 = 48
                    b: i32 = 48
                    if dist < f64(5.00) {
                        r = i32(255.0 * ( 1.0 - ratio ))
                        g = i32(255.0 * ratio)
                        b = 0
                    }
                    myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8) + f32(shake_x), f32(y) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, r, g, b, 255)
                }
                else {
                    entities[i].skip_update = util_rand_range(5, 10)
                }
            }
            else {
                myDrawTexturePro(icons, f32(7 * 8), f32(4 * 8), 8, 8, f32(x) * f32(SCALE_8) + f32(shake_x), f32(y) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, DARKRED)
            }
        }
        else {
            entities[i].skip_update = entities[i].skip_update - 1
        }
        kx: i32 = entities[i].kx
        ky: i32 = entities[i].ky
        if kx < 0 {
            entities[i].kx = kx + 1
        }
        if kx > 0 {
            entities[i].kx = kx - 1
        }
        if ky < 0 {
            entities[i].ky = ky + 1
        }
        if ky > 0 {
            entities[i].ky = ky - 1
        }
    }
	
    t_flames = t_flames + 1.0 / 60.0
    for i in 0 ..< num_torches {
        ix: i32 = torches[i].x
        iy: i32 = torches[i].y
        if ix == entities[0].ix && iy == entities[0].iy && 0 < entities[0].health {
            entities[0].health = 0
            rl.PlaySound(snd_dead)
        }
        if seen[iy * MAP_WIDTH + ix] {
            ofs: i32 = i32(( t_flames * 12.0 + f64(i) )) % 6
            tx: i32 = i32(( t_flames * 12.0 + f64(i) )) % 7
            ty: i32 = 7
            myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(ix) * f32(SCALE_8) + f32(shake_x), f32(iy) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, flame[ofs])
        }
    }
	
    if magic_ball.active {
        myDrawTexturePro(icons, f32(6 * 8), f32(6 * 8), 8, 8, f32(magic_ball.px) * f32(SCALE_8) + f32(shake_x), f32(magic_ball.py) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, magic[util_rand_range(0, 5)])
    }
	
    if 0 < entities[0].health {
        entity_draw_player()
    }
}

entity_draw_player :: proc() {
    tx: i32 = 0
    ty: i32 = 0
    x: f64 = entities[0].px
    y: f64 = entities[0].py
    if 0 < entities[0].health {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8), f32(y) * f32(SCALE_8), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, 0, 128, 255, 255)
    }
    else {
        myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8), f32(y) * f32(SCALE_8), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, 64, 64, 64, 255)
    }
}

entity_move :: proc(eidx: i32, move_dir: enumtype) {

    ix: i32 = entities[eidx].ix
    iy: i32 = entities[eidx].iy
    idx: i32 = iy * MAP_WIDTH + ix
	
    if enumtype.MOVE_UP == move_dir && iy > 0 && 3 > board[idx - MAP_WIDTH] {
        iy = iy - 1
    }
    else if enumtype.MOVE_DOWN == move_dir && iy < MAP_HEIGHT - 1 && 3 > board[idx + MAP_WIDTH] {
        iy = iy + 1
    }
    else if enumtype.MOVE_LEFT == move_dir && ix > 0 && 3 > board[idx - 1] {
        ix = ix - 1
    }
    else if enumtype.MOVE_RIGHT == move_dir && ix < MAP_WIDTH - 1 && 3 > board[idx + 1] {
        ix = ix + 1
    }
	
    new_idx: i32 = iy * MAP_WIDTH + ix
    if 0 == eidx && idx != new_idx && 1 == board[new_idx] {
        if found_key {
            found_key = false
            add_note("Unlocked!", rl.YELLOW, f64(5.00))
            board[new_idx] = 2
            rl.PlaySound(snd_door)
        }
        else {
            add_note("Locked!", rl.ORANGE, f64(5.00))
            new_idx = idx
        }
    }
	
    if idx != new_idx {
        for i in 1 ..< num_entities {
            if 0 > entities[i].skip_update && entities[i].block_movement && new_idx == entities[i].iy * MAP_WIDTH + entities[i].ix {
                if 0 == eidx && 0 > entities[eidx].cooldown {
                    entities[i].health = entities[i].health - 1
                    note.txt = "Hit Beast for 1 dmg!"
                    note.color = rl.GRAY
                    note.timer = f64(5.00)
                    entities[0].kx = ( ix - entities[eidx].ix ) * 8
                    entities[0].ky = ( iy - entities[eidx].iy ) * 8
                    entities[0].cooldown = f64(0.30)
                    rl.PlaySound(snd_attack)
                    if 0 == entities[i].health {
                        entities[i].sprite = 39
                        entities[i].block_movement = false
                        note.txt = "Beast fell!"
                        note.color = rl.LIGHTGRAY
                        note.timer = f64(5.00)
                    }
                }
                ix = entities[eidx].ix
                iy = entities[eidx].iy
                break
            }
        }
        entities[eidx].ix = ix
        entities[eidx].iy = iy
        if 0 == eidx {
            if iy * MAP_WIDTH + ix == win_idx {
                screen_shake = true
                rl.PlaySound(snd_cast)
            }
        }
    }
    else {
        if 0 == eidx && f64(0.10) > note.timer {
            add_note("Blocked!", rl.BROWN, f64(3.00))
        }
    }
}

entity_spawn_monster :: proc(x: i32, y: i32, lvl: i32) {
    mx: i32 = lvl * 23 / 5
    if mx < 4 {
        mx = 4
    }
    if mx > 23 {
        mx = 23
    }
    sprite: i32 = 16 + util_rand_range(0, mx)
    entity_new(x, y, sprite, 1 + i32(( 1.0 + rand.float64() ) * f64(lvl)), lvl, i32(math.ceil_f64(( f64(0.20) + rand.float64() * f64(0.50) ) * f64(lvl))), i32(math.ceil_f64(( f64(0.20) + rand.float64() * f64(0.50) ) * f64(lvl))), true)
}

entity_update :: proc(eidx: i32, t_delta: f64) {
    fps: f64 = 1 / t_delta
    if fps < 10 {
        entities[eidx].px = f64(entities[eidx].ix)
        entities[eidx].py = f64(entities[eidx].iy)
        key_delay = 0
    }
	
    dx: f64 = f64(entities[eidx].ix) - entities[eidx].px
    if abs(dx) > f64(0.10) {
        entities[eidx].px = entities[eidx].px + dx * f64(0.50)
    }
    else {
        entities[eidx].px = f64(entities[eidx].ix)
    }
	
    dy: f64 = f64(entities[eidx].iy) - entities[eidx].py
    if abs(dy) > f64(0.10) {
        entities[eidx].py = entities[eidx].py + dy * f64(0.50)
    }
    else {
        entities[eidx].py = f64(entities[eidx].iy)
    }
    entities[eidx].cooldown = entities[eidx].cooldown - t_delta
}

entity_update_all :: proc() {
    if intro_hold {
        return 
    }
	
    t_delta: f64 = 1.0 / 60.0
    entity_update(0, t_delta)
    if screen_shake {
        return 
    }
	
    if 0 < entities[0].health && f64(entities[0].health) < f64(entities[0].max_health) * f64(0.31) && !screen_shake && !game_win {
        blip_timer = blip_timer - t_delta
        if 0 > blip_timer {
            blip_timer = f64(1.00)
            rl.PlaySound(snd_blip)
        }
    }
	
    if magic_ball.active {
        magic_ball.px = magic_ball.px + magic_ball.vx * t_delta
        magic_ball.py = magic_ball.py + magic_ball.vy * t_delta
        px: i32 = i32(magic_ball.px + f64(0.50))
        py: i32 = i32(magic_ball.py + f64(0.50))
        idx: i32 = py * MAP_WIDTH + px
        if - 1 != board[idx] {
            magic_ball.active = false
        }
    }
	
    if !game_win && !screen_shake {
        ambient_timer = ambient_timer - t_delta
        if 0 > ambient_timer {
            ambient_timer = 4 + 4 * rand.float64()
            snd: i32 = util_rand_range(0, 3)
            if 0 == snd {
                rl.PlaySound(snd_ambient_1)
            }
            else if 1 == snd {
                rl.PlaySound(snd_ambient_2)
            }
            else if 2 == snd {
                rl.PlaySound(snd_ambient_3)
            }
        }
    }
	
    for i in 1 ..< num_entities {
        if 0 < entities[i].health && magic_ball.active {
            dx: f64 = entities[i].px - magic_ball.px
            dy: f64 = entities[i].py - magic_ball.py
            if math.sqrt_f64(f64(dx * dx + dy * dy)) < f64(0.50) {
                dmg: i32 = 2 * entities[0].level
                entities[i].health = max(0, entities[i].health - dmg)
                note.txt = fmt.tprintf("Hit Beast for {} dmg!", dmg)
                note.color = rl.GRAY
                note.timer = f64(5.00)
                entities[0].cooldown = f64(0.30)
                rl.PlaySound(snd_attack)
                if 0 == entities[i].health {
                    entities[i].sprite = 39
                    entities[i].block_movement = false
                    note.txt = "Beast fell!"
                    note.color = rl.LIGHTGRAY
                    note.timer = f64(5.00)
                }
            }
        }
        if 0 < entities[i].health && 0 > entities[i].skip_update && 0 > entities[i].cooldown {
            if amort == i % 4 {
                dx: f64 = entities[0].px - entities[i].px
                dy: f64 = entities[0].py - entities[i].py
                dist: f64 = math.sqrt_f64(f64(dx * dx + dy * dy))
                if enumtype.WANDER == entities[i].state && dist < f64(5.00) {
                    entities[i].state = enumtype.CHASE
                }
                else if enumtype.CHASE == entities[i].state && dist > 7 {
                    entities[i].state = enumtype.WANDER
                }
                if dist < f64(1.20) && rand.float64() < f64(0.50) && 0 < entities[0].health {
                    note.txt = "Beast hit for 1 dmg!"
                    note.color = rl.RED
                    note.timer = f64(5.00)
                    entities[i].cooldown = f64(0.70)
                    entities[i].ix = i32(entities[i].px)
                    entities[i].iy = i32(entities[i].py)
                    entities[i].kx = i32(dx * 8)
                    entities[i].ky = i32(dy * 8)
                    entities[0].health = max(0, entities[0].health - 1)
                    rl.PlaySound(snd_hurt)
                    if 0 == entities[0].health {
                        rl.PlaySound(snd_dead)
                    }
                }
                if enumtype.WANDER == entities[i].state && rand.float64() < f64(0.10) {
                    j: i32 = util_rand_range(0, 4)
                    if 0 == j {
                        entity_move(i, enumtype.MOVE_UP)
                    }
                    else if 1 == j {
                        entity_move(i, enumtype.MOVE_DOWN)
                    }
                    else if 2 == j {
                        entity_move(i, enumtype.MOVE_LEFT)
                    }
                    else if 3 == j {
                        entity_move(i, enumtype.MOVE_RIGHT)
                    }
                }
                else if enumtype.CHASE == entities[i].state && rand.float64() < f64(0.10) {
                    if abs(dx) > abs(dy) {
                        if entities[i].px < entities[0].px {
                            entity_move(i, enumtype.MOVE_RIGHT)
                        }
                        else {
                            entity_move(i, enumtype.MOVE_LEFT)
                        }
                    }
                    else {
                        if entities[i].py < entities[0].py {
                            entity_move(i, enumtype.MOVE_DOWN)
                        }
                        else {
                            entity_move(i, enumtype.MOVE_UP)
                        }
                    }
                }
            }
        }
        entity_update(i, t_delta)
    }
}

gen_rooms :: proc() -> bool {
    fmt.printfln("Generating Rooms")
	
	for i in 0 ..< MAP_SZ {
		board[i] = -1
		board2[i] = -1
		board3[i] = -1
		dist[i] = -1
		dist2[i] = -1
		seen[i] = false
		known[i] = false
	}
	
    num_rooms = 0
	
    keep_going = false
    w3: i32 = MAP_WIDTH / 3
    h2: i32 = MAP_HEIGHT / 2
    for j in 0 ..< 6 {
        xx: i32
        yy: i32
        if 1 == j {
            yy = 1
        }
        else if 2 == j {
            xx = 1
            yy = 1
        }
        else if 3 == j {
            xx = 1
            yy = 0
        }
        else if 4 == j {
            xx = 2
            yy = 0
        }
        else if 5 == j {
            xx = 2
            yy = 1
        }
        for k in 0 ..< 200 {
            w: i32 = util_rand_range(4, 8)
            h: i32 = util_rand_range(4, 6)
            x: i32 = util_rand_range(( xx * w3 ), ( ( xx + 1 ) * w3 ) - w + 1)
            y: i32 = util_rand_range(( yy * h2 ), ( ( yy + 1 ) * h2 ) - h + 1)
            if check_room_plot(x, y, w, h) {
                gen_room_plot(x, y, w, h)
            }
        }
    }
	
	
    taken: [MAP_SZ]bool
	for i in 0 ..< MAP_SZ {
		taken[i] = false
	}
	
    w: i32 = 6
    h: i32 = 6
    y: i32 = MAP_HEIGHT - 7
    x: i32 = 54 + util_rand_range(0, 15)
    phoenix_loc = ( y + 2 ) * MAP_WIDTH + x + 2
    gen_room_plot(x, y, w, h)
    for yy in 0 ..< h {
        for xx in 0 ..< w {
            idx: i32 = ( y + yy ) * MAP_WIDTH + x + xx
            taken[idx] = true
        }
    }
	
	
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            if - 1 == board[idx] {
                board[idx] = 6
            }
        }
    }
	
	for i in 0 ..< num_rooms - 1 {
        gen_hallway(i32(i), i32(i + 1))
    }
	
    for i in 0 ..< MAP_SZ {
        board2[i] = board[i]
    }
	
    for i in 0 ..< MAP_SZ {
        board[i] = board2[i]
        if 4 == board2[i] {
            board[i] = - 1
        }
        else if - 1 == board2[i] {
            board[i] = 3
        }
        board2[i] = board[i]
    }
	
    for x in 0 ..< MAP_WIDTH {
        idx: i32 = 18 * MAP_WIDTH + x
        if - 1 == board[idx] {
            board2[idx] = 1
        }
    }
	
    for y in 0 ..< MAP_HEIGHT - 1 {
        for x in 0 ..< MAP_WIDTH - 1 {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            if 6 != board[idx] {
                continue
            }
            if 6 == board[idx + 1] && 6 == board[idx + MAP_WIDTH] && 6 == board[idx + MAP_WIDTH + 1] {
                board3[idx] = 13
            }
        }
    }
	
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            if 6 != board[idx] {
                continue
            }
            up: bool
            down: bool
            left: bool
            right: bool
            if x > 0 {
                if 6 == board[idx - 1] {
                    left = true
                }
            }
            if y > 0 {
                if 6 == board[idx - MAP_WIDTH] {
                    up = true
                }
            }
            if x < MAP_WIDTH - 1 {
                if 6 == board[idx + 1] {
                    right = true
                }
            }
            if y < MAP_HEIGHT - 1 {
                if 6 == board[idx + MAP_WIDTH] {
                    down = true
                }
            }
            yy: i32 = 8
            xx: i32 = 0
            if left {
                xx = xx + 4
            }
            if right {
                yy = yy + 1
            }
            if up {
                xx = xx + 1
            }
            if down {
                xx = xx + 2
            }
            board2[idx] = yy * 8 + xx
        }
    }
	
    for i in 0 ..< MAP_SZ {
        board[i] = board2[i]
    }
	
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            if x < MAP_WIDTH - 1 && x > 0 {
                if 77 == board[idx - 1] && 77 == board[idx] && 77 == board[idx + 1] && rand.float64() < f64(0.80) {
                    board[idx] = 76
                }
                if 78 == board[idx - 1] && 78 == board[idx] && 78 == board[idx + 1] && rand.float64() < f64(0.80) {
                    board[idx] = 76
                }
            }
            if y < MAP_HEIGHT - 1 && y > 0 {
                if 71 == board[idx - MAP_WIDTH] && 71 == board[idx] && 71 == board[idx + MAP_WIDTH] && rand.float64() < f64(0.80) {
                    board[idx] = 67
                }
                if 75 == board[idx - MAP_WIDTH] && 75 == board[idx] && 75 == board[idx + MAP_WIDTH] && rand.float64() < f64(0.80) {
                    board[idx] = 67
                }
            }
        }
    }
	
	
    for i in 0 ..< MAP_SZ {
        if 1 == board[i] {
            dist[i] = 0
        }
        else if - 1 != board[i] {
            dist[i] = - 2
        }
    }
	
    mindist: f64 = 9999999
    for y in 0 ..< 13 {
        for x in 0 ..< 13 {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            if - 1 != board[idx] {
                continue
            }
            d: f64 = math.sqrt_f64(f64(x * x + y * y))
            if d < mindist {
                mindist = d
                start_idx = idx
            }
        }
    }
	
    win_idx = phoenix_loc + 1 + 2 * MAP_WIDTH
	
    dist[start_idx] = 1
	
    dist2 = dist
    cc: i32
    for {
        keep_going = false
		for i in 0 ..< MAP_SZ {
			update_dist(i32(i))
		}
        dist = dist2
        if !keep_going {
            break
        }
        cc = cc + 1
        if cc > 1000 {
            return false
        }
    }
	
    x = phoenix_loc % MAP_WIDTH
    y = ( phoenix_loc - x ) / MAP_WIDTH
    for yy in 0 ..< 3 {
        for xx in 0 ..< 3 {
            if 1 == xx && 2 == yy {
                continue
            }
            idx: i32 = ( y + i32(yy) ) * MAP_WIDTH + x + i32(xx)
            board[idx] = 4
        }
    }
	
    key0: i32
    key1: i32
    key2: i32
	
    maxdist: i32 = - 1
    for y in 0 ..< 18 {
        for x in 0 ..< 25 {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            d: i32 = dist[idx]
            if d > maxdist {
                maxdist = d
                key0 = idx
                taken[idx] = true
            }
        }
    }
    x = key0 % MAP_WIDTH
    y = ( key0 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, rl.GOLD, false, "Key", enumtype.KEY)
	
    maxdist = - 1
    for y in 0 ..< 18 {
        for x in 0 ..< 50 {
            idx: i32 = i32( 18 + y ) * MAP_WIDTH + i32(x)
            d: i32 = dist[idx]
            if d > maxdist {
                maxdist = d
                key1 = idx
                taken[idx] = true
            }
        }
    }
    x = key1 % MAP_WIDTH
    y = ( key1 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, rl.GOLD, false, "Key", enumtype.KEY)
	
    maxdist = - 1
    for y in 0 ..< 18 {
        for x in 0 ..< 50 {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x) + 25
            d: i32 = dist[idx]
            if d > maxdist {
                maxdist = d
                key2 = idx
                taken[idx] = true
            }
        }
    }
    x = key2 % MAP_WIDTH
    y = ( key2 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, rl.GOLD, false, "Key", enumtype.KEY)

    maxdist = - 1
    for i in 0 ..< MAP_SZ {
        d: i32 = dist[i]
        if d > maxdist {
            maxdist = d
        }
    }
	
    arm0: i32
    arm1: i32
    arm2: i32
    leg0: i32
    leg1: i32
    leg2: i32
    rod0: i32
    heart0: i32
    heart1: i32
    heart2: i32
    potions: [6]int
    mana: [2]int
    v: vec2i
	
    for yy in 0 ..< 2 {
        for xx in 0 ..< 3 {
            mx: i32 = 1
            if 0 < xx {
                mx = mx + 1
                if 0 == yy {
                    mx = mx + 1
                }
            }
            if 1 < xx {
                mx = mx + 1
            }
            for k in 0 ..< mx {
                c: i32 = 0
                for {
                    c = c + 1
                    if 1000 == c {
                        break
                    }
                    v.x = util_rand_range(1, 25) + i32(xx * 25)
                    v.y = util_rand_range(1, 18) + i32(yy * 18)
                    idx: i32 = v.y * MAP_WIDTH + v.x
                    if - 1 == board[idx] && !taken[idx] {
                        pass: bool = true
                        for y in 0 ..< 3 {
                            for x in 0 ..< 3 {
                                idx0: i32 = idx + i32( y - 1 ) * MAP_WIDTH + i32(x) - 1
                                if - 1 != board[idx0] || taken[idx0] {
                                    pass = false
                                    break
                                }
                            }
                            if !pass {
                                break
                            }
                        }
                        if pass {
                            taken[idx] = true
							torches[num_torches] = v
							num_torches += 1
                            break
                        }
                    }
                }
            }
        }
    }
	
	for {
        x = util_rand_range(0, 25)
        y = util_rand_range(0, 18)
        if 0 == heart0 {
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                heart0 = idx
                item_new(x, y, 6 * 8 + 1, rl.RED, false, "Heart Container", enumtype.HEART)
                taken[idx] = true
            }
        }
        else if 0 == heart1 {
            x = x + 25
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                heart1 = idx
                item_new(x, y, 6 * 8 + 1, rl.RED, false, "Heart Container", enumtype.HEART)
                taken[idx] = true
            }
        }
        else if 0 == heart2 {
            x = x + 50
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                heart2 = idx
                item_new(x, y, 6 * 8 + 1, rl.RED, false, "Heart Container", enumtype.HEART)
                taken[idx] = true
            }
        }
        else if 0 == arm0 {
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                arm0 = idx
                item_new(x, y, 5 * 8 + 0, rl.VIOLET, false, "Shield", enumtype.ARM_SHIELD)
                taken[idx] = true
            }
        }
        else if 0 == arm1 {
            x = x + 25
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                arm1 = idx
                item_new(x, y, 5 * 8 + 1, rl.VIOLET, false, "Helmet", enumtype.ARM_HELMET)
                taken[idx] = true
            }
        }
        else if 0 == arm2 {
            x = x + 50
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                arm2 = idx
                item_new(x, y, 5 * 8 + 2, rl.VIOLET, false, "Mail", enumtype.ARM_MAIL)
                taken[idx] = true
            }
        }
        else if 0 == rod0 {
            x = x + 25
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                rod0 = idx
                item_new(x, y, 6 * 8 + 2, rl.GREEN, false, "Rod", enumtype.ROD)
                taken[idx] = true
            }
        }
        else if 0 == leg0 {
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                leg0 = idx
                item_new(x, y, 5 * 8 + 3, rl.BROWN, false, "Food", enumtype.TURKEY_LEG)
                taken[idx] = true
            }
        }
        else if 0 == leg1 {
            x = x + 25
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                leg1 = idx
                item_new(x, y, 5 * 8 + 3, rl.BROWN, false, "Food", enumtype.TURKEY_LEG)
                taken[idx] = true
            }
        }
        else if 0 == leg2 {
            x = x + 50
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                leg2 = idx
                item_new(x, y, 5 * 8 + 3, rl.BROWN, false, "Food", enumtype.TURKEY_LEG)
                taken[idx] = true
            }
        }
        else if 1 > potions[0] {
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[0] = potions[0] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 2 > potions[1] {
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[1] = potions[1] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 2 > potions[2] {
            x = x + 25
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[2] = potions[2] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 2 > potions[3] {
            x = x + 25
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[3] = potions[3] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 2 > potions[4] {
            x = x + 50
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[4] = potions[4] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 1 > potions[5] {
            x = x + 50
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                potions[5] = potions[5] + 1
                item_new(x, y, 6 * 8 + 3, rl.RED, false, "Health Potion", enumtype.POTION_HEALTH)
                taken[idx] = true
            }
        }
        else if 2 > mana[0] {
            y = y + 18
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                mana[0] = mana[0] + 1
                item_new(x, y, 6 * 8 + 4, rl.GREEN, false, "Mana Potion", enumtype.POTION_MANA)
                taken[idx] = true
            }
        }
        else if 2 > mana[1] {
            x = x + 25
            idx: i32 = y * MAP_WIDTH + x
            if - 1 == board[idx] && !taken[idx] {
                mana[1] = mana[1] + 1
                item_new(x, y, 6 * 8 + 4, rl.GREEN, false, "Mana Potion", enumtype.POTION_MANA)
                taken[idx] = true
            }
        }
        else {
            break
        }
    }
	
	// player
    px: i32 = start_idx % MAP_WIDTH
    py: i32 = ( start_idx - px ) / MAP_WIDTH
    entity_new(px, py, 0, 10, 1, 1, 1, false)
    entities[0].mana = 5
    entities[0].max_mana = entities[0].mana
	
	// monsters
    for i in 0 ..< 75 {
        c: i32 = 0
        for {
            c = c + 1
            if 1000 == c {
                break
            }
            x: i32 = util_rand_range(0, MAP_WIDTH)
            y: i32 = util_rand_range(0, MAP_HEIGHT)
            dx: i32 = x - px
            dy: i32 = y - py
            dist: f64 = math.sqrt_f64(f64(dx * dx + dy * dy))
            if dist < 8 {
                continue
            }
            if dist < 15 && rand.float64() < f64(0.50) {
                continue
            }
            if x < 25 && rand.float64() < f64(0.30) {
                continue
            }
            if x < 50 && rand.float64() < f64(0.30) {
                continue
            }
            idx: i32 = y * MAP_WIDTH + x
            if - 1 != board[idx] || taken[idx] {
                continue
            }
            taken[idx] = true
            lvl: i32 = i32(( dist / f64(MAP_WIDTH )) * 4) + util_rand_range(0, 3)
            entity_spawn_monster(x, y, lvl)
            break
        }
    }
	
	
    rl.BeginTextureMode(ground_tex)
    rl.ClearBackground(rl.BLACK)
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            t: i32 = board[idx]
            if 0 > t {
                continue
            }
            tx: i32 = t % 8
            ty: i32 = ( t - tx ) / 8
            r: i32 = 96
            g: i32 = 96
            b: i32 = 96
            if 3 == t {
                r = 64
                g = 48
                b = 32
            }
            else if 1 == t {
                r = 192
                g = 127
                b = 32
            }
            if x < 26 && y < 19 {
                r = 0
            }
            if x > 49 {
                r = i32(f64(r) * f64(1.20))
                g = i32(f64(g) * f64(1.20))
                b = i32(f64(b) * f64(1.20))
                if y > 18 {
                    r = 230
					g = 230
					b = 230
                }
            }
            myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x * 8), f32(y * 8), 8, 8, 0, 0, 0, r / 3, g / 3, b / 3, 255)
        }
    }
    rl.EndTextureMode()
	
    rl.BeginTextureMode(ceiling_tex)
    rl.ClearBackground(rl.BLANK)
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = i32(y) * MAP_WIDTH + i32(x)
            t: i32 = board3[idx]
            if 0 > t {
                continue
            }
            tx: i32 = t % 8
            ty: i32 = ( t - tx ) / 8
            r: i32 = 96 / 3
            g: i32 = 64 / 3
            b: i32 = 127 / 3
            if x < 26 && y < 19 {
                g = 127 / 3
                b = 96 / 3
                r = 64 / 3
                tx = 6 + ( x + y ) % 2
                ty = ( x + y ) % 2
            }
            if x > 49 {
                r = i32(f64(r) * f64(0.30))
            }
            myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x * 8 + 4), f32(y * 8 + 2), 8, 8, 0, 0, 0, r, g, b, 255)
        }
    }
    rl.EndTextureMode()
	
    rl.BeginTextureMode(pre_game_tex)
    rl.ClearBackground(rl.BLANK)
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            r: i32 = i32(255 * ( f64(y) / f64(MAP_HEIGHT) ) * f64(0.10))
            b: i32 = i32(255 * ( f64(1) - f64(y) / f64(MAP_HEIGHT) ) * f64(0.30))
            g: i32 = i32(f64(b) * f64(0.70))
            myDrawTextureProRGBA(icons, f32(5 * 8), 8, 8, 8, f32(x * 8), f32(y * 8), 8, 8, 0, 0, 0, r, g, b, 255)
        }
    }
    rl.EndTextureMode()
    return true
}

update_dist :: proc(idx: i32) {
    if - 1 != dist[idx] {
        return 
    }
    x: i32 = idx % MAP_WIDTH
    y: i32 = ( idx - x ) / MAP_WIDTH
    if x < 1 || y < 1 || x > MAP_WIDTH - 2 || y > MAP_HEIGHT - 2 {
        return 
    }
    up: i32 = dist[idx - MAP_WIDTH]
    down: i32 = dist[idx + MAP_WIDTH]
    left: i32 = dist[idx - 1]
    right: i32 = dist[idx + 1]
    d: i32 = max(max(max(up, down), left), right)
    if d > - 1 {
        dist2[idx] = d + 1
    }
    keep_going = true
}

check_room_plot :: proc(x: i32, y: i32, w: i32, h: i32) -> bool {
    if 0 > x || 0 > y {
        return false
    }
    if MAP_WIDTH - 1 < x + w || MAP_HEIGHT - 1 < y + h {
        return false
    }
    for yy in 0 ..< h {
        for xx in 0 ..< w {
            i: i32 = ( yy + y ) * MAP_WIDTH + xx + x
            if - 1 != board[i] {
                return false
            }
        }
    }
    return true
}

gen_room_plot :: proc(x: i32, y: i32, w: i32, h: i32) {
    for yy in 0 ..< h {
        for xx in 0 ..< w {
            i: i32 = ( yy + y ) * MAP_WIDTH + xx + x
            if 0 == yy || 0 == xx {
                board[i] = 6
            }
            else {
                board[i] = 4
            }
        }
    }
    room: room_s
    room.x = x
    room.y = y
    room.w = w
    room.h = h
    room.cx = i32(math.ceil_f64(f64(x + w / 2.0)))
    room.cy = i32(math.ceil_f64(f64(y + h / 2.0)))
	rooms[num_rooms] = room
	num_rooms += 1
}

gen_hallway :: proc(r0_in: i32, r1_in: i32) {
    r0: i32 = r0_in
    r1: i32 = r1_in
    if rooms[r1].cy < rooms[r0].cy {
        temp: i32 = r0
        r0 = r1
        r1 = temp
    }
	
    y0: i32 = rooms[r0].cy
    y1: i32 = rooms[r1].cy
    if rooms[r0].cx < rooms[r1].x {
        x0: i32 = rooms[r0].cx
        x1: i32 = rooms[r1].cx
        if rand.float64() < f64(0.50) {
            for x in x0 ..< x1 + 1 {
                idx: i32 = y0 * MAP_WIDTH + x
                board[idx] = 4
            }
            for y in y0 ..< y1 + 1 {
                idx: i32 = y * MAP_WIDTH + x1
                board[idx] = 4
            }
        }
        else {
            for y in y0 ..< y1 + 1 {
                idx: i32 = y * MAP_WIDTH + x0
                board[idx] = 4
            }
            for x in x0 ..< x1 + 1 {
                idx: i32 = y1 * MAP_WIDTH + x
                board[idx] = 4
            }
        }
    }
    else {
        x0: i32 = rooms[r1].cx
        x1: i32 = rooms[r0].cx
        if rand.float64() < f64(0.50) {
            for x in x0 ..< x1 + 1 {
                idx: i32 = y0 * MAP_WIDTH + x
                board[idx] = 4
            }
            for y in y0 ..< y1 + 1 {
                idx: i32 = y * MAP_WIDTH + x0
                board[idx] = 4
            }
        }
        else {
            for y in y0 ..< y1 + 1 {
                idx: i32 = y * MAP_WIDTH + x1
                board[idx] = 4
            }
            for x in x0 ..< x1 + 1 {
                idx: i32 = y1 * MAP_WIDTH + x
                board[idx] = 4
            }
        }
    }
}

draw_map :: proc() {
    myDrawTexturePro(ground_tex_tex, 0, 0, f32(MAP_WIDTH * 8), f32(-MAP_HEIGHT * 8), f32(shake_x), f32(shake_y), f32(MAP_WIDTH * SCALE_8), f32(MAP_HEIGHT *	SCALE_8), 0, 0, 0, rl.WHITE)
	
    x: i32 = phoenix_loc % MAP_WIDTH
    y: i32 = ( phoenix_loc - x ) / MAP_WIDTH
    frame: i32 = i32(phoenix_frame)
    if frame > 6 {
        frame = 6
    }
	
    tx: i32 = frame % 4
    ty: i32 = ( frame - tx ) / 4
    myDrawTexturePro(reveal, f32(tx * 24), f32(ty * 24), 24, 24, f32(x * SCALE_8), f32(y * SCALE_8), f32(SCALE * 24), f32(SCALE * 24), 0, 0, 0, rl.WHITE)
	
    ix: i32 = entities[0].ix
    iy: i32 = entities[0].iy
    idx: i32
    dx: i32
    dy: i32
    xx: i32
    yy: i32
    for y in 0 ..< 15 {
        for x in 0 ..< 15 {
            dx = i32(x) - 6
            dy = i32(y) - 6
            if dx * dx + dy * dy > 36 {
                continue
            }
            xx = ix + dx
            yy = iy + dy
            if xx >= 0 && xx < MAP_WIDTH && yy >= 0 && yy < MAP_HEIGHT {
                idx = yy * MAP_WIDTH + xx
                if dx * dx + dy * dy < 9 {
                    known[idx] = true
                }
                if !seen[idx] {
                    continue
                }
                mag: f64 = math.sqrt_f64(f64(dx * dx + dy * dy)) / 6
                if mag > 1 {
                    mag = 1
                }
                mag = 1 - mag
                t0: i32 = board[idx]
                if 4 == t0 {
                    continue
                }
                if 0 < t0 {
                    tx: i32 = t0 % 8
                    ty: i32 = ( t0 - tx ) / 8
                    r: i32 = 96
                    g: i32 = 96
                    b: i32 = 96
                    if 3 == t0 {
                        r = 64
                        g = 48
                        b = 32
                    }
                    else if 1 == t0 {
                        r = 192
                        g = 127
                        b = 32
                    }
                    r = min(255, 64 + r)
                    g = min(255, 32 + g)
                    if xx < 26 && yy < 19 {
                        r = 0
                    }
                    if xx > 49 {
                        r = i32(f64(r) * f64(1.20))
                        g = i32(f64(g) * f64(1.20))
                        b = i32(f64(b) * f64(1.20))
                        if yy > 18 {
                            r = 242
							g = 242
							b = 242
                        }
                    }
                    rr: f64 = f64(0.33) + f64(0.66) * mag
                    r = i32(f64(r) * rr)
                    g = i32(f64(g) * rr)
                    b = i32(f64(b) * rr)
                    myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(xx) * f32(SCALE_8) + f32(shake_x), f32(yy) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, r, g, b, 255)
                }
            }
        }
    }
	
    for i in 0 ..< num_torches {
        ix: i32 = torches[i].x
        iy: i32 = torches[i].y
        ofs: i32 = i32(( t_flames * 12 + f64(i) )) % 6
        for y in 0 ..< 7 {
            for x in 0 ..< 7 {
                dx: i32 = i32(x) - 3
                dy: i32 = i32(y) - 3
                delta: i32 = dx * dx + dy * dy
                xx: i32 = ix + dx
                yy: i32 = iy + dy
                if xx > - 1 && yy > - 1 && xx < MAP_WIDTH && yy < MAP_HEIGHT {
                    idx: i32 = yy * MAP_WIDTH + xx
                    if !seen[idx] {
                        continue
                    }
                    t: i32 = board[idx]
                    if 0 > t || 4 == t {
                        continue
                    }
                    tx: i32 = t % 8
                    ty: i32 = ( t - tx ) / 8
                    ratio: f64 = 1 - math.sqrt_f64(f64(delta)) / 3
                    if ratio > 1 {
                        ratio = 1
                    }
                    if ratio < 0 {
                        ratio = 0
                    }
                    r: i32 = 255
                    g: i32 = i32( 128.0 + rand.float64() * 127.0 )
                    myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(i32(xx) * SCALE_8) + f32(shake_x), f32(i32(yy) * SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, r, g, 0, i32(ratio * 255.0))
                }
            }
        }
    }
	
	
    myDrawTexturePro(ceiling_tex_tex, 0, 0, f32(MAP_WIDTH * 8), f32(-MAP_HEIGHT * 8), f32(shake_x), f32(shake_y), f32(MAP_WIDTH * SCALE_8), f32(MAP_HEIGHT * SCALE_8), 0, 0, 0, rl.WHITE)
	
    idx = 0
    dx = 0
    dy = 0
    xx = 0
    yy = 0
    for y in 0 ..< 15 {
        for x in 0 ..< 15 {
            dx = i32(x) - 6
            dy = i32(y) - 6
            if dx * dx + dy * dy > 36 {
                continue
            }
            xx = ix + dx
            yy = iy + dy
            if xx >= 0 && xx < MAP_WIDTH && yy >= 0 && yy < MAP_HEIGHT {
                idx = yy * MAP_WIDTH + xx
                if !seen[idx] {
                    continue
                }
                mag: f64 = math.sqrt_f64(f64(dx * dx + dy * dy)) / 6
                if mag > 1 {
                    mag = 1
                }
                mag = 1 - mag
                t3: i32 = board3[idx]
                if 0 < t3 {
                    tx: i32 = t3 % 8
                    ty: i32 = ( t3 - tx ) / 8
                    r: i32 = 127
                    g: i32 = 64
                    b: i32 = 96
                    if xx < 26 && yy < 19 {
                        g = 127
                        b = 96
                        r = 64
                        tx = 6 + ( xx + yy ) % 2
                        ty = ( xx + yy ) % 2
                    }
                    if xx > 49 {
                        r = i32(f64(r) * f64(0.30))
                    }
                    rr: f64 = f64(0.33) + f64(0.66) * mag
                    r = i32(f64(r) * rr)
                    g = i32(f64(g) * rr)
                    b = i32(f64(b) * rr)
                    myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(xx) * f32(SCALE_8) + f32(4 * SCALE) + f32(shake_x), f32(yy) * f32(SCALE_8) + f32(2 * SCALE) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, r, g, b, 255)
                }
            }
        }
    }
	
    for y in 0 ..< MAP_HEIGHT {
        for x in 0 ..< MAP_WIDTH {
            idx: i32 = y * MAP_WIDTH + x
            if !seen[idx] {
                tx: i32 = 5
                ty: i32 = 1
                r: i32 = 127
                g: i32 = 64
                b: i32 = 96
                if x < 26 && y < 19 {
                    g = 127
                    b = 96
                    r = 64
                    tx = 6 + ( x + y ) % 2
                    ty = ( x + y ) % 2
                }
                if x > 49 {
                    r = i32(f64(r) * f64(0.40) * f64(1.50))
                    b = i32(f64(b) * f64(1.30) * f64(1.20))
                }
                if !known[idx] {
                    r = 96
                    g = 96
                    b = 96
                    tx = 3
                    ty = 0
                }
                myDrawTextureProRGBA(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8) + f32(4 * SCALE) + f32(shake_x), f32(y) * f32(SCALE_8) + f32(2 * SCALE) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, r / 3, g / 3, b / 3, 255)
            }
        }
    }
	
    if intro_hold {
        myDrawTexturePro(pre_game_tex_tex, 0, 0, f32(MAP_WIDTH * 8), f32(-MAP_HEIGHT * 8), f32(shake_x), f32(shake_y), f32(MAP_WIDTH * SCALE_8), f32(MAP_HEIGHT * SCALE_8), 0, 0, 0, rl.WHITE)
    }
}

map_update_visibility :: proc() {
    px: f64 = f64(entities[0].ix)
    py: f64 = f64(entities[0].iy)
    rx: f64
    ry: f64
    w: f64 = f64(0.30)
    for i in 0 ..< 45 {
        an: f64 = f64(i) * 8 * f64(3.141593) / 180.0
        dx: f64 = math.cos_f64(an)
        dy: f64 = math.sin_f64(an)
        for jj in 0 ..< 20 {
            j: f64 = f64(0.50) + f64(0.35) * f64(jj)
            rx = px + dx * j
            ry = py + dy * j
            x0: i32 = i32(rx - w)
            y0: i32 = i32(ry - w)
            x1: i32 = i32(rx - w)
            y1: i32 = i32(ry + w)
            x2: i32 = i32(rx + w)
            y2: i32 = i32(ry + w)
            x3: i32 = i32(rx + w)
            y3: i32 = i32(ry - w)
            c: i32 = 0
            if x0 > - 1 && y0 > - 1 && x0 < MAP_WIDTH && y0 < MAP_HEIGHT {
                idx: i32 = y0 * MAP_WIDTH + x0
                if - 1 == board[idx] {
                    c = c + 1
                }
            }
            if x1 > - 1 && y1 > - 1 && x1 < MAP_WIDTH && y1 < MAP_HEIGHT {
                idx: i32 = y1 * MAP_WIDTH + x1
                if - 1 == board[idx] {
                    c = c + 1
                }
            }
            if x2 > - 1 && y2 > - 1 && x2 < MAP_WIDTH && y2 < MAP_HEIGHT {
                idx: i32 = y2 * MAP_WIDTH + x2
                if - 1 == board[idx] {
                    c = c + 1
                }
            }
            if x3 > - 1 && y3 > - 1 && x3 < MAP_WIDTH && y3 < MAP_HEIGHT {
                idx: i32 = y3 * MAP_WIDTH + x3
                if - 1 == board[idx] {
                    c = c + 1
                }
            }
            ix: i32 = i32(rx)
            iy: i32 = i32(ry)
            idx: i32 = iy * MAP_WIDTH + ix
            seen[idx] = true
            if 0 == c {
                break
            }
        }
    }
}

item_new :: proc(x: i32, y: i32, sprite: i32, color: rl.Color, block_movement: bool, name: string, kind: enumtype) {
    i: item_s
    i.ix = x
    i.iy = y
    i.sprite = sprite
    i.color = color
    i.block_movement = block_movement
    i.name = name
    i.found = false
    i.kind = kind
    i.skip_update = - 1
	loot[num_loot] = i
	num_loot += 1
}

item_draw_all :: proc() {
    for i in 0 ..< num_loot {
        if loot[i].found {
            continue
        }
        sprite: i32 = loot[i].sprite
        tx: i32 = sprite % 8
        ty: i32 = ( sprite - tx ) / 8
        x: i32 = loot[i].ix
        y: i32 = loot[i].iy
        if !seen[y * MAP_WIDTH + x] {
            continue
        }
        dx: f64 = entities[0].px - f64(x)
        dy: f64 = entities[0].py - f64(y)
        dist: f64 = math.sqrt_f64(f64(dx * dx + dy * dy))
        if dist < f64(7.00) {
            if dist < f64(5.00) {
                myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8) + f32(shake_x), f32(y) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, loot[i].color)
            }
            else {
                myDrawTexturePro(icons, f32(tx * 8), f32(ty * 8), 8, 8, f32(x) * f32(SCALE_8) + f32(shake_x), f32(y) * f32(SCALE_8) + f32(shake_y), f32(SCALE_8), f32(SCALE_8), 0, 0, 0, DARKDARKGRAY)
            }
        }
        if x == entities[0].ix && y == entities[0].iy {
            found_text: string = fmt.tprintf("Found {}!", loot[i].name)
            if enumtype.POTION_HEALTH == loot[i].kind {
                if 9 == inventory[0] {
                    continue
                }
                inventory[0] = inventory[0] + 1
                add_note(found_text, rl.RED, f64(5.00))
            }
            else if enumtype.POTION_MANA == loot[i].kind {
                if 9 == inventory[0] {
                    continue
                }
                inventory[1] = inventory[1] + 1
                add_note(found_text, rl.GREEN, f64(5.00))
            }
            else if enumtype.TURKEY_LEG == loot[i].kind {
                entities[0].power = entities[0].power + 1
                add_note(found_text, rl.ORANGE, f64(5.00))
            }
            else if enumtype.ARM_SHIELD == loot[i].kind {
                entities[0].defense = entities[0].defense + 1
                found_shield = true
                add_note(found_text, rl.VIOLET, f64(5.00))
            }
            else if enumtype.ARM_MAIL == loot[i].kind {
                entities[0].defense = entities[0].defense + 1
                found_mail = true
                add_note(found_text, rl.VIOLET, f64(5.00))
            }
            else if enumtype.ARM_HELMET == loot[i].kind {
                entities[0].defense = entities[0].defense + 1
                found_helmet = true
                add_note(found_text, rl.VIOLET, f64(5.00))
            }
            else if enumtype.KEY == loot[i].kind {
                found_key = true
                add_note(found_text, rl.GOLD, f64(5.00))
            }
            if enumtype.ROD == loot[i].kind {
                found_rod = true
                add_note(found_text, rl.GREEN, f64(5.00))
                rl.PlaySound(snd_cast)
            }
            else if enumtype.HEART == loot[i].kind {
                note.txt = "LEVEL UP!"
                note.color = rl.PURPLE
                note.timer = f64(5.00)
                entities[0].level = entities[0].level + 1
                entities[0].max_health = i32(f64(entities[0].max_health) * ( f64(1.30) + f64(0.30) * rand.float64() ))
                entities[0].max_mana = entities[0].max_mana + 1
                entities[0].health = entities[0].max_health
                entities[0].mana = entities[0].max_mana
                rl.PlaySound(snd_levelup)
            }
            else {
                rl.PlaySound(snd_pickup)
            }
            loot[i].found = true
        }
    }
}

get_player_input :: proc() {

    move_dir: enumtype = enumtype.INVALID
	
    if rl.IsKeyDown(rl.KeyboardKey.ESCAPE) {
        quit_game = true
    }
	
    if 0 >= entities[0].health {
        add_note("YOU DIED!", rl.RED, f64(5.00))
        entities[0].block_movement = false
        entities[0].sprite = 47
        return 
    }
    idx: i32 = entities[0].iy * MAP_WIDTH + entities[0].ix
    key_delay = key_delay - 1
    if 0 > key_delay && intro_hold {
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            key_delay = 5
            if enumtype.INTRO == menu {
                menu = enumtype.CONTROLS
            }
            else if enumtype.CONTROLS == menu {
                menu = enumtype.GAME
                intro_hold = false
                rl.StopSound(snd_melody)
            }
            rl.PlaySound(snd_hurt)
        }
        return 
    }
    if 0 > key_delay && game_win && enumtype.WIN == menu {
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            quit_game = true
        }
        return 
    }
    if !game_win && !screen_shake {
        if rl.IsKeyDown(rl.KeyboardKey.UP) {
            move_dir = enumtype.MOVE_UP
        }
        if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
            move_dir = enumtype.MOVE_DOWN
        }
        if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
            move_dir = enumtype.MOVE_LEFT
        }
        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
            move_dir = enumtype.MOVE_RIGHT
        }
        if 0 > key_delay && found_rod && rl.IsKeyDown(rl.KeyboardKey.C) && 0 < entities[0].mana && 0 > entities[0].cooldown {
            px: f64 = entities[0].px
            py: f64 = entities[0].py
            vx: f64
            vy: f64
            speed: f64 = 8
            if enumtype.MOVE_UP == last_move {
                vy = - 1
            }
            else if enumtype.MOVE_DOWN == last_move {
                vy = 1
            }
            else if enumtype.MOVE_LEFT == last_move {
                vx = - 1
            }
            else if enumtype.MOVE_RIGHT == last_move {
                vx = 1
            }
            vx = vx * speed
            vy = vy * speed
            key_delay = 5
            entities[0].cooldown = f64(1.00)
            magic_ball.px = px
            magic_ball.py = py
            magic_ball.vx = vx
            magic_ball.vy = vy
            magic_ball.active = true
            entities[0].mana = entities[0].mana - 1
            rl.PlaySound(snd_cast)
        }
        if 0 > key_delay && 0 < inventory[0] && entities[0].health < entities[0].max_health && rl.IsKeyDown(rl.KeyboardKey.H) {
            inventory[0] = inventory[0] - 1
            entities[0].health = entities[0].max_health
			key_delay = 5
            rl.PlaySound(snd_potion)
        }
        if 0 > key_delay && 0 < inventory[1] && entities[0].mana < entities[0].max_mana && rl.IsKeyDown(rl.KeyboardKey.M) {
            inventory[1] = inventory[1] - 1
            entities[0].mana = entities[0].max_mana
			key_delay = 5
            rl.PlaySound(snd_potion)
        }
    }
    if 0 > key_delay {
        if enumtype.INVALID != move_dir {
            last_move = move_dir
            entity_move(0, move_dir)
            key_delay = 4
            map_update_visibility()
        }
    }
    kx: i32 = entities[0].kx
    ky: i32 = entities[0].ky
    if kx < 0 {
        entities[0].kx = kx + 1
    }
    if kx > 0 {
        entities[0].kx = kx - 1
    }
    if ky < 0 {
        entities[0].ky = ky + 1
    }
    if ky > 0 {
        entities[0].ky = ky - 1
    }
}




//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------

VERSION: string = "v1.0.0"
SCALE: i32 = 3
XRES: i32 = 600
XRES_HALF: i32 = XRES / 2
YRES: i32 = 320
YRES_HALF: i32 = YRES / 2
SCALE_8: i32 = SCALE * 8

DIR_UP: i32 = 0
DIR_DOWN: i32 = 1
DIR_LEFT: i32 = 2
DIR_RIGHT: i32 = 3

MAP_WIDTH: i32 = 75
MAP_HEIGHT: i32 = 36
MAP_SZ :: 3000

DARKDARKGRAY :: rl.Color{ 20, 20, 20, 255 }
DARKRED :: rl.Color{ 128, 20, 25, 255 }
SHARKGRAY :: rl.Color{ 34, 32, 39, 255 }
BITTERSWEET :: rl.Color{ 254, 111, 94, 255 }
CYAN :: rl.Color{ 0, 224, 224, 255 }


quit_game: bool
game_win: bool
last_move: enumtype = enumtype.MOVE_UP


found_helmet: bool
found_mail: bool
found_shield: bool
found_key: bool
found_rod: bool
found_tears: bool

phoenix_loc: i32
key_delay: i32
amort: i32


// textures
icons: rl.Texture
reveal: rl.Texture
gradient: rl.Texture

ceiling_tex: rl.RenderTexture2D
ceiling_tex_tex: rl.Texture
ground_tex: rl.RenderTexture2D
ground_tex_tex: rl.Texture
pre_game_tex: rl.RenderTexture2D
pre_game_tex_tex: rl.Texture


// fonts
fnt: rl.Font
fnt_sm: rl.Font

// notifications
note: notification

// sounds
snd_blip: rl.Sound
snd_hurt: rl.Sound
snd_attack: rl.Sound
snd_pickup: rl.Sound 
snd_potion: rl.Sound 
snd_ambient_1: rl.Sound
snd_ambient_2: rl.Sound
snd_ambient_3: rl.Sound
snd_cast: rl.Sound
snd_dead: rl.Sound
snd_door: rl.Sound
snd_levelup: rl.Sound
snd_shake: rl.Sound
snd_melody: rl.Sound

blip_timer: f64
ambient_timer: f64

screen_shake: bool
shake_sound_played: bool
t_shake_move: f64
t_shake_timer: f64 = 5
shake_x: f64
shake_y: f64
phoenix_frame: f64
t_clock: f64
t_game: f64

intro_hold: bool = true
menu: enumtype = enumtype.INTRO
t_win: f64

entities: [100]entity_s
num_entities: i32 = 0

flame: [6]rl.Color = { rl.YELLOW, rl.ORANGE, rl.WHITE, rl.RED, rl.ORANGE, rl.WHITE }
magic: [5]rl.Color = { rl.GREEN, rl.DARKGREEN, rl.YELLOW, rl.GREEN, rl.DARKGREEN }

torches: [25]vec2i
num_torches: i32 = 0
t_flames: f64
magic_ball: projectile_s

board: [MAP_SZ]i32
board2: [MAP_SZ]i32
board3: [MAP_SZ]i32
dist: [MAP_SZ]i32
dist2: [MAP_SZ]i32
seen: [MAP_SZ]bool
known: [MAP_SZ]bool

rooms: [100]room_s
num_rooms: i32 = 0

keep_going: bool
start_idx: i32
win_idx: i32

loot: [100]item_s
num_loot: i32 = 0
inventory: [2]int = { 1, 1 }


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

main :: proc() {
	fmt.printfln("test");
	
    rl.InitWindow(XRES * SCALE, YRES * SCALE, strings.clone_to_cstring(fmt.tprintf("Dungeon of the Phoenix {} - by Syn9", VERSION), context.temp_allocator))
    rl.SetExitKey(rl.KeyboardKey.KEY_NULL)
    rl.InitAudioDevice()
    rl.SetTargetFPS(60)
    rl.BeginDrawing()
    rl.ClearBackground(SHARKGRAY)
    rl.EndDrawing()
    
	icons = rl.LoadTexture("assets/icons.png")
    reveal = rl.LoadTexture("assets/reveal.png")
    gradient = rl.LoadTexture("assets/gradient.png")
    fnt = rl.LoadFont("assets/alagard.fnt")
    fnt_sm = rl.LoadFont("assets/font.png")
    
	snd_blip = rl.LoadSound("assets/sounds/blip.ogg")
    snd_hurt = rl.LoadSound("assets/sounds/hurt.ogg")
    snd_attack = rl.LoadSound("assets/sounds/attack.ogg")
    snd_pickup = rl.LoadSound("assets/sounds/pickup.ogg")
    snd_potion = rl.LoadSound("assets/sounds/potion.ogg")
    snd_ambient_1 = rl.LoadSound("assets/sounds/ambient-1.ogg")
    snd_ambient_2 = rl.LoadSound("assets/sounds/ambient-2.ogg")
    snd_ambient_3 = rl.LoadSound("assets/sounds/ambient-3.ogg")
    snd_cast = rl.LoadSound("assets/sounds/cast.ogg")
    snd_dead = rl.LoadSound("assets/sounds/dead.ogg")
    snd_door = rl.LoadSound("assets/sounds/door.ogg")
    snd_levelup = rl.LoadSound("assets/sounds/levelup.ogg")
    snd_shake = rl.LoadSound("assets/sounds/shake.ogg")
    snd_melody = rl.LoadSound("assets/sounds/melody.ogg")
	
	ceiling_tex = rl.LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
	ceiling_tex_tex = ceiling_tex.texture
	ground_tex = rl.LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
	ground_tex_tex = ground_tex.texture
	pre_game_tex = rl.LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
	pre_game_tex_tex = pre_game_tex.texture
	
	for {
        if gen_rooms() {
            break
        }
    }
	
    map_update_visibility()
    rl.PlaySound(snd_melody)
    t_clock = rl.GetTime()
	
	for {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        draw_map()
        if !intro_hold {
            item_draw_all()
            entity_draw_all()
        }
        ui_draw()
        rl.EndDrawing()
		
        amort = ( amort + 1 ) % 4
        get_player_input()
        entity_update_all()
		
        if rl.WindowShouldClose() || quit_game {
            break
        }
    }
	
    unload_sounds()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}

