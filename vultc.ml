(*
The MIT License (MIT)

Copyright (c) 2014 Leonardo Laguna Ruiz, Carl Jönsson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*)
open LexerVult
open ParserVult
open Types
let main () =
  let _ = parsePrintExp "a" in
  let _ = parsePrintExp "a:b" in
  let _ = parsePrintExp "a(1,2)" in
  let _ = parsePrintExp "a:b()" in
  let _ = parsePrintExp "a:b(1,2)" in
  let _ = parsePrintExp "-a(1,2)+b*c+d/2" in
  let _ = parsePrintExp "a+b>0&&a/b||a==b" in
  let _ = parsePrintExp "()" in
  let _ = parsePrintExp "(a)" in
  let _ = parsePrintExp "(a,b)" in
  let _ = parsePrintStmtList "val a;" in
  let _ = parsePrintStmtList "mem a:num,b,c;" in
  let _ = parsePrintStmtList "val a:num=0;" in
  let _ = parsePrintStmtList "mem a=0,b:num=0;" in
  let _ = parsePrintStmtList "return -a;" in
  let _ = parsePrintStmtList "return (a,0);" in
  let _ = parsePrintStmtList "{ val a =0; return a; }" in
  let _ = parsePrintStmtList "{ return a; }" in
  let _ = parsePrintStmtList "if(a){ val a=0;return a;}" in
  let _ = parsePrintStmtList "if(a) return 0;" in
  let _ = parsePrintStmtList "if(a) return false; else return true;" in
  let _ = parsePrintStmtList "fun add(a,b) return a+b;" in
  let _ = parsePrintStmtList "fun add:int(a:int,b:int) return a+b;" in
  ()
;;
main ();;
