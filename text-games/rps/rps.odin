//-----------------------------------------------------------------------------
// Rock, Paper, Scissors game by Syn9
// Tested with Odin version dev-2025-04-nightly:d9f990d
//-----------------------------------------------------------------------------

package main

import "core:math/rand"
import "core:fmt"
import "core:os"
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
util_str_equal :: proc(lhs: string, rhs: string) -> bool {
	return 0 == strings.compare(lhs, rhs)
}



//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

main :: proc()
{
    p_score: int
    c_score: int
    tries: int = 3
    max: int = tries

    ROCK: int = 0
    PAPER: int = 1
    SCISSORS: int = 2
    
    INVALID: int = 3
    TIE: int = 0
    PLAYER_WIN: int = 1
    COMPUTER_WIN: int = 2
    
    fmt.println("Let's play Rock-Paper-Scissors!")
    for tries > 0 {
        fmt.printf("Best out of {}, {} tries remaining. ", max, tries)
        fmt.println("What is your guess? [r]ock, [p]aper, or [s]cissors?")

        guess: int = INVALID
        for {
            s: string = util_console_input()
            if util_str_equal("r", s) {
                guess = ROCK
            }
            else if util_str_equal("p", s) {
                guess = PAPER
            }
            else if util_str_equal("s", s) {
                guess = SCISSORS
            }
            else {
                fmt.println("input invalid.")
            }
            if INVALID != guess {
                break
            }
        }
	
        choice: string
        if ROCK == guess {
            choice = "Rock"
        }
        else if PAPER == guess {
            choice = "Paper"
        }
        else if SCISSORS == guess {
            choice = "Scissors"
        }
        fmt.printfln("Player: {}", choice)
	
        comp: int = util_rand_range(0, 3)
        if ROCK == comp {
            choice = "Rock"
        }
        else if PAPER == comp {
            choice = "Paper"
        }
        else if SCISSORS == comp {
            choice = "Scissors"
        }
        fmt.printfln("Computer: {}", choice)
	
        result: int = TIE
        if ( ROCK == comp && SCISSORS == guess ) || ( SCISSORS == comp && PAPER == guess ) || ( PAPER == comp && ROCK == guess ) {
            result = COMPUTER_WIN
        }
        else if ( ROCK == guess && SCISSORS == comp ) || ( SCISSORS == guess && PAPER == comp ) || ( PAPER == guess && ROCK == comp ) {
            result = PLAYER_WIN
        }
	
        tries = tries - 1
        if TIE == result {
            fmt.println("Tie!")
            tries = tries + 1
        }
        else if COMPUTER_WIN == result {
            fmt.println("Computer Score!")
            c_score = c_score + 1
        }
        else if PLAYER_WIN == result {
            fmt.println("Player Score!")
            p_score = p_score + 1
        }
	
        fmt.printfln("Score: Player: {}, Computer: {}", p_score, c_score)
    }
    
    if p_score == c_score {
        fmt.println("GAME TIED!")
    }
    else if p_score > c_score {
        fmt.println("PLAYER WINS GAME!")
    }
    else {
        fmt.println("COMPUTER WINS GAME!")
    }
}

