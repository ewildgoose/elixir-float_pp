defmodule FloatPP do
  @moduledoc """
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


  @doc """
  Convert a float to the shortest, correctly rounded string that converts to the
  same float when read back with String.to_float
  """
  def to_string(float, options \\ %{}) when is_float(float) do
    to_iodata(float, options)
    |> IO.iodata_to_binary
  end

  @doc """
  Convert a float to the shortest, correctly rounded string that converts to the
  same float when read back with String.to_float

  Returns an iodata list
  """
  def to_iodata(float, options \\ %{}) when is_float(float) do
    options = Map.merge(%{decimals: 20, compact: true, rounding: :half_even}, options)

    positive = (float < 0)
    {place, digits} = FloatPP.Digits.to_digits(float)

    digits
    |> FloatPP.Round.round(place, positive, options)
    |> stringify
    |> format_decimal(place, options)
    |> add_negative_sign(not(positive))
  end


  # Take our list of integers and convert to a list of strings
  defp stringify(digits) do
    digits
    |> List.flatten
    |> Enum.map(&Integer.to_string/1)
  end


  # Prepend a "-" if not (positive)
  defp add_negative_sign(digits, _positive = true), do: digits
  defp add_negative_sign(digits, _positive = false), do: ["-" | digits]


  # format as a decimal number, either: decimal, or scientific notation
  # optionally will pad out decimal places to given "dp" if given option
  # compact: false
  def format_decimal(digits, place, %{scientific: dp, compact: false}) do
    [do_format_decimal(digits, 1, dp), format_exponent(place-1)]
  end

  def format_decimal(digits, place, %{scientific: _dp}) do
    [do_format_decimal(digits, 1, 0), format_exponent(place-1)]
  end

  def format_decimal(digits, place, %{decimals: dp, compact: false}) do
    do_format_decimal(digits, place, dp)
  end

  def format_decimal(digits, place, _options) do
    do_format_decimal(digits, place, 0)
  end


  # Insert a decimal in the given location
  # Optionally ensure we have "decimals" places of precision
  # NOTE: We assume rounding already performed, ie input has correct max decimal places
  #
  # FIXME: Need internationalisation of the decimal symbol
  defp do_format_decimal(digits, place, decimals) do
    decimal_sym = "."
    digit_count = Enum.count(digits)

    needed = place + max(1, decimals)
    if digit_count < needed do
      digits = digits ++ List.duplicate("0", needed - digit_count)
    end

    # Ensure we have enough zeros on each end to place the "."
    if place <= 0 do
      digits = List.duplicate("0", 1 - place) ++ digits
      place = 1
    end

    # Split the digits and place the decimal in the correct place
    {l, r} = Enum.split(digits, place)
    [l, decimal_sym, r]
  end


  @doc """
  Format an exponent in float point format

    iex> format_exponent(4)
      e+04
    iex> format_exponent(128)
      e+128
    iex> format_exponent(-128)
      e-128
  """
  defp format_exponent(exp) when (abs(exp) < 10) and (exp >= 0), do: ["e+0", Integer.to_string(exp)]
  defp format_exponent(exp) when (abs(exp) < 10), do: ["e-0", Integer.to_string(-exp)]
  defp format_exponent(exp) when (exp < 0), do: ["e-", Integer.to_string(-exp)]
  defp format_exponent(exp), do: ["e+", Integer.to_string(exp)]

end

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

defmodule FloatPP.Digits do
  @moduledoc """
  Given an IEEE 754 float, computes the shortest, correctly rounded list of digits
  that converts back to the same Double value when read back with String.to_float/1.

  Implements the algorithm from "Printing Floating-Point Numbers Quickly and Accurately"
  in Proceedings of the SIGPLAN '96 Conference on Programming Language Design and Implementation.
  """

  use Bitwise
  require Integer

  @two52 bsl 1, 52
  @two53 bsl 1, 53
  @float_bias 1022
  @min_e -1074


  @doc """
  Computes a iodata list of the digits of the given IEEE 754 floating point number,
  together with the location of the decimal point as {place, digits}

  A "compact" representation is returned, so there may be fewer digits returned
  than the decimal point location
  """
  def to_digits(0.0), do: {1, [0]}
  def to_digits(float) do
    # Find mantissa and exponent from IEEE-754 packed notation
    {frac, exp} = frexp(float)

    # Scale fraction to integer (and adjust mantissa to compensate)
    frac = trunc(abs(frac) * @two53)
    exp = exp - 53

    # Compute digits
    flonum(float, frac, exp)
  end


  ############################################################################
  # The following functions are Elixir translations of the original paper:
  # "Printing Floating-Point Numbers Quickly and Accurately"
  # See the paper for further explanation


  @doc """
  Set initial values {r, s, m+, m-}
  based on table 1 from FP-Printing paper

  Assumes frac is scaled to integer (and exponent scaled appropriately)
  """
  def flonum(float, frac, exp) do
    round = Integer.is_even(frac)
    if exp >= 0 do
      b_exp = bsl(1, exp)
      if frac !== @two52 do
        scale((frac * b_exp * 2), 2, b_exp, b_exp, round, round, float)
      else
        scale((frac * b_exp * 4), 4, (b_exp * 2), b_exp, round, round, float)
      end
    else
      if (exp === @min_e) or (frac !== @two52) do
        scale((frac * 2), bsl(1, (1 - exp)), 1, 1, round, round, float)
      else
        scale((frac * 4), bsl(1, (2 - exp)), 2, 1, round, round, float)
      end
    end
  end

  def scale(r, s, m_plus, m_minus, low_ok, high_ok, float) do
    # TODO: Benchmark removing the log10 and using the approximation given in original paper?
    est = trunc(Float.ceil(:math.log10(abs(float)) - 1.0e-10))
    if est >= 0 do
      fixup(r, s * power_of_10(est), m_plus, m_minus, est, low_ok, high_ok)
    else
      scale = power_of_10(-est)
      fixup(r * scale, s, m_plus * scale, m_minus * scale, est, low_ok, high_ok)
    end
  end

  def fixup(r, s, m_plus, m_minus, k, low_ok, high_ok) do
    too_low = if high_ok, do: (r + m_plus) >= s, else: (r + m_plus) > s

    if too_low do
      {(k + 1), generate(r, s, m_plus, m_minus, low_ok, high_ok)}
    else
      {k, generate(r * 10, s, m_plus * 10, m_minus * 10, low_ok, high_ok)}
    end
  end

  defp generate(r, s, m_plus, m_minus, low_ok, high_ok) do
    d = div r, s
    r = rem r, s

    tc1 = if low_ok,  do: r <= m_minus,       else: r < m_minus
    tc2 = if high_ok, do: (r + m_plus) >= s,  else: (r + m_plus) > s

    if not(tc1) do
      if not(tc2) do
        [d | generate(r * 10, s, m_plus * 10, m_minus * 10, low_ok, high_ok)]
      else
        [d + 1]
      end
    else
      if not(tc2) do
        [d]
      else
        if r * 2 < s do
          [d]
        else
          [d + 1]
        end
      end
    end
  end


  ############################################################################
  # Utility functions

  @doc """
  The frexp() function is as per the clib function with the same name. It breaks
  the floating-point number value into a normalized fraction and an integral
  power of 2.

  Returns {frac, exp}, where the magnitude of frac is in the interval
  [1/2, 1) or 0, and value = frac*(2^exp).

  FIXME: We don't handle +/-inf and NaN inputs. Not believed to be an issue in
  Elixir, but beware future-self reading this...
  """
  def frexp(value) do
    << sign::1, exp::11, frac::52 >> = << value::float >>
    frexp(sign, frac, exp)
  end

  defp frexp(_Sign, 0, 0) do
    {0.0, 0}
  end
  # Handle denormalised values
  defp frexp(sign, frac, 0) do
    exp = bitwise_length(frac)
    <<f::float>> = <<sign::1, @float_bias::11, (frac-1)::52>>
    {f, -(@float_bias) - 52 + exp}
  end
  # Handle normalised values
  defp frexp(sign, frac, exp) do
    <<f::float>> = <<sign::1, @float_bias::11, frac::52>>
    {f, exp - @float_bias}
  end


  @doc """
  Return the number of significant bits needed to store the given number
  """
  def bitwise_length(value) do
    bitwise_length(value, 0)
  end

  defp bitwise_length(0, n), do: n
  defp bitwise_length(value, n), do: bitwise_length(bsr(value, 1), n+1)


  # Precompute powers of 10 up to 10^326
  # FIXME: duplicating existing function in Float, which only goes up to 15.
  Enum.reduce 0..326, 1, fn x, acc ->
    defp power_of_10(unquote(x)), do: unquote(acc)
    acc * 10
  end


end