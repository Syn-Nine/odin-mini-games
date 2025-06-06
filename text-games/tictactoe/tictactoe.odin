//-----------------------------------------------------------------------------
// Tic-Tac-Toe game by Syn9
// Tested with Odin version dev-2025-04-nightly:d9f990d
//-----------------------------------------------------------------------------

package main

import "core:math/rand"
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
util_rand_range :: proc(lhs: int, rhs: int) -> int {
	return lhs + rand.int_max(rhs - lhs)
}

//-----------------------------------------------------------------------------
util_str_to_int :: proc(val: string) -> int {
	return strconv.atoi(val)
}


//-----------------------------------------------------------------------------
// Global Enumeration
//-----------------------------------------------------------------------------

enumtype :: enum {
    ENUM_COMPUTER,
    ENUM_EMPTY,
    ENUM_PLAYER,
}


//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

check_win :: proc(who: enumtype) -> bool {
    ret: bool = false
    idx: int
    
    for row in 0 ..< 3 {
        idx = row * 3
        if who == board[idx] && who == board[idx + 1] && who == board[idx + 2] {
            ret = true
        }
    }
    for col in 0 ..< 3 {
        idx = col
        if who == board[idx] && who == board[idx + 3] && who == board[idx + 6] {
            ret = true
        }
    }
    if who == board[4] {
        if who == board[0] && who == board[8] {
            ret = true
        }
        else if who == board[2] && who == board[6] {
            ret = true
        }
    }
    
    if ret {
        if enumtype.ENUM_PLAYER == who {
            fmt.printfln("Player Wins!")
        }
        else {
            fmt.printfln("Computer Wins!")
        }
    }
    else {
        for i in 0 ..< SZ {
            if enumtype.ENUM_EMPTY == board[i] {
                break
            }
            if 8 == i {
                ret = true
                fmt.printfln("DRAW!")
            }
        }
    }
    return ret
}

draw_board :: proc() {
    fmt.printfln("/-----------\\ ")
    fmt.printf("| ")
    draw_cell(0)
    fmt.printf(" | ")
    draw_cell(1)
    fmt.printf(" | ")
    draw_cell(2)
    fmt.printfln(" | ")
    fmt.printfln("|---|---|---|")
    fmt.printf("| ")
    draw_cell(3)
    fmt.printf(" | ")
    draw_cell(4)
    fmt.printf(" | ")
    draw_cell(5)
    fmt.printfln(" | ")
    fmt.printfln("|---|---|---|")
    fmt.printf("| ")
    draw_cell(6)
    fmt.printf(" | ")
    draw_cell(7)
    fmt.printf(" | ")
    draw_cell(8)
    fmt.printfln(" | ")
    fmt.printfln("\\-----------/")
}

draw_cell :: proc(idx: int) {
    if enumtype.ENUM_EMPTY == board[idx] {
        fmt.printf(fmt.tprintf("{}", ( idx + 1 )))
    }
    else if enumtype.ENUM_PLAYER == board[idx] {
        fmt.printf("X")
    }
    else if enumtype.ENUM_COMPUTER == board[idx] {
        fmt.printf("O")
    }
}

get_player_input :: proc() {
    for {
        fmt.printfln("Enter the # for your choice (X)")
        temp: int = util_str_to_int(util_console_input())
        if temp > 0 && temp < 10 {
            if enumtype.ENUM_EMPTY == board[temp - 1] {
                board[temp - 1] = enumtype.ENUM_PLAYER
                break
            }
        }
        fmt.printfln("Invalid choice.")
    }
}

get_computer_input :: proc() {
    for {
        choice: int = util_rand_range(0, SZ)
        if enumtype.ENUM_EMPTY == board[choice] {
            board[choice] = enumtype.ENUM_COMPUTER
            break
        }
    }
}


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

SZ: int = 9
board: [9]enumtype

main :: proc() {
    for i in 0 ..< 9 - 1 {
        board[i] = enumtype.ENUM_EMPTY
    }
    
    fmt.printfln("Let's play Tic-Tac-Toe!")
    fmt.printfln("-----------------------------------------------------")
    for {
        draw_board()
        get_player_input()
        if check_win(enumtype.ENUM_PLAYER) {
            break
        }
        get_computer_input()
        if check_win(enumtype.ENUM_COMPUTER) {
            break
        }
    }
    draw_board()
}

