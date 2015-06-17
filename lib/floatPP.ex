defmodule FloatPP do
  @doc """
  Pretty printer for Floats written in Elixir.

  Writes the shortest, correctly rounded string that converts to Float when read back with String.to_float/1.

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
  Convert a float to the shortest, correctly rounded string that converts to the
  same float when read back with String.to_float
  """
  def to_string(float, _options \\ %{}) when is_float(float) do
    {place, digits} = digits(float)

    digits
    |> insert_decimal(place)
    |> add_negative_sign(float < 0)
    |> IO.iodata_to_binary

  end

  # Prepend a "-" if negative
  defp add_negative_sign(digits, negative) do
    if negative, do: ["-" | digits], else: digits
  end

  # insert decimal places and format
  defp insert_decimal(digits, place) do
    digit_count = Enum.count(digits)

    # Ensure we have enough zeros on each end to place the "."
    if place <= 0 do
      digits = List.duplicate("0", 1 - place) ++ digits
      place = 1
    else
      if digit_count < (place + 1) do
        digits = digits ++ List.duplicate("0", place + 1 - digit_count)
      end
    end

    # Split the digits and place the decimal in the correct place
    {l, r} = Enum.split(digits, place)
    [l, ".", r]
  end

  @doc """
  Computes a iodata list of the digits of the given floating point number,
  together with the location of the decimal point as {place, digits}

  A "compact" representation is returned, so there may be fewer digits returned
  than the decimal point location
  """
  def digits(0.0), do: [1, "0"]
  def digits(float) do
    # Find mantissa and exponent from IEEE-754 packed notation
    {frac, exp} = frexp(float)

    # Scale fraction to integer (and adjust mantissa to compensate)
    frac = trunc(abs(frac) * @two53)
    exp = exp - 53

    # Compute digits
    flonum(float, frac, exp)
  end

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
        [Integer.to_string(d) | generate(r * 10, s, m_plus * 10, m_minus * 10, low_ok, high_ok)]
      else
        [Integer.to_string(d + 1)]
      end
    else
      if not(tc2) do
        [Integer.to_string(d)]
      else
        if r * 2 < s do
          [Integer.to_string(d)]
        else
          [Integer.to_string(d + 1)]
        end
      end
    end
  end



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


  def bitwise_length(value) do
    bitwise_length(value, 0)
  end

  defp bitwise_length(0, n), do: n
  defp bitwise_length(value, n), do: bitwise_length(bsr(value, 1), n+1)

  # FIXME: duplicating existing function in Float, which only goes up to 15.
  Enum.reduce 0..326, 1, fn x, acc ->
    defp power_of_10(unquote(x)), do: unquote(acc)
    acc * 10
  end


end