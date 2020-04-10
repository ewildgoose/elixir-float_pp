defmodule RoundingTest do
  use ExUnit.Case

  def round(number, precision \\ 0, rounding \\ :half_up) do
    number
    |> FloatPP.to_string(%{compact: false, decimals: precision, rounding: rounding})
    |> String.to_float()
  end

  def ceil(number, precision \\ 0) do
    round(number, precision, :ceiling)
  end

  def floor(number, precision \\ 0) do
    round(number, precision, :floor)
  end

  test "Simple round :half_up" do
    assert 1.21 == round(1.205, 2)
    assert 1.22 == round(1.215, 2)
    assert 1.23 == round(1.225, 2)
    assert 1.24 == round(1.235, 2)
    assert 1.25 == round(1.245, 2)
    assert 1.26 == round(1.255, 2)
    assert 1.27 == round(1.265, 2)
    assert 1.28 == round(1.275, 2)
    assert 1.29 == round(1.285, 2)
    assert 1.30 == round(1.295, 2)
  end

  test "Simple round :half_even" do
    assert 1.20 == round(1.205, 2, :half_even)
    assert 1.22 == round(1.215, 2, :half_even)
    assert 1.22 == round(1.225, 2, :half_even)
    assert 1.24 == round(1.235, 2, :half_even)
    assert 1.24 == round(1.245, 2, :half_even)
    assert 1.26 == round(1.255, 2, :half_even)
    assert 1.26 == round(1.265, 2, :half_even)
    assert 1.28 == round(1.275, 2, :half_even)
    assert 1.28 == round(1.285, 2, :half_even)
    assert 1.30 == round(1.295, 2, :half_even)
  end

  test "test ceil" do
    assert 1.21 == ceil(1.204, 2)
    assert 1.21 == ceil(1.205, 2)
    assert 1.21 == ceil(1.206, 2)

    assert 1.22 == ceil(1.214, 2)
    assert 1.22 == ceil(1.215, 2)
    assert 1.22 == ceil(1.216, 2)

    assert -1.20 == ceil(-1.204, 2)
    assert -1.20 == ceil(-1.205, 2)
    assert -1.20 == ceil(-1.206, 2)
  end

  test "test floor" do
    assert 1.20 == floor(1.204, 2)
    assert 1.20 == floor(1.205, 2)
    assert 1.20 == floor(1.206, 2)

    assert 1.21 == floor(1.214, 2)
    assert 1.21 == floor(1.215, 2)
    assert 1.21 == floor(1.216, 2)

    assert -1.21 == floor(-1.204, 2)
    assert -1.21 == floor(-1.205, 2)
    assert -1.21 == floor(-1.206, 2)
  end

  test "round with 0 decimals of a number between 0 and one" do
    assert 1.0 == round(0.959999999999809, 0)
  end

  test "rounding to less than the precision of the number returns 0" do
    assert 0.0 = round(1.235e-4, 3, :half_even)
  end
end
