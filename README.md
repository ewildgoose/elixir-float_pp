FloatPP
=====


DO NOT USE

This is a pretty printer for Floats written in Elixir.

Writes the shortest, correctly rounded string that converts to Float when read back with String.to_float.

Implements the algorithm from "Printing Floating-Point Numbers Quickly and Accurately"
in Proceedings of the SIGPLAN '96 Conference on Programming Language Design and Implementation.

Subsequently I discovered that there is already an implementation in Erlang stdlib (doh!).

Access it with:
    :io_lib_format.fwrite_g(thing)

Left here for interest...