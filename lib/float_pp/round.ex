defmodule FloatPP.Round do
  @moduledoc """
  Implement rounding of a list of decimal digits to an arbitrary precision
  using one of several rounding algorithms.

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
  """
  require Integer

  @type rounding :: :down |
                    :half_up |
                    :half_even |
                    :ceiling |
                    :floor |
                    :half_down |
                    :up


  @doc """
  Round a digit using a specified rounding.

  Given a list of decimal digits (without trailing zeros) in the form
    sign [sig_digits] | least_sig | tie | [rest]

  There are a number of rounding options which may be conditional on for example
  - sign of the orignal number
  - even-ness of the least_sig digit
  - whether there is a non-zero tie break digit
  - if the tie break digit is 5, whether there are further non zero digits

  The various rounding rules are based on IEEE 754 and documented in the moduledoc
  """
  def round(digits, place, positive, options)

  # Passing 'nil' for decimal places avoids rounding and uses whatever is necessary
  def round(digits, _, _, %{scientific: nil}), do: digits
  def round(digits, _, _, %{decimals: nil}), do: digits

  # scientific/decimal rounding are the same, we are just varying which
  # digit we start counting from to find our rounding point
  def round(_, _place, _, %{scientific: dp}) when dp <= 0,
    do: [0]
  def round(digits, _place, positive, options = %{scientific: dp}),
    do: tiebreak(digits, dp, positive, options)

  def round(_, place, _, %{decimals: dp}) when dp + place <= 0,
    do: [0]
  def round(digits, place, positive, options = %{decimals: dp}),
    do: tiebreak(digits, dp + place - 1, positive, options)


  defp tiebreak(digits, place, positive, %{rounding: rounding}) do
    case Enum.split(digits, place) do
      {l, [least_sig | [tie | rest]]} -> [l, do_tiebreak(positive, least_sig, tie, rest, rounding)]
      {l, [least_sig | []]}           -> [l, least_sig]
      {l, []}                         -> l
    end
  end


  @spec do_tiebreak(boolean, non_neg_integer | nil, non_neg_integer | nil, list, FloatPP.rounding) :: non_neg_integer
  defp do_tiebreak(positive, least_sig, tie, rest, round)

  # Directed rounding towards 0 (truncate)
  defp do_tiebreak(_, ls, _tie, _, :down), do: ls
  # Directed rounding away from 0 (non IEEE option)
  defp do_tiebreak(_, ls, nil, _, :up), do: ls
  defp do_tiebreak(_, ls, _tie, _, :up), do: ls + 1

  # Directed rounding towards +∞ (rounding up / ceiling)
  defp do_tiebreak(true, ls, tie, _, :ceiling) when tie != nil, do: ls + 1
  defp do_tiebreak(_, ls, _tie, _, :ceiling), do: ls

  # Directed rounding towards -∞ (rounding down / floor)
  defp do_tiebreak(false, ls, tie, _, :floor) when tie != nil, do: ls + 1
  defp do_tiebreak(_, ls, _tie, _, :floor), do: ls

  # Round to nearest - tiebreaks by rounding to even
  # Default IEEE rounding, recommended default for decimal
  defp do_tiebreak(_, ls, 5, [], :half_even) when Integer.is_even(ls), do: ls
  defp do_tiebreak(_, ls, tie, _rest, :half_even) when tie >= 5, do: ls + 1
  defp do_tiebreak(_, ls, _tie, _rest, :half_even), do: ls

  # Round to nearest - tiebreaks by rounding away from zero (same as Elixir Kernel.round)
  defp do_tiebreak(_, ls, tie, _rest, :half_up) when tie >= 5, do: ls + 1
  defp do_tiebreak(_, ls, _tie, _rest, :half_up), do: ls

  # Round to nearest - tiebreaks by rounding towards zero (non IEEE option)
  defp do_tiebreak(_, ls, 5, [], :half_down), do: ls
  defp do_tiebreak(_, ls, tie, _rest, :half_down) when tie >= 5, do: ls + 1
  defp do_tiebreak(_, ls, _tie, _rest, :half_down), do: ls
end
