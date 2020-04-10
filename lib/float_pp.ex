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

    iex> FloatPP.to_string(12.3456, %{scientific: 3, compact: true, rounding: :floor})
    "1.234e+01"

    iex> FloatPP.to_string(12.3456, %{decimals: true})
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
    options = Map.merge(%{compact: false, rounding: :half_even}, options)

    options = if not(Map.has_key?(options, :decimals) or Map.has_key?(options, :scientific)) do
                Map.put(options, :decimals, true)
              else
                options
              end

    {digits, place, positive} = FloatPP.Digits.to_digits(float)

    {digits, place, positive}
    |> FloatPP.Round.round(options)
    |> stringify
    |> format_decimal(options)
  end


  # Take our list of integers and convert to a list of strings
  defp stringify({digits, place, positive}) do
    digit_string = digits
    |> List.flatten
    |> Enum.map(&Integer.to_string/1)

    {digit_string, place, positive}
  end


  # Prepend a "-" if not (positive)
  defp add_negative_sign(digits, _positive = true), do: digits
  defp add_negative_sign(digits, _positive = false), do: ["-" | digits]


  # format as a decimal number, either: decimal, or scientific notation
  # optionally will pad out decimal places to given "dp" if given option
  # compact: false
  # Returns iodata list
  def format_decimal({digits, place, positive}, %{scientific: dp, compact: false}) when is_integer(dp) do
    [do_format_decimal({digits, 1, positive}, dp), format_exponent(place-1)]
  end

  def format_decimal({digits, place, positive}, %{scientific: _dp}) do
    [do_format_decimal({digits, 1, positive}, 0), format_exponent(place-1)]
  end

  def format_decimal(digits_t, %{decimals: dp, compact: false}) when is_integer(dp) do
    do_format_decimal(digits_t, dp)
  end

  def format_decimal(digits_t, _options) do
    do_format_decimal(digits_t, 0)
  end


  # Insert a decimal in the given location
  # Optionally ensure we have "decimals" places of precision
  # NOTE: We assume rounding already performed, ie input has correct max decimal places
  #
  # FIXME: Need internationalisation of the decimal symbol
  defp do_format_decimal({digits, place, positive}, decimals) do
    decimal_sym = "."
    digit_count = Enum.count(digits)

    needed = place + max(1, decimals)
    digits =  if digit_count < needed do
                digits ++ List.duplicate("0", needed - digit_count)
              else
                digits
              end

    # Ensure we have enough zeros on each end to place the "."
    {digits, place} = if place <= 0 do
                        {List.duplicate("0", 1 - place) ++ digits, 1}
                      else
                        {digits, place}
                      end

    # Split the digits and place the decimal in the correct place
    {l, r} = Enum.split(digits, place)
    [l, decimal_sym, r]
    |> add_negative_sign(positive)
  end


  _ = """
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
