//-----------------------------------------------------------------------------
// Catfish Bouncer - Raylib minigame by Syn9
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
// Structure Definitions
//-----------------------------------------------------------------------------

game_data_s :: struct {
    // clock
    t_prev: f64,
    t_base: f64,
    t_delta: f64,

    // ball
    ball_x: f64,
    ball_y: f64,
    ball_dx: f64,
    ball_dy: f64,
    ball_speed: f64,
    
    // mouse
    mx: int,
    my: int,
    prev_mx: int,
    prev_my: int,
    dmx: f64,
    dmy: f64,
    
    // state
    YUM_MAX: f64,
    yumY: f64,
    fish: int,
    newBall: bool,
}


//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

draw_game_board :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    
    // testing text output
    rl.DrawText("Catfish Bouncer!", 20, 20, 20, TXT_COLOR)
    rl.DrawText(strings.clone_to_cstring(fmt.tprintf("fps: {}", int( 1 / game_data.t_delta )), context.temp_allocator), 20, 40, 20, TXT_COLOR)
    rl.DrawText(strings.clone_to_cstring(fmt.tprintf("clock: {}", f32(rl.GetTime() - game_data.t_base) ), context.temp_allocator), 20, 60, 20, TXT_COLOR)
    rl.DrawCircle(XRES_HALF, YRES_HALF, 30, CAT_COLOR)
    
    // draw cat
    w: f32 = 15
    h: f32 = 50
    rl.DrawTriangle({f32(XRES_HALF), f32(YRES_HALF)}, {f32(XRES_HALF) - w, f32(YRES_HALF) - h}, {f32(XRES_HALF) - w - w, f32(YRES_HALF)}, CAT_COLOR)
    rl.DrawTriangle({f32(XRES_HALF), f32(YRES_HALF)}, {f32(XRES_HALF) + w + w, f32(YRES_HALF)}, {f32(XRES_HALF) + w, f32(YRES_HALF) - h}, CAT_COLOR)
    
    // draw fish
    for i in 0 ..< game_data.fish {
        rl.DrawCircle(XRES_HALF + i32(( f64(i) - ( f64(game_data.fish) - f64(1.00) ) / 2.0 ) * 12.0), YRES_HALF + 50, 5, YUM_COLOR)
    }
    
    // draw ball
    if !game_data.newBall {
        rl.DrawCircle(i32(game_data.ball_x), i32(game_data.ball_y), f32(BALL_RADIUS), BALL_COLOR)
    }
    
    // draw yum text
    game_data.yumY = game_data.yumY - game_data.t_delta
    if game_data.yumY > 0 {
        rl.DrawText("YUM!", XRES_HALF - 50, YRES_HALF - 50 - i32(game_data.YUM_MAX * ( 1 - game_data.yumY )), 40, YUM_COLOR)
    }
    
    // draw paddles
    rl.DrawRectangle(i32(game_data.mx) - i32(PADDLE_W), 0, i32(PADDLE_W) * 2, i32(PADDLE_H), PADDLE_COLOR)
    rl.DrawRectangle(i32(game_data.mx) - i32(PADDLE_W), i32(YRES) - i32(PADDLE_H), i32(PADDLE_W) * 2, i32(PADDLE_H), PADDLE_COLOR)
    rl.DrawRectangle(0, i32(game_data.my) - i32(PADDLE_W), i32(PADDLE_H), i32(PADDLE_W) * 2, PADDLE_COLOR)
    rl.DrawRectangle(i32(XRES) - i32(PADDLE_H), i32(game_data.my) - i32(PADDLE_W), i32(PADDLE_H), i32(PADDLE_W) * 2, PADDLE_COLOR)
    rl.EndDrawing()
}


