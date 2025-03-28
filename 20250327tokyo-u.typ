
#import "@preview/js:0.1.0": *
 // or put your modified `js.typ` in the same folder and `#import "js.typ": *`

#show: js.with(
  lang: "ja",
  seriffont: "New Computer Modern",
  seriffont-cjk: "BIZ UDPMincho" , // or "Yu Mincho" or "Hiragino Mincho ProN"
  sansfont: "Helvetica", // or "Arial" or "Helvetica"
  sansfont-cjk: "BIZ UDPGothic", // or "Yu Gothic" or "Hiragino Kaku Gothic ProN"
  paper: "a4", // "a*", "b*", or (paperwidth, paperheight) e.g. (210mm, 297mm)
  fontsize: 9pt,
  baselineskip: auto,
  textwidth: auto,
  lines-per-page: auto,
  book: false, // or true
  cols: 1, // 1, 2, 3, ...
  non-cjk: regex("[\u0000-\u2023]"),  // or "latin-in-cjk" or any regex
  cjkheight: 0.88, // height of CJK in em
)

#maketitle(
  title: "2025年 東京大学・理系 数学",
  authors: "清水 団",
  // authors: ("奥村 晴彦", "何野 何某"),
  // authors: (("奥村 晴彦", "三重大"), ("何野 何某", "某大")),
  // authors: (("奥村 晴彦", "三重大", "okumura@okumuralab.org"), ("何野 何某", "某大")),
//   abstract: [
  //  ]
)

// #outline() #v(1em)

#set enum(numbering: "(1)",)
 
#set heading(numbering: "第1問")
 
 
=

座標平面上の点 $"A"(0,0)$, $"B"(0,1)$, $"C"(1,1)$, $"D"(1,0)$ を考える。
実数 $0 < t < 1$ に対して、線分 $"AB"$, $"BC"$, $"CD"$ を $t:(1-t)$ に内分する点をそれぞれ $"P"_t$, $"Q"_t$, $"R"_t$ とし、
線分 $"P"_t "Q"_t$, $"Q"_t "R"_t$ を $t:(1-t)$ に内分する点をそれぞれ $"S"_t$, $"T"_t$ とする。
さらに、線分 $"S"_t "T"_t$ を $t:(1-t)$ に内分する点を $"U"_t$ とする。
また、点 $"A"$ を $"U"_0$, 点 $"D"$ を $"U"_1$ とする。

+ 点 $U_t$ の座標を求めよ。
+ $t$ が $0 lt.equiv t lt.equiv 1$ の範囲を動くときに点 $"U"_t$ が描く曲線と、線分 $"AD"$ で囲まれた部分の面積を求めよ。
+ $a$ を $0 < a < 1$ を満たす実数とする。$t$ が $0 lt.equiv t lt.equiv a$ の範囲を動くときに点 $"U"_t$ が描く曲線の長さを、$a$ の多項式の形で求めよ。

= 

1. $x > 0$ のとき、不等式 $log x lt.equiv x - 1$ を示せ。

2. 次の極限を求めよ。

   $ lim_(n → ∞) n ∫_1^2 log ( (1 + x^(1/n)) / 2 ) d x $

= 

平行四辺形 $"ABCD"$ において、$∠"ABC" = display(π / 6)$, $"AB" = a$, $"BC" = b$, $a ≦ b$ とする。
次の条件を満たす長方形 $"EFGH"$ を考え、その面積を $S$ とする。

条件：点 $"A", "B", "C", "D"$ はそれぞれ辺 $"EF", "FG", "GH", "HE"$ 上にある。
ただし、辺はその両端の点も含むものとする。

1. $∠"BCG" = θ$ とするとき、$S$ を $a, b, θ$ を用いて表せ。
2. $S$ のとりうる値の最大値を $a, b$ を用いて表せ。

= 

この問いでは、0 以上の整数の 2 乗になる数を平方数と呼ぶ。$a$ を正の整数とし、
$f_a (x) = x^2 + x - a$ とおく。

1. $n$ を正の整数とする。$f_a (n)$ が平方数ならば、$n ≤ a$ であることを示せ。

2. $f_a (n)$ が平方数となる正の整数 $n$ の個数を $N_a$ とおく。次の条件 (i), (ii) が同値であることを示せ。

   (i) $N_a = 1$ である。

   (ii) $4a + 1$ は素数である。

#pagebreak()

= 

$n$ を 2 以上の整数とする。1 から $n$ までの数字が書かれた札が各 1 枚ずつ合計 $n$ 枚あり、横一列におかれている。
1 以上 $(n-1)$ 以下の整数 $i$ に対して、次の操作 $(T_i)$ を考える。

- $(T_i)$ 左から $i$ 番目の札の数字が、左から $(i+1)$ 番目の札の数字よりも大きければ、これら 2 枚の札の位置を入れかえる。
  そうでなければ、札の位置をかえない。

最初の状態において札の数字は左から $A_1, A_2, …, A_n$ であったとする。
この状態から $(n-1)$ 回の操作 $(T_1), (T_2), …, (T_(n-1))$ を順に行った後、続けて $(n-1)$ 回の操作 $(T_(n-1)), …, (T_2), (T_1)$ を順に行ったところ、
札の数字は左から $1, 2, …, n$ と小さい順に並んだ。以下の問いに答えよ。

1. $A_1$ と $A_2$ のうち少なくとも一方は 2 以下であることを示せ。

2. 最初の状態としてありうる札の数字の並び方 $A_1, A_2, …, A_n$ の総数を $c_n$ とする。
   $n$ が 4 以上の整数であるとき、$c_n$ を $c_(n-1)$ と $c_(n-2)$ を用いて表せ。


= 

複素数平面上の点 $display(1/2)$ を中心とする半径 $display(1/2)$ の円の周から原点を除いた曲線を $C$ とする。

1. 曲線 $C$ 上の複素数 $z$ に対し、$display(1/z)$ の実部は 1 であることを示せ。

#v(3mm)

2. $α, β$ を曲線 $C$ 上の相異なる複素数とするとき、$display(1/α^2 + 1/β^2)$ がとりうる範囲を複素数平面上に図示せよ。
#v(3mm)


3. $γ$ を (2) で求めた範囲に属さない複素数とするとき、$display(1/γ)$ の実部がとりうる値の最大値と最小値を求めよ。