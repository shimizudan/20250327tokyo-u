// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#show: doc => article(
  title: [大学入試（数学）とJulia言語],
  authors: (
    ( name: [清水　団　Dan Shimizu],
      affiliation: [],
      email: [] ),
    ),
  date: [2025-03-23],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)
#import "@preview/fontawesome:0.1.0": *


= はじめに
<はじめに>
#box(image("327001_files/mediabag/pic29.png"))

#pagebreak()
= 自己紹介
<自己紹介>
- 清水　団（しみず・だん）
- 東京都板橋区 城北中学校・高等学校 に数学科の教員として勤務
- 2025年度より校長です。

#pagebreak()
= Julia言語のについて
<julia言語のについて>
#link("https://julialang.org")

#box(image("327001_files/mediabag/pic24.png"))

Juliaは統計処理や科学技術計算、機械学習に強いプログラミング言語といわれています。 例えばStatsBase.jlやDistributions.jlなどのパッケージを使用すると、統計モデリングや仮説検定、回帰分析、時系列分析などの統計処理を行えます。

#pagebreak()
= 東京大(理系）2025・数学
<東京大理系2025数学>
2025年2月25日に行われた東京大学の入学試験の理系の数学の問題を#strong[Julia言語];を用いて，「解く」というよりも「考えて」みました。コードを書くときはできるだけ，`julia`のパッケージを利用しました。

また，#link("https://quarto.org")[quarto];というパブリッシング・システムを用いてWebページを作成しました。基本`Markdown`で，コードの読み込みも容易です。今回は利用していませんが，新たな数式処理の#link("https://typst.app")[typst];も実装可能です。

#pagebreak()
== 第1問
<第1問>
This is an equation: $underbrace(e^(i pi), -1) + 1 = 0$

$underbrace(e^(i pi), -1) + 1 = 0$
#block[
#callout(
body: 
[
座標空間内の点 $upright(A) (0 , med - 1 , med 1)$をとる.~$x y$平面上の点Pが次の条件 (i),~(ii),~(iii) をすべて満たすとする.

(i)　P は原点 O と異なる.

(ii)　$angle upright(A O P) gt.equiv 2 / 3 pi$

(iii)　$angle upright(O A P) lt.equiv pi / 6$

P がとりうる範囲を $x y$平面上に図示せよ.

]
, 
title: 
[
第1問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
$upright("A") (0 , - 1 , 1)$，$upright("P") (x , y , 0)$として，

$ frac(arrow(upright("OA")) dot.op arrow(upright("OP")), #scale(x: 120%, y: 120%)[\|] arrow(upright("OA")) #scale(x: 120%, y: 120%)[\|] #scale(x: 120%, y: 120%)[\|] arrow(upright("OP")) #scale(x: 120%, y: 120%)[\|]) lt.equiv cos frac(2 pi, 3) thin and thin cos pi / 6 lt.equiv frac(arrow(upright("AO")) dot.op arrow(upright("AP")), #scale(x: 120%, y: 120%)[\|] arrow(upright("AO")) #scale(x: 120%, y: 120%)[\|] #scale(x: 120%, y: 120%)[\|] arrow(upright("AP")) #scale(x: 120%, y: 120%)[\|]) $

- 線形代数パッケージ`LinearAlgebra.jl` を利用
- 描画パッケージ `Plots.jl` を利用

]
, 
title: 
[
julia言語で図示するコード作成
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using LinearAlgebra , Plots


function val1(x,y)
    A = [ 0 -1 1 ]
    P = [ x y 0]
    dot(A, P) / norm(A,2) / norm(P,2)
end

function val2(x,y)
    A = [ 0 -1 1 ]
    P = [ x y 0]
    dot(-A, P-A) / norm(-A,2) / norm(P-A,2)
end

function f(x,y)
    if x == y == 0
        return 0
    elseif val1(x,y) <= cos(2π/3) && cos(π/6) <= val2(x,y) 
        return 1
    else 0.8
    end
end

contour(-3:0.01:3 , -3:0.01:3 ,f,fill=true,aspectratio=true)
```

#figure([
#box(image("327001_files/figure-typst/cell-2-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
範囲を図示
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#pagebreak()
== 第2問
<第2問>
#block[
#callout(
body: 
[
次の関数 $f (x)$を考える.

$ f (x) = integral_0^1 frac(lr(|t - x|), 1 + t^2) med d t med med (0 lt.equiv x lt.equiv 1) $

(1)　$0 < alpha < pi / 4$を満たす実数 $alpha$で,~$f^prime (tan alpha) = 0$となるものを求めよ.

(2)　(1) で求めた $alpha$に対し,~$tan alpha$の値を求めよ.

(3)　関数 $f (x)$の区間 $0 lt.equiv x lt.equiv 1$における最大値と最小値を求めよ.~必要ならば,~$0.69 < log 2 < 0.7$であることを用いてよい.

]
, 
title: 
[
第2問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- 数値積分パッケージ `QuadGK.jl`を利用
- 描画パッケージ `Plots.jl` を利用
- 最小値求値パッケージ `Optim.jl` を利用

]
, 
title: 
[
julia言語で最大値・最小値を求めるコードを作成
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using QuadGK , Plots


f(x) = quadgk(t -> abs(t-x)/(1+t^2), 0, 1)[1]

plot(f,xlim=(0,1),label="y=f(x)")
```

#figure([
#box(image("327001_files/figure-typst/cell-3-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
関数を定義してグラフを作成
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
```julia
using QuadGK , Optim


f(x) = quadgk(t -> abs(t-x)/(1+t^2), 0, 1)[1]
g(x) = -f(x)

minf = optimize(f, 0.0, 1.0)
maxf = optimize(g, 0.0, 1.0)

println("x=",minf |> Optim.minimizer,"のとき最小値",minf |> Optim.minimum)

println("x=",maxf |> Optim.minimizer,"のとき最大値",maxf |> Optim.minimum |> x -> -x)
```

#block[
```
x=0.414224911677881のとき最小値0.18822640711914512
x=0.999999984947842のとき最大値0.43882456129553843
```

]
]
#pagebreak()
== 第3問
<第3問>
#block[
#callout(
body: 
[
座標平面上を次の規則 (i),~(ii) に従って 1 秒ごとに動く点 P を考える.

(i)　最初に,~Pは点 $(2 , med 1)$にいる.

(ii)　ある時刻で P が点 $(a , med b)$にいるとき,~その 1 秒後には P は

- 確率 $1 / 3$で $x$軸に関して $(a , med b)$と対称な点

- 確率 $1 / 3$で $y$軸に関して $(a , med b)$と対称な点

- 確率 $1 / 6$で直線 $y = x$に関して $(a , med b)$と対称な点

- 確率 $1 / 6$で直線 $y = - x$に関して $(a , med b)$と対称な点

にいる.

以下の問に答えよ. ただし,~(1)については,~結論のみを書けばよい.

(1)　Pがとりうる点の座標をすべて求めよ.

(2)　$n$を正の整数とする.~最初から $n$秒後に P が点 $(2 , med 1)$にいる確率と,~最初から $n$秒後に P が点 $(- 2 , med - 1)$にいる確率は等しいことを示せ.

(3)　$n$を正の整数とする.~最初から $n$秒後に P が点 $(2 , med 1)$にいる確率を求めよ.

]
, 
title: 
[
第3問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
行列で考える。求める確率は$a_n$

- $vec(a_n, b_n, c_n, d_n, e_n, f_n, g_n, h_n, ) = 1 / 6^(n - 1) mat(delim: "(", 0, 1, 0, 2, 0, 1, 0, 2; 1, 0, 2, 0, 1, 0, 2, 0; 0, 2, 0, 1, 0, 2, 0, 1; 2, 0, 1, 0, 2, 0, 1, 0; 0, 1, 0, 2, 0, 1, 0, 2; 1, 0, 2, 0, 1, 0, 2, 0; 0, 2, 0, 1, 0, 2, 0, 1; 2, 0, 1, 0, 2, 0, 1, 0; #none)^(n - 1) vec(1, 0, 0, 0, 0, 0, 0, 0, )$

]
, 
title: 
[
Julia言語で$n$秒後の確率を求めるコードを作成
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
#block[
```julia
function f(n)
    A = 1//6* [
    0 1 0 2 0 1 0 2
    1 0 2 0 1 0 2 0
    0 2 0 1 0 2 0 1
    2 0 1 0 2 0 1 0
    0 1 0 2 0 1 0 2
    1 0 2 0 1 0 2 0
    0 2 0 1 0 2 0 1
    2 0 1 0 2 0 1 0
    ]

    X = [
    1
    0
    0
    0
    0
    0
    0
    0
    ]

    if n == 1
        return X[1]
    else
        for i = 1:n-1
            X = A*X
        end
        return X[1]
    end
end

for j = 1:10
    println("n=$j のとき，確率は",f(j))
end
```

#block[
```
n=1 のとき，確率は1
n=2 のとき，確率は0//1
n=3 のとき，確率は5//18
n=4 のとき，確率は0//1
n=5 のとき，確率は41//162
n=6 のとき，確率は0//1
n=7 のとき，確率は365//1458
n=8 のとき，確率は0//1
n=9 のとき，確率は3281//13122
n=10 のとき，確率は0//1
```

]
]
#pagebreak()
== 第4問
<第4問>
#block[
#callout(
body: 
[
$f (x) = - sqrt(2) / 4 x^2 + 4 sqrt(2)$とおく.~$0 < t < 4$を満たす実数 $t$に対し,~座標平面上の点 $(t , med f (t))$を通り,~この点において放物線 $y = f (x)$と共通の接線を持ち,~ $x$軸上に中心を持つ円を $C_t$とする.

(1)　円 $C_t$の中心の座標を $(c (t) , med 0)$,~半径を $r (t)$とおく.~$c (t)$と ${ r (t) }^2$を $t$の整式で表せ.

(2)　実数$a$は $0 < a < f (3)$を満たすとする.~円 $C_t$が点 $(3 , med a)$を通るような実数 $t$は $0 < t < 4$ の範囲にいくつあるか.

]
, 
title: 
[
第4問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
+ 関数を定義してグラフを作成

- $f (x) = - sqrt(2) / 4 x^2 + 4 sqrt(2)$

- $c (t) = frac(f (t), f prime (t)) + t$

- $r (t) = sqrt((t - c (t))^2 + f (t)^2)$

- $g (t) = r (t)^2 - (3 - c (t))^2$

- $h (t) = - g (t)$

- $y = g (t)$のグラフを見る

- $y = a^2$のグラフを$0 < a^2 < f (3)^2$の範囲で考える。

#block[
#set enum(numbering: "1.", start: 2)
+ 個数を調べるための極値・端点を調べる。
]

- 自動微分パッケージ `Zygote.jl` を利用 \
- 描画パッケージ `Plots.jl` を利用
- 最小値求値パッケージ `Optim.jl` を利用

]
, 
title: 
[
Julia言語で実数$t$の個数を図で確認
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using Zygote , Plots
f(x) = -sqrt(2)/4 *x^2+4*sqrt(2)
c(t) = f(t)*f'(t)+t
r(t) = sqrt((t-c(t))^2+f(t)^2)
g(t) = r(t)^2-(3-c(t))^2

plot(g,xlim=(0,4),label="y=g(x)")
plot!(x->0,label="y=0")
plot!(x->f(3)^2,label="y=f(3)^2=$(f(3)^2)")
```

#figure([
#box(image("327001_files/figure-typst/cell-6-output-1.svg"))
], caption: figure.caption(
position: bottom, 
[
関数を定義してグラフを作成
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
```julia
using Zygote , Optim
f(x) = -sqrt(2)/4 *x^2+4*sqrt(2)
c(t) = f(t)*f'(t)+t
r(t) = sqrt((t-c(t))^2+f(t)^2)
g(t) = r(t)^2-(3-c(t))^2
h(t) = -g(t)

println( optimize(g, 1.0 , 3.0))

println( optimize(h, 2.0 , 4.0))

println( optimize(g, 3.0 , 4.0))
```

#block[
```
Results of Optimization Algorithm
 * Algorithm: Brent's Method
 * Search Interval: [1.000000, 3.000000]
 * Minimizer: 2.000000e+00
 * Minimum: 5.000000e+00
 * Iterations: 15
 * Convergence: max(|x - x_upper|, |x - x_lower|) <= 2*(1.5e-08*|x|+2.2e-16): true
 * Objective Function Calls: 16
Results of Optimization Algorithm
 * Algorithm: Brent's Method
 * Search Interval: [2.000000, 4.000000]
 * Minimizer: 3.000000e+00
 * Minimum: -6.125000e+00
 * Iterations: 12
 * Convergence: max(|x - x_upper|, |x - x_lower|) <= 2*(1.5e-08*|x|+2.2e-16): true
 * Objective Function Calls: 13
Results of Optimization Algorithm
 * Algorithm: Brent's Method
 * Search Interval: [3.000000, 4.000000]
 * Minimizer: 4.000000e+00
 * Minimum: -9.999988e-01
 * Iterations: 33
 * Convergence: max(|x - x_upper|, |x - x_lower|) <= 2*(1.5e-08*|x|+2.2e-16): true
 * Objective Function Calls: 34
```

]
]
#pagebreak()
== 第5問
<第5問>
#block[
#callout(
body: 
[
座標空間内に3点 $upright(A) (1 , med 0 , med 0) , med upright(B) (0 , med 1 , med 0) , med upright(C) (0 , med 0 , med 1)$をとり,~D を線分 AC の中点とする.~三角形 ABD の周および内部を $x$軸のまわりに 1 回転させて得られる立体の体積を求めよ.

]
, 
title: 
[
第5問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- パラメータを$0 lt.equiv k lt.equiv 1 , 0 lt.equiv theta < 2 pi$とする。

- 内側の曲面

  - $0 lt.equiv k lt.equiv 1 / 3$のとき

    $ (x , y , z) = (k , sqrt((1 - 2 k)^2 + k^2) cos theta , sqrt((1 - 2 k)^2 + k^2) sin theta) $

  - $1 / 3 lt.equiv k lt.equiv 1$のとき

    $ (x , y , z) = (k , frac(1 - k, sqrt(2)) dot.op cos theta , frac(1 - k, sqrt(2)) dot.op sin theta) $

- 外側の曲面 $ (x , y , z) = (k , (1 - k) cos theta , (1 - k) sin theta) $

]
, 
title: 
[
Julia言語で回転体を見てみよう
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using Plots
plotlyjs()

A = [1,0,0]
B = [0,1,0]
C = [0,0,1] 
f(u,v) = A+(u/2 *(C-A)+(1-u)*(B-A))*v
us = vs = range(0, 1, length=10)

x = [f(u,v)[1] for u in us , v in vs]
y = [f(u,v)[2] for u in us , v in vs]
z = [f(u,v)[3] for u in us , v in vs]

surface(x,y,z,xlabel="x",ylabel="y",zlabel="z",size=(700,500),color=:yellow)

function uchigawa(k,θ)
    if 0≤k≤1/3
        [k,sqrt((1-2k)^2+k^2)*cos(θ),sqrt((1-2k)^2+k^2)*sin(θ)]
    elseif 1/3≤k≤1
        [k,(1-k)/sqrt(2) *cos(θ),(1-k)/sqrt(2) *sin(θ)]
    end
end

n=100
ks = range(0, 1, length=n)
θs = range(0 ,2π,length=n)

x = [uchigawa(k,θ)[1] for k in ks , θ in θs]
y = [uchigawa(k,θ)[2] for k in ks , θ in θs]
z = [uchigawa(k,θ)[3] for k in ks , θ in θs]


surface!(x,y,z,xlabel="x",ylabel="y",zlabel="z",size=(700,500),alpha=0.7,color=:red)

sotogawa(k,θ) = [k,(1-k)*cos(θ),(1-k)*sin(θ)]
n=100
ks = range(0, 1, length=n)
θs = range(0 ,2π,length=n)

x = [sotogawa(k,θ)[1] for k in ks , θ in θs]
y = [sotogawa(k,θ)[2] for k in ks , θ in θs]
z = [sotogawa(k,θ)[3] for k in ks , θ in θs]


surface!(x,y,z,xlabel="x",ylabel="y",zlabel="z",size=(700,500),alpha=0.5,color=:blue)
```

```
WebIO._IJuliaInit()
```

#block[
#box(image("327001_files/figure-typst/cell-8-output-2.svg"))

]
#pagebreak()
== 第6問
<第6問>
#block[
#callout(
body: 
[
$2$以上の整数で,~1 とそれ自身以外に正の約数を持たない数を素数という.~以下の問いに答えよ.

(1)　$f (x) = x^3 + 10 x^2 + 20 x$とする.~$f (n)$が素数となるような整数 $n$をすべて求めよ.

(2)　$a , med b$を整数の定数とし,~$g (x) = x^3 + a x^2 + b x$とする.~$g (n)$が素数となるような整数 $n$の個数は $3$個以下であることを示せ.

]
, 
title: 
[
第6問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- 素数パッケージ`Primes.jl`を利用

- #block[
  #set enum(numbering: "(1)", start: 1)
  + は$- 100 lt.equiv n lt.equiv 100$で調べました。
  ]