// game logic
update_game_state :: proc() {
    // mouse delta for moving paddles and applying friction
    game_data.prev_mx = game_data.mx
    game_data.prev_my = game_data.my
    game_data.mx = int(rl.GetMouseX())
    game_data.my = int(rl.GetMouseY())
    game_data.dmx = game_data.dmx * f64(0.80) + f64( game_data.mx - game_data.prev_mx ) * ( 1 - f64(0.80) )
    game_data.dmy = game_data.dmy * f64(0.80) + f64( game_data.my - game_data.prev_my ) * ( 1 - f64(0.80) )
    
    // time delta for animation
    t_clock: f64 = rl.GetTime()
    game_data.t_delta = ( t_clock - game_data.t_prev )
    game_data.t_prev = t_clock
    
    // is ball outside of game board?
    if ( game_data.yumY < 0 && game_data.newBall ) || PADDLE_H > game_data.ball_x || f64(XRES) - PADDLE_H < game_data.ball_x || PADDLE_H > game_data.ball_y || f64(YRES) - PADDLE_H < game_data.ball_y {
        // initialize position
	game_data.ball_x = 100.0 + rand.float64() * ( f64(XRES_HALF) - 200.0 )
        if rand.float64() < f64(0.50) {
            game_data.ball_x = f64(XRES_HALF) + game_data.ball_x
        }
        game_data.ball_y = 100.0 + rand.float64() * ( f64(YRES) - 200.0 )
	
	// initialize velocity
        game_data.ball_speed = START_SPEED
        angle: f64 = rand.float64() * f64(3.141593) * f64(2.00)
        game_data.ball_dx = game_data.ball_speed * math.cos_f64(angle)
        game_data.ball_dy = game_data.ball_speed * math.sin_f64(angle)
        game_data.newBall = false
    }
    // update ball state
    if !game_data.newBall {
        // integrate ball location
        game_data.ball_x = game_data.ball_x + game_data.ball_dx * game_data.t_delta
        game_data.ball_y = game_data.ball_y + game_data.ball_dy * game_data.t_delta
	
	// top/bottom bounce
        if game_data.ball_x > f64(game_data.mx) - PADDLE_W && game_data.ball_x < f64(game_data.mx) + PADDLE_W {
            if game_data.ball_y - BALL_RADIUS < PADDLE_H || game_data.ball_y + BALL_RADIUS > YRES - PADDLE_H {
                game_data.ball_dy = - game_data.ball_dy
                game_data.ball_y = PADDLE_H + BALL_RADIUS
                if math.sign_f64(game_data.ball_dy) < 0 {
                    game_data.ball_y = YRES - PADDLE_H - BALL_RADIUS
                }
                game_data.ball_dx = game_data.ball_dx + game_data.dmx * game_data.ball_speed / 20
                game_data.ball_speed = game_data.ball_speed + INC_SPEED
            }
        }
	
	// left/right bounce
        if game_data.ball_y > f64(game_data.my) - PADDLE_W && game_data.ball_y < f64(game_data.my) + PADDLE_W {
            if game_data.ball_x - BALL_RADIUS < PADDLE_H || game_data.ball_x + BALL_RADIUS > XRES - PADDLE_H {
                game_data.ball_dx = - game_data.ball_dx
                game_data.ball_x = PADDLE_H + BALL_RADIUS
                if math.sign_f64(game_data.ball_dx) < 0 {
                    game_data.ball_x = XRES - PADDLE_H - BALL_RADIUS
                }
                game_data.ball_dy = game_data.ball_dy + game_data.dmy * game_data.ball_speed / 20
                game_data.ball_speed = game_data.ball_speed + INC_SPEED
            }
        }
	
	// check for feed
        if game_data.yumY < 0 && game_data.ball_x > f64(XRES_HALF) - FEED_RADIUS && game_data.ball_x < f64(XRES_HALF) + FEED_RADIUS && game_data.ball_y > f64(YRES_HALF) - FEED_RADIUS && game_data.ball_y < f64(YRES_HALF) + FEED_RADIUS {
            game_data.yumY = f64(1.00)
            game_data.newBall = true
            game_data.fish = game_data.fish + 1
        }
    }
}


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

// window res
XRES :: 800
YRES :: 600
XRES_HALF: i32 = XRES / 2.0
YRES_HALF: i32 = YRES / 2.0

// entity colors
BG_COLOR := rl.RAYWHITE
CAT_COLOR := rl.ORANGE
TXT_COLOR := rl.LIGHTGRAY
YUM_COLOR := rl.SKYBLUE
BALL_COLOR := rl.SKYBLUE
PADDLE_COLOR := rl.GRAY

// game constants
START_SPEED: f64 = 300
INC_SPEED: f64 = 20
BALL_RADIUS: f64 = 20
FEED_RADIUS: f64 = 50
PADDLE_W: f64 = 50
PADDLE_H: f64 = 10

// global game structure
game_data: game_data_s

main :: proc() {
    rl.InitWindow(XRES, YRES, "Catfish Bouncer")
    rl.SetTargetFPS(60)
    game_data.YUM_MAX = 100
    game_data.t_prev = rl.GetTime()
    game_data.t_base = rl.GetTime()

    for {
        update_game_state()
        draw_game_board()
        if rl.WindowShouldClose() {
            break
        }
    }

    rl.CloseWindow()
}

