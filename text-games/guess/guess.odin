//-----------------------------------------------------------------------------
// Guess the number game by Syn9
// Tested with Odin version dev-2025-04-nightly:d9f990d
//-----------------------------------------------------------------------------

package main

import "core:math/rand"
import "core:math"
import "core:fmt"
import "core:os"
import "core:strconv"

//-----------------------------------------------------------------------------
//  Utility Functions
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
console_input :: proc() -> string {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	return fmt.tprintf(string(buf[:n]))
}

//-----------------------------------------------------------------------------
string_to_int :: proc(val: string) -> int {
	return strconv.atoi(val)
}

//-----------------------------------------------------------------------------
rand_range :: proc(lhs: int, rhs: int) -> int {
	return lhs + rand.int_max(rhs - lhs)
}

//-----------------------------------------------------------------------------
str_cat :: proc(lhs: string, rhs: string) -> string {
	return fmt.tprintf("{}{}", lhs, rhs)
}



//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

main :: proc()
{

    tries: int = 6
    secret: int = rand_range(1, 19 + 1)

    for tries > 0
    {
        fmt.printfln("Enter a guess between 0 and 20, {} tries remaining", tries)

        guess: int = string_to_int(console_input())
        if guess < secret
        {
            fmt.println("Too Small")
        }
        else if guess > secret
        {
            fmt.println("Too Large")
        }
        else
        {
            fmt.println("You Win!")
            tries = 0
        }

        tries = tries - 1
        if 0 == tries
        {
            fmt.println("Game Over")
        }
    }
}