- (2)は素数となるものが3つである$a$，$b$，$n$を列挙しました。

]
, 
title: 
[
(1)(2)を調べてみよう。
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using Primes


f(x) = x^3+10x^2+20x

n=100
p=[]
for i = -n:n
    if f(i) |>  isprime
        append!(p,i)
    end
end
 
p
```

```
3-element Vector{Any}:
 -7
 -3
  1
```

#block[
```julia
using Primes

g(a,b,x) = x^3+a*x^2+b*x


n=20
p=[]
for a = -n:n , b = -n:n
    t = [a,b]
    for i = -n:n
        if g(a,b,i) |>  isprime
            append!(t,i)
        end    
    end
    push!(p,t)
end
 
for j =1:length(p)
    if p[j] |>length == 5
        println(p[j])
    end
end
```

#block[
```
[-9, 15, 1, 2, 7]
[-7, 11, 1, 2, 5]
[-5, 7, 1, 2, 3]
[2, -1, -2, -1, 1]
[3, -1, -3, -1, 1]
[5, -1, -5, -1, 1]
[5, 5, -3, -2, 1]
[7, -1, -7, -1, 1]
[7, 9, -5, -2, 1]
[8, 14, -5, -3, 1]
[9, 13, -7, -2, 1]
[10, 20, -7, -3, 1]
[11, -1, -11, -1, 1]
[13, -1, -13, -1, 1]
[17, -1, -17, -1, 1]
[19, -1, -19, -1, 1]
```

]
]
#pagebreak()
= 東京大（文系）2024・数学
<東京大文系2024数学>
== 第1問
<第1問-1>
#block[
#callout(
body: 
[
座標平面上で，放物線 $C : y = a x^2 + b x + c$ が 2点 $upright(P) (cos theta , med sin theta) , med upright(Q) (- cos theta , med sin theta)$を通り，点 $upright("P")$ と点 $upright("Q")$ のそれぞれにおいて円 $x^2 + y^2 = 1$ と共通の接線を持っている。ただし， $0^circle.stroked.tiny < theta < 90^circle.stroked.tiny$ とする。

(1)　$a , med b , med c$ を $s = sin theta$ を用いて表せ。

(2)　放物線 $C$ と $x$ 軸で囲まれた図形の面積 $A$ を $s$ を用いて表せ。

(3)　$A gt.equiv sqrt(3)$ を示せ。

]
, 
title: 
[
第1問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- $f (x , theta) = - frac(1, 2 sin theta) x^2 + frac(sin^2 theta + 1, 2 sin theta)$

- $A (theta) = 2 integral_0^(cos theta) f (x) d x$

- $0 < theta < pi / 2$

]
, 
title: 
[
変化を見てみよう
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using Plots

f(x , θ) = -x^2/(2sin(θ)) +(sin(θ)+1/sin(θ))/2

plot(x->sqrt(1-x^2),aspectratio=true,label="x²+y²=1")
plot!(x->f(x,π/6),label="y=f(x,π/6)")
```

#box(image("327001_files/figure-typst/cell-11-output-1.svg"))

```julia
using QuadGK,Plots

f(x , θ) = -x^2/(2sin(θ)) +(sin(θ)+1/sin(θ))/2
Aa(θ) = 2 * quadgk(x-> f(x,θ),0,sqrt(sin(θ)^2+1))[1]

plot(x->Aa(x),xlim=(0.1,π/2),label="y=A(θ)")
```

#box(image("327001_files/figure-typst/cell-12-output-1.svg"))

```julia
using Optim,QuadGK

f(x , θ) = -x^2/(2sin(θ)) +(sin(θ)+1/sin(θ))/2
Aa(θ) = 2 * quadgk(x-> f(x,θ),0,sqrt(sin(θ)^2+1))[1]

minA = optimize(Aa, 0.1, 1.4)
```

```
Results of Optimization Algorithm
 * Algorithm: Brent's Method
 * Search Interval: [0.100000, 1.400000]
 * Minimizer: 7.853982e-01
 * Minimum: 1.732051e+00
 * Iterations: 12
 * Convergence: max(|x - x_upper|, |x - x_lower|) <= 2*(1.5e-08*|x|+2.2e-16): true
 * Objective Function Calls: 13
```

#pagebreak()
== 第2問
<第2問-1>
#block[
#callout(
body: 
[
以下の問に答えよ。必要ならば，$0.3 < log_10 2 < 0.31$ であることを用いてよい。

(1)　$5^n > 10^19$ となる最小の自然数 $n$ を求めよ。

(2)　$5^m + 4^m > 10^19$ となる最小の自然数 $m$ を求めよ.

]
, 
title: 
[
第2問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- $f (m) = 5^m + 4^m$

- $g (m) = ⌊ log_10 f (m) ⌋ + 1$

]
, 
title: 
[
桁数を調べてみよう。
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
f(m) = (BigInt(5))^m+(BigInt(4))^m

g(m) =floor(log10(f(m)))+1 |>Int

k =1
while g(k) < 20
    k += 1
end
k
```

```
28
```

#pagebreak()
== 第3問
<第3問-1>
#block[
#callout(
body: 
[
座標平面上に2点 $upright(O) (0 , med 0) , med upright(A) (0 , med 1)$ をとる。 $x$ 軸上の2点 $upright(P) (p , med 0) , med upright(Q) (q , med 0)$が，次の条件 (i)，(ii)をともに満たすとする。

(i)　$0 < p < 1$ かつ $p < q$

(ii)　線分 $upright("AP")$ の中点を $upright("M")$ とするとき， $angle upright(O A P) = angle upright(P M Q)$

(1)　$q$ を $p$ を用いて表せ。

(2)　$q = 1 / 3$ となる $p$ の値を求めよ。

(3)　$triangle.stroked.t upright(O A P)$ の面積を $S$，$triangle.stroked.t upright(P M Q)$ の面積を $T$ とする。$S > T$ となる $p$ の範囲を求めよ。

]
, 
title: 
[
第3問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- $q = frac(3 p - p^3, 2 (1 - p^2))$

- $S = 1 / 2 p$

- $T = 1 / 4 (q - p)$

- $f (p) = S - T$

]
, 
title: 
[
変化を見てみよう。
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
```julia
using Plots

q(p) = (3p-p^3)/2/(1-p^2)

S(p) =p/2

T(p) = (q(p)-p)/4

plot(S,xlim=(0.1,.9),label="y=S(p)")
plot!(T,xlim=(0.1,.9),label="y=T(p)")
```

#box(image("327001_files/figure-typst/cell-15-output-1.svg"))

```julia
using Optim

q(p) = (3p-p^3)/2/(1-p^2)

S(p) =p/2

T(p) = (q(p)-p)/4

f(p) = S(p) - T(p)

minf = optimize(x->abs(f(x)),.6,.8)
```

```
Results of Optimization Algorithm
 * Algorithm: Brent's Method
 * Search Interval: [0.600000, 0.800000]
 * Minimizer: 7.745967e-01
 * Minimum: 1.984967e-09
 * Iterations: 24
 * Convergence: max(|x - x_upper|, |x - x_lower|) <= 2*(1.5e-08*|x|+2.2e-16): true
 * Objective Function Calls: 25
```

#pagebreak()
== 第4問
<第4問-1>
#block[
#callout(
body: 
[
$n$ を5以上の奇数とする。平面上の点 $upright("O")$ を中心とする円をとり，それに内接する正 $n$ 角形を考える。$n$ 個の頂点から異なる4点を同時に選ぶ。ただし，どの4点も等確率で選ばれるものとする。選んだ4点を頂点とする四角形が $upright("O")$ を内部に含む確率 $p_n$ を求めよ。

]
, 
title: 
[
第4問・問題
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- 円周上から4点選ぶ。

- この4点から3点選んで三角形を作ったとき，1つでも鋭角三角形ができればOK。

- 4点を反時計回りに順番をつけ，最初と最後の点の差（4つある）がすべて$n \/ 2$より大きいとき，四角形の内部に中心が含まれる。

- コンビネーションパッケージ`Combinatorics.jl`を利用

]
, 
title: 
[
確率を求める数列を作ってみよう。
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
#block[
```julia
using Combinatorics

function N(n)
    X = [i for i = 0:n-1]
    Y = combinations(X,4) |> collect
    p=0
    for y in Y
        k = [
            mod(y[4]-y[1],n)
            mod(y[1]-y[2],n)
            mod(y[2]-y[3],n)
            mod(y[3]-y[4],n)
            ]
        if minimum(k) > n/2
            p += 1
        end
    end
    p//length(Y)
end

for i=5:2:21
    println("正",i,"角形のとき，確率は",N(i))
end
```

#block[
```
正5角形のとき，確率は1//1
正7角形のとき，確率は4//5
正9角形のとき，確率は5//7
正11角形のとき，確率は2//3
正13角形のとき，確率は7//11
正15角形のとき，確率は8//13
正17角形のとき，確率は3//5
正19角形のとき，確率は10//17
正21角形のとき，確率は11//19
```

]
]
#pagebreak()



