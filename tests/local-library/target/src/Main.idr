module Main
import Foo

main : IO ()
main = printLn "Hello World"

prf : (x : Nat) -> foo x === 1+x
prf x = Refl

