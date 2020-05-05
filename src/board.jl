"""
    Board

Parent element which encapsulates all objects (sliders, points, curves, ...).
"""
mutable struct Board
    name::String
    functions::Vector{JSFun}
    objects::Vector{Object}
    # --- key board options ---
    xlim::Vector{<:Real}
    ylim::Vector{<:Real}
    axis::Bool
    showcopyright::Bool
    shownavigation::Bool
    style::String
    # --- other board options --- jsxgraph.org/docs/symbols/JXG.Board.html
    opts::Option{LittleDict{Symbol,Any}}
end
function Board(name, funs, objs;
               xlim=[-10,10], ylim=[-10,10], axis=false,
               showcopyright=false, shownavigation=false,
               style="width:300px; height:300px;", kw...)
    d = dict(;kw...)
    b = Board(name, funs, objs, xlim, ylim, axis,
              showcopyright, shownavigation,
              style, d)
    if !isnothing(d) && :boundingbox ∈ keys(d)
        bb = d[:boundingbox]
        @assert length(bb) == 4 "Bounding box must have 4 elements."
        b.xlim = bb[1,3]
        b.ylim = bb[4,2]
    end
    return b
end

"""
    board(name="brd"+randstring(3); opts...)

Create a new board.

* `name` - name of the board (generated by default)

## Keyword
* `xlim::Vector` - x axis limits default: `[-10,10]`
* `ylim::Vector` - y axis limits default: `[-10,10]`
* `axis::Bool` - whether to show the axis ex: false
* `showcopyright::Bool` - whether to show JSX's copyright ex: true
* `shownavigation::Bool` - whether to show a navigation tool on the board ex:
                            true
* `style::String` - the CSS style of the div containing the board ex:
                     `"width:300px; height:300px;"`

You can also use any of the keywords from https://jsxgraph.org/docs/symbols/JXG.Board.html.
"""
board(name="brd_"*randstring(3); kw...) = Board(name, JSFun[], Object[]; kw...)

# ---------------------------------------------------------------------------

get_opts(b::Board) = (
    boundingbox = [b.xlim[1], b.ylim[2], b.xlim[2], b.ylim[1]],
    axis = b.axis,
    showcopyright = b.showcopyright,
    shownavigation = b.shownavigation,
    (isnothing(b.opts) ? () : (;b.opts...))...
    )

"""
    o |> board
    (o1, o2, ...) |> board
    [o1, o2, ...] |> board

Add object(s) to board `board`.
"""
(b::Board)(j::JSFun)  = push!(b.functions, j)
(b::Board)(o::Object) = push!(b.objects, o)
(b::Board)(o) = (b.(o); b)

"""
    board ++ o

Same as `o |> board`.
"""
++(b::Board, o) = b(o)
++(o, b::Board) = b(o)

"""
    empty!(board)

Removes everything on the board
"""
Base.empty!(b::Board) = (empty!(b.functions); empty!(b.objects); b)

# ---------------------------------------------------------------------------

const PREAMBLE = "function val(x){return x.Value();};" *
         "function valx(p){return p.X();};" *
         "function valy(p){return p.Y();};" *
         prod("function $f(x){return Math.$f(x);};"
         for f in (:abs, :acos, :acosh, :asin, :asinh,
                   :atan, :atanh, :ceil, :cos, :cosh, :exp,
                   :expm1, :floor, :hypot, :log, :log1p, :log10,
                   :log2, :max, :min, :round, :sign, :sin, :sinh,
                   :sqrt, :tan, :tanh, :trunc)) *
    "function rand(){return Math.random();};" *
    "const π=Math.PI;const ℯ=Math.E;const pi=Math.PI;"

function str(b::Board; preamble=true)
    io = IOBuffer()
    # preamble
    preamble && print(io, PREAMBLE)
    # functions
    for f in b.functions
        print(io, str(f))
    end
    # objects
    opts = get_opts(b)
    jss = js"JXG.JSXGraph.initBoard($(b.name),$opts);"
    print(io, "var $(b.name)=" * jss.s)
    for o in b.objects
        print(io, str(o, b))
    end
    s = "(function(){" * String(take!(io)) * "})();"
    return s
end

"""
    save(b, fpath)

Save a board as a javascript file that can be plugged in a HTML file which
would link to the JSXGraph library and stylesheet.
"""
function save(b::Board, fpath::AbstractString)
    fpath = splitext(fpath)[1] * ".js"
    write(fpath, str(b))
    return nothing
end
