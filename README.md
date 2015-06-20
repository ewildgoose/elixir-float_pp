FloatPP
=====

  Pretty printer for Floats written in Elixir.

  Writes the shortest, correctly rounded string of decimals that converts back
  to a Double when parsed with String.to_float/1.

  Implements the algorithm from "Printing Floating-Point Numbers Quickly and Accurately"
  in Proceedings of the SIGPLAN '96 Conference on Programming Language Design and Implementation.

  ## Output format options
  The output can be in either decimal or scientific format, and optionally rounded
  to an arbitrary number of decimal places, using one of several rounding algorithms.

  Output is the shortest decimal string which can be round tripped back into the
  original Double value (ie without loss of precision)

  Rounding algorithms are based on the definitions given in IEEE 754, but also
  include 2 additional options (effectively the complementary versions):

  ## Rounding algorithms

  Directed roundings:
  * `:down` - Round towards 0 (truncate), eg 10.9 rounds to 10.0
  * `:up` - Round away from 0, eg 10.1 rounds to 11.0. (Non IEEE algorithm)
  * `:ceiling` - Round toward +∞ - Also known as rounding up or ceiling
  * `:floor` - Round toward -∞ - Also known as rounding down or floor

  Round to nearest:
  * `:half_even` - Round to nearest value, but in a tiebreak, round towards the
    nearest value with an even (zero) least significant bit, which occurs 50%
    of the time. This is the default for IEEE binary floating-point and the recommended
    value for decimal.
  * `:half_up` - Round to nearest value, but in a tiebreak, round away from 0.
    This is the default algorithm for Erlang's Kernel.round/2
  * `:half_down` - Round to nearest value, but in a tiebreak, round towards 0
    (Non IEEE algorithm)

  ## Examples

    iex> FloatPP.to_string(12.3456, %{decimals: 3, compact: true, rounding: :half_even})
    "12.346"

    iex> FloatPP.to_string(12.3456, %{decimals: 6, compact: false, rounding: :half_even})
    "12.345600"

    iex> FloatPP.to_string(12.3456, %{scientific: 3, compact: true, rounding: :ceiling})
    "1.234e+01"

    iex> FloatPP.to_string(12.3456, %{decimals: nil})
    "12.3456"

  """